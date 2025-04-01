import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/log_utils.dart';
import '../models/user_model.dart';

/// `getUserInfoAsStreamByIdProvider` là một `StreamProvider.family`
///
/// Provider này **lắng nghe thông tin của một người dùng bất kỳ** theo thời gian thực,
/// dựa trên `userId` được truyền vào.
///
/// - **Đầu vào**: `String userId` – UID của người dùng cần lấy thông tin.
/// - **Đầu ra**: `Stream<UserModel>` – thông tin của người dùng tương ứng.
///
/// 🔹 **Cách sử dụng trong UI**:
/// ```dart
/// final userStream = ref.watch(getUserInfoAsStreamByIdProvider('someUserId'));
///
/// userStream.when(
///   data: (user) => Text("Tên người dùng: ${user.displayName}"),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stackTrace) => Text("Lỗi: $error"),
/// );
/// ```
///
/// 🔹 **Cơ chế hoạt động**:
/// - Lắng nghe Firestore collection `users`, tìm kiếm user theo `uid` truyền vào.
/// - Khi có thay đổi, dữ liệu mới sẽ được ánh xạ (`map()`) thành một đối tượng `UserModel`.
///
/// 🔹 **Lưu ý**:
/// - `userId` phải tồn tại trong Firestore, nếu không sẽ gây lỗi khi truy cập `docs.first`.
/// - Dữ liệu được cập nhật tự động khi có thay đổi trong Firestore.
///
/// 🚀 **Sử dụng khi cần hiển thị thông tin của một người dùng bất kỳ trong thời gian thực.**
final getUserInfoAsStreamByIdProvider =
    StreamProvider.autoDispose.family<UserModel, String>((ref, String userId) {
  if (userId.isEmpty) {
    logError(LogService.AUTH,
        '[USER_STREAM_ID] Không thể tạo stream thông tin người dùng: userId trống');
    throw Exception('userId không được để trống');
  }

  logDebug(LogService.AUTH,
      '[USER_STREAM_ID] Khởi tạo stream theo dõi thông tin người dùng theo ID: $userId');

  ref.onDispose(() {
    logDebug(LogService.AUTH,
        '[USER_STREAM_ID] Hủy stream theo dõi thông tin người dùng theo ID: $userId');
  });

  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      logError(LogService.AUTH,
          '[USER_STREAM_ID] Không tìm thấy dữ liệu người dùng trong stream theo ID: $userId');
      throw Exception('Không tìm thấy thông tin người dùng');
    }

    logDebug(LogService.AUTH,
        '[USER_STREAM_ID] Nhận cập nhật thông tin người dùng từ stream theo ID: $userId');
    final userData = snapshot.docs.first;
    return UserModel.fromMap(userData.data());
  });
});
