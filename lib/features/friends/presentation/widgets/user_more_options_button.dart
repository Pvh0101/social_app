import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/utils/log_utils.dart';
import '../../../authentication/models/user_model.dart';
import '../../providers/friend_provider.dart';
import '../../providers/get_all_friends_provider.dart';

/// Widget hiển thị nút more options và xử lý các tùy chọn cho người dùng.
///
/// Widget này được sử dụng để hiển thị các tùy chọn như báo cáo, chặn và hủy kết bạn
/// trong các màn hình hiển thị thông tin người dùng.
class UserMoreOptionsButton extends ConsumerWidget {
  /// ID của người dùng cần hiển thị tùy chọn
  final String userId;

  /// Thông tin người dùng (nếu có sẵn)
  final UserModel? user;

  /// Callback sau khi hủy kết bạn thành công
  final VoidCallback? onUnfriendSuccess;

  const UserMoreOptionsButton({
    super.key,
    required this.userId,
    this.user,
    this.onUnfriendSuccess,
  });

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    final UserModel? userData = user;

    ref.logInfo(LogService.FRIEND,
        '[MORE_OPTIONS] Hiển thị tùy chọn mở rộng cho người dùng: ${userData?.fullName ?? userId}');

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text('common.report'.tr()),
            onTap: () {
              Navigator.pop(context);
              ref.logInfo(LogService.FRIEND,
                  '[MORE_OPTIONS] Người dùng chọn báo cáo: ${userData?.fullName ?? userId}');
              // TODO: Xử lý báo cáo người dùng
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: Text('common.block'.tr()),
            onTap: () {
              Navigator.pop(context);
              ref.logInfo(LogService.FRIEND,
                  '[MORE_OPTIONS] Người dùng chọn chặn: ${userData?.fullName ?? userId}');
              // TODO: Xử lý chặn người dùng
            },
          ),
          // Thêm tùy chọn hủy kết bạn nếu đã là bạn bè
          Consumer(
            builder: (context, ref, child) {
              final statusAsync = ref.watch(friendshipStatusProvider(userId));
              return statusAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (status) {
                  if (status['isFriend'] == true) {
                    return ListTile(
                      leading: const Icon(Icons.person_remove_outlined,
                          color: Colors.red),
                      title: Text(
                        'friends.actions.unfriend'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        ref.logInfo(LogService.FRIEND,
                            '[MORE_OPTIONS] Người dùng chọn hủy kết bạn với: ${userData?.fullName ?? userId}');
                        Navigator.pop(context); // Đóng bottom sheet

                        // Hiển thị hộp thoại xác nhận
                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('friends.unfriend.title'.tr()),
                                content: Text('friends.unfriend.message'.tr()),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('common.cancel'.tr()),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text('common.confirm'.tr()),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (confirmed) {
                          ref.logInfo(LogService.FRIEND,
                              '[MORE_OPTIONS] Người dùng xác nhận hủy kết bạn với: ${userData?.fullName ?? userId}');
                          await ref
                              .read(friendProvider)
                              .removeFriend(userId: userId);
                          ref.invalidate(friendshipStatusProvider(userId));
                          ref.invalidate(getAllFriendsProvider);

                          if (onUnfriendSuccess != null) {
                            onUnfriendSuccess!();
                          }
                        } else {
                          ref.logDebug(LogService.FRIEND,
                              '[MORE_OPTIONS] Đã hủy thao tác hủy kết bạn với: ${userData?.fullName ?? userId}');
                        }
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showMoreOptions(context, ref),
      tooltip: 'friends.actions.more'.tr(),
    );
  }
}
