import 'package:chat_app/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ChangePasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final _obscureCurrentPassword = true.obs;
  final _obscureNewPassword = true.obs;
  final _obscureConfirmPassword = true.obs;
  bool get obscureCurrentPassword => _obscureCurrentPassword.value;
  bool get obscureNewPassword => _obscureNewPassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      _isLoading.value = true;
      _error.value = '';
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user is currently Logged In');
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPasswordController.text);
      Get.snackbar(
        'Success',
        'Password Changed Successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      Get.back();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'The current password is incorrect.';
          break;
        case 'weak-password':
          errorMessage = 'The new password is too weak.';
          break;

        case 'requires-recent-login':
          errorMessage = 'Please log in again and try changing your password.';
          break;
        default:
          errorMessage = 'Failed to change password: ${e.message}';
      }
      _error.value = errorMessage;
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _error.value = 'Failed to change password: ${e.toString()}';
      print(e.toString());
      Get.snackbar(
        'Error',
        _error.value,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  String? validateCurrentPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your new password';
    }
    if (value!.length < 6) {
      return 'The new password must be at least 6 characters long';
    }
    if (value == currentPasswordController.text) {
      return 'The new password must be different from the current password';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please confirm your new password';
    }
    if (value != newPasswordController.text) {
      return 'The confirmed password does not match the new password';
    }
    return null;
  }
  void _clearError() {
    _error.value = '';
  }
}
