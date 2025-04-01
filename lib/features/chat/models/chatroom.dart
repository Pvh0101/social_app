import '../../../core/utils/datetime_helper.dart';
import 'package:social_app/core/enums/message_type.dart';

/// Model đại diện cho phòng chat trong ứng dụng mạng xã hội.
///
/// [Chatroom] lưu trữ tất cả thông tin liên quan đến một phòng chat bao gồm
/// thông tin cơ bản, danh sách thành viên, quyền hạn, và tin nhắn cuối cùng.
/// Model này hỗ trợ cả chat 1-1 và chat nhóm.
class Chatroom {
  /// ID duy nhất của phòng chat
  final String id;

  /// Tên của phòng chat (đối với chat nhóm) hoặc tên người dùng (đối với chat 1-1)
  final String? name;

  /// URL ảnh đại diện của phòng chat hoặc người dùng
  final String? avatar;

  /// Xác định đây là chat nhóm (true) hay chat 1-1 (false)
  final bool isGroup;

  /// Xác định phòng chat là công khai (true) hay riêng tư (false)
  /// Nếu công khai, bất kỳ ai cũng có thể tham gia
  /// Nếu riêng tư, chỉ admin mới có thể thêm thành viên
  final bool isPublic;

  /// Danh sách ID của các thành viên trong phòng chat
  final List<String> members;

  /// Danh sách ID của các admin trong phòng chat
  final List<String> admins;

  /// ID của tin nhắn cuối cùng trong phòng chat
  final String? lastMessageId;

  /// Nội dung của tin nhắn cuối cùng
  final String? lastMessage;

  /// Loại của tin nhắn cuối cùng (văn bản/hình ảnh/video/...)
  final MessageType? lastMessageType;

  /// ID của người gửi tin nhắn cuối cùng
  final String? lastMessageSenderId;

  /// Tên của người gửi tin nhắn cuối cùng
  final String? lastMessageSenderName;

  /// Thời điểm phòng chat được cập nhật lần cuối
  final DateTime updatedAt;

  /// ID của người tạo phòng chat
  final String createdBy;

  /// Thời điểm phòng chat được tạo
  final DateTime createdAt;

  /// Constructor tạo đối tượng Chatroom với các tham số bắt buộc và tùy chọn
  Chatroom({
    required this.id,
    this.name,
    this.avatar,
    required this.isGroup,
    required this.isPublic,
    required this.members,
    required this.admins,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
    required this.updatedAt,
    required this.createdBy,
    required this.createdAt,
  });

  /// Kiểm tra xem một người dùng có phải là admin của phòng chat không
  ///
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu người dùng là admin
  bool isAdmin(String userId) {
    return admins.contains(userId);
  }

  /// Kiểm tra xem một người dùng có phải là thành viên của phòng chat không
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu người dùng là thành viên
  bool isMember(String userId) {
    return members.contains(userId);
  }

  /// Kiểm tra xem một người dùng có thể tham gia phòng chat không
  ///
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu phòng chat là công khai hoặc người dùng là admin
  bool canJoin(String userId) {
    return isPublic || isAdmin(userId);
  }

  /// Lấy ID của người dùng khác trong chat 1-1
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về ID của người dùng còn lại trong chat 1-1
  /// Trả về chuỗi rỗng nếu là chat nhóm hoặc không tìm thấy người dùng khác
  String getOtherUserId(String currentUserId) {
    if (isGroup) {
      return '';
    }

    final otherUserId = members.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    return otherUserId;
  }

  /// Lấy tên hiển thị của phòng chat
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về tên của phòng chat (đối với chat nhóm) hoặc tên người dùng (đối với chat 1-1)
  String getDisplayName(String currentUserId) {
    return isGroup ? name ?? 'Nhóm chat' : name ?? 'Người dùng';
  }

  /// Lấy URL ảnh đại diện của phòng chat
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về URL ảnh đại diện của phòng chat hoặc người dùng
  String? getDisplayAvatar(String currentUserId) {
    if (isGroup) return avatar;
    return avatar;
  }

  /// Lấy nội dung hiển thị của tin nhắn cuối cùng
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về nội dung tin nhắn cuối cùng
  /// - Nếu người gửi là người dùng hiện tại, thêm tiền tố "Bạn: "
  /// - Nếu là nhóm chat và người gửi không phải người dùng hiện tại, hiển thị "Tên người gửi: nội dung"
  /// - Nếu là chat 1-1, chỉ hiển thị nội dung tin nhắn
  String getDisplayLastMessage(String currentUserId) {
    if (lastMessage == null) {
      return 'Chưa có tin nhắn';
    }

    // Nếu người gửi tin nhắn cuối cùng là người dùng hiện tại
    if (lastMessageSenderId == currentUserId) {
      return 'Bạn: $lastMessage';
    }

    // Nếu là nhóm chat và có thông tin người gửi, hiển thị tên người gửi
    if (isGroup && lastMessageSenderName != null) {
      return '$lastMessageSenderName: $lastMessage';
    }

    // Trường hợp còn lại (chat 1-1 hoặc không có thông tin người gửi)
    return lastMessage!;
  }

  /// Lấy thời gian cập nhật phòng chat dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get updatedAtText {
    return DateTimeHelper.getRelativeTime(updatedAt);
  }

  /// Tạo đối tượng Chatroom từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
  factory Chatroom.fromMap(Map<String, dynamic> map) {
    try {
      final chatroom = Chatroom(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        avatar: map['avatar'],
        isGroup: map['isGroup'] ?? false,
        isPublic: map['isPublic'] ?? false,
        members: List<String>.from(map['members'] ?? []),
        admins: List<String>.from(map['admins'] ?? []),
        lastMessageId: map['lastMessageId'],
        lastMessage: map['lastMessage'],
        lastMessageType: map['lastMessageType'] != null
            ? MessageType.fromString(map['lastMessageType'])
            : null,
        lastMessageSenderId: map['lastMessageSenderId'],
        lastMessageSenderName: map['lastMessageSenderName'],
        updatedAt: DateTimeHelper.fromMap(map['updatedAt']) ?? DateTime.now(),
        createdBy: map['createdBy'] ?? '',
        createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
      );

      return chatroom;
    } catch (e) {
      rethrow;
    }
  }

  /// Chuyển đổi đối tượng Chatroom thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isGroup': isGroup,
      'isPublic': isPublic,
      'members': members,
      'admins': admins,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType?.name,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageSenderName': lastMessageSenderName,
      'updatedAt': DateTimeHelper.toMap(updatedAt),
      'createdBy': createdBy,
      'createdAt': DateTimeHelper.toMap(createdAt),
    };
  }

  /// Tạo bản sao của đối tượng Chatroom với một số thuộc tính được thay đổi
  ///
  /// Phương thức này giúp tạo đối tượng mới mà không thay đổi đối tượng gốc (immutability)
  Chatroom copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isGroup,
    bool? isPublic,
    List<String>? members,
    List<String>? admins,
    String? lastMessageId,
    String? lastMessage,
    MessageType? lastMessageType,
    String? lastMessageSenderId,
    String? lastMessageSenderName,
    DateTime? updatedAt,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Chatroom(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isGroup: isGroup ?? this.isGroup,
      isPublic: isPublic ?? this.isPublic,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSenderName:
          lastMessageSenderName ?? this.lastMessageSenderName,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
