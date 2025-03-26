import 'package:flutter/material.dart';

class RoundButtonFill extends StatelessWidget {
  const RoundButtonFill({
    super.key,
    required this.onPressed,
    required this.label,
    this.color,
    this.height = 45,
    this.width,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  final double height;
  final double? width;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Container(
            height: height,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: color ?? theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
