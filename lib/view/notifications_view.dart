import 'package:chat_app/controllers/notifications_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final notification = controller.notifications[index];
            return Dismissible(
              key: ValueKey(notification.id),
              onDismissed: (_) => controller.delete(notification),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Colors.red.shade50,
                child: const Icon(Icons.delete_outline),
              ),
              child: ListTile(
                onTap: () => controller.openNotification(notification),
                tileColor: notification.isRead
                    ? null
                    : Theme.of(context).colorScheme.primary.withOpacity(.08),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Text(notification.body),
                trailing: notification.isRead
                    ? null
                    : const Icon(Icons.circle, size: 10),
              ),
            );
          },
        );
      }),
    );
  }
}
