import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final TextEditingController _inputController;

  ChatController get controller => Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
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
        title: Row(
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
                Text(
                  user.isOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: user.isOnline
                        ? AppTheme.successColor
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .78,
                      ),
                      child: IntrinsicWidth(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? AppTheme.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMine ? 18 : 4),
                              bottomRight: Radius.circular(isMine ? 4 : 18),
                            ),
                            border: isMine
                                ? null
                                : Border.all(color: AppTheme.borderColor),
                            boxShadow: const [
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
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMine ? Colors.white : null,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.isRead
                                          ? Icons.done_all
                                          : Icons.done,
                                      size: 14,
                                      color: message.isRead
                                          ? const Color(0xFFB9E7FF)
                                          : Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: AppTheme.cardColor,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
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
                        onPressed: controller.isSending.value ? null : _send,
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

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
  }
}
