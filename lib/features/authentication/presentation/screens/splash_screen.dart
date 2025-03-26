import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/core.dart';
import '../../../screens/home_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state_provider.dart';
import '../screens/email_verification_screen.dart';
import '../screens/login_screen.dart';
import '../screens/user_information_screen.dart';

/// Màn hình khởi động của ứng dụng.
///
/// [SplashScreen] hiển thị khi ứng dụng khởi động và chịu trách nhiệm:
/// - Kiểm tra trạng thái đăng nhập của người dùng
/// - Kiểm tra xác minh email
/// - Kiểm tra thông tin cá nhân đã hoàn thiện chưa
/// - Điều hướng người dùng đến màn hình phù hợp (đăng nhập, xác minh email,
///   nhập thông tin, hoặc màn hình chính)
///
/// Màn hình này sử dụng [authStateProvider] để theo dõi trạng thái xác thực.
class SplashScreen extends ConsumerWidget {
  static const String routeName = RouteConstants.splash;
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          return FutureBuilder(
            future: _checkUserState(user, ref, context),
            builder: (context, stateSnapshot) {
              if (stateSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingView();
              }

              if (stateSnapshot.hasError) {
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }

              final nextScreen = stateSnapshot.data;
              return nextScreen!;
            },
          );
        },
        loading: () => _buildLoadingView(),
        error: (error, stack) {
          logger.e('[SPLASH] $error');
          return const LoginScreen();
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.asset(
              AssetsManager.social,
              repeat: true,
              animate: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _checkUserState(
      User user, WidgetRef ref, BuildContext context) async {
    try {
      logger.i('[SPLASH] Kiểm tra trạng thái người dùng: ${user.email}');

      // 1. Kiểm tra xác thực email
      if (!user.emailVerified) {
        logger.w('[SPLASH] Email chưa được xác thực: ${user.email}');
        return EmailVerificationScreen(
          email: user.email!,
          uid: user.uid,
        );
      }

      // 2. Kiểm tra thông tin profile
      logger.d('[SPLASH] Email đã xác thực, kiểm tra thông tin profile');
      final authRepository = ref.read(authProvider);
      final isProfileComplete = await authRepository.isCompleteProfile();

      if (!isProfileComplete) {
        logger.w('[SPLASH] Thông tin profile chưa đầy đủ: ${user.email}');
        return UserInformationScreen(
          arguments: {
            'uid': user.uid,
            'email': user.email,
          },
        );
      }

      // 3. Chỉ cập nhật trạng thái online khi đã xác thực email và hoàn thành profile
      logger.i(
          '[SPLASH] Tất cả điều kiện đã thỏa mãn, cập nhật trạng thái online');
      await authRepository.updateUserStatus(true);

      return const HomeScreen();
    } catch (e) {
      logger.e('[SPLASH] Lỗi khi kiểm tra trạng thái người dùng: $e');
      throw e;
    }
  }
}
