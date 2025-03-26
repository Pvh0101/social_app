import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

class BirthdayPicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;
  final String label;

  final DateTime? firstDate;
  final DateTime? lastDate;

  const BirthdayPicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.label = 'birthday',
    this.firstDate,
    this.lastDate,
  });

  Future<void> _selectDate(BuildContext context) async {
    final picked = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now(),
      dateFormat: "dd/MM/yyyy",
      locale: DateTimePickerLocale.en_us,
      looping: true, // Cho phép cuộn vô tận
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          borderRadius: BorderRadius.circular(15),
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate == null
                        ? '${'birthday'.tr()} *'
                        : DateFormat('dd/MM/yyyy').format(selectedDate!),
                    style: selectedDate == null
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          )
                        : TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
