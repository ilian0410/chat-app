import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:uuid/uuid.dart';

enum UserRelationShipStatus {
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
}

class UsersListController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = Uuid();
  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _error = ''.obs;
  final RxMap<String, UserRelationShipStatus> _userRelationships =
      <String, UserRelationShipStatus>{}.obs;
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;
  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;
  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  String get error => _error.value;
  Map<String, UserRelationShipStatus> get userRelationships =>
      _userRelationships;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRelationships();
    debounce(
      _sentRequests,
      (_) => _filterUsers(),
      time: Duration(milliseconds: 300),
    );
  }

  void _loadUsers() async {
    _users.bindStream(_firestoreService.getAllUsersStream());
    // filter out current user and update the filtered list
    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      final otherUsers = userList
          .where((user) => user.id != currentUserId)
          .toList();

      if (_searchQuery.isNotEmpty) {
        _filteredUsers.value = otherUsers;
      } else {
        _filterUsers();
      }
    });
  }

  void _loadRelationships() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStream(currentUserId),
      );
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );
      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );
      ever(_sentRequests, (_) => _updateAllUserRelationshipsStatus());
      ever(_receivedRequests, (_) => _updateAllUserRelationshipsStatus());
      ever(_friendships, (_) => _updateAllUserRelationshipsStatus());
      ever(_users, (_) => _updateAllUserRelationshipsStatus());
    }
  }

  void _updateAllUserRelationshipsStatus() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;
    for (var user in _users) {
      final status = _calculateUserRelationshipStatus(user.id);
      _userRelationships[user.id] = status;
    }
  }

  UserRelationShipStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return UserRelationShipStatus.none;
    final friendship = _friendships.firstWhereOrNull(
      (f) =>
          (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );

    if (friendship != null) {
      if (friendship.isBlocked) {
        return UserRelationShipStatus.blocked;
      } else {
        return UserRelationShipStatus.friends;
      }
    }

    final sentRequest = _sentRequests.firstWhereOrNull(
      (r) => r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );

    if (sentRequest != null) {
      return UserRelationShipStatus.friendRequestSent;
    }

    final receivedRequest = _receivedRequests.firstWhereOrNull(
      (r) => r.senderId == userId && r.status == FriendRequestStatus.pending,
    );

    if (receivedRequest != null) {
      return UserRelationShipStatus.friendRequestReceived;
    }

    return UserRelationShipStatus.none;
  }

  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      _filteredUsers.value = _users
          .where((user) => user.id != currentUserId)
          .toList();
    } else {
      _filteredUsers.value = _users.where((user) {
        return user.id != currentUserId &&
            (user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearchQuery() {
    _searchQuery.value = '';
  }

  Future<void> SendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        final request = FriendRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
        );

        _userRelationships[user.id] = UserRelationShipStatus.friendRequestSent;
        await _firestoreService.sendFriendRequest(request);
        Get.snackbar('Success', 'Friend request sent To ${user.displayName}');
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationShipStatus.none;
      _error.value = e.toString();
      print('Error sending friend request: $e');
      Get.snackbar('Error', 'Failed to send friend request: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        final request = _sentRequests.firstWhereOrNull(
          (r) =>
              r.receiverId == user.id &&
              r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationShipStatus.none;
          await _firestoreService.cancelFriendRequest(request.id);

          Get.snackbar(
            'Success',
            'Friend request canceled for ${user.displayName}',
          );
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationShipStatus.friendRequestSent;
      _error.value = e.toString();
      print('Error canceling friend request: $e');
      Get.snackbar('Error', 'Failed to cancel friend request: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationShipStatus.friends;
          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.accepted,
          );
          Get.snackbar(
            'Success',
            'Friend request accepted from ${user.displayName}',
          );
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationShipStatus.friendRequestReceived;
      _error.value = e.toString();
      print('Error accepting friend request: $e');
      Get.snackbar('Error', 'Failed to accept friend request: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declineFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationShipStatus.none;
          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.declined,
          );
          Get.snackbar(
            'Success',
            'Friend request declined from ${user.displayName}',
          );
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationShipStatus.friendRequestReceived;
      _error.value = e.toString();
      print('Error declining friend request: $e');
      Get.snackbar('Error', 'Failed to decline friend request: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;
      if (currentUserId != null) {
        final relationship =
            _userRelationships[user.id] ?? UserRelationShipStatus.none;
        if (relationship != UserRelationShipStatus.friends) {
          Get.snackbar(
            'Info',
            'You can only start a chat with friends. Please send a friend request first.',
          );
          return;
        }

        final chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );
        Get.toNamed(
          AppRoutes.chat,
          arguments: {'chatId': chatId, 'otherUser': user},
        );
      }
    } catch (e) {
      _error.value = e.toString();
      print('Error starting chat: $e');
      Get.snackbar('Error', 'Failed to start chat: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  UserRelationShipStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationShipStatus.none;
  }

  String getRelationshipButtonText(UserRelationShipStatus status) {
    switch (status) {
      case UserRelationShipStatus.none:
        return 'Add';
      case UserRelationShipStatus.friendRequestSent:
        return 'Request Sent';
      case UserRelationShipStatus.friendRequestReceived:
        return 'Accept';
      case UserRelationShipStatus.friends:
        return 'Message';
      case UserRelationShipStatus.blocked:
        return 'Blocked';
    }
  }

  IconData getRelationshipButtonIcon(UserRelationShipStatus status) {
    switch (status) {
      case UserRelationShipStatus.none:
        return Icons.person_add;
      case UserRelationShipStatus.friendRequestSent:
        return Icons.hourglass_top;
      case UserRelationShipStatus.friendRequestReceived:
        return Icons.check;
      case UserRelationShipStatus.friends:
        return Icons.chat_bubble_outline;
      case UserRelationShipStatus.blocked:
        return Icons.block;
    }
  }

  Color getRelationshipButtonColor(UserRelationShipStatus status) {
    switch (status) {
      case UserRelationShipStatus.none:
        return Colors.blue;
      case UserRelationShipStatus.friendRequestSent:
        return Colors.orange;
      case UserRelationShipStatus.friendRequestReceived:
        return Colors.green;
      case UserRelationShipStatus.friends:
        return Colors.blue;
      case UserRelationShipStatus.blocked:
        return Colors.red;
    }
  }

  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);
    switch (status) {
      case UserRelationShipStatus.none:
        SendFriendRequest(user);
        break;
      case UserRelationShipStatus.friendRequestSent:
        cancelFriendRequest(user);
        break;
      case UserRelationShipStatus.friendRequestReceived:
        acceptFriendRequest(user);
        break;
      case UserRelationShipStatus.friends:
        startChat(user);
        break;
      case UserRelationShipStatus.blocked:
        Get.snackbar('Info', 'You cannot interact with blocked users.');
        break;
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return "Online";
    } else {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen);
      if (difference.inMinutes < 1) {
        return "seen just now";
      } else if (difference.inHours < 1) {
        return "seen ${difference.inMinutes} min ago";
      } else if (difference.inDays < 1) {
        return "seen ${difference.inHours} h ago";
      } else if (difference.inDays < 7) {
        return "seen ${difference.inDays} d ago";
      } else {
        return "seen on ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}";
      }
    }
  }

  void _clearError() {
    _error.value = '';
  }
}
