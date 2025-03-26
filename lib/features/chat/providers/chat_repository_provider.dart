import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/log_utils.dart';
import '../repositories/chat_repository.dart';

/// Provider cung cấp instance của ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  // Lấy thông tin người dùng hiện tại
  final currentUser = FirebaseAuth.instance.currentUser;

  // Kiểm tra xem người dùng đã đăng nhập chưa
  if (currentUser == null) {
    logError(LogService.CHAT, '[CHAT_REPOSITORY_PROVIDER] No user logged in',
        null, StackTrace.current);
    throw Exception('Người dùng chưa đăng nhập');
  }

  logDebug(LogService.CHAT,
      '[CHAT_REPOSITORY_PROVIDER] Initializing ChatRepository with userId: ${currentUser.uid}');

  // Khởi tạo repository với Firestore và userId
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    currentUserId: currentUser.uid,
  );
});
