import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/global_method.dart';
import '../../../core/services/media/media_service.dart';
import '../../../core/services/media/media_upload_service.dart';
import '../../../core/services/media/media_types.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../models/chatroom.dart';
import '../repositories/chat_repository.dart';
import '../providers/chat_repository_provider.dart';

/// Cung cấp service ChatroomService
final chatroomServiceProvider = Provider.autoDispose((ref) {
  return ChatroomService(ref);
});

/// Service quản lý các tác vụ liên quan đến nhóm chat
///
/// Tập trung xử lý các tác vụ như:
/// - Tạo nhóm chat mới
/// - Cập nhật thông tin nhóm chat
/// - Thêm/xóa thành viên
/// - Upload media cho nhóm chat
class ChatroomService {
  final ProviderRef ref;
  late final ChatRepository _chatRepository;
  late final MediaService _mediaService;

  ChatroomService(this.ref) {
    _chatRepository = ref.read(chatRepositoryProvider);
    _mediaService = ref.read(mediaServiceProvider);
  }

  /// Tạo nhóm chat mới
  Future<String?> createGroupChat({
    required String name,
    required List<String> members,
    required bool isPublic,
    File? groupImage,
  }) async {
    if (name.trim().isEmpty) {
      showToastMessage(text: 'Tên nhóm không được để trống');
      return null;
    }

    if (members.isEmpty) {
      showToastMessage(text: 'Vui lòng chọn ít nhất một thành viên');
      return null;
    }

    try {
      String? avatarUrl;

      // Xử lý và upload ảnh nhóm nếu có
      if (groupImage != null) {
        // Nén ảnh trước khi upload để giảm dung lượng
        final compressedImage = await _mediaService.compressImage(
          groupImage,
          onError: (error) => showToastMessage(text: 'Lỗi khi nén ảnh: $error'),
        );

        final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}';
        final path = 'group_images/$fileName';

        // Upload ảnh đã nén
        final uploadResult = await _mediaService.uploadSingleFile(
          file: compressedImage ?? groupImage,
          path: path,
          onProgress: (progress) {
            // Có thể thêm code hiển thị tiến trình upload ở đây nếu cần
          },
        );

        if (uploadResult.isSuccess) {
          avatarUrl = uploadResult.downloadUrl;
        } else {
          showToastMessage(text: 'Lỗi khi upload ảnh: ${uploadResult.error}');
        }
      }

      // Tạo nhóm
      final chatId = await _chatRepository.createGroupChat(
        name: name.trim(),
        avatar: avatarUrl,
        members: members,
        isPublic: isPublic,
      );

      return chatId;
    } catch (e) {
      showToastMessage(text: 'Lỗi khi tạo nhóm: ${e.toString()}');
      return null;
    }
  }

  /// Cập nhật thông tin nhóm chat
  Future<bool> updateChatInfo({
    required String chatId,
    required String name,
    File? imageFile,
    String? currentAvatar,
    required String currentUserId,
  }) async {
    try {
      // Lấy thông tin chat hiện tại
      final chat = await _chatRepository.getChatById(chatId);

      if (chat == null) {
        showToastMessage(text: 'Không tìm thấy thông tin nhóm chat');
        return false;
      }

      // Kiểm tra quyền
      if (!chat.isAdmin(currentUserId)) {
        showToastMessage(text: 'Bạn không có quyền cập nhật thông tin nhóm');
        return false;
      }

      if (name.trim().isEmpty) {
        showToastMessage(text: 'Tên nhóm không được để trống');
        return false;
      }

      String? avatarUrl = currentAvatar;

      // Xử lý và upload ảnh mới nếu có
      if (imageFile != null) {
        // Nén ảnh trước khi upload
        final compressedImage = await _mediaService.compressImage(
          imageFile,
          onError: (error) => showToastMessage(text: 'Lỗi khi nén ảnh: $error'),
        );

        final fileName =
            'chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}';
        final path = 'chat_images/$fileName';

        // Upload ảnh đã nén
        final uploadResult = await _mediaService.uploadSingleFile(
          file: compressedImage ?? imageFile,
          path: path,
          onProgress: (progress) {
            // Có thể thêm code hiển thị tiến trình upload ở đây nếu cần
          },
        );

        if (uploadResult.isSuccess) {
          avatarUrl = uploadResult.downloadUrl;

          // Xóa ảnh cũ nếu có
          if (currentAvatar != null && currentAvatar.isNotEmpty) {
            final storagePath = _extractStoragePath(currentAvatar);
            if (storagePath != null) {
              await _mediaService.deleteFile(storagePath);
            }
          }
        } else {
          showToastMessage(text: 'Lỗi khi upload ảnh: ${uploadResult.error}');
        }
      }

      // Cập nhật thông tin nhóm
      await _chatRepository.updateChatInfo(
        chatId,
        name: name.trim(),
        avatar: avatarUrl,
      );

      showToastMessage(text: 'Cập nhật thông tin nhóm thành công');
      return true;
    } catch (e) {
      showToastMessage(text: 'Lỗi khi cập nhật thông tin nhóm: $e');
      return false;
    }
  }

  /// Thêm thành viên vào nhóm chat
  Future<bool> addMemberToChat(String chatId, String userId) async {
    if (userId.isEmpty) return false;

    try {
      await _chatRepository.addMemberToChat(chatId, userId);
      showToastMessage(text: 'Thêm thành viên thành công');
      return true;
    } catch (e) {
      showToastMessage(text: 'Lỗi khi thêm thành viên: $e');
      return false;
    }
  }

  /// Xóa thành viên khỏi nhóm chat
  Future<bool> removeMemberFromChat(BuildContext context, String chatId,
      String userId, String currentUserId) async {
    // Lấy thông tin nhóm
    final chat = await _chatRepository.getChatById(chatId);
    if (chat == null) {
      showToastMessage(text: 'Không tìm thấy thông tin nhóm chat');
      return false;
    }

    // Kiểm tra quyền
    if (!chat.isAdmin(currentUserId)) {
      showToastMessage(text: 'Bạn không có quyền xóa thành viên');
      return false;
    }

    // Hiển thị dialog xác nhận
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Xác nhận xóa thành viên',
      message: 'Bạn có chắc chắn muốn xóa thành viên này khỏi nhóm?',
      confirmText: 'Xóa',
    );

    if (confirmed != true) return false;

    try {
      await _chatRepository.removeMemberFromChat(chatId, userId);
      showToastMessage(text: 'Xóa thành viên thành công');
      return true;
    } catch (e) {
      showToastMessage(text: 'Lỗi khi xóa thành viên: $e');
      return false;
    }
  }

  /// Rời khỏi nhóm chat
  Future<bool> leaveChat(
      BuildContext context, String chatId, String userId) async {
    // Hiển thị dialog xác nhận
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Xác nhận rời nhóm',
      message: 'Bạn có chắc chắn muốn rời khỏi nhóm chat này?',
      confirmText: 'Rời nhóm',
    );

    if (confirmed != true) return false;

    try {
      await _chatRepository.removeMemberFromChat(chatId, userId);
      showToastMessage(text: 'Đã rời khỏi nhóm chat');
      return true;
    } catch (e) {
      showToastMessage(text: 'Lỗi khi rời nhóm: $e');
      return false;
    }
  }

  /// Trích xuất đường dẫn lưu trữ từ URL download
  String? _extractStoragePath(String url) {
    // Ví dụ URL: https://firebasestorage.googleapis.com/v0/b/app-name.appspot.com/o/group_images%2Fimage123.jpg?alt=media&token=abc123
    // => group_images/image123.jpg
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('firebasestorage.googleapis.com')) {
        final pathSegment =
            uri.pathSegments.lastWhere((segment) => segment == 'o');
        if (pathSegment.isNotEmpty) {
          final encodedPath =
              uri.pathSegments[uri.pathSegments.indexOf(pathSegment) + 1];
          return Uri.decodeComponent(encodedPath);
        }
      }
    } catch (e) {
      print('Lỗi khi trích xuất đường dẫn: $e');
    }
    return null;
  }
}
