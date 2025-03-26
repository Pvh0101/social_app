import 'package:easy_localization/easy_localization.dart';

class ValidationUtils {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  static final RegExp _nameRegex = RegExp(
    r'^[a-zA-ZÀ-ỹ\s]{2,50}$',
    unicode: true,
  );

  static final RegExp _phoneRegex = RegExp(
    r'^(\+84|0)[1-9][0-9]{8,9}$',
  );

  static String? validateEmail(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return 'validations.email.required'.tr();
    }
    if (!_emailRegex.hasMatch(trimmedValue)) {
      return 'validations.email.invalid'.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'validations.password.required'.tr();
    }
    if (value.length < 8) {
      return 'validations.password.length'.tr();
    }
    if (!_passwordRegex.hasMatch(value)) {
      return 'validations.password.complexity'.tr();
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'validations.confirm_password.required'.tr();
    }
    if (value != password) {
      return 'validations.confirm_password.not_match'.tr();
    }
    return null;
  }

  static String? validateName(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return 'validations.name.required'.tr();
    }
    if (trimmedValue.length < 2) {
      return 'validations.name.length'.tr();
    }
    if (!_nameRegex.hasMatch(trimmedValue)) {
      return 'validations.name.invalid'.tr();
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return 'validations.phone.required'.tr();
    }
    if (!_phoneRegex.hasMatch(trimmedValue)) {
      return 'validations.phone.invalid'.tr();
    }
    return null;
  }

  static bool isStrongPassword(String password) {
    return _passwordRegex.hasMatch(password);
  }

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  static bool isValidPhone(String phone) {
    return _phoneRegex.hasMatch(phone.trim());
  }

  static bool isValidName(String name) {
    return _nameRegex.hasMatch(name.trim());
  }
}
