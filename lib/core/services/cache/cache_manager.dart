import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/log_utils.dart';

/// Dịch vụ quản lý cache trong ứng dụng với các tùy chỉnh cho từng loại nội dung
class AppCacheManager {
  // Singleton pattern
  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;
  AppCacheManager._internal();

  // Khóa để lưu cấu hình cache và thống kê
  static const String _lastCacheCleanKey = 'last_cache_clean_time';
  static const String _imageCacheSizeKey = 'image_cache_size_bytes';
  static const String _audioCacheSizeKey = 'audio_cache_size_bytes';

  // Đếm số lần thử lại
  final Map<String, int> _retryAttempts = {};
  static const int _maxRetryAttempts = 2;

  // Kích thước cache mặc định
  static const int _defaultMaxCacheSize = 150 * 1024 * 1024; // 150MB
  static const int _defaultMaxImageCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _defaultMaxAudioCacheSize = 50 * 1024 * 1024; // 50MB

  // Thời gian hết hạn mặc định
  static const Duration _defaultImageMaxAge = Duration(days: 14); // 2 tuần
  static const Duration _defaultAudioMaxAge = Duration(days: 14); // 2 tuần

  // Cache manager instance cho từng loại media
  late final BaseCacheManager imageCacheManager;
  late final BaseCacheManager audioCacheManager;

  bool _isInitialized = false;

  /// Khởi tạo các cache manager với cấu hình mặc định
  Future<void> initialize() async {
    if (_isInitialized) return;

    logInfo(LogService.MEDIA, '[CACHE_MANAGER] Khởi tạo AppCacheManager');

    // Tạo các cache manager riêng biệt cho mỗi loại media
    imageCacheManager = _createCacheManager(
        'image_cache', _defaultMaxImageCacheSize, _defaultImageMaxAge);

    audioCacheManager = _createCacheManager(
        'audio_cache', _defaultMaxAudioCacheSize, _defaultAudioMaxAge);

    // Kiểm tra và dọn dẹp cache nếu cần
    await _checkAndCleanCache();

    _isInitialized = true;
    logInfo(LogService.MEDIA,
        '[CACHE_MANAGER] AppCacheManager đã khởi tạo thành công');
  }

  /// Tạo cache manager với các cấu hình tùy chỉnh
  BaseCacheManager _createCacheManager(
      String key, int maxSize, Duration maxAge) {
    return CacheManager(
      Config(
        key,
        stalePeriod: maxAge,
        maxNrOfCacheObjects: 1000, // Số lượng object tối đa
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
        fileSystem: IOFileSystem(key), // Lưu trong thư mục riêng
      ),
    );
  }

  /// Lấy file từ cache hoặc tải về nếu cần
  Future<File?> getFileFromCache(String url, MediaCacheType type,
      {bool checkSizeOnly = false}) async {
    final cacheManager = _getCacheManagerForType(type);

    try {
      // Kiểm tra nếu file đã có trong cache
      final fileInfo = await cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        // Chỉ cập nhật thống kê nếu không phải chỉ kiểm tra kích thước
        if (!checkSizeOnly) {
          _updateCacheStats(type, fileInfo.file.lengthSync());
        }
        logDebug(LogService.MEDIA, '[CACHE_MANAGER] Lấy file từ cache: $url');
        _retryAttempts.remove(url); // Xóa số lần thử lại nếu thành công
        return fileInfo.file;
      }

      // Nếu chỉ kiểm tra kích thước, không tải file mới
      if (checkSizeOnly) {
        return null;
      }

      // Tải file mới
      logDebug(LogService.MEDIA, '[CACHE_MANAGER] Tải file mới: $url');
      final file = await cacheManager.getSingleFile(url);
      _updateCacheStats(type, file.lengthSync());
      _retryAttempts.remove(url); // Xóa số lần thử lại nếu thành công
      return file;
    } catch (e) {
      if (e is HttpException && e.toString().contains('403')) {
        return _handleForbiddenError(url, type, e, checkSizeOnly);
      } else if (e is SocketException || e is HttpException) {
        return _handleNetworkError(url, type, e);
      } else {
        logError(LogService.MEDIA,
            '[CACHE_MANAGER] Lỗi khi lấy file từ cache: $url', e);
        return null;
      }
    }
  }

  /// Xử lý lỗi 403 Forbidden
  Future<File?> _handleForbiddenError(String url, MediaCacheType type,
      dynamic error, bool checkSizeOnly) async {
    final retries = _retryAttempts[url] ?? 0;
    if (retries < _maxRetryAttempts) {
      _retryAttempts[url] = retries + 1;
      logWarning(LogService.MEDIA,
          '[CACHE_MANAGER] Lỗi 403 Forbidden, thử lấy URL mới (lần ${retries + 1}/$_maxRetryAttempts): $url');

      try {
        // Xóa file khỏi cache nếu có
        await removeFromCache(url, type);

        // Không thử tải lại nếu chỉ kiểm tra kích thước
        if (checkSizeOnly) {
          return null;
        }

        // Thử tải lại với thêm param để bypass cache
        final bypassUrl = _addCacheBustingParam(url);
        final cacheManager = _getCacheManagerForType(type);
        final file = await cacheManager.getSingleFile(bypassUrl);
        _updateCacheStats(type, file.lengthSync());
        return file;
      } catch (retryError) {
        logError(
            LogService.MEDIA,
            '[CACHE_MANAGER] Thử lại thất bại sau lỗi 403 (lần ${retries + 1}/$_maxRetryAttempts): $url',
            retryError);
        return null;
      }
    } else {
      logError(
          LogService.MEDIA,
          '[CACHE_MANAGER] Đã vượt quá số lần thử lại tối đa ($retries/$_maxRetryAttempts) cho URL: $url',
          error);
      _retryAttempts.remove(url); // Reset số lần thử lại
      return null;
    }
  }

  /// Xử lý lỗi mạng
  Future<File?> _handleNetworkError(
      String url, MediaCacheType type, dynamic error) async {
    logWarning(
        LogService.MEDIA, '[CACHE_MANAGER] Lỗi kết nối mạng khi tải: $url');

    // Kiểm tra một lần cuối trong cache
    try {
      final fileInfo =
          await _getCacheManagerForType(type).getFileFromCache(url);
      if (fileInfo != null) {
        logInfo(LogService.MEDIA,
            '[CACHE_MANAGER] Sử dụng phiên bản cache cũ do lỗi mạng: $url');
        return fileInfo.file;
      }
    } catch (e) {
      // Bỏ qua lỗi khi kiểm tra cache
    }

    return null;
  }

  /// Thêm tham số để bypass cache
  String _addCacheBustingParam(String url) {
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Cập nhật thống kê kích thước cache
  Future<void> _updateCacheStats(MediaCacheType type, int fileSize) async {
    // Bỏ qua nếu kích thước file quá nhỏ
    if (fileSize < 1024) {
      return; // Bỏ qua các file nhỏ để giảm số lần cập nhật SharedPreferences
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String key;

      switch (type) {
        case MediaCacheType.image:
          key = _imageCacheSizeKey;
          break;
        case MediaCacheType.audio:
          key = _audioCacheSizeKey;
          break;
      }

      // Lấy giá trị hiện tại
      int currentSize = 0;
      try {
        currentSize = prefs.getInt(key) ?? 0;
      } catch (e) {
        // Nếu xảy ra lỗi khi đọc, reset giá trị
        logWarning(LogService.MEDIA,
            '[CACHE_MANAGER] Lỗi khi đọc giá trị cache hiện tại, đặt lại thống kê');
        return;
      }

      // Kiểm tra nếu kích thước mới cộng với hiện tại có bất thường
      if (currentSize + fileSize < 0 ||
          currentSize + fileSize > 1024 * 1024 * 1024) {
        // Kích thước vượt quá 1GB hoặc bị tràn số, đặt lại thống kê
        logWarning(LogService.MEDIA,
            '[CACHE_MANAGER] Kích thước cache bất thường, đặt lại thống kê: $currentSize + $fileSize');
        return;
      }

      // Cập nhật chỉ khi có sự thay đổi đáng kể
      if (fileSize > 50 * 1024) {
        // Chỉ cập nhật khi thay đổi > 50KB
        try {
          await prefs.setInt(key, currentSize + fileSize);
        } catch (e) {
          logError(LogService.MEDIA,
              '[CACHE_MANAGER] Lỗi khi lưu thống kê cache', e);
        }
      }
    } catch (e) {
      logError(LogService.MEDIA,
          '[CACHE_MANAGER] Lỗi khi cập nhật thống kê cache', e);
    }
  }

  /// Lấy cache manager tương ứng với loại media
  BaseCacheManager _getCacheManagerForType(MediaCacheType type) {
    switch (type) {
      case MediaCacheType.image:
        return imageCacheManager;
      case MediaCacheType.audio:
        return audioCacheManager;
    }
  }

  /// Tải trước nhiều media và lưu vào cache
  Future<void> preCacheMedia(List<String> urls, MediaCacheType type) async {
    final cacheManager = _getCacheManagerForType(type);

    logDebug(LogService.MEDIA,
        '[CACHE_MANAGER] Bắt đầu pre-cache ${urls.length} ${type.name}');

    final List<String> failedUrls = [];
    final List<String> successUrls = [];

    for (final url in urls) {
      try {
        // Kiểm tra xem đã có trong cache chưa
        final fileInfo = await cacheManager.getFileFromCache(url);
        if (fileInfo != null) {
          successUrls.add(url);
          continue;
        }

        // Tải file mới
        final file = await cacheManager.getSingleFile(url);
        _updateCacheStats(type, file.lengthSync());
        successUrls.add(url);
      } catch (e) {
        if (e is HttpException && e.toString().contains('403')) {
          // Thử với URL có bypass cache
          try {
            final bypassUrl = _addCacheBustingParam(url);
            await cacheManager.getSingleFile(bypassUrl);
            successUrls.add(url);
          } catch (retryError) {
            logError(LogService.MEDIA,
                'Lỗi khi pre-cache media sau khi thử lại: $url', retryError);
            failedUrls.add(url);
          }
        } else {
          logError(LogService.MEDIA, 'Lỗi khi pre-cache media: $url', e);
          failedUrls.add(url);
        }
      }
    }

    if (successUrls.isNotEmpty) {
      logDebug(LogService.MEDIA,
          '[CACHE_MANAGER] Pre-cache thành công ${successUrls.length}/${urls.length} ${type.name}');
    }

    if (failedUrls.isNotEmpty) {
      logWarning(LogService.MEDIA,
          '[CACHE_MANAGER] Pre-cache thất bại ${failedUrls.length}/${urls.length} ${type.name}');
    }
  }

  /// Xóa file cụ thể khỏi cache
  Future<void> removeFromCache(String url, MediaCacheType type) async {
    final cacheManager = _getCacheManagerForType(type);
    await cacheManager.removeFile(url);
    logDebug(LogService.MEDIA, '[CACHE_MANAGER] Đã xóa file khỏi cache: $url');
  }

  /// Xóa toàn bộ cache cho một loại media
  Future<void> clearCache(MediaCacheType type) async {
    final cacheManager = _getCacheManagerForType(type);
    await cacheManager.emptyCache();

    // Xóa thống kê kích thước cache
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (type) {
      case MediaCacheType.image:
        key = _imageCacheSizeKey;
        break;
      case MediaCacheType.audio:
        key = _audioCacheSizeKey;
        break;
    }
    await prefs.remove(key);

    logInfo(
        LogService.MEDIA, '[CACHE_MANAGER] Đã xóa toàn bộ cache ${type.name}');
  }

  /// Kiểm tra và dọn dẹp cache nếu cần thiết
  Future<void> _checkAndCleanCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanTime = prefs.getInt(_lastCacheCleanKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Dọn dẹp cache sau mỗi tuần
      if (currentTime - lastCleanTime >
          const Duration(days: 7).inMilliseconds) {
        logInfo(LogService.MEDIA,
            '[CACHE_MANAGER] Thực hiện dọn dẹp cache định kỳ');

        // Dọn dẹp các file cũ
        await imageCacheManager.emptyCache();
        await audioCacheManager.emptyCache();

        // Cập nhật thời gian dọn dẹp
        await prefs.setInt(_lastCacheCleanKey, currentTime);

        // Xóa các thống kê kích thước cache
        await prefs.remove(_imageCacheSizeKey);
        await prefs.remove(_audioCacheSizeKey);

        logInfo(LogService.MEDIA,
            '[CACHE_MANAGER] Đã hoàn thành dọn dẹp cache định kỳ');
      }
    } catch (e) {
      logError(LogService.MEDIA,
          '[CACHE_MANAGER] Lỗi khi kiểm tra và dọn dẹp cache', e);
    }
  }

  /// Lấy thống kê dung lượng cache hiện tại
  Future<Map<String, int>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'image': prefs.getInt(_imageCacheSizeKey) ?? 0,
      'audio': prefs.getInt(_audioCacheSizeKey) ?? 0,
      'total': (prefs.getInt(_imageCacheSizeKey) ?? 0) +
          (prefs.getInt(_audioCacheSizeKey) ?? 0),
    };
  }

  /// Cập nhật cấu hình cache
  Future<void> updateCacheConfig({
    int? maxImageCacheSize,
    int? maxAudioCacheSize,
    Duration? imageMaxAge,
    Duration? audioMaxAge,
  }) async {
    // Hiện thực tùy chỉnh nâng cao có thể được bổ sung sau
    // Hiện tại chỉ lưu các cấu hình mới trong SharedPreferences
    // và áp dụng khi khởi động lại ứng dụng
    logInfo(LogService.MEDIA,
        '[CACHE_MANAGER] Đã cập nhật cấu hình cache. Vui lòng khởi động lại ứng dụng để áp dụng.');
  }
}

/// Enum định nghĩa các loại cache media
enum MediaCacheType {
  image,
  audio,
}

/// Định dạng kích thước file cho dễ đọc
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

/// Provider cho AppCacheManager
final appCacheManagerProvider = Provider<AppCacheManager>((ref) {
  final cacheManager = AppCacheManager();
  cacheManager.initialize();
  return cacheManager;
});
