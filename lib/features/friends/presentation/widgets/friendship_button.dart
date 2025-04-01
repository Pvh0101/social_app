import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/widgets/buttons/round_button.dart';
import '../../providers/friend_provider.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../../core/utils/log_utils.dart';

class FriendshipButton extends ConsumerWidget {
  final String userId;

  const FriendshipButton({
    super.key,
    required this.userId,
  });

  Future<bool> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required WidgetRef ref,
  }) async {
    ref.logDebug(LogService.FRIEND,
        '[FRIENDSHIP_BUTTON] Hiển thị hộp thoại xác nhận: $title');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );
    ref.logDebug(LogService.FRIEND,
        '[FRIENDSHIP_BUTTON] Kết quả hộp thoại xác nhận: ${result == true ? "Đồng ý" : "Hủy"}');
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIENDSHIP_BUTTON] Xây dựng nút kết bạn cho người dùng: $userId');
    final statusAsync = ref.watch(friendshipStatusProvider(userId));

    return statusAsync.when(
      loading: () {
        ref.logDebug(LogService.FRIEND,
            '[FRIENDSHIP_BUTTON] Đang tải trạng thái kết bạn với: $userId');
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      error: (error, stack) {
        ref.logError(
            LogService.FRIEND,
            '[FRIENDSHIP_BUTTON] Lỗi khi tải trạng thái kết bạn với: $userId',
            error,
            stack);
        return const SizedBox.shrink();
      },
      data: (status) {
        ref.logDebug(LogService.FRIEND,
            '[FRIENDSHIP_BUTTON] Trạng thái kết bạn: $status');

        // Đã là bạn bè
        if (status['isFriend'] == true) {
          return RoundButton(
            label: 'friends.actions.message'.tr(),
            onPressed: () {
              ref.logDebug(LogService.FRIEND,
                  '[FRIENDSHIP_BUTTON] Mở cuộc trò chuyện với: $userId');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(receiverId: userId),
                ),
              );
            },
          );
        }

        // Người dùng hiện tại là người gửi lời mời
        if (status['hasPendingRequest'] == true && status['isSender'] == true) {
          return RoundButton(
            label: 'friends.status.cancel_request'.tr(),
            onPressed: () async {
              ref.logDebug(LogService.FRIEND,
                  '[FRIENDSHIP_BUTTON] Nhấn nút hủy lời mời kết bạn đã gửi cho: $userId');
              final confirm = await _showConfirmationDialog(
                context,
                title: 'friends.cancel_request.title'.tr(),
                content: 'friends.cancel_request.message'.tr(),
                ref: ref,
              );

              if (confirm && context.mounted) {
                ref.logInfo(LogService.FRIEND,
                    '[FRIENDSHIP_BUTTON] Hủy lời mời kết bạn đã gửi cho người dùng: $userId');
                await ref
                    .read(friendProvider)
                    .removeFriendRequest(userId: userId);
                ref.invalidate(friendshipStatusProvider(userId));
              } else {
                ref.logDebug(LogService.FRIEND,
                    '[FRIENDSHIP_BUTTON] Đã hủy thao tác hủy lời mời kết bạn với: $userId');
              }
            },
          );
        }

        // Người dùng hiện tại là người nhận lời mời
        if (status['hasPendingRequest'] == true &&
            status['isReceiver'] == true) {
          return RoundButton(
            label: 'friends.status.accept'.tr(),
            onPressed: () async {
              ref.logInfo(LogService.FRIEND,
                  '[FRIENDSHIP_BUTTON] Chấp nhận lời mời kết bạn từ người dùng: $userId');
              await ref
                  .read(friendProvider)
                  .acceptFriendRequest(userId: userId);
              ref.invalidate(friendshipStatusProvider(userId));
            },
          );
        }

        // Chưa có mối quan hệ nào
        return RoundButton(
          label: 'friends.status.add_friend'.tr(),
          onPressed: () async {
            ref.logInfo(LogService.FRIEND,
                '[FRIENDSHIP_BUTTON] Gửi lời mời kết bạn đến người dùng: $userId');
            await ref.read(friendProvider).sendFriendRequest(userId: userId);
            ref.invalidate(friendshipStatusProvider(userId));
          },
        );
      },
    );
  }
}
