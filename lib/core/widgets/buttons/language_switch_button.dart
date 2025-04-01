import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Xác định ngôn ngữ tiếp theo (chỉ chuyển đổi giữa en và vi)
        final String currentLocale = context.locale.languageCode;
        late final Locale nextLocale;

        switch (currentLocale) {
          case 'en':
            nextLocale = const Locale('vi');
            break;
          case 'vi':
            nextLocale = const Locale('en');
            break;
          default:
            nextLocale = const Locale('en');
        }

        context.setLocale(nextLocale);
      },
      child: _getLanguageText(context),
    );
  }

  Widget _getLanguageText(BuildContext context) {
    final String currentLocale = context.locale.languageCode;
    String langText;

    switch (currentLocale) {
      case 'en':
        langText = '🇺🇸 EN';
        break;
      case 'vi':
        langText = '🇻🇳 VI';
        break;
      default:
        langText = '🇺🇸 EN';
    }

    return Text(
      langText,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
