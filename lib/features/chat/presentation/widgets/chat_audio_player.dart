import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../../../core/services/cache/cache_manager.dart';

/// Widget hiển thị và phát audio trong tin nhắn
class ChatAudioPlayer extends ConsumerStatefulWidget {
  final String audioUrl;
  final Color backgroundColor;
  final Color foregroundColor;

  const ChatAudioPlayer({
    Key? key,
    required this.audioUrl,
    required this.backgroundColor,
    required this.foregroundColor,
  }) : super(key: key);

  @override
  ConsumerState<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends ConsumerState<ChatAudioPlayer> {
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initAudioPlayer() async {
    // Sử dụng AppCacheManager để quản lý cache audio
    final cacheManager = ref.read(appCacheManagerProvider);
    File? cachedFile;

    try {
      // Lấy file từ cache hoặc tải xuống nếu cần
      cachedFile = await cacheManager.getFileFromCache(
          widget.audioUrl, MediaCacheType.audio);
    } catch (e) {
      debugPrint('Lỗi khi lấy audio từ cache: $e');
    }

    // Sử dụng đường dẫn file đã cache hoặc URL ban đầu
    final audioSource = cachedFile != null ? cachedFile.path : widget.audioUrl;
    final isLocal = cachedFile != null;

    try {
      _audioPlayer = AudioPlayer();

      // Thiết lập nguồn audio
      if (isLocal) {
        await _audioPlayer!.setFilePath(audioSource);
      } else {
        await _audioPlayer!.setUrl(audioSource);
      }

      // Lấy thông tin thời lượng
      _duration = _audioPlayer!.duration ?? Duration.zero;

      // Đăng ký lắng nghe các sự kiện
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo audio player: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_audioPlayer == null) return;

    if (_isPlaying) {
      _audioPlayer!.pause();
    } else {
      _audioPlayer!.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 60,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _isLoading
          ? _buildLoadingIndicator()
          : (!_isInitialized ? _buildErrorWidget() : _buildAudioControls()),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.foregroundColor,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Icon(
        Icons.error_outline,
        color: widget.foregroundColor.withOpacity(0.7),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Row(
      children: [
        // Nút phát/dừng
        InkWell(
          onTap: _togglePlayPause,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.foregroundColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.foregroundColor,
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Thanh tiến trình
        Expanded(
          child: ProgressBar(
            progress: _position,
            total: _duration,
            buffered: _duration, // Khi đã cache thì buffered = duration
            progressBarColor: widget.foregroundColor,
            baseBarColor: widget.foregroundColor.withOpacity(0.2),
            bufferedBarColor: widget.foregroundColor.withOpacity(0.3),
            thumbColor: widget.foregroundColor,
            barHeight: 3,
            thumbRadius: 5,
            timeLabelTextStyle: TextStyle(
              color: widget.foregroundColor.withOpacity(0.8),
              fontSize: 10,
            ),
            timeLabelPadding: 2,
            onSeek: (duration) {
              _audioPlayer?.seek(duration);
            },
          ),
        ),
      ],
    );
  }
}
