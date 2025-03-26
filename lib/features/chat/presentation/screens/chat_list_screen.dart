import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/chat_providers.dart';
import '../../models/chatroom.dart';
import '../../../../features/authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../../../core/constants/routes_constants.dart';
import '../../../../core/widgets/display_user_image.dart';
import '../../../../core/utils/datetime_helper.dart';
import '../../../../core/utils/global_method.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamProvider trực tiếp
    final chatsAsync = ref.watch(userChatsProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    print('Current user ID: $currentUserId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Tạo nhóm chat mới',
            onPressed: () {
              // Mở màn hình tạo nhóm chat mới
              Navigator.pushNamed(context, RouteConstants.createGroup);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Làm mới danh sách chat
          ref.refresh(userChatsProvider);
        },
        child: chatsAsync.when(
          data: (chats) {
            print('Received ${chats.length} chats');
            for (final chat in chats) {
              print('Chat ID: ${chat.id}');
              print('Chat members: ${chat.members}');
              print('Chat last message: ${chat.lastMessage}');
              print('Chat updated at: ${chat.updatedAt}');
            }
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  'Bạn chưa có cuộc trò chuyện nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                print('Building chat item: ${chat.id}');
                return _buildChatItem(context, chat, currentUserId);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) {
            return Center(
              child: Text('Lỗi: $error'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Mở màn hình tìm kiếm người dùng để bắt đầu cuộc trò chuyện mới
          Navigator.pushNamed(context, RouteConstants.friends);
        },
        tooltip: 'Tạo cuộc trò chuyện mới',
        child: const Icon(Icons.message),
      ),
    );
  }

  // Xây dựng item chat
  Widget _buildChatItem(
      BuildContext context, Chatroom chat, String currentUserId) {
    // Hiển thị thông tin người dùng khác trong chat 1-1
    if (!chat.isGroup) {
      // Lấy ID người dùng khác trong chat 1-1
      final otherUserId = chat.getOtherUserId(currentUserId);

      if (otherUserId.isNotEmpty) {
        final userStream =
            ref.watch(getUserInfoAsStreamByIdProvider(otherUserId));
        final unreadCountStream =
            ref.watch(unreadMessagesCountProvider(chat.id));
        return userStream.when(
          data: (user) {
            // Hiển thị nội dung tin nhắn cuối cùng
            String lastMessageText = '';
            if (chat.lastMessage != null) {
              // Nếu người gửi tin nhắn cuối cùng là người dùng hiện tại
              if (chat.lastMessageSenderId == currentUserId) {
                lastMessageText = 'Bạn: ${chat.lastMessage}';
              } else {
                lastMessageText = chat.lastMessage ?? '';
              }
            }

            return ListTile(
              leading: DisplayUserImage(
                imageUrl: user.profileImage,
                userName: user.fullName,
                radius: 24,
                isOnline: user.isOnline,
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lastMessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              tileColor: unreadCountStream.when(
                data: (count) =>
                    count > 0 ? Colors.blue.withOpacity(0.1) : null,
                loading: () => null,
                error: (_, __) => null,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateTimeHelper.getRelativeTime(chat.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  unreadCountStream.when(
                    data: (count) {
                      if (count > 0) {
                        return Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              onTap: () {
                print(
                    '[ChatListScreen] Navigating to chat with ID: ${chat.id}');
                print('[ChatListScreen] Chat is group: ${chat.isGroup}');
                print('[ChatListScreen] Chat members: ${chat.members}');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chat.id,
                      isGroup: chat.isGroup,
                    ),
                  ),
                );
              },
              onLongPress: () => _showChatOptions(context, chat),
            );
          },
          loading: () => const ListTile(
            leading: CircleAvatar(
              child: CircularProgressIndicator(),
            ),
            title: Text('Đang tải...'),
          ),
          error: (error, stack) => ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.error),
            ),
            title: const Text('Không thể tải thông tin'),
            subtitle: Text(error.toString()),
          ),
        );
      }
    }

    // Hiển thị thông tin nhóm chat
    final unreadCountStream = ref.watch(unreadMessagesCountProvider(chat.id));
    return ListTile(
      leading: DisplayUserImage(
        imageUrl: chat.avatar,
        userName: chat.name ?? 'Nhóm chat',
        radius: 24,
      ),
      title: Text(
        chat.name ?? 'Nhóm chat',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        chat.getDisplayLastMessage(currentUserId),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      tileColor: unreadCountStream.when(
        data: (count) => count > 0 ? Colors.blue.withOpacity(0.1) : null,
        loading: () => null,
        error: (_, __) => null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateTimeHelper.getRelativeTime(chat.updatedAt),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          unreadCountStream.when(
            data: (count) {
              if (count > 0) {
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      onTap: () {
        print('[ChatListScreen] Navigating to chat with ID: ${chat.id}');
        print('[ChatListScreen] Chat is group: ${chat.isGroup}');
        print('[ChatListScreen] Chat members: ${chat.members}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              isGroup: chat.isGroup,
            ),
          ),
        );
      },
      onLongPress: () => _showChatOptions(context, chat),
    );
  }

  // Hiển thị tùy chọn cho đoạn chat
  void _showChatOptions(BuildContext context, Chatroom chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Xóa đoạn chat'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDeleteChat(context, chat.id);
              },
            ),
            if (!chat.isGroup) ...[
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Chặn người dùng'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Chức năng chặn người dùng sẽ được thêm sau
                  showToastMessage(text: 'Chức năng đang phát triển');
                },
              ),
            ],
            if (chat.isGroup &&
                chat.isAdmin(FirebaseAuth.instance.currentUser?.uid ?? '')) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa nhóm'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Chức năng chỉnh sửa nhóm sẽ được thêm sau
                  showToastMessage(text: 'Chức năng đang phát triển');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận xóa đoạn chat
  Future<void> _confirmDeleteChat(BuildContext context, String chatId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        // Xóa chat
        await ref.read(deleteChatProvider(chatId).future);

        // Hiển thị thông báo thành công
        showToastMessage(text: 'Đã xóa đoạn chat');
      } catch (e) {
        // Hiển thị thông báo lỗi
        showToastMessage(text: 'Lỗi: ${e.toString()}');
      }
    }
  }
}
