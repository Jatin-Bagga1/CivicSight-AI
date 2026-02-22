import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

/// App-level provider that exposes the user's chosen accent colour.
/// Loads from SharedPreferences on init and notifies listeners on change.
class AccentColorProvider extends ChangeNotifier {
  static const String _prefKey = 'citizen_accent_color';

  int _hex = 0xFF1A4D94; // default = AppColors.primaryBlue
  int get hex => _hex;
  Color get color => Color(_hex);

  AccentColorProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefKey);
    if (stored != null && stored != _hex) {
      _hex = stored;
      notifyListeners();
    }
  }

  /// Call this whenever the user picks a new colour (e.g. from profile screen).
  void update(int colorHex) {
    if (_hex == colorHex) return;
    _hex = colorHex;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_prefKey, colorHex);
    });
  }

  /// Re-read from disk (useful after returning from profile screen).
  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefKey);
    if (stored != null && stored != _hex) {
      _hex = stored;
      notifyListeners();
    }
  }
}
