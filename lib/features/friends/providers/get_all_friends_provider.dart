import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log_utils.dart';
import '../models/friend_model.dart';

final getAllFriendsProvider = StreamProvider.autoDispose((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) {
    logWarning(LogService.FRIEND,
        '[FRIEND_LIST] Không thể lấy danh sách bạn bè: người dùng chưa đăng nhập');
    return Stream.value([]);
  }

  logDebug(LogService.FRIEND,
      '[FRIEND_LIST] Khởi tạo stream lấy danh sách bạn bè cho userId: $currentUserId');

  return FirebaseFirestore.instance
      .collection('friendships')
      .where('isAccepted', isEqualTo: true)
      .where('senderId', isEqualTo: currentUserId)
      .snapshots()
      .asyncMap((sentFriendshipsSnapshot) async {
    // Lấy danh sách các mối quan hệ bạn bè đã được chấp nhận từ phía gửi
    final sentFriendships = sentFriendshipsSnapshot.docs
        .map((doc) => FriendshipModel.fromDocument(doc))
        .toList();

    logDebug(LogService.FRIEND,
        '[FRIEND_LIST] Tìm thấy ${sentFriendships.length} bạn bè mà người dùng $currentUserId đã gửi lời mời');

    // Lấy danh sách các mối quan hệ bạn bè đã được chấp nhận từ phía nhận
    final receivedFriendshipsSnapshot = await FirebaseFirestore.instance
        .collection('friendships')
        .where('isAccepted', isEqualTo: true)
        .where('receiverId', isEqualTo: currentUserId)
        .get();

    final receivedFriendships = receivedFriendshipsSnapshot.docs
        .map((doc) => FriendshipModel.fromDocument(doc))
        .toList();

    logDebug(LogService.FRIEND,
        '[FRIEND_LIST] Tìm thấy ${receivedFriendships.length} bạn bè đã gửi lời mời cho người dùng $currentUserId');

    // Kết hợp danh sách uid của bạn bè từ cả hai phía
    final allFriends = [
      ...sentFriendships.map((f) => f.receiverId),
      ...receivedFriendships.map((f) => f.senderId),
    ];

    logInfo(LogService.FRIEND,
        '[FRIEND_LIST] Tổng số bạn bè của người dùng $currentUserId: ${allFriends.length}');

    return allFriends;
  });
});
