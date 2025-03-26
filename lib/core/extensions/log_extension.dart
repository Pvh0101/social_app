import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_service.dart';

/// Extension cho WidgetRef để dễ dàng sử dụng LogService trong các widget.
extension LogExtension on WidgetRef {
  /// Log thông tin debug
  void logDebug(String module, String message) {
    logService.d(module, message);
  }

  /// Log thông tin
  void logInfo(String module, String message) {
    logService.i(module, message);
  }

  /// Log cảnh báo
  void logWarning(String module, String message) {
    logService.w(module, message);
  }

  /// Log lỗi
  void logError(String module, String message,
      [dynamic error, StackTrace? stackTrace]) {
    logService.e(module, message, error, stackTrace);
  }

  /// Log lỗi nghiêm trọng
  void logCritical(String module, String message,
      [dynamic error, StackTrace? stackTrace]) {
    logService.wtf(module, message, error, stackTrace);
  }
}

/// Extension cho StateNotifier để dễ dàng sử dụng LogService trong các provider.
extension StateNotifierLogExtension on StateNotifier {
  /// Log thông tin debug
  void logDebug(String module, String message) {
    logService.d(module, message);
  }

  /// Log thông tin
  void logInfo(String module, String message) {
    logService.i(module, message);
  }

  /// Log cảnh báo
  void logWarning(String module, String message) {
    logService.w(module, message);
  }

  /// Log lỗi
  void logError(String module, String message,
      [dynamic error, StackTrace? stackTrace]) {
    logService.e(module, message, error, stackTrace);
  }

  /// Log lỗi nghiêm trọng
  void logCritical(String module, String message,
      [dynamic error, StackTrace? stackTrace]) {
    logService.wtf(module, message, error, stackTrace);
  }
}
