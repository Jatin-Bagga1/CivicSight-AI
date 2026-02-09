import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../Models/user_model.dart';
import '../Services/auth_service.dart';

/// ProfileSetup ViewModel - Manages profile setup screen state
class ProfileSetupViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Form fields
  String _fullName = '';
  String _phone = '';
  UserRole? _selectedRole;

  // State
  bool _isLoading = false;
  String? _errorMessage;

  ProfileSetupViewModel() {
    // Pre-fill from existing user data if available
    final user = _authService.currentUser;
    if (user != null) {
      _fullName = user.fullName;
      _phone = user.phone ?? '';
      _selectedRole = user.role;
    }
  }

  // Getters
  String get fullName => _fullName;
  String get phone => _phone;
  UserRole? get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _authService.currentUser;

  // Setters
  void setFullName(String value) {
    _fullName = value.trim();
  }

  void setPhone(String value) {
    _phone = value.trim();
  }

  void setRole(UserRole role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    HapticFeedback.selectionClick();
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Save profile to Firestore
  Future<bool> saveProfile() async {
    if (_isLoading) return false;

    // Validate
    if (_fullName.isEmpty) {
      _setError('Please enter your full name');
      return false;
    }

    if (_fullName.length < 2) {
      _setError('Name must be at least 2 characters');
      return false;
    }

    if (_selectedRole == null) {
      _setError('Please select your role');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateUserProfile(
        fullName: _fullName,
        role: _selectedRole!,
        phone: _phone.isNotEmpty ? _phone : null,
      );

      if (result.success) {
        HapticFeedback.lightImpact();
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Failed to save profile');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

}
