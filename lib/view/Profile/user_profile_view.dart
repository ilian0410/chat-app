import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  UserModel? get user {
    final arguments = Get.arguments;
    if (arguments is UserModel) return arguments;
    if (arguments is Map<String, dynamic> && arguments['user'] is UserModel) {
      return arguments['user'] as UserModel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = user;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('This profile is unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(profile.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: AppTheme.primaryColor,
              backgroundImage: profile.photoURL.isNotEmpty
                  ? NetworkImage(profile.photoURL)
                  : null,
              child: profile.photoURL.isEmpty
                  ? Text(
                      profile.displayName.isEmpty
                          ? '?'
                          : profile.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile.displayName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (profile.bio.trim().isNotEmpty)
              Text(
                profile.bio,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: Icon(
                  profile.isOnline ? Icons.circle : Icons.circle_outlined,
                  color: profile.isOnline
                      ? AppTheme.successColor
                      : AppTheme.textSecondaryColor,
                  size: 14,
                ),
                title: Text(
                  profile.isOnline
                      ? 'Online'
                      : 'Last seen ${_lastSeen(profile.lastSeen)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastSeen(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
