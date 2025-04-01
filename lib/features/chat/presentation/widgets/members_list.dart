import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chatroom.dart';
import '../../../authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../../../core/widgets/display_user_image.dart';

/// Widget hiển thị danh sách thành viên trong nhóm chat
///
/// Sử dụng trong màn hình thông tin chat để:
/// - Hiển thị tất cả thành viên trong nhóm
/// - Hiển thị vai trò của từng thành viên (admin/thành viên)
/// - Cho phép admin xóa thành viên
class MembersList extends StatelessWidget {
  final Chatroom chat;
  final String currentUserId;
  final Function(String) onRemoveMember;
  final bool showHeader; // Có hiển thị tiêu đề không

  const MembersList({
    Key? key,
    required this.chat,
    required this.currentUserId,
    required this.onRemoveMember,
    this.showHeader = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Thành viên nhóm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (chat.isAdmin(currentUserId))
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${chat.members.length} thành viên',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ...chat.members.map((userId) => MemberItem(
              chat: chat,
              userId: userId,
              currentUserId: currentUserId,
              onRemove: () => onRemoveMember(userId),
            )),
      ],
    );
  }
}

/// Widget hiển thị một thành viên trong danh sách
class MemberItem extends ConsumerWidget {
  final Chatroom chat;
  final String userId;
  final String currentUserId;
  final VoidCallback onRemove;

  const MemberItem({
    Key? key,
    required this.chat,
    required this.userId,
    required this.currentUserId,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = chat.isAdmin(userId);
    final isSelf = userId == currentUserId;
    final userAsync = ref.watch(getUserInfoAsStreamByIdProvider(userId));

    return userAsync.when(
      data: (user) {
        return ListTile(
          leading: DisplayUserImage(
            imageUrl: user.profileImage,
            radius: 20,
          ),
          title: Row(
            children: [
              Text(user.fullName),
              if (isSelf)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '(Bạn)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              if (isAdmin)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(user.email),
          trailing: chat.isAdmin(currentUserId) && !isSelf
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: onRemove,
                )
              : null,
        );
      },
      loading: () => const ListTile(
        leading: CircleAvatar(
          radius: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Đang tải...'),
      ),
      error: (error, stack) => ListTile(
        leading: const CircleAvatar(
          radius: 20,
          child: Icon(Icons.error),
        ),
        title: const Text('Lỗi'),
        subtitle: Text(error.toString()),
      ),
    );
  }
}
