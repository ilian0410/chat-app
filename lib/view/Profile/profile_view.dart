import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:flutter/material.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isEditing
                  ? controller.toggleEditing
                  : controller.toggleEditing,
              child: Text(
                controller.isEditing ? 'Cancel' : 'Edit',
                style: TextStyle(
                  color: controller.isEditing
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Obx(() {
        final user = controller.currentUser;
        if (user == null) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        return SingleChildScrollView(
padding: const EdgeInsets.symmetric(
  horizontal: 24,
  vertical: 12,
),          child: Column(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor,
                        child: user.photoURL.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.photoURL,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar(user);
                                  },
                                ),
                              )
                            : _buildDefaultAvatar(user),
                      ),

                      if (controller.isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Get.snackbar(
                                  'Info',
                                  'Photo Update Coming Soon',
                                );
                              },
                              icon: Icon(
                                size: 20,
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: user.isOnline
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.textSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: user.isOnline
                                ? AppTheme.successColor
                                : AppTheme.textSecondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          user.isOnline ? 'Online' : 'Offline',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: user.isOnline
                                    ? AppTheme.successColor
                                    : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    controller.getJoinedData(),
                    style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Obx(
                () => Card(
                  child: Padding(
                    padding: EdgeInsetsGeometry.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Personal Information",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: controller.displayNameController,
                          enabled: controller.isEditing,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person_outlined),
                            labelText: 'Display Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                         TextFormField(
                          controller: controller.emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined),
                            helperText: "Email can't be changed",
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      if (controller.isEditing)...[
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isLoading ? null : controller.updateProfile,
                            child:controller.isLoading 
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                           : Text('Save Changes'),
                          ),
                        ),
                      ]
                       
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  Card(
                    child:Column(
                      children: [
                        ListTile(
                          leading:Icon(
                            Icons.security,
                            color: AppTheme.primaryColor
                            ,
                            
                          ) ,
                          title: Text('Change Password'),
                          trailing: Icon(Icons.arrow_forward_ios_rounded),
                          onTap: () {
                            Get.toNamed(AppRoutes.changePassword);
                          },
                        ),
                        Divider(height: 1, color: Colors.grey),
                          ListTile(
                          leading:Icon(
                            Icons.delete_forever_rounded,
                            color: AppTheme.errorColor
                            ,
                            
                          ) ,
                          title: Text('Delete Account'),
                          trailing: Icon(Icons.arrow_forward_ios_rounded),
                          onTap: () {
                            controller.deleteAccount();
                          },
                        ),
                        Divider(height: 1, color: Colors.grey),
                          ListTile(
                          leading:Icon(
                            Icons.logout_rounded,
                            color: AppTheme.errorColor
                            ,
                            
                          ) ,
                          title: Text('Sign Out'),
                          trailing: Icon(Icons.arrow_forward_ios_rounded),
                          onTap: () {
                            controller.signOut();
                          },
                        ),
                      ],
                    ) ,
                  ),
                  SizedBox(height: 12),
                  Text("ChatApp v1.0.0", style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),)
                ],
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDefaultAvatar(user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
