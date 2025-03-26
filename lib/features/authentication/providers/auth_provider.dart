import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/auth_repository.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/log_utils.dart';

/// Provider cho AuthRepository
///
/// Provider này tạo và cung cấp một instance của [AuthRepository] với các
/// dependencies cần thiết (Firebase Auth, Firestore, FCM Service).
///
/// 🔹 **Cách sử dụng**:
/// ```dart
/// final authRepo = ref.watch(authRepositoryProvider);
/// await authRepo.signIn(email: email, password: password);
/// ```
///
/// 🔹 **Lưu ý**:
/// - Đây là provider chính cho các thao tác xác thực.
/// - Nên sử dụng provider này thay vì tạo instance AuthRepository trực tiếp.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  logDebug(LogService.AUTH, '[INIT] Khởi tạo AuthRepository');
  final fcmService = ref.watch(fcmServiceProvider);
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    fcmService: fcmService,
  );
});

/// Provider cho AuthRepository (legacy)
///
/// Provider này được giữ lại để tương thích với mã nguồn cũ.
/// Nó chỉ đơn giản là chuyển tiếp đến [authRepositoryProvider].
///
/// 🔹 **Cách sử dụng**:
/// ```dart
/// final authRepo = ref.watch(authProvider);
/// await authRepo.signIn(email: email, password: password);
/// ```
///
/// 🔹 **Lưu ý**:
/// - Nên sử dụng [authRepositoryProvider] cho code mới.
final authProvider = Provider((ref) {
  logDebug(
      LogService.AUTH, '[ACCESS] Truy cập AuthRepository qua authProvider');
  return ref.watch(authRepositoryProvider);
});
