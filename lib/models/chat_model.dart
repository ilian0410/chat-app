import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;

  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final Map<String, bool> deletedBy;
  final Map<String, DateTime?> deletedAt;
  final Map<String, DateTime?> lastSeenBy;
  final Map<String, bool> typing;
  final Map<String, bool> pinnedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.deletedBy = const {},
    this.deletedAt = const {},
    this.lastSeenBy = const {},
    this.typing = const {},
    this.pinnedBy = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt.map(
        (key, value) => MapEntry(key, value?.millisecondsSinceEpoch),
      ),
      'lastSeenBy': lastSeenBy.map(
        (key, value) => MapEntry(key, value?.millisecondsSinceEpoch),
      ),
      'typing': typing,
      'pinnedBy': pinnedBy,

      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static ChatModel fromMap(Map<String, dynamic> map) {
    Map<String, DateTime?> lastSeenMap = {};
    if (map['lastSeenBy'] != null) {
      Map<String, dynamic> rawLastSeen = Map<String, dynamic>.from(
        map['lastSeenBy'],
      );

      lastSeenMap = rawLastSeen.map(
        (key, value) => MapEntry(
          key,
          _parseDateTime(value),
        ),
      );
    }

    Map<String, DateTime?> deletedAtMap = {};
    if (map['deletedAt'] != null) {
      Map<String, dynamic> rawDeletedAt = Map<String, dynamic>.from(
        map['deletedAt'],
      );

      deletedAtMap = rawDeletedAt.map(
        (key, value) => MapEntry(
          key,
          _parseDateTime(value),
        ),
      );
    }
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: _parseDateTime(map['lastMessageTime']),
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      deletedBy: Map<String, bool>.from(map['deletedBy'] ?? {}),
      deletedAt: deletedAtMap,
      lastSeenBy: lastSeenMap,
      typing: Map<String, bool>.from(map['typing'] ?? {}),
      pinnedBy: Map<String, bool>.from(map['pinnedBy'] ?? {}),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    Map<String, bool>? deletedBy,
    Map<String, DateTime?>? deletedAt,
    Map<String, DateTime?>? lastSeenBy,
    Map<String, bool>? typing,
    Map<String, bool>? pinnedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      lastSeenBy: lastSeenBy ?? this.lastSeenBy,
      typing: typing ?? this.typing,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isDeletedBy(String userId) {
    return deletedBy[userId] ?? false;
  }

  DateTime? getDeletedAt(String userId) {
    return deletedAt[userId];
  }

  DateTime? getLastSeenBy(String userId) {
    return lastSeenBy[userId];
  }

  bool isTyping(String userId) => typing[userId] ?? false;
  bool isPinnedBy(String userId) => pinnedBy[userId] ?? false;

  bool isMessageSeen(String currentUserId, String otherUserId) {
    if (lastMessageSenderId == currentUserId && lastMessageTime != null) {
      final otherUserLastSeen = getLastSeenBy(otherUserId);
      if (otherUserLastSeen != null) {
        return otherUserLastSeen.isAfter(lastMessageTime!) ||
            otherUserLastSeen.isAtSameMomentAs(lastMessageTime!);
      }
    }
    return false;
  }
}
