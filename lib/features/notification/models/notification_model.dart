import '../../../core/utils/datetime_helper.dart';
import '../../../core/enums/notification_type.dart';
import 'package:intl/intl.dart';

/// **Mô hình Thông báo (NotificationModel)**
///
/// Đây là mô hình dùng để quản lý thông báo trong ứng dụng.
/// Bao gồm các loại thông báo như: tin nhắn, tương tác bài viết, lời mời kết bạn, v.v.
class NotificationModel {
  /// **ID của thông báo** (duy nhất)
  final String id;

  /// **ID của người gửi thông báo**
  final String senderId;

  /// **ID của người nhận thông báo**
  final String receiverId;

  /// **Nội dung của thông báo** (Ví dụ: "Người A đã thích bài viết của bạn")
  final String content;

  /// **Loại thông báo**, có thể là một trong các loại sau:
  /// - `"message"`: Tin nhắn
  /// - `"like"`: Lượt thích bài viết
  /// - `"comment"`: Bình luận bài viết
  /// - `"mention"`: Được gắn thẻ trong bài viết/bình luận
  /// - `"friend_request"`: Lời mời kết bạn
  /// - `"friend_accept"`: Chấp nhận lời mời kết bạn
  final NotificationType type;

  /// **ID bài viết (nếu có)**
  /// - Dùng khi thông báo liên quan đến bài viết (like/comment).
  final String? postId;

  /// **ID bình luận (nếu có)**
  /// - Dùng khi thông báo liên quan đến bình luận.
  final String? commentId;

  /// **ID cuộc trò chuyện (nếu có)**
  /// - Dùng khi thông báo liên quan đến tin nhắn.
  final String? chatId;

  /// **Trạng thái đã đọc thông báo hay chưa**
  /// - `true`: Đã đọc
  /// - `false`: Chưa đọc
  final bool isRead;

  /// **Thời gian tạo thông báo**
  final DateTime createdAt;

  /// **Tên người gửi thông báo**
  final String? senderName;

  /// **URL ảnh đại diện của người gửi thông báo**
  final String? senderAvatar;

  /// **Khởi tạo đối tượng NotificationModel**
  const NotificationModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.postId,
    this.commentId,
    this.chatId,
    this.senderName,
    this.senderAvatar,
  });

  /// **Chuyển đổi từ Firestore (Map) sang NotificationModel**
  ///
  /// Dữ liệu được lấy từ Firestore có dạng `Map<String, dynamic>`,
  /// sau đó được chuyển đổi thành một đối tượng `NotificationModel`.
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    try {
      return NotificationModel(
        id: map['id'] ?? '',
        senderId: map['senderId'] ?? '',
        receiverId: map['receiverId'] ?? '',
        type: NotificationType.fromMap(map),
        content: map['content'] ?? '',
        createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
        isRead: map['isRead'] ?? false,
        postId: map['postId'],
        commentId: map['commentId'],
        chatId: map['chatId'],
        senderName: map['senderName'],
        senderAvatar: map['senderAvatar'],
      );
    } catch (e) {
      // Trả về một notification mặc định nếu có lỗi
      return NotificationModel(
        id: '',
        senderId: '',
        receiverId: '',
        type: NotificationType.message,
        content: '',
        createdAt: DateTime.now(),
      );
    }
  }

  /// **Chuyển đổi từ NotificationModel sang Firestore (Map)**
  ///
  /// Dữ liệu sẽ được lưu trữ trong Firestore dưới dạng `Map<String, dynamic>`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.value,
      'content': content,
      'createdAt': DateTimeHelper.toMap(createdAt),
      'isRead': isRead,
      'postId': postId,
      'commentId': commentId,
      'chatId': chatId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
    };
  }

  /// Lấy thời gian tạo thông báo dưới dạng relative time
  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);

  /// Copy with
  NotificationModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    NotificationType? type,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? postId,
    String? commentId,
    String? chatId,
    String? senderName,
    String? senderAvatar,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      chatId: chatId ?? this.chatId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}
