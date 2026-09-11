import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String bio;
  final String photoURL;
  final List<String> blockedUserIds;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.bio = '',
    this.photoURL = "",
    this.blockedUserIds = const [],
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'photoURL': photoURL,
      'blockedUserIds': blockedUserIds,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      photoURL: map['photoURL'] ?? '',
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? const []),
      isOnline: map['isOnline'] ?? false,

      lastSeen: map['lastSeen'] is Timestamp
          ? (map['lastSeen'] as Timestamp).toDate()
          : map['lastSeen'] is String
          ? DateTime.parse(map['lastSeen'])
          : DateTime.fromMillisecondsSinceEpoch(map['lastSeen']),

      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? bio,
    String? photoURL,
    List<String>? blockedUserIds,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoURL: photoURL ?? this.photoURL,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
