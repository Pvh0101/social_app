import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/global_method.dart';
import '../../features/authentication/repository/auth_repository.dart';

/// Observer để theo dõi và xử lý trạng thái lifecycle của ứng dụng
class AppLifecycleObserver with WidgetsBindingObserver {
  final AuthRepository _authRepository;
  Timer? _debounceTimer;
  Timer? _offlineTimer;

  AppLifecycleObserver(this._authRepository) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _debounceTimer?.cancel();
      _offlineTimer?.cancel();

      switch (state) {
        case AppLifecycleState.resumed:
          // Cập nhật online ngay lập tức
          _authRepository.updateUserStatus(true);
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          // Đợi 2 phút trước khi chuyển sang offline
          _offlineTimer = Timer(const Duration(minutes: 1), () {
            _authRepository.updateUserStatus(false);
          });
          break;
      }
    } catch (e) {
      logger.e('AppLifecycleObserver error: $e');
    }
  }

  /// Dispose observer khi không cần thiết
  void dispose() {
    _debounceTimer?.cancel();
    _offlineTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
