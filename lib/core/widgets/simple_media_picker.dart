import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/media/media_service.dart';
import '../services/media/media_types.dart';
import '../services/permission/permission_service.dart';

class SimpleMediaPicker extends ConsumerWidget {
  // Callback khi media được chọn
  final Function(File file, MediaType type) onMediaSelected;

  // Callback khi chọn nhiều ảnh
  final Function(List<File> files)? onMultipleImagesSelected;

  // Cho phép chọn nhiều ảnh
  final bool allowMultipleImages;

  // Màu của biểu tượng
  final Color? iconColor;

  // Kích thước của biểu tượng
  final double iconSize;

  // Tiêu đề của bottom sheet
  final String? title;

  // Biểu tượng tùy chỉnh
  final IconData? icon;

  const SimpleMediaPicker({
    Key? key,
    required this.onMediaSelected,
    this.onMultipleImagesSelected,
    this.allowMultipleImages = false,
    this.iconColor,
    this.iconSize = 24.0,
    this.title,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = iconColor ?? colorScheme.primary;

    return IconButton(
      icon: Icon(
        icon ?? Icons.add_photo_alternate,
        color: color,
        size: iconSize,
      ),
      onPressed: () => _showMediaOptions(context, ref),
    );
  }

  void _showMediaOptions(BuildContext context, WidgetRef ref) {
    final mediaService = ref.read(mediaServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Phần Ảnh
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ảnh',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                size: 28,
                color: colorScheme.primary,
              ),
              title: Text(
                'Chụp ảnh',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final file = await mediaService.pickImageFromCamera(
                    onError: (error) => _showError(context, error),
                  );
                  if (file != null) {
                    onMediaSelected(file, MediaType.image);
                  }
                } catch (e) {
                  _showError(context, 'Lỗi khi truy cập máy ảnh: $e');
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                size: 28,
                color: colorScheme.primary,
              ),
              title: Text(
                allowMultipleImages ? 'Chọn nhiều ảnh' : 'Chọn ảnh từ thư viện',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (allowMultipleImages && onMultipleImagesSelected != null) {
                    // Chọn nhiều ảnh
                    final files = await mediaService.pickImagesFromGallery(
                      multiple: true,
                      onError: (error) => _showError(context, error),
                    );
                    if (files.isNotEmpty) {
                      onMultipleImagesSelected!(files);
                    }
                  } else {
                    // Chọn một ảnh
                    final files = await mediaService.pickImagesFromGallery(
                      multiple: false,
                      onError: (error) => _showError(context, error),
                    );
                    if (files.isNotEmpty) {
                      onMediaSelected(files.first, MediaType.image);
                    }
                  }
                } catch (e) {
                  _showError(context, 'Lỗi khi truy cập thư viện ảnh: $e');
                }
              },
            ),
            // Phần Video
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Video',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.videocam,
                size: 28,
                color: colorScheme.primary,
              ),
              title: Text(
                'Chọn video từ thư viện',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final file = await mediaService.pickVideoFromGallery(
                    onError: (error) => _showError(context, error),
                  );
                  if (file != null) {
                    onMediaSelected(file, MediaType.video);
                  }
                } catch (e) {
                  _showError(context, 'Lỗi khi truy cập thư viện video: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    // Kiểm tra nếu lỗi liên quan đến quyền truy cập
    String errorMessage = error;
    String actionLabel = 'OK';
    final permissionService = PermissionService();

    if (error.contains('Không có quyền truy cập')) {
      errorMessage = 'permissions.media_rationale'.tr();
      actionLabel = 'permissions.settings'.tr();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: () async {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            // Nếu lỗi quyền truy cập, mở cài đặt ứng dụng
            if (error.contains('Không có quyền truy cập')) {
              // Hiển thị dialog giải thích và đưa người dùng đến cài đặt nếu họ đồng ý
              final shouldOpenSettings =
                  await permissionService.showPermissionRationaleDialog(
                context,
                PermissionGroup.media,
              );

              if (shouldOpenSettings) {
                await permissionService.openAppSettings();
              }
            }
          },
        ),
      ),
    );
  }
}
