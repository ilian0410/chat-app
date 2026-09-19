import 'package:chat_app/controllers/friend_requests_controller.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/friend_request_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FriendRequestsView extends GetView<FriendRequestsController> {
  const FriendRequestsView({super.key});

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
                automaticallyImplyLeading: false,
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
                  'Friend Requests',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -0.3,
                  ),
                ),
                centerTitle: true,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // ── Segmented Control Bar ────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _buildSegmentedControl(),
            ),
            Container(height: 0.5, color: const Color(0xFFE5E5EA)),

            // ── Content Area ─────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.error.isNotEmpty) {
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
                            controller.error,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: controller.clearError,
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return IndexedStack(
                  index: controller.selectedTabIndex,
                  children: [
                    _buildReceivedRequestsList(),
                    _buildSentRequestsList(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Obx(() {
      final selected = controller.selectedTabIndex;
      final receivedCount = controller.receivedRequests.length;
      final sentCount = controller.sentRequests.length;

      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            // Received Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.changeTab(0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selected == 0
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Received',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: selected == 0
                              ? AppTheme.textPrimaryColor
                              : const Color(0xFF636E72),
                        ),
                      ),
                      if (receivedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected == 0
                                ? AppTheme.primaryColor
                                : const Color(0xFF8E8E93),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$receivedCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Sent Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.changeTab(1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selected == 1
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sent',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected == 1 ? FontWeight.w600 : FontWeight.w500,
                          color: selected == 1
                              ? AppTheme.textPrimaryColor
                              : const Color(0xFF636E72),
                        ),
                      ),
                      if (sentCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected == 1
                                ? AppTheme.primaryColor
                                : const Color(0xFF8E8E93),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$sentCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReceivedRequestsList() {
    return Obx(() {
      final requests = controller.receivedRequests;
      if (requests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.person_search_rounded,
          title: 'No Friend Requests',
          subtitle:
              'When people send you a friend request, it will appear here.',
          action: FilledButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.usersList),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Find Friends'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 1,
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
                  for (int i = 0; i < requests.length; i++) ...[
                    _buildReceivedRow(requests[i]),
                    if (i < requests.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 70),
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
    });
  }

  Widget _buildReceivedRow(FriendRequestModel request) {
    final sender = controller.getUser(request.senderId);
    if (sender == null) return const SizedBox.shrink();

    return FriendRequestItem(
      key: ValueKey(request.id),
      request: request,
      user: sender,
      timeText: controller.getRequestTimeText(request.createdAt),
      isReceived: true,
      onAccept: () => controller.acceptRequest(request),
      onDecline: () => controller.declineFriendRequest(request),
      onRemove: () => _confirmRemove(request),
    );
  }

  Widget _buildSentRequestsList() {
    return Obx(() {
      final requests = controller.sentRequests;
      if (requests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.send_rounded,
          title: 'No Sent Requests',
          subtitle:
              'Requests you send to other users will appear here until accepted.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 1,
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
                  for (int i = 0; i < requests.length; i++) ...[
                    _buildSentRow(requests[i]),
                    if (i < requests.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 70),
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
    });
  }

  Widget _buildSentRow(FriendRequestModel request) {
    final receiver = controller.getUser(request.receiverId);
    if (receiver == null) return const SizedBox.shrink();

    return FriendRequestItem(
      key: ValueKey(request.id),
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
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: const Color(0xFFC7C7CC),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(FriendRequestModel request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          'Remove Request?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This will remove this request from your history.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF636E72),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
