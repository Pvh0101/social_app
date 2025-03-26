import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log_utils.dart';
import '../models/user_model.dart';

/// `getUserInfoByIdProvider` là một `FutureProvider.family`
///
/// Provider này chịu trách nhiệm lấy thông tin của **một người dùng cụ thể**
/// từ Firestore dựa trên `userId` được truyền vào.
///
/// - **Đầu vào**: `String userId` – UID của người dùng cần lấy thông tin.
/// - **Đầu ra**: `Future<UserModel>` – thông tin của người dùng tương ứng.
///
/// 🔹 **Cách sử dụng trong UI**:
/// ```dart
/// final userInfo = ref.watch(getUserInfoByIdProvider('someUserId'));
///
/// userInfo.when(
///   data: (user) => Text("Tên người dùng: ${user.displayName}"),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stackTrace) => Text("Lỗi: $error"),
/// );
/// ```
///
/// 🔹 **Lưu ý**:
/// - `userId` phải tồn tại trong Firestore, nếu không sẽ gây lỗi.
/// - Không tự động cập nhật khi dữ liệu thay đổi (không phải stream).
///
/// 🚀 **Sử dụng khi cần hiển thị thông tin của một người dùng cụ thể một lần.**
final getUserInfoByIdProvider =
    FutureProvider.autoDispose.family<UserModel, String>((ref, userId) {
  logDebug(LogService.AUTH,
      '[USER_INFO_ID] Lấy thông tin người dùng theo ID: $userId');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get()
      .then((userData) {
    if (!userData.exists) {
      logError(LogService.AUTH,
          '[USER_INFO_ID] Không tìm thấy dữ liệu người dùng cho ID: $userId');
      throw Exception('Không tìm thấy thông tin người dùng');
    }

    logInfo(LogService.AUTH,
        '[USER_INFO_ID] Đã lấy thông tin người dùng thành công: $userId');
    return UserModel.fromMap(userData.data()!);
  }).catchError((error) {
    logError(LogService.AUTH,
        '[USER_INFO_ID] Lỗi khi lấy thông tin người dùng theo ID: $error');
    throw error;
  });
});
