import '../../../core/utils/datetime_helper.dart';

/// Model đại diện cho bình luận trong ứng dụng mạng xã hội.
///
/// [CommentModel] lưu trữ thông tin về bình luận của người dùng đối với bài viết,
/// bao gồm nội dung bình luận, thông tin người bình luận, và các tương tác liên quan.
/// Model này hỗ trợ cả bình luận thông thường và trả lời bình luận (reply).
class CommentModel {
  /// ID duy nhất của bình luận
  final String commentId;

  /// ID của bài viết được bình luận
  final String postId;

  /// ID của người dùng đã bình luận
  final String userId;

  /// Nội dung văn bản của bình luận
  final String content;

  /// Số lượng lượt thích mà bình luận nhận được
  final int likeCount;

  /// Thời điểm bình luận được tạo
  final DateTime createdAt;

  /// ID của bình luận cha (nếu đây là một trả lời cho bình luận khác)
  /// Giá trị null nếu đây là bình luận gốc
  final String? parentId;

  /// Constructor tạo đối tượng CommentModel với các tham số bắt buộc và tùy chọn
  const CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.content,
    this.likeCount = 0,
    required this.createdAt,
    this.parentId,
  });

  /// Tạo đối tượng CommentModel từ Map dữ liệu
  ///
  /// Thường được sử dụng khi lấy dữ liệu từ Firestore
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] ?? map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      likeCount: map['likeCount'] ?? 0,
      createdAt: DateTimeHelper.fromMap(map['createdAt']) ?? DateTime.now(),
      parentId: map['parentId'],
    );
  }

  /// Chuyển đổi đối tượng CommentModel thành Map dữ liệu
  ///
  /// Thường được sử dụng khi lưu dữ liệu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'content': content,
      'likeCount': likeCount,
      'createdAt': DateTimeHelper.toMap(createdAt),
      'parentId': parentId,
    };
  }

  /// Lấy thời gian tạo bình luận dưới dạng văn bản tương đối
  ///
  /// Ví dụ: "5 phút trước", "2 giờ trước", "Hôm qua", v.v.
  String get createdAtText => DateTimeHelper.getRelativeTime(createdAt);

  /// Tạo bản sao của đối tượng CommentModel với một số thuộc tính được thay đổi
  ///
  /// Phương thức này giúp tạo đối tượng mới mà không thay đổi đối tượng gốc (immutability)
  CommentModel copyWith({
    String? commentId,
    String? postId,
    String? userId,
    String? content,
    int? likeCount,
    DateTime? createdAt,
    String? parentId,
  }) {
    return CommentModel(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
    );
  }
}
