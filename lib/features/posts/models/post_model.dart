import '../../../core/enums/post_type.dart';
import '../../../core/utils/datetime_helper.dart';

/// Model đại diện cho bài đăng trong ứng dụng mạng xã hội.
///
/// [PostModel] lưu trữ tất cả thông tin liên quan đến một bài đăng bao gồm
/// nội dung, hình ảnh/video, thông tin người đăng, và các số liệu tương tác.
/// Model này được sử dụng để hiển thị bài đăng trên bảng tin và trang cá nhân.
class PostModel {
  /// ID duy nhất của bài viết
  final String postId;

  /// ID của người đăng bài viết
  final String userId;

  /// Nội dung văn bản của bài viết
  final String content;

  /// Danh sách URL của các file đính kèm (hình ảnh hoặc video)
  final List<String>? fileUrls;

  /// URL của ảnh đại diện nếu bài viết chứa video
  final String? thumbnailUrl;

  /// Loại bài đăng (văn bản/hình ảnh/video)
  final PostType postType;

  /// Thời điểm bài viết được tạo
  final DateTime createdAt;

  /// Thời điểm bài viết được cập nhật lần cuối
  final DateTime? updatedAt;

  /// Số lượt thích bài viết
  final int likeCount;

  /// Số lượng bình luận trên bài viết
  final int commentCount;

  /// Constructor tạo đối tượng PostModel với các tham số bắt buộc và tùy chọn
  const PostModel({
    required this.postId,
    required this.userId,
    required this.content,
    this.fileUrls,
    this.thumbnailUrl,
    required this.postType,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  /// Tạo đối tượng PostModel từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
  factory PostModel.fromMap(Map<String, dynamic> map) {
    try {
      final post = PostModel(
        postId: map['postId'] as String,
        userId: map['userId'] as String,
        content: map['content'] as String,
        fileUrls: (map['fileUrls'] as List?)?.map((e) => e as String).toList(),
        thumbnailUrl: map['thumbnailUrl'] as String?,
        postType: PostTypeExtension.fromString(map['postType'] as String),
        createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
        updatedAt: DateTimeHelper.fromMap(map['updatedAt']),
        likeCount: map['likeCount'] as int? ?? 0,
        commentCount: map['commentCount'] as int? ?? 0,
      );
      return post;
    } catch (e) {
      rethrow;
    }
  }

  /// Chuyển đổi đối tượng PostModel thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'content': content,
      'fileUrls': fileUrls,
      'thumbnailUrl': thumbnailUrl,
      'postType': postType.value,
      'createdAt': DateTimeHelper.toMap(createdAt),
      'updatedAt': DateTimeHelper.toMap(updatedAt),
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }

  /// Lấy thời gian tạo bài viết dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);

  /// Lấy thời gian cập nhật bài viết dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get updatedAtText => DateTimeHelper.getRelativeTime(updatedAt);
}
