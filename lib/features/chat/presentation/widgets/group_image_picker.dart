import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/media/media_service.dart';
import '../../../../core/services/media/media_types.dart';
import '../../../../core/utils/global_method.dart';

/// Widget dùng chung để hiển thị và chọn ảnh nhóm chat
///
/// Có thể sử dụng để:
/// - Hiển thị ảnh nhóm hiện tại (từ URL)
/// - Hiển thị ảnh đã chọn (từ File)
/// - Cho phép người dùng chọn ảnh mới
class GroupImagePicker extends ConsumerWidget {
  final String? existingImageUrl; // URL ảnh hiện có (nếu đang chỉnh sửa nhóm)
  final File? selectedImage; // File ảnh đã chọn (chưa upload)
  final Function(File) onImageSelected; // Callback khi chọn ảnh mới
  final bool isEditable; // Có cho phép chỉnh sửa ảnh không
  final double radius; // Kích thước avatar
  final bool isGroup; // Nhóm hay cá nhân (thay đổi icon mặc định)

  const GroupImagePicker({
    Key? key,
    this.existingImageUrl,
    this.selectedImage,
    required this.onImageSelected,
    this.isEditable = true,
    this.radius = 50,
    this.isGroup = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaService = ref.read(mediaServiceProvider);
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Avatar circle
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          backgroundImage: selectedImage != null
              ? FileImage(selectedImage!) as ImageProvider
              : existingImageUrl != null
                  ? NetworkImage(existingImageUrl!) as ImageProvider
                  : null,
          child: (existingImageUrl == null && selectedImage == null)
              ? Icon(
                  isGroup ? Icons.group : Icons.person,
                  size: radius,
                  color: Colors.grey[600],
                )
              : null,
        ),

        // Button to edit image
        if (isEditable)
          GestureDetector(
            onTap: () async {
              // Hiển thị tùy chọn chọn ảnh
              final files = await mediaService.pickImagesFromGallery(
                multiple: false,
                onError: (error) => showToastMessage(text: 'Lỗi: $error'),
              );

              if (files.isNotEmpty) {
                onImageSelected(files.first);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}
