import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendRequestItem extends StatelessWidget {
  final FriendRequestModel request;
  final UserModel user;
  final String timeText;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;
  final String? statusText;
  final Color? statusColor;

  const FriendRequestItem({
    super.key,
    required this.request,
    required this.user,
    required this.timeText,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    this.onRemove,
    this.statusText,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Avatar + User info + Timestamp/Remove ──────────────
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.userProfile,
                  arguments: {'user': user},
                ),
                child: _buildAvatar(),
              ),
              const SizedBox(width: 12),

              // Name & Email
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.toNamed(
                    AppRoutes.userProfile,
                    arguments: {'user': user},
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Remove icon for completed / resolved requests
              if (onRemove != null &&
                  (!isReceived || request.status != FriendRequestStatus.pending))
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFFAEAEB2),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          // ── Action Buttons (Received) ─────────────────────────────────
          if (isReceived &&
              request.status == FriendRequestStatus.pending) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Row(
                children: [
                  // Confirm button
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Decline button
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton.tonal(
                        onPressed: onDecline,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F2F7),
                          foregroundColor: const Color(0xFF3C3C43),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]

          // ── Sent Request Status Badge ─────────────────────────────────
          else if (!isReceived && statusText != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Row(
                children: [
                  _buildStatusPill(),
                  const Spacer(),
                  if (request.status == FriendRequestStatus.pending &&
                      onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cancel request',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
      ),
      child: user.photoURL.isNotEmpty
          ? ClipOval(
              child: Image.network(
                user.photoURL,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
    );
  }

  Widget _buildStatusPill() {
    Color bg;
    Color fg;
    IconData icon;

    switch (request.status) {
      case FriendRequestStatus.pending:
        bg = const Color(0xFFFF9500).withValues(alpha: 0.12);
        fg = const Color(0xFFFF9500);
        icon = Icons.schedule_rounded;
        break;
      case FriendRequestStatus.accepted:
        bg = const Color(0xFF34C759).withValues(alpha: 0.12);
        fg = const Color(0xFF34C759);
        icon = Icons.check_circle_outline_rounded;
        break;
      case FriendRequestStatus.declined:
        bg = const Color(0xFFFF3B30).withValues(alpha: 0.12);
        fg = const Color(0xFFFF3B30);
        icon = Icons.highlight_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            statusText!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
