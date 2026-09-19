import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/user_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindPeopleView extends GetView<UsersListController> {
  const FindPeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Find Friends',
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

          // ── User Results List ────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading && controller.users.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                );
              }

              if (controller.filteredUsers.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: controller.filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = controller.filteredUsers[index];
                  final isFirst = index == 0;
                  final isLast = index == controller.filteredUsers.length - 1;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(12) : Radius.zero,
                        bottom: isLast ? const Radius.circular(12) : Radius.zero,
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
                        UserListItem(
                          user: user,
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.userProfile,
                              arguments: {'user': user},
                            );
                          },
                          controller: controller,
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
                  hintText: 'Search by name or email…',
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
                onTap: controller.clearSearchQuery,
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
      if (controller.filteredUsers.isEmpty) return const SizedBox.shrink();

      final text = controller.searchQuery.isNotEmpty
          ? '${controller.filteredUsers.length} ${controller.filteredUsers.length == 1 ? "RESULT" : "RESULTS"}'
          : 'PEOPLE ON CHATAPP';

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
              isSearching ? 'No Results Found' : 'No People Found',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'No users matched "${controller.searchQuery}". Check the spelling or try a different name.'
                  : 'New users will appear here once they join the app.',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.clearSearchQuery,
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
