import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/log_utils.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';

/// Provider quản lý việc phát video reels
final reelsPlayerProvider = ChangeNotifierProvider<ReelsPlayerProvider>((ref) {
  final provider = ReelsPlayerProvider();

  // Lắng nghe thay đổi từ feed provider để tải video
  ref.listen<AsyncValue<List<PostModel>>>(
    videoFeedProvider.select((value) => value.items),
    (previous, next) {
      next.whenData((posts) {
        if (posts.isNotEmpty) {
          provider.setVideosList(posts);
        }
      });
    },
  );

  return provider;
});

class ReelsPlayerProvider extends ChangeNotifier {
  int currentReelIndex = 0;
  bool loading = true;
  BetterPlayerController? reelsController;
  final cacheController =
      BetterPlayerController(const BetterPlayerConfiguration());
  List<PostModel> videosList = [];

  // Trạng thái phát/dừng hiện tại
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Khởi tạo danh sách video
  void setVideosList(List<PostModel> posts) async {
    try {
      loading = true;
      videosList = posts;
      notifyListeners();

      if (videosList.isNotEmpty) {
        logInfo(LogService.MEDIA,
            '[REELS_PLAYER] Bắt đầu khởi tạo danh sách video (${posts.length} videos)');

        // Cache thumbnail và video đầu tiên
        await cacheImage(videosList.first.thumbnailUrl ?? '');

        // Preload video thứ 2 nếu có
        if (videosList.length > 1) {
          logDebug(LogService.MEDIA, '[REELS_PLAYER] Preload video thứ 2');
          await cacheImage(videosList[1].thumbnailUrl ?? '');
          if (videosList[1].fileUrls?.isNotEmpty == true) {
            cacheController
                .preCache(initDataSource(videosList[1].fileUrls!.first));
          }
        }

        // Khởi tạo controller cho video đầu tiên
        if (videosList.first.fileUrls?.isNotEmpty == true) {
          logInfo(LogService.MEDIA,
              '[REELS_PLAYER] Khởi tạo controller cho video đầu tiên');
          createReelsController(videosList.first.fileUrls!.first);
        }

        loading = false;
        notifyListeners();
      }
    } catch (e) {
      logError(LogService.MEDIA,
          '[REELS_PLAYER] Lỗi khi khởi tạo video list: $e', e);
      loading = false;
      notifyListeners();
    }
  }

  /// Tạo controller cho video đang xem
  void createReelsController(String url) {
    try {
      logDebug(
          LogService.MEDIA, '[REELS_PLAYER] Tạo controller cho video: $url');
      disposeController();

      // Tạo data source
      final betterPlayerDataSource = initDataSource(url);

      // Khởi tạo controller với cấu hình phù hợp
      reelsController = BetterPlayerController(
        BetterPlayerConfiguration(
          placeholder: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: videosList[currentReelIndex].thumbnailUrl ?? '',
            placeholder: (context, url) => const SizedBox(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          aspectRatio: 9 / 16,
          fit: BoxFit.contain,
          autoDispose: false,
          autoPlay: false,
          looping: true,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            showControls: false,
            enableFullscreen: false,
            enableProgressBar: false,
            loadingWidget: SizedBox(),
          ),
        ),
        betterPlayerDataSource: betterPlayerDataSource,
      );

      // Lắng nghe sự kiện từ controller
      reelsController?.addEventsListener((event) {
        if (reelsController!.isVideoInitialized()! &&
            !reelsController!.isPlaying()!) {
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      logError(
          LogService.MEDIA, '[REELS_PLAYER] Lỗi khi tạo controller: $e', e);
    }
  }

  /// Phát video
  void playVideo() {
    try {
      logDebug(LogService.MEDIA, '[REELS_PLAYER] Phát video');
      reelsController?.play();
      _isPlaying = true;
    } catch (e) {
      logError(LogService.MEDIA, '[REELS_PLAYER] Lỗi khi phát video: $e', e);
    }
  }

  /// Dừng video
  void pauseVideo() {
    try {
      logDebug(LogService.MEDIA, '[REELS_PLAYER] Dừng video');
      reelsController?.pause();
      _isPlaying = false;
    } catch (e) {
      logError(LogService.MEDIA, '[REELS_PLAYER] Lỗi khi dừng video: $e', e);
    }
  }

  /// Khởi tạo data source với cấu hình cache
  BetterPlayerDataSource initDataSource(String url) {
    logDebug(LogService.MEDIA, '[REELS_PLAYER] Khởi tạo data source: $url');
    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 3000,
        maxBufferMs: 10000,
        bufferForPlaybackMs: 1000,
        bufferForPlaybackAfterRebufferMs: 2000,
      ),
      cacheConfiguration: BetterPlayerCacheConfiguration(
        useCache: true,
        preCacheSize: 3 * 1024 * 1024, // Cache 3MB của video
        maxCacheSize: 500 * 1024 * 1024, // Cache tối đa 500MB
        maxCacheFileSize:
            3 * 1024 * 1024, // Kích thước tối đa cho mỗi file cache
        key: Platform.isIOS ? url : null,
      ),
    );
  }

  /// Xử lý khi chuyển video
  void onPageChange(int index) async {
    try {
      logInfo(LogService.MEDIA,
          '[REELS_PLAYER] Chuyển sang video ở vị trí: $index');
      // Cập nhật index hiện tại
      currentReelIndex = index;
      notifyListeners();

      // Tạo controller mới cho video hiện tại
      if (videosList[index].fileUrls?.isNotEmpty == true) {
        createReelsController(videosList[index].fileUrls!.first);
      }

      // Preload video kế tiếp nếu không phải video cuối cùng
      if (index < videosList.length - 1) {
        logDebug(LogService.MEDIA,
            '[REELS_PLAYER] Preload video kế tiếp (index: ${index + 1})');
        if (videosList[index + 1].fileUrls?.isNotEmpty == true) {
          cacheController
              .preCache(initDataSource(videosList[index + 1].fileUrls!.first));
        }
        await cacheImage(videosList[index + 1].thumbnailUrl ?? '');
      }
    } catch (e) {
      logError(LogService.MEDIA, '[REELS_PLAYER] Lỗi khi chuyển video: $e', e);
    }
  }

  /// Cache thumbnail
  Future<void> cacheImage(String url) async {
    if (url.isEmpty) return;

    try {
      logDebug(LogService.MEDIA, '[REELS_PLAYER] Cache thumbnail: $url');
      final imageProvider = CachedNetworkImageProvider(url);
      final completer = Completer<void>();

      final listener = ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          if (!completer.isCompleted) {
            logDebug(LogService.MEDIA,
                '[REELS_PLAYER] Thumbnail đã được cache: $url');
            completer.complete();
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            logError(LogService.MEDIA,
                '[REELS_PLAYER] Lỗi khi cache thumbnail: $exception');
            completer.completeError(exception);
          }
        },
      );

      imageProvider.resolve(const ImageConfiguration()).addListener(listener);
      await completer.future;
    } catch (e) {
      logError(
          LogService.MEDIA, '[REELS_PLAYER] Lỗi khi cache thumbnail: $e', e);
    }
  }

  /// Dispose controller một cách an toàn
  void disposeController() {
    try {
      if (reelsController != null) {
        logDebug(LogService.MEDIA, '[REELS_PLAYER] Giải phóng controller');
        reelsController?.removeEventsListener((event) {});
        reelsController?.dispose(forceDispose: true);
        reelsController = null;
      }
    } catch (e) {
      logError(
          LogService.MEDIA, '[REELS_PLAYER] Lỗi khi dispose controller: $e', e);
    }
  }

  /// Dispose provider
  @override
  void dispose() {
    logInfo(LogService.MEDIA, '[REELS_PLAYER] Giải phóng ReelsPlayerProvider');
    disposeController();
    super.dispose();
  }
}
