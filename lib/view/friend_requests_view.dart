import 'package:chat_app/controllers/friend_requests_controller.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/friend_request_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

class FriendRequestsView extends GetView<FriendRequestsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Requests'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Column(
        //Tab selector
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex == 0
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              color: controller.selectedTabIndex == 0
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Received (${controller.receivedRequests.length})',
                              style: TextStyle(
                                color: controller.selectedTabIndex == 0
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex == 1
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: controller.selectedTabIndex == 1
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sent (${controller.sentRequests.length})',
                              style: TextStyle(
                                color: controller.selectedTabIndex == 1
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.error.isNotEmpty) {
                return Center(child: Text(controller.error));
              }
              return IndexedStack(
                index: controller.selectedTabIndex,
                children: [
                  _buildReceivedRequestsList(),
                  _buildSendRequestsTab(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedRequestsList() {
    return Obx(() {
      if (controller.receivedRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox,
          title: 'No Friend requests',
          message:
              'When someone sends you a friend request, it will appear here.',
        );
      }
      return ListView.separated(
        itemBuilder: (context, index) {
          final request = controller.receivedRequests[index];
          final sender = controller.getUser(request.senderId);
          if (sender == null) {
            return SizedBox.shrink();
          }
          return FriendRequestItem(
            request: request,
            user: sender,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: true,
            onAccept: () => controller.acceptRequest(request),
            onDecline: () => controller.declineFriendRequest(request),
            onRemove: () => _confirmRemove(request),
          );
        },
        separatorBuilder: ((context, index) => SizedBox(height: 8)),
        itemCount: controller.receivedRequests.length,
      );
    });
  }

  Widget _buildSendRequestsTab() {
    return Obx(() {
      if (controller.sentRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox,
          title: 'No Sent requests',
          message:
              'Friend requests you send will appear here until they are accepted or declined.',
        );
      }
      return ListView.separated(
        itemBuilder: (context, index) {
          final request = controller.sentRequests[index];
          final receiver = controller.getUser(request.receiverId);
          if (receiver == null) {
            return SizedBox.shrink();
          }
          return FriendRequestItem(
            request: request,
            user: receiver,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: false,
            statusText: controller.getStatusText(request.status),
            statusColor: controller.getStatusColor(request.status),
            onCancel: request.status == FriendRequestStatus.pending
                ? () => controller.cancelFriendRequest(request)
                : null,
            onRemove: () => _confirmRemove(request),
          );
        },
        separatorBuilder: ((context, index) => SizedBox(height: 8)),
        itemCount: controller.sentRequests.length,
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(FriendRequestModel request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove request?'),
        content: const Text(
          'This request will be removed from your request history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteFriendRequest(request);
    }
  }
}
