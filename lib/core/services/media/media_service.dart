import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/log_utils.dart';

import 'media_types.dart';
import 'media_upload_service.dart';
import 'media_processor_service.dart';
import '../../services/permission/permission_service.dart';

/// MediaService - Dịch vụ đơn giản để làm việc với media trong ứng dụng
///
/// Cung cấp các phương thức để:
/// - Chọn ảnh, video từ camera/gallery
/// - Ghi âm từ micro
/// - Tải lên và quản lý media
class MediaService {
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  // Khởi tạo các service
  final MediaUploadService _uploadService = MediaUploadService();
  final MediaProcessorService _processorService = MediaProcessorService();
  final PermissionService _permissionService = PermissionService();

  // Singleton pattern
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal() {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] MediaService được khởi tạo');
  }

  /// Kiểm tra và yêu cầu quyền
  Future<bool> _requestPermission(Permission permission) async {
    logDebug(LogService.MEDIA,
        '[MEDIA_SERVICE] Yêu cầu quyền: ${permission.toString()}');
    PermissionGroup group;
    switch (permission) {
      case Permission.camera:
        group = PermissionGroup.media;
        break;
      case Permission.storage:
        group = PermissionGroup.storage;
        break;
      case Permission.microphone:
        group = PermissionGroup.audio;
        break;
      default:
        group = PermissionGroup.storage;
    }

    final status = await _permissionService.requestPermission(group);
    final bool granted = status == AppPermissionStatus.granted;
    logDebug(LogService.MEDIA,
        '[MEDIA_SERVICE] Kết quả yêu cầu quyền ${permission.toString()}: ${granted ? "cấp phép" : "từ chối"}');
    return granted;
  }

  /// CHỌN MEDIA

  /// Chọn ảnh từ camera
  Future<File?> pickImageFromCamera({Function(String)? onError}) async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Bắt đầu chọn ảnh từ camera');
    try {
      if (!await _requestPermission(Permission.camera)) {
        logWarning(
            LogService.MEDIA, '[MEDIA_SERVICE] Không có quyền truy cập camera');
        if (onError != null) onError('Không có quyền truy cập camera');
        return null;
      }

      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Đã chụp ảnh: ${image.path}');
        return File(image.path);
      } else {
        logDebug(
            LogService.MEDIA, '[MEDIA_SERVICE] Người dùng đã hủy chụp ảnh');
        return null;
      }
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_SERVICE] Lỗi khi chụp ảnh: $e', e,
          stackTrace);
      if (onError != null) onError(e.toString());
      return null;
    }
  }

  /// Chọn ảnh từ thư viện
  Future<List<File>> pickImagesFromGallery({
    bool multiple = false,
    Function(String)? onError,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_SERVICE] Bắt đầu chọn ảnh từ thư viện (multiple: $multiple)');
    try {
      if (!await _requestPermission(Permission.storage)) {
        logWarning(LogService.MEDIA,
            '[MEDIA_SERVICE] Không có quyền truy cập thư viện');
        if (onError != null) onError('Không có quyền truy cập thư viện');
        return [];
      }

      if (multiple) {
        final images = await _picker.pickMultiImage();
        logInfo(LogService.MEDIA,
            '[MEDIA_SERVICE] Đã chọn ${images.length} ảnh từ thư viện');
        return images.map((image) => File(image.path)).toList();
      } else {
        final image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          logInfo(
              LogService.MEDIA, '[MEDIA_SERVICE] Đã chọn ảnh: ${image.path}');
          return [File(image.path)];
        } else {
          logDebug(
              LogService.MEDIA, '[MEDIA_SERVICE] Người dùng đã hủy chọn ảnh');
          return [];
        }
      }
    } catch (e, stackTrace) {
      logError(LogService.MEDIA,
          '[MEDIA_SERVICE] Lỗi khi chọn ảnh từ thư viện: $e', e, stackTrace);
      if (onError != null) onError(e.toString());
      return [];
    }
  }

  /// Chọn video từ thư viện
  Future<File?> pickVideoFromGallery({Function(String)? onError}) async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Bắt đầu chọn video từ thư viện');
    try {
      if (!await _requestPermission(Permission.storage)) {
        logWarning(LogService.MEDIA,
            '[MEDIA_SERVICE] Không có quyền truy cập thư viện');
        if (onError != null) onError('Không có quyền truy cập thư viện');
        return null;
      }

      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        logInfo(
            LogService.MEDIA, '[MEDIA_SERVICE] Đã chọn video: ${video.path}');
        return File(video.path);
      } else {
        logDebug(
            LogService.MEDIA, '[MEDIA_SERVICE] Người dùng đã hủy chọn video');
        return null;
      }
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_SERVICE] Lỗi khi chọn video: $e', e,
          stackTrace);
      if (onError != null) onError(e.toString());
      return null;
    }
  }

  /// GHI ÂM

  /// Bắt đầu ghi âm
  Future<bool> startAudioRecording({Function(String)? onError}) async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Bắt đầu ghi âm');
    try {
      if (_isRecording) {
        logDebug(LogService.MEDIA,
            '[MEDIA_SERVICE] Đã đang ghi âm, không cần bắt đầu lại');
        return true;
      }

      // Sử dụng PermissionService để yêu cầu quyền microphone
      final status =
          await _permissionService.requestPermission(PermissionGroup.audio);
      if (status != AppPermissionStatus.granted) {
        logWarning(
            LogService.MEDIA, '[MEDIA_SERVICE] Không có quyền truy cập micro');
        if (onError != null)
          onError(
              'Ứng dụng cần quyền truy cập micro để cho phép bạn ghi âm tin nhắn thoại.');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      logDebug(LogService.MEDIA,
          '[MEDIA_SERVICE] Đã tạo đường dẫn lưu file âm thanh: $path');

      await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path);

      _isRecording = true;
      logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Đã bắt đầu ghi âm: $path');
      return true;
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_SERVICE] Lỗi khi bắt đầu ghi âm: $e',
          e, stackTrace);
      if (onError != null) onError('Lỗi ghi âm: $e');
      return false;
    }
  }

  /// Dừng ghi âm và lấy file
  Future<File?> stopAudioRecording({Function(String)? onError}) async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Dừng ghi âm');
    try {
      if (!_isRecording) {
        logWarning(LogService.MEDIA,
            '[MEDIA_SERVICE] Không có phiên ghi âm đang hoạt động');
        if (onError != null) onError('Không có phiên ghi âm đang hoạt động');
        return null;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null) {
        logInfo(LogService.MEDIA,
            '[MEDIA_SERVICE] Đã dừng ghi âm và lưu file: $path');
        return File(path);
      } else {
        logWarning(
            LogService.MEDIA, '[MEDIA_SERVICE] Không thể lưu file ghi âm');
        return null;
      }
    } catch (e, stackTrace) {
      _isRecording = false;
      logError(LogService.MEDIA, '[MEDIA_SERVICE] Lỗi khi dừng ghi âm: $e', e,
          stackTrace);
      if (onError != null) onError('Lỗi dừng ghi âm: $e');
      return null;
    }
  }

  /// Hủy ghi âm
  Future<bool> cancelAudioRecording() async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Hủy ghi âm');
    if (!_isRecording) {
      logDebug(LogService.MEDIA,
          '[MEDIA_SERVICE] Không có phiên ghi âm đang hoạt động để hủy');
      return true;
    }

    await _audioRecorder.stop();
    _isRecording = false;
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Đã hủy ghi âm thành công');
    return true;
  }

  bool get isRecording => _isRecording;

  /// XỬ LÝ MEDIA

  /// Nén ảnh
  Future<File?> compressImage(
    File file, {
    Function(String)? onError,
  }) async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Nén ảnh: ${file.path}');
    final result = await _processorService.compressImage(
      file,
      onError: onError,
    );

    if (result != null) {
      logInfo(LogService.MEDIA,
          '[MEDIA_SERVICE] Nén ảnh thành công: ${result.path}');
    } else {
      logWarning(
          LogService.MEDIA, '[MEDIA_SERVICE] Không thể nén ảnh: ${file.path}');
    }

    return result;
  }

  /// Cắt ảnh
  Future<File?> cropImage(
    File file, {
    Function(String)? onError,
  }) async {
    logInfo(LogService.MEDIA, '[MEDIA_SERVICE] Cắt ảnh: ${file.path}');
    final result = await _processorService.cropImage(
      file,
      onError: onError,
    );

    if (result != null) {
      logInfo(LogService.MEDIA,
          '[MEDIA_SERVICE] Cắt ảnh thành công: ${result.path}');
    } else {
      logDebug(LogService.MEDIA,
          '[MEDIA_SERVICE] Không cắt ảnh (có thể người dùng đã hủy)');
    }

    return result;
  }

  /// Nén video
  Future<File?> compressVideo(
    File file, {
    VideoQuality quality = VideoQuality.DefaultQuality,
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_SERVICE] Nén video: ${file.path}, chất lượng: $quality');

    // Tạo wrapper cho onProgress để có thể log
    Function(double)? progressWrapper;
    if (onProgress != null) {
      progressWrapper = (double progress) {
        onProgress(progress);
        if (progress > 0 && progress % 0.25 < 0.01) {
          // Log tại các mốc 25%, 50%, 75%, 100%
          logDebug(LogService.MEDIA,
              '[MEDIA_SERVICE] Tiến trình nén video: ${(progress * 100).toStringAsFixed(0)}%');
        }
      };
    }

    final result = await _processorService.compressVideo(
      file,
      onProgress: progressWrapper,
      onError: onError,
    );

    if (result != null) {
      logInfo(LogService.MEDIA,
          '[MEDIA_SERVICE] Nén video thành công: ${result.path}');
    } else {
      logWarning(LogService.MEDIA,
          '[MEDIA_SERVICE] Không thể nén video: ${file.path}');
    }

    return result;
  }

  /// Tạo thumbnail từ video
  Future<File?> getVideoThumbnail(
    String videoPath, {
    Function(String)? onError,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_SERVICE] Tạo thumbnail cho video: $videoPath, ');
    final result = await _processorService.getVideoThumbnail(
      videoPath,
      quality: 100,
      onError: onError,
    );

    if (result != null) {
      logInfo(LogService.MEDIA,
          '[MEDIA_SERVICE] Tạo thumbnail thành công: ${result.path}');
    } else {
      logWarning(LogService.MEDIA, '[MEDIA_SERVICE] Không thể tạo thumbnail');
    }

    return result;
  }

  /// Phát hiện loại media từ đuôi file
  MediaType detectMediaType(File file) {
    logDebug(LogService.MEDIA,
        '[MEDIA_SERVICE] Phát hiện loại media cho file: ${file.path}');
    return _processorService.detectMediaType(file);
  }

  /// TẢI LÊN MEDIA

  /// Tải lên một file duy nhất lên Firebase Storage
  Future<UploadResult> uploadSingleFile({
    required File file,
    required String path,
    Function(double)? onProgress,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_SERVICE] Tải lên file: ${file.path} đến $path');
    final result = await _uploadService.uploadSingleFile(
      file: file,
      path: path,
      onProgress: onProgress,
    );

    if (result.isSuccess) {
      logInfo(LogService.MEDIA,
          '[MEDIA_SERVICE] Tải lên file thành công: URL=${result.downloadUrl}');
    } else {
      logError(
          LogService.MEDIA,
          '[MEDIA_SERVICE] Lỗi tải lên file: ${result.error}',
          null,
          StackTrace.current);
    }

    return result;
  }

  /// Tải lên nhiều file cùng lúc
  Future<List<UploadResult>> uploadMultipleFiles({
    required List<File> files,
    required String basePath,
    Function(double)? onProgress,
  }) async {
    logInfo(LogService.MEDIA,
        '[MEDIA_SERVICE] Tải lên ${files.length} files đến $basePath');
    final results = await _uploadService.uploadMultipleFiles(
      files: files,
      basePath: basePath,
      onProgress: onProgress,
    );

    final int successCount = results.where((result) => result.isSuccess).length;
    logInfo(LogService.MEDIA,
        '[MEDIA_SERVICE] Kết quả tải lên nhiều files: $successCount/${files.length} thành công');

    return results;
  }

  /// Xóa file từ Firebase Storage
  Future<bool> deleteFile(String storagePath) async {
    return await _uploadService.deleteFile(storagePath);
  }

  /// Kiểm tra xem file có tồn tại trong Firebase Storage không
  Future<bool> fileExists(String storagePath) async {
    return await _uploadService.fileExists(storagePath);
  }
}

/// Provider cho MediaService
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});
