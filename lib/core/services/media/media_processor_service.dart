import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'media_types.dart';
import '../../../core/utils/log_utils.dart';
import 'dart:async';

/// Service chuyên về xử lý media như nén ảnh/video, cắt ảnh, tạo thumbnail
class MediaProcessorService {
  // Singleton pattern
  static final MediaProcessorService _instance =
      MediaProcessorService._internal();
  factory MediaProcessorService() => _instance;
  MediaProcessorService._internal() {
    logInfo(LogService.MEDIA,
        '[MEDIA_PROCESSOR] MediaProcessorService được khởi tạo');
  }

  /// Nén ảnh với chất lượng tùy chỉnh (giống Instagram)
  Future<File?> compressImage(
    File file, {
    Function(String)? onError,
  }) async {
    try {
      // Kiểm tra kích thước file ban đầu
      final int fileSize = file.lengthSync();
      const int oneMB = 1 * 1024 * 1024; // 1MB
      const int threeMB = 3 * 1024 * 1024; // 3MB

      // Xác định chất lượng nén theo kiểu Instagram
      int compressQuality;
      String qualityLabel;

      if (fileSize < oneMB) {
        // Ảnh đã nhỏ - chất lượng cao
        compressQuality = 100;
        qualityLabel = "cao";
      } else if (fileSize < threeMB) {
        // Ảnh kích thước trung bình - chất lượng vừa
        compressQuality = 90;
        qualityLabel = "vừa";
      } else {
        // Ảnh lớn - giảm chất lượng
        compressQuality = 82;
        qualityLabel = "thấp";
      }

      logDebug(LogService.MEDIA,
          '[MEDIA_PROCESSOR] Bắt đầu nén ảnh: ${file.path}, kích thước: ${(fileSize / 1024).toStringAsFixed(1)}KB, chất lượng: $compressQuality% ($qualityLabel)');

      final result = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: compressQuality,
        format: CompressFormat.jpeg, // JPEG như Instagram
        minWidth: 1080, // Kích thước tối đa giống Instagram
        keepExif: false, // Loại bỏ metadata để giảm kích thước
      );

      if (result == null) {
        logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Không thể nén ảnh', null,
            StackTrace.current);
        if (onError != null) onError('Không thể nén ảnh');
        return null;
      }

      // Tạo file mới để lưu ảnh đã nén
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(result);

      final int compressedSize = compressedFile.lengthSync();
      final double compressionRatio = (1 - compressedSize / fileSize) * 100;
      logInfo(LogService.MEDIA,
          '[MEDIA_PROCESSOR] Đã nén ảnh thành công, kích thước: ${(compressedSize / 1024).toStringAsFixed(1)}KB (giảm ${compressionRatio.toStringAsFixed(1)}%)');

      return compressedFile;
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Lỗi khi nén ảnh: $e', e,
          stackTrace);
      if (onError != null) onError('Lỗi nén ảnh: $e');
      return null;
    }
  }

  /// Cắt ảnh với các tùy chỉnh
  Future<File?> cropImage(
    File file, {
    CropAspectRatioPreset aspectRatio = CropAspectRatioPreset.original,
    bool lockAspectRatio = false,
    Function(String)? onError,
  }) async {
    logDebug(
        LogService.MEDIA, '[MEDIA_PROCESSOR] Bắt đầu cắt ảnh: ${file.path}');
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Chỉnh sửa ảnh',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: lockAspectRatio,
            hideBottomControls: false,
            initAspectRatio: aspectRatio,
          ),
          IOSUiSettings(
            title: 'Chỉnh sửa ảnh',
            aspectRatioLockEnabled: lockAspectRatio,
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        logInfo(LogService.MEDIA,
            '[MEDIA_PROCESSOR] Đã cắt ảnh thành công: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        logDebug(LogService.MEDIA,
            '[MEDIA_PROCESSOR] Người dùng đã hủy thao tác cắt ảnh');
        return null;
      }
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Lỗi khi cắt ảnh: $e', e,
          stackTrace);
      if (onError != null) onError('Lỗi cắt ảnh: $e');
      return null;
    }
  }

  /// Nén video với chất lượng giống TikTok
  Future<File?> compressVideo(
    File file, {
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    // Đo thời gian nén
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final int fileSize = file.lengthSync();
      final MediaInfo info = await VideoCompress.getMediaInfo(file.path);

      logInfo(LogService.MEDIA,
          '[MEDIA_PROCESSOR] Video gốc: ${info.width}x${info.height}, ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB, ${info.duration?.toStringAsFixed(1)}s, định dạng: ${file.path.split('.').last}');

      // Kiểm tra có cần nén không
      final (shouldCompress, videoQuality, reason) =
          shouldCompressVideo(file, info);

      if (!shouldCompress) {
        logInfo(LogService.MEDIA, '[MEDIA_PROCESSOR] Không cần nén: $reason');
        return file;
      }

      logInfo(LogService.MEDIA,
          '[MEDIA_PROCESSOR] Bắt đầu nén, lý do: $reason, chất lượng: $videoQuality');

      // Theo dõi tiến trình nén
      dynamic subscription;
      try {
        subscription = VideoCompress.compressProgress$.subscribe((progress) {
          onProgress?.call(progress / 100);
          if ((progress % 20) < 1 || progress > 99) {
            logDebug(LogService.MEDIA,
                '[MEDIA_PROCESSOR] Tiến độ: ${progress.toStringAsFixed(0)}%');
          }
        });

        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: videoQuality,
          deleteOrigin: false,
          includeAudio: true,
          frameRate: 30,
        );

        // Hủy đăng ký theo dõi tiến độ
        if (subscription != null) {
          subscription.cancel();
        }

        if (mediaInfo == null || mediaInfo.file == null) {
          logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Nén thất bại', null,
              StackTrace.current);
          onError?.call('Không thể nén video');
          return null;
        }

        final File compressedVideo = mediaInfo.file!;
        final int compressedSize = compressedVideo.lengthSync();
        final double compressionRatio = (1 - compressedSize / fileSize) * 100;

        // Dừng đo thời gian
        stopwatch.stop();
        final compressionTime = stopwatch.elapsedMilliseconds / 1000;

        // Log thông tin chi tiết về kết quả nén
        logInfo(LogService.MEDIA,
            '[MEDIA_PROCESSOR] Nén thành công: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)}MB (giảm ${compressionRatio.toStringAsFixed(1)}%), thời gian: ${compressionTime.toStringAsFixed(1)}s');

        // Log thông tin chi tiết về độ phân giải mới
        if (mediaInfo.width != null && mediaInfo.height != null) {
          logDebug(LogService.MEDIA,
              '[MEDIA_PROCESSOR] Độ phân giải sau khi nén: ${mediaInfo.width}x${mediaInfo.height}');
        }

        return compressedVideo;
      } catch (e, stackTrace) {
        if (subscription != null) {
          subscription.cancel();
        }
        stopwatch.stop();
        logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Lỗi khi nén video: $e', e,
            stackTrace);
        onError?.call('Lỗi nén video: $e');
        return null;
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Lỗi: $e', e, stackTrace);
      onError?.call('Lỗi: $e');
      return null;
    }
  }

  /// Kiểm tra có cần nén video không
  (bool shouldCompress, VideoQuality quality, String reason)
      shouldCompressVideo(File file, MediaInfo info) {
    const int largeSizeThreshold = 50 * 1024 * 1024; // 50MB
    const int fullHdWidth = 1920; // 1080p

    final int fileSize = file.lengthSync();
    bool shouldCompress = false;
    VideoQuality videoQuality = VideoQuality.DefaultQuality;
    String reason = "kích thước và độ phân giải đã phù hợp";

    if (fileSize > largeSizeThreshold) {
      shouldCompress = true;
      videoQuality = VideoQuality.Res1920x1080Quality;
      reason =
          "kích thước file quá lớn (>${(largeSizeThreshold / (1024 * 1024)).toStringAsFixed(0)}MB)";
      return (shouldCompress, videoQuality, reason);
    }

    if (info.width != null && info.width! > fullHdWidth) {
      shouldCompress = true;
      videoQuality = VideoQuality.Res1920x1080Quality;
      reason = "độ phân giải cao (> 1080p)";
      return (shouldCompress, videoQuality, reason);
    }

    return (shouldCompress, videoQuality, reason);
  }

  /// Tạo thumbnail từ video
  Future<File?> getVideoThumbnail(
    String videoPath, {
    int quality = 75,
    Function(String)? onError,
  }) async {
    logDebug(LogService.MEDIA,
        '[MEDIA_PROCESSOR] Bắt đầu tạo thumbnail cho video: $videoPath, chất lượng: $quality');
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: quality,
      );

      logInfo(LogService.MEDIA,
          '[MEDIA_PROCESSOR] Đã tạo thumbnail thành công: ${thumbnailFile.path}');
      return thumbnailFile;
    } catch (e, stackTrace) {
      logError(LogService.MEDIA, '[MEDIA_PROCESSOR] Lỗi khi tạo thumbnail: $e',
          e, stackTrace);
      if (onError != null) onError('Lỗi tạo thumbnail: $e');
      return null;
    }
  }

  /// Phát hiện loại media từ đuôi file
  MediaType detectMediaType(File file) {
    final mimeType = lookupMimeType(file.path);
    if (mimeType?.startsWith('image/') == true) return MediaType.image;
    if (mimeType?.startsWith('video/') == true) return MediaType.video;
    if (mimeType?.startsWith('audio/') == true) return MediaType.audio;
    return MediaType.file;
  }
}

/// Provider cho MediaProcessorService
final mediaProcessorServiceProvider = Provider<MediaProcessorService>((ref) {
  return MediaProcessorService();
});
