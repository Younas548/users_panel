import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // ---- Theme mode ----
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() => setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);

  // ---- Primary seed color (NEW) ----
  Color _primarySeed = const Color(0xFF2563EB); // Ocean Blue default
  Color get primarySeed => _primarySeed;

  void setPrimarySeed(Color color) {
    if (_primarySeed.value == color.value) return;
    _primarySeed = color;
    notifyListeners();
  }
}
