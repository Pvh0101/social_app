import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../../models/chatroom.dart';
import '../../providers/chat_providers.dart';
import '../../../../features/authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../../../features/friends/providers/get_all_friends_provider.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../services/chatroom_service.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/friend_selection_list.dart';

// Widget hiển thị các tùy chọn khác
class OtherOptions extends StatelessWidget {
  final Chatroom chat;
  final VoidCallback onLeaveChat;
  final VoidCallback onDeleteChat;

  const OtherOptions({
    Key? key,
    required this.chat,
    required this.onLeaveChat,
    required this.onDeleteChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn khác',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (chat.isGroup)
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Rời khỏi nhóm'),
            onTap: onLeaveChat,
          ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Xóa đoạn chat'),
          onTap: onDeleteChat,
        ),
        if (!chat.isGroup)
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Chặn người dùng'),
            onTap: () {
              showToastMessage(text: 'Chức năng đang phát triển');
            },
          ),
      ],
    );
  }
}

class ChatInfoScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatInfoScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  ConsumerState<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends ConsumerState<ChatInfoScreen> {
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _nameController = TextEditingController();
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onImageSelected(File file) {
    setState(() {
      _selectedImage = file;
    });
  }

  Future<void> _showAddMemberDialog() async {
    // Hiển thị bottom sheet để chọn bạn bè
    final selectedFriend = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // Cho phép bottom sheet mở rộng
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Ban đầu chiếm 60% màn hình
          minChildSize: 0.3, // Tối thiểu 30% màn hình
          maxChildSize: 0.9, // Tối đa 90% màn hình
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phần header có nút đóng
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thêm thành viên',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Phần danh sách bạn bè
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Consumer(
                        builder: (context, ref, _) {
                          return FriendSelectionList(
                            chatId: widget.chatId,
                            onFriendToggled: (friendId) =>
                                Navigator.of(context).pop(friendId),
                            useCheckbox: false,
                            filterExistingMembers:
                                true, // Chỉ hiển thị bạn bè chưa là thành viên
                            enableSearch: true, // Bật tính năng tìm kiếm
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedFriend == null || selectedFriend.isEmpty || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng ChatroomService để thêm thành viên
      final chatroomService = ref.read(chatroomServiceProvider);
      await chatroomService.addMemberToChat(widget.chatId, selectedFriend);

      // Làm mới provider để cập nhật UI
      ref.invalidate(chatProvider(widget.chatId));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng ChatroomService để xóa thành viên
      final chatroomService = ref.read(chatroomServiceProvider);
      await chatroomService.removeMemberFromChat(
        context,
        widget.chatId,
        userId,
        _currentUserId,
      );

      // Làm mới provider để cập nhật UI
      ref.invalidate(chatProvider(widget.chatId));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _leaveChat() async {
    // Sử dụng ChatroomService để rời nhóm
    final chatroomService = ref.read(chatroomServiceProvider);
    if (await chatroomService.leaveChat(
        context, widget.chatId, _currentUserId)) {
      // Làm mới provider trước khi rời khỏi màn hình
      ref.invalidate(chatProvider(widget.chatId));
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateChatInfo(Chatroom chat) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng ChatroomService để cập nhật thông tin nhóm
      final chatroomService = ref.read(chatroomServiceProvider);
      final success = await chatroomService.updateChatInfo(
        chatId: widget.chatId,
        name: _nameController.text,
        imageFile: _selectedImage,
        currentAvatar: chat.avatar,
        currentUserId: _currentUserId,
      );

      if (success && mounted) {
        // Làm mới provider để cập nhật UI
        ref.invalidate(chatProvider(widget.chatId));
        setState(() {
          _isEditing = false;
          _selectedImage = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ đoạn chat này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Quay lại màn hình danh sách chat
              Navigator.of(context).pop();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin chat'),
        actions: [
          if (chatAsync.hasValue &&
              chatAsync.value != null &&
              chatAsync.value!.isGroup)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _updateChatInfo(chatAsync.value!);
                } else {
                  setState(() {
                    _isEditing = true;
                    _nameController.text = chatAsync.value!.name ?? '';
                  });
                }
              },
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: chatAsync.when(
          data: (chat) {
            if (chat == null) {
              return const Center(
                child: Text('Không tìm thấy thông tin chat'),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sử dụng GroupImagePicker thay vì ChatroomInfoHeader
                Center(
                  child: GroupImagePicker(
                    existingImageUrl: chat.avatar,
                    selectedImage: _selectedImage,
                    isEditable: _isEditing,
                    onImageSelected: _onImageSelected,
                    isGroup: chat.isGroup,
                  ),
                ),
                const SizedBox(height: 16),

                // Sử dụng GroupNameField thay vì triển khai trực tiếp
                Center(
                  child: GroupNameField(
                    controller: _nameController,
                    isEditing: _isEditing,
                    initialName: chat.getDisplayName(_currentUserId),
                  ),
                ),

                // Thông tin thêm về nhóm
                Center(
                  child: Text(
                    chat.isGroup
                        ? '${chat.members.length} thành viên'
                        : 'Chat 1-1',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Tạo ngày ${chat.createdAt.day}/${chat.createdAt.month}/${chat.createdAt.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Phần quản lý thành viên (chỉ hiển thị nếu là nhóm)
                if (chat.isGroup) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thành viên nhóm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (chat.isAdmin(_currentUserId))
                        TextButton.icon(
                          onPressed: _showAddMemberDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm'),
                        ),
                      if (!chat.isAdmin(_currentUserId))
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

                  // Sử dụng MembersList thay vì triển khai trực tiếp - ẩn tiêu đề của MembersList
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: MembersList(
                      chat: chat,
                      currentUserId: _currentUserId,
                      onRemoveMember: _removeMember,
                      showHeader:
                          false, // Không hiển thị tiêu đề trong MembersList
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Phần các tùy chọn khác
                const Divider(),
                const SizedBox(height: 8),
                OtherOptions(
                  chat: chat,
                  onLeaveChat: _leaveChat,
                  onDeleteChat: _showDeleteChatConfirmation,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Lỗi: $error'),
          ),
        ),
      ),
    );
  }
}
