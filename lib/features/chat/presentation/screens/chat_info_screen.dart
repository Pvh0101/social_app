import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../models/chatroom.dart';
import '../../providers/chat_providers.dart';
import '../../providers/chat_repository_provider.dart';
import '../../../../features/authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/custom_text_field.dart';

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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      showToastMessage(text: 'Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _updateChatInfo(Chatroom chat) async {
    if (!chat.isAdmin(_currentUserId)) {
      showToastMessage(text: 'Bạn không có quyền cập nhật thông tin nhóm');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      showToastMessage(text: 'Tên nhóm không được để trống');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      String? avatarUrl;

      // Upload ảnh mới nếu có
      if (_selectedImage != null) {
        avatarUrl =
            await chatRepository.uploadMedia(_selectedImage!, widget.chatId);
      }

      // Cập nhật thông tin nhóm
      await chatRepository.updateChatInfo(
        widget.chatId,
        name: _nameController.text.trim(),
        avatar: avatarUrl ?? chat.avatar,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
          _selectedImage = null;
        });
        showToastMessage(text: 'Cập nhật thông tin nhóm thành công');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToastMessage(text: 'Lỗi khi cập nhật thông tin nhóm: $e');
      }
    }
  }

  Future<void> _addMember(Chatroom chat) async {
    // Hiển thị dialog để nhập ID người dùng cần thêm
    final userId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: CustomTextField(
          hintText: 'Nhập ID người dùng',
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final textField = context.findRenderObject() as RenderBox;
              final controller = (textField.parent as TextField).controller;
              Navigator.of(context).pop(controller?.text);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (userId == null || userId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.addMemberToChat(widget.chatId, userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToastMessage(text: 'Thêm thành viên thành công');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToastMessage(text: 'Lỗi khi thêm thành viên: $e');
      }
    }
  }

  Future<void> _removeMember(Chatroom chat, String userId) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa thành viên'),
            content: const Text(
                'Bạn có chắc chắn muốn xóa thành viên này khỏi nhóm?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.removeMemberFromChat(widget.chatId, userId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToastMessage(text: 'Xóa thành viên thành công');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToastMessage(text: 'Lỗi khi xóa thành viên: $e');
      }
    }
  }

  Future<void> _leaveChat(Chatroom chat) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận rời nhóm'),
            content:
                const Text('Bạn có chắc chắn muốn rời khỏi nhóm chat này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Rời nhóm', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      await chatRepository.removeMemberFromChat(widget.chatId, _currentUserId);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop(); // Quay lại màn hình danh sách chat
        showToastMessage(text: 'Đã rời khỏi nhóm chat');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showToastMessage(text: 'Lỗi khi rời nhóm: $e');
      }
    }
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
      body: chatAsync.when(
        data: (chat) {
          if (chat == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin chat'),
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Phần thông tin nhóm
                  _buildChatInfo(chat),
                  const SizedBox(height: 24),

                  // Phần quản lý thành viên (chỉ hiển thị nếu là nhóm)
                  if (chat.isGroup) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildMemberManagement(chat),
                    const SizedBox(height: 24),
                  ],

                  // Phần các tùy chọn khác
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildOtherOptions(chat),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
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
    );
  }

  Widget _buildChatInfo(Chatroom chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar nhóm
        GestureDetector(
          onTap: _isEditing ? _pickImage : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : chat.avatar != null
                        ? NetworkImage(chat.avatar!) as ImageProvider
                        : null,
                child: chat.avatar == null && _selectedImage == null
                    ? Icon(
                        chat.isGroup ? Icons.group : Icons.person,
                        size: 50,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tên nhóm
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: CustomTextField(
              controller: _nameController,
              hintText: 'Tên nhóm',
              keyboardType: TextInputType.text,
            ),
          )
        else
          Text(
            chat.getDisplayName(_currentUserId),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 8),

        // Thông tin thêm
        Text(
          chat.isGroup ? '${chat.members.length} thành viên' : 'Chat 1-1',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tạo ngày ${chat.createdAt.day}/${chat.createdAt.month}/${chat.createdAt.year}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberManagement(Chatroom chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onPressed: () => _addMember(chat),
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...chat.members.map((userId) => _buildMemberItem(chat, userId)),
      ],
    );
  }

  Widget _buildMemberItem(Chatroom chat, String userId) {
    final isAdmin = chat.isAdmin(userId);
    final isSelf = userId == _currentUserId;

    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(getUserInfoAsStreamByIdProvider(userId));

        return userAsync.when(
          data: (user) {
            return ListTile(
              leading: DisplayUserImage(
                imageUrl: user.profileImage,
                radius: 20,
              ),
              title: Row(
                children: [
                  Text(user.fullName),
                  if (isSelf)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '(Bạn)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: chat.isAdmin(_currentUserId) && !isSelf
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () => _removeMember(chat, userId),
                    )
                  : null,
            );
          },
          loading: () => const ListTile(
            leading: CircleAvatar(
              radius: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Đang tải...'),
          ),
          error: (error, stack) => ListTile(
            leading: CircleAvatar(
              radius: 20,
              child: Icon(Icons.error),
            ),
            title: Text('Lỗi: $error'),
          ),
        );
      },
    );
  }

  Widget _buildOtherOptions(Chatroom chat) {
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
            onTap: () => _leaveChat(chat),
          ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Xóa đoạn chat'),
          onTap: () {
            Navigator.of(context).pop();
            _showDeleteChatConfirmation(context);
          },
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

  void _showDeleteChatConfirmation(BuildContext context) {
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
              // Xóa chat (chức năng này đã có sẵn trong ChatScreen)
              // Quay lại màn hình danh sách chat
              Navigator.of(context).pop();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
