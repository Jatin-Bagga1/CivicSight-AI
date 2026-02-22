import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/citizen_profile_model.dart';
import '../Services/supabase_service.dart';
import '../Services/auth_service.dart';
import '../Services/accent_color_provider.dart';

/// ViewModel for the Citizen Profile editing screen.
class CitizenProfileViewModel extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  CitizenProfile? _profile;
  CitizenProfile? get profile => _profile;

  bool _loading = true;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Editable fields
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController provinceCtrl = TextEditingController();
  final TextEditingController zipCodeCtrl = TextEditingController();

  // Local-only accent colour (stored as raw ARGB hex int)
  int _accentColorHex = 0xFF1A4D94; // default = primaryBlue
  int get accentColorHex => _accentColorHex;
  Color get accentColor => Color(_accentColorHex);

  // ─── Lifecycle ───

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) {
        _errorMessage = 'No authenticated user.';
        _loading = false;
        notifyListeners();
        return;
      }

      _profile = await _supabase.getCitizenProfile(uid);

      // Populate controllers from existing data (null-safe)
      addressCtrl.text = _profile?.address ?? '';
      cityCtrl.text = _profile?.city ?? '';
      provinceCtrl.text = _profile?.province ?? '';
      zipCodeCtrl.text = _profile?.zipCode ?? '';

      // Load locally-stored accent colour
      final prefs = await SharedPreferences.getInstance();
      final storedColor = prefs.getInt('citizen_accent_color');
      if (storedColor != null) {
        _accentColorHex = storedColor;
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    }

    _loading = false;
    notifyListeners();
  }

  // ─── Save / Upsert ───

  Future<bool> save() async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = AuthService().currentUser?.uid;
      if (uid == null) {
        _errorMessage = 'No authenticated user.';
        _saving = false;
        notifyListeners();
        return false;
      }

      final updated = CitizenProfile(
        citizenId: uid,
        address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
        city: cityCtrl.text.trim().isEmpty ? null : cityCtrl.text.trim(),
        province: provinceCtrl.text.trim().isEmpty ? null : provinceCtrl.text.trim(),
        zipCode: zipCodeCtrl.text.trim().isEmpty ? null : zipCodeCtrl.text.trim(),
      );

      await _supabase.upsertCitizenProfile(updated);

      // Reload so timestamps are fresh
      _profile = await _supabase.getCitizenProfile(uid);

      // Persist accent colour locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('citizen_accent_color', _accentColorHex);

      _saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile: $e';
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Accent colour ───

  /// Optional reference to the app-level accent provider so changes
  /// are reflected across all screens immediately.
  AccentColorProvider? _accentProvider;
  void attachAccentProvider(AccentColorProvider provider) {
    _accentProvider = provider;
  }

  void setAccentColor(int colorHex) {
    _accentColorHex = colorHex;
    notifyListeners();
    // Sync with app-level provider so other screens update instantly
    _accentProvider?.update(colorHex);
    // Persist immediately so it survives navigation
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('citizen_accent_color', colorHex);
    });
  }

  // ─── Cleanup ───

  @override
  void dispose() {
    addressCtrl.dispose();
    cityCtrl.dispose();
    provinceCtrl.dispose();
    zipCodeCtrl.dispose();
    super.dispose();
  }
}
