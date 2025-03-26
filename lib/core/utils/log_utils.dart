import '../services/log_service.dart';
export '../services/log_service.dart';
export '../extensions/log_extension.dart';

/// Hàm tiện ích để log nhanh chóng mà không cần instance
///
/// Các hàm này có thể gọi trực tiếp từ bất kỳ đâu trong ứng dụng
/// Ví dụ: logDebug(LogService.AUTH, 'Đăng nhập thành công');

void logDebug(String module, String message) {
  logService.d(module, message);
}

void logInfo(String module, String message) {
  logService.i(module, message);
}

void logWarning(String module, String message) {
  logService.w(module, message);
}

void logError(String module, String message,
    [dynamic error, StackTrace? stackTrace]) {
  logService.e(module, message, error, stackTrace);
}

void logCritical(String module, String message,
    [dynamic error, StackTrace? stackTrace]) {
  logService.wtf(module, message, error, stackTrace);
}
