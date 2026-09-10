import 'dart:async';

import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = const Uuid();

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxString error = ''.obs;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  final Set<String> _readMessageIds = <String>{};
  bool _isMarkingMessagesRead = false;

  UserModel? otherUser;
  String? chatId;
  String get currentUserId => _authController.user?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final argumentUser = arguments['otherUser'];
    if (argumentUser is UserModel) {
      otherUser = argumentUser;
    }
    chatId = arguments['chatId'] as String?;
    if (otherUser == null) {
      error.value = 'This conversation is unavailable.';
      isLoading.value = false;
    } else {
      _loadMessages();
    }
  }

  @override
  void onReady() {
    super.onReady();
    markMessagesAsRead();
  }

  void _loadMessages() {
    final user = otherUser;
    if (currentUserId.isEmpty || user == null) {
      error.value = 'You must be signed in to view this chat.';
      isLoading.value = false;
      return;
    }

    _messagesSubscription = _firestoreService
        .getMessagesStream(currentUserId, user.id)
        .listen(
          (value) {
            isLoading.value = false;
            error.value = '';
            messages.assignAll(value);
            markMessagesAsRead();
          },
          onError: (Object streamError, StackTrace stackTrace) {
            isLoading.value = false;
            error.value = streamError.toString();
          },
        );
  }

  Future<void> sendMessage(String content) async {
    final trimmedContent = content.trim();
    final user = otherUser;
    if (trimmedContent.isEmpty ||
        currentUserId.isEmpty ||
        user == null ||
        isSending.value) {
      return;
    }

    isSending.value = true;
    error.value = '';
    try {
      chatId ??= await _firestoreService.createOrGetChat(
        currentUserId,
        user.id,
      );
      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: user.id,
        content: trimmedContent,
        timestamp: DateTime.now(),
      );
      await _firestoreService.sendMessage(chatId!, message);
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> markMessagesAsRead() async {
    if (currentUserId.isEmpty || _isMarkingMessagesRead) return;
    final unreadMessages = messages
        .where(
          (message) =>
              message.receiverId == currentUserId &&
              !message.isRead &&
              !_readMessageIds.contains(message.id),
        )
        .toList();
    if (unreadMessages.isEmpty) return;

    _isMarkingMessagesRead = true;
    try {
      for (final message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
        _readMessageIds.add(message.id);
      }
      if (chatId != null) {
        await _firestoreService.restoreUnreadCount(chatId!, currentUserId);
        await _firestoreService.updateUserLastSeen(chatId!, currentUserId);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      _isMarkingMessagesRead = false;
    }
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    super.onClose();
  }
}
