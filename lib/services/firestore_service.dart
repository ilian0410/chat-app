import 'dart:async';

import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, Future<UserModel?>> _userLookupCache = {};

  String describeStreamError(Object error, String resource) {
    if (error is FirebaseException && error.code == 'failed-precondition') {
      return 'Unable to load $resource. A Firestore index must be deployed.';
    }
    return 'Unable to load $resource. Please try again.';
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    final cached = _userLookupCache[userId];
    if (cached != null) return cached;

    final lookup = _getUserFromFirestore(userId);
    _userLookupCache[userId] = lookup;
    return lookup;
  }

  Future<UserModel?> _getUserFromFirestore(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception('Failed to update user online status: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Stream<ChatModel?> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? ChatModel.fromMap(doc.data() as Map<String, dynamic>)
              : null,
        );
  }

  Future<void> updateTyping(String chatId, String userId, bool isTyping) {
    return _firestore.collection('chats').doc(chatId).update({
      'typing.$userId': isTyping,
    });
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
      _userLookupCache.remove(user.id);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> setChatPinned(String chatId, String userId, bool pinned) async {
    await _firestore.collection('chats').doc(chatId).update({
      'pinnedBy.$userId': pinned,
    });
  }

  Future<bool> areUsersBlocked(String userId, String otherUserId) async {
    final users = await Future.wait([
      _getUserFromFirestore(userId),
      _getUserFromFirestore(otherUserId),
    ]);
    final user = users[0];
    final otherUser = users[1];
    return user?.blockedUserIds.contains(otherUserId) == true ||
        otherUser?.blockedUserIds.contains(userId) == true;
  }

  Stream<bool> getBlockedStatusStream(String userId, String otherUserId) {
    return getUserStream(
      userId,
    ).map((user) => user?.blockedUserIds.contains(otherUserId) ?? false);
  }

  Future<void> setUserBlocked(
    String userId,
    String otherUserId,
    bool blocked,
  ) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final otherRef = _firestore.collection('users').doc(otherUserId);
    final operation = blocked
        ? FieldValue.arrayUnion([otherUserId])
        : FieldValue.arrayRemove([otherUserId]);
    final reverseOperation = blocked
        ? FieldValue.arrayUnion([userId])
        : FieldValue.arrayRemove([userId]);
    batch.update(userRef, {'blockedUserIds': operation});
    batch.update(otherRef, {'blockedUserIds': reverseOperation});
    await batch.commit();
    _userLookupCache.remove(userId);
    _userLookupCache.remove(otherUserId);
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // friend request collection
  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      if (await areUsersBlocked(request.senderId, request.receiverId)) {
        throw Exception('This user is blocked.');
      }
      await _firestore
          .collection('friend_requests')
          .doc(request.id)
          .set(request.toMap());
      String notificationId =
          'friend_request_${request.id}_${request.receiverId}_${DateTime.now().millisecondsSinceEpoch}';

      final sender = await getUser(request.senderId);
      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          title: 'New Friend Request',
          body:
              'You have a new friend request from ${sender?.displayName ?? 'a user'}',
          type: NotificationType.friendRequest,
          data: {'senderId': request.senderId, 'requestId': request.id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to send friend request: ${e.toString()}');
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      DocumentSnapshot requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();
      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );
        await _firestore.collection('friend_requests').doc(requestId).delete();
        await deleteNotificationsByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception('Failed to cancel friend request: ${e.toString()}');
    }
  }

  Future<void> deleteFriendRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();
      if (!requestDoc.exists) return;
      final request = FriendRequestModel.fromMap(
        requestDoc.data() as Map<String, dynamic>,
      );
      await _firestore.collection('friend_requests').doc(requestId).delete();
      if (request.status == FriendRequestStatus.pending) {
        await deleteNotificationsByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception('Failed to delete friend request: ${e.toString()}');
    }
  }

  Future<void> respondToFriendRequest(
    String requestId,
    FriendRequestStatus status,
  ) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': status.name,
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });
      DocumentSnapshot requestDoc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();

      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );
        if (status == FriendRequestStatus.accepted) {
          await createFriendship(request.senderId, request.receiverId);
          final receiver = await getUser(request.receiverId);
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Accepted',
              body:
                  'Your friend request has been accepted by ${receiver?.displayName ?? 'the recipient'}',
              type: NotificationType.friendRequestAccepted,
              data: {'senderId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );
          await _removeNotificationForCanceledRequest(
            request.receiverId,
            request.senderId,
          );
        } else if (status == FriendRequestStatus.declined) {
          final receiver = await getUser(request.receiverId);
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Declined',
              body:
                  'Your friend request has been declined by ${receiver?.displayName ?? 'the recipient'}',
              type: NotificationType.friendRequestDeclined,
              data: {'senderId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );
          await _removeNotificationForCanceledRequest(
            request.receiverId,
            request.senderId,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to respond to friend request: ${e.toString()}');
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<FriendRequestModel?> getFriendRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (query.docs.isNotEmpty) {
        return FriendRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friend request: ${e.toString()}');
    }
  }

  // friendships collections

  Future<void> createFriendship(String userId, String user2Id) async {
    try {
      List<String> userIds = [userId, user2Id];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';
      FriendshipModel friendship = FriendshipModel(
        id: friendshipId,
        user1Id: userIds[0],
        user2Id: userIds[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .set(friendship.toMap());
    } catch (e) {
      throw Exception('Failed to create friendship: ${e.toString()}');
    }
  }

  Future<void> removeFriendShip(String userId, String user2Id) async {
    try {
      List<String> userIds = [userId, user2Id];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendshipId).delete();

      final remover = await getUser(userId);
      await createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user2Id,
          title: 'Friend Removed',
          body:
              '${remover?.displayName ?? 'A friend'} removed you as a friend.',
          type: NotificationType.friendRemoved,
          data: {'userId': userId},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to remove friendship: ${e.toString()}');
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  Future<void> unblockUser(String userId, String user2Id) async {
    try {
      List<String> userIds = [userId, user2Id];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendshipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    final controller = StreamController<List<FriendshipModel>>.broadcast();
    var first = <FriendshipModel>[];
    var second = <FriendshipModel>[];

    void emit() {
      controller.add(
        [
          ...first,
          ...second,
        ].where((friendship) => !friendship.isBlocked).toList(),
      );
    }

    final firstSubscription = _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          first = snapshot.docs
              .map(
                (doc) => FriendshipModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList();
          emit();
        }, onError: controller.addError);
    final secondSubscription = _firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          second = snapshot.docs
              .map(
                (doc) => FriendshipModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList();
          emit();
        }, onError: controller.addError);

    controller.onCancel = () async {
      await firstSubscription.cancel();
      await secondSubscription.cancel();
    };
    return controller.stream;
  }

  Future<FriendshipModel?> getFriendships(String userId, String user2Id) async {
    try {
      List<String> userIds = [userId, user2Id];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (doc.exists) {
        return FriendshipModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friendship: ${e.toString()}');
    }
  }

  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check if user is blocked: ${e.toString()}');
    }
  }

  Future<bool> isUnfriended(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();
      String friendshipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      return !doc.exists || (doc.exists && doc.data() == null);
    } catch (e) {
      throw Exception('Failed to check if users are friends: ${e.toString()}');
    }
  }

  // chats collection

  Future<String> createOrGetChat(String userId1, String userId2) async {
    try {
      List<String> participants = [userId1, userId2];
      participants.sort();
      String chatId = '${participants[0]}_${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        ChatModel newChat = ChatModel(
          id: chatId,
          participants: participants,
          unreadCount: {userId1: 0, userId2: 0},
          deletedBy: {userId1: false, userId2: false},
          deletedAt: {userId1: null, userId2: null},
          lastSeenBy: {userId1: null, userId2: null},
          typing: {userId1: false, userId2: false},
          pinnedBy: {userId1: false, userId2: false},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await chatRef.set(newChat.toMap());
      } else {
        ChatModel existingChat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        if (existingChat.isDeletedBy(userId1)) {
          await restoreChatForUser(chatId, userId1);
        }
        if (existingChat.isDeletedBy(userId2)) {
          await restoreChatForUser(chatId, userId2);
        }
      }
      return chatId;
    } catch (e) {
      throw Exception('Failed to create or get chat: ${e.toString()}');
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .where((chat) => !chat.isDeletedBy(userId))
              .toList(),
        );
  }

  Future<void> updateChatLastMessage(
    String chatId,
    MessageModel message,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update chat last message: ${e.toString()}');
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update last seen: ${e.toString()}');
    }
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to delete chat for user: ${e.toString()}');
    }
  }

  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deletedBy.$userId': false,
      });
    } catch (e) {
      throw Exception('Failed to restore chat for user: ${e.toString()}');
    }
  }

  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': count,
      });
    } catch (e) {
      throw Exception('Failed to update unread count: ${e.toString()}');
    }
  }

  Future<void> incrementUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment unread count: ${e.toString()}');
    }
  }

  Future<void> restoreUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to restore unread count: ${e.toString()}');
    }
  }

  Future<void> markConversationAsRead(
    String chatId,
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('senderId', isEqualTo: otherUserId)
          .get();
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        final data = document.data();
        if (data['isRead'] != true) {
          batch.update(document.reference, {'isRead': true});
        }
      }
      batch.update(_firestore.collection('chats').doc(chatId), {
        'unreadCount.$currentUserId': 0,
        'lastSeenBy.$currentUserId': DateTime.now().millisecondsSinceEpoch,
      });
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark conversation as read: ${e.toString()}');
    }
  }

  //Messages collection

  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      if (await areUsersBlocked(message.senderId, message.receiverId)) {
        throw Exception(
          'Messaging is unavailable because one user is blocked.',
        );
      }
      final messageData = message.toMap()..['isDelivered'] = true;
      await _firestore.collection('messages').doc(message.id).set(messageData);
      final resolvedChatId = chatId;

      await updateChatLastMessage(resolvedChatId, message);
      await updateUserLastSeen(resolvedChatId, message.senderId);
      await incrementUnreadCount(resolvedChatId, message.receiverId);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> setMessageReaction(
    String messageId,
    String userId,
    String? reaction,
  ) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'reactions.$userId': reaction == null ? FieldValue.delete() : reaction,
      });
    } catch (e) {
      throw Exception('Failed to update message reaction: ${e.toString()}');
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String userId1, String userId2) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> participants = [userId1, userId2];
          participants.sort();
          String chatId = '${participants[0]}_${participants[1]}';
          DocumentSnapshot chatDoc = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();
          ChatModel? chat;
          if (chatDoc.exists) {
            chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
          }
          List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            MessageModel message = MessageModel.fromMap(doc.data());
            if (message.senderId == userId1 && message.receiverId == userId2 ||
                message.senderId == userId2 && message.receiverId == userId1) {
              bool includeMessage = true;

              if (chat != null) {
                DateTime? currentUserDeletedAt = chat.getDeletedAt(userId1);
                if (currentUserDeletedAt != null &&
                    message.timestamp.isBefore(currentUserDeletedAt)) {
                  includeMessage = false;
                }
              }
              if (includeMessage) {
                final deletedFor = List<String>.from(
                  (doc.data()['deletedFor'] as List<dynamic>?) ?? const [],
                );
                if (deletedFor.contains(userId1)) includeMessage = false;
                if (doc.data()['deletedForEveryone'] == true) {
                  message = message.copyWith(
                    content: 'This message was deleted',
                    isEdited: true,
                  );
                }
              }
              if (includeMessage) {
                messages.add(message);
              }
            }
          }
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  Future<void> deleteMessageForMe(String messageId, String userId) {
    return _redactDeletedMessage(messageId, deletedFor: userId);
  }

  Future<void> deleteMessageForEveryone(String messageId) {
    return _redactDeletedMessage(messageId, forEveryone: true);
  }

  Future<void> _redactDeletedMessage(
    String messageId, {
    String? deletedFor,
    bool forEveryone = false,
  }) async {
    final messageRef = _firestore.collection('messages').doc(messageId);
    final snapshot = await messageRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final senderId = data['senderId'] as String?;
    final receiverId = data['receiverId'] as String?;
    final timestamp = data['timestamp'] as int?;
    if (senderId == null || receiverId == null || timestamp == null) return;

    final updates = <String, dynamic>{
      'content': 'Message deleted',
      'replyToContent': FieldValue.delete(),
    };
    if (forEveryone) {
      updates['deletedForEveryone'] = true;
    } else if (deletedFor != null) {
      updates['deletedFor'] = FieldValue.arrayUnion([deletedFor]);
    }
    await messageRef.update(updates);

    final chatId = _chatIdFor(senderId, receiverId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnapshot = await chatRef.get();
    final chatData = chatSnapshot.data();
    if (chatData != null) {
      final chatUpdates = <String, dynamic>{};
      if (_matchesMessageTimestamp(chatData['lastMessageTime'], timestamp)) {
        chatUpdates.addAll({
          'lastMessage': 'Message deleted',
          'lastMessageTime': timestamp,
          'lastMessageSenderId': senderId,
        });
      }
      if (deletedFor == receiverId) {
        final unreadCount =
            (chatData['unreadCount'] as Map<String, dynamic>?)?[receiverId]
                as int? ??
            0;
        chatUpdates['unreadCount.$receiverId'] = unreadCount > 0
            ? unreadCount - 1
            : 0;
      }
      if (chatUpdates.isNotEmpty) await chatRef.update(chatUpdates);
    }
    final notificationRef = _firestore
        .collection('notifications')
        .doc(messageId);
    final notificationSnapshot = await notificationRef.get();
    if (notificationSnapshot.exists) {
      await notificationRef.update({
        'body': 'Message deleted',
        'isRead': true,
        'data.deletedMessage': true,
      });
    }
  }

  bool _matchesMessageTimestamp(dynamic storedTimestamp, int messageTimestamp) {
    if (storedTimestamp is int) return storedTimestamp == messageTimestamp;
    if (storedTimestamp is double) {
      return storedTimestamp.toInt() == messageTimestamp;
    }
    if (storedTimestamp is Timestamp) {
      return storedTimestamp.millisecondsSinceEpoch == messageTimestamp;
    }
    return false;
  }

  String _chatIdFor(String userId1, String userId2) {
    final participants = [userId1, userId2]..sort();
    return '${participants[0]}_${participants[1]}';
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to edit message: ${e.toString()}');
    }
  }

  //notifications collection

  Future<void> createNotification(NotificationModel notification) async {
    if (notification.type == NotificationType.newMessage) return;
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final notifications = <NotificationModel>[];
          for (final doc in snapshot.docs) {
            var notification = NotificationModel.fromMap(doc.data());
            if (notification.type == NotificationType.newMessage) continue;
            final actorId = _notificationActorId(notification);
            final actor = actorId == null ? null : await getUser(actorId);
            notification = _humanizeNotification(
              notification,
              actor?.displayName,
            );
            notifications.add(notification);
          }
          return notifications;
        });
  }

  String? _notificationActorId(NotificationModel notification) {
    final data = notification.data;
    for (final key in const ['senderId', 'userId', 'actorId']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    final markerIndex = notification.body.indexOf(' by ');
    if (markerIndex >= 0) {
      final legacyId = notification.body.substring(markerIndex + 4).trim();
      if (legacyId.isNotEmpty) return legacyId;
    }
    return null;
  }

  NotificationModel _humanizeNotification(
    NotificationModel notification,
    String? displayName,
  ) {
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : 'this user';
    switch (notification.type) {
      case NotificationType.newMessage:
        return notification.copyWith(
          title: 'New message from $name',
          body:
              notification.data['deletedMessage'] == true ||
                  notification.body == 'Message deleted'
              ? 'Message deleted'
              : notification.body,
        );
      case NotificationType.friendRequest:
        return notification.copyWith(
          body: 'You have a new friend request from $name',
        );
      case NotificationType.friendRequestAccepted:
        return notification.copyWith(
          body: 'Your friend request has been accepted by $name',
        );
      case NotificationType.friendRequestDeclined:
        return notification.copyWith(
          body: 'Your friend request has been declined by $name',
        );
      case NotificationType.friendRemoved:
        return notification.copyWith(
          body: 'You have been removed from $name\'s friend list.',
        );
    }
  }

  Future<void> deleteNotificationsByTypeAndUser(
    String userId,
    NotificationType type,
    String senderId,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .where('data.senderId', isEqualTo: senderId)
          .get();

      for (var doc in query.docs) {
        await _firestore.collection('notifications').doc(doc.id).delete();
      }
    } catch (e) {
      throw Exception(
        'Failed to delete notifications by type and user: ${e.toString()}',
      );
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      WriteBatch batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        'Failed to mark all notifications as read: ${e.toString()}',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  Future<void> _removeNotificationForCanceledRequest(
    String receiverId,
    String senderId,
  ) async {
    try {
      await deleteNotificationsByTypeAndUser(
        receiverId,
        NotificationType.friendRequest,
        senderId,
      );
    } catch (e) {
      /*throw Exception(
        'Failed to remove notification for canceled request: ${e.toString()}',
      );*/
      print(
        'Failed to remove notification for canceled request: ${e.toString()}',
      );
    }
  }
}
