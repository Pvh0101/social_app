import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../../../core/enums/message_type.dart';
import 'package:social_app/features/posts/presentation/widgets/post_image_view.dart';
import 'chat_video_player.dart';
import 'chat_audio_player.dart';

class MessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageContent({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  String? get _mediaUrl => message.mediaUrl;
  bool get _hasValidMedia => _mediaUrl != null && _mediaUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color placeholderColor = isMe
        ? colorScheme.surface.withAlpha(51)
        : colorScheme.surface.withAlpha(235);

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        );

      case MessageType.image:
        if (!_hasValidMedia) {
          return _buildErrorContainer(
              'Không thể tải ảnh', placeholderColor, colorScheme);
        }

        // Sử dụng container để giới hạn kích thước và kiểm soát tỷ lệ
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PostImageView(
            imageUrls: [_mediaUrl!],
            heroTagPrefix: 'message_${message.id}',
          ),
        );

      case MessageType.video:
        if (!_hasValidMedia) {
          return _buildErrorContainer(
              'Không thể tải video', placeholderColor, colorScheme);
        }
        return ChatVideoPlayer(
            videoUrl: _mediaUrl!, placeholderColor: placeholderColor);

      case MessageType.audio:
        if (!_hasValidMedia) {
          return _buildErrorContainer(
              'Không thể tải audio', placeholderColor, colorScheme);
        }
        return ChatAudioPlayer(
          audioUrl: _mediaUrl!,
          backgroundColor: placeholderColor,
          foregroundColor: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
        );
    }
  }

  Widget _buildErrorContainer(
      String message, Color bgColor, ColorScheme colorScheme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgColor,
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: colorScheme.onBackground.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
