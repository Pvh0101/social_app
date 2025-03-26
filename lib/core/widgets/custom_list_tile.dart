import 'package:flutter/material.dart';

class CustomListTile extends StatefulWidget {
  final IconData leadingIcon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const CustomListTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  State<CustomListTile> createState() => _CustomListTileState();
}

class _CustomListTileState extends State<CustomListTile> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.symmetric(
        vertical: 2.0, // Reduced vertical padding
        horizontal: isPressed ? 2.0 : 0.0,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60, // Slightly increased height
        decoration: BoxDecoration(
          color: isPressed
              ? Theme.of(context).primaryColor.withAlpha(isDark ? 25 : 8)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(20),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: Theme.of(context).primaryColor.withAlpha(13),
            highlightColor: Colors.transparent,
            onTapDown: (_) => setState(() => isPressed = true),
            onTapUp: (_) => setState(() => isPressed = false),
            onTapCancel: () => setState(() => isPressed = false),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, // Increased horizontal padding
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.leadingIcon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22, // Slightly reduced icon size
                  ),
                  const SizedBox(width: 20), // Increased spacing
                  Expanded(
                    child: Text(widget.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16, // Standard primary text size
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                  if (widget.trailing != null)
                    SizedBox(
                      width: 52, // Increased for Switch widget
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 14, // Standard secondary text size
                            color:
                                Theme.of(context).primaryColor.withAlpha(180),
                            fontWeight: FontWeight.w500,
                          ),
                          child: widget.trailing!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
