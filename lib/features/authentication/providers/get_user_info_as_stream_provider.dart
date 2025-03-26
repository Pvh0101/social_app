import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/log_utils.dart';

import '../models/user_model.dart';

/// `getUserInfoAsStreamProvider` là một `StreamProvider`
///
/// Provider này lắng nghe **thông tin của người dùng hiện tại** trong Firestore
/// theo thời gian thực, dựa vào `uid` của người dùng đang đăng nhập.
///
/// - **Đầu vào**: Không có (tự động lấy `uid` của người dùng hiện tại).
/// - **Đầu ra**: `Stream<UserModel>` – thông tin của người dùng hiện tại.
///
/// 🔹 **Cách sử dụng trong UI**:
/// ```dart
/// final userStream = ref.watch(getUserInfoAsStreamProvider);
///
/// userStream.when(
///   data: (user) => Text("Xin chào, ${user.displayName}"),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stackTrace) => Text("Lỗi: $error"),
/// );
/// ```
///
/// 🔹 **Cơ chế hoạt động**:
/// - Lắng nghe Firestore collection `users`, lọc theo `uid` của người dùng hiện tại.
/// - Khi có thay đổi, dữ liệu mới sẽ được ánh xạ (`map()`) thành một đối tượng `UserModel`.
///
/// 🔹 **Lưu ý**:
/// - Người dùng phải đăng nhập (`FirebaseAuth.instance.currentUser` không được null).
/// - Nếu `uid` không tồn tại trong Firestore, có thể gây lỗi khi truy cập `docs.first`.
final getUserInfoAsStreamProvider =
    StreamProvider.autoDispose<UserModel>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    logError(LogService.AUTH,
        '[USER_STREAM] Không thể tạo stream thông tin người dùng: currentUser là null');
    throw Exception('Người dùng chưa đăng nhập');
  }

  logDebug(LogService.AUTH,
      '[USER_STREAM] Khởi tạo stream theo dõi thông tin người dùng: $uid');

  ref.onDispose(() {
    logDebug(LogService.AUTH,
        '[USER_STREAM] Hủy stream theo dõi thông tin người dùng: $uid');
  });

  return FirebaseFirestore.instance
      .collection('users')
      .where('uid', isEqualTo: uid)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      logError(LogService.AUTH,
          '[USER_STREAM] Không tìm thấy dữ liệu người dùng trong stream: $uid');
      throw Exception('Không tìm thấy thông tin người dùng');
    }

    logDebug(LogService.AUTH,
        '[USER_STREAM] Nhận cập nhật thông tin người dùng từ stream: $uid');
    final userData = snapshot.docs.first;
    return UserModel.fromMap(userData.data());
  });
});
