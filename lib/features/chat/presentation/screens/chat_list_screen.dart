import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/chat_providers.dart';
import '../../models/chatroom.dart';
import '../../../../core/constants/routes_constants.dart';
import '../../../../core/utils/global_method.dart';
import '../../../../core/widgets/loading_indicator.dart';
import 'chat_screen.dart';
import '../widgets/chat_list_item.dart';

/// Màn hình danh sách đoạn chat
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildChatList(chatsAsync),
      floatingActionButton: _buildNewChatButton(),
    );
  }

  /// Xây dựng AppBar với các actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('chat.title'.tr()),
      actions: [
        IconButton(
          icon: const Icon(Icons.group_add),
          tooltip: 'chat.group.create'.tr(),
          onPressed: _navigateToCreateGroup,
        ),
      ],
    );
  }

  /// Chuyển đến màn hình tạo nhóm chat
  void _navigateToCreateGroup() {
    Navigator.pushNamed(context, RouteConstants.createGroup);
  }

  /// Xây dựng danh sách chat với RefreshIndicator
  Widget _buildChatList(AsyncValue<List<Chatroom>> chatsAsync) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userChatsProvider);
      },
      child: chatsAsync.when(
        data: (chats) => _buildChatListContent(chats),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => _buildErrorView(error, stack),
      ),
    );
  }

  /// Xây dựng nội dung danh sách chat khi đã tải xong
  Widget _buildChatListContent(List<Chatroom> chats) {
    if (chats.isEmpty) {
      return _buildEmptyListView();
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          currentUserId: _currentUserId,
          onTap: () => _navigateToChatScreen(chat),
          onLongPress: () => _showChatOptions(context, chat),
        );
      },
    );
  }

  /// Hiển thị khi danh sách chat rỗng
  Widget _buildEmptyListView() {
    return Center(
      child: Text(
        'chat.empty'.tr(),
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Hiển thị khi có lỗi tải danh sách chat
  Widget _buildErrorView(Object error, StackTrace? stack) {
    return Center(
      child: Text('${'errors.unknown'.tr()}: $error'),
    );
  }

  /// Button tạo cuộc trò chuyện mới
  Widget _buildNewChatButton() {
    return FloatingActionButton(
      onPressed: _navigateToFriends,
      tooltip: 'chat.new_message'.tr(),
      child: const Icon(Icons.message),
    );
  }

  /// Chuyển đến màn hình bạn bè để tạo chat mới
  void _navigateToFriends() {
    Navigator.pushNamed(context, RouteConstants.friends);
  }

  /// Chuyển đến màn hình chat
  void _navigateToChatScreen(Chatroom chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id,
          isGroup: chat.isGroup,
        ),
      ),
    );
  }

  /// Hiển thị các tùy chọn cho đoạn chat
  void _showChatOptions(BuildContext context, Chatroom chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => ChatOptionsSheet(
        chat: chat,
        currentUserId: _currentUserId,
        onDeletePressed: () {
          Navigator.of(context).pop();
          _confirmDeleteChat(context, chat.id);
        },
      ),
    );
  }

  /// Hiển thị hộp thoại xác nhận xóa đoạn chat
  Future<void> _confirmDeleteChat(BuildContext context, String chatId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => const DeleteChatConfirmDialog(),
        ) ??
        false;

    if (confirmed) {
      await _performChatDeletion(chatId);
    }
  }

  /// Thực hiện việc xóa chat
  Future<void> _performChatDeletion(String chatId) async {
    try {
      await ref.read(deleteChatProvider(chatId).future);
      showToastMessage(text: 'chat.delete_success'.tr());
    } catch (e) {
      showToastMessage(text: '${'errors.unknown'.tr()}: ${e.toString()}');
    }
  }
}

/// Widget hiển thị danh sách các tùy chọn cho một đoạn chat
class ChatOptionsSheet extends StatelessWidget {
  final Chatroom chat;
  final String currentUserId;
  final VoidCallback onDeletePressed;

  const ChatOptionsSheet({
    Key? key,
    required this.chat,
    required this.currentUserId,
    required this.onDeletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDeleteOption(context),
          if (!chat.isGroup) _buildBlockUserOption(context),
          if (chat.isGroup && chat.isAdmin(currentUserId))
            _buildEditGroupOption(context),
        ],
      ),
    );
  }

  Widget _buildDeleteOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Xóa đoạn chat'),
      onTap: onDeletePressed,
    );
  }

  Widget _buildBlockUserOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.block),
      title: const Text('Chặn người dùng'),
      onTap: () {
        Navigator.of(context).pop();
        showToastMessage(text: 'Chức năng đang phát triển');
      },
    );
  }

  Widget _buildEditGroupOption(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.edit),
      title: const Text('Chỉnh sửa nhóm'),
      onTap: () {
        Navigator.of(context).pop();
        showToastMessage(text: 'Chức năng đang phát triển');
      },
    );
  }
}

/// Hộp thoại xác nhận xóa chat
class DeleteChatConfirmDialog extends StatelessWidget {
  const DeleteChatConfirmDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ đoạn chat này không? Hành động này không thể hoàn tác.'),
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
    );
  }
}
