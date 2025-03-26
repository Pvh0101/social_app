import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/friend_provider.dart';
import '../../../authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../providers/get_all_friend_requests_provider.dart';
import '../../providers/search_users_provider.dart';

import '../../../../core/core.dart';
import '../../../../core/screens/error_screen.dart';
import '../../../../core/screens/loader.dart';
import '../../../../core/utils/log_utils.dart';
import 'friend_tile.dart';
import '../../providers/get_all_users_provider.dart';

class FriendSuggestionList extends ConsumerStatefulWidget {
  final String searchQuery;

  const FriendSuggestionList({
    super.key,
    this.searchQuery = '',
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RequestsListState();
}

class _RequestsListState extends ConsumerState<FriendSuggestionList> {
  @override
  Widget build(BuildContext context) {
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_SUGGESTION_LIST] Xây dựng danh sách gợi ý bạn bè với từ khóa: ${widget.searchQuery.isEmpty ? "[rỗng]" : widget.searchQuery}');

    // Nếu có từ khóa tìm kiếm, sử dụng searchUsersProvider
    if (widget.searchQuery.isNotEmpty) {
      ref.logDebug(LogService.FRIEND,
          '[FRIEND_SUGGESTION_LIST] Sử dụng searchUsersProvider với từ khóa: ${widget.searchQuery}');
      final searchResults = ref.watch(searchUsersProvider(widget.searchQuery));

      return searchResults.when(
        data: (userIds) {
          ref.logDebug(LogService.FRIEND,
              '[FRIEND_SUGGESTION_LIST] Nhận được ${userIds.length} kết quả tìm kiếm');

          if (userIds.isEmpty) {
            ref.logInfo(LogService.FRIEND,
                '[FRIEND_SUGGESTION_LIST] Không tìm thấy kết quả cho từ khóa: ${widget.searchQuery}');
            return Center(
              child: Text(
                'Không tìm thấy kết quả',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          ref.logInfo(LogService.FRIEND,
              '[FRIEND_SUGGESTION_LIST] Hiển thị ${userIds.length} kết quả tìm kiếm');
          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final userId = userIds[index];
              return FriendTile(
                userId: userId,
                type: FriendTileType.suggestion,
              );
            },
          );
        },
        error: (error, stackTrace) {
          ref.logError(
              LogService.FRIEND,
              '[FRIEND_SUGGESTION_LIST] Lỗi khi tìm kiếm người dùng',
              error,
              stackTrace);
          return ErrorScreen(error: error.toString());
        },
        loading: () {
          ref.logDebug(LogService.FRIEND,
              '[FRIEND_SUGGESTION_LIST] Đang tải kết quả tìm kiếm...');
          return const Loader();
        },
      );
    }

    // Nếu không có từ khóa, hiển thị danh sách gợi ý như cũ
    ref.logDebug(LogService.FRIEND,
        '[FRIEND_SUGGESTION_LIST] Hiển thị danh sách gợi ý mặc định');
    final userIds = ref.watch(getAllUsersProvider);
    // final allUsers = ref.watch(getAllUsersProvider);
    // final allFriendRequests = ref.watch(getAllFriendRequestsProvider);
    // final allFriends = ref.watch(getAllUsersProvider);

    final currentUser = ref.watch(getUserInfoAsStreamByIdProvider(
        FirebaseAuth.instance.currentUser!.uid));

    return userIds.when(
      data: (ids) {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_SUGGESTION_LIST] Nhận được ${ids.length} người dùng tiềm năng');

        return currentUser.when(
          data: (user) {
            if (ids.isEmpty) {
              ref.logInfo(LogService.FRIEND,
                  '[FRIEND_SUGGESTION_LIST] Không có gợi ý kết bạn');
              return Center(
                child: Text(
                  'Không có gợi ý kết bạn',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            ref.logInfo(LogService.FRIEND,
                '[FRIEND_SUGGESTION_LIST] Hiển thị ${ids.length} gợi ý kết bạn');
            return ListView.builder(
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final userId = ids[index];
                return FriendTile(
                  userId: userId,
                  type: FriendTileType.suggestion,
                );
              },
            );
          },
          error: (error, stackTrace) {
            ref.logError(
                LogService.FRIEND,
                '[FRIEND_SUGGESTION_LIST] Lỗi khi lấy thông tin người dùng hiện tại',
                error,
                stackTrace);
            return ErrorScreen(error: error.toString());
          },
          loading: () {
            ref.logDebug(LogService.FRIEND,
                '[FRIEND_SUGGESTION_LIST] Đang tải thông tin người dùng hiện tại...');
            return const Loader();
          },
        );
      },
      error: (error, stackTrace) {
        ref.logError(
            LogService.FRIEND,
            '[FRIEND_SUGGESTION_LIST] Lỗi khi lấy danh sách tất cả người dùng',
            error,
            stackTrace);
        return ErrorScreen(error: error.toString());
      },
      loading: () {
        ref.logDebug(LogService.FRIEND,
            '[FRIEND_SUGGESTION_LIST] Đang tải danh sách người dùng...');
        return const Loader();
      },
    );
  }
}
