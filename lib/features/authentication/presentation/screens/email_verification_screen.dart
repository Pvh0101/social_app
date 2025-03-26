import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/core.dart';
import '../../providers/auth_provider.dart';

/// Màn hình xác minh email.
///
/// [EmailVerificationScreen] hiển thị sau khi người dùng đăng ký tài khoản mới
/// và cần xác minh địa chỉ email của họ. Màn hình này:
/// - Hiển thị hướng dẫn xác minh email
/// - Cho phép gửi lại email xác minh
/// - Tự động kiểm tra trạng thái xác minh
/// - Điều hướng người dùng sau khi xác minh thành công
///
/// Màn hình yêu cầu [email] và [uid] của người dùng để hoạt động.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  static const String routeName = RouteConstants.emailVerification;
  final String email;
  final String uid;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.uid,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

/// State của màn hình xác minh email.
///
/// Quản lý việc kiểm tra trạng thái xác minh và gửi lại email.
class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _timer;
  bool _isChecking = false;
  bool _isResendLoading = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    ref.logInfo(LogService.AUTH,
        '[VERIFY] Khởi tạo màn hình xác thực email cho: ${widget.email}');
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    ref.logDebug(LogService.AUTH,
        '[VERIFY] Bắt đầu chu kỳ kiểm tra trạng thái xác thực email');
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified(showLoading: false);
    });
  }

  Future<void> _checkEmailVerified({bool showLoading = true}) async {
    try {
      if (!mounted) return;
      if (showLoading) {
        setState(() => _isChecking = true);
      }

      ref.logDebug(LogService.AUTH,
          '[VERIFY] Kiểm tra trạng thái xác thực email: ${widget.email}');
      final authRepository = ref.read(authProvider);

      // Đảm bảo cập nhật thông tin người dùng từ server
      await FirebaseAuth.instance.currentUser?.reload();

      final isVerified = await authRepository.checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        _timer?.cancel();
        ref.logInfo(LogService.AUTH,
            '[VERIFY] Email đã được xác thực thành công: ${widget.email}');
        showToastMessage(text: 'email_verification.verify.success'.tr());
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            RouteConstants.userInformation,
            arguments: {
              'uid': widget.uid,
              'email': widget.email,
            },
          );
        }
      } else {
        ref.logDebug(LogService.AUTH,
            '[VERIFY] Email chưa được xác thực: ${widget.email}');
      }
    } catch (e) {
      ref.logError(LogService.AUTH, '[VERIFY] Lỗi kiểm tra xác thực email', e,
          StackTrace.current);
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResendLoading || _resendCountdown > 0) return;

    try {
      setState(() => _isResendLoading = true);
      ref.logInfo(LogService.AUTH,
          '[VERIFY] Gửi lại email xác thực cho: ${widget.email}');

      final authRepository = ref.read(authProvider);
      await authRepository.resendVerificationEmail();

      if (!mounted) return;

      ref.logInfo(
          LogService.AUTH, '[VERIFY] Đã gửi lại email xác thực thành công');
      showToastMessage(text: 'email_verification.resend.success'.tr());
      _startResendTimer();
    } catch (e) {
      ref.logError(LogService.AUTH, '[VERIFY] Lỗi gửi lại email xác thực', e,
          StackTrace.current);
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isResendLoading = false);
      }
    }
  }

  void _startResendTimer() {
    ref.logDebug(LogService.AUTH,
        '[VERIFY] Bắt đầu đếm ngược thời gian gửi lại email (60s)');
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          ref.logDebug(LogService.AUTH,
              '[VERIFY] Hết thời gian đếm ngược, có thể gửi lại email');
          _resendTimer?.cancel();
        }
      });
    });
  }

  Future<void> _signOut() async {
    try {
      ref.logInfo(
          LogService.AUTH, '[VERIFY] Đăng xuất từ màn hình xác thực email');
      await ref.read(authProvider).logout();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteConstants.login,
        (route) => false,
      );
    } catch (e) {
      ref.logError(
          LogService.AUTH, '[VERIFY] Lỗi đăng xuất', e, StackTrace.current);
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    ref.logDebug(LogService.AUTH, '[VERIFY] Hủy màn hình xác thực email');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Icon(
              Icons.mark_email_unread_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'email_verification.subtitle'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'email_verification.instruction'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'email_verification.check_spam'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Nút làm mới trạng thái
            if (_isChecking)
              const CircularProgressIndicator()
            else
              OutlinedButton.icon(
                onPressed: _checkEmailVerified,
                icon: const Icon(Icons.refresh),
                label: Text('email_verification.actions.refresh'.tr()),
              ),
            const SizedBox(height: 16),

            // Nút gửi lại email
            TextButton(
              onPressed: _resendCountdown > 0 ? null : _resendVerificationEmail,
              child: Text(
                _resendCountdown > 0
                    ? 'email_verification.resend.wait'
                        .tr(args: [_resendCountdown.toString()])
                    : 'email_verification.resend.button'.tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
