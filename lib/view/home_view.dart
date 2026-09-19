import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Column(
          children: [
            _Header(controller: controller),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshChats,
                color: AppTheme.primaryColor,
                child: Obx(() {
                  // Loading
                  if (controller.isLoading && controller.allChats.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }

                  // Error
                  if (controller.error.isNotEmpty &&
                      controller.allChats.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        _EmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'Something went wrong',
                          subtitle: controller.error,
                          action: TextButton(
                            onPressed: controller.refreshChats,
                            child: const Text('Try again'),
                          ),
                        ),
                      ],
                    );
                  }

                  final chats = controller.chats;

                  // Empty
                  if (chats.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        controller.searchQuery.value.isNotEmpty
                            ? _EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No results',
                                subtitle:
                                    'No conversations match "${controller.searchQuery.value}"',
                              )
                            : _EmptyState(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'No conversations yet',
                                subtitle:
                                    'Start a conversation with one of your friends.',
                                action: FilledButton.icon(
                                  onPressed: controller.openFindPeople,
                                  icon: const Icon(Icons.person_search_rounded,
                                      size: 18),
                                  label: const Text('Find Friends'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    );
                  }

                  // Chat list
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: chats.length + 1, // +1 for the grouped container
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return _ChatGroupContainer(
                          count: chats.length,
                          children: chats.map((chat) {
                            final user = controller.getOtherUser(chat);
                            if (user == null) return const SizedBox.shrink();
                            return ChatListItem(
                              key: ValueKey(chat.id),
                              chat: chat,
                              otherUser: user,
                              lastMessageTime: _formatTime(chat.lastMessageTime),
                              onTap: () => controller.openChat(chat),
                            );
                          }).toList(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '${m}m';
    }
    if (diff.inDays == 0) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final min = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$min $period';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    }
    return '${time.day}/${time.month}';
  }
}

// ── Header (title + search + filter chips) ────────────────────────────────────

class _Header extends StatelessWidget {
  final HomeController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding + 8),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Obx(
                  () => IconButton(
                    tooltip: 'Notifications',
                    icon: Badge(
                      isLabelVisible:
                          controller.getUnreadNotificationsCount() > 0,
                      label: Text(
                        '${controller.getUnreadNotificationsCount()}',
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 24,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    onPressed: controller.openNotifications,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBar(controller: controller),
          ),

          const SizedBox(height: 10),

          // Filter chips
          _FilterChips(controller: controller),

          // Bottom hairline
          Container(height: 0.5, color: const Color(0xFFE5E5EA)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final HomeController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.search_rounded, size: 18, color: Color(0xFFAEAEB2)),
          ),
          Expanded(
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimaryColor,
              ),
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Color(0xFFAEAEB2),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Obx(() {
            if (controller.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: controller.clearSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFAEAEB2),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final HomeController controller;
  const _FilterChips({required this.controller});

  static const _filters = ['All', 'Unread', 'Recent', 'Active'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.activeFilter.value;
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i];
            final selected = f == active;
            return GestureDetector(
              onTap: () => controller.setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : const Color(0xFF3C3C43),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Grouped container with rounded corners ────────────────────────────────────

class _ChatGroupContainer extends StatelessWidget {
  final List<Widget> children;
  final int count;
  const _ChatGroupContainer({required this.children, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          child: Column(
            children: _buildWithDividers(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWithDividers() {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          const Padding(
            padding: EdgeInsets.only(left: 79),
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFFF2F2F7),
            ),
          ),
        );
      }
    }
    return result;
  }
}

// ── Empty / error state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: const Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
