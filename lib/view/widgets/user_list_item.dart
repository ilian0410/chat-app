import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final UsersListController controller;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final relationshipStatus = controller.getUserRelationshipStatus(user.id);

      if (relationshipStatus == UserRelationShipStatus.blocked) {
        return const SizedBox.shrink();
      }

      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online dot indicator
              _buildAvatar(),

              const SizedBox(width: 14),

              // User Name and secondary details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                    const SizedBox(height: 3),
                    _buildSecondaryText(),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Contextual relationship action button
              _buildActionArea(context, relationshipStatus),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvatar() {
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          child: user.photoURL.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    user.photoURL,
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
        if (user.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759), // iOS / WhatsApp green
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecondaryText() {
    // Show bio if available, else email
    if (user.bio.trim().isNotEmpty) {
      return Text(
        user.bio.trim(),
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (user.isOnline) {
      return const Text(
        'Online',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF34C759),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      user.email,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textSecondaryColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    UserRelationShipStatus status,
  ) {
    switch (status) {
      case UserRelationShipStatus.none:
        return SizedBox(
          height: 32,
          child: FilledButton.icon(
            onPressed: () => controller.SendFriendRequest(user),
            icon: const Icon(Icons.person_add_rounded, size: 15),
            label: const Text(
              'Add',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      case UserRelationShipStatus.friendRequestSent:
        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Requested',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showCancelRequestDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        );

      case UserRelationShipStatus.friendRequestReceived:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: FilledButton.icon(
                onPressed: () => controller.acceptFriendRequest(user),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: const Text(
                  'Accept',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF34C759),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 32,
              width: 32,
              child: IconButton(
                onPressed: () => controller.declineFriendRequest(user),
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Decline',
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.textSecondaryColor,
                  backgroundColor: const Color(0xFFF2F2F7),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: Color(0xFFE5E5EA),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case UserRelationShipStatus.friends:
        return SizedBox(
          height: 32,
          child: OutlinedButton.icon(
            onPressed: () => controller.startChat(user),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
            label: const Text(
              'Message',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                width: 1,
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      case UserRelationShipStatus.blocked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Blocked',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorColor,
            ),
          ),
        );
    }
  }

  void _showCancelRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text('Cancel Request'),
        content: Text(
          'Cancel the friend request sent to ${user.displayName}?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.cancelFriendRequest(user);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}
