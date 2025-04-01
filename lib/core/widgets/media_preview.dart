import 'dart:io';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../services/media/media_types.dart';
import '../services/media/media_service.dart';

// MediaPreview đơn giản theo kiểu Facebook
class MediaPreview extends StatefulWidget {
  final File media;
  final MediaType type;
  final VoidCallback onRemove;
  final Function(File)? onEdit;
  final bool isUploading;
  final double? uploadProgress;

  const MediaPreview({
    Key? key,
    required this.media,
    required this.type,
    required this.onRemove,
    this.onEdit,
    this.isUploading = false,
    this.uploadProgress,
  }) : super(key: key);

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  BetterPlayerController? _videoController;
  bool _isVideoLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == MediaType.video) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    setState(() => _isVideoLoading = true);

    try {
      final betterPlayerConfiguration = BetterPlayerConfiguration(
        aspectRatio: 9 / 16,
        fit: BoxFit.contain,
        autoPlay: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enableFullscreen: false,
          enableOverflowMenu: false,
          showControls: false,
          enablePlayPause: false,
          enableProgressBar: false,
          enableSkips: false,
          loadingWidget:
              Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        widget.media.path,
      );

      _videoController = BetterPlayerController(betterPlayerConfiguration);
      await _videoController?.setupDataSource(dataSource);
    } catch (e) {
      debugPrint('Lỗi khởi tạo video player: $e');
    } finally {
      if (mounted) {
        setState(() => _isVideoLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _editImage() async {
    if (widget.onEdit == null) return;

    try {
      final mediaService = MediaService();
      final croppedFile = await mediaService.cropImage(widget.media);

      if (croppedFile != null) {
        widget.onEdit!(croppedFile);
      }
    } catch (e) {
      debugPrint('Lỗi khi chỉnh sửa ảnh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Media content với container đen để đảm bảo màu nền nhất quán
          Container(
            color: Colors.black,
            child: _buildMediaContent(),
          ),

          // Close button ở góc trên bên phải
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                // Edit button (chỉ cho ảnh)
                if (widget.type == MediaType.image && widget.onEdit != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _editImage,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Remove button
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onRemove,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Upload progress indicator
          if (widget.isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: widget.uploadProgress != null
                    ? CircularProgressIndicator(
                        value: widget.uploadProgress,
                        color: Colors.white,
                      )
                    : const CircularProgressIndicator(
                        color: Colors.white,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (widget.type) {
      case MediaType.image:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Image.file(
            widget.media,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
            ),
          ),
        );

      case MediaType.video:
        if (_isVideoLoading) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (_videoController == null) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.play_circle_outline,
                  color: Colors.white, size: 64),
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Video player với container màu đen tràn toàn bộ không gian
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 16 / 9,
                  child: BetterPlayer(controller: _videoController!),
                ),
              ),
            ),

            // Play button overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: (!_videoController!.isPlaying()!)
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _videoController!.play();
                            setState(() {});
                          },
                          customBorder: const CircleBorder(),
                          child: Ink(
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(18.0),
                              child: Icon(
                                Icons.play_arrow,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _videoController!.pause();
                            setState(() {});
                          },
                          customBorder: const CircleBorder(),
                          child: const SizedBox.shrink(),
                        ),
                      ),
              ),
            ),
          ],
        );

      default:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.insert_drive_file, color: Colors.white, size: 40),
          ),
        );
    }
  }
}

// Widget hiển thị nhiều media trong một danh sách cuộn ngang đơn giản
class MultipleMediaPreview extends StatelessWidget {
  final List<File> mediaFiles;
  final List<MediaType> mediaTypes;
  final Function(int) onRemove;
  final Function(int, File)? onEdit;
  final bool isUploading;
  final List<double>? uploadProgress;

  const MultipleMediaPreview({
    Key? key,
    required this.mediaFiles,
    required this.mediaTypes,
    required this.onRemove,
    this.onEdit,
    this.isUploading = false,
    this.uploadProgress,
  })  : assert(mediaFiles.length == mediaTypes.length),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng 2 columns nếu có nhiều hơn 1 media
    final bool useGrid = mediaFiles.length > 1;

    if (!useGrid) {
      // Nếu chỉ có 1 media, hiển thị đơn giản
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: MediaPreview(
          key: ValueKey(0),
          media: mediaFiles[0],
          type: mediaTypes[0],
          onRemove: () => onRemove(0),
          onEdit: onEdit != null && mediaTypes[0] == MediaType.image
              ? (file) => onEdit!(0, file)
              : null,
          isUploading: isUploading,
          uploadProgress: uploadProgress != null && uploadProgress!.isNotEmpty
              ? uploadProgress![0]
              : null,
        ),
      );
    }

    // Hiển thị dạng grid nếu có nhiều media
    return LayoutBuilder(builder: (context, constraints) {
      // Tính toán số cột dựa trên số lượng media và kích thước màn hình
      final int columns =
          mediaFiles.length > 3 || constraints.maxWidth > 400 ? 2 : 1;
      final double aspectRatio = columns == 1 ? 3 / 4 : 1;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: mediaFiles.length,
        itemBuilder: (context, index) {
          return MediaPreview(
            key: ValueKey(index),
            media: mediaFiles[index],
            type: mediaTypes[index],
            onRemove: () => onRemove(index),
            onEdit: onEdit != null && mediaTypes[index] == MediaType.image
                ? (file) => onEdit!(index, file)
                : null,
            isUploading: isUploading,
            uploadProgress:
                uploadProgress != null && index < uploadProgress!.length
                    ? uploadProgress![index]
                    : null,
          );
        },
      );
    });
  }
}
