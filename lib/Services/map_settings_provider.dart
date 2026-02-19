import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared state for map settings across Settings and Map screens.
class MapSettingsProvider extends ChangeNotifier {
  static const String _mapTypeKey = 'map_type';
  static const String _showResolvedKey = 'map_show_resolved';

  MapType _mapType = MapType.normal;
  bool _showResolved = true;

  MapSettingsProvider() {
    _load();
  }

  MapType get mapType => _mapType;
  bool get showResolved => _showResolved;

  /// String label for UI display
  String get mapTypeLabel {
    switch (_mapType) {
      case MapType.hybrid:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      default:
        return 'Normal';
    }
  }

  Future<void> setMapType(String type) async {
    switch (type) {
      case 'Satellite':
        _mapType = MapType.hybrid;
        break;
      case 'Terrain':
        _mapType = MapType.terrain;
        break;
      default:
        _mapType = MapType.normal;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapTypeKey, type);
  }

  Future<void> setShowResolved(bool value) async {
    _showResolved = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showResolvedKey, value);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final typeStr = prefs.getString(_mapTypeKey) ?? 'Normal';
    _showResolved = prefs.getBool(_showResolvedKey) ?? true;
    switch (typeStr) {
      case 'Satellite':
        _mapType = MapType.hybrid;
        break;
      case 'Terrain':
        _mapType = MapType.terrain;
        break;
      default:
        _mapType = MapType.normal;
    }
    notifyListeners();
  }
}
