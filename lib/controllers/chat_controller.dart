import 'dart:async';

import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/chat_model.dart';
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
  final RxBool isOtherUserTyping = false.obs;
  final Rx<UserModel?> presenceUser = Rx<UserModel?>(null);
  final Rx<MessageModel?> replyTo = Rx<MessageModel?>(null);
  final RxBool isBlocked = false.obs;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  StreamSubscription<ChatModel?>? _chatSubscription;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<bool>? _blockedSubscription;
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
      _initChat();
    }
  }

  Future<void> _initChat() async {
    final user = otherUser;
    if (currentUserId.isEmpty || user == null) {
      error.value = 'You must be signed in to view this chat.';
      isLoading.value = false;
      return;
    }

    try {
      if (chatId == null) {
        chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );
      }
    } catch (_) {}

   _loadMessages();
_loadPresence();
await _markConversationAsRead();
  }

  void _loadPresence() {
    final user = otherUser;
    if (user == null || chatId == null) return;
    if (_chatSubscription != null || _userSubscription != null) return;
    _chatSubscription = _firestoreService.getChatStream(chatId!).listen((chat) {
      isOtherUserTyping.value = chat?.isTyping(user.id) ?? false;
    });
    _userSubscription = _firestoreService.getUserStream(user.id).listen((
      value,
    ) {
      if (value != null) {
        otherUser = value;
        presenceUser.value = value;
      }
    });
    _blockedSubscription = _firestoreService
        .getBlockedStatusStream(currentUserId, user.id)
        .listen((blocked) => isBlocked.value = blocked);
  }

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> _markConversationAsRead() async {
    final user = otherUser;
    final id = chatId;
    if (currentUserId.isEmpty || user == null || id == null) return;
    try {
      await _firestoreService.markConversationAsRead(
        id,
        currentUserId,
        user.id,
      );
    } catch (e) {
      error.value = e.toString();
    }
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
        isBlocked.value ||
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
        replyToMessageId: replyTo.value?.id,
        replyToContent: replyTo.value?.content,
        replyToSenderId: replyTo.value?.senderId,
      );
      await _firestoreService.sendMessage(chatId!, message);
      replyTo.value = null;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> setTyping(bool value) async {
    final user = otherUser;
    if (currentUserId.isEmpty || user == null) return;
    try {
      if (chatId == null) {
        chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );
        _loadPresence();
      }
      await _firestoreService.updateTyping(chatId!, currentUserId, value);
    } catch (_) {}
  }

  void selectReply(MessageModel message) => replyTo.value = message;

  void clearReply() => replyTo.value = null;

  Future<void> setReaction(MessageModel message, String? reaction) async {
    if (currentUserId.isEmpty) return;
    try {
      await _firestoreService.setMessageReaction(
        message.id,
        currentUserId,
        reaction,
      );
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> toggleBlocked() async {
    final user = otherUser;
    if (user == null || currentUserId.isEmpty) return;
    try {
      final blocked = !isBlocked.value;
      await _firestoreService.setUserBlocked(currentUserId, user.id, blocked);
      isBlocked.value = blocked;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteForMe(MessageModel message) async {
    await _firestoreService.deleteMessageForMe(message.id, currentUserId);
  }

  Future<void> deleteForEveryone(MessageModel message) async {
    if (message.senderId != currentUserId) return;
    await _firestoreService.deleteMessageForEveryone(message.id);
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
    _chatSubscription?.cancel();
    _userSubscription?.cancel();
    _blockedSubscription?.cancel();
    setTyping(false);
    super.onClose();
  }
}
