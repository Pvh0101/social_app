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
        context.setLocale(
          context.locale.languageCode == 'en'
              ? const Locale('vi')
              : const Locale('en'),
        );
      },
      child: Text(context.locale.languageCode == 'en' ? '🇻🇳 VI' : '🇺🇸 EN',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          )),
    );
  }
}
