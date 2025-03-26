import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;
import 'media_types.dart';
import '../../../core/utils/log_utils.dart';

/// Status của quá trình tải lên
enum UploadStatus {
  /// Đang chuẩn bị tải lên
  preparing,

  /// Đang tải lên
  uploading,

  /// Tải lên thành công
  success,

  /// Tải lên thất bại
  failed,

  /// Đang tạm dừng tải lên
  paused,

  /// Đã hủy tải lên
  canceled,
}

/// Kết quả tải lên media
class UploadResult {
  /// URL của file đã tải lên
  final String? downloadUrl;

  /// Đường dẫn đến file trong Firebase Storage
  final String? storagePath;

  /// Trạng thái tải lên
  final UploadStatus status;

  /// Lỗi nếu có
  final String? error;

  /// Constructor
  UploadResult({
    this.downloadUrl,
    this.storagePath,
    required this.status,
    this.error,
  });

  /// Kiểm tra xem kết quả có thành công không
  bool get isSuccess =>
      status == UploadStatus.success && downloadUrl != null && error == null;

  /// Tạo kết quả lỗi
  factory UploadResult.error(String errorMessage) {
    return UploadResult(
      status: UploadStatus.failed,
      error: errorMessage,
    );
  }

  /// Tạo kết quả thành công
  factory UploadResult.success(String url, String path) {
    return UploadResult(
      downloadUrl: url,
      storagePath: path,
      status: UploadStatus.success,
    );
  }
}

/// Service quản lý việc tải lên media lên Firebase Storage
class MediaUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  static final MediaUploadService _instance = MediaUploadService._internal();
  factory MediaUploadService() => _instance;
  MediaUploadService._internal() {
    logInfo(
        LogService.MEDIA, '[MEDIA_UPLOAD] MediaUploadService được khởi tạo');
  }

  /// Tải lên một file duy nhất lên Firebase Storage
  Future<UploadResult> uploadSingleFile({
    required File file,
    required String path,
    Function(double)? onProgress,
    bool autoRetry = true,
    int maxRetries = 3,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_UPLOAD] Bắt đầu tải file: ${file.path} đến $path');
    try {
      // Kiểm tra kết nối mạng
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        logError(LogService.MEDIA, '[MEDIA_UPLOAD] Không có kết nối mạng', null,
            StackTrace.current);
        return UploadResult.error('Không có kết nối mạng');
      }

      // Tạo reference
      final Reference ref = _storage.ref().child(path);
      logDebug(LogService.MEDIA, '[MEDIA_UPLOAD] Đã tạo reference: $path');

      // Tạo upload task
      final UploadTask uploadTask = ref.putFile(file);

      // Theo dõi tiến trình
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);

          if (progress > 0 && progress % 0.25 < 0.01) {
            // Log tại các mốc 25%, 50%, 75%, 100%
            logDebug(LogService.MEDIA,
                '[MEDIA_UPLOAD] Tiến trình tải lên: ${(progress * 100).toStringAsFixed(0)}%');
          }
        });
      }

      // Chờ tải lên hoàn tất
      final TaskSnapshot taskSnapshot = await uploadTask;
      logDebug(LogService.MEDIA,
          '[MEDIA_UPLOAD] Đã tải lên ${taskSnapshot.bytesTransferred} bytes');

      // Lấy URL download
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      logInfo(LogService.MEDIA, '[MEDIA_UPLOAD] Tải lên thành công: $path');

      // Trả về kết quả
      return UploadResult.success(downloadUrl, path);
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_UPLOAD] Lỗi tải lên file: $e', e,
          stackTrace);
      return UploadResult.error(e.toString());
    }
  }

  /// Tải lên nhiều file cùng lúc
  Future<List<UploadResult>> uploadMultipleFiles({
    required List<File> files,
    required String basePath,
    Function(double)? onProgress,
    bool autoRetry = true,
    int maxRetries = 3,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_UPLOAD] Bắt đầu tải ${files.length} files đến $basePath');
    try {
      // Kiểm tra danh sách file
      if (files.isEmpty) {
        logWarning(LogService.MEDIA, '[MEDIA_UPLOAD] Danh sách file trống');
        return [UploadResult.error('Danh sách file trống')];
      }

      // Tạo danh sách các nhiệm vụ tải lên
      final List<Future<UploadResult>> uploadTasks = [];
      final int totalFiles = files.length;

      // Tạo các nhiệm vụ tải lên
      for (int i = 0; i < files.length; i++) {
        final File file = files[i];
        final String fileName = path.basename(file.path);
        final String uploadPath =
            '$basePath/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // Tạo callback tiến trình riêng cho từng file
        Function(double)? fileProgress;
        if (onProgress != null) {
          fileProgress = (progress) {
            // Tính toán tiến độ tổng thể
            final double overallProgress =
                i / totalFiles + (progress / totalFiles);
            onProgress(overallProgress);
          };
        }

        // Thêm nhiệm vụ tải lên vào danh sách
        uploadTasks.add(uploadSingleFile(
          file: file,
          path: uploadPath,
          onProgress: fileProgress,
          autoRetry: autoRetry,
          maxRetries: maxRetries,
        ));
      }

      // Thực hiện tất cả các nhiệm vụ tải lên
      final List<UploadResult> results = await Future.wait(uploadTasks);

      // Đếm số lượng tải lên thành công
      final int successCount =
          results.where((result) => result.isSuccess).length;
      logInfo(LogService.MEDIA,
          '[MEDIA_UPLOAD] Kết quả: Tải thành công $successCount/${files.length} files');

      return results;
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_UPLOAD] Lỗi khi tải nhiều files: $e',
          e, stackTrace);
      return [UploadResult.error(e.toString())];
    }
  }

  /// Xóa file từ Firebase Storage
  Future<bool> deleteFile(String storagePath) async {
    logInfo(LogService.MEDIA, '[MEDIA_UPLOAD] Bắt đầu xóa file: $storagePath');
    try {
      await _storage.ref().child(storagePath).delete();
      logInfo(LogService.MEDIA,
          '[MEDIA_UPLOAD] Đã xóa file thành công: $storagePath');
      return true;
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_UPLOAD] Lỗi khi xóa file: $e', e,
          stackTrace);
      return false;
    }
  }

  /// Kiểm tra xem file có tồn tại trong Firebase Storage không
  Future<bool> fileExists(String storagePath) async {
    logDebug(LogService.MEDIA,
        '[MEDIA_UPLOAD] Kiểm tra sự tồn tại của file: $storagePath');
    try {
      final ListResult result = await _storage.ref().child(storagePath).list();
      final bool exists = result != null;
      logDebug(LogService.MEDIA,
          '[MEDIA_UPLOAD] File $storagePath ${exists ? "tồn tại" : "không tồn tại"}');
      return exists;
    } catch (e, stackTrace) {
      logDebug(LogService.MEDIA,
          '[MEDIA_UPLOAD] File $storagePath không tồn tại (lỗi: $e)');
      return false;
    }
  }
}

// Provider cho MediaUploadService
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService();
});
