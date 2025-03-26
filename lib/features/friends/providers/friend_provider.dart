import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/log_utils.dart';
import '../repositories/friend_repository.dart';
import '../models/friend_model.dart';

final friendProvider = Provider((ref) {
  logDebug(LogService.FRIEND, '[FRIEND_PROVIDER] Khởi tạo FriendRepository');
  return FriendRepository();
});

final friendshipStatusProvider =
    StreamProvider.autoDispose.family<Map<String, bool>, String>((ref, userId) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) {
    logWarning(LogService.FRIEND,
        '[FRIEND_PROVIDER] Không thể lấy thông tin bạn bè: người dùng chưa đăng nhập');
    return Stream.value({
      'isFriend': false,
      'isSender': false,
      'isReceiver': false,
      'hasPendingRequest': false,
    });
  }

  // Tạo friendshipId theo cùng logic với FriendRepository
  final List<String> ids = [currentUserId, userId];
  ids.sort();
  final friendshipId = 'friend_${ids.join('_')}';

  logDebug(LogService.FRIEND,
      '[FRIEND_PROVIDER] Lắng nghe trạng thái friendship với userId: $userId, friendshipId: $friendshipId');

  // Lắng nghe thay đổi của document friendship
  return FirebaseFirestore.instance
      .collection('friendships')
      .doc(friendshipId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      logDebug(LogService.FRIEND,
          '[FRIEND_PROVIDER] Không tìm thấy mối quan hệ bạn bè với userId: $userId');
      return {
        'isFriend': false,
        'isSender': false,
        'isReceiver': false,
        'hasPendingRequest': false,
      };
    }

    final friendship = FriendshipModel.fromDocument(doc);
    logDebug(LogService.FRIEND,
        '[FRIEND_PROVIDER] Cập nhật trạng thái bạn bè, isAccepted: ${friendship.isAccepted}');

    // Xác định đúng vai trò người gửi và người nhận, phù hợp với FriendRepository
    final status = {
      'isFriend': friendship.isAccepted,
      'isSender': friendship.senderId == currentUserId,
      'isReceiver': friendship.receiverId == currentUserId,
      'hasPendingRequest': !friendship.isAccepted,
    };

    return status;
  });
});
