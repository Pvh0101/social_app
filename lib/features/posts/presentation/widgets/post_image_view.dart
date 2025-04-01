import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/log_utils.dart';

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    ref.logDebug(LogService.MEDIA,
        'PostImageView khởi tạo với ${widget.imageUrls.length} ảnh');
  }

  @override
  void dispose() {
    ref.logDebug(LogService.MEDIA, 'PostImageView dispose');
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
                    placeholder: (context, url) => const Center(
                      child: SizedBox.shrink(),
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
  bool isDragging = false;

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
            isDragging = true;
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
                  _dragOffset < _dragThreshold) {}
            }
          },
          onVerticalDragEnd: (details) {
            isDragging = false;
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
              },
              scrollDirection: Axis.horizontal,
            ),
          ),
        ),
      ),
    );
  }
}
