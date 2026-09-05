import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/view/widgets/user_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

class FindPeopleView extends GetView<UsersListController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find People'), leading: SizedBox()),

      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.filteredUsers.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.separated(
                itemBuilder: (context, index) {
                  final user = controller.filteredUsers[index];
                  return UserListItem(
                    user: user,
                    onTap: () {
                      
                      () => controller.handleRelationshipAction(user);
                    },
                    controller: controller,
                  );
                },

                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemCount: controller.filteredUsers.length,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
            width: 1.0,
          ),
        ),
      ),

      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search people',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Obx(() {
            return controller.searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      controller.clearSearchQuery();
                    },
                  )
                : SizedBox.shrink();
          }),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.borderColor.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.borderColor.withOpacity(0.5),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.person_search_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'No results found'
                  : 'No people found',
              style: Theme.of(
                Get.context!,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Try adjusting your search or check back later.'
                  : 'All users will appear here once they join the app.',
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
}
