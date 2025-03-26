import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/core.dart';
import '../../../../core/providers/theme_provider.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  static const String routeName = RouteConstants.themeSettings;

  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.theme.title'.tr()),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Switch
          _buildSection(
            title: 'settings.theme.dark_mode'.tr(),
            child: SwitchListTile(
              value: themeState.isDarkMode,
              onChanged: (value) => themeNotifier.toggleTheme(),
              title: Text(
                themeState.isDarkMode
                    ? 'settings.theme.dark'.tr()
                    : 'settings.theme.light'.tr(),
              ),
              secondary: Icon(
                themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Theme Color Selection
          _buildSection(
            title: 'settings.theme.colors'.tr(),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...ThemeNotifier.predefinedColors.map((color) {
                  return _buildColorOption(
                    context,
                    color: color,
                    isSelected: themeState.primaryColor.value == color.value,
                    onTap: () => themeNotifier.setPrimaryColor(color),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Font Size Adjustment
          _buildSection(
            title: 'settings.theme.text_size'.tr(),
            child: Column(
              children: [
                Slider(
                  value: themeState.textScaleFactor,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  label: '${(themeState.textScaleFactor * 100).round()}%',
                  onChanged: (value) => themeNotifier.setTextScaleFactor(value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('settings.theme.text_small'.tr()),
                    Text('settings.theme.text_large'.tr()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Theme Preview
          _buildSection(
            title: 'settings.theme.preview'.tr(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings.theme.preview_title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'settings.theme.preview_subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () {},
                        child: Text('settings.theme.preview_button'.tr()),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text('settings.theme.preview_button'.tr()),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: Text('settings.theme.preview_button'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(
    BuildContext context, {
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
