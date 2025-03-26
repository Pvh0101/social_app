import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:logger/logger.dart';

import '../../../core/core.dart';
import '../../../core/utils/log_utils.dart';
import '../models/friend_model.dart';
import '../../../features/notification/repository/notification_repository.dart';
import '../../../features/authentication/models/user_model.dart';

/// Repository quản lý các thao tác kết bạn trên Firestore.
@immutable
class FriendRepository {
  final _myUid = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;
  final _notificationRepository = NotificationRepository();
  final logger = Logger();

  /// Tạo friendshipId từ hai userId
  String _createFriendshipId(String userId1, String userId2) {
    final List<String> ids = [userId1, userId2];
    ids.sort(); // Sắp xếp theo thứ tự từ điển
    final id = 'friend_${ids.join('_')}';
    logDebug(LogService.FRIEND,
        '[FRIEND_CHECK] Tạo friendshipId: userId1=$userId1, userId2=$userId2, friendshipId=$id');
    return id;
  }

  /// Kiểm tra các trạng thái khác nhau của quan hệ bạn bè
  Future<Map<String, bool>> checkFriendshipStatus(String userId) async {
    try {
      logDebug(LogService.FRIEND,
          '[FRIEND_CHECK] Kiểm tra trạng thái bạn bè với userId: $userId');
      final friendshipId = _createFriendshipId(_myUid, userId);
      final friendshipDoc =
          await _firestore.collection('friendships').doc(friendshipId).get();

      if (!friendshipDoc.exists) {
        logDebug(LogService.FRIEND,
            '[FRIEND_CHECK] Không tìm thấy mối quan hệ bạn bè với userId: $userId');
        return {
          'isFriend': false,
          'isSender': false,
          'isReceiver': false,
          'hasPendingRequest': false,
        };
      }

      final friendship = FriendshipModel.fromDocument(friendshipDoc);
      final status = {
        'isFriend': friendship.isAccepted,
        'isSender': friendship.senderId == _myUid,
        'isReceiver': friendship.receiverId == _myUid,
        'hasPendingRequest': !friendship.isAccepted,
      };

      logDebug(LogService.FRIEND,
          '[FRIEND_CHECK] Kết quả kiểm tra: isFriend=${status['isFriend']}, isSender=${status['isSender']}, isReceiver=${status['isReceiver']}, hasPendingRequest=${status['hasPendingRequest']}');
      return status;
    } catch (e) {
      logError(
          LogService.FRIEND,
          '[FRIEND_CHECK] Lỗi khi kiểm tra trạng thái bạn bè',
          e,
          StackTrace.current);
      showToastMessage(text: "Có lỗi xảy ra: ${e.toString()}");
      return {
        'isFriend': false,
        'isSender': false,
        'isReceiver': false,
        'hasPendingRequest': false,
      };
    }
  }

  /// Kiểm tra xem [userId] có phải là bạn bè của người dùng hiện tại không.
  Future<bool> isFriend(String userId) async {
    logDebug(LogService.FRIEND,
        '[FRIEND_CHECK] Kiểm tra xem $userId có phải là bạn bè không');
    final status = await checkFriendshipStatus(userId);
    return status['isFriend']!;
  }

  /// Kiểm tra xem [userId] có phải là người gửi lời mời kết bạn không.
  Future<bool> isSender(String userId) async {
    logDebug(LogService.FRIEND,
        '[FRIEND_CHECK] Kiểm tra xem $userId có phải là người gửi lời mời kết bạn không');
    final status = await checkFriendshipStatus(userId);
    return status['isSender']!;
  }

  /// Kiểm tra xem [userId] có phải là người nhận lời mời kết bạn không.
  Future<bool> isReceiver(String userId) async {
    logDebug(LogService.FRIEND,
        '[FRIEND_CHECK] Kiểm tra xem $userId có phải là người nhận lời mời kết bạn không');
    final status = await checkFriendshipStatus(userId);
    return status['isReceiver']!;
  }

  /// Kiểm tra xem có lời mời kết bạn đang chờ không.
  Future<bool> hasPendingRequest(String userId) async {
    logDebug(LogService.FRIEND,
        '[FRIEND_CHECK] Kiểm tra xem có lời mời kết bạn đang chờ với $userId không');
    final status = await checkFriendshipStatus(userId);
    return status['hasPendingRequest']!;
  }

  /// Kiểm tra xem có mối quan hệ nào giữa hai người dùng không.
  Future<bool> hasRelationship(String userId) async {
    logDebug(LogService.FRIEND,
        '[FRIEND_CHECK] Kiểm tra xem có mối quan hệ nào với $userId không');
    final status = await checkFriendshipStatus(userId);
    return status['isFriend']! || status['hasPendingRequest']!;
  }

  /// Gửi lời mời kết bạn đến [userId].
  Future<String?> sendFriendRequest({required String userId}) async {
    try {
      logInfo(LogService.FRIEND,
          '[FRIEND_REQUEST] Bắt đầu gửi lời mời kết bạn đến userId: $userId');

      // Kiểm tra nếu người dùng đang gửi lời mời cho chính mình
      if (_myUid == userId) {
        logWarning(LogService.FRIEND,
            '[FRIEND_REQUEST] Người dùng đang gửi lời mời kết bạn cho chính mình');
        showToastMessage(
            text: "Bạn không thể gửi lời mời kết bạn cho chính mình!");
        return "Bạn không thể gửi lời mời kết bạn cho chính mình!";
      }

      final friendshipId = _createFriendshipId(_myUid, userId);
      logDebug(LogService.FRIEND,
          '[FRIEND_REQUEST] Chuẩn bị gửi lời mời kết bạn: friendshipId=$friendshipId, myUid=$_myUid, userId=$userId');

      // Kiểm tra xem đã có lời mời kết bạn trước đó chưa
      final existingRequest =
          await _firestore.collection('friendships').doc(friendshipId).get();

      if (existingRequest.exists) {
        final existingFriendship =
            FriendshipModel.fromDocument(existingRequest);

        logDebug(LogService.FRIEND,
            '[FRIEND_REQUEST] Thông tin friendship hiện tại: ${existingFriendship.toMap()}');

        // Nếu đã là bạn bè
        if (existingFriendship.isAccepted) {
          logWarning(LogService.FRIEND,
              '[FRIEND_REQUEST] Đã là bạn bè: friendshipId=$friendshipId');
          showToastMessage(text: "Hai người đã là bạn bè!");
          return "Hai người đã là bạn bè!";
        }

        // Nếu người dùng hiện tại đã gửi lời mời trước đó
        if (existingFriendship.senderId == _myUid) {
          logWarning(LogService.FRIEND,
              '[FRIEND_REQUEST] Đã gửi lời mời kết bạn trước đó: friendshipId=$friendshipId');
          showToastMessage(text: "Bạn đã gửi lời mời trước đó!");
          return "Bạn đã gửi lời mời trước đó!";
        }

        // Nếu người dùng hiện tại đã nhận được lời mời từ người kia
        if (existingFriendship.receiverId == _myUid) {
          logWarning(LogService.FRIEND,
              '[FRIEND_REQUEST] Đã nhận được lời mời kết bạn từ người này: friendshipId=$friendshipId');
          showToastMessage(
              text:
                  "Người này đã gửi lời mời kết bạn cho bạn. Hãy chấp nhận lời mời!");
          return "Người này đã gửi lời mời kết bạn cho bạn. Hãy chấp nhận lời mời!";
        }

        // Trường hợp không xác định, xóa document cũ và tạo mới
        logWarning(LogService.FRIEND,
            '[FRIEND_REQUEST] Trạng thái friendship không xác định, xóa và tạo mới: friendshipId=$friendshipId');
        await _firestore.collection('friendships').doc(friendshipId).delete();
      }

      // Tạo một document mới trong collection friendships
      final friendship = FriendshipModel(
        friendshipId: friendshipId,
        senderId: _myUid,
        receiverId: userId,
        isAccepted: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .set(friendship.toMap());
      logInfo(LogService.FRIEND,
          '[FRIEND_REQUEST] Đã gửi lời mời kết bạn thành công: friendshipId=$friendshipId');

      // Gửi thông báo
      final userDoc = await _firestore.collection('users').doc(_myUid).get();
      final userData = userDoc.data() ?? {};
      final currentUser = UserModel(
        uid: _myUid,
        email: userData['email'] ?? '',
        fullName: userData['fullName'] ?? 'Người dùng',
        profileImage: userData['profileImage'],
      );

      await _notificationRepository.createFriendRequestNotification(
        receiverId: userId,
        sender: currentUser,
      );

      showToastMessage(text: "Đã gửi lời mời kết bạn");
      return null;
    } catch (e) {
      logError(
          LogService.FRIEND,
          '[FRIEND_REQUEST] Lỗi khi gửi lời mời kết bạn',
          e,
          StackTrace.current);
      showToastMessage(text: e.toString());
      return e.toString();
    }
  }

  /// Chấp nhận lời mời kết bạn từ [userId].
  Future<String?> acceptFriendRequest({required String userId}) async {
    try {
      logInfo(LogService.FRIEND,
          '[FRIEND_ACCEPT] Bắt đầu chấp nhận lời mời kết bạn từ userId: $userId');
      final friendshipId = _createFriendshipId(_myUid, userId);

      // Thực hiện trong transaction
      await _firestore.runTransaction((transaction) async {
        final friendshipDoc = await transaction.get(
          _firestore.collection('friendships').doc(friendshipId),
        );

        if (!friendshipDoc.exists) {
          logWarning(LogService.FRIEND,
              '[FRIEND_ACCEPT] Lời mời kết bạn không tồn tại: friendshipId=$friendshipId');
          showToastMessage(text: "Lời mời kết bạn không tồn tại!");
          return;
        }

        final friendship = FriendshipModel.fromDocument(friendshipDoc);

        // Kiểm tra xem đã chấp nhận chưa
        if (friendship.isAccepted) {
          logWarning(LogService.FRIEND,
              '[FRIEND_ACCEPT] Lời mời đã được chấp nhận trước đó: friendshipId=$friendshipId');
          showToastMessage(text: "Hai người đã là bạn bè!");
          return;
        }

        // Kiểm tra xem người dùng hiện tại có phải là người nhận lời mời không
        if (friendship.receiverId != _myUid) {
          logWarning(LogService.FRIEND,
              '[FRIEND_ACCEPT] Người dùng không phải người nhận lời mời: myUid=$_myUid, receiverId=${friendship.receiverId}');
          showToastMessage(text: "Bạn không phải người nhận lời mời!");
          return;
        }

        transaction.update(friendshipDoc.reference, {
          'isAccepted': true,
        });

        logInfo(LogService.FRIEND,
            '[FRIEND_ACCEPT] Đã chấp nhận lời mời kết bạn thành công: friendshipId=$friendshipId');
      });

      // Gửi thông báo
      final userDoc = await _firestore.collection('users').doc(_myUid).get();
      final userData = userDoc.data() ?? {};
      final currentUser = UserModel(
        uid: _myUid,
        email: userData['email'] ?? '',
        fullName: userData['fullName'] ?? 'Người dùng',
        profileImage: userData['profileImage'],
      );

      await _notificationRepository.createFriendAcceptNotification(
        receiverId: userId,
        sender: currentUser,
      );

      showToastMessage(text: "Đã chấp nhận lời mời kết bạn");
      return null;
    } catch (e) {
      logError(
          LogService.FRIEND,
          '[FRIEND_ACCEPT] Lỗi khi chấp nhận lời mời kết bạn',
          e,
          StackTrace.current);
      showToastMessage(text: e.toString());
      return e.toString();
    }
  }

  /// Xóa lời mời kết bạn hoặc hủy kết bạn với [userId].
  Future<String?> removeFriendRequest({required String userId}) async {
    try {
      logInfo(LogService.FRIEND,
          '[FRIEND_REMOVE] Bắt đầu xóa lời mời kết bạn với userId: $userId');
      final friendshipId = _createFriendshipId(_myUid, userId);

      // Kiểm tra xem lời mời kết bạn có tồn tại không
      final friendshipDoc =
          await _firestore.collection('friendships').doc(friendshipId).get();

      if (!friendshipDoc.exists) {
        logWarning(LogService.FRIEND,
            '[FRIEND_REMOVE] Lời mời kết bạn không tồn tại: friendshipId=$friendshipId');
        showToastMessage(text: "Lời mời kết bạn không tồn tại!");
        return "Lời mời kết bạn không tồn tại!";
      }

      final friendship = FriendshipModel.fromDocument(friendshipDoc);
      logDebug(LogService.FRIEND,
          '[FRIEND_REMOVE] Thông tin lời mời kết bạn: ${friendship.toMap()}');

      // Kiểm tra xem người dùng hiện tại có phải là người gửi hoặc người nhận không
      if (friendship.senderId != _myUid && friendship.receiverId != _myUid) {
        logWarning(LogService.FRIEND,
            '[FRIEND_REMOVE] Người dùng không có quyền xóa lời mời: myUid=$_myUid, senderId=${friendship.senderId}, receiverId=${friendship.receiverId}');
        showToastMessage(text: "Bạn không có quyền xóa lời mời kết bạn này!");
        return "Bạn không có quyền xóa lời mời kết bạn này!";
      }

      await _firestore.collection('friendships').doc(friendshipId).delete();
      logInfo(LogService.FRIEND,
          '[FRIEND_REMOVE] Đã xóa lời mời kết bạn thành công: friendshipId=$friendshipId');

      // Hiển thị thông báo phù hợp
      if (friendship.senderId == _myUid) {
        showToastMessage(text: "Đã hủy lời mời kết bạn");
      } else {
        showToastMessage(text: "Đã từ chối lời mời kết bạn");
      }

      return null;
    } catch (e) {
      logError(LogService.FRIEND, '[FRIEND_REMOVE] Lỗi khi xóa lời mời kết bạn',
          e, StackTrace.current);
      showToastMessage(text: e.toString());
      return e.toString();
    }
  }

  /// Hủy kết bạn với [userId].
  Future<String?> removeFriend({required String userId}) async {
    try {
      logInfo(LogService.FRIEND,
          '[FRIEND_REMOVE] Bắt đầu hủy kết bạn với userId: $userId');
      final friendshipId = _createFriendshipId(_myUid, userId);

      // Thực hiện trong transaction
      await _firestore.runTransaction((transaction) async {
        final friendshipDoc = await transaction.get(
          _firestore.collection('friendships').doc(friendshipId),
        );

        if (!friendshipDoc.exists) {
          logWarning(LogService.FRIEND,
              '[FRIEND_REMOVE] Mối quan hệ bạn bè không tồn tại: friendshipId=$friendshipId');
          showToastMessage(text: "Mối quan hệ bạn bè không tồn tại!");
          return;
        }

        final friendship = FriendshipModel.fromDocument(friendshipDoc);
        if (!friendship.isAccepted) {
          logWarning(LogService.FRIEND,
              '[FRIEND_REMOVE] Hai người chưa phải là bạn bè: friendshipId=$friendshipId');
          showToastMessage(text: "Hai người chưa phải là bạn bè!");
          return;
        }

        transaction.delete(friendshipDoc.reference);
        logInfo(LogService.FRIEND,
            '[FRIEND_REMOVE] Đã hủy kết bạn thành công: friendshipId=$friendshipId');
      });

      showToastMessage(text: "Đã hủy kết bạn");
      return null;
    } catch (e) {
      logError(LogService.FRIEND, '[FRIEND_REMOVE] Lỗi khi hủy kết bạn', e,
          StackTrace.current);
      showToastMessage(text: e.toString());
      return e.toString();
    }
  }
}
