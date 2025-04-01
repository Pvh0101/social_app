import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = 'common.cancel',
    this.confirmText = 'common.confirm',
    this.confirmColor,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        cancelText: cancelText ?? 'common.cancel',
        confirmText: confirmText ?? 'common.confirm',
        confirmColor: confirmColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText.tr(),
            style: TextStyle(
              color: confirmColor ?? colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
