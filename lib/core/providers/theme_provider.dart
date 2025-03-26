import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeState {
  final bool isDarkMode;
  final Color primaryColor;
  final double textScaleFactor;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  ThemeState({
    required this.isDarkMode,
    required this.primaryColor,
    required this.textScaleFactor,
  })  : lightTheme =
            _createThemeData(Brightness.light, primaryColor, textScaleFactor),
        darkTheme =
            _createThemeData(Brightness.dark, primaryColor, textScaleFactor);

  ThemeState copyWith({
    bool? isDarkMode,
    Color? primaryColor,
    double? textScaleFactor,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColor: primaryColor ?? this.primaryColor,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }

  static ThemeData _createThemeData(
      Brightness brightness, Color primaryColor, double textScaleFactor) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16 * textScaleFactor),
        bodyMedium: TextStyle(fontSize: 14 * textScaleFactor),
        titleLarge: TextStyle(fontSize: 22 * textScaleFactor),
        titleMedium: TextStyle(fontSize: 16 * textScaleFactor),
      ),
    );
  }

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;
  static const String _darkModeKey = 'isDarkMode';
  static const String _primaryColorKey = 'primaryColor';
  static const String _textScaleFactorKey = 'textScaleFactor';

  static const List<Color> predefinedColors = [
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.red,
    Colors.indigo,
    Color(0xFF55C255), // Telegram Green
    Color(0xFF2AABEE), // Telegram Blue
  ];

  ThemeNotifier(this._prefs)
      : super(ThemeState(
          isDarkMode: _prefs.getBool(_darkModeKey) ?? false,
          primaryColor:
              Color(_prefs.getInt(_primaryColorKey) ?? Colors.blue.value),
          textScaleFactor: _prefs.getDouble(_textScaleFactorKey) ?? 1.0,
        ));

  void toggleTheme() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    _prefs.setBool(_darkModeKey, state.isDarkMode);
  }

  void setPrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
    _prefs.setInt(_primaryColorKey, color.value);
  }

  void setTextScaleFactor(double factor) {
    state = state.copyWith(textScaleFactor: factor);
    _prefs.setDouble(_textScaleFactorKey, factor);
  }
}
