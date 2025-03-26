import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/screens/error_screen.dart';
import '../../../../core/widgets/loader.dart';
import '../../../../core/core.dart';
import '../../../authentication/authentication.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                children: [
                  FriendshipButton(userId: userId),
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
