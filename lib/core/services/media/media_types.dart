/// Enum định nghĩa các loại media được hỗ trợ trong ứng dụng
enum MediaType {
  /// Ảnh - các định dạng như JPG, PNG, GIF, WebP, v.v.
  image,

  /// Video - các định dạng như MP4, MOV, AVI, v.v.
  video,

  /// Âm thanh - các định dạng như MP3, WAV, AAC, v.v.
  audio,

  /// File thông thường - các loại file khác không thuộc các loại trên
  file,
}

/// Enum định nghĩa các nguồn để chọn media
enum MediaSource {
  /// Camera của thiết bị
  camera,

  /// Thư viện media của thiết bị
  gallery,
}

/// Class kết quả chọn media có thể chứa nhiều file và thông tin chi tiết
class MediaPickResult {
  /// Danh sách các file đã chọn
  final List<dynamic> files;

  /// Loại media đã chọn
  final MediaType type;

  /// Nguồn của media (camera, gallery)
  final MediaSource source;

  /// Lỗi nếu có
  final String? error;

  /// Constructor
  MediaPickResult({
    required this.files,
    required this.type,
    required this.source,
    this.error,
  });

  /// Kiểm tra xem kết quả có thành công không
  bool get isSuccess => error == null && files.isNotEmpty;

  /// Kiểm tra xem có lỗi không
  bool get hasError => error != null;

  /// Tạo kết quả lỗi
  factory MediaPickResult.error(String errorMessage) {
    return MediaPickResult(
      files: [],
      type: MediaType.image,
      source: MediaSource.gallery,
      error: errorMessage,
    );
  }
}
