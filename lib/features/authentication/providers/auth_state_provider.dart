import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log_utils.dart';

/// Provider theo dõi trạng thái xác thực của người dùng
///
/// Provider này cung cấp một stream theo dõi trạng thái đăng nhập của người dùng
/// thông qua Firebase Authentication.
///
/// - **Đầu ra**: `Stream<User?>` - stream trả về đối tượng User khi đăng nhập hoặc null khi đăng xuất
///
/// 🔹 **Cách sử dụng trong UI**:
/// ```dart
/// final authState = ref.watch(authStateProvider);
///
/// authState.when(
///   data: (user) {
///     if (user != null) {
///       return Text("Đã đăng nhập: ${user.email}");
///     } else {
///       return Text("Chưa đăng nhập");
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text("Lỗi: $error"),
/// );
/// ```
///
/// 🔹 **Lưu ý**:
/// - Stream này tự động cập nhật khi trạng thái đăng nhập thay đổi
/// - Thường được sử dụng để điều hướng giữa các màn hình đăng nhập và nội dung chính
final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  logDebug(LogService.AUTH,
      '[AUTH_STATE] Khởi tạo authStateProvider - lắng nghe thay đổi trạng thái xác thực');

  final authStateStream = FirebaseAuth.instance.authStateChanges();

  ref.onDispose(() {
    logDebug(LogService.AUTH, '[AUTH_STATE] Hủy authStateProvider');
  });

  return authStateStream.map((user) {
    if (user != null) {
      logInfo(LogService.AUTH,
          '[AUTH_STATE] Trạng thái xác thực: Đã đăng nhập (${user.email})');
    } else {
      logInfo(
          LogService.AUTH, '[AUTH_STATE] Trạng thái xác thực: Chưa đăng nhập');
    }
    return user;
  });
});
