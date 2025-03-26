import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase_options.dart';

/// Service cấu hình Firebase và các dịch vụ liên quan
class FirebaseConfigService {
  // Singleton pattern
  static final FirebaseConfigService _instance =
      FirebaseConfigService._internal();
  factory FirebaseConfigService() => _instance;
  FirebaseConfigService._internal();

  /// Khởi tạo tất cả các dịch vụ Firebase
  Future<void> initializeFirebase() async {
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Cấu hình Firestore
    configureFirestore();

    // Đăng ký handler cho thông báo nền
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Xử lý thông báo khi ứng dụng đang ở trạng thái terminated
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Đảm bảo Firebase đã được khởi tạo
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    debugPrint("Handling a background message: ${message.messageId}");
    // Không hiển thị thông báo ở đây, chỉ xử lý dữ liệu
  }

  /// Khởi tạo và cấu hình cho Firestore
  void configureFirestore() {
    // Cấu hình kích thước cache Firestore trong khoảng hợp lệ (1MB - 100MB)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100MB (giá trị tối đa cho phép)
    );
  }
}

/// Provider cho Firebase Config Service
final firebaseConfigServiceProvider = Provider<FirebaseConfigService>((ref) {
  return FirebaseConfigService();
});
