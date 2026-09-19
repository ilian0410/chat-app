import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/controllers/main_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/friend_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        actions: [
          IconButton(
            tooltip: 'Friend Requests',
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppTheme.textPrimaryColor,
              size: 22,
            ),
            onPressed: controller.openFriendRequests,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ───────────────────────────────────────────────────
          _buildSearchBar(),

          // ── Error Banner ─────────────────────────────────────────────────
          _buildErrorBanner(),

          // ── Section Header ───────────────────────────────────────────────
          _buildSectionHeader(),

          // ── Friends List ─────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.friends.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                );
              }

              if (controller.filteredFriends.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.refreshFriends,
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: controller.filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = controller.filteredFriends[index];
                    final isFirst = index == 0;
                    final isLast =
                        index == controller.filteredFriends.length - 1;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: isFirst
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottom: isLast
                              ? const Radius.circular(12)
                              : Radius.zero,
                        ),
                        border: Border(
                          left: const BorderSide(
                            color: Color(0xFFE5E5EA),
                            width: 0.5,
                          ),
                          right: const BorderSide(
                            color: Color(0xFFE5E5EA),
                            width: 0.5,
                          ),
                          top: isFirst
                              ? const BorderSide(
                                  color: Color(0xFFE5E5EA),
                                  width: 0.5,
                                )
                              : BorderSide.none,
                          bottom: isLast
                              ? const BorderSide(
                                  color: Color(0xFFE5E5EA),
                                  width: 0.5,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FriendListItem(
                            friend: friend,
                            lastSeenText: controller.getLastSeenText(friend),
                            onTap: () => controller.startChat(friend),
                            onRemove: () => controller.removeFriend(friend),
                            onBlock: () => controller.blockFriend(friend),
                          ),
                          if (!isLast)
                            const Padding(
                              padding: EdgeInsets.only(left: 74),
                              child: Divider(
                                height: 0.5,
                                thickness: 0.5,
                                color: Color(0xFFE5E5EA),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE5E5EA),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF8E8E93),
                size: 20,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.updateSearchQuery,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimaryColor,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search friends…',
                  hintStyle: TextStyle(
                    color: Color(0xFFAEAEB2),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            Obx(() {
              if (controller.searchQuery.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: controller.clearSearch,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Icon(
                    Icons.cancel,
                    size: 18,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Obx(() {
      if (controller.filteredFriends.isEmpty) return const SizedBox.shrink();

      final text = controller.searchQuery.isNotEmpty
          ? '${controller.filteredFriends.length} ${controller.filteredFriends.length == 1 ? "RESULT" : "RESULTS"}'
          : '${controller.friends.length} ${controller.friends.length == 1 ? "FRIEND" : "FRIENDS"}';

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFAEAEB2),
            letterSpacing: 0.4,
          ),
        ),
      );
    });
  }

  Widget _buildErrorBanner() {
    return Obx(() {
      if (controller.error.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppTheme.errorColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.error,
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: controller.clearError,
              child: const Icon(
                Icons.close_rounded,
                color: AppTheme.errorColor,
                size: 18,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    final isSearching = controller.searchQuery.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5E5EA),
                  width: 0.8,
                ),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 28,
                color: const Color(0xFFAEAEB2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No Results Found' : 'No Friends Yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'No friends matched "${controller.searchQuery}". Check the spelling or try searching with an email.'
                  : 'Add friends to start chatting, sharing moments, and staying connected.',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (isSearching)
              TextButton(
                onPressed: controller.clearSearch,
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (Get.isRegistered<MainController>()) {
                          Get.find<MainController>().changeTabIndex(2);
                        } else {
                          Get.toNamed(AppRoutes.usersList);
                        }
                      },
                      icon: const Icon(Icons.person_search_rounded, size: 16),
                      label: const Text(
                        'Find Friends',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: controller.openFriendRequests,
                      icon: const Icon(Icons.inbox_rounded, size: 16),
                      label: const Text(
                        'Friend Requests',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: const BorderSide(
                          color: Color(0xFFE5E5EA),
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
