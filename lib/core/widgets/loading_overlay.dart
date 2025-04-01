import 'package:flutter/material.dart';

/// Widget hiển thị lớp phủ loading khi đang tải dữ liệu
///
/// Bọc widget con và hiển thị lớp phủ mờ với CircularProgressIndicator
/// khi đang tải dữ liệu (isLoading = true)
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final Widget? loadingIndicator;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.loadingIndicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: loadingIndicator ?? const CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
