import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../../../core/utils/datetime_helper.dart';
import '../../../../core/utils/log_utils.dart';
import '../../../../core/enums/message_type.dart';
import 'message_content.dart';

/// Constants cho UI của message bubble
const double _kBubbleCornerRadius = 18.0;
const double _kSmallBubbleCornerRadius = 4.0;
const double _kTimestampFontSize = 11.0;
const double _kIconSize = 12.0;
const double _kTimestampSpacing = 4.0;
const EdgeInsets _kTextMessagePadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 12);
const EdgeInsets _kMediaMessagePadding =
    EdgeInsets.symmetric(horizontal: 8, vertical: 8);
const EdgeInsets _kTimestampPadding = EdgeInsets.only(top: 4, bottom: 8);

/// MessageBubble - Widget hiển thị bong bóng tin nhắn
///
/// Widget này hiển thị một bong bóng tin nhắn với:
/// - Định dạng phụ thuộc vào người gửi (tin nhắn của mình hoặc người khác)
/// - Hiển thị thời gian và trạng thái đã đọc theo quy tắc của Messenger
/// - Khả năng hiện/ẩn tên người gửi
/// - Điều chỉnh hình dạng bong bóng dựa vào vị trí của tin nhắn trong chuỗi
class MessageBubble extends StatefulWidget {
  /// Dữ liệu tin nhắn cần hiển thị
  final Message message;

  /// Tin nhắn có phải của người dùng hiện tại không
  final bool isMe;

  /// Tin nhắn trước có phải cùng người gửi không
  final bool isPrevSameSender;

  /// Tin nhắn sau có phải cùng người gửi không
  final bool isNextSameSender;

  /// Tên người gửi tin nhắn
  final String senderName;

  /// Có hiển thị thời gian không
  final bool showTime;

  /// Có phải là chat nhóm không
  final bool isGroup;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.isPrevSameSender,
    required this.isNextSameSender,
    required this.senderName,
    this.showTime = false,
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // Trạng thái hiển thị thời gian
  bool _isTimeVisible = false;

  @override
  void initState() {
    super.initState();
    logDebug(LogService.CHAT,
        '[MESSAGE_BUBBLE] Initialized bubble for message ${widget.message.id}');
    logDebug(LogService.CHAT,
        '[MESSAGE_BUBBLE] Message type: ${widget.message.type.name}, isMe: ${widget.isMe}');
  }

  @override
  Widget build(BuildContext context) {
    logDebug(LogService.CHAT,
        '[MESSAGE_BUBBLE] Building message bubble for ${widget.message.id}');

    final theme = Theme.of(context);
    final bubbleColor = widget.isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant;
    final textColor = widget.isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    // Kiểm tra xem có nên hiện tên người gửi không
    final shouldShowSenderName = !widget.isMe && !widget.isNextSameSender;

    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Hiển thị tên người gửi ở ngoài bong bóng tin nhắn (chỉ khi không phải tin nhắn của mình và tin nhắn đầu tiên của chuỗi tin nhắn)
        if (shouldShowSenderName)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
            child: Text(
              widget.senderName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        // Bong bóng tin nhắn với GestureDetector để phát hiện nhấn
        GestureDetector(
          onTap: () {
            // Nếu là tin nhắn ảnh hoặc video, không làm gì cả vì MessageContent đã có GestureDetector riêng
            // xử lý sự kiện tap trong _buildImageContent và _buildVideoThumbnail
            if (widget.message.type == MessageType.text ||
                widget.message.type == MessageType.audio) {
              // Chuyển đổi trạng thái hiển thị thời gian
              setState(() {
                _isTimeVisible = !_isTimeVisible;
              });

              // Tự động ẩn thời gian sau 3 giây
              if (_isTimeVisible) {
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      _isTimeVisible = false;
                    });
                  }
                });
              }
            }
          },
          // Sử dụng behavior: HitTestBehavior.opaque để đảm bảo sự kiện không truyền xuống con
          behavior: HitTestBehavior.opaque,
          child: _buildMessageBubble(context),
        ),

        // Hiển thị thời gian nếu người dùng nhấn vào tin nhắn hoặc nếu showTime = true
        if (_isTimeVisible || widget.showTime) _buildTimestamp(context),
      ],
    );
  }

  /// Xây dựng bong bóng tin nhắn chính
  Widget _buildMessageBubble(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: _getMessagePadding(),
      decoration: BoxDecoration(
        color: _getBubbleColor(colorScheme),
        borderRadius: _getBubbleBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: MessageContent(
        message: widget.message,
        isMe: widget.isMe,
      ),
    );
  }

  /// Xây dựng phần hiển thị thời gian và trạng thái
  Widget _buildTimestamp(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: _kTimestampPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thời gian
          Text(
            DateTimeHelper.getTimeString(widget.message.createdAt),
            style: TextStyle(
              fontSize: _kTimestampFontSize,
              color: colorScheme.onSurface.withAlpha(130),
            ),
          ),

          // Chỉ báo đã xem (chỉ cho tin nhắn của tôi và là tin nhắn cuối cùng của chuỗi)
          if (widget.isMe) ...[
            const SizedBox(width: _kTimestampSpacing),
            _buildSeenIndicator(colorScheme),
          ],
        ],
      ),
    );
  }

  /// Hiển thị chỉ báo đã xem
  Widget _buildSeenIndicator(ColorScheme colorScheme) {
    return Icon(
      widget.message.seenBy.isNotEmpty ? Icons.check_circle : Icons.check,
      size: _kIconSize,
      color: widget.message.seenBy.isNotEmpty
          ? colorScheme.primary
          : colorScheme.onSurface.withAlpha(130),
    );
  }

  /// Lấy màu cho bong bóng tin nhắn
  Color _getBubbleColor(ColorScheme colorScheme) {
    return widget.isMe ? colorScheme.primary : colorScheme.primaryContainer;
  }

  /// Lấy border radius cho bong bóng tin nhắn
  BorderRadius _getBubbleBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(_kBubbleCornerRadius),
      topRight: const Radius.circular(_kBubbleCornerRadius),
      bottomLeft: Radius.circular(widget.isMe || widget.isNextSameSender
          ? _kBubbleCornerRadius
          : _kSmallBubbleCornerRadius),
      bottomRight: Radius.circular(!widget.isMe || widget.isNextSameSender
          ? _kBubbleCornerRadius
          : _kSmallBubbleCornerRadius),
    );
  }

  /// Lấy padding cho bong bóng tin nhắn dựa trên loại tin nhắn
  EdgeInsets _getMessagePadding() {
    return widget.message.type.isText
        ? _kTextMessagePadding
        : _kMediaMessagePadding;
  }
}

/// Extension để dễ dàng kiểm tra loại tin nhắn
extension MessageTypeExtension on MessageType {
  bool get isText => this == MessageType.text;
  bool get isImage => this == MessageType.image;
  bool get isVideo => this == MessageType.video;
  bool get isAudio => this == MessageType.audio;
}
