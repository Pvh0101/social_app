import 'package:social_app/core/enums/message_type.dart';

import '../../../core/utils/datetime_helper.dart';

/// Model đại diện cho tin nhắn trong ứng dụng mạng xã hội.
///
/// [Message] lưu trữ tất cả thông tin liên quan đến một tin nhắn bao gồm
/// nội dung, người gửi, thời gian gửi, và trạng thái đã xem.
/// Model này được sử dụng để hiển thị tin nhắn trong các cuộc trò chuyện.
class Message {
  /// ID duy nhất của tin nhắn
  final String id;

  /// ID của phòng chat chứa tin nhắn này
  final String chatId;

  /// ID của người gửi tin nhắn
  final String senderId;

  /// Tên hiển thị của người gửi
  final String? senderName;

  /// URL ảnh đại diện của người gửi
  final String? senderAvatar;

  /// Nội dung của tin nhắn
  final String content;

  /// Loại tin nhắn (văn bản/hình ảnh/video/file/...)
  final MessageType type;

  /// URL của media đính kèm (nếu có)
  final String? mediaUrl;

  /// Danh sách ID người dùng đã xem tin nhắn
  final Set<String> seenBy;

  /// Thời điểm tin nhắn được tạo
  final DateTime createdAt;

  /// Constructor tạo đối tượng Message với các tham số bắt buộc và tùy chọn
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.seenBy,
    required this.createdAt,
  });

  /// Kiểm tra xem tin nhắn đã được xem bởi người dùng cụ thể chưa
  ///
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu người dùng đã xem tin nhắn
  bool isSeenBy(String userId) => seenBy.contains(userId);

  /// Lấy nội dung hiển thị của tin nhắn
  ///
  /// Nếu là tin nhắn văn bản, trả về nội dung gốc
  /// Nếu là tin nhắn media, trả về thông báo phù hợp với loại media
  String getDisplayContent() {
    if (type == MessageType.text) {
      return content;
    }

    // Đối với các loại tin nhắn khác, hiển thị loại media
    return type.displayText;
  }

  /// Lấy thời gian tạo tin nhắn dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);

  /// Tạo đối tượng Message từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      type: MessageType.fromString(map['type'] ?? ''),
      mediaUrl: map['mediaUrl'],
      seenBy: Set<String>.from(map['seenBy'] ?? []),
      createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Chuyển đổi đối tượng Message thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'seenBy': seenBy.toList(),
      'createdAt': DateTimeHelper.toMap(createdAt),
    };
  }
}
