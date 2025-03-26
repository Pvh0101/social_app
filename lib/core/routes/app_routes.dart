import 'package:flutter/material.dart';

import '../../features/authentication/presentation/screens/email_verification_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/user_information_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/create_group_screen.dart';
import '../../features/chat/presentation/screens/chat_info_screen.dart';
import '../../features/chat/models/chatroom.dart';
import '../../features/posts/screens/feed_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/screens/home_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../constants/routes_constants.dart';
import '../core.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        return _materialRoute(const SplashScreen());
      case RouteConstants.login:
        return _materialRoute(const LoginScreen());
      case RouteConstants.register:
        return _materialRoute(const RegisterScreen());
      case RouteConstants.userInformation:
        return _materialRoute(
          UserInformationScreen(
            arguments: settings.arguments as Map<String, dynamic>?,
          ),
        );
      case RouteConstants.emailVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return _materialRoute(
          EmailVerificationScreen(
            email: args['email'] as String,
            uid: args['uid'] as String,
          ),
        );
      case RouteConstants.home:
        return _materialRoute(const HomeScreen());
      case RouteConstants.friends:
        final args = settings.arguments as Map<String, dynamic>?;
        return _materialRoute(FriendsScreen(
          initialTabIndex: args?['initialTabIndex'] as int?,
        ));
      case RouteConstants.feed:
        return _materialRoute(const FeedScreen());
      case RouteConstants.themeSettings:
        return _materialRoute(const ThemeSettingsScreen());
      case RouteConstants.userProfile:
        return _materialRoute(
          UserProfileScreen(
            userId: settings.arguments as String,
          ),
        );
      // Chat routes
      case RouteConstants.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _materialRoute(
          ChatScreen(
            chatId: args?['chatId'] as String?,
            receiverId: args?['receiverId'] as String?,
            isGroup: args?['isGroup'] as bool? ?? false,
          ),
        );
      case RouteConstants.chatList:
        return _materialRoute(const ChatListScreen());
      case RouteConstants.newChat:
        return _materialRoute(const FriendsScreen());
      case RouteConstants.createGroup:
        return _materialRoute(const CreateGroupScreen());
      // Notification routes
      case RouteConstants.notifications:
        return _materialRoute(const NotificationScreen());
      case RouteConstants.chatInfo:
        if (settings.arguments is String) {
          return _materialRoute(
            ChatInfoScreen(
              chatId: settings.arguments as String,
            ),
          );
        } else if (settings.arguments is Chatroom) {
          final chat = settings.arguments as Chatroom;
          return _materialRoute(
            ChatInfoScreen(
              chatId: chat.id,
            ),
          );
        }
        return _materialRoute(
          const SplashScreen(),
        );

      default:
        return _materialRoute(const SplashScreen());
    }
  }

  static Route _materialRoute(Widget view) => MaterialPageRoute(
        builder: (_) => view,
      );

  Routes._();
}
