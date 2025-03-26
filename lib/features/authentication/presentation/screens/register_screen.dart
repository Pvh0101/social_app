import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/core.dart';
import '../../../../core/widgets/fields/password_text_field.dart';
import '../../providers/auth_provider.dart';

/// Màn hình đăng ký tài khoản mới.
///
/// [RegisterScreen] cho phép người dùng tạo tài khoản mới trong ứng dụng.
/// Màn hình này cung cấp các tính năng:
/// - Đăng ký tài khoản bằng email/mật khẩu
/// - Xác nhận mật khẩu để tránh lỗi nhập
/// - Chấp nhận điều khoản sử dụng
/// - Chuyển hướng đến màn hình đăng nhập
///
/// Màn hình sử dụng [authProvider] để thực hiện các thao tác đăng ký.
class RegisterScreen extends ConsumerStatefulWidget {
  static const String routeName = RouteConstants.register;

  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// State của màn hình đăng ký.
///
/// Quản lý form đăng ký, xử lý việc tạo tài khoản và điều hướng.
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    ref.logDebug(
        LogService.AUTH, '[REGISTER] Màn hình đăng ký đã được khởi tạo');
  }

  /// Xử lý quá trình đăng ký tài khoản.
  ///
  /// Kiểm tra tính hợp lệ của form, gọi API đăng ký và xử lý kết quả.
  /// Hiển thị thông báo lỗi nếu đăng ký thất bại.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      ref.logWarning(LogService.AUTH, '[REGISTER] Form đăng ký không hợp lệ');
      return;
    }

    if (!_acceptTerms) {
      ref.logWarning(LogService.AUTH,
          '[REGISTER] Người dùng chưa chấp nhận điều khoản sử dụng');
      showToastMessage(text: 'auth.register.accept_terms'.tr());
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ref.logWarning(
          LogService.AUTH, '[REGISTER] Mật khẩu xác nhận không khớp');
      showToastMessage(text: 'validations.confirm_password.not_match'.tr());
      return;
    }

    try {
      setState(() => _isLoading = true);
      ref.logInfo(LogService.AUTH,
          '[REGISTER] Bắt đầu quá trình đăng ký với email: ${_emailController.text}');

      final authRepository = ref.read(authProvider);
      final credential = await authRepository.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ref.logInfo(LogService.AUTH,
          '[REGISTER] Đăng ký thành công, chuyển đến trang xác thực email');
      // Chuyển đến màn hình xác thực email
      Navigator.pushReplacementNamed(
        context,
        RouteConstants.emailVerification,
        arguments: {
          'uid': credential.user!.uid,
          'email': credential.user!.email,
        },
      );
    } catch (e) {
      ref.logError(LogService.AUTH, '[REGISTER] Đăng ký thất bại', e,
          StackTrace.current);
      if (mounted) {
        showToastMessage(text: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToLogin() {
    ref.logDebug(LogService.AUTH, '[REGISTER] Chuyển đến màn hình đăng nhập');
    Navigator.pushNamed(context, RouteConstants.login);
  }

  void _showTermsAndConditions() {
    ref.logDebug(LogService.AUTH, '[REGISTER] Hiển thị điều khoản sử dụng');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điều khoản sử dụng'),
        content: const SingleChildScrollView(
          child: Text(
            'Nội dung điều khoản sử dụng...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBackButton(),
        actions: const [
          Row(
            children: [
              LanguageSwitchButton(),
              Text('|'),
              ThemeSwitchButton(),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildRegisterForm(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildButtons(),
              const SizedBox(height: 24),
            ],
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
        // Text(
        //   'auth.register.title'.tr(),
        //   style: Theme.of(context).textTheme.headlineMedium,
        // ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundTextField(
            textInputAction: TextInputAction.next,
            controller: _emailController,
            labelText: 'fields.email.label'.tr(),
            hintText: 'fields.email.hint'.tr(),
            keyboardType: TextInputType.emailAddress,
            validator: ValidationUtils.validateEmail,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            textInputAction: TextInputAction.next,
            controller: _passwordController,
            labelText: 'fields.password.label'.tr(),
            hintText: 'fields.password.hint'.tr(),
            validator: ValidationUtils.validatePassword,
            enabled: !_isLoading,
            focusNode: _passwordFocusNode,
            onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            controller: _confirmPasswordController,
            labelText: 'fields.confirm_password.label'.tr(),
            hintText: 'fields.confirm_password.hint'.tr(),
            validator: (value) => ValidationUtils.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            focusNode: _confirmPasswordFocusNode,
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _acceptTerms = value!),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showTermsAndConditions,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'auth.register.terms.agree'.tr()),
                        TextSpan(
                          text: 'auth.register.terms.link'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundButtonFill(
          onPressed: _isLoading ? null : _handleRegister,
          label: _isLoading
              ? 'auth.register.processing'.tr()
              : 'auth.register.button'.tr(),
          color: Theme.of(context).colorScheme.primary,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('auth.register.have_account'.tr()),
            TextButton(
              onPressed: _isLoading ? null : _navigateToLogin,
              child: Text(
                'auth.login.button'.tr(),
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
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    ref.logDebug(LogService.AUTH, 'Màn hình đăng ký đã được hủy');
    super.dispose();
  }
}
