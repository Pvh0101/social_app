import '../../../core/utils/datetime_helper.dart';
import 'package:social_app/core/enums/message_type.dart';
import 'package:logger/logger.dart';

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

  /// Thời điểm phòng chat được cập nhật lần cuối
  final DateTime updatedAt;

  /// ID của người tạo phòng chat
  final String createdBy;

  /// Thời điểm phòng chat được tạo
  final DateTime createdAt;

  static final logger = Logger();

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
    required this.updatedAt,
    required this.createdBy,
    required this.createdAt,
  }) {
    logger.d(
        'Đã tạo phòng chat: ID=$id, Tên=$name, Nhóm=$isGroup, Công khai=$isPublic');
  }

  /// Kiểm tra xem một người dùng có phải là admin của phòng chat không
  ///
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu người dùng là admin
  bool isAdmin(String userId) {
    final result = admins.contains(userId);
    logger.d('Kiểm tra admin: userId=$userId, kết quả=$result');
    return result;
  }

  /// Kiểm tra xem một người dùng có phải là thành viên của phòng chat không
  ///
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu người dùng là thành viên
  bool isMember(String userId) {
    final result = members.contains(userId);
    logger.d('Kiểm tra thành viên: userId=$userId, kết quả=$result');
    return result;
  }

  /// Kiểm tra xem một người dùng có thể tham gia phòng chat không
  ///
  /// [userId] là ID của người dùng cần kiểm tra
  /// Trả về true nếu phòng chat là công khai hoặc người dùng là admin
  bool canJoin(String userId) {
    final result = isPublic || isAdmin(userId);
    logger.d('Kiểm tra quyền tham gia: userId=$userId, kết quả=$result');
    return result;
  }

  /// Lấy ID của người dùng khác trong chat 1-1
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về ID của người dùng còn lại trong chat 1-1
  /// Trả về chuỗi rỗng nếu là chat nhóm hoặc không tìm thấy người dùng khác
  String getOtherUserId(String currentUserId) {
    logger.i('===== BẮT ĐẦU LẤY ID NGƯỜI DÙNG KHÁC =====');
    logger.i('getOtherUserId được gọi với currentUserId: $currentUserId');
    logger.i('isGroup: $isGroup, members: $members');

    if (isGroup) {
      logger.i('Đây là nhóm chat, trả về chuỗi rỗng');
      return '';
    }

    final otherUserId = members.firstWhere(
      (id) => id != currentUserId,
      orElse: () {
        logger.i('Không tìm thấy người dùng khác trong danh sách thành viên');
        return '';
      },
    );

    logger.i('Đã tìm thấy ID người dùng khác: $otherUserId');
    logger.i('===== KẾT THÚC LẤY ID NGƯỜI DÙNG KHÁC =====');
    return otherUserId;
  }

  /// Lấy tên hiển thị của phòng chat
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về tên của phòng chat (đối với chat nhóm) hoặc tên người dùng (đối với chat 1-1)
  String getDisplayName(String currentUserId) {
    final displayName = isGroup ? name ?? 'Nhóm chat' : name ?? 'Người dùng';
    logger.d(
        'Lấy tên hiển thị cho người dùng: $currentUserId, kết quả: $displayName');
    return displayName;
  }

  /// Lấy URL ảnh đại diện của phòng chat
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về URL ảnh đại diện của phòng chat hoặc người dùng
  String? getDisplayAvatar(String currentUserId) {
    logger.d(
        'Lấy avatar hiển thị cho người dùng: $currentUserId, kết quả: $avatar');
    if (isGroup) return avatar;
    return avatar;
  }

  /// Lấy nội dung hiển thị của tin nhắn cuối cùng
  ///
  /// [currentUserId] là ID của người dùng hiện tại
  /// Trả về nội dung tin nhắn cuối cùng, có thêm tiền tố "Bạn: " nếu người gửi là người dùng hiện tại
  String getDisplayLastMessage(String currentUserId) {
    logger
        .d('Lấy tin nhắn cuối cùng để hiển thị cho người dùng: $currentUserId');

    if (lastMessage == null) {
      logger.d('Chưa có tin nhắn, trả về mặc định');
      return 'Chưa có tin nhắn';
    }

    // Nếu người gửi tin nhắn cuối cùng là người dùng hiện tại
    if (lastMessageSenderId == currentUserId) {
      logger.d(
          'Người gửi tin nhắn cuối cùng là người dùng hiện tại, thêm tiền tố "Bạn: "');
      return 'Bạn: $lastMessage';
    }

    logger.d('Trả về tin nhắn cuối cùng nguyên bản: $lastMessage');
    return lastMessage!;
  }

  /// Lấy thời gian cập nhật phòng chat dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get updatedAtText {
    final text = DateTimeHelper.getRelativeTime(updatedAt);
    logger.d('Lấy thời gian cập nhật dạng văn bản: $text');
    return text;
  }

  /// Tạo đối tượng Chatroom từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
  factory Chatroom.fromMap(Map<String, dynamic> map) {
    logger.i('===== BẮT ĐẦU TẠO CHATROOM TỪ MAP =====');
    logger.i(
        'Dữ liệu đầu vào: id=${map['id']}, name=${map['name']}, isGroup=${map['isGroup']}');

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
        updatedAt: DateTimeHelper.fromMap(map['updatedAt']) ?? DateTime.now(),
        createdBy: map['createdBy'] ?? '',
        createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
      );

      logger.i('Đã tạo thành công chatroom với ID: ${chatroom.id}');
      logger.i(
          'Số lượng thành viên: ${chatroom.members.length}, Số lượng admin: ${chatroom.admins.length}');
      logger.i('===== KẾT THÚC TẠO CHATROOM TỪ MAP =====');
      return chatroom;
    } catch (e) {
      logger.e('Lỗi khi tạo Chatroom từ Map: $e');
      logger.i('===== KẾT THÚC TẠO CHATROOM TỪ MAP - LỖI =====');
      rethrow;
    }
  }

  /// Chuyển đổi đối tượng Chatroom thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
  Map<String, dynamic> toMap() {
    logger.d('Chuyển đổi chatroom thành Map: id=$id');
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
    DateTime? updatedAt,
    String? createdBy,
    DateTime? createdAt,
  }) {
    logger.d('Tạo bản sao của chatroom: id=$id');
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
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
