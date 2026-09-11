import 'dart:async';

import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final TextEditingController _inputController;
  Timer? _typingTimer;
  final Map<String, double> _messageSwipeOffsets = {};

  static const double _replySwipeThreshold = 44;
  static const double _maxReplySwipeOffset = 56;

  ChatController get controller => Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _typingTimer?.cancel();
    controller.setTyping(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.otherUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(child: Text(controller.error.value)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: AppTheme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () =>
              Get.toNamed(AppRoutes.userProfile, arguments: {'user': user}),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(.12),
                foregroundColor: AppTheme.primaryColor,
                child: Text(
                  user.displayName.isEmpty
                      ? '?'
                      : user.displayName[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName),
                  Obx(() {
                    final presence = controller.presenceUser.value ?? user;
                    return Text(
                      presence.isOnline
                          ? 'Online'
                          : _lastSeenLabel(presence.lastSeen),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: presence.isOnline
                            ? AppTheme.successColor
                            : AppTheme.textSecondaryColor,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Obx(() {
            final isBlocked = controller.isBlocked.value;
            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle-block') {
                  controller.toggleBlocked();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle-block',
                  child: Text(isBlocked ? 'Unblock user' : 'Block user'),
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error.value.isNotEmpty &&
                  controller.messages.isEmpty) {
                return Center(child: Text(controller.error.value));
              }
              if (controller.messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 48,
                          color: AppTheme.primaryColor.withOpacity(.55),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Start the conversation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send a message to ${user.displayName} and start chatting.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                itemCount: controller.messages.length,
                itemBuilder: (_, index) {
                  final message = controller.messages[index];
                  final isMine = message.senderId == controller.currentUserId;
                  final isDeleted =
                      message.isEdited &&
                      message.content == 'This message was deleted';
                  return GestureDetector(
                    onLongPress: () => _showMessageActions(message),
                    onHorizontalDragStart: (_) {
                      _messageSwipeOffsets[message.id] = 0;
                    },
                    onHorizontalDragUpdate: (details) {
                      final currentOffset =
                          _messageSwipeOffsets[message.id] ?? 0;
                      final nextOffset = (currentOffset + details.delta.dx)
                          .clamp(-_maxReplySwipeOffset, _maxReplySwipeOffset);
                      if (nextOffset != currentOffset && mounted) {
                        setState(() {
                          _messageSwipeOffsets[message.id] = nextOffset;
                        });
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      final offset = _messageSwipeOffsets[message.id] ?? 0;
                      if (offset.abs() >= _replySwipeThreshold) {
                        controller.selectReply(message);
                      }
                      if (mounted) {
                        setState(() {
                          _messageSwipeOffsets[message.id] = 0;
                        });
                      }
                    },
                    onHorizontalDragCancel: () {
                      if (mounted) {
                        setState(() {
                          _messageSwipeOffsets[message.id] = 0;
                        });
                      }
                    },
                    child: Transform.translate(
                      offset: Offset(_messageSwipeOffsets[message.id] ?? 0, 0),
                      child: Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .78,
                          ),
                          child: IntrinsicWidth(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDeleted
                                        ? const Color(0xFFE8E7EC)
                                        : isMine
                                        ? AppTheme.primaryColor
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(
                                        isMine ? 18 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMine ? 4 : 18,
                                      ),
                                    ),
                                    border: isDeleted
                                        ? Border.all(
                                            color: const Color(0xFFD4D1DA),
                                          )
                                        : isMine
                                        ? null
                                        : Border.all(
                                            color: AppTheme.borderColor,
                                          ),
                                    boxShadow: isDeleted
                                        ? const []
                                        : const [
                                            BoxShadow(
                                              color: Color(0x10000000),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isDeleted &&
                                          message.replyToContent != null)
                                        _quotedPreview(
                                          message.replyToContent!,
                                          isMine,
                                        ),
                                      Text(
                                        isDeleted
                                            ? 'This message was deleted'
                                            : message.content,
                                        style: TextStyle(
                                          color: isDeleted
                                              ? AppTheme.textSecondaryColor
                                              : isMine
                                              ? Colors.white
                                              : AppTheme.textPrimaryColor,
                                          fontStyle: isDeleted
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTime(message.timestamp),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMine
                                                  ? Colors.white70
                                                  : AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                          if (isMine) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              message.isRead
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 14,
                                              color: message.isRead
                                                  ? const Color(0xFFB9E7FF)
                                                  : Colors.white70,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              message.isRead
                                                  ? 'Seen'
                                                  : message.isDelivered
                                                  ? 'Delivered'
                                                  : 'Sent',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMine
                                                    ? Colors.white70
                                                    : AppTheme
                                                          .textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (message.reactions.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    right: isMine ? 8 : null,
                                    left: isMine ? null : 8,
                                    child: Transform.translate(
                                      offset: const Offset(0, -2),
                                      child: _reactionSummary(
                                        message.reactions,
                                        isMine,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Obx(
            () => controller.isOtherUserTyping.value
                ? const Padding(
                    padding: EdgeInsets.only(left: 18, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Typing...'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: AppTheme.cardColor,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => controller.isBlocked.value
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Messaging is unavailable while this user is blocked.',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => controller.replyTo.value == null
                        ? const SizedBox.shrink()
                        : Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.reply, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.replyTo.value!.content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: controller.clearReply,
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          textInputAction: TextInputAction.send,
                          onChanged: _handleTyping,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Write a message',
                            filled: true,
                            fillColor: const Color(0xFFF5F3FB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(
                        () => SizedBox(
                          width: 46,
                          height: 46,
                          child: IconButton(
                            onPressed:
                                controller.isSending.value ||
                                    controller.isBlocked.value
                                ? null
                                : _send,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.primaryColor
                                  .withOpacity(.45),
                            ),
                            icon: controller.isSending.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.arrow_upward_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final content = _inputController.text;
    if (content.trim().isEmpty) return;
    controller
        .sendMessage(content)
        .then((_) {
          _inputController.clear();
        })
        .catchError((_) {});
  }

  void _handleTyping(String value) {
    _typingTimer?.cancel();
    if (value.trim().isEmpty) {
      controller.setTyping(false);
      return;
    }
    controller.setTyping(true);
    _typingTimer = Timer(const Duration(milliseconds: 900), () {
      controller.setTyping(false);
    });
  }

  Widget _quotedPreview(String content, bool isMine) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isMine ? Colors.white70 : AppTheme.primaryColor,
            width: 2,
          ),
        ),
      ),
      child: Text(
        content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isMine ? Colors.white70 : AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  Future<void> _showMessageActions(MessageModel message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final reaction in const [
                    '👍',
                    '❤️',
                    '😂',
                    '😮',
                    '😢',
                    '😡',
                  ])
                    IconButton(
                      tooltip: reaction,
                      onPressed: () =>
                          Navigator.pop(context, 'react:$reaction'),
                      icon: Text(
                        reaction,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Remove reaction',
                    onPressed: () => Navigator.pop(context, 'react:'),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for me'),
              onTap: () => Navigator.pop(context, 'me'),
            ),
            if (message.senderId == controller.currentUserId)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Delete for everyone'),
                onTap: () => Navigator.pop(context, 'everyone'),
              ),
          ],
        ),
      ),
    );
    if (action?.startsWith('react:') == true) {
      final reaction = action!.substring('react:'.length);
      await controller.setReaction(message, reaction.isEmpty ? null : reaction);
      return;
    }
    if (action == 'reply') controller.selectReply(message);
    if (action == 'me') await controller.deleteForMe(message);
    if (action == 'everyone') await controller.deleteForEveryone(message);
  }

  Widget _reactionSummary(Map<String, String> reactions, bool isMine) {
    final counts = <String, int>{};
    for (final reaction in reactions.values) {
      counts[reaction] = (counts[reaction] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: .18)
            : const Color(0xFFF1EFF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in counts.entries) ...[
            Text(entry.key, style: const TextStyle(fontSize: 13)),
            if (entry.value > 1)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  String _lastSeenLabel(DateTime lastSeen) {
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inMinutes < 1) return 'Last seen just now';
    if (difference.inHours < 1) return 'Last seen ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Last seen ${difference.inHours}h ago';
    if (difference.inDays < 7) return 'Last seen ${difference.inDays}d ago';
    return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}
