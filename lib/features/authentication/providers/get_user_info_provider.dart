import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../core/utils/log_utils.dart';

/// `getUserInfoProvider` là một `FutureProvider`
///
/// Provider này chịu trách nhiệm lấy thông tin của **người dùng hiện tại**
/// từ Firestore dựa trên `uid` của họ.
///
/// - **Đầu vào**: Không có.
/// - **Đầu ra**: Trả về một `Future<UserModel>`, chứa thông tin của người dùng.
///
/// 🔹 **Cách sử dụng trong UI**:
/// ```dart
/// final userInfo = ref.watch(getUserInfoProvider);
///
/// userInfo.when(
///   data: (user) => Text("Xin chào, ${user.displayName}"),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stackTrace) => Text("Lỗi: $error"),
/// );
/// ```
///
/// 🔹 **Lưu ý**:
/// - Nếu `FirebaseAuth.instance.currentUser` là `null`, hàm sẽ gặp lỗi.
/// - Để tránh lỗi, nên đảm bảo người dùng đã đăng nhập trước khi gọi provider này.
final getUserInfoProvider = FutureProvider.autoDispose<UserModel>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    logError(LogService.AUTH,
        '[USER_INFO] Không thể lấy thông tin người dùng: currentUser là null');
    throw Exception('Người dùng chưa đăng nhập');
  }

  logDebug(
      LogService.AUTH, '[USER_INFO] Lấy thông tin người dùng cho UID: $uid');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get()
      .then((userData) {
    if (!userData.exists) {
      logError(LogService.AUTH,
          '[USER_INFO] Không tìm thấy dữ liệu người dùng cho UID: $uid');
      throw Exception('Không tìm thấy thông tin người dùng');
    }

    logInfo(LogService.AUTH,
        '[USER_INFO] Đã lấy thông tin người dùng thành công: $uid');
    return UserModel.fromMap(userData.data()!);
  }).catchError((error) {
    logError(LogService.AUTH,
        '[USER_INFO] Lỗi khi lấy thông tin người dùng: $error');
    throw error;
  });
});
