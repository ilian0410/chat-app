import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendListItem extends StatelessWidget {
  final UserModel friend;
  final String lastSeenText;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onBlock;

  const FriendListItem({
    super.key,
    required this.friend,
    required this.lastSeenText,
    required this.onTap,
    required this.onRemove,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar with presence badge & profile tap ───────────────────
            _buildAvatar(),

            const SizedBox(width: 14),

            // ── Friend name and presence / last seen status ────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friend.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  _buildStatusText(),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Quick Message Button ───────────────────────────────────────
            IconButton(
              onPressed: onTap,
              tooltip: 'Message',
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 19,
                color: AppTheme.primaryColor,
              ),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: 4),

            // ── Secondary Options Menu ─────────────────────────────────────
            _buildOptionsMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = friend.displayName.isNotEmpty
        ? friend.displayName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.userProfile, arguments: {'user': friend});
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
            ),
            child: friend.photoURL.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      friend.photoURL,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 18,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
          ),
          if (friend.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    if (friend.isOnline) {
      return const Text(
        'Active now',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF34C759),
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      lastSeenText,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textSecondaryColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Get.toNamed(AppRoutes.userProfile, arguments: {'user': friend});
            break;
          case 'message':
            onTap();
            break;
          case 'remove':
            onRemove();
            break;
          case 'block':
            onBlock();
            break;
        }
      },
      tooltip: 'More actions',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppTheme.textPrimaryColor,
              ),
              SizedBox(width: 12),
              Text(
                'View Profile',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'message',
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 12),
              Text(
                'Send Message',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(
                Icons.person_remove_outlined,
                size: 18,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: 12),
              Text(
                'Remove Friend',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              Icon(
                Icons.block_rounded,
                size: 18,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: 12),
              Text(
                'Block User',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: Color(0xFF8E8E93),
        size: 20,
      ),
    );
  }
}
