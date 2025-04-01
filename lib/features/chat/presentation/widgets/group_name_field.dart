import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';

/// Widget để nhập tên nhóm chat
///
/// Có thể sử dụng trong cả hai trường hợp:
/// - Tạo nhóm mới
/// - Chỉnh sửa tên nhóm hiện có
class GroupNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing; // Chế độ chỉnh sửa hay hiển thị
  final String? initialName; // Tên ban đầu
  final String? Function(String?)? validator; // Hàm kiểm tra hợp lệ

  const GroupNameField({
    Key? key,
    required this.controller,
    this.isEditing = true,
    this.initialName,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu đang ở chế độ chỉnh sửa, hiển thị text field
    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tên nhóm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller,
              hintText: 'Nhập tên nhóm',
              keyboardType: TextInputType.text,
              validator: validator,
            ),
          ],
        ),
      );
    }

    // Nếu không ở chế độ chỉnh sửa, chỉ hiển thị tên
    return Text(
      initialName ?? 'Nhóm chat',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
