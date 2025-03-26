import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.color,
    this.height = 45,
    this.width,
    this.isLoading = false,
    this.backgroundColor,
  });

  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  final double height;
  final double? width;
  final bool isLoading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: IntrinsicWidth(
            // 🌟 Tự động giãn theo nội dung
            child: Container(
              height: height,
              width: width, // Không đặt full-width mặc định
              padding: const EdgeInsets.symmetric(
                  horizontal: 16), // Thêm padding ngang
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary),
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          color: color ?? theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
