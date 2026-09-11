enum MessageType { text }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;

  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final bool isEdited;
  final Map<String, String> reactions;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderId;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.isEdited = false,
    this.reactions = const {},
    this.editedAt,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isEdited': isEdited,
      'reactions': reactions,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSenderId': replyToSenderId,
    };
  }

  static MessageModel fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? true,
      isEdited: map['isEdited'] ?? false,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      replyToMessageId: map['replyToMessageId'] as String?,
      replyToContent: map['replyToContent'] as String?,
      replyToSenderId: map['replyToSenderId'] as String?,
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    bool? isEdited,
    Map<String, String>? reactions,
    DateTime? editedAt,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      isEdited: isEdited ?? this.isEdited,
      reactions: reactions ?? this.reactions,
      editedAt: editedAt ?? this.editedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
    );
  }
}
