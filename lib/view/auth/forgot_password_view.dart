import 'package:chat_app/controllers/forgot_password_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: controller.goBackToLogin,
                      icon: Icon(Icons.arrow_back),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Forgot Password',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 56),
                  child: Text(
                    "Enter your email address below and we'll send you a link to reset your password",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppTheme.primaryColor,
                      size: 50,
                    ),
                  ),
                ),
                SizedBox(height: 60),
                Obx(() {
                  if (controller.emailSent) {
                    return _buildEmailSentContent(controller);
                  } else {
                    return _buildEmailForm(controller);
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(ForgotPasswordController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
            hintText: 'Enter your email Address',
          ),

          validator: controller.validateEmail,
        ),
        SizedBox(height: 32),
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : controller.sendPasswordResetEmail,
              icon: controller.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send),
              label: Text(
                controller.isLoading ? 'Sending...' : 'Send Reset Link',
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Remember your password ?",
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            GestureDetector(
              onTap: controller.goBackToLogin,
              child: Text(
                " Sign In",
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSentContent(ForgotPasswordController controller) {
    return Column(
children: [
  Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.successColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon( Icons.mark_email_read_rounded,
          color: AppTheme.successColor,
          size: 60,
        ),
        SizedBox(height: 16),
        Text(
          'Email Sent!',
          style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
            color: AppTheme.successColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'A password reset link has been sent to ${controller.emailController.text.trim()}. Please check your inbox and follow the instructions to reset your password.',
          textAlign: TextAlign.center,
          style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
SizedBox(height: 4,),
Text(controller.emailController.text,
style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
  color: AppTheme.primaryColor,
  fontWeight: FontWeight.w600
),
),
Text( "Check your email and follow the instructions to reset your password.",
style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
  color: AppTheme.textSecondaryColor,
),
textAlign: TextAlign.center
,)
      ],
    ),
  ),
SizedBox(height: 32,),
SizedBox(width: double.infinity,
child: OutlinedButton.icon(
  onPressed: controller.resendEmail,
icon: Icon(Icons.refresh),
label: Text("Resend Email")
),
),
SizedBox(height: 16,),
SizedBox(width: double.infinity,
child: ElevatedButton.icon(
  onPressed: controller.goBackToLogin,
icon: Icon(Icons.arrow_back),
label: Text("Go Back to Sign In")
),
),
SizedBox(height: 24,),
Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.secondaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        SizedBox(width: 12),
        Expanded(child: Text(
          "Didn't receive the email? Please check your spam folder or try resending the email.",
          style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondaryColor,
          ),
        )
        ),
      ],
    ),
)

],

    );
  }
}
