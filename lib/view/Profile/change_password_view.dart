import 'package:chat_app/controllers/change_password_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/state_manager.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Update your password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Enter your current password and choose a new secure password to update your account.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 40),
                Obx(
                  () => TextFormField(
                    controller: controller.currentPasswordController,
                    obscureText: controller.obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefix: Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureCurrentPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.toggleCurrentPasswordVisibility,
                      ),
                      hintText: 'Enter your current password',
                    ),

                    validator: controller.validateCurrentPassword,
                  ),
                ),
                SizedBox(height: 20),
                Obx(
                  () => TextFormField(
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefix: Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureNewPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.toggleNewPasswordVisibility,
                      ),
                      hintText: 'Enter your new password',
                    ),
                    validator: controller.validateNewPassword,
                  ),
                ),
                SizedBox(height: 32),

                Obx(
                  () => TextFormField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefix: Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                      hintText: 'Confirm your new password',
                    ),
                    validator: controller.validateConfirmPassword,
                  ),
                ),
                SizedBox(height: 40),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : controller.changePassword,
                      icon: controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.security_rounded),
                      label: Text(
                        controller.isLoading
                            ? 'Updating...'
                            : 'Update Password',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
