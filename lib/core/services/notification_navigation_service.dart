import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/routes_constants.dart';
import '../enums/notification_type.dart';
import '../../features/posts/screens/post_detail_screen.dart';
import '../../features/notification/providers/notification_provider.dart';

/// Service xử lý chuyển hướng khi nhấn vào thông báo
class NotificationNavigationService {
  /// Xử lý chuyển hướng khi nhấn vào thông báo
  static void handleNotificationNavigation(
    BuildContext context,
    NotificationType type, {
    String? postId,
    String? chatId,
    String? senderId,
    int? initialTabIndex,
    String? notificationId,
    WidgetRef? ref,
  }) {
    // Đánh dấu thông báo đã đọc nếu có notificationId và ref
    if (notificationId != null && ref != null) {
      final repository = ref.read(notificationRepositoryProvider);
      repository.markAsRead(notificationId).catchError((error) {
        debugPrint('Error marking notification as read: $error');
      });
    }

    // Chuyển hướng dựa trên loại thông báo
    switch (type) {
      case NotificationType.like:
        if (postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: postId,
                focusComment: false,
              ),
            ),
          );
        }
        break;
      case NotificationType.comment:
      case NotificationType.mention:
        if (postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: postId,
                focusComment:
                    true, // Focus vào ô comment khi đến từ thông báo bình luận
              ),
            ),
          );
        }
        break;
      case NotificationType.message:
        if (chatId != null) {
          Navigator.pushNamed(
            context,
            RouteConstants.chat,
            arguments: {
              'chatId': chatId,
              'isGroup': false,
            },
          );
        }
        break;
      case NotificationType.friendRequest:
        Navigator.pushNamed(
          context,
          RouteConstants.friends,
          arguments: {'initialTabIndex': initialTabIndex ?? 1}, // Tab requests
        );
        break;
      case NotificationType.friendAccept:
        if (senderId != null) {
          Navigator.pushNamed(
            context,
            RouteConstants.userProfile,
            arguments: senderId,
          );
        }
        break;
    }
  }
}
