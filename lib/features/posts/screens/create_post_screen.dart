import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/widgets.dart';
import '../../authentication/providers/get_user_info_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/post_provider.dart';
import '../../../core/utils/global_method.dart';
import '../../../core/utils/log_utils.dart';
import '../../../core/enums/post_type.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/permission/permission_service.dart';

import '../posts.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final PostModel? post;

  const CreatePostScreen({
    super.key,
    this.post,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedFiles = [];
  final List<String> _existingFileUrls = [];
  final List<String> _deletedFileUrls = [];
  bool _isLoading = false;
  PostType _postType = PostType.text;
  final List<MediaType> _mediaTypes = [];
  double _compressionProgress = 0.0;
  final PermissionService _permissionService = PermissionService();

  static const int maxFiles = 10;

  @override
  void initState() {
    super.initState();
    logDebug(
        LogService.POST, '[CREATE_POST_SCREEN] Khởi tạo màn hình tạo bài viết');
    if (widget.post != null) {
      logInfo(LogService.POST,
          '[CREATE_POST_SCREEN] Chỉnh sửa bài viết có ID: ${widget.post!.postId}');
    } else {
      logInfo(LogService.POST, '[CREATE_POST_SCREEN] Tạo bài viết mới');
    }
    _initializeData();
  }

  void _initializeData() {
    if (widget.post != null) {
      _contentController.text = widget.post!.content;
      _postType = widget.post!.postType;
      if (widget.post!.fileUrls != null) {
        _existingFileUrls.addAll(widget.post!.fileUrls!);
        logDebug(LogService.POST,
            '[CREATE_POST_SCREEN] Đã tải ${_existingFileUrls.length} files từ bài viết gốc');
      }
      logDebug(LogService.POST,
          '[CREATE_POST_SCREEN] Khởi tạo dữ liệu từ bài viết có sẵn, loại: ${_postType.value}');
    }
  }

  @override
  void dispose() {
    logDebug(LogService.POST,
        '[CREATE_POST_SCREEN] Giải phóng tài nguyên màn hình tạo bài viết');
    _contentController.dispose();
    super.dispose();
  }

  void _handleMediaSelected(File file, MediaType type) {
    logDebug(LogService.POST,
        '[CREATE_POST_SCREEN] Xử lý file media được chọn, loại: ${type.name}');

    final totalFiles = _selectedFiles.length + _existingFileUrls.length;
    if (totalFiles >= maxFiles) {
      logWarning(LogService.POST,
          '[CREATE_POST_SCREEN] Đã đạt giới hạn số lượng file: $maxFiles');
      showToastMessage(text: '${'create_post.max_files'.tr()} $maxFiles');
      return;
    }

    if (type == MediaType.video &&
        (totalFiles > 0 || _existingFileUrls.isNotEmpty)) {
      logWarning(LogService.POST,
          '[CREATE_POST_SCREEN] Không thể kết hợp video với các file khác');
      showToastMessage(text: 'create_post.video_restriction'.tr());
      return;
    }

    if ((type == MediaType.image || type == MediaType.audio) &&
        _mediaTypes.contains(MediaType.video)) {
      logWarning(LogService.POST,
          '[CREATE_POST_SCREEN] Không thể kết hợp hình ảnh hoặc âm thanh với video');
      showToastMessage(text: 'create_post.media_with_video'.tr());
      return;
    }

    setState(() {
      _selectedFiles.add(file);
      _mediaTypes.add(type);

      // Cập nhật loại bài viết dựa trên loại media
      if (type == MediaType.image) {
        _postType = PostType.image;
        logDebug(LogService.POST,
            '[CREATE_POST_SCREEN] Đã cập nhật loại bài viết thành IMAGE');
      } else if (type == MediaType.video) {
        _postType = PostType.video;
        logDebug(LogService.POST,
            '[CREATE_POST_SCREEN] Đã cập nhật loại bài viết thành VIDEO');
      }
    });

    logInfo(LogService.POST,
        '[CREATE_POST_SCREEN] Đã thêm file media: ${file.path}, tổng số: ${_selectedFiles.length}');
  }

  void _handleMultipleMediaSelected(List<File> files, List<MediaType> types) {
    // Loại bỏ các file trùng lặp trước khi thêm vào danh sách
    final List<File> uniqueFiles = [];
    final List<MediaType> uniqueTypes = [];

    for (int i = 0; i < files.length; i++) {
      // Kiểm tra xem file này đã tồn tại trong _selectedFiles chưa
      bool isDuplicate = false;
      for (final existingFile in _selectedFiles) {
        if (existingFile.path == files[i].path) {
          isDuplicate = true;
          break;
        }
      }

      // Kiểm tra xem file này đã tồn tại trong danh sách mới chọn chưa
      if (!isDuplicate) {
        for (final uniqueFile in uniqueFiles) {
          if (uniqueFile.path == files[i].path) {
            isDuplicate = true;
            break;
          }
        }
      }

      // Nếu không trùng lặp, thêm vào danh sách
      if (!isDuplicate) {
        uniqueFiles.add(files[i]);
        uniqueTypes.add(types[i]);
      }
    }

    // Tiếp tục xử lý với danh sách không trùng lặp
    final totalFiles =
        _selectedFiles.length + _existingFileUrls.length + uniqueFiles.length;
    if (totalFiles > maxFiles) {
      final canAdd =
          maxFiles - (_selectedFiles.length + _existingFileUrls.length);
      if (canAdd <= 0) {
        showToastMessage(text: '${'create_post.max_files'.tr()} $maxFiles');
        return;
      }

      uniqueFiles.length = canAdd;
      uniqueTypes.length = canAdd;
      showToastMessage(text: '${'create_post.max_files_added'.tr()} $canAdd');
    }

    // Kiểm tra nếu có video trong danh sách
    final hasVideo = uniqueTypes.contains(MediaType.video);
    if (hasVideo &&
        (_selectedFiles.isNotEmpty || _existingFileUrls.isNotEmpty)) {
      showToastMessage(text: 'create_post.no_video_with_image'.tr());
      return;
    }

    if (uniqueFiles.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(uniqueFiles);
        _mediaTypes.addAll(uniqueTypes);
        _postType = uniqueTypes.contains(MediaType.video)
            ? PostType.video
            : PostType.image;
      });
    }
  }

  void _removeFile(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _deletedFileUrls.add(_existingFileUrls[index]);
        _existingFileUrls.removeAt(index);
      } else {
        _selectedFiles.removeAt(index);
        _mediaTypes.removeAt(index);
      }

      if (_selectedFiles.isEmpty && _existingFileUrls.isEmpty) {
        _postType = PostType.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(getUserInfoProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post != null
              ? 'edit_post.title'.tr()
              : 'create_post.title'.tr(),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _compressionProgress > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: _compressionProgress,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${(_compressionProgress * 100).toInt()}%",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            )
          else
            TextButton(
              onPressed: _savePost,
              child: Text(
                widget.post != null
                    ? 'edit_post.save'.tr()
                    : 'create_post.upload'.tr(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DisplayUserImage(
                  imageUrl: currentUser.value?.profileImage ?? '',
                  radius: 27,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleSmall,
                          children: [
                            TextSpan(text: '${'create_post.greeting'.tr()} '),
                            TextSpan(
                                text: currentUser.value?.fullName ?? '',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                      Text(
                        'create_post.subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _contentController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'create_post.content_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút chọn ảnh
                _buildMediaButton(
                  icon: Icons.photo_library_rounded,
                  label: 'create_post.add_image'.tr(),
                  color: colorScheme.primary,
                  onPressed: () async {
                    final mediaService = ref.read(mediaServiceProvider);
                    try {
                      final files = await mediaService.pickImagesFromGallery(
                        multiple: true,
                        onError: (error) => showToastMessage(text: error),
                      );

                      if (files.isNotEmpty) {
                        final types = List<MediaType>.filled(
                            files.length, MediaType.image);
                        _handleMultipleMediaSelected(files, types);
                      }
                    } catch (e) {
                      showToastMessage(
                          text: '${'permissions.gallery_denied'.tr()}: $e');
                    }
                  },
                ),

                const SizedBox(width: 16),

                // Nút tải lên video
                _buildMediaButton(
                  icon: Icons.videocam_rounded,
                  label: 'create_post.add_video'.tr(),
                  color: colorScheme.secondary,
                  onPressed: () async {
                    final mediaService = ref.read(mediaServiceProvider);
                    try {
                      final file = await mediaService.pickVideoFromGallery(
                        onError: (error) => showToastMessage(text: error),
                      );

                      if (file != null) {
                        _handleMediaSelected(file, MediaType.video);
                      }
                    } catch (e) {
                      showToastMessage(
                          text: '${'permissions.gallery_denied'.tr()}: $e');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _buildMediaPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: MultipleMediaPreview(
              mediaFiles: _selectedFiles,
              mediaTypes: _mediaTypes,
              onRemove: (index) => _removeFile(index, false),
              onEdit: _mediaTypes.contains(MediaType.image)
                  ? (index, file) {
                      setState(() {
                        _selectedFiles[index] = file;
                      });
                    }
                  : null,
            ),
          ),
        if (_existingFileUrls.isNotEmpty)
          Container(
            height: 300,
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingFileUrls.length,
              itemBuilder: (context, index) {
                final url = _existingFileUrls[index];
                final isVideo = url.contains('video');

                return Container(
                  width: isVideo ? 200 : 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      isVideo
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/video_placeholder.png',
                                  fit: BoxFit.cover,
                                ),
                                const Icon(
                                  Icons.play_circle_fill,
                                  size: 40,
                                  color: Colors.white70,
                                ),
                              ],
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
                            ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeFile(index, true),
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
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 120,
      height: 70,
      child: Material(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePost() async {
    if (_contentController.text.trim().isEmpty) {
      showToastMessage(text: 'create_post.validation.content_required'.tr());
      return;
    }

    setState(() => _isLoading = true);
    _compressionProgress = 0.0;

    try {
      final postRepository = ref.read(postRepositoryProvider);

      if (widget.post != null) {
        await postRepository.updatePost(
          postId: widget.post!.postId,
          content: _contentController.text,
          postType: _postType,
          newFiles: _selectedFiles.isNotEmpty ? _selectedFiles : null,
          deletedFileUrls:
              _deletedFileUrls.isNotEmpty ? _deletedFileUrls : null,
          onProgress: (progress) {
            setState(() {
              _compressionProgress = progress;
            });
          },
        );
      } else {
        await postRepository.createPost(
          content: _contentController.text,
          postType: _postType,
          files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
          onProgress: (progress) {
            setState(() {
              _compressionProgress = progress;
            });
          },
        );
      }

      if (mounted) {
        if (_postType == PostType.video) {
          ref.read(videoFeedProvider.notifier).refresh();
        } else {
          ref.read(mainFeedProvider.notifier).refresh();
        }

        Navigator.pop(context);
        showToastMessage(
          text: widget.post != null
              ? 'edit_post.success'.tr()
              : 'create_post.success'.tr(),
        );
      }
    } catch (e) {
      showToastMessage(text: '${'common.error'.tr()}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
