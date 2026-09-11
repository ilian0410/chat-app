import 'package:chat_app/controllers/notifications_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(
            () => controller.unreadCount == 0
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: controller.markAllAsRead,
                    child: const Text('Mark all read'),
                  ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.error.isNotEmpty && controller.notifications.isEmpty) {
          return Center(child: Text(controller.error.value));
        }
        if (controller.notifications.isEmpty) {
          return const Center(child: Text('No notifications'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final notification = controller.notifications[index];
            return VisibilityDetector(
              key: Key('notification-visibility-${notification.id}'),
              onVisibilityChanged: (info) {
                final current = controller.notifications.firstWhereOrNull(
                  (item) => item.id == notification.id,
                );
                if (info.visibleFraction > 0 &&
                    current != null &&
                    !current.isRead) {
                  controller.markAsRead(current);
                }
              },
              child: Dismissible(
                key: ValueKey(notification.id),
                onDismissed: (_) => controller.delete(notification),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red.shade700),
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: notification.isRead
                      ? AppTheme.cardColor
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: notification.isRead
                          ? AppTheme.borderColor
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .18),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => controller.openNotification(notification),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppTheme.textPrimaryColor,
                                              fontWeight: notification.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _formatTime(notification.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.body,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: notification.isRead
                                            ? AppTheme.textSecondaryColor
                                            : AppTheme.textPrimaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.circle,
                                size: 9,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Delete notification',
                            onPressed: () => controller.delete(notification),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppTheme.textSecondaryColor,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
