import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/cache/cache_manager.dart';
import '../../../core/utils/log_utils.dart';
import '../models/post_model.dart';

/// Tùy chọn cấu hình cho việc preload video
class PreloadOptions {
  /// Số lượng video kế tiếp sẽ được preload
  final int preloadCount;

  /// Có preload thumbnail hay không
  final bool preloadThumbnails;

  /// Thời gian delay giữa các lần preload (ms)
  final int preloadDelay;

  const PreloadOptions({
    this.preloadCount = 1,
    this.preloadThumbnails = true,
    this.preloadDelay = 500, // 500ms delay mặc định
  });
}

/// Provider quản lý việc preload video
final videoPreloadProvider = Provider<VideoPreloadManager>((ref) {
  final cacheManager = ref.watch(appCacheManagerProvider);
  return VideoPreloadManager(cacheManager);
});

/// Provider cung cấp tùy chọn preload
final preloadOptionsProvider = StateProvider<PreloadOptions>((ref) {
  return const PreloadOptions();
});

/// Lớp quản lý việc preload video
class VideoPreloadManager {
  final AppCacheManager _cacheManager;
  BetterPlayerController? _reelsController;
  final BetterPlayerController _cacheController;
  bool _isPreloading = false;

  VideoPreloadManager(this._cacheManager)
      : _cacheController = BetterPlayerController(
          const BetterPlayerConfiguration(),
        );

  /// Preload video của các post kế tiếp
  Future<void> preloadNextVideos(
      List<PostModel> posts, int currentIndex) async {
    if (_isPreloading) return;

    try {
      _isPreloading = true;

      // Preload video kế tiếp
      final nextIndex = currentIndex + 1;
      if (nextIndex < posts.length) {
        final nextPost = posts[nextIndex];
        await _preloadVideo(nextPost);
      }

      // Delay 1 giây trước khi preload video tiếp theo
      await Future.delayed(const Duration(seconds: 1));

      // Preload video tiếp theo
      final nextNextIndex = currentIndex + 2;
      if (nextNextIndex < posts.length) {
        final nextNextPost = posts[nextNextIndex];
        await _preloadVideo(nextNextPost);
      }
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload video
  Future<void> _preloadVideo(PostModel post) async {
    try {
      final videoUrl = post.fileUrls!.first;
      logDebug(
          LogService.MEDIA, '[PRELOAD] Bắt đầu preload video ${post.postId}');

      // Tạo data source cho video
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 3000,
          maxBufferMs: 10000,
          bufferForPlaybackMs: 1000,
          bufferForPlaybackAfterRebufferMs: 2000,
        ),
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          preCacheSize: 3 * 1024 * 1024, // Cache 3MB của video
          maxCacheSize: 500 * 1024 * 1024, // Cache tối đa 500MB
          maxCacheFileSize:
              3 * 1024 * 1024, // Kích thước tối đa cho mỗi file cache
        ),
      );

      // Preload video sử dụng cache controller
      _cacheController.preCache(dataSource);

      // Preload thumbnail nếu có
      if (post.thumbnailUrl != null) {
        await _preloadThumbnail(post.thumbnailUrl!);
      }

      logDebug(LogService.MEDIA,
          '[PRELOAD] Đã hoàn thành preload video ${post.postId}');
    } catch (e) {
      logError(LogService.MEDIA,
          '[PRELOAD] Lỗi khi preload video: ${e.toString()}', e);
    }
  }

  /// Preload thumbnail
  Future<void> _preloadThumbnail(String url) async {
    try {
      final imageProvider = CachedNetworkImageProvider(url);
      final completer = Completer<void>();

      final listener = ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(exception);
          }
        },
      );

      imageProvider.resolve(const ImageConfiguration()).addListener(listener);
      await completer.future;
    } catch (e) {
      logError(LogService.MEDIA, '[PRELOAD] Lỗi khi preload thumbnail: $e', e);
    }
  }

  /// Reset trạng thái preload
  void reset() {
    try {
      _reelsController?.dispose();
      _reelsController = null;
      _cacheController.dispose();
    } catch (e) {
      logError(LogService.MEDIA, '[PRELOAD] Lỗi khi hủy controllers: $e', e);
    }
    _isPreloading = false;
  }
}
