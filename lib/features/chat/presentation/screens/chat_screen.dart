import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/chat_title.dart';
import '../widgets/group_title.dart';
import '../../../../core/core.dart';
import '../../../../core/utils/log_utils.dart';
import '../../providers/chat_providers.dart';
import '../../providers/chat_repository_provider.dart';
import '../../../../features/authentication/providers/get_user_info_as_stream_by_id_provider.dart';
import '../../../../features/authentication/models/user_model.dart';
import '../widgets/message_input.dart';
import '../widgets/message_list.dart';
import '../../../../core/enums/message_type.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;
  final String? receiverId;
  final bool isGroup;

  const ChatScreen({
    Key? key,
    this.chatId,
    this.receiverId,
    this.isGroup = false,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _inputFocusNode = FocusNode();

  late String _chatId;
  String _receiverId = '';
  late bool _isGroup;
  UserModel? _receiver;

  @override
  void initState() {
    super.initState();
    _isGroup = widget.isGroup;
    ref.logDebug(
        LogService.CHAT, '[CHAT_SCREEN] Initial isGroup value: $_isGroup');
    _initializeChatParameters();
  }

  Future<void> _initializeChatParameters() async {
    ref.logDebug(LogService.CHAT,
        '[CHAT_SCREEN] Initializing with chatId: ${widget.chatId}, receiverId: ${widget.receiverId}, isGroup: $_isGroup');

    // Trường hợp 1: Đã có chatId
    if (widget.chatId != null && widget.chatId!.isNotEmpty) {
      _chatId = widget.chatId!;
      ref.logDebug(LogService.CHAT, '[CHAT_SCREEN] ChatId set to: $_chatId');

      // Nếu không có thông tin isGroup đã truyền vào, thì lấy từ chatProvider
      if (!_isGroup) {
        try {
          final chat = await ref.read(chatProvider(_chatId).future);
          _isGroup = chat?.isGroup ?? false;
          ref.logDebug(LogService.CHAT,
              '[CHAT_SCREEN] Updated isGroup from chat info: $_isGroup');
        } catch (e) {
          ref.logError(
              LogService.CHAT,
              '[CHAT_SCREEN] Error loading chat info: $e',
              e,
              StackTrace.current);
        }
      }

      // Nếu là nhóm chat, không cần receiverId
      if (_isGroup) {
        _receiverId = ''; // Không cần receiverId cho nhóm chat
        ref.logDebug(LogService.CHAT,
            '[CHAT_SCREEN] Group chat detected, receiverId not needed');
        return;
      }

      // Xử lý chat 1-1 (không thay đổi phần này)
      if (widget.receiverId != null && widget.receiverId!.isNotEmpty) {
        _receiverId = widget.receiverId!;
        ref.logDebug(LogService.CHAT,
            '[CHAT_SCREEN] Using provided receiverId: $_receiverId');
      } else {
        // Trích xuất receiverId từ chatId (định dạng: userId1_userId2) cho chat 1-1
        final userIds = _chatId.split('_');
        ref.logDebug(LogService.CHAT,
            '[CHAT_SCREEN] Extracted userIds from chatId: $userIds');

        if (userIds.length == 2) {
          _receiverId = userIds[0] == _currentUserId ? userIds[1] : userIds[0];
          ref.logDebug(LogService.CHAT,
              '[CHAT_SCREEN] Extracted receiverId: $_receiverId');
        } else {
          _receiverId = '';
          ref.logError(
              LogService.CHAT,
              '[CHAT_SCREEN] Could not extract receiverId from chatId, invalid format',
              null,
              StackTrace.current);

          // Hiển thị thông báo lỗi và quay lại chỉ khi xác định đây là chat 1-1 nhưng ID không hợp lệ
          if (mounted) {
            showToastMessage(text: 'Định dạng ID cuộc trò chuyện không hợp lệ');
            Navigator.pop(context);
            return;
          }
        }
      }
    }
    // Trường hợp 2: Chỉ có receiverId
    else if (widget.receiverId != null && widget.receiverId!.isNotEmpty) {
      _receiverId = widget.receiverId!;
      ref.logDebug(LogService.CHAT,
          '[CHAT_SCREEN] Only receiverId provided: $_receiverId');

      // Tạo chatId từ currentUserId và receiverId
      final users = [_currentUserId, _receiverId]..sort();
      _chatId = users.join('_');
      ref.logDebug(LogService.CHAT, '[CHAT_SCREEN] Generated chatId: $_chatId');

      // Lấy thông tin người nhận từ database
      try {
        final userInfo =
            await ref.read(getUserInfoAsStreamByIdProvider(_receiverId).future);
        setState(() {
          _receiver = userInfo;
        });
        ref.logDebug(LogService.CHAT,
            '[CHAT_SCREEN] Receiver info loaded: ${_receiver?.fullName}');
      } catch (e) {
        ref.logError(
            LogService.CHAT,
            '[CHAT_SCREEN] Error loading receiver info: $e',
            e,
            StackTrace.current);
        // Tiếp tục ngay cả khi lấy thông tin người dùng thất bại
      }
    }
    // Trường hợp 3: Không có cả chatId và receiverId
    else {
      _chatId = '';
      _receiverId = '';
      ref.logError(
          LogService.CHAT,
          '[CHAT_SCREEN] No chatId or receiverId provided',
          null,
          StackTrace.current);

      // Hiển thị thông báo lỗi và quay lại
      if (mounted) {
        showToastMessage(
            text: 'Không thể mở cuộc trò chuyện: Thiếu thông tin người nhận');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    ref.logDebug(LogService.CHAT, '[CHAT_SCREEN] Disposing ChatScreen');
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted(String text, MessageType type, String? mediaUrl) async {
    if (text.trim().isEmpty && mediaUrl == null) {
      return;
    }

    ref.logDebug(LogService.CHAT,
        '[CHAT_SCREEN] Sending message, isGroup: $_isGroup, chatId: $_chatId, receiverId: $_receiverId');

    // Kiểm tra điều kiện hợp lệ dựa trên loại chat (sử dụng _isGroup thay vì phải query lại)
    if (_chatId.isEmpty || (!_isGroup && _receiverId.isEmpty)) {
      ref.logError(
          LogService.CHAT,
          '[CHAT_SCREEN] Invalid chat info for sending message',
          null,
          StackTrace.current);
      showToastMessage(
          text: 'Không thể gửi tin nhắn: Thông tin người nhận không hợp lệ');
      return;
    }

    try {
      final sendParams = SendMessageParams(
        chatId: _chatId,
        receiverId:
            _isGroup ? '' : _receiverId, // Nhóm chat không cần receiverId
        content: text,
        type: type,
        mediaUrl: mediaUrl,
        isGroup: _isGroup, // Thêm tham số isGroup
      );

      ref.logDebug(LogService.CHAT,
          '[CHAT_SCREEN] Sending message with params: $sendParams');
      await ref.read(sendMessageProvider(sendParams).future);
      ref.logInfo(LogService.CHAT, '[CHAT_SCREEN] Message sent successfully');
      _scrollToBottom;
    } catch (e) {
      ref.logError(LogService.CHAT, '[CHAT_SCREEN] Error sending message: $e',
          e, StackTrace.current);
      showToastMessage(text: 'Không thể gửi tin nhắn: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(_chatId));
    final chatRepository = ref.watch(chatRepositoryProvider);

    // Lấy thông tin chat để kiểm tra xem có phải là nhóm chat không
    final chatAsync = ref.watch(chatProvider(_chatId));

    return Scaffold(
      appBar: AppBar(
        title: chatAsync.when(
          data: (chat) {
            // Kiểm tra xem có phải nhóm chat không
            if (chat != null && chat.isGroup) {
              return SizedBox(
                width: MediaQuery.of(context).size.width,
                child: GroupTitle(chatId: _chatId),
              );
            } else {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: ChatTitle(userId: _receiverId),
              );
            }
          },
          loading: () => const Text('Đang tải...'),
          error: (error, _) =>
              Text('Lỗi', overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
      body: Column(
        children: [
          // Phần hiển thị danh sách tin nhắn
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                return MessageList(
                  messages: messages,
                  onMessageSeen: (messageId) {
                    chatRepository.markMessageAsSeen(_chatId, messageId);
                  },
                  scrollController: _scrollController,
                  chatId: _chatId,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) {
                return Center(
                  child: Text('Có lỗi xảy ra khi tải tin nhắn: $error'),
                );
              },
            ),
          ),

          // Phần nhập tin nhắn
          MessageInput(
            chatId: _chatId,
            onSend: _handleSubmitted,
            focusNode: _inputFocusNode,
          ),
        ],
      ),
    );
  }
}
