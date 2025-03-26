import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

import '../../../core/enums/message_type.dart';
import '../../../core/utils/log_utils.dart';
import '../models/message.dart';
import '../models/chatroom.dart';
import '../../../features/notification/repository/notification_repository.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../core/services/media/media_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  final String _currentUserId;
  final _notificationRepository = NotificationRepository();
  final _mediaService = MediaService();
  final logger = Logger();

  ChatRepository({
    required FirebaseFirestore firestore,
    required String currentUserId,
  })  : _firestore = firestore,
        _currentUserId = currentUserId {
    logInfo(LogService.CHAT,
        '[CHAT_REPOSITORY] Khởi tạo với ID người dùng: $_currentUserId');
  }

  // Lấy reference đến collection messages của một chat
  CollectionReference<Map<String, dynamic>> _getMessagesRef(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages');
  }

  // Lấy reference đến document của một chat
  DocumentReference<Map<String, dynamic>> _getChatRef(String chatId) {
    return _firestore.collection('chats').doc(chatId);
  }

  // Lấy thông tin người dùng từ Firestore
  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    logInfo(LogService.CHAT, 'Đang lấy thông tin người dùng có ID: $userId');
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      logInfo(
          LogService.CHAT, 'Tài liệu người dùng tồn tại: ${userDoc.exists}');

      if (!userDoc.exists) {
        logInfo(LogService.CHAT, 'Không tìm thấy tài liệu người dùng');
        // Thay vì throw exception, trả về thông tin mặc định
        return {
          'uid': userId,
          'fullName': 'Người dùng',
          'profileImage': null,
          'email': 'unknown@example.com',
        };
      }

      final userData = userDoc.data()!;
      logInfo(LogService.CHAT, 'Dữ liệu người dùng: $userData');
      return userData;
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi trong _getUserInfo: $e');
      // Trả về thông tin mặc định thay vì throw exception
      return {
        'uid': userId,
        'fullName': 'Người dùng',
        'profileImage': null,
        'email': 'unknown@example.com',
      };
    }
  }

  // Gửi tin nhắn - phương thức chính, phân loại và định tuyến đến các phương thức xử lý cụ thể
  Future<void> sendMessage({
    required String chatId,
    required String content,
    required MessageType type,
    String receiverId = '',
    String? mediaUrl,
    UserModel? currentUser,
    bool isGroup = false,
  }) async {
    logInfo(LogService.CHAT, '===== BẮT ĐẦU GỬI TIN NHẮN =====');
    logInfo(LogService.CHAT,
        'Tham số: chatId=$chatId, receiverId=$receiverId, content=$content, type=${type.name}, mediaUrl=$mediaUrl, isGroup=$isGroup');
    logInfo(LogService.CHAT, 'ID người dùng hiện tại: $_currentUserId');

    try {
      // 2. Lấy thông tin người gửi
      final senderInfo = await _getSenderInfo(currentUser);

      // 3. Kiểm tra chat đã tồn tại chưa
      final chatExists = await _checkChatExists(chatId);
      logInfo(LogService.CHAT, 'Chat tồn tại: $chatExists');

      // 4. Xử lý tùy theo loại chat và trạng thái tồn tại
      if (isGroup) {
        // Xử lý trường hợp chat nhóm
        await _handleGroupMessage(
          chatId: chatId,
          content: content,
          type: type,
          mediaUrl: mediaUrl,
          senderInfo: senderInfo,
          chatExists: chatExists,
          currentUser: currentUser,
        );
      } else {
        // Xử lý trường hợp chat 1-1
        await _handleOneToOneMessage(
          chatId: chatId,
          receiverId: receiverId,
          content: content,
          type: type,
          mediaUrl: mediaUrl,
          senderInfo: senderInfo,
          chatExists: chatExists,
          currentUser: currentUser,
        );
      }

      logInfo(
          LogService.CHAT, '===== KẾT THÚC GỬI TIN NHẮN - THÀNH CÔNG =====');
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi trong sendMessage: $e');
      logError(LogService.CHAT, '===== KẾT THÚC GỬI TIN NHẮN - LỖI =====');
      throw Exception('Không thể gửi tin nhắn: $e');
    }
  }

  // Kiểm tra chat đã tồn tại chưa
  Future<bool> _checkChatExists(String chatId) async {
    logInfo(LogService.CHAT, 'Kiểm tra xem chat có tồn tại không: $chatId');
    final chatDoc = await _getChatRef(chatId).get();
    logInfo(
        LogService.CHAT, 'Đã lấy tài liệu chat, tồn tại: ${chatDoc.exists}');
    return chatDoc.exists;
  }

  // Xử lý tin nhắn nhóm
  Future<void> _handleGroupMessage({
    required String chatId,
    required String content,
    required MessageType type,
    String? mediaUrl,
    required Map<String, dynamic> senderInfo,
    required bool chatExists,
    UserModel? currentUser,
  }) async {
    logInfo(LogService.CHAT, 'Xử lý tin nhắn nhóm cho chatId: $chatId');

    // 1. Nếu chat nhóm không tồn tại, báo lỗi
    if (!chatExists) {
      logError(
          LogService.CHAT, 'Nhóm chat không tồn tại, không thể gửi tin nhắn');
      throw Exception('Nhóm chat không tồn tại, vui lòng tạo nhóm trước');
    }

    // 2. Lấy thông tin chat
    final chatDoc = await _getChatRef(chatId).get();
    final chatroom = Chatroom.fromMap(chatDoc.data()!);

    // 3. Kiểm tra quyền gửi tin nhắn
    if (!chatroom.isMember(_currentUserId)) {
      logError(LogService.CHAT, 'Người dùng không phải là thành viên của nhóm');
      throw Exception('Bạn không phải là thành viên của cuộc trò chuyện này');
    }

    // 4. Tạo tin nhắn
    final message = _createMessage(chatId, content, type, mediaUrl, senderInfo);

    // 5. Cập nhật thông tin chat
    await _updateChatLastMessage(chatId, message);

    // 6. Lưu tin nhắn vào Firestore
    await _saveMessage(chatId, message);

    // 7. [Tùy chọn] Gửi thông báo cho tất cả thành viên nhóm
    // Hiện tại chưa xử lý thông báo nhóm, có thể thêm trong tương lai
    logInfo(LogService.CHAT, 'Hoàn thành xử lý tin nhắn nhóm');
  }

  // Xử lý tin nhắn 1-1
  Future<void> _handleOneToOneMessage({
    required String chatId,
    required String receiverId,
    required String content,
    required MessageType type,
    String? mediaUrl,
    required Map<String, dynamic> senderInfo,
    required bool chatExists,
    UserModel? currentUser,
  }) async {
    logInfo(LogService.CHAT,
        'Xử lý tin nhắn 1-1 cho chatId: $chatId, receiverId: $receiverId');

    // 1. Tạo tin nhắn
    final message = _createMessage(chatId, content, type, mediaUrl, senderInfo);

    // 2. Xử lý tùy theo chat đã tồn tại hay chưa
    if (!chatExists) {
      // 2.1. Tạo chat mới nếu chưa tồn tại
      logInfo(LogService.CHAT, 'Chat 1-1 chưa tồn tại, tạo mới');
      await _createNewOneToOneChat(chatId, receiverId, message, senderInfo);
    } else {
      // 2.2. Cập nhật chat hiện có
      logInfo(LogService.CHAT, 'Chat 1-1 đã tồn tại, cập nhật');
      await _updateChatLastMessage(chatId, message);
    }

    // 3. Lưu tin nhắn vào Firestore
    await _saveMessage(chatId, message);

    // 4. Gửi thông báo cho người nhận
    await _sendNotificationToUser(
      receiverId: receiverId,
      content: content,
      chatId: chatId,
      currentUser: currentUser,
      senderInfo: senderInfo,
    );

    logInfo(LogService.CHAT, 'Hoàn thành xử lý tin nhắn 1-1');
  }

  // Tạo chat 1-1 mới
  Future<void> _createNewOneToOneChat(
    String chatId,
    String receiverId,
    Message message,
    Map<String, dynamic> senderInfo,
  ) async {
    logInfo(LogService.CHAT, 'Tạo mới chat 1-1 với receiverId: $receiverId');

    // 1. Lấy thông tin người nhận
    Map<String, dynamic> receiverInfo;
    try {
      logInfo(
          LogService.CHAT, 'Đang lấy thông tin người nhận có ID: $receiverId');
      receiverInfo = await _getUserInfo(receiverId);
      logInfo(LogService.CHAT, 'Đã lấy thông tin người nhận: $receiverInfo');
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi khi lấy thông tin người nhận: $e');
      receiverInfo = {
        'uid': receiverId,
        'fullName': 'Người dùng',
        'profileImage': null,
        'email': 'unknown@example.com',
      };
      logInfo(LogService.CHAT,
          'Sử dụng thông tin người nhận mặc định: $receiverInfo');
    }

    // 2. Tạo tên chat dựa trên tên người gửi và người nhận
    final chatName = '${senderInfo['fullName']} và ${receiverInfo['fullName']}';
    logInfo(LogService.CHAT, 'Đã tạo tên chat: $chatName');

    // 3. Tạo đối tượng Chatroom mới
    final newChat = Chatroom(
      id: chatId,
      name: chatName,
      avatar: null,
      isGroup: false, // Chat 1-1
      isPublic: false,
      members: [_currentUserId, receiverId],
      admins: [_currentUserId, receiverId],
      lastMessageId: message.id,
      lastMessage: message.getDisplayContent(),
      lastMessageType: message.type,
      lastMessageSenderId: message.senderId,
      updatedAt: message.createdAt,
      createdBy: _currentUserId,
      createdAt: message.createdAt,
    );

    logInfo(LogService.CHAT, 'Dữ liệu chat mới: ${newChat.toMap()}');

    // 4. Lưu chat mới vào Firestore
    try {
      logInfo(LogService.CHAT, 'Đang lưu chat mới vào Firestore');
      await _getChatRef(chatId).set(newChat.toMap());
      logInfo(LogService.CHAT, 'Đã tạo chat mới thành công');
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi khi tạo chat mới: $e');
      throw Exception('Không thể tạo cuộc trò chuyện mới: $e');
    }
  }

  // Cập nhật thông tin chat với tin nhắn cuối cùng
  Future<void> _updateChatLastMessage(String chatId, Message message) async {
    logInfo(LogService.CHAT,
        'Cập nhật thông tin tin nhắn cuối cùng cho chat: $chatId');

    final updateData = <String, dynamic>{
      'lastMessageId': message.id,
      'lastMessage': message.getDisplayContent(),
      'lastMessageType': message.type.name,
      'lastMessageSenderId': message.senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    logInfo(LogService.CHAT, 'Dữ liệu cập nhật: $updateData');

    try {
      logInfo(LogService.CHAT, 'Đang cập nhật chat trong Firestore');
      await _getChatRef(chatId).update(updateData);
      logInfo(LogService.CHAT, 'Đã cập nhật chat thành công');
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi khi cập nhật chat: $e');
      throw Exception('Không thể cập nhật cuộc trò chuyện: $e');
    }
  }

  // Gửi thông báo cho người nhận trong chat 1-1
  Future<void> _sendNotificationToUser({
    required String receiverId,
    required String content,
    required String chatId,
    UserModel? currentUser,
    required Map<String, dynamic> senderInfo,
  }) async {
    logInfo(LogService.CHAT, 'Đang gửi thông báo cho người dùng: $receiverId');
    try {
      // Tạo UserModel từ thông tin người gửi nếu chưa có
      final sender = currentUser ??
          UserModel(
            uid: _currentUserId,
            email: senderInfo['email'] as String,
            fullName: senderInfo['fullName'] as String,
            profileImage: senderInfo['profileImage'] as String?,
          );
      logInfo(LogService.CHAT,
          'Thông tin người gửi cho thông báo: ${sender.toMap()}');

      logInfo(LogService.CHAT, 'Đang tạo thông báo tin nhắn');
      await _notificationRepository.createMessageNotification(
        receiverId: receiverId,
        sender: sender,
        chatId: chatId,
        messageContent: content,
      );
      logInfo(LogService.CHAT, 'Đã gửi thông báo thành công');
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi khi gửi thông báo: $e');
      // Tiếp tục xử lý tin nhắn ngay cả khi gửi thông báo thất bại
    }
  }

  // 2. Lấy thông tin người gửi
  Future<Map<String, dynamic>> _getSenderInfo(UserModel? currentUser) async {
    if (currentUser != null) {
      // Nếu đã có thông tin người dùng hiện tại, sử dụng nó
      final senderInfo = {
        'uid': currentUser.uid,
        'fullName': currentUser.fullName,
        'profileImage': currentUser.profileImage,
        'email': currentUser.email,
      };
      logInfo(LogService.CHAT,
          'Sử dụng thông tin người dùng đã cung cấp: $senderInfo');
      return senderInfo;
    } else {
      // Nếu không có, lấy từ Firestore
      try {
        logInfo(LogService.CHAT,
            'Đang lấy thông tin người dùng từ Firestore với ID: $_currentUserId');
        final senderInfo = await _getUserInfo(_currentUserId);
        logInfo(LogService.CHAT,
            'Đã lấy thông tin người dùng từ Firestore: $senderInfo');
        return senderInfo;
      } catch (e) {
        logError(LogService.CHAT, 'Lỗi khi lấy thông tin người dùng: $e');
        throw Exception('Không thể lấy thông tin người dùng: $e');
      }
    }
  }

  // 3. Tạo đối tượng tin nhắn mới
  Message _createMessage(String chatId, String content, MessageType type,
      String? mediaUrl, Map<String, dynamic> senderInfo) {
    logInfo(LogService.CHAT, 'Đang tạo đối tượng tin nhắn mới');
    final message = Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: _currentUserId,
      senderName: senderInfo['fullName'] as String,
      senderAvatar: senderInfo['profileImage'] as String?,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      seenBy: {_currentUserId}, // Người gửi tự động đánh dấu là đã xem
      createdAt: DateTime.now(),
    );

    logInfo(LogService.CHAT, 'Đã tạo đối tượng tin nhắn với ID: ${message.id}');
    logInfo(LogService.CHAT, 'Chi tiết tin nhắn: ${message.toMap()}');
    return message;
  }

  // Lưu tin nhắn vào Firestore
  Future<void> _saveMessage(String chatId, Message message) async {
    logInfo(LogService.CHAT, 'Đang thêm tin nhắn vào collection messages');
    try {
      logInfo(LogService.CHAT, 'Đang lưu tin nhắn với ID: ${message.id}');
      await _getMessagesRef(chatId).doc(message.id).set(message.toMap());
      logInfo(LogService.CHAT, 'Đã thêm tin nhắn thành công');
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi khi thêm tin nhắn: $e');
      throw Exception('Không thể thêm tin nhắn: $e');
    }
  }

  // Lấy danh sách chat của người dùng
  Stream<List<Chatroom>> getUserChats() {
    logInfo(LogService.CHAT, '===== BẮT ĐẦU LẤY DANH SÁCH CHAT =====');
    logInfo(LogService.CHAT,
        'Đang lấy danh sách chat cho người dùng: $_currentUserId');

    return _firestore
        .collection('chats')
        .where('members', arrayContains: _currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      logInfo(LogService.CHAT,
          'Đã nhận snapshot chat với ${snapshot.docs.length} cuộc trò chuyện');

      final chats = snapshot.docs
          .map((doc) {
            try {
              logInfo(LogService.CHAT, 'Đang xử lý tài liệu chat: ${doc.id}');
              final chatroom = Chatroom.fromMap(doc.data());
              logInfo(LogService.CHAT,
                  'Đã phân tích chat thành công: ${chatroom.id}, tên: ${chatroom.name}');
              return chatroom;
            } catch (e) {
              logError(LogService.CHAT,
                  'Lỗi khi phân tích tài liệu chat ${doc.id}: $e');
              // Bỏ qua chat không hợp lệ thay vì gây crash
              return null;
            }
          })
          .whereType<Chatroom>()
          .toList();

      logInfo(
          LogService.CHAT, 'Đã xử lý thành công ${chats.length} chat hợp lệ');
      logInfo(LogService.CHAT, '===== KẾT THÚC LẤY DANH SÁCH CHAT =====');
      return chats;
    });
  }

  // Lấy thông tin chi tiết của một chat
  Future<Chatroom?> getChatById(String chatId) async {
    logInfo(LogService.CHAT, '===== BẮT ĐẦU LẤY THÔNG TIN CHAT =====');
    logInfo(LogService.CHAT, 'Đang lấy thông tin chat với ID: $chatId');

    try {
      final doc = await _getChatRef(chatId).get();
      logInfo(LogService.CHAT, 'Tài liệu chat tồn tại: ${doc.exists}');

      if (!doc.exists) {
        logInfo(LogService.CHAT, 'Không tìm thấy chat, trả về null');
        return null;
      }

      final chatroom = Chatroom.fromMap(doc.data()!);
      logInfo(LogService.CHAT,
          'Đã lấy thông tin chat thành công: ${chatroom.name}');
      logInfo(LogService.CHAT, '===== KẾT THÚC LẤY THÔNG TIN CHAT =====');
      return chatroom;
    } catch (e) {
      logError(LogService.CHAT, 'Lỗi khi lấy thông tin chat: $e');
      logInfo(LogService.CHAT, '===== KẾT THÚC LẤY THÔNG TIN CHAT - LỖI =====');
      throw Exception('Không thể lấy thông tin chat: $e');
    }
  }

  // Lấy danh sách tin nhắn của một chat
  Stream<List<Message>> getChatMessages(String chatId, {int limit = 100}) {
    logInfo(LogService.CHAT, '===== BẮT ĐẦU LẤY TIN NHẮN CHAT =====');
    logInfo(LogService.CHAT,
        'Đang lấy tin nhắn cho chatId: $chatId với giới hạn: $limit');

    return _getMessagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      logInfo(LogService.CHAT,
          'Đã nhận snapshot tin nhắn với ${snapshot.docs.length} tin nhắn');

      final messages = snapshot.docs
          .map((doc) {
            try {
              logInfo(
                  LogService.CHAT, 'Đang xử lý tài liệu tin nhắn: ${doc.id}');
              final message = Message.fromMap(doc.data());

              // Đánh dấu tin nhắn đã xem nếu chưa
              if (!message.isSeenBy(_currentUserId)) {
                logInfo(LogService.CHAT,
                    'Tin nhắn ${message.id} chưa được người dùng hiện tại xem, đánh dấu là đã xem');
                markMessageAsSeen(chatId, message.id);
              }

              logInfo(LogService.CHAT,
                  'Đã phân tích tin nhắn thành công: ${message.id}, loại: ${message.type.name}');
              return message;
            } catch (e) {
              logError(LogService.CHAT,
                  'Lỗi khi phân tích tài liệu tin nhắn ${doc.id}: $e');
              // Bỏ qua tin nhắn không hợp lệ thay vì gây crash
              return null;
            }
          })
          .whereType<Message>()
          .toList();

      // Sắp xếp tin nhắn theo thời gian giảm dần để hiển thị đúng với ListView.reverse=true
      // Tin nhắn mới nhất (thời gian lớn hơn) sẽ ở vị trí cao hơn trong danh sách
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      logInfo(LogService.CHAT,
          'Đã xử lý thành công ${messages.length} tin nhắn hợp lệ');
      logInfo(LogService.CHAT, '===== KẾT THÚC LẤY TIN NHẮN CHAT =====');
      return messages;
    });
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    try {
      await _getMessagesRef(chatId).doc(messageId).update({
        'seenBy': FieldValue.arrayUnion([_currentUserId])
      });
    } catch (e) {
      throw Exception('Không thể đánh dấu tin nhắn đã đọc: $e');
    }
  }

  // Tạo nhóm chat mới
  Future<String> createGroupChat({
    required String name,
    String? avatar,
    required List<String> members,
    required bool isPublic,
  }) async {
    try {
      // Thêm người tạo vào danh sách thành viên nếu chưa có
      if (!members.contains(_currentUserId)) {
        members.add(_currentUserId);
      }

      final chatId = _uuid.v4();
      final now = DateTime.now();

      final newChat = Chatroom(
        id: chatId,
        name: name,
        avatar: avatar,
        isGroup: true,
        isPublic: isPublic,
        members: members,
        admins: [_currentUserId], // Người tạo là admin
        updatedAt: now,
        createdBy: _currentUserId,
        createdAt: now,
      );

      await _getChatRef(chatId).set(newChat.toMap());

      return chatId;
    } catch (e) {
      throw Exception('Không thể tạo nhóm chat: $e');
    }
  }

  // Thêm thành viên vào nhóm
  Future<void> addMemberToChat(String chatId, String userId) async {
    try {
      final chatDoc = await _getChatRef(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Không tìm thấy nhóm chat');
      }

      final chatroom = Chatroom.fromMap(chatDoc.data()!);
      if (!chatroom.isAdmin(_currentUserId)) {
        throw Exception('Bạn không có quyền thêm thành viên');
      }

      if (chatroom.isMember(userId)) {
        throw Exception('Người dùng đã là thành viên của nhóm');
      }

      await _getChatRef(chatId).update({
        'members': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Không thể thêm thành viên: $e');
    }
  }

  // Xóa thành viên khỏi nhóm
  Future<void> removeMemberFromChat(String chatId, String userId) async {
    try {
      final chatDoc = await _getChatRef(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Không tìm thấy nhóm chat');
      }

      final chatroom = Chatroom.fromMap(chatDoc.data()!);
      if (!chatroom.isAdmin(_currentUserId) && _currentUserId != userId) {
        throw Exception('Bạn không có quyền xóa thành viên');
      }

      if (!chatroom.isMember(userId)) {
        throw Exception('Người dùng không phải là thành viên của nhóm');
      }

      // Nếu là admin và đang rời nhóm, cần chuyển quyền admin
      if (chatroom.isAdmin(userId) && userId == _currentUserId) {
        // Tìm admin khác
        final otherAdmins =
            chatroom.admins.where((id) => id != _currentUserId).toList();
        if (otherAdmins.isEmpty) {
          // Nếu không có admin khác, chọn một thành viên làm admin
          final otherMembers =
              chatroom.members.where((id) => id != _currentUserId).toList();
          if (otherMembers.isEmpty) {
            // Nếu không còn ai, xóa nhóm
            await _getChatRef(chatId).delete();
            return;
          }
          // Chọn thành viên đầu tiên làm admin
          await _getChatRef(chatId).update({
            'admins': FieldValue.arrayUnion([otherMembers.first]),
            'members': FieldValue.arrayRemove([userId]),
          });
        } else {
          // Nếu có admin khác, chỉ cần rời nhóm
          await _getChatRef(chatId).update({
            'admins': FieldValue.arrayRemove([userId]),
            'members': FieldValue.arrayRemove([userId]),
          });
        }
      } else {
        // Nếu không phải admin đang rời nhóm, chỉ cần xóa khỏi danh sách thành viên
        await _getChatRef(chatId).update({
          'members': FieldValue.arrayRemove([userId]),
          'admins': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (e) {
      throw Exception('Không thể xóa thành viên: $e');
    }
  }

  // Cập nhật thông tin nhóm
  Future<void> updateChatInfo(String chatId,
      {String? name, String? avatar}) async {
    try {
      final chatDoc = await _getChatRef(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Không tìm thấy nhóm chat');
      }

      final chatroom = Chatroom.fromMap(chatDoc.data()!);
      if (!chatroom.isAdmin(_currentUserId)) {
        throw Exception('Bạn không có quyền cập nhật thông tin nhóm');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatar != null) updates['avatar'] = avatar;

      await _getChatRef(chatId).update(updates);
    } catch (e) {
      throw Exception('Không thể cập nhật thông tin nhóm: $e');
    }
  }

  // Tải lên file đa phương tiện
  Future<String> uploadMedia(File file, String chatId) async {
    try {
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$fileExtension';
      final path = 'chats/$chatId/media/$fileName';

      // Sử dụng uploadSingleFile thay vì uploadMedia
      final uploadResult = await _mediaService.uploadSingleFile(
        file: file,
        path: path,
      );

      if (!uploadResult.isSuccess || uploadResult.downloadUrl == null) {
        throw Exception(
            'Tải lên thất bại: ${uploadResult.error ?? "Lỗi không xác định"}');
      }

      return uploadResult.downloadUrl!;
    } catch (e) {
      throw Exception('Không thể tải lên file: $e');
    }
  }

  // Lấy số tin nhắn chưa đọc của một chat
  Stream<int> getUnreadMessagesCount(String chatId) {
    return _getMessagesRef(chatId)
        .where('seenBy', whereNotIn: [
          [_currentUserId]
        ])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final seenBy = List<String>.from(data['seenBy'] ?? []);
            return !seenBy.contains(_currentUserId);
          }).length;
        });
  }

  // Lấy tổng số tin nhắn chưa đọc từ tất cả các cuộc trò chuyện
  Stream<int> getTotalUnreadMessagesCount() {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: _currentUserId)
        .snapshots()
        .asyncMap((chatSnapshot) async {
      int totalCount = 0;

      for (final chatDoc in chatSnapshot.docs) {
        final chatId = chatDoc.id;

        // Lấy các tin nhắn chưa đọc từ mỗi chat
        final messagesSnapshot =
            await _getMessagesRef(chatId).where('seenBy', whereNotIn: [
          [_currentUserId]
        ]).get();

        // Đếm số tin nhắn thực sự chưa đọc
        final unreadCount = messagesSnapshot.docs.where((doc) {
          final data = doc.data();
          final seenBy = List<String>.from(data['seenBy'] ?? []);
          final senderId = data['senderId'] as String?;

          // Nếu người gửi là chính mình, không tính là chưa đọc
          if (senderId == _currentUserId) return false;

          return !seenBy.contains(_currentUserId);
        }).length;

        totalCount += unreadCount;
      }

      return totalCount;
    });
  }

  // Xóa tin nhắn
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      // Kiểm tra xem tin nhắn có tồn tại không
      final messageDoc = await _getMessagesRef(chatId).doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Tin nhắn không tồn tại');
      }

      // Kiểm tra quyền xóa tin nhắn
      final message = Message.fromMap(messageDoc.data()!);
      final chatDoc = await _getChatRef(chatId).get();

      if (!chatDoc.exists) {
        throw Exception('Cuộc trò chuyện không tồn tại');
      }

      final chatroom = Chatroom.fromMap(chatDoc.data()!);

      // Chỉ cho phép người gửi tin nhắn hoặc admin của nhóm xóa tin nhắn
      if (message.senderId != _currentUserId &&
          !chatroom.isAdmin(_currentUserId)) {
        throw Exception('Bạn không có quyền xóa tin nhắn này');
      }

      // Xóa tin nhắn
      await _getMessagesRef(chatId).doc(messageId).delete();

      // Nếu tin nhắn bị xóa là tin nhắn cuối cùng, cập nhật thông tin chat
      if (chatroom.lastMessageId == messageId) {
        // Lấy tin nhắn mới nhất
        final latestMessages = await _getMessagesRef(chatId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (latestMessages.docs.isNotEmpty) {
          // Nếu còn tin nhắn khác, cập nhật thông tin tin nhắn cuối cùng
          final latestMessage =
              Message.fromMap(latestMessages.docs.first.data());
          await _getChatRef(chatId).update({
            'lastMessageId': latestMessage.id,
            'lastMessage': latestMessage.getDisplayContent(),
            'lastMessageType': latestMessage.type.name,
            'lastMessageSenderId': latestMessage.senderId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Nếu không còn tin nhắn nào, xóa thông tin tin nhắn cuối cùng
          await _getChatRef(chatId).update({
            'lastMessageId': null,
            'lastMessage': null,
            'lastMessageType': null,
            'lastMessageSenderId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      throw Exception('Không thể xóa tin nhắn: $e');
    }
  }

  // Xóa toàn bộ đoạn chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Kiểm tra xem chat có tồn tại không
      final chatDoc = await _getChatRef(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Cuộc trò chuyện không tồn tại');
      }

      final chatroom = Chatroom.fromMap(chatDoc.data()!);

      // Kiểm tra quyền xóa chat
      if (!chatroom.isAdmin(_currentUserId)) {
        throw Exception('Bạn không có quyền xóa cuộc trò chuyện này');
      }

      // Lấy tất cả tin nhắn trong chat
      final messagesSnapshot = await _getMessagesRef(chatId).get();

      // Xóa từng tin nhắn
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Xóa document chat
      batch.delete(_getChatRef(chatId));

      // Thực hiện batch operation
      await batch.commit();
    } catch (e) {
      throw Exception('Không thể xóa cuộc trò chuyện: $e');
    }
  }

  // Tạo chatId từ hai userId
  String getChatRoomId(String userIdA, String userIdB) {
    // Sắp xếp userIds để đảm bảo chatId luôn nhất quán
    final userIds = [userIdA, userIdB]..sort();
    return '${userIds[0]}_${userIds[1]}';
  }

  // Kiểm tra xem chat đã tồn tại chưa
  Future<bool> chatExists(String chatId) async {
    try {
      final doc = await _getChatRef(chatId).get();
      return doc.exists;
    } catch (e) {
      logError(LogService.CHAT, 'Error checking if chat exists: $e');
      return false;
    }
  }

  // Kiểm tra trạng thái của chức năng chat
  Future<Map<String, dynamic>> checkChatStatus(String chatId) async {
    logInfo(LogService.CHAT, '===== START CHECK CHAT STATUS =====');
    logInfo(LogService.CHAT, 'Checking chat status for chatId: $chatId');

    final result = <String, dynamic>{
      'success': false,
      'chatExists': false,
      'messagesCount': 0,
      'members': <String>[],
      'lastMessage': null,
      'error': null,
    };

    try {
      // Kiểm tra xem chat có tồn tại không
      final chatDoc = await _getChatRef(chatId).get();
      result['chatExists'] = chatDoc.exists;
      logInfo(LogService.CHAT, 'Chat exists: ${chatDoc.exists}');

      if (chatDoc.exists) {
        // Lấy thông tin chat
        final chatroom = Chatroom.fromMap(chatDoc.data()!);
        result['members'] = chatroom.members;
        result['lastMessage'] = {
          'id': chatroom.lastMessageId,
          'content': chatroom.lastMessage,
          'type': chatroom.lastMessageType?.name,
          'senderId': chatroom.lastMessageSenderId,
        };

        logInfo(LogService.CHAT, 'Chat members: ${chatroom.members}');
        logInfo(LogService.CHAT, 'Last message: ${chatroom.lastMessage}');

        // Kiểm tra xem người dùng hiện tại có phải là thành viên không
        final isMember = chatroom.isMember(_currentUserId);
        result['isMember'] = isMember;
        logInfo(LogService.CHAT, 'Current user is member: $isMember');

        // Lấy số lượng tin nhắn
        final messagesSnapshot = await _getMessagesRef(chatId).get();
        result['messagesCount'] = messagesSnapshot.docs.length;
        logInfo(
            LogService.CHAT, 'Messages count: ${messagesSnapshot.docs.length}');

        // Kiểm tra quyền gửi tin nhắn
        result['canSendMessages'] = isMember;

        result['success'] = true;
      }
    } catch (e) {
      logError(LogService.CHAT, 'Error checking chat status: $e');
      result['error'] = e.toString();
    }

    logInfo(LogService.CHAT, 'Check chat status result: $result');
    logInfo(LogService.CHAT, '===== END CHECK CHAT STATUS =====');

    return result;
  }
}
