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
      const betterPlayerConfiguration = BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: false,
          enableOverflowMenu: false,
          showControls: false, // Ẩn controls để chỉ hiển thị nút play
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
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Media content
        _buildMediaContent(),

        // Close button ở góc trên bên phải
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              // Edit button (chỉ cho ảnh)
              if (widget.type == MediaType.image && widget.onEdit != null)
                GestureDetector(
                  onTap: _editImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

              // Remove button
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
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
    );
  }

  Widget _buildMediaContent() {
    switch (widget.type) {
      case MediaType.image:
        return Image.file(
          widget.media,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          ),
        );

      case MediaType.video:
        if (_isVideoLoading) {
          return Container(
            color: Colors.transparent,
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
            // Video player
            BetterPlayer(controller: _videoController!),

            // Play button overlay
            GestureDetector(
              onTap: () {
                if (_videoController!.isPlaying() ?? false) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
                setState(() {});
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: Center(
                  child: (!_videoController!.isPlaying()!)
                      ? const Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.white,
                        )
                      : const SizedBox.shrink(),
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

  const MultipleMediaPreview({
    Key? key,
    required this.mediaFiles,
    required this.mediaTypes,
    required this.onRemove,
    this.onEdit,
    this.isUploading = false,
  })  : assert(mediaFiles.length == mediaTypes.length),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mediaFiles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: MediaPreview(
                key: ValueKey(index),
                media: mediaFiles[index],
                type: mediaTypes[index],
                onRemove: () => onRemove(index),
                onEdit: onEdit != null && mediaTypes[index] == MediaType.image
                    ? (file) => onEdit!(index, file)
                    : null,
                isUploading: isUploading,
              ),
            ),
          );
        },
      ),
    );
  }
}
