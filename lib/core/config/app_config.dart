// lib/core/config/app_config.dart
class AppConfig {
  // App Information
  static const String appName = 'Social App';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.example.social_app';

  // Environment
  static const bool isDevelopment = true;
  static const String apiBaseUrl =
      isDevelopment ? 'https://dev-api.example.com' : 'https://api.example.com';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Cache Config
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Upload Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB

  // Auth Config
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration sessionTimeout = Duration(hours: 24);

  // App Settings
  static const String defaultLanguage = 'vi';
  static const String defaultTheme = 'light';
  static const List<String> supportedLocales = ['en', 'vi'];
}
