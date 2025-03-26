import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/cache/cache_manager.dart';

/// Widget hiển thị ảnh thống nhất cho toàn ứng dụng
/// Hỗ trợ hiển thị ảnh đơn lẻ hoặc bộ sưu tập ảnh
/// Có khả năng zoom và vuốt để thoát
class UnifiedMediaViewer extends ConsumerStatefulWidget {
  /// Danh sách URL của ảnh
  final List<String> mediaUrls;

  /// Vị trí khởi đầu khi mở viewer
  final int initialIndex;

  /// Tiền tố cho Hero tag, nên là định danh duy nhất
  final String? heroTagPrefix;

  /// Nếu true, ẩn appbar khi mở đầu
  final bool startWithoutControls;

  /// Mặc định có thể vuốt xuống để thoát
  final bool allowVerticalDismiss;

  /// Mặc định có thể zoom ảnh
  final bool allowZoom;

  /// Callback khi ảnh hiện tại thay đổi
  final void Function(int index)? onPageChanged;

  const UnifiedMediaViewer({
    Key? key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
    this.startWithoutControls = false,
    this.allowVerticalDismiss = true,
    this.allowZoom = true,
    this.onPageChanged,
  }) : super(key: key);

  @override
  ConsumerState<UnifiedMediaViewer> createState() => _UnifiedMediaViewerState();
}

class _UnifiedMediaViewerState extends ConsumerState<UnifiedMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = false;

  double _dragDistance = 0.0;
  bool _isDragging = false;
  static const double _minDragDistanceToExit = 100.0;
  static const double _maxDragOpacityThreshold = 200.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _showControls = !widget.startWithoutControls;
    _pageController = PageController(initialPage: _currentIndex);

    // Preload current image
    _preloadImage(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _preloadImage(int index) async {
    if (index < 0 || index >= widget.mediaUrls.length) return;

    final cacheManager = ref.read(appCacheManagerProvider);
    final url = widget.mediaUrls[index];

    try {
      await cacheManager.getFileFromCache(url, MediaCacheType.image);
    } catch (e) {
      debugPrint('Lỗi khi tải trước ảnh: $e');
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    widget.onPageChanged?.call(index);

    // Tải trước ảnh kế tiếp
    _preloadImage(index);
  }

  // Xử lý vuốt để thoát
  void _onDragStart(DragStartDetails details) {
    if (!widget.allowVerticalDismiss) return;

    setState(() {
      _isDragging = true;
      _dragDistance = 0.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.allowVerticalDismiss || !_isDragging) return;

    // Chỉ cho phép vuốt xuống
    if (details.delta.dy > 0) {
      setState(() {
        _dragDistance += details.delta.dy;
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.allowVerticalDismiss || !_isDragging) return;

    if (_dragDistance > _minDragDistanceToExit) {
      Navigator.of(context).pop();
    } else {
      // Reset nếu không đủ khoảng cách
      setState(() {
        _isDragging = false;
        _dragDistance = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán độ mờ dựa trên khoảng cách kéo
    final double opacity = _isDragging
        ? 1.0 - (_dragDistance / _maxDragOpacityThreshold).clamp(0.0, 0.7)
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      extendBodyBehindAppBar: true,
      appBar: _showControls ? _buildAppBar() : null,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragDistance / 2),
          child: Opacity(
            opacity: opacity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaUrls.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _buildImageView(index),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _showControls && widget.mediaUrls.length > 1
          ? _buildBottomIndicator()
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black26,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: widget.mediaUrls.length > 1
          ? Text(
              '${_currentIndex + 1}/${widget.mediaUrls.length}',
              style: const TextStyle(color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBottomIndicator() {
    return Container(
      height: 50,
      color: Colors.black38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.mediaUrls.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentIndex ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageView(int index) {
    final heroTag = widget.heroTagPrefix != null
        ? '${widget.heroTagPrefix}_$index'
        : widget.mediaUrls[index];

    return Hero(
      tag: heroTag,
      child: PhotoView(
        imageProvider: CachedNetworkImageProvider(widget.mediaUrls[index]),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 50),
        ),
        enableRotation: true,
        tightMode: false,
        disableGestures: !widget.allowZoom,
      ),
    );
  }
}
