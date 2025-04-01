enum NotificationType {
  like('like'),
  comment('comment'),
  mention('mention'),
  friendRequest('friend_request'),
  friendAccept('friend_accept'),
  message('message');

  final String value;
  const NotificationType(this.value);

  /// Chuyển đổi từ String sang NotificationType
  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (element) => element.value == value,
      orElse: () => NotificationType.message,
    );
  }

  /// Chuyển đổi từ Map sang NotificationType
  factory NotificationType.fromMap(Map<String, dynamic> map) {
    return fromString(map['type'] as String?);
  }

  /// Chuyển đổi sang Map
  Map<String, dynamic> toMap() {
    return {
      'type': value,
    };
  }

  /// Lấy message mẫu cho từng loại thông báo
  String getTemplateMessage(String senderName) {
    switch (this) {
      case NotificationType.like:
        return '$senderName đã thích bài viết của bạn';
      case NotificationType.comment:
        return '$senderName đã bình luận về bài viết của bạn';
      case NotificationType.mention:
        return '$senderName đã nhắc đến bạn trong một bài viết';
      case NotificationType.friendRequest:
        return '$senderName đã gửi lời mời kết bạn';
      case NotificationType.friendAccept:
        return '$senderName đã chấp nhận lời mời kết bạn của bạn';
      case NotificationType.message:
        return '$senderName đã gửi tin nhắn cho bạn';
    }
  }

  /// Lấy message mẫu cho từng loại thông báo
  String getTemplateMessageText() {
    switch (this) {
      case NotificationType.like:
        return 'đã thích bài viết của bạn';
      case NotificationType.comment:
        return 'đã bình luận về bài viết của bạn';
      case NotificationType.mention:
        return 'đã nhắc đến bạn trong một bài viết';
      case NotificationType.friendRequest:
        return 'đã gửi lời mời kết bạn';
      case NotificationType.friendAccept:
        return 'đã chấp nhận lời mời kết bạn của bạn';
      case NotificationType.message:
        return 'đã gửi tin nhắn cho bạn';
    }
  }
}
