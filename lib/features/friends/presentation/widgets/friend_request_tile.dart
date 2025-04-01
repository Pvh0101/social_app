import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/widgets/buttons/round_button.dart';
import '../../providers/friend_provider.dart';

import '../../../../core/core.dart';
import '../../../../core/screens/error_screen.dart';
import '../../../../core/screens/loader.dart';
import '../../../authentication/authentication.dart';

class FriendRequestTile extends ConsumerWidget {
  const FriendRequestTile({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_REQUEST_TILE] Xây dựng tile lời mời kết bạn từ người dùng: $userId');
    final userData = ref.watch(getUserInfoAsStreamByIdProvider(userId));
    return userData.when(
      data: (user) {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_REQUEST_TILE] Đã nhận thông tin người dùng gửi lời mời: ${user.fullName} (${user.uid})');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: () {
                  ref.logDebug(LogService.FRIEND,
                      '[FRIEND_REQUEST_TILE] Chuyển đến trang profile của người dùng: ${user.fullName} (${user.uid})');
                  Navigator.pushNamed(
                    context,
                    RouteConstants.userProfile,
                    arguments: userId,
                  );
                },
                child: DisplayUserImage(
                  imageUrl: user.profileImage,
                  userName: user.fullName,
                  radius: 36,
                  isOnline: user.isOnline,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.lastSeenText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 6),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: RoundButtonFill(
                            onPressed: () {
                              ref.logInfo(LogService.FRIEND,
                                  '[FRIEND_REQUEST_TILE] Đồng ý lời mời kết bạn từ: ${user.fullName} (${user.uid})');
                              ref
                                  .read(friendProvider)
                                  .acceptFriendRequest(userId: userId);
                            },
                            label: 'friends.status.accept'.tr(),
                            height: 38,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RoundButton(
                            onPressed: () {
                              ref.logInfo(LogService.FRIEND,
                                  '[FRIEND_REQUEST_TILE] Từ chối lời mời kết bạn từ: ${user.fullName} (${user.uid})');
                              ref
                                  .read(friendProvider)
                                  .removeFriendRequest(userId: userId);
                            },
                            label: 'friends.decline'.tr(),
                            height: 38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        ref.logError(
            LogService.FRIEND,
            '[FRIEND_REQUEST_TILE] Lỗi khi tải thông tin người dùng gửi lời mời: $userId',
            error,
            stackTrace);
        return ErrorScreen(error: error.toString());
      },
      loading: () {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_REQUEST_TILE] Đang tải thông tin người dùng gửi lời mời: $userId');
        return const Loader();
      },
    );
  }
}
