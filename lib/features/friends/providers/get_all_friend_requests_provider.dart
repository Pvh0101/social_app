import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log_utils.dart';
import '../models/friend_model.dart';

final getAllFriendRequestsProvider = StreamProvider.autoDispose((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) {
    logWarning(LogService.FRIEND,
        '[FRIEND_REQUESTS] Không thể lấy danh sách lời mời kết bạn: người dùng chưa đăng nhập');
    return Stream.value([]);
  }

  logDebug(LogService.FRIEND,
      '[FRIEND_REQUESTS] Khởi tạo stream lấy danh sách lời mời kết bạn cho userId: $currentUserId');

  return FirebaseFirestore.instance
      .collection('friendships')
      .where('receiverId', isEqualTo: currentUserId)
      .where('isAccepted', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
    final requestsList = snapshot.docs
        .map((doc) => FriendshipModel.fromDocument(doc))
        .map((friendship) => friendship.senderId)
        .toList();

    logInfo(LogService.FRIEND,
        '[FRIEND_REQUESTS] Tìm thấy ${requestsList.length} lời mời kết bạn cho người dùng $currentUserId');
    return requestsList;
  });
});
