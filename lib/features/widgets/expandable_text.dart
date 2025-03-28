import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLength;
  final TextStyle? textStyle;
  final TextStyle? expandButtonStyle;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLength = 100,
    this.textStyle,
    this.expandButtonStyle,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu đoạn văn bản quá dài và cần hiển thị nút mở rộng
    final bool shouldShowExpandButton = widget.text.length > widget.maxLength;

    // Nếu văn bản ngắn hơn maxLength, hiển thị toàn bộ
    if (!shouldShowExpandButton) {
      return Text(widget.text,
          style: widget.textStyle ?? const TextStyle(fontSize: 16));
    }

    // Xác định đoạn văn bản sẽ hiển thị
    final String displayedText = isExpanded
        ? widget.text
        : '${widget.text.substring(0, widget.maxLength)}...';

    // Style mặc định cho nút mở rộng
    final TextStyle expandStyle = widget.expandButtonStyle ??
        TextStyle(
          fontSize: 14,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Text(
            displayedText,
            style: widget.textStyle ?? const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Text(
            isExpanded ? "Thu gọn" : "Xem thêm",
            style: expandStyle,
          ),
        ),
      ],
    );
  }
}
