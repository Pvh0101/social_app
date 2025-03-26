// lib/core/constants/app_constants.dart
class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Storage Paths
  static const String userImagesPath = 'user_images';
  static const String messageImagesPath = 'message_images';
  static const String chatImagesPath = 'chat_images';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxBioLength = 150;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultIconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  // Timeouts
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Limits
  static const int maxLoginAttempts = 5;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxMessageLength = 1000;
  // Collections Firebase
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';

  // Storage paths
  static const String userImages = 'user_images';
  static const String messageImages = 'message_images';

  // Routes
  static const String landingScreen = '/';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String homeScreen = '/home';
  static const String userInformationScreen = '/user-information';
  static const String chatScreen = '/chat';
}
