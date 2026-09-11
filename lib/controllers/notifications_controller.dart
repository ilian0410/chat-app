import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final userId = _authController.user?.uid;
    if (userId != null) {
      notifications.bindStream(
        _firestoreService.getNotificationsStream(userId).handleError((
          Object streamError,
          StackTrace stackTrace,
        ) {
          error.value = _firestoreService.describeStreamError(
            streamError,
            'notifications',
          );
        }),
      );
    }
  }

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index >= 0) {
      notifications[index] = notification.copyWith(isRead: true);
    }
    try {
      await _firestoreService.markNotificationAsRead(notification.id);
    } catch (e) {
      if (index >= 0) notifications[index] = notification;
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _authController.user?.uid;
    if (userId != null) {
      await _firestoreService.markAllNotificationsAsRead(userId);
    }
  }

  Future<void> delete(NotificationModel notification) async {
    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    notifications.removeWhere((item) => item.id == notification.id);
    try {
      await _firestoreService.deleteNotification(notification.id);
    } catch (e) {
      if (index >= 0) notifications.insert(index, notification);
      rethrow;
    }
  }

  Future<void> openNotification(NotificationModel notification) async {
    try {
      await markAsRead(notification);
      if (notification.type == NotificationType.friendRequest) {
        Get.toNamed(AppRoutes.friendRequests);
      } else if (notification.type == NotificationType.friendRequestAccepted ||
          notification.type == NotificationType.friendRequestDeclined ||
          notification.type == NotificationType.friendRemoved) {
        Get.toNamed(AppRoutes.friends);
      }
    } catch (e) {
      error.value = e.toString();
    }
  }
}
