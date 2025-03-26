import '../../../core/enums/content_type.dart';
import '../../../core/utils/datetime_helper.dart';

/// Model đại diện cho lượt thích trong ứng dụng mạng xã hội.
///
/// [LikeModel] lưu trữ thông tin về lượt thích của người dùng đối với nội dung
/// như bài viết hoặc bình luận. Model này giúp theo dõi ai đã thích nội dung nào
/// và thời điểm thích.
class LikeModel {
  /// ID duy nhất của lượt thích
  final String likeId;

  /// ID của nội dung được thích (bài viết hoặc bình luận)
  final String contentId;

  /// Loại nội dung được thích (post hoặc comment)
  final ContentType contentType;

  /// ID của người dùng đã thích nội dung
  final String userId;

  /// Thời điểm lượt thích được tạo
  final DateTime createdAt;

  /// Constructor tạo đối tượng LikeModel với các tham số bắt buộc
  const LikeModel({
    required this.likeId,
    required this.contentId,
    required this.contentType,
    required this.userId,
    required this.createdAt,
  });

  /// Tạo đối tượng LikeModel từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
  factory LikeModel.fromMap(Map<String, dynamic> map) {
    return LikeModel(
      likeId: map['likeId'],
      contentId: map['contentId'],
      contentType: ContentType.fromString(map['contentType']),
      userId: map['userId'],
      createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Chuyển đổi đối tượng LikeModel thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'likeId': likeId,
      'contentId': contentId,
      'contentType': contentType.value,
      'userId': userId,
      'createdAt': DateTimeHelper.toMap(createdAt),
    };
  }

  /// Lấy thời gian tạo lượt thích dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);
}
