import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chatroom.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import 'chat_repository_provider.dart';
import '../../../core/enums/message_type.dart';
import '../../../features/authentication/models/user_model.dart';
import 'dart:io';

// Provider cho danh sách chat của người dùng
final userChatsProvider = StreamProvider<List<Chatroom>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getUserChats();
});

// Provider cho thông tin chi tiết của một chat
final chatProvider =
    FutureProvider.family<Chatroom?, String>((ref, chatId) async {
  final chatRepository = ref.watch(chatRepositoryProvider);

  try {
    final chat = await chatRepository.getChatById(chatId);
    if (chat != null) {
      return chat;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
});

// Provider cho danh sách tin nhắn của một chat
final chatMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getChatMessages(chatId, limit: 100);
});

// Provider cho việc gửi tin nhắn
final sendMessageProvider =
    FutureProvider.family<void, SendMessageParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  try {
    await chatRepository.sendMessage(
      chatId: params.chatId,
      receiverId: params.receiverId,
      content: params.content,
      type: params.type,
      mediaUrl: params.mediaUrl,
      currentUser: params.currentUser,
      isGroup: params.isGroup,
    );
  } catch (e) {
    throw e; // Re-throw the exception
  }
});

// Provider cho việc đánh dấu tin nhắn đã đọc
final markMessageAsSeenProvider =
    FutureProvider.family<void, MarkMessageAsSeenParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.markMessageAsSeen(params.chatId, params.messageId);
});

// Provider cho việc tải lên file đa phương tiện
final uploadMediaProvider =
    FutureProvider.family<String, UploadMediaParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.uploadMedia(params.file, params.chatId);
});

// Provider cho việc tạo nhóm chat
final createGroupChatProvider =
    FutureProvider.family<String, CreateGroupChatParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.createGroupChat(
    name: params.name,
    avatar: params.avatar,
    members: params.members,
    isPublic: params.isPublic,
  );
});

// Provider cho việc thêm thành viên vào nhóm
final addMemberProvider =
    FutureProvider.family<void, AddMemberParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.addMemberToChat(params.chatId, params.userId);
});

// Provider cho việc xóa thành viên khỏi nhóm
final removeMemberProvider =
    FutureProvider.family<void, RemoveMemberParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.removeMemberFromChat(params.chatId, params.userId);
});

// Provider cho việc cập nhật thông tin nhóm
final updateChatInfoProvider =
    FutureProvider.family<void, UpdateChatInfoParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.updateChatInfo(
    params.chatId,
    name: params.name,
    avatar: params.avatar,
  );
});

// Provider cho số tin nhắn chưa đọc của một chat
final unreadMessagesCountProvider =
    StreamProvider.family<int, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getUnreadMessagesCount(chatId);
});

// Provider cho tổng số tin nhắn chưa đọc từ tất cả các cuộc trò chuyện
final totalUnreadMessagesProvider = StreamProvider<int>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getTotalUnreadMessagesCount();
});

// Provider cho việc xóa tin nhắn
final deleteMessageProvider =
    FutureProvider.family<void, DeleteMessageParams>((ref, params) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.deleteMessage(params.chatId, params.messageId);
});

// Provider cho việc xóa toàn bộ đoạn chat
final deleteChatProvider =
    FutureProvider.family<void, String>((ref, chatId) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.deleteChat(chatId);
});

// Provider cho việc kiểm tra trạng thái của chức năng chat
final checkChatStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, chatId) async {
  final chatRepository = ref.watch(chatRepositoryProvider);
  try {
    final result = await chatRepository.checkChatStatus(chatId);
    return result;
  } catch (e) {
    throw e;
  }
});

// Provider cho việc tạo chatId từ hai userId
final getChatIdProvider = Provider.family<String, List<String>>((ref, userIds) {
  if (userIds.length != 2) {
    throw Exception('Cần cung cấp đúng 2 userId để tạo chatId');
  }

  // Sắp xếp userIds để đảm bảo chatId luôn nhất quán
  final sortedUserIds = [...userIds]..sort();
  return '${sortedUserIds[0]}_${sortedUserIds[1]}';
});

// Các class params để truyền dữ liệu
class SendMessageParams {
  final String chatId;
  final String receiverId;
  final String content;
  final MessageType type;
  final String? mediaUrl;
  final UserModel? currentUser;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool isGroup;

  SendMessageParams({
    required this.chatId,
    required this.receiverId,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.currentUser,
    this.otherUserName,
    this.otherUserAvatar,
    this.isGroup = false,
  });
}

class MarkMessageAsSeenParams {
  final String chatId;
  final String messageId;

  MarkMessageAsSeenParams({
    required this.chatId,
    required this.messageId,
  });
}

class UploadMediaParams {
  final String chatId;
  final dynamic file;

  UploadMediaParams({
    required this.chatId,
    required this.file,
  });
}

class CreateGroupChatParams {
  final String name;
  final String? avatar;
  final List<String> members;
  final bool isPublic;

  CreateGroupChatParams({
    required this.name,
    this.avatar,
    required this.members,
    required this.isPublic,
  });
}

class AddMemberParams {
  final String chatId;
  final String userId;

  AddMemberParams({
    required this.chatId,
    required this.userId,
  });
}

class RemoveMemberParams {
  final String chatId;
  final String userId;

  RemoveMemberParams({
    required this.chatId,
    required this.userId,
  });
}

class UpdateChatInfoParams {
  final String chatId;
  final String? name;
  final String? avatar;

  UpdateChatInfoParams({
    required this.chatId,
    this.name,
    this.avatar,
  });
}

class DeleteMessageParams {
  final String chatId;
  final String messageId;

  DeleteMessageParams({
    required this.chatId,
    required this.messageId,
  });
}
