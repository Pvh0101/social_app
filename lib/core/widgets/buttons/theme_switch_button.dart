import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';

class ThemeSwitchButton extends ConsumerWidget {
  const ThemeSwitchButton({
    super.key,
    this.textStyle = const TextStyle(
      fontSize: 16,
    ),
  });

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return TextButton(
      onPressed: () => themeNotifier.toggleTheme(),
      child: Icon(
        themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        size: 24,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
