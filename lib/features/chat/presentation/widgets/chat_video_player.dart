import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget chuyên biệt để hiển thị video trong tin nhắn với tỷ lệ tự động phát hiện
class ChatVideoPlayer extends ConsumerStatefulWidget {
  final String videoUrl;
  final Color placeholderColor;

  const ChatVideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.placeholderColor,
  }) : super(key: key);

  @override
  ConsumerState<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends ConsumerState<ChatVideoPlayer> {
  BetterPlayerController? _controller;
  double? _aspectRatio;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      const betterPlayerConfiguration = BetterPlayerConfiguration(
        autoPlay: false,
        aspectRatio: 16 / 9, // Tỷ lệ mặc định, sẽ được cập nhật sau
        fit: BoxFit.contain,
        handleLifecycle: true,
        autoDetectFullscreenDeviceOrientation: true,
        deviceOrientationsOnFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
        ],
        systemOverlaysAfterFullScreen: SystemUiOverlay.values,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: true,
          enableFullscreen: true,
          enablePlayPause: true,
          enableMute: true,
          enableSkips: false,
          enableOverflowMenu: false,
          enablePlaybackSpeed: false,
          enableSubtitles: false,
          enableQualities: false,
          showControlsOnInitialize: false,
          controlBarHeight: 40,
          controlBarColor: Colors.black54,
          playerTheme: BetterPlayerTheme.material,
        ),
      );

      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.videoUrl,
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          maxCacheSize: 10 * 1024 * 1024, // 10MB tối đa
          maxCacheFileSize: 2 * 1024 * 1024, // 2MB cho mỗi file
          preCacheSize: 3 * 1024 * 1024, // 3MB preload
        ),
      );

      _controller = BetterPlayerController(betterPlayerConfiguration);
      await _controller!.setupDataSource(betterPlayerDataSource);

      if (mounted) {
        setState(() {
          _aspectRatio = 16 / 9; // Tỷ lệ mặc định
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo video player: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return _buildLoadingIndicator();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _aspectRatio ?? 16 / 9,
        child: BetterPlayer(controller: _controller!),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        color: widget.placeholderColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
