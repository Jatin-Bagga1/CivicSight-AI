import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's theme mode (light, dark, auto).
/// Persists the user's preference to SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';

  /// Current theme mode string: 'light', 'dark', or 'auto'
  String _themeMode = 'auto';

  ThemeProvider() {
    _loadPreference();
  }

  String get themeMode => _themeMode;

  /// Returns the Flutter ThemeMode based on user preference.
  ThemeMode get effectiveThemeMode {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode and persist.
  Future<void> setThemeMode(String mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }

  /// Load saved preference on startup.
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getString(_key) ?? 'auto';
    notifyListeners();
  }
}
