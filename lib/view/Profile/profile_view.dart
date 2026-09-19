import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS-style system grouped background
      body: Obx(() {
        final user = controller.currentUser;
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
          );
        }

        final isEditing = controller.isEditing;
        final isLoading = controller.isLoading;

        return CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFFF2F2F7),
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              title: Text(
                isEditing ? 'Edit Profile' : 'Profile',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                  fontSize: 17,
                ),
              ),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: isLoading ? null : controller.toggleEditing,
                  child: Text(
                    isEditing ? 'Cancel' : 'Edit',
                    style: TextStyle(
                      color: isEditing
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // ── Avatar + Identity ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
                    child: Column(
                      children: [
                        // Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _Avatar(user: user),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => Get.snackbar(
                                    'Coming soon',
                                    'Photo upload will be available soon.',
                                    snackPosition: SnackPosition.BOTTOM,
                                  ),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFF2F2F7),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Display name
                        Text(
                          user.displayName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                            fontSize: 22,
                          ),
                        ),

                        const SizedBox(height: 3),

                        // Email
                        Text(
                          user.email,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),

                        // Bio (if present and not editing)
                        if (user.bio.trim().isNotEmpty && !isEditing)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
                            child: Text(
                              user.bio,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // Status + join date row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: user.isOnline
                                    ? const Color(0xFF34C759) // iOS green
                                    : const Color(0xFFAEAEB2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              user.isOnline ? 'Active now' : 'Offline',
                              style: textTheme.bodySmall?.copyWith(
                                color: user.isOnline
                                    ? const Color(0xFF34C759)
                                    : const Color(0xFFAEAEB2),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '·',
                              style: TextStyle(
                                color: Color(0xFFAEAEB2),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              controller.getJoinedData(),
                              style: textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFAEAEB2),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Edit Form (shown only in edit mode) ───────────────────
                  if (isEditing)
                    _Section(
                      children: [
                        _FormField(
                          label: 'Display Name',
                          controller: controller.displayNameController,
                          enabled: true,
                          maxLength: 50,
                        ),
                        const _Separator(),
                        _FormField(
                          label: 'Bio',
                          controller: controller.bioController,
                          enabled: true,
                          maxLength: 120,
                          maxLines: 3,
                          hint: 'Add a short bio…',
                        ),
                      ],
                    ),

                  // Read-only email shown always when not editing
                  if (!isEditing)
                    _Section(
                      children: [
                        _InfoRow(
                          label: 'Email',
                          value: user.email,
                        ),
                      ],
                    ),

                  // ── Save button ───────────────────────────────────────────
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : controller.updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),

                  // ── Account Section ───────────────────────────────────────
                  if (!isEditing)
                    _Section(
                      header: 'ACCOUNT',
                      children: [
                        _ActionRow(
                          icon: Icons.lock_outline,
                          label: 'Change Password',
                          onTap: () => Get.toNamed(AppRoutes.changePassword),
                        ),
                      ],
                    ),

                  // ── Danger Zone ───────────────────────────────────────────
                  if (!isEditing)
                    _Section(
                      children: [
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          onTap: () => _confirmSignOut(context),
                        ),
                        const _Separator(),
                        _ActionRow(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete Account',
                          isDestructive: true,
                          onTap: () => controller.deleteAccount(),
                        ),
                      ],
                    ),

                  // ── Version footer ────────────────────────────────────────
                  if (!isEditing)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
                      child: Text(
                        'ChatApp v1.0.0',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFAEAEB2),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final dynamic user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = (user.displayName as String).isNotEmpty
        ? (user.displayName as String)[0].toUpperCase()
        : '?';

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor,
      ),
      child: (user.photoURL as String).isNotEmpty
          ? ClipOval(
              child: Image.network(
                user.photoURL as String,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

/// Grouped card section — matches iOS settings style
class _Section extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const _Section({this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                header!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAEAEB2),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// A thin divider line for use inside a _Section
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: const Color(0xFFE5E5EA),
      ),
    );
  }
}

/// Read-only info row
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable action row (for settings / account actions)
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFAEAEB2),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline text form field — no floating label, clean single-line look
class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int? maxLength;
  final int maxLines;
  final String? hint;

  const _FormField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.maxLength,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 108,
            child: Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLength: maxLength,
              maxLines: maxLines,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                  null, // hide char counter
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondaryColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFAEAEB2),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
