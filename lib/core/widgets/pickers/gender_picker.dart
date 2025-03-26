import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Widget cho phép người dùng chọn giới tính từ một danh sách có sẵn
///
/// Hiển thị dưới dạng một PopupMenuButton đơn giản
/// Hỗ trợ validation và đa ngôn ngữ
class GenderPicker extends StatelessWidget {
  /// Giá trị giới tính hiện tại được chọn
  final String? selectedGender;

  /// Callback được gọi khi người dùng chọn giới tính
  final Function(String?) onChanged;

  /// Danh sách các giá trị giới tính hợp lệ
  static const List<String> validGenders = ['male', 'female', 'other'];

  const GenderPicker({
    super.key,
    this.selectedGender,
    required this.onChanged,
  });

  /// Lấy icon tương ứng cho từng giới tính
  IconData _getGenderIcon(String? gender) {
    switch (gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'other':
        return Icons.people;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      position: PopupMenuPosition.under,
      splashRadius: 0,
      enableFeedback: false,
      itemBuilder: (context) => validGenders.map((gender) {
        return PopupMenuItem<String>(
          value: gender,
          mouseCursor: SystemMouseCursors.basic,
          child: Row(
            children: [
              Icon(
                _getGenderIcon(gender),
                size: 20,
                color: gender == selectedGender
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'fields.gender.$gender'.tr(),
                style: TextStyle(
                  color: gender == selectedGender
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: gender == selectedGender ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: Row(
            children: [
              Icon(
                _getGenderIcon(selectedGender),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedGender != null
                      ? 'fields.gender.$selectedGender'.tr()
                      : 'Giới tính *',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
