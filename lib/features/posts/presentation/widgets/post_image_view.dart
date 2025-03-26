import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cache/cache_manager.dart';
import '../../../../core/utils/log_utils.dart';

// Provider lưu trữ trạng thái của các URL đã được tải
final _preloadedImagesProvider = StateProvider<Set<String>>((ref) => {});

class PostImageView extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final String? heroTagPrefix;

  const PostImageView({
    super.key,
    required this.imageUrls,
    this.heroTagPrefix,
  });

  @override
  ConsumerState<PostImageView> createState() => _PostImageViewState();
}

class _PostImageViewState extends ConsumerState<PostImageView>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  int _currentPage = 0;
  String? _currentImageUrl;
  bool _hasInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    ref.logDebug(LogService.MEDIA,
        'PostImageView khởi tạo với ${widget.imageUrls.length} ảnh');

    if (widget.imageUrls.isNotEmpty) {
      _currentImageUrl = widget.imageUrls[0];
    }

    // Tải ảnh trong frame tiếp theo để tránh lỗi khi widget được tạo/hủy nhanh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadImages();
        _hasInitialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(PostImageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Kiểm tra xem URL ảnh có thay đổi không
    final hasNewImages = widget.imageUrls.isNotEmpty &&
        (oldWidget.imageUrls.isEmpty ||
            widget.imageUrls[0] != oldWidget.imageUrls[0]);

    if (hasNewImages && mounted) {
      ref.logDebug(LogService.MEDIA,
          'PostImageView: URL ảnh đã thay đổi, tải lại dữ liệu');
      _currentImageUrl = widget.imageUrls[0];
      _preloadImages();
    }
  }

  Future<void> _preloadImages() async {
    if (widget.imageUrls.isEmpty) return;

    // Lấy danh sách ảnh đã được tải trước
    final preloadedImages = ref.read(_preloadedImagesProvider);

    // Nếu ảnh đã được tải trước rồi, không cần tải lại
    if (preloadedImages.contains(widget.imageUrls[0])) {
      ref.logDebug(LogService.MEDIA,
          'Ảnh ${widget.imageUrls[0]} đã được tải trước đó, bỏ qua');
      return;
    }

    final cacheManager = ref.read(appCacheManagerProvider);
    try {
      ref.logDebug(
          LogService.MEDIA, 'Bắt đầu tải trước ảnh: ${widget.imageUrls[0]}');
      // Ưu tiên tải ảnh hiện tại trước
      await cacheManager.getFileFromCache(
          widget.imageUrls[0], MediaCacheType.image);

      // Đánh dấu ảnh đã được tải
      ref
          .read(_preloadedImagesProvider.notifier)
          .update((state) => {...state, widget.imageUrls[0]});

      // Sau đó tải trước các ảnh khác
      if (widget.imageUrls.length > 1) {
        ref.logDebug(LogService.MEDIA,
            'Tải trước ${widget.imageUrls.length - 1} ảnh còn lại');
        cacheManager.preCacheMedia(
            widget.imageUrls.sublist(1), MediaCacheType.image);

        // Đánh dấu các ảnh khác
        ref
            .read(_preloadedImagesProvider.notifier)
            .update((state) => {...state, ...widget.imageUrls.sublist(1)});
      }
    } catch (e) {
      ref.logError(LogService.MEDIA, 'Lỗi khi tải trước ảnh: $e', e);
    }
  }

  @override
  void dispose() {
    ref.logDebug(LogService.MEDIA,
        'PostImageView dispose: ${_currentImageUrl ?? "không có URL"}');
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreenView() {
    if (widget.imageUrls.isEmpty) return;

    ref.logInfo(LogService.MEDIA,
        'Mở chế độ xem ảnh toàn màn hình, ảnh: ${_currentPage + 1}/${widget.imageUrls.length}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImageView(
          imageUrls: widget.imageUrls,
          initialIndex: _currentPage,
          heroTagPrefix: widget.heroTagPrefix,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin

    if (widget.imageUrls.isEmpty) {
      ref.logWarning(LogService.MEDIA,
          'PostImageView được xây dựng với danh sách ảnh trống');
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              ref.logDebug(LogService.MEDIA,
                  'Chuyển sang ảnh ${index + 1}/${widget.imageUrls.length}');
              // Tải trước ảnh kế tiếp khi chuyển trang
              _preloadNextImage(index);
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: _openFullscreenView,
                child: Hero(
                  tag: '${widget.heroTagPrefix ?? "image"}_$index',
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.cover,
                    cacheManager: DefaultCacheManager(),
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) {
                      ref.logError(
                          LogService.MEDIA, 'Lỗi tải ảnh: $url', error);
                      return const Center(
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _preloadNextImage(int currentIndex) {
    if (widget.imageUrls.length <= 1) return;

    final cacheManager = ref.read(appCacheManagerProvider);
    final preloadedImages = ref.read(_preloadedImagesProvider);

    // Tải ảnh kế tiếp
    final nextIndex = (currentIndex + 1) % widget.imageUrls.length;
    final nextImageUrl = widget.imageUrls[nextIndex];

    if (!preloadedImages.contains(nextImageUrl)) {
      ref.logDebug(LogService.MEDIA,
          'Tải trước ảnh tiếp theo: ${nextIndex + 1}/${widget.imageUrls.length}');
      cacheManager.getFileFromCache(nextImageUrl, MediaCacheType.image);

      // Đánh dấu ảnh đã được tải
      ref
          .read(_preloadedImagesProvider.notifier)
          .update((state) => {...state, nextImageUrl});
    }

    // Tải ảnh trước đó nếu có
    if (widget.imageUrls.length > 2) {
      final prevIndex = (currentIndex - 1 + widget.imageUrls.length) %
          widget.imageUrls.length;
      final prevImageUrl = widget.imageUrls[prevIndex];

      if (!preloadedImages.contains(prevImageUrl)) {
        ref.logDebug(LogService.MEDIA,
            'Tải trước ảnh trước đó: ${prevIndex + 1}/${widget.imageUrls.length}');
        cacheManager.getFileFromCache(prevImageUrl, MediaCacheType.image);

        // Đánh dấu ảnh đã được tải
        ref
            .read(_preloadedImagesProvider.notifier)
            .update((state) => {...state, prevImageUrl});
      }
    }
  }
}

class FullscreenImageView extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  const FullscreenImageView({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    this.heroTagPrefix,
  });

  @override
  ConsumerState<FullscreenImageView> createState() =>
      _FullscreenImageViewState();
}

class _FullscreenImageViewState extends ConsumerState<FullscreenImageView> {
  late PageController _pageController;
  int _currentPage = 0;
  double _dragOffset = 0;
  static const double _dragThreshold = 100.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 1.0,
    );
    _currentPage = widget.initialIndex;
    ref.logInfo(LogService.MEDIA,
        'FullscreenImageView khởi tạo với ảnh ${widget.initialIndex + 1}/${widget.imageUrls.length}');
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    if (widget.imageUrls.isEmpty) return;

    final cacheManager = ref.read(appCacheManagerProvider);

    try {
      // Ưu tiên tải ảnh hiện tại
      ref.logDebug(LogService.MEDIA,
          'Tải ảnh hiện tại cho fullscreen: ${_currentPage + 1}/${widget.imageUrls.length}');
      await cacheManager.getFileFromCache(
          widget.imageUrls[_currentPage], MediaCacheType.image);

      // Sau đó tải các ảnh xung quanh (trước và sau) nếu có
      final imagesToPreload = <String>[];

      if (_currentPage > 0) {
        imagesToPreload.add(widget.imageUrls[_currentPage - 1]);
      }

      if (_currentPage < widget.imageUrls.length - 1) {
        imagesToPreload.add(widget.imageUrls[_currentPage + 1]);
      }

      if (imagesToPreload.isNotEmpty) {
        ref.logDebug(LogService.MEDIA,
            'Tải trước ${imagesToPreload.length} ảnh liền kề');
        cacheManager.preCacheMedia(imagesToPreload, MediaCacheType.image);
      }
    } catch (e) {
      ref.logError(
          LogService.MEDIA, 'Lỗi khi tải trước ảnh full screen: $e', e);
    }
  }

  @override
  void dispose() {
    ref.logDebug(LogService.MEDIA, 'FullscreenImageView dispose');
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra để tránh lỗi
    if (widget.imageUrls.isEmpty) {
      ref.logWarning(LogService.MEDIA,
          'FullscreenImageView được xây dựng với danh sách ảnh trống');
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Không có hình ảnh để hiển thị',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              ref.logInfo(
                  LogService.MEDIA, 'Đóng chế độ xem ảnh toàn màn hình');
              Navigator.pop(context);
            },
          ),
          actions: [
            if (widget.imageUrls.length > 1)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        body: GestureDetector(
          onVerticalDragStart: (details) {
            _isDragging = true;
            _dragOffset = 0;
            ref.logDebug(
                LogService.MEDIA, 'Bắt đầu kéo thả để đóng fullscreen');
          },
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! > 0) {
              setState(() {
                _dragOffset += details.primaryDelta!;
              });

              if (_dragOffset > _dragThreshold / 2 &&
                  _dragOffset < _dragThreshold) {
                ref.logDebug(LogService.MEDIA,
                    'Kéo thả tiến triển: $_dragOffset/${_dragThreshold}');
              }
            }
          },
          onVerticalDragEnd: (details) {
            _isDragging = false;
            if (_dragOffset > _dragThreshold) {
              ref.logInfo(LogService.MEDIA,
                  'Đóng fullscreen bằng kéo thả (offset: $_dragOffset)');
              Navigator.pop(context);
            } else {
              ref.logDebug(LogService.MEDIA,
                  'Hủy kéo thả, quay lại chế độ xem toàn màn hình');
              setState(() => _dragOffset = 0);
            }
          },
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: PhotoViewGallery.builder(
              scrollPhysics: const ClampingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(
                    widget.imageUrls[index],
                    cacheManager: DefaultCacheManager(),
                  ),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: '${widget.heroTagPrefix ?? "image"}_$index',
                  ),
                );
              },
              itemCount: widget.imageUrls.length,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                  color: Colors.white,
                ),
              ),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                ref.logInfo(LogService.MEDIA,
                    'Chuyển sang ảnh toàn màn hình ${index + 1}/${widget.imageUrls.length}');
                _preloadAdjacentImages(index);
              },
              scrollDirection: Axis.horizontal,
            ),
          ),
        ),
      ),
    );
  }

  void _preloadAdjacentImages(int currentIndex) {
    if (widget.imageUrls.length <= 1) return;

    final cacheManager = ref.read(appCacheManagerProvider);

    // Tạo danh sách các ảnh cần tải trước (ảnh trước và sau vị trí hiện tại)
    final List<String> imagesToPreload = [];

    // Ảnh tiếp theo
    if (currentIndex < widget.imageUrls.length - 1) {
      imagesToPreload.add(widget.imageUrls[currentIndex + 1]);
      ref.logDebug(LogService.MEDIA,
          'Tải trước ảnh kế tiếp: ${currentIndex + 2}/${widget.imageUrls.length}');
    }

    // Ảnh trước đó
    if (currentIndex > 0) {
      imagesToPreload.add(widget.imageUrls[currentIndex - 1]);
      ref.logDebug(LogService.MEDIA,
          'Tải trước ảnh trước đó: ${currentIndex}/${widget.imageUrls.length}');
    }

    // Tải trước các ảnh liền kề
    if (imagesToPreload.isNotEmpty) {
      cacheManager.preCacheMedia(imagesToPreload, MediaCacheType.image);
    }
  }
}
