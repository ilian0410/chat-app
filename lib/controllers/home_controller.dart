import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<ChatModel> _allChats = <ChatModel>[].obs;
  final RxList<ChatModel> _filteredChats = <ChatModel>[].obs;
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;
  final RxString _activeFilter = 'All'.obs;

  List<ChatModel> get chats => _getFilteredChats();
  List<ChatModel> get allChats => _allChats;
  List<ChatModel> get filteredChats => _filteredChats;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  RxMap<String, UserModel> get users => _users;
  RxString get searchQuery => _searchQuery;
  bool get isSearching => _isSearching.value;
  RxString get activeFilter => _activeFilter;

  @override
  void onInit() {
    super.onInit();
    _loadChats();
    _loadUsers();
    _loadNotifications();
  }

  void _loadChats() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _allChats.bindStream(
        _firestoreService.getUserChatsStream(currentUserId).handleError((
          Object error,
          StackTrace stackTrace,
        ) {
          _isLoading.value = false;
          _error.value = _firestoreService.describeStreamError(
            error,
            'conversations',
          );
        }),
      );

      ever(_allChats, (_) {
        if (_isSearching.value && _searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });

      ever(_activeFilter, (_) {
        if (_searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });

      ever(_users, (_) {
        if (_isSearching.value && _searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });
    }
  }

  void _loadUsers() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var user in userList) {
          userMap[user.id] = user;
        }
        return userMap;
      }),
    );
  }

  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId).handleError((
          Object error,
          StackTrace stackTrace,
        ) {
          _error.value = _firestoreService.describeStreamError(
            error,
            'notifications',
          );
        }),
      );
    }
  }

  UserModel? getOtherUser(ChatModel chat) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      return _users[otherUserId];
    }
    return null;
  }

  List<ChatModel> _getFilteredChats() {
    List<ChatModel> baseList = _isSearching.value ? _filteredChats : _allChats;
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      baseList = List<ChatModel>.from(baseList)
        ..sort((a, b) {
          final pinned = (b.isPinnedBy(currentUserId) ? 1 : 0).compareTo(
            a.isPinnedBy(currentUserId) ? 1 : 0,
          );
          if (pinned != 0) return pinned;
          return (b.lastMessageTime ?? DateTime(0)).compareTo(
            a.lastMessageTime ?? DateTime(0),
          );
        });
    }
    switch (_activeFilter.value) {
      case "Unread":
        return _applyUnreadFilter(baseList);

      case "Recent":
        return _applyRecentFilter(baseList);

      case "Active":
        return _applyActiveFilter(baseList);
      default:
        return baseList;
    }
  }

  List<ChatModel> _applyUnreadFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return [];

    return chats.where((chat) {
      return chat.getUnreadCount(currentUserId) > 0;
    }).toList();
  }

  List<ChatModel> _applyRecentFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final threeDayAgo = now.subtract(Duration(days: 3));
    return chats.where((chat) {
      final lastMessageTime = chat.lastMessageTime;
      return lastMessageTime != null && lastMessageTime.isAfter(threeDayAgo);
    }).toList();
  }

  List<ChatModel> _applyActiveFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(Duration(days: 7));
    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(oneWeekAgo);
    }).toList();
  }

  void setFilter(String filterType) {
    _activeFilter.value = filterType;
    if (filterType == "All") {
      if (_searchQuery.value.isEmpty) {
        _isSearching.value = false;
        _filteredChats.clear();
      }
    }
  }

  void clearAllFilters() {
    _activeFilter.value = 'All';
    _clearSearch();
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _clearSearch();
    } else {
      _isSearching.value = true;
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    final lowercaseQuery = query.toLowerCase().trim();
    _filteredChats.value = _allChats.where((chat) {
      final otherUser = getOtherUser(chat);
      if (otherUser == null) return false;
      final displayName = otherUser.displayName.toLowerCase().contains(
        lowercaseQuery,
      );

      final emailMatch = otherUser.email.toLowerCase().contains(lowercaseQuery);
      final lastMessageMatch =
          chat.lastMessage?.toLowerCase().contains(lowercaseQuery) ?? false;
      return displayName || emailMatch || lastMessageMatch;
    }).toList();

    _sortSearchResults(lowercaseQuery);
  }

  void _sortSearchResults(String query) {
    _filteredChats.sort((a, b) {
      final userA = getOtherUser(a);
      final userB = getOtherUser(b);

      if (userA == null || userB == null) return 0;

      final pinnedA = a.isPinnedBy(_authController.user?.uid ?? '');
      final pinnedB = b.isPinnedBy(_authController.user?.uid ?? '');
      if (pinnedA != pinnedB) return pinnedB ? 1 : -1;

      final exactMatchA = userA.displayName.toLowerCase().startsWith(query);
      final exactMatchB = userB.displayName.toLowerCase().startsWith(query);

      if (exactMatchA && !exactMatchB) return -1;
      if (!exactMatchA && exactMatchB) return 1;

      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });
  }

  void _clearSearch() {
    _isSearching.value = false;
    _filteredChats.clear();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _clearSearch();
  }

  void searchUserByName(String name) {
    onSearchChanged(name);
  }

  void searchByLastMessage(String message) {
    onSearchChanged(message);
  }

  List<ChatModel> getUnreadChats() {
    return _applyUnreadFilter(chats);
  }

  List<ChatModel> getActiveChats() {
    return _applyActiveFilter(chats);
  }

  List<ChatModel> getRecentChats({int limit = 10}) {
    final recentChats = _applyRecentFilter(_allChats);
    final sortedChats = List<ChatModel>.from(recentChats);
    sortedChats.sort((a, b) {
      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });
    return sortedChats.take(limit).toList();
  }

  int getUnreadCountForUser() {
    return getUnreadChats().length;
  }

  int getRecentCount() {
    return _applyRecentFilter(_allChats).length;
  }

  int getActiveCount() {
    return getActiveChats().length;
  }

  List<String> getSearchSuggestions() {
    final suggestions = <String>{};
    for (var chat in _allChats) {
      final otherUser = getOtherUser(chat);
      if (otherUser?.displayName != null) {
        suggestions.add(otherUser!.displayName);
      }
    }
    return suggestions.toSet().toList();
  }

  void openChat(ChatModel chat) {
    final otherUser = getOtherUser(chat);
    if (otherUser != null) {
      Get.toNamed(
        AppRoutes.chat,
        arguments: {'chatId': chat.id, 'otherUser': otherUser},
      );
    }
  }

  Future<void> togglePinned(ChatModel chat) async {
    final userId = _authController.user?.uid;
    if (userId == null) return;
    try {
      await _firestoreService.setChatPinned(
        chat.id,
        userId,
        !chat.isPinnedBy(userId),
      );
    } catch (e) {
      _error.value = 'Unable to update pinned conversation.';
    }
  }

  void openFriends() {
    Get.toNamed(AppRoutes.friends);
  }

  void openFindPeople() {
    Get.toNamed(AppRoutes.usersList);
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> refreshChats() async {
    _isLoading.value = true;

    try {
      await Future.delayed(Duration(seconds: 1));
      if (_isSearching.value && _searchQuery.value.isNotEmpty) {
        _performSearch(_searchQuery.value);
      }
    } catch (e) {
      _error.value = 'Failed to refresh chats';
    } finally {
      _isLoading.value = false;
    }
  }

  int getTotalUnreadCount() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return 0;

    int total = 0;
    for (var chat in _allChats) {
      total += chat.getUnreadCount(currentUserId);
    }
    return total;
  }

  int getUnreadNotificationsCount() {
    return _notifications.where((notif) => !notif.isRead).length;
  }

  Future<void> deleteChat(ChatModel chat) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;
      final otherUser = getOtherUser(chat);
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Chat'),
          content: Text(
            'Are you sure you want to delete this chat with ${otherUser?.displayName ?? 'this user'} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
      if (result == true) {
        await _firestoreService.deleteChatForUser(chat.id, currentUserId);
        Get.snackbar('Success', 'The chat has been deleted successfully.');
      }
    } catch (e) {
      print(e.toString());
      Get.snackbar('Error', 'Failed to delete chat.');
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _error.value = '';
  }

  @override
  void onClose() {
    super.onClose();
  }
}
