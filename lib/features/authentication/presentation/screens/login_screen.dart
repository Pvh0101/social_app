import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../screens/home_screen.dart';
import '../../../../core/core.dart';
import '../../../../core/widgets/fields/password_text_field.dart';
import '../../providers/auth_provider.dart';

/// Màn hình đăng nhập của ứng dụng.
///
/// [LoginScreen] cho phép người dùng đăng nhập vào ứng dụng bằng email và mật khẩu.
/// Màn hình này cung cấp các tính năng:
/// - Đăng nhập bằng email/mật khẩu
/// - Chuyển hướng đến màn hình đăng ký
/// - Khôi phục mật khẩu đã quên
///
/// Màn hình sử dụng [authProvider] để thực hiện các thao tác xác thực.
class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = RouteConstants.login;
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// State của màn hình đăng nhập.
///
/// Quản lý form đăng nhập, xử lý việc xác thực và điều hướng.
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.logDebug(
        LogService.AUTH, '[LOGIN] Màn hình đăng nhập đã được khởi tạo');
  }

  /// Xử lý quá trình đăng nhập.
  ///
  /// Kiểm tra tính hợp lệ của form, gọi API đăng nhập và xử lý kết quả.
  /// Hiển thị thông báo lỗi nếu đăng nhập thất bại.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      ref.logWarning(LogService.AUTH, '[LOGIN] Form đăng nhập không hợp lệ');
      return;
    }

    try {
      setState(() => _isLoading = true);
      ref.logInfo(LogService.AUTH,
          '[LOGIN] Bắt đầu quá trình đăng nhập với email: ${_emailController.text}');

      final authRepository = ref.read(authProvider);
      final credential = await authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Kiểm tra xác thực email
      if (!credential.user!.emailVerified) {
        ref.logWarning(LogService.AUTH, '[LOGIN] Email chưa được xác thực');
        if (!mounted) return;

        // Chuyển đến màn hình xác thực email và xóa stack cũ
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteConstants.emailVerification,
          (route) => false,
          arguments: {
            'uid': credential.user!.uid,
            'email': credential.user!.email,
          },
        );
        return;
      }

      // Kiểm tra thông tin profile
      final isProfileComplete = await authRepository.isCompleteProfile();

      if (!mounted) return;

      if (!isProfileComplete) {
        ref.logWarning(LogService.AUTH, '[LOGIN] Profile chưa hoàn thiện');
        // Chưa có thông tin -> chuyển đến màn hình nhập thông tin
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteConstants.userInformation,
          (route) => false,
          arguments: {
            'uid': credential.user!.uid,
            'email': credential.user!.email,
          },
        );
        return;
      }

      ref.logInfo(LogService.AUTH,
          '[LOGIN] Đăng nhập thành công, chuyển đến trang chính');
      // Đã có đầy đủ thông tin -> chuyển đến home và xóa stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      ref.logError(
          LogService.AUTH, '[LOGIN] Đăng nhập thất bại', e, StackTrace.current);
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ref.logWarning(LogService.AUTH,
          '[PASSWORD] Email không được cung cấp cho đặt lại mật khẩu');
      showToastMessage(text: 'validations.email.required'.tr());
      return;
    }

    try {
      setState(() => _isLoading = true);
      ref.logInfo(LogService.AUTH,
          '[PASSWORD] Bắt đầu quá trình đặt lại mật khẩu cho: $email');

      final authRepository = ref.read(authProvider);
      await authRepository.resetPassword(email);

      if (!mounted) return;

      ref.logInfo(LogService.AUTH,
          '[PASSWORD] Đã gửi email đặt lại mật khẩu thành công');
      showToastMessage(text: 'auth.reset_password.success'.tr());
    } catch (e) {
      ref.logError(LogService.AUTH, '[PASSWORD] Lỗi gửi email đặt lại mật khẩu',
          e, StackTrace.current);
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        actions: const [
          Row(
            children: [
              LanguageSwitchButton(),
              SizedBox(width: 8),
              Text('|'),
              SizedBox(width: 8),
              ThemeSwitchButton(),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildLoginForm(),
                const SizedBox(height: 24),
                _buildButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          width: 160,
          child: Lottie.asset(AssetsManager.social),
        ),
        const SizedBox(height: 16),
        Text(
          'login_verification_message'.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundTextField(
          controller: _emailController,
          labelText: 'fields.email.label'.tr(),
          hintText: 'fields.email.hint'.tr(),
          keyboardType: TextInputType.emailAddress,
          validator: ValidationUtils.validateEmail,
          enabled: !_isLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        PasswordTextField(
          controller: _passwordController,
          labelText: 'fields.password.label'.tr(),
          validator: ValidationUtils.validatePassword,
          enabled: !_isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading ? null : _handleForgotPassword,
            child: Text('auth.login.forgot_password'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundButtonFill(
          onPressed: _isLoading ? null : _handleLogin,
          label: _isLoading
              ? 'auth.login.processing'.tr()
              : 'auth.login.button'.tr(),
          color: Theme.of(context).colorScheme.primary,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('auth.login.no_account'.tr()),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        RouteConstants.register,
                      ),
              child: Text(
                'auth.register.button'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
