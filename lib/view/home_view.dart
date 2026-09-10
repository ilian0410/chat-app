import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: controller.getUnreadNotificationsCount() > 0,
                label: Text('${controller.getUnreadNotificationsCount()}'),
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: controller.openNotifications,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search conversations',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshChats,
              child: Obx(() {
                if (controller.isLoading && controller.allChats.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error.isNotEmpty && controller.allChats.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(controller.error)),
                    ],
                  );
                }
                final chats = controller.chats;
                if (chats.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 56,
                        color: AppTheme.primaryColor.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          controller.searchQuery.value.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations found',
                        ),
                      ),
                      if (controller.searchQuery.value.isEmpty) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: controller.openFindPeople,
                            icon: const Icon(Icons.person_search),
                            label: const Text('Find friends'),
                          ),
                        ),
                      ],
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final chat = chats[index];
                    final user = controller.getOtherUser(chat);
                    if (user == null) return const SizedBox.shrink();
                    return ChatListItem(
                      chat: chat,
                      otherUser: user,
                      lastMessageTime: _formatTime(chat.lastMessageTime),
                      onTap: () => controller.openChat(chat),
                      
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      return '$hour:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${time.day}/${time.month}';
  }
}
