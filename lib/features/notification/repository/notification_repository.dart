import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../../../core/enums/notification_type.dart';
import '../../../features/authentication/models/user_model.dart';

/// Repository quản lý thông báo trong Firestore
class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Lấy ID của người dùng hiện tại
  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Lấy reference đến collection thông báo
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  /// Lấy reference đến collection hàng đợi thông báo
  CollectionReference<Map<String, dynamic>> get _notificationsQueueRef =>
      _firestore.collection('notifications_queue');

  /// Lấy danh sách thông báo của người dùng hiện tại
  Stream<List<NotificationModel>> getNotifications() {
    if (_currentUserId.isEmpty) {
      debugPrint('No user logged in');
      return Stream.value([]);
    }

    try {
      return _notificationsRef
          .where('receiverId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        debugPrint('Error getting notifications: $error');
        if (error is FirebaseException && error.code == 'failed-precondition') {
          debugPrint(
              'Need to create index for notifications. Check Firebase console.');
        }
        return [];
      }).map((snapshot) {
        debugPrint('Got ${snapshot.docs.length} notifications');
        return snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      debugPrint('Error in getNotifications: $e');
      return Stream.value([]);
    }
  }

  /// Lấy số lượng thông báo chưa đọc
  Stream<int> getUnreadNotificationsCount() {
    if (_currentUserId.isEmpty) {
      debugPrint('No user logged in');
      return Stream.value(0);
    }

    try {
      return _notificationsRef
          .where('receiverId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .handleError((error) {
        debugPrint('Error getting unread count: $error');
        if (error is FirebaseException && error.code == 'failed-precondition') {
          debugPrint(
              'Need to create index for unread notifications. Check Firebase console.');
        }
        return 0;
      }).map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('Error in getUnreadNotificationsCount: $e');
      return Stream.value(0);
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({
        'isRead': true,
      });
      debugPrint('Marked notification $notificationId as read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead() async {
    try {
      // Lấy tất cả thông báo chưa đọc
      final snapshot = await _notificationsRef
          .where('receiverId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Tạo batch để cập nhật nhiều document cùng lúc
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Commit batch
      await batch.commit();
      debugPrint('Marked all notifications as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Tạo thông báo mới
  Future<String> createNotification({
    required String receiverId,
    required UserModel sender,
    required NotificationType type,
    String? postId,
    String? commentId,
    String? chatId,
    String? messageContent,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final now = DateTime.now();

      final data = {
        'id': notificationId,
        'senderId': sender.uid,
        'receiverId': receiverId,
        'type': type.value,
        'content': type.getTemplateMessage(sender.fullName),
        'createdAt': now,
        'isRead': false,
        'senderName': sender.fullName,
        'senderAvatar': sender.profileImage,
        if (postId != null) 'postId': postId,
        if (commentId != null) 'commentId': commentId,
        if (chatId != null) 'chatId': chatId,
      };

      await _notificationsRef.doc(notificationId).set(data);
      debugPrint('Created notification $notificationId');

      return notificationId;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
      debugPrint('Deleted notification $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Xóa tất cả thông báo của người dùng
  Future<void> deleteAllNotifications() async {
    try {
      // Lấy tất cả thông báo của người dùng
      final snapshot = await _notificationsRef
          .where('receiverId', isEqualTo: _currentUserId)
          .get();

      // Tạo batch để xóa nhiều document cùng lúc
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit batch
      await batch.commit();
      debugPrint('Deleted all notifications');
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }

  /// Tạo thông báo khi có tin nhắn mới
  Future<String> createMessageNotification({
    required String receiverId,
    required UserModel sender,
    required String chatId,
    required String messageContent,
  }) async {
    return createNotificationWithPush(
      receiverId: receiverId,
      sender: sender,
      type: NotificationType.message,
      chatId: chatId,
      messageContent: messageContent,
    );
  }

  /// Tạo thông báo khi có lượt thích mới
  Future<String> createLikeNotification({
    required String receiverId,
    required UserModel sender,
    required String postId,
  }) async {
    return createNotificationWithPush(
      receiverId: receiverId,
      sender: sender,
      type: NotificationType.like,
      postId: postId,
    );
  }

  /// Tạo thông báo khi có bình luận mới
  Future<String> createCommentNotification({
    required String receiverId,
    required UserModel sender,
    required String postId,
    required String commentId,
  }) async {
    return createNotificationWithPush(
      receiverId: receiverId,
      sender: sender,
      type: NotificationType.comment,
      postId: postId,
      commentId: commentId,
    );
  }

  /// Tạo thông báo khi có lời mời kết bạn
  Future<String> createFriendRequestNotification({
    required String receiverId,
    required UserModel sender,
  }) async {
    return createNotificationWithPush(
      receiverId: receiverId,
      sender: sender,
      type: NotificationType.friendRequest,
    );
  }

  /// Tạo thông báo khi chấp nhận lời mời kết bạn
  Future<String> createFriendAcceptNotification({
    required String receiverId,
    required UserModel sender,
  }) async {
    return createNotificationWithPush(
      receiverId: receiverId,
      sender: sender,
      type: NotificationType.friendAccept,
    );
  }

  /// Gửi thông báo đẩy trực tiếp bằng FCM token
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final now = DateTime.now();

      // Tạo document trong collection notifications_queue để kích hoạt Cloud Function
      await _notificationsQueueRef.doc(notificationId).set({
        'id': notificationId,
        'token': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'createdAt': now,
        'sent': false,
      });

      debugPrint('Added notification to queue: $notificationId');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      rethrow;
    }
  }

  /// Tạo thông báo và gửi thông báo đẩy
  Future<String> createNotificationWithPush({
    required String receiverId,
    required UserModel sender,
    required NotificationType type,
    String? postId,
    String? commentId,
    String? chatId,
    String? messageContent,
  }) async {
    try {
      // Tạo thông báo trong Firestore
      final notificationId = await createNotification(
        receiverId: receiverId,
        sender: sender,
        type: type,
        postId: postId,
        commentId: commentId,
        chatId: chatId,
        messageContent: messageContent,
      );

      // Lấy FCM token của người nhận
      final userDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Gửi thông báo đẩy
        await sendPushNotification(
          token: fcmToken,
          title: 'Thông báo mới',
          body: type.getTemplateMessage(sender.fullName),
          data: {
            'notificationId': notificationId,
            'type': type.value,
            'senderId': sender.uid,
            if (postId != null) 'postId': postId,
            if (commentId != null) 'commentId': commentId,
            if (chatId != null) 'chatId': chatId,
          },
        );
      } else {
        debugPrint('No FCM token found for user $receiverId');
      }

      return notificationId;
    } catch (e) {
      debugPrint('Error creating notification with push: $e');
      rethrow;
    }
  }

  /// Gửi thông báo đẩy cho tin nhắn mà không lưu vào collection notifications
  Future<void> sendMessagePushNotificationOnly({
    required String receiverId,
    required UserModel sender,
    required String chatId,
    required String messageContent,
  }) async {
    try {
      // Lấy FCM token của người nhận
      final userDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        // Tạo nội dung thông báo
        final title = '${sender.fullName}';
        final body =
            messageContent.isNotEmpty ? messageContent : 'Đã gửi một media';

        // Gửi thông báo đẩy
        await sendPushNotification(
          token: fcmToken,
          title: title,
          body: body,
          data: {
            'type': NotificationType.message.value,
            'senderId': sender.uid,
            'chatId': chatId,
          },
        );
        debugPrint(
            'Đã gửi push notification tin nhắn không lưu vào collection');
      } else {
        debugPrint('Không tìm thấy FCM token cho người dùng $receiverId');
      }
    } catch (e) {
      debugPrint('Lỗi khi gửi push notification tin nhắn: $e');
      // Không ném lỗi để không ảnh hưởng đến luồng gửi tin nhắn
    }
  }
}
