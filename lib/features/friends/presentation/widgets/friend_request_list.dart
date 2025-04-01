import 'friend_request_tile.dart';

import '../../../../core/screens/error_screen.dart';
import '../../../../core/screens/loader.dart';
import '../../../authentication/authentication.dart';
import '../../providers/get_all_friend_requests_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/log_utils.dart';

class FriendRequestList extends ConsumerWidget {
  final String searchQuery;

  const FriendRequestList({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_REQUEST_LIST] Xây dựng danh sách lời mời kết bạn với từ khóa tìm kiếm: ${searchQuery.isEmpty ? "[rỗng]" : searchQuery}');
    final requestsList = ref.watch(getAllFriendRequestsProvider);

    return requestsList.when(
      data: (requestIds) {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_REQUEST_LIST] Đã nhận danh sách: ${requestIds.length} lời mời kết bạn');

        // Lọc danh sách yêu cầu kết bạn theo từ khóa tìm kiếm
        final filteredIds = requestIds.where((requestId) {
          final userInfo =
              ref.watch(getUserInfoAsStreamByIdProvider(requestId));
          return userInfo.when(
            data: (user) =>
                user.fullName.toLowerCase().contains(searchQuery.toLowerCase()),
            loading: () => false,
            error: (_, __) => false,
          );
        }).toList();

        ref.logDebug(LogService.FRIEND,
            '[FRIEND_REQUEST_LIST] Sau khi lọc: ${filteredIds.length} lời mời phù hợp với từ khóa tìm kiếm');

        if (filteredIds.isEmpty) {
          final message = searchQuery.isEmpty
              ? 'friends.no_requests'.tr()
              : 'friends.no_search_results'.tr();
          ref.logInfo(LogService.FRIEND, '[FRIEND_REQUEST_LIST] $message');

          return Center(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        ref.logInfo(LogService.FRIEND,
            '[FRIEND_REQUEST_LIST] Hiển thị ${filteredIds.length} lời mời kết bạn');
        return ListView.builder(
          itemCount: filteredIds.length,
          itemBuilder: (context, index) {
            final requestId = filteredIds[index];
            return FriendRequestTile(
              userId: requestId,
            );
          },
        );
      },
      loading: () {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_REQUEST_LIST] Đang tải danh sách lời mời kết bạn...');
        return const Loader();
      },
      error: (error, stack) {
        ref.logError(
            LogService.FRIEND,
            '[FRIEND_REQUEST_LIST] Lỗi khi tải danh sách lời mời kết bạn',
            error,
            stack);
        return ErrorScreen(error: error.toString());
      },
    );
  }
}
