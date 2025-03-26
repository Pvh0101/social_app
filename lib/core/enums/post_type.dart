/// Enum định nghĩa các loại bài đăng trong ứng dụng
enum PostType {
  /// Bài đăng chỉ chứa văn bản
  text,

  /// Bài đăng có hình ảnh
  image,

  /// Bài đăng có video
  video,
}

/// Extension để thêm các phương thức tiện ích cho PostType
extension PostTypeExtension on PostType {
  /// Chuyển đổi PostType thành String để lưu vào database
  String get value {
    switch (this) {
      case PostType.text:
        return 'text';
      case PostType.image:
        return 'image';
      case PostType.video:
        return 'video';
    }
  }

  /// Chuyển đổi từ String sang PostType
  /// Mặc định trả về PostType.text nếu giá trị không hợp lệ
  static PostType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return PostType.text;
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      default:
        return PostType.text;
    }
  }

  /// Kiểm tra xem bài đăng có phải dạng media không
  bool get isMedia => this == PostType.image || this == PostType.video;

  /// Kiểm tra xem bài đăng có cần thumbnail không
  bool get needsThumbnail => this == PostType.video;
}
