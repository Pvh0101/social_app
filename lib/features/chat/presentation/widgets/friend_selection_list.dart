import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../../friends/providers/get_all_friends_provider.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../providers/chat_providers.dart';

/// Widget hiển thị danh sách bạn bè để chọn thêm vào nhóm chat
///
/// Có thể sử dụng trong:
/// - Tạo nhóm mới: cho phép chọn nhiều bạn bè cùng lúc (useCheckbox = true)
/// - Thêm thành viên: chọn từng bạn bè để thêm vào nhóm (useCheckbox = false)
class FriendSelectionList extends ConsumerStatefulWidget {
  final Set<String>? selectedIds; // Danh sách ID đã chọn
  final Function(String) onFriendToggled; // Callback khi chọn/bỏ chọn bạn bè
  final String?
      chatId; // ID của phòng chat (dùng để kiểm tra đã là thành viên chưa)
  final bool useCheckbox; // Sử dụng checkbox hay không
  final bool filterExistingMembers; // Lọc bạn bè đã là thành viên
  final bool enableSearch; // Cho phép tìm kiếm

  const FriendSelectionList({
    Key? key,
    this.selectedIds,
    required this.onFriendToggled,
    this.chatId,
    this.useCheckbox = true,
    this.filterExistingMembers = false,
    this.enableSearch = true,
  }) : super(key: key);

  @override
  ConsumerState<FriendSelectionList> createState() =>
      _FriendSelectionListState();
}

class _FriendSelectionListState extends ConsumerState<FriendSelectionList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(getAllFriendsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề chỉ hiển thị khi không lọc thành viên
        if (!widget.filterExistingMembers)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              widget.useCheckbox ? 'Chọn thành viên:' : 'Thêm thành viên:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Thanh tìm kiếm (chỉ hiển thị khi có bật tính năng tìm kiếm)
        if (widget.enableSearch)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

        // Danh sách bạn bè
        friendsAsync.when(
          data: (friendIds) {
            if (friendIds.isEmpty) {
              return _buildEmptyState('Bạn chưa có bạn bè nào');
            }

            // Lọc danh sách theo thành viên hiện có và theo từ khóa tìm kiếm
            List<String> filteredIds =
                _filterFriendIds(friendIds, context, ref);

            if (filteredIds.isEmpty) {
              if (widget.filterExistingMembers) {
                return _buildEmptyState(
                    'Tất cả bạn bè đã là thành viên của nhóm');
              } else if (_searchQuery.isNotEmpty) {
                return _buildEmptyState('Không tìm thấy bạn bè nào phù hợp');
              }
              return _buildEmptyState('Không có bạn bè nào');
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredIds.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                return _buildFriendItem(filteredIds[index], ref);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Lỗi: $error'),
            ),
          ),
        ),
      ],
    );
  }

  // Lọc danh sách bạn bè dựa trên điều kiện
  List<String> _filterFriendIds(
      List<dynamic> friendIds, BuildContext context, WidgetRef ref) {
    List<String> result = List<String>.from(friendIds);

    // Lọc theo thành viên hiện có trong nhóm
    if (widget.filterExistingMembers && widget.chatId != null) {
      final chatAsync = ref.watch(chatProvider(widget.chatId!));
      if (chatAsync.hasValue && chatAsync.value != null) {
        result = result
            .where((id) => !chatAsync.value!.members.contains(id))
            .toList();
      }
    }

    // Lọc theo từ khóa tìm kiếm
    if (_searchQuery.isNotEmpty) {
      // Sử dụng danh sách tạm để lưu trữ kết quả
      List<String> searchResults = [];

      for (String friendId in result) {
        final userInfo =
            ref.read(getUserInfoAsStreamByIdProvider(friendId)).valueOrNull;
        if (userInfo != null) {
          final fullName = userInfo.fullName.toLowerCase();
          final email = (userInfo.email ?? '').toLowerCase();

          if (fullName.contains(_searchQuery) || email.contains(_searchQuery)) {
            searchResults.add(friendId);
          }
        }
      }

      result = searchResults;
    }

    return result;
  }

  // Widget hiển thị trạng thái trống
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị một item bạn bè
  Widget _buildFriendItem(String friendId, WidgetRef ref) {
    final friendStream = ref.watch(getUserInfoAsStreamByIdProvider(friendId));

    // Kiểm tra xem bạn bè đã là thành viên của nhóm chat chưa
    bool isMember = false;
    if (widget.chatId != null) {
      final chatAsync = ref.watch(chatProvider(widget.chatId!));
      isMember = chatAsync.value?.members.contains(friendId) ?? false;
    }

    return friendStream.when(
      data: (friend) {
        if (widget.useCheckbox) {
          // Hiển thị với checkbox (dùng cho tạo nhóm)
          return CheckboxListTile(
            title: Text(
              friend.fullName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Text(
              friend.email ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            secondary: DisplayUserImage(
              imageUrl: friend.profileImage,
              userName: friend.fullName,
              radius: 24,
            ),
            value: widget.selectedIds?.contains(friendId) ?? false,
            onChanged: isMember
                ? null
                : (value) {
                    if (value != null) {
                      widget.onFriendToggled(friendId);
                    }
                  },
            activeColor: Theme.of(context).primaryColor,
            selected: widget.selectedIds?.contains(friendId) ?? false,
          );
        } else {
          // Hiển thị dạng ListTile thông thường (dùng cho thêm thành viên)
          return ListTile(
            leading: DisplayUserImage(
              imageUrl: friend.profileImage,
              userName: friend.fullName,
              radius: 24,
            ),
            title: Text(
              friend.fullName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isMember ? Colors.grey : Colors.grey[800],
              ),
            ),
            subtitle: Text(
              friend.email ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            enabled: !isMember,
            onTap: isMember ? null : () => widget.onFriendToggled(friendId),
            trailing: isMember
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Đã là thành viên',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : const Icon(Icons.add_circle_outline, color: Colors.blue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            dense: false,
          );
        }
      },
      loading: () => const ListTile(
        leading: CircleAvatar(
          radius: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Đang tải...'),
      ),
      error: (error, stack) => ListTile(
        leading: const CircleAvatar(
          radius: 24,
          child: Icon(Icons.error),
        ),
        title: Text('Lỗi'),
        subtitle: Text(error.toString()),
      ),
    );
  }
}
