import '../../../../core/screens/error_screen.dart';
import '../../../../core/screens/loader.dart';
import '../../../authentication/authentication.dart';
import 'friend_tile.dart';
import '../../providers/get_all_friends_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/log_utils.dart';

class FriendsList extends ConsumerWidget {
  final String searchQuery;

  const FriendsList({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_LIST_WIDGET] Xây dựng danh sách bạn bè với từ khóa tìm kiếm: ${searchQuery.isEmpty ? "[rỗng]" : searchQuery}');
    final friendsList = ref.watch(getAllFriendsProvider);

    return friendsList.when(
      data: (friendIds) {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_LIST_WIDGET] Đã nhận danh sách: ${friendIds.length} bạn bè');

        // Lọc danh sách bạn bè theo từ khóa tìm kiếm
        final filteredIds = friendIds.where((friendId) {
          final userInfo = ref.watch(getUserInfoAsStreamByIdProvider(friendId));
          return userInfo.when(
            data: (user) =>
                user.fullName.toLowerCase().contains(searchQuery.toLowerCase()),
            loading: () => false,
            error: (_, __) => false,
          );
        }).toList();

        ref.logDebug(LogService.FRIEND,
            '[FRIEND_LIST_WIDGET] Sau khi lọc: ${filteredIds.length} bạn bè phù hợp với từ khóa tìm kiếm');

        if (filteredIds.isEmpty) {
          final message = searchQuery.isEmpty
              ? 'Bạn chưa có bạn bè nào'
              : 'Không tìm thấy bạn bè phù hợp';
          ref.logInfo(LogService.FRIEND, '[FRIEND_LIST_WIDGET] $message');

          return Center(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        ref.logInfo(LogService.FRIEND,
            '[FRIEND_LIST_WIDGET] Hiển thị ${filteredIds.length} bạn bè');
        return ListView.builder(
          itemCount: filteredIds.length,
          itemBuilder: (context, index) {
            final friendId = filteredIds[index];
            return FriendTile(
              userId: friendId,
              type: FriendTileType.friend,
            );
          },
        );
      },
      loading: () {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_LIST_WIDGET] Đang tải danh sách bạn bè...');
        return const Loader();
      },
      error: (error, stack) {
        ref.logError(LogService.FRIEND,
            '[FRIEND_LIST_WIDGET] Lỗi khi tải danh sách bạn bè', error, stack);
        return ErrorScreen(error: error.toString());
      },
    );
  }
}
