import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

void _loadUserData() {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  print('PROFILE UID: $currentUserId');

  if (currentUserId != null) {
    _currentUser.bindStream(
      _firestoreService.getUserStream(currentUserId),
    );

    ever(_currentUser, (UserModel? user) {
      print('FIRESTORE USER: $user');

      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    });
  }
}

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isLoading.value = true;
      _error.value = '';
      final user = _currentUser.value;
      if (user == null) return;
      final updatedUser = user.copyWith(
        displayName: displayNameController.text,
      );
      await _firestoreService.updateUser(updatedUser);
      _isEditing.value = false;
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isEditing.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authController.signOut();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Get.back(result: true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
      await _authController.deleteAccount();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete account: ${e.toString()}',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
      );
    }
  }
  String getJoinedData() {
  final user = _currentUser.value;

  if (user == null) return '';

  final date = user.createdAt;

  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  return 'Joined ${months[date.month - 1]} ${date.year}';
}

void _clearError() {
    _error.value = '';
  }

}
