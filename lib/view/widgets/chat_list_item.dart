import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final UserModel otherUser;
  final String lastMessageTime;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.otherUser,
    required this.lastMessageTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Get.find<AuthController>().user?.uid ?? '';
    final unreadCount = chat.getUnreadCount(currentUserId);
    final isPinned = chat.isPinnedBy(currentUserId);
    final isFromMe = chat.lastMessageSenderId == currentUserId;
    final isSeen = isFromMe &&
        chat.isMessageSeen(
          currentUserId,
          chat.getOtherParticipant(currentUserId),
        );

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showChatOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            _buildAvatar(),

            const SizedBox(width: 13),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name + timestamp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isPinned)
                              const Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 12,
                                  color: Color(0xFFAEAEB2),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                otherUser.displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastMessageTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? AppTheme.primaryColor
                              : const Color(0xFFAEAEB2),
                          fontWeight: unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Row 2: message preview + unread badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Delivery tick (only for sent messages)
                      if (isFromMe) ...[
                        Icon(
                          isSeen
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: isSeen
                              ? AppTheme.primaryColor
                              : const Color(0xFFAEAEB2),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0
                                ? AppTheme.textPrimaryColor
                                : const Color(0xFF8E8E93),
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = otherUser.displayName.isNotEmpty
        ? otherUser.displayName[0].toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
          child: otherUser.photoURL.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    otherUser.photoURL,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 19,
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
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
        ),
        if (otherUser.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  void _showChatOptions(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final currentUserId =
        Get.find<AuthController>().user?.uid ?? '';
    final isPinned = chat.isPinnedBy(currentUserId);

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // ── User info header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Text(
                        otherUser.displayName.isNotEmpty
                            ? otherUser.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          otherUser.isOnline ? 'Online' : otherUser.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE5E5EA)),
            ),

            // ── Actions ───────────────────────────────────────────────
            _BottomSheetTile(
              icon: Icons.person_outline_rounded,
              label: 'View Profile',
              iconColor: AppTheme.primaryColor,
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.userProfile, arguments: {'user': otherUser});
              },
            ),
            _BottomSheetTile(
              icon: isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              label: isPinned ? 'Unpin Conversation' : 'Pin Conversation',
              iconColor: AppTheme.textPrimaryColor,
              onTap: () {
                Get.back();
                homeController.togglePinned(chat);
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE5E5EA)),
            ),

            _BottomSheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Conversation',
              iconColor: AppTheme.errorColor,
              textColor: AppTheme.errorColor,
              onTap: () {
                Get.back();
                homeController.deleteChat(chat);
              },
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
      isScrollControlled: false,
    );
  }
}

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _BottomSheetTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: textColor ?? AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
