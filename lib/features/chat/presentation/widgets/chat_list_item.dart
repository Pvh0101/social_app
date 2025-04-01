import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/chatroom.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../../core/utils/datetime_helper.dart';
import '../../../../features/authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../providers/chat_providers.dart';

/// Widget hiển thị một mục trong danh sách chat
class ChatListItem extends ConsumerWidget {
  final Chatroom chat;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatListItem({
    Key? key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return chat.isGroup
        ? _buildGroupChatItem(context, ref)
        : _buildPrivateChatItem(context, ref);
  }

  /// Xây dựng item chat 1-1
  Widget _buildPrivateChatItem(BuildContext context, WidgetRef ref) {
    // Lấy ID người dùng khác trong chat 1-1
    final otherUserId = chat.getOtherUserId(currentUserId);

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    final userStream = ref.watch(getUserInfoAsStreamByIdProvider(otherUserId));
    final unreadCountStream = ref.watch(unreadMessagesCountProvider(chat.id));

    return userStream.when(
      data: (user) {
        return _buildListTile(
          imageUrl: user.profileImage,
          userName: user.fullName,
          isOnline: user.isOnline,
          title: user.fullName,
          subtitle: chat.getDisplayLastMessage(currentUserId),
          updatedAt: chat.updatedAt,
          unreadCountStream: unreadCountStream,
        );
      },
      loading: () => ListTile(
        leading: const CircleAvatar(
          child: CircularProgressIndicator(),
        ),
        title: Text('common.loading'.tr()),
      ),
      error: (error, stack) {
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.error),
          ),
          title: Text('common.error.load'.tr()),
          subtitle: Text(error.toString()),
        );
      },
    );
  }

  /// Xây dựng item nhóm chat
  Widget _buildGroupChatItem(BuildContext context, WidgetRef ref) {
    final unreadCountStream = ref.watch(unreadMessagesCountProvider(chat.id));

    return _buildListTile(
      imageUrl: chat.avatar,
      userName: chat.name ?? 'chat.group.default_name'.tr(),
      title: chat.name ?? 'chat.group.default_name'.tr(),
      subtitle: chat.getDisplayLastMessage(currentUserId),
      updatedAt: chat.updatedAt,
      unreadCountStream: unreadCountStream,
    );
  }

  /// Xây dựng ListTile chung cho cả chat 1-1 và nhóm
  Widget _buildListTile({
    required String? imageUrl,
    required String userName,
    bool isOnline = false,
    required String title,
    required String subtitle,
    required DateTime updatedAt,
    required AsyncValue<int> unreadCountStream,
  }) {
    return ListTile(
      leading: DisplayUserImage(
        imageUrl: imageUrl,
        userName: userName,
        radius: 24,
        isOnline: isOnline,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      tileColor: unreadCountStream.when(
        data: (count) => count > 0 ? Colors.blue.withAlpha(10) : null,
        loading: () => null,
        error: (_, __) => null,
      ),
      trailing: _buildTrailing(updatedAt, unreadCountStream),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// Xây dựng phần trailing của ListTile
  Widget _buildTrailing(DateTime updatedAt, AsyncValue<int> unreadCountStream) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateTimeHelper.getRelativeTime(updatedAt),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        unreadCountStream.when(
          data: (count) {
            if (count > 0) {
              return _buildUnreadBadge(count);
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Xây dựng badge hiển thị số tin nhắn chưa đọc
  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
