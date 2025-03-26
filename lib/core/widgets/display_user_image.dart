import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// **Widget hiển thị ảnh đại diện của người dùng**
///
/// - Hỗ trợ hiển thị ảnh từ **tập tin cục bộ** hoặc **URL**.
/// - Nếu không có ảnh, hiển thị **icon mặc định** hoặc **chữ cái đầu của tên**.
/// - Hỗ trợ **nút chỉnh sửa** nếu `showEditIcon == true`.
/// - Hỗ trợ **trạng thái online** nếu `isOnline == true`.
class DisplayUserImage extends StatelessWidget {
  /// Ảnh đại diện từ tập tin cục bộ (ưu tiên nếu có).
  final File? finalFileImage;

  /// Đường dẫn ảnh đại diện từ internet.
  final String? imageUrl;

  /// Tên người dùng (dùng để lấy chữ cái đầu nếu không có ảnh).
  final String? userName;

  /// Bán kính của ảnh đại diện (mặc định là `40`).
  final double radius;

  /// Hiển thị nút chỉnh sửa hay không.
  final bool showEditIcon;

  /// Callback khi nhấn vào nút chỉnh sửa.
  final VoidCallback? onPressed;

  /// Icon mặc định khi không có ảnh.
  final IconData defaultIcon;

  /// Người dùng có đang online không? (Hiển thị chấm xanh nếu `true`).
  final bool isOnline;

  const DisplayUserImage({
    super.key,
    this.finalFileImage,
    this.imageUrl,
    this.userName,
    this.radius = 40,
    this.showEditIcon = false,
    this.onPressed,
    this.defaultIcon = Icons.person,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ảnh đại diện
        CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: _getImageProvider(),
          child: _buildPlaceholder(context),
        ),

        // Hiển thị trạng thái online hoặc nút chỉnh sửa (nếu có)
        if (showEditIcon && onPressed != null || isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildStatusOrEditButton(context),
          ),
      ],
    );
  }

  /// Trả về ảnh đại diện từ tập tin cục bộ, URL hoặc `null` nếu không có.
  ImageProvider? _getImageProvider() {
    if (finalFileImage != null) return FileImage(finalFileImage!);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(imageUrl!);
    }
    return null;
  }

  /// Hiển thị icon hoặc chữ cái đầu nếu không có ảnh.
  Widget? _buildPlaceholder(BuildContext context) {
    if (_getImageProvider() != null)
      return null; // Có ảnh thì không cần placeholder

    if (userName == null || userName!.trim().isEmpty) {
      return Icon(
        defaultIcon,
        size: radius,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      );
    }

    final initials = _getInitials();
    return Text(
      initials,
      style: TextStyle(
        fontSize: radius * 0.8,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Trả về chữ cái đầu từ tên người dùng (nếu có).
  String _getInitials() {
    if (userName == null || userName!.trim().isEmpty) return '';

    final names =
        userName!.trim().split(' ').where((name) => name.isNotEmpty).toList();

    if (names.isEmpty) return '';

    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }

    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }

  /// Hiển thị chấm trạng thái online hoặc nút chỉnh sửa.
  Widget _buildStatusOrEditButton(BuildContext context) {
    if (isOnline) {
      return CircleAvatar(
        radius: radius * 0.22,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: radius * 0.2,
          backgroundColor: Colors.green,
        ),
      );
    }

    if (showEditIcon && onPressed != null) {
      return CircleAvatar(
        radius: radius * 0.3,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.edit,
            size: radius * 0.3,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: onPressed,
        ),
      );
    }

    return const SizedBox.shrink(); // Không hiển thị gì nếu cả hai `false`
  }
}
