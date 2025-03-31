import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/screens/error_screen.dart';
import '../../../../core/widgets/loader.dart';
import '../../../../core/core.dart';
import '../../../authentication/authentication.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../providers/friend_provider.dart';
import '../../providers/get_all_friends_provider.dart';
import 'friendship_button.dart';

enum FriendTileType {
  friend, // Hiển thị bạn bè hiện tại
  suggestion, // Hiển thị gợi ý kết bạn
}

class FriendTile extends ConsumerWidget {
  final String userId;
  final FriendTileType type;
  final bool? isOnline;
  final VoidCallback? onMessageTap;
  final VoidCallback? onAddFriend;
  final VoidCallback? onCancelRequest;
  final bool isPendingRequest;

  const FriendTile({
    super.key,
    required this.userId,
    this.type = FriendTileType.friend,
    this.isOnline,
    this.onMessageTap,
    this.onAddFriend,
    this.onCancelRequest,
    this.isPendingRequest = false,
  });

  void _showMoreOptions(BuildContext context, WidgetRef ref, UserModel user) {
    ref.logInfo(LogService.FRIEND,
        '[FRIEND_TILE] Hiển thị tùy chọn mở rộng cho người dùng: ${user.fullName} (${user.uid})');

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Hủy kết bạn',
              ),
              onTap: () async {
                Navigator.pop(context); // Đóng bottom sheet

                // Hiển thị hộp thoại xác nhận
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận hủy kết bạn'),
                        content: Text(
                            'Bạn có chắc chắn muốn hủy kết bạn với ${user.fullName}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (confirmed) {
                  ref.logInfo(LogService.FRIEND,
                      '[FRIEND_TILE] Người dùng xác nhận hủy kết bạn với: ${user.fullName} (${user.uid})');
                  await ref.read(friendProvider).removeFriend(userId: user.uid);
                  ref.invalidate(friendshipStatusProvider(user.uid));
                  ref.invalidate(getAllFriendsProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_TILE] Xây dựng tile cho người dùng: $userId, loại: ${type.name}');
    final userData = ref.watch(getUserInfoAsStreamByIdProvider(userId));
    return userData.when(
      data: (user) {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_TILE] Đã nhận thông tin người dùng: ${user.fullName} (${user.uid})');
        return Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
          child: Row(
            children: [
              // Avatar và thông tin người dùng, bọc trong GestureDetector
              GestureDetector(
                onTap: () {
                  ref.logDebug(LogService.FRIEND,
                      '[FRIEND_TILE] Chuyển đến trang profile của người dùng: ${user.fullName} (${user.uid})');
                  Navigator.pushNamed(
                    context,
                    RouteConstants.userProfile,
                    arguments: userId,
                  );
                },
                child: DisplayUserImage(
                  imageUrl: user.profileImage,
                  userName: user.fullName,
                  isOnline: user.isOnline,
                  radius: 36,
                ),
              ),
              const SizedBox(width: 10),

              // Thông tin người dùng, cũng bọc trong GestureDetector
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.logDebug(LogService.FRIEND,
                        '[FRIEND_TILE] Chuyển đến trang profile của người dùng: ${user.fullName} (${user.uid})');
                    Navigator.pushNamed(
                      context,
                      RouteConstants.userProfile,
                      arguments: userId,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.lastSeenText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FriendshipButton(userId: userId),

                  // Nút More chỉ hiển thị khi đây là bạn bè
                  if (type == FriendTileType.friend)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showMoreOptions(context, ref, user),
                      tooltip: 'Thêm tùy chọn',
                    ),
                ],
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        ref.logError(
            LogService.FRIEND,
            '[FRIEND_TILE] Lỗi khi tải thông tin người dùng: $userId',
            error,
            stackTrace);
        return ErrorScreen(error: error.toString());
      },
      loading: () {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_TILE] Đang tải thông tin người dùng: $userId');
        return const Loader();
      },
    );
  }
}
