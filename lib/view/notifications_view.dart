import 'package:chat_app/controllers/notifications_controller.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: AppBar(
                automaticallyImplyLeading: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppTheme.textPrimaryColor,
                  ),
                  onPressed: () => Get.back(),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -0.3,
                  ),
                ),
                centerTitle: true,
                actions: [
                  Obx(() {
                    if (controller.unreadCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: controller.markAllAsRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.error.isNotEmpty && controller.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.error.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (controller.notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 52,
                      color: Color(0xFFC7C7CC),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'All caught up',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'You don\'t have any notifications right now.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = controller.notifications;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: 1, // Single grouped card container
            itemBuilder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E5EA),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < notifications.length; i++) ...[
                        _buildNotificationRow(
                          context,
                          notifications[i],
                          isLast: i == notifications.length - 1,
                        ),
                        if (i < notifications.length - 1)
                          const Padding(
                            padding: EdgeInsets.only(left: 64),
                            child: Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: Color(0xFFF2F2F7),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildNotificationRow(
    BuildContext context,
    NotificationModel notification, {
    required bool isLast,
  }) {
    return VisibilityDetector(
      key: Key('notification-visibility-${notification.id}'),
      onVisibilityChanged: (info) {
        final current = controller.notifications.firstWhereOrNull(
          (item) => item.id == notification.id,
        );
        if (info.visibleFraction > 0 && current != null && !current.isRead) {
          controller.markAsRead(current);
        }
      },
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          controller.delete(notification);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: const Color(0xFFFF3B30),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        child: Material(
          color: notification.isRead
              ? Colors.white
              : AppTheme.primaryColor.withValues(alpha: 0.04),
          child: InkWell(
            onTap: () => controller.openNotification(notification),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  _buildTypeIcon(notification.type),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: notification.isRead
                                    ? const Color(0xFF8E8E93)
                                    : AppTheme.primaryColor,
                                fontWeight: notification.isRead
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: notification.isRead
                                ? const Color(0xFF636E72)
                                : AppTheme.textPrimaryColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Unread indicator dot
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.friendRequest:
        icon = Icons.person_add_rounded;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.friendRequestAccepted:
        icon = Icons.how_to_reg_rounded;
        color = const Color(0xFF34C759);
        break;
      case NotificationType.friendRequestDeclined:
      case NotificationType.friendRemoved:
        icon = Icons.person_remove_rounded;
        color = const Color(0xFFFF3B30);
        break;
      case NotificationType.newMessage:
        icon = Icons.chat_bubble_rounded;
        color = const Color(0xFF007AFF);
        break;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
