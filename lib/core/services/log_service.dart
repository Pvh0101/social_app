import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service quản lý log tập trung cho ứng dụng.
///
/// LogService cung cấp các phương thức để log theo cấp độ khác nhau,
/// với định dạng thống nhất và phân chia theo module.
class LogService {
  // Singleton pattern
  static final LogService _instance = LogService._internal();

  factory LogService() => _instance;

  LogService._internal() {
    _initLogger();
  }

  late final Logger _logger;

  void _initLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // Không hiển thị stack trace cho các log thông thường
        errorMethodCount: 8, // Hiển thị 8 dòng stack trace cho lỗi
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );
  }

  // Log thông tin debug
  void d(String module, String message) {
    if (kDebugMode) {
      _logger.d('[$module] $message');
    }
  }

  // Log thông tin
  void i(String module, String message) {
    _logger.i('[$module] $message');
  }

  // Log cảnh báo
  void w(String module, String message) {
    _logger.w('[$module] $message');
  }

  // Log lỗi
  void e(String module, String message,
      [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$module] $message', error: error, stackTrace: stackTrace);
  }

  // Log lỗi nghiêm trọng
  void wtf(String module, String message,
      [dynamic error, StackTrace? stackTrace]) {
    _logger.f('[$module] $message', error: error, stackTrace: stackTrace);
  }

  // === Các hằng số module ===
  // Sử dụng các hằng số này để đảm bảo tính nhất quán trong toàn bộ ứng dụng
  static const String AUTH = 'AUTH';
  static const String CHAT = 'CHAT';
  static const String POST = 'POST';
  static const String FRIEND = 'FRIEND';
  static const String PROFILE = 'PROFILE';
  static const String NOTIF = 'NOTIF';
  static const String NETWORK = 'NETWORK';
  static const String UI = 'UI';
  static const String MEDIA = 'MEDIA';
  static const String SYSTEM = 'SYSTEM';
}

// Biến global để dễ dàng truy cập từ mọi nơi
final logService = LogService();
