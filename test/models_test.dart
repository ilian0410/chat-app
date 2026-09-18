import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/notification_model.dart';

void main() {
  group('ChatModel date resilience', () {
    test('handles null lastMessageTime without defaulting to 1970', () {
      final chat = ChatModel.fromMap({
        'id': 'c1',
        'participants': ['u1', 'u2'],
        'lastMessage': null,
        'lastMessageTime': null,
        'createdAt': 1700000000000,
        'updatedAt': 1700000000000,
      });

      expect(chat.lastMessageTime, isNull);
      expect(chat.isMessageSeen('u1', 'u2'), isFalse);
    });

    test('handles Timestamp objects for lastMessageTime, createdAt, and lastSeenBy', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final chat = ChatModel.fromMap({
        'id': 'c2',
        'participants': ['u1', 'u2'],
        'lastMessage': 'hello',
        'lastMessageSenderId': 'u1',
        'lastMessageTime': timestamp,
        'lastSeenBy': {'u2': timestamp},
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      expect(chat.lastMessageTime, isNotNull);
      expect(chat.lastMessageTime!.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      expect(chat.isMessageSeen('u1', 'u2'), isTrue);
    });
  });

  group('MessageModel date resilience', () {
    test('handles Timestamp and integer milliseconds', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final msgFromTimestamp = MessageModel.fromMap({
        'id': 'm1',
        'senderId': 'u1',
        'receiverId': 'u2',
        'content': 'hi',
        'timestamp': timestamp,
        'editedAt': timestamp,
      });

      expect(msgFromTimestamp.timestamp.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      expect(msgFromTimestamp.editedAt, isNotNull);

      final msgFromMillis = MessageModel.fromMap({
        'id': 'm2',
        'senderId': 'u1',
        'receiverId': 'u2',
        'content': 'hi',
        'timestamp': 1700000000000,
      });

      expect(msgFromMillis.timestamp.millisecondsSinceEpoch, equals(1700000000000));
      expect(msgFromMillis.editedAt, isNull);
    });
  });

  group('FriendRequestModel and FriendshipModel date resilience', () {
    test('parses Timestamp correctly', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final req = FriendRequestModel.fromMap({
        'id': 'r1',
        'senderId': 'u1',
        'receiverId': 'u2',
        'createdAt': timestamp,
        'respondedAt': timestamp,
      });

      expect(req.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      expect(req.respondedAt, isNotNull);

      final friendship = FriendshipModel.fromMap({
        'id': 'f1',
        'user1Id': 'u1',
        'user2Id': 'u2',
        'createdAt': timestamp,
      });

      expect(friendship.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });

  group('NotificationModel resilience', () {
    test('safely falls back from unknown type and parses Timestamp', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      final notif = NotificationModel.fromMap({
        'id': 'n1',
        'userId': 'u1',
        'title': 'Test',
        'body': 'Test body',
        'type': 'unknown_type',
        'createdAt': timestamp,
      });

      expect(notif.type, equals(NotificationType.friendRequest));
      expect(notif.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });
}
