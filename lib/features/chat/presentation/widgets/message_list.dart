import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/message.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../../core/utils/datetime_helper.dart';
import '../../../../core/utils/log_utils.dart';
import 'message_bubble.dart';

/// Widget hiển thị danh sách tin nhắn trong chat
class MessageList extends StatefulWidget {
  /// Danh sách tin nhắn cần hiển thị
  final List<Message> messages;

  /// Callback khi tin nhắn được xem
  final Function(String) onMessageSeen;

  /// ScrollController cho ListView
  final ScrollController? scrollController;

  /// ID của chatroom
  final String chatId;

  /// Có phải là group chat không
  final bool isGroup;

  const MessageList({
    Key? key,
    required this.messages,
    required this.onMessageSeen,
    required this.chatId,
    this.scrollController,
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  /// ID của người dùng hiện tại
  late final String _currentUserId;

  /// Biến theo dõi trạng thái mounted
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    logDebug(LogService.CHAT,
        '[MESSAGE_LIST] Initialized with chatId: ${widget.chatId}, isGroup: ${widget.isGroup}');
    logDebug(
        LogService.CHAT, '[MESSAGE_LIST] Current user ID: $_currentUserId');
    _checkForUnseenMessages();
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    logDebug(LogService.CHAT,
        '[MESSAGE_LIST] Widget updated, messages count: ${widget.messages.length}');

    // Nếu số lượng tin nhắn thay đổi, kiểm tra tin nhắn chưa xem
    if (oldWidget.messages.length != widget.messages.length) {
      logDebug(LogService.CHAT,
          '[MESSAGE_LIST] Message count changed, checking for unseen messages');
      _checkForUnseenMessages();
    }
  }

  @override
  void dispose() {
    logDebug(LogService.CHAT, '[MESSAGE_LIST] Disposing message list');
    _isMounted = false;
    super.dispose();
  }

  /// Kiểm tra và cập nhật trạng thái đã xem cho các tin nhắn mới
  void _checkForUnseenMessages() {
    logDebug(LogService.CHAT, '[MESSAGE_LIST] Checking for unseen messages');
    if (widget.messages.isEmpty) {
      logDebug(LogService.CHAT, '[MESSAGE_LIST] No messages to check');
      return;
    }

    int unseenCount = 0;

    // Lọc tin nhắn chưa xem và không phải của người dùng hiện tại
    for (final message in widget.messages) {
      if (!message.isSeenBy(_currentUserId) &&
          message.senderId != _currentUserId) {
        widget.onMessageSeen(message.id);
        unseenCount++;
      }
    }

    if (unseenCount > 0) {
      logDebug(LogService.CHAT,
          '[MESSAGE_LIST] Marked $unseenCount messages as seen');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.messages.length,
      itemBuilder: _buildMessageItem,
    );
  }

  /// Widget hiển thị khi không có tin nhắn
  Widget _buildEmptyState() {
    return Center(
      child: Text('chat.empty'.tr()),
    );
  }

  /// Builder cho mỗi item tin nhắn
  Widget _buildMessageItem(BuildContext context, int index) {
    if (!_isMounted) return const SizedBox();

    final message = widget.messages[index];
    final isMe = message.senderId == _currentUserId;
    final displayName = message.senderName ?? 'Unknown';

    // Đánh dấu tin nhắn đã đọc nếu cần
    if (!isMe && !message.seenBy.contains(_currentUserId)) {
      // Sử dụng Future.microtask để tránh gọi callback trong quá trình build
      Future.microtask(() {
        if (_isMounted) {
          widget.onMessageSeen(message.id);
        }
      });
    }

    // Kiểm tra các điều kiện hiển thị
    final isNextSameSender = _isNextSameSender(index);
    final isPrevSameSender = _isPrevSameSender(index);
    final isNewDay = _isNewDay(index);

    return Column(
      children: [
        // Hiển thị divider ngày nếu cần
        if (isNewDay) _buildDateDivider(message.createdAt),

        // Hiển thị tin nhắn
        Padding(
          padding: EdgeInsets.only(
            bottom: isPrevSameSender ? 2 : 8,
            top: isNextSameSender ? 2 : 8,
          ),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar (chỉ hiển thị cho tin nhắn không phải của tôi và là tin nhắn đầu tiên của nhóm)
              if (!isMe && !isNextSameSender)
                _buildAvatar(message, displayName)
              else if (!isMe)
                const SizedBox(width: 40.0),

              // Bong bóng tin nhắn
              Flexible(
                child: MessageBubble(
                  message: message,
                  isMe: isMe,
                  isPrevSameSender: isPrevSameSender,
                  isNextSameSender: isNextSameSender,
                  senderName: displayName,
                  showTime: false,
                  isGroup: widget.isGroup,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget hiển thị avatar người gửi
  Widget _buildAvatar(Message message, String displayName) {
    return Row(
      children: [
        DisplayUserImage(
          imageUrl: message.senderAvatar,
          userName: displayName,
          radius: 15,
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }

  /// Kiểm tra xem tin nhắn tiếp theo có cùng người gửi không
  bool _isNextSameSender(int index) {
    if (index >= widget.messages.length - 1) return false;
    return widget.messages[index].senderId ==
        widget.messages[index + 1].senderId;
  }

  /// Kiểm tra xem tin nhắn trước có cùng người gửi không
  bool _isPrevSameSender(int index) {
    if (index <= 0) return false;
    return widget.messages[index].senderId ==
        widget.messages[index - 1].senderId;
  }

  /// Phương thức kiểm tra xem có phải là ngày mới không
  bool _isNewDay(int index) {
    if (index == widget.messages.length - 1)
      return true; // Tin nhắn đầu tiên luôn là ngày mới

    final currentMessage = widget.messages[index];
    final nextMessage = widget.messages[index + 1]; // Tin nhắn cũ hơn

    return !DateTimeHelper.isSameDay(
        currentMessage.createdAt, nextMessage.createdAt);
  }

  /// Hiển thị divider cho ngày mới
  Widget _buildDateDivider(DateTime? dateTime) {
    if (dateTime == null) return const SizedBox.shrink();

    final dateText = DateTimeHelper.getFormattedDate(dateTime);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withAlpha(230),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
