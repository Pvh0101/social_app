import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/cache/cache_manager.dart';
import '../../utils/log_utils.dart';

/// Component hiển thị thumbnail cho video với các tính năng nâng cao:
/// - Tự động cache sử dụng AppCacheManager
/// - Hiệu ứng transition mượt mà
/// - Hiệu ứng blur và gradient (tùy chọn)
/// - Hỗ trợ indicator thời lượng video
class VideoThumbnail extends ConsumerStatefulWidget {
  /// URL của thumbnail (ưu tiên sử dụng nếu có)
  final String? thumbnailUrl;

  /// URL của video (dùng để tạo thumbnail nếu không có thumbnailUrl)
  final String? videoUrl;

  /// Kích thước chiều rộng của thumbnail
  final double? width;

  /// Kích thước chiều cao của thumbnail
  final double? height;

  /// Cách hiển thị hình ảnh trong container
  final BoxFit fit;

  /// Có hiển thị thời lượng video không
  final bool showDuration;

  /// Có hiển thị icon play không
  final bool showPlayIcon;

  /// Callback khi nhấn vào thumbnail
  final VoidCallback? onTap;

  /// Trạng thái hiển thị (dùng cho animation fade)
  final bool isVisible;

  /// Có sử dụng hiệu ứng blur không
  final bool useBlurEffect;

  /// Cường độ của hiệu ứng blur
  final double blurIntensity;

  /// Có sử dụng overlay gradient không
  final bool useGradientOverlay;

  /// Thời lượng video (để hiển thị badge)
  final Duration? duration;

  const VideoThumbnail({
    Key? key,
    this.thumbnailUrl,
    this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showDuration = false,
    this.showPlayIcon = true,
    this.onTap,
    this.isVisible = true,
    this.useBlurEffect = false,
    this.blurIntensity = 3.0,
    this.useGradientOverlay = true,
    this.duration,
  })  : assert(thumbnailUrl != null || videoUrl != null,
            'Phải cung cấp ít nhất một trong hai: thumbnailUrl hoặc videoUrl'),
        super(key: key);

  @override
  ConsumerState<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends ConsumerState<VideoThumbnail> {
  File? _thumbnailFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    logDebug(LogService.MEDIA, '[THUMBNAIL] Khởi tạo VideoThumbnail');
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tải lại thumbnail nếu URL thay đổi
    if (widget.thumbnailUrl != oldWidget.thumbnailUrl ||
        widget.videoUrl != oldWidget.videoUrl) {
      _thumbnailFile = null;
      _errorMessage = null;
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (_isLoading || _thumbnailFile != null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.thumbnailUrl != null) {
        // Tải từ URL sử dụng AppCacheManager
        final cacheManager = ref.read(appCacheManagerProvider);
        final cachedFile = await cacheManager.getFileFromCache(
            widget.thumbnailUrl!, MediaCacheType.image);

        if (mounted) {
          setState(() {
            _thumbnailFile = cachedFile;
            _isLoading = false;
          });

          logDebug(LogService.MEDIA,
              '[THUMBNAIL] Đã tải thumbnail ${cachedFile != null ? 'từ cache' : 'không thành công'}');
        }
      } else if (widget.videoUrl != null && widget.thumbnailUrl == null) {
        // Tạo thumbnail từ video nếu cần và không có sẵn thumbnailUrl
        logDebug(LogService.MEDIA, '[THUMBNAIL] Cần tạo thumbnail từ video');
        // TODO: Sử dụng MediaDisplayService để tạo thumbnail
        // Tạm thời đánh dấu là đã tải xong để tránh loading vô hạn
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      logError(LogService.MEDIA, '[THUMBNAIL] Lỗi khi tải thumbnail: $e', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải thumbnail';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              _buildThumbnailImage(),

              // Play Icon Overlay
              if (widget.showPlayIcon)
                Center(
                  child: AnimatedOpacity(
                    opacity: widget.isVisible ? 0.8 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),

              // Duration Badge (nếu được bật)
              if (widget.showDuration && widget.duration != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(widget.duration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailImage() {
    Widget baseWidget;

    // Loading
    if (_isLoading) {
      return _buildLoading();
    }

    // Error
    if (_errorMessage != null) {
      return _buildError();
    }

    // Local File
    if (_thumbnailFile != null) {
      baseWidget = Image.file(
        _thumbnailFile!,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    // Remote URL với CachedNetworkImage
    else if (widget.thumbnailUrl != null) {
      baseWidget = CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }
    // Fallback
    else {
      baseWidget = _buildFallback();
    }

    // Áp dụng các hiệu ứng nếu cần
    return _applyEffects(baseWidget);
  }

  Widget _applyEffects(Widget baseImage) {
    Widget result = baseImage;

    // Áp dụng blur effect nếu được yêu cầu
    if (widget.useBlurEffect) {
      result = Stack(
        fit: StackFit.expand,
        children: [
          // Background blur copy của ảnh
          ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: widget.blurIntensity, sigmaY: widget.blurIntensity),
            child: Transform.scale(
              scale: 1.2, // Scale lớn hơn để blur không thấy viền
              child: baseImage,
            ),
          ),
          // Ảnh chính không blur
          baseImage,
        ],
      );
    }

    // Áp dụng gradient overlay
    if (widget.useGradientOverlay) {
      result = Stack(
        fit: StackFit.expand,
        children: [
          result,
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
        ],
      );
    }

    return result;
  }

  Widget _buildLoading() => Container(
        color: Colors.black38,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            strokeWidth: 2.0,
          ),
        ),
      );

  Widget _buildError() => Container(
        color: Colors.black54,
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white60,
            size: 32,
          ),
        ),
      );

  Widget _buildFallback() => Container(
        color: Colors.black54,
        child: const Center(
          child: Icon(
            Icons.videocam_outlined,
            color: Colors.white54,
            size: 32,
          ),
        ),
      );

  String _formatDuration(Duration duration) {
    // Format mm:ss hoặc hh:mm:ss
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = (minutes % 60).toString().padLeft(2, '0');
      return '$hours:$mins:$seconds';
    }

    return '$minutes:$seconds';
  }
}
