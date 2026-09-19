import 'dart:async';

import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final TextEditingController _inputController;
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _hasInitiallyScrolled = false;
  bool _hasText = false;
  final Map<String, double> _messageSwipeOffsets = {};

  static const double _replySwipeThreshold = 48.0;
  static const double _maxReplySwipeOffset = 64.0;

  ChatController get controller => Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _typingTimer?.cancel();
    _scrollController.dispose();
    controller.setTyping(false);
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      } else {
        _scrollController.jumpTo(maxScroll);
      }
    });
  }

  void _scrollToInitialPosition() {
    if (_hasInitiallyScrolled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        _hasInitiallyScrolled = true;
      }
    });
  }

  void _send() {
    final content = _inputController.text;
    if (content.trim().isEmpty) return;
    _inputController.clear();
    controller.sendMessage(content).then((_) {
      _scrollToBottom();
    }).catchError((_) {});
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

  @override
  Widget build(BuildContext context) {
    final user = controller.otherUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Obx(() => Text(controller.error.value)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: _buildAppBar(context, user),
        body: Column(
          children: [
            // ── Messages Stream ──────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  );
                }

                if (controller.error.value.isNotEmpty &&
                    controller.messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        controller.error.value,
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                _scrollToInitialPosition();

                if (controller.messages.isEmpty) {
                  return _EmptyConversationView(
                    user: user,
                    onSuggestionTap: (text) {
                      _inputController.text = text;
                      _inputController.selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                      _handleTyping(text);
                    },
                  );
                }

                final messages = controller.messages;
                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == controller.currentUserId;

                    // Date separator check
                    final showDateSeparator = _shouldShowDateSeparator(
                      index > 0 ? messages[index - 1] : null,
                      message,
                    );

                    // Message grouping check (same sender within 2 mins)
                    final isGroupedWithNext = _isGroupedWithNext(
                      message,
                      index < messages.length - 1 ? messages[index + 1] : null,
                    );
                    final isGroupedWithPrevious = _isGroupedWithPrevious(
                      message,
                      index > 0 ? messages[index - 1] : null,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(timestamp: message.timestamp),
                        _MessageBubble(
                          message: message,
                          isMine: isMine,
                          isGroupedWithNext: isGroupedWithNext,
                          isGroupedWithPrevious: isGroupedWithPrevious,
                          swipeOffset: _messageSwipeOffsets[message.id] ?? 0.0,
                          onSwipeUpdate: (delta) {
                            final current = _messageSwipeOffsets[message.id] ?? 0;
                            final next = (current + delta).clamp(
                              -_maxReplySwipeOffset,
                              _maxReplySwipeOffset,
                            );
                            if (next != current && mounted) {
                              setState(() {
                                _messageSwipeOffsets[message.id] = next;
                              });
                            }
                          },
                          onSwipeEnd: () {
                            final offset = _messageSwipeOffsets[message.id] ?? 0;
                            if (offset.abs() >= _replySwipeThreshold) {
                              HapticFeedback.lightImpact();
                              controller.selectReply(message);
                            }
                            if (mounted) {
                              setState(() {
                                _messageSwipeOffsets[message.id] = 0;
                              });
                            }
                          },
                          onLongPress: () => _showMessageActions(message),
                          onReactionTap: (reaction) {
                            controller.setReaction(
                              message,
                              message.reactions[controller.currentUserId] == reaction
                                  ? null
                                  : reaction,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }),
            ),

            // ── Typing Indicator ─────────────────────────────────────────
            Obx(() {
              if (!controller.isOtherUserTyping.value) {
                return const SizedBox.shrink();
              }
              return _TypingBubble(userName: user.displayName);
            }),

            // ── Composer / Blocked Footer ────────────────────────────────
            Obx(() {
              if (controller.isBlocked.value) {
                return _BlockedFooter(
                  onUnblock: controller.toggleBlocked,
                );
              }
              return _ChatComposer(
                inputController: _inputController,
                hasText: _hasText,
                onChanged: _handleTyping,
                onSend: _send,
                replyMessage: controller.replyTo.value,
                onClearReply: controller.clearReply,
                isSending: controller.isSending.value,
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(MessageModel? prev, MessageModel curr) {
    if (prev == null) return true;
    final prevDate = DateTime(
      prev.timestamp.year,
      prev.timestamp.month,
      prev.timestamp.day,
    );
    final currDate = DateTime(
      curr.timestamp.year,
      curr.timestamp.month,
      curr.timestamp.day,
    );
    return currDate.isAfter(prevDate);
  }

  bool _isGroupedWithNext(MessageModel curr, MessageModel? next) {
    if (next == null) return false;
    if (curr.senderId != next.senderId) return false;
    final diff = next.timestamp.difference(curr.timestamp);
    return diff.inMinutes < 2;
  }

  bool _isGroupedWithPrevious(MessageModel curr, MessageModel? prev) {
    if (prev == null) return false;
    if (curr.senderId != prev.senderId) return false;
    final diff = curr.timestamp.difference(prev.timestamp);
    return diff.inMinutes < 2;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel user) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppTheme.textPrimaryColor,
                ),
                onPressed: () => Get.back(),
                tooltip: 'Back',
              ),

              // User avatar & title info (tappable to view profile)
              Expanded(
                child: InkWell(
                  onTap: () => Get.toNamed(
                    AppRoutes.userProfile,
                    arguments: {'user': user},
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        _buildHeaderAvatar(user),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Obx(() {
                                final presence =
                                    controller.presenceUser.value ?? user;
                                final isOnline = presence.isOnline;
                                return Text(
                                  isOnline
                                      ? 'Active now'
                                      : _formatLastSeen(presence.lastSeen),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOnline
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFF8E8E93),
                                    fontWeight: isOnline
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // More options menu
              Obx(() {
                final isBlocked = controller.isBlocked.value;
                return PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppTheme.textPrimaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'profile') {
                      Get.toNamed(
                        AppRoutes.userProfile,
                        arguments: {'user': user},
                      );
                    } else if (value == 'block') {
                      controller.toggleBlocked();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 19,
                            color: AppTheme.textPrimaryColor,
                          ),
                          SizedBox(width: 10),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            isBlocked
                                ? Icons.check_circle_outline_rounded
                                : Icons.block_rounded,
                            size: 19,
                            color: isBlocked
                                ? AppTheme.primaryColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isBlocked ? 'Unblock user' : 'Block user',
                            style: TextStyle(
                              color: isBlocked
                                  ? AppTheme.primaryColor
                                  : AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(UserModel user) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return Obx(() {
      final presence = controller.presenceUser.value ?? user;
      final isOnline = presence.isOnline;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
            ),
            child: user.photoURL.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.photoURL,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      );
    });
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inHours < 1) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Last seen yesterday';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  Future<void> _showMessageActions(MessageModel message) async {
    final isMine = message.senderId == controller.currentUserId;
    final isDeleted =
        message.isEdited && message.content == 'This message was deleted';

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MessageActionSheet(
        message: message,
        isMine: isMine,
        isDeleted: isDeleted,
      ),
    );

    if (result == null) return;

    if (result.startsWith('react:')) {
      final reaction = result.substring('react:'.length);
      await controller.setReaction(
        message,
        reaction.isEmpty ? null : reaction,
      );
    } else if (result == 'reply') {
      controller.selectReply(message);
    } else if (result == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.content));
      Get.rawSnackbar(
        message: 'Message copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
    } else if (result == 'me') {
      await controller.deleteForMe(message);
    } else if (result == 'everyone') {
      await controller.deleteForEveryone(message);
    }
  }
}

// ── Date Separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime timestamp;
  const _DateSeparator({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatSeparator(timestamp),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF636E72),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  String _formatSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return 'Today';
    if (messageDate == yesterday) return 'Yesterday';

    final diff = today.difference(messageDate);
    if (diff.inDays < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return weekdays[date.weekday - 1];
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isGroupedWithNext;
  final bool isGroupedWithPrevious;
  final double swipeOffset;
  final ValueChanged<double> onSwipeUpdate;
  final VoidCallback onSwipeEnd;
  final VoidCallback onLongPress;
  final ValueChanged<String> onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isGroupedWithNext,
    required this.isGroupedWithPrevious,
    required this.swipeOffset,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
    required this.onLongPress,
    required this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted =
        message.isEdited && message.content == 'This message was deleted';
    final hasReactions = message.reactions.isNotEmpty;

    // Radius logic for organic grouping
    final borderRadius = _calculateBorderRadius();

    return Padding(
      padding: EdgeInsets.only(
        bottom: hasReactions
            ? 14
            : (isGroupedWithNext ? 3.0 : 8.0),
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        onHorizontalDragUpdate: (details) => onSwipeUpdate(details.delta.dx),
        onHorizontalDragEnd: (_) => onSwipeEnd(),
        onHorizontalDragCancel: onSwipeEnd,
        child: Stack(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            // Reply icon revealed behind bubble on swipe
            if (swipeOffset.abs() > 4)
              Positioned(
                left: isMine ? null : 8,
                right: isMine ? 8 : null,
                child: Opacity(
                  opacity: (swipeOffset.abs() / 48.0).clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),

            // Translating bubble
            Transform.translate(
              offset: Offset(swipeOffset, 0),
              child: Align(
                alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.76,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDeleted
                              ? const Color(0xFFE5E5EA)
                              : isMine
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                          borderRadius: borderRadius,
                          border: (!isMine && !isDeleted)
                              ? Border.all(
                                  color: const Color(0xFFE5E5EA),
                                  width: 0.5,
                                )
                              : null,
                          boxShadow: isDeleted
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Quoted Reply Banner ───────────────────────
                            if (!isDeleted && message.replyToContent != null)
                              _QuotedPreview(
                                content: message.replyToContent!,
                                isMine: isMine,
                              ),

                            // ── Content + Timestamp/Status ───────────────
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              spacing: 8,
                              runSpacing: 2,
                              children: [
                                Text(
                                  isDeleted
                                      ? 'This message was deleted'
                                      : message.content,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDeleted
                                        ? const Color(0xFF8E8E93)
                                        : isMine
                                            ? Colors.white
                                            : AppTheme.textPrimaryColor,
                                    fontStyle: isDeleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    height: 1.3,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isMine
                                              ? Colors.white.withValues(alpha: 0.72)
                                              : const Color(0xFF8E8E93),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      if (isMine) ...[
                                        const SizedBox(width: 4),
                                        _buildDeliveryStatusIcon(),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Reactions Floating Badge ────────────────────────
                      if (hasReactions)
                        Positioned(
                          bottom: -10,
                          right: isMine ? 6 : null,
                          left: isMine ? null : 6,
                          child: _ReactionSummaryBadge(
                            reactions: message.reactions,
                            isMine: isMine,
                            onTap: onReactionTap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BorderRadius _calculateBorderRadius() {
    const double outerR = 17.0;
    const double innerR = 5.0;

    if (isMine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(outerR),
        topRight: Radius.circular(isGroupedWithPrevious ? innerR : outerR),
        bottomLeft: const Radius.circular(outerR),
        bottomRight: Radius.circular(isGroupedWithNext ? innerR : 4.0),
      );
    } else {
      return BorderRadius.only(
        topLeft: Radius.circular(isGroupedWithPrevious ? innerR : outerR),
        topRight: const Radius.circular(outerR),
        bottomLeft: Radius.circular(isGroupedWithNext ? innerR : 4.0),
        bottomRight: const Radius.circular(outerR),
      );
    }
  }

  Widget _buildDeliveryStatusIcon() {
    final isSeen = message.isRead;
    final isDelivered = message.isDelivered;

    if (isSeen) {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Color(0xFFB9E7FF),
      );
    } else if (isDelivered) {
      return Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Colors.white.withValues(alpha: 0.72),
      );
    } else {
      return Icon(
        Icons.done_rounded,
        size: 14,
        color: Colors.white.withValues(alpha: 0.72),
      );
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final min = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}

// ── Quoted Preview Inside Bubble ──────────────────────────────────────────────

class _QuotedPreview extends StatelessWidget {
  final String content;
  final bool isMine;

  const _QuotedPreview({
    required this.content,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMine ? Colors.white : AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Text(
        content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isMine
              ? Colors.white.withValues(alpha: 0.9)
              : const Color(0xFF636E72),
          height: 1.25,
        ),
      ),
    );
  }
}

// ── Reaction Summary Badge ────────────────────────────────────────────────────

class _ReactionSummaryBadge extends StatelessWidget {
  final Map<String, String> reactions;
  final bool isMine;
  final ValueChanged<String> onTap;

  const _ReactionSummaryBadge({
    required this.reactions,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final r in reactions.values) {
      counts[r] = (counts[r] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in counts.entries) ...[
            GestureDetector(
              onTap: () => onTap(entry.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 12)),
                    if (entry.value > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF636E72),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing Indicator Bubble ───────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final String userName;
  const _TypingBubble({required this.userName});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(1),
              const SizedBox(width: 4),
              _buildDot(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = (_animController.value - (index * 0.2)) % 1.0;
        final opacity = progress < 0.5
            ? (0.3 + (progress * 1.4)).clamp(0.3, 1.0)
            : (1.0 - ((progress - 0.5) * 1.4)).clamp(0.3, 1.0);
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ── Composer / Input Bar ──────────────────────────────────────────────────────

class _ChatComposer extends StatelessWidget {
  final TextEditingController inputController;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final MessageModel? replyMessage;
  final VoidCallback onClearReply;
  final bool isSending;

  const _ChatComposer({
    required this.inputController,
    required this.hasText,
    required this.onChanged,
    required this.onSend,
    required this.replyMessage,
    required this.onClearReply,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Active Reply Preview ──────────────────────────────────
            if (replyMessage != null)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9FB),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Replying to message',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            replyMessage!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF636E72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF8E8E93),
                      ),
                      onPressed: onClearReply,
                      tooltip: 'Cancel reply',
                    ),
                  ],
                ),
              ),

            // ── Input field + Send button ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: inputController,
                        onChanged: onChanged,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textPrimaryColor,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(
                            color: Color(0xFFAEAEB2),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasText && !isSending
                          ? AppTheme.primaryColor
                          : const Color(0xFFE5E5EA),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (hasText && !isSending) ? onSend : null,
                        borderRadius: BorderRadius.circular(19),
                        child: Center(
                          child: isSending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
                                  color: hasText
                                      ? Colors.white
                                      : const Color(0xFFAEAEB2),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blocked Footer ────────────────────────────────────────────────────────────

class _BlockedFooter extends StatelessWidget {
  final VoidCallback onUnblock;
  const _BlockedFooter({required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(
              Icons.block_rounded,
              size: 18,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'You blocked this contact.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
            TextButton(
              onPressed: onUnblock,
              child: const Text(
                'Unblock',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Conversation View ───────────────────────────────────────────────────

class _EmptyConversationView extends StatelessWidget {
  final UserModel user;
  final ValueChanged<String> onSuggestionTap;

  const _EmptyConversationView({
    required this.user,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
              ),
              child: user.photoURL.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 14),

            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'No messages here yet.\nSay hello and start the conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Starter prompt chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _StarterChip(
                  label: '👋 Say Hello',
                  onTap: () => onSuggestionTap('Hello! 👋'),
                ),
                _StarterChip(
                  label: 'How are you?',
                  onTap: () => onSuggestionTap('Hey, how are you?'),
                ),
                _StarterChip(
                  label: "What's up?",
                  onTap: () => onSuggestionTap("What's up?"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StarterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }
}

// ── Message Action Modal Bottom Sheet ─────────────────────────────────────────

class _MessageActionSheet extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isDeleted;

  const _MessageActionSheet({
    required this.message,
    required this.isMine,
    required this.isDeleted,
  });

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Emoji Reaction Bar
            if (!isDeleted) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final emoji in _emojis)
                        InkWell(
                          onTap: () => Navigator.pop(context, 'react:$emoji'),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      InkWell(
                        onTap: () => Navigator.pop(context, 'react:'),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 22,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE5E5EA)),
            ],

            // Actions list
            if (!isDeleted) ...[
              _ActionTile(
                icon: Icons.reply_rounded,
                label: 'Reply',
                onTap: () => Navigator.pop(context, 'reply'),
              ),
              _ActionTile(
                icon: Icons.copy_rounded,
                label: 'Copy text',
                onTap: () => Navigator.pop(context, 'copy'),
              ),
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: Color(0xFFE5E5EA),
              ),
            ],

            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete for me',
              iconColor: AppTheme.errorColor,
              textColor: AppTheme.errorColor,
              onTap: () => Navigator.pop(context, 'me'),
            ),

            if (isMine && !isDeleted)
              _ActionTile(
                icon: Icons.delete_forever_rounded,
                label: 'Delete for everyone',
                iconColor: AppTheme.errorColor,
                textColor: AppTheme.errorColor,
                onTap: () => Navigator.pop(context, 'everyone'),
              ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? AppTheme.textPrimaryColor,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: textColor ?? AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
