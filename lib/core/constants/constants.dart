import 'package:flutter/material.dart';
import '../config/app_config.dart';

// class FirebaseCollectionNames {
//   static const String users = 'users';
//   static const String posts = 'posts';
//   static const String comments = 'comments';
//   static const String stories = 'stories';
//   static const String chatrooms = 'chatrooms';
//   static const String messages = 'messages';

//   FirebaseCollectionNames._();
// }

// class FirebaseFieldNames {
//   static const String userStatus = 'user_status';
//   static const String fullName = 'full_name';
//   static const String birthDay = 'birth_day';
//   static const String gender = 'gender';
//   static const String email = 'email';
//   static const String password = 'password';
//   static const String friends = 'friends';
//   static const String sentRequests = 'sent_requests';
//   static const String receivedRequests = 'receivedRequests';
//   static const String uid = 'uid';
//   static const String datePublished = 'date_published';
//   static const String postId = 'post_id';
//   static const String posterId = 'poster_id';
//   static const String content = 'content';
//   static const String fileUrl = 'file_url';
//   static const String postType = 'post_type';
//   static const String likes = 'likes';
//   static const String profilePicUrl = 'profile_pic_url';
//   static const String createdAt = 'created_at';
//   static const String authorId = 'author_id';
//   static const String commentId = 'comment_id';
//   static const String text = 'text';
//   static const String isOnline = 'is_online';
//   static const String lastSeen = 'last_seen';
//   static const String decs = 'decs';
//   static const String address = 'address';
//   static const String phoneNumber = 'phone_number';
//   static const String token = 'token';

//   // story specific
//   static const String imageUrl = 'image_url';
//   static const String storyId = 'story_id';
//   static const String views = 'views';

//   // video related
//   static const String videoUrl = 'video_url';
//   static const String videoId = 'video_id';

//   // Chat Feature
//   static const members = 'members';
//   static const chatroomId = 'chatroom_id';
//   static const lastMessage = 'last_message';
//   static const lastMessageTs = 'last_message_ts';
//   static const message = 'message';
//   static const senderId = 'sender_id';
//   static const receiverId = 'receiver_id';
//   static const seen = 'seen';
//   static const timestamp = 'timestamp';
//   static const messageId = 'message_id';
//   static const messageType = 'message_type';

//   FirebaseFieldNames._();
// }

class Constants {
  // Additional user fields

  static const String verificationId = 'verificationId';

  static const String users = 'users';
  static const String userImages = 'userImages';
  static const String userModel = 'userModel';

  static const String contactName = 'contactName';
  static const String contactImage = 'contactImage';
  static const String groupId = 'groupId';

  static const String senderUID = 'senderUID';
  static const String senderName = 'senderName';
  static const String senderImage = 'senderImage';
  static const String contactUID = 'contactUID';
  static const String message = 'message';
  static const String messageType = 'messageType';
  static const String timeSent = 'timeSent';
  static const String messageId = 'messageId';
  static const String isSeen = 'isSeen';
  static const String repliedMessage = 'repliedMessage';
  static const String repliedTo = 'repliedTo';
  static const String repliedMessageType = 'repliedMessageType';
  static const String isMe = 'isMe';
  static const String reactions = 'reactions';
  static const String isSeenBy = 'isSeenBy';
  static const String deletedBy = 'deletedBy';

  static const String lastMessage = 'lastMessage';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  static const chatFiles = 'chatFiles';

  static const String private = 'private';
  static const String public = 'public';

  static const String creatorUID = 'creatorUID';
  static const String groupName = 'groupName';
  static const String groupDescription = 'groupDescription';
  static const String groupImage = 'groupImage';
  static const String isPrivate = 'isPrivate';
  static const String editSettings = 'editSettings';
  static const String approveMembers = 'approveMembers';
  static const String lockMessages = 'lockMessages';
  static const String requestToJoing = 'requestToJoing';
  static const String membersUIDs = 'membersUIDs';
  static const String adminsUIDs = 'adminsUIDs';
  static const String awaitingApprovalUIDs = 'awaitingApprovalUIDs';

  static const String groupImages = 'groupImages';
  static const String changeName = 'changeName';
  static const String changeDesc = 'changeDesc';
  //notifications
  static const String notificationType = 'notificationType';
  static const String groupChatNotification = 'groupChatNotification';
  static const String chatNotification = 'chatNotification';
  static const String messageNotification = 'messageNotification';
  static const String userNotification = 'userNotification';
  // Default padding for screens
  static const defaultPadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 10,
  );

  // Text Styles
  static TextStyle labelAndHintTextStyle(ColorScheme colorScheme) => TextStyle(
        color: colorScheme.secondary,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      );
}

// lib/core/constants/api_constants.dart
class ApiConstants {
  // Base URLs
  static const String baseUrl = AppConfig.apiBaseUrl;
  static const String apiVersion = 'v1';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String resetPassword = '/auth/reset-password';
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/update';
  static const String uploadImage = '/upload/image';

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String applicationJson = 'application/json';

  // Error Codes
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}

// lib/core/constants/asset_constants.dart
class AssetConstants {
  // Images
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String background = 'assets/images/background.png';

  // Icons
  static const String googleIcon = 'assets/icons/google.png';
  static const String facebookIcon = 'assets/icons/facebook.png';
  static const String appleIcon = 'assets/icons/apple.png';

  // Animations
  static const String loading = 'assets/animations/loading.json';
  static const String success = 'assets/animations/success.json';
  static const String error = 'assets/animations/error.json';
  static const String empty = 'assets/animations/empty.json';
  static const String social = 'assets/animations/social.json';
}

// lib/core/constants/storage_keys.dart
class StorageKeys {
  // Auth
  static const String token = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String savedEmail = 'saved_email';

  // User Data
  static const String userData = 'user_data';
  static const String userSettings = 'user_settings';
  static const String userPreferences = 'user_preferences';

  // App Settings
  static const String language = 'app_language';
  static const String theme = 'app_theme';
  static const String notifications = 'notifications_enabled';
  static const String firstLaunch = 'first_launch';
  static const String lastSync = 'last_sync';
}
