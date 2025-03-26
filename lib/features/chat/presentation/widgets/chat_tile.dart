import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routes_constants.dart';
import '../../../../core/enums/message_type.dart';
import '../../../../core/utils/datetime_helper.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../models/chatroom.dart';
import '../../providers/chat_providers.dart';

/// Widget hiển thị thông tin cuộc trò chuyện trong danh sách chat
///
/// Sử dụng chủ yếu cho màn hình danh sách chat (ChatListScreen)
///
/// # Cách sử dụng cơ bản
///
/// ```dart
/// ChatTile(
///   chat: chatroom,
///   currentUserId: currentUserId,
///   onTap: () {
///     // Xử lý khi nhấn vào cuộc trò chuyện
///   },
/// )
/// ```
///
/// Widget này sẽ tự động:
/// - Lấy thông tin của người dùng kia (trong trò chuyện 1-1)
/// - Hiển thị ảnh đại diện, tên, trạng thái online
/// - Hiển thị tin nhắn cuối cùng và thời gian
/// - Hiển thị số tin nhắn chưa đọc
class ChatTile extends ConsumerWidget {
  /// Thông tin cuộc trò chuyện
  final Chatroom chat;

  /// ID của người dùng hiện tại
  final String currentUserId;

  /// Xử lý khi nhấn vào tile
  final VoidCallback? onTap;

  /// Xử lý khi nhấn và giữ tile
  final VoidCallback? onLongPress;

  /// Có đánh dấu tile này là đã chọn không
  final bool isSelected;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Xử lý cho trường hợp chat 1-1
    if (!chat.isGroup) {
      final otherUserId = chat.getOtherUserId(currentUserId);
      if (otherUserId.isEmpty) {
        return _buildErrorTile(context, 'Không thể xác định người nhận');
      }

      // Lấy thông tin người dùng kia bằng Stream để cập nhật realtime
      final otherUserAsync =
          ref.watch(getUserInfoAsStreamByIdProvider(otherUserId));

      // Lấy số tin nhắn chưa đọc
      final unreadCountAsync = ref.watch(unreadMessagesCountProvider(chat.id));

      return otherUserAsync.when(
        data: (user) {
          return _buildChatTileContent(
            context: context,
            name: user.fullName,
            avatar: user.profileImage,
            isOnline: user.isOnline,
            lastMessage: chat.lastMessage,
            lastMessageType: chat.lastMessageType,
            lastMessageTime: chat.updatedAt,
            isLastMessageMine: chat.lastMessageSenderId == currentUserId,
            unreadCount: unreadCountAsync.value ?? 0,
          );
        },
        loading: () => _buildLoadingTile(context),
        error: (error, stack) => _buildErrorTile(context, 'Lỗi: $error'),
      );
    }
    // Xử lý cho trường hợp chat nhóm
    else {
      // Lấy số tin nhắn chưa đọc
      final unreadCountAsync = ref.watch(unreadMessagesCountProvider(chat.id));

      return _buildChatTileContent(
        context: context,
        name: chat.name ?? 'Nhóm chat',
        avatar: chat.avatar,
        isOnline: false, // Nhóm chat không có trạng thái online
        lastMessage: chat.lastMessage,
        lastMessageType: chat.lastMessageType,
        lastMessageTime: chat.updatedAt,
        isLastMessageMine: chat.lastMessageSenderId == currentUserId,
        unreadCount: unreadCountAsync.value ?? 0,
        isGroup: true,
      );
    }
  }

  // Widget hiển thị nội dung tile
  Widget _buildChatTileContent({
    required BuildContext context,
    required String name,
    required String? avatar,
    required bool isOnline,
    required String? lastMessage,
    required MessageType? lastMessageType,
    required DateTime? lastMessageTime,
    required bool isLastMessageMine,
    required int unreadCount,
    bool isGroup = false,
  }) {
    final theme = Theme.of(context);

    // Xử lý hiển thị tin nhắn cuối cùng
    String lastMessageText = 'Bắt đầu cuộc trò chuyện';
    if (lastMessage != null && lastMessageType != null) {
      if (lastMessageType == MessageType.text) {
        lastMessageText = lastMessage;
      } else if (lastMessageType == MessageType.image) {
        lastMessageText = '[Hình ảnh]';
      } else if (lastMessageType == MessageType.video) {
        lastMessageText = '[Video]';
      } else if (lastMessageType == MessageType.audio) {
        lastMessageText = '[Âm thanh]';
      }

      // Nếu tin nhắn cuối cùng là của mình
      if (isLastMessageMine) {
        lastMessageText = 'Bạn: $lastMessageText';
      }
    }

    // Định dạng thời gian
    final timeText = lastMessageTime != null
        ? DateTimeHelper.getRelativeTime(lastMessageTime)
        : '';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? theme.highlightColor : null,
        child: Row(
          children: [
            // Avatar
            DisplayUserImage(
              imageUrl: avatar,
              userName: name,
              radius: 28,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12),

            // Thông tin chat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên và thời gian
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: unreadCount > 0
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Tin nhắn cuối và số tin nhắn chưa đọc
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: unreadCount > 0
                                ? theme.textTheme.bodyMedium?.color
                                : theme.textTheme.bodySmall?.color,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị khi đang tải
  Widget _buildLoadingTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  color: Colors.grey.withOpacity(0.2),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị khi có lỗi
  Widget _buildErrorTile(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
