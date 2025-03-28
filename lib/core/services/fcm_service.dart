import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enums/notification_type.dart';
import '../../features/notification/providers/notification_provider.dart';
import '../../features/authentication/models/user_model.dart';
import 'notification_navigation_service.dart';
import '../services/permission/permission_service.dart';

final fcmServiceProvider = Provider((ref) => FCMService(ref));

/// FCMService quản lý việc nhận và xử lý thông báo từ Firebase Cloud Messaging
class FCMService {
  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Ref _ref;
  final PermissionService _permissionService = PermissionService();

  // Channel ID cho Android
  static const String _androidChannelId = 'social_app_channel';
  static const String _androidChannelName = 'Social App Notifications';
  static const String _androidChannelDescription =
      'Thông báo từ ứng dụng Social App';

  // Tạo GlobalKey để truy cập Navigator
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  FCMService(this._ref);

  /// Khởi tạo FCM Service
  Future<void> initialize() async {
    try {
      // Yêu cầu quyền thông báo
      await _requestPermission();

      // Cấu hình thông báo local
      await _setupLocalNotifications();

      // Xử lý thông báo khi ứng dụng đang chạy
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Xử lý thông báo khi nhấn vào thông báo
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Kiểm tra xem ứng dụng có được mở từ thông báo không
      await _checkInitialMessage();

      // Lấy và lưu token FCM
      await _setupFcmToken();

      // Xử lý token refresh
      _messaging.onTokenRefresh.listen(_updateFcmToken);

      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM Service: $e');
    }
  }

  /// Yêu cầu quyền thông báo sử dụng PermissionService
  Future<bool> _requestPermission() async {
    // Sử dụng PermissionService để yêu cầu quyền thông báo
    final status = await _permissionService
        .requestPermission(PermissionGroup.notification);

    // Nếu quyền đã được cấp, thực hiện yêu cầu cấu hình FCM cụ thể
    if (status == AppPermissionStatus.granted) {
      // Yêu cầu cấu hình FCM cụ thể (vẫn cần thiết vì FCM có các quyền chi tiết hơn)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    debugPrint('Notification permission denied');
    return false;
  }

  /// Cấu hình thông báo local
  Future<void> _setupLocalNotifications() async {
    // Cấu hình cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình cho iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Khởi tạo plugin
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng nhấn vào thông báo
        _handleNotificationTap(response.payload);
      },
    );

    // Tạo channel cho Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Setup và lưu FCM token
  Future<void> _setupFcmToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    if (token != null) {
      await _updateFcmToken(token);
    }
  }

  /// Cập nhật FCM token
  Future<void> _updateFcmToken(String token) async {
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'fcmToken': token});
      debugPrint('FCM token updated successfully');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Xử lý thông báo khi ứng dụng đang chạy
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');

    // Validate data
    if (!_validateMessageData(message.data)) {
      debugPrint('Invalid message data');
      return;
    }

    // Hiển thị thông báo local
    // await _showLocalNotification(message);

    // Lưu thông báo vào Firestore
    await _saveNotificationToFirestore(message);
  }

  /// Validate message data
  bool _validateMessageData(Map<String, dynamic> data) {
    if (!data.containsKey('type')) return false;

    final type = NotificationType.fromString(data['type']);

    switch (type) {
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.mention:
        if (!data.containsKey('postId')) return false;
        break;
      case NotificationType.message:
        if (!data.containsKey('chatId')) return false;
        break;
      case NotificationType.friendRequest:
      case NotificationType.friendAccept:
        if (!data.containsKey('senderId')) return false;
        break;
    }

    return true;
  }

  /// Hiển thị thông báo local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  /// Lưu thông báo vào Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      final data = message.data;
      final type = NotificationType.fromString(data['type']);
      final senderId = data['senderId'];
      final senderName = data['senderName'];
      final senderAvatar = data['senderAvatar'];

      if (senderId == null || senderName == null) return;

      // Tạo UserModel từ dữ liệu FCM
      final sender = UserModel(
        uid: senderId,
        fullName: senderName,
        profileImage: senderAvatar,
        email: '', // Không cần thiết cho thông báo
        isOnline: false, // Không cần thiết cho thông báo
        isPrivateAccount: false, // Không cần thiết cho thông báo
        followersCount: 0, // Không cần thiết cho thông báo
      );

      await repository.createNotification(
        receiverId: _auth.currentUser!.uid,
        type: type,
        sender: sender,
        postId: data['postId'],
        commentId: data['commentId'],
        chatId: data['chatId'],
        messageContent: data['messageContent'],
      );
    } catch (e) {
      debugPrint('Error saving notification to Firestore: $e');
    }
  }

  /// Xử lý khi người dùng nhấn vào thông báo
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('Message opened app: ${message.messageId}');

    // Validate data
    if (!_validateMessageData(message.data)) {
      debugPrint('Invalid message data');
      return;
    }

    // Xử lý dữ liệu thông báo
    _handleNotificationData(message.data);
  }

  /// Kiểm tra xem ứng dụng có được mở từ thông báo không
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('App opened from terminated state by notification');
      if (_validateMessageData(initialMessage.data)) {
        _handleNotificationData(initialMessage.data);
      }
    }
  }

  /// Xử lý dữ liệu thông báo
  void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('Handling notification data: $data');

    final type = NotificationType.fromString(data['type']);
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // Sử dụng BuildContext từ navigator
    final context = navigator.context;

    // Đánh dấu thông báo đã đọc nếu có notificationId
    final notificationId = data['notificationId'];
    if (notificationId != null) {
      final repository = _ref.read(notificationRepositoryProvider);
      repository.markAsRead(notificationId).catchError((error) {
        debugPrint('Error marking notification as read: $error');
      });
    }

    // Sử dụng NotificationNavigationService
    NotificationNavigationService.handleNotificationNavigation(
      context,
      type,
      postId: data['postId'],
      chatId: data['chatId'],
      senderId: data['senderId'],
    );
  }

  /// Xử lý khi người dùng nhấn vào thông báo local
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      final Map<String, dynamic> data = json.decode(payload);
      if (_validateMessageData(data)) {
        _handleNotificationData(data);
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  /// Lấy token FCM hiện tại
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Gửi thông báo đẩy đến nhiều người dùng
  Future<void> sendMulticastPushNotification({
    required List<String> receiverTokens,
    required String title,
    required String body,
    required NotificationType type,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    String? postId,
    String? commentId,
    String? chatId,
    String? messageContent,
  }) async {
    try {
      if (receiverTokens.isEmpty) {
        debugPrint('No receiver tokens provided');
        return;
      }

      // Tạo batch để thêm nhiều thông báo cùng lúc
      final batch = _firestore.batch();
      final queueRef = _firestore.collection('notifications_queue');

      // Dữ liệu cơ bản cho thông báo
      final baseData = {
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'type': type.value,
          'senderId': senderId,
          'senderName': senderName,
          if (senderAvatar != null) 'senderAvatar': senderAvatar,
          if (postId != null) 'postId': postId,
          if (commentId != null) 'commentId': commentId,
          if (chatId != null) 'chatId': chatId,
          if (messageContent != null) 'messageContent': messageContent,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Thêm thông báo cho từng token
      for (final token in receiverTokens) {
        final docRef = queueRef.doc();
        batch.set(docRef, {
          ...baseData,
          'token': token,
        });
      }

      // Commit batch
      await batch.commit();
      debugPrint('Multicast push notifications queued successfully');
    } catch (e) {
      debugPrint('Error sending multicast push notifications: $e');
      rethrow;
    }
  }

  /// Gửi thông báo đẩy đến một người dùng cụ thể
  Future<void> sendPushNotification({
    required String receiverToken,
    required String title,
    required String body,
    required NotificationType type,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    String? postId,
    String? commentId,
    String? chatId,
    String? messageContent,
  }) async {
    try {
      // Tạo dữ liệu thông báo
      final notificationData = {
        'token': receiverToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'type': type.value,
          'senderId': senderId,
          'senderName': senderName,
          if (senderAvatar != null) 'senderAvatar': senderAvatar,
          if (postId != null) 'postId': postId,
          if (commentId != null) 'commentId': commentId,
          if (chatId != null) 'chatId': chatId,
          if (messageContent != null) 'messageContent': messageContent,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Thêm vào collection notifications_queue để Cloud Functions xử lý
      await _firestore.collection('notifications_queue').add(notificationData);

      debugPrint('Push notification queued successfully');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      rethrow;
    }
  }

  /// Tạo và gửi thông báo like
  Future<void> sendLikeNotification({
    required String receiverToken,
    required String senderName,
    required String senderId,
    required String postId,
    String? senderAvatar,
  }) async {
    await sendPushNotification(
      receiverToken: receiverToken,
      title: 'Lượt thích mới',
      body: '$senderName đã thích bài viết của bạn',
      type: NotificationType.like,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      postId: postId,
    );
  }

  /// Tạo và gửi thông báo comment
  Future<void> sendCommentNotification({
    required String receiverToken,
    required String senderName,
    required String senderId,
    required String postId,
    required String commentId,
    String? senderAvatar,
  }) async {
    await sendPushNotification(
      receiverToken: receiverToken,
      title: 'Bình luận mới',
      body: '$senderName đã bình luận về bài viết của bạn',
      type: NotificationType.comment,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      postId: postId,
      commentId: commentId,
    );
  }

  /// Tạo và gửi thông báo tin nhắn
  Future<void> sendMessageNotification({
    required String receiverToken,
    required String senderName,
    required String senderId,
    required String chatId,
    required String messageContent,
    String? senderAvatar,
  }) async {
    await sendPushNotification(
      receiverToken: receiverToken,
      title: 'Tin nhắn mới',
      body: '$senderName: $messageContent',
      type: NotificationType.message,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      chatId: chatId,
      messageContent: messageContent,
    );
  }

  /// Tạo và gửi thông báo lời mời kết bạn
  Future<void> sendFriendRequestNotification({
    required String receiverToken,
    required String senderName,
    required String senderId,
    String? senderAvatar,
  }) async {
    await sendPushNotification(
      receiverToken: receiverToken,
      title: 'Lời mời kết bạn',
      body: '$senderName muốn kết bạn với bạn',
      type: NotificationType.friendRequest,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  /// Tạo và gửi thông báo chấp nhận kết bạn
  Future<void> sendFriendAcceptNotification({
    required String receiverToken,
    required String senderName,
    required String senderId,
    String? senderAvatar,
  }) async {
    await sendPushNotification(
      receiverToken: receiverToken,
      title: 'Đã chấp nhận lời mời',
      body: '$senderName đã chấp nhận lời mời kết bạn của bạn',
      type: NotificationType.friendAccept,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  /// Lấy FCM token của một người dùng từ Firestore
  Future<String?> getUserToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('User $userId not found');
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) return null;

      return userData['fcmToken'] as String?;
    } catch (e) {
      debugPrint('Error getting user token: $e');
      return null;
    }
  }

  /// Lưu FCM token vào thông tin người dùng
  Future<void> saveTokenToUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('Không thể lấy FCM token');
        return;
      }

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });

      debugPrint('Đã lưu FCM token cho người dùng $userId');
    } catch (e) {
      debugPrint('Lỗi khi lưu FCM token: $e');
    }
  }

  /// Xóa FCM token của người dùng khi đăng xuất
  Future<void> removeToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });

      debugPrint('Đã xóa FCM token của người dùng $userId');
    } catch (e) {
      debugPrint('Lỗi khi xóa FCM token: $e');
    }
  }
}
