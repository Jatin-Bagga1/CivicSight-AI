import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../Models/user_model.dart';
import '../Services/auth_service.dart';

/// SignUp ViewModel - Manages signup screen state and business logic
class SignUpViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Form fields
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _phone = '';
  UserRole? _selectedRole;
  
  // State
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  UserModel? _user;

  // Getters
  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get phone => _phone;
  UserRole? get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  // Setters - optimized to avoid unnecessary rebuilds
  void setName(String value) {
    _name = value.trim();
  }

  void setEmail(String value) {
    _email = value.trim();
  }

  void setPassword(String value) {
    _password = value;
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
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

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    HapticFeedback.selectionClick();
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

  /// Sign up with email and password
  Future<bool> signUp() async {
    if (_isLoading) return false;

    // Validate role selection
    if (_selectedRole == null) {
      _setError('Please select your role (Citizen or Field Worker)');
      return false;
    }

    // Validate password match
    if (_password != _confirmPassword) {
      _setError('Passwords do not match');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.registerWithEmailPassword(
        email: _email,
        password: _password,
        fullName: _name,
        role: _selectedRole!,
        phone: _phone.isNotEmpty ? _phone : null,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Sign up failed. Please try again.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Sign up with Google
  Future<bool> signUpWithGoogle() async {
    if (_isLoading) return false;

    if (_selectedRole == null) {
      _setError('Please select your role first');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithGoogle();

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Google sign up failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Sign up with Facebook
  Future<bool> signUpWithFacebook() async {
    if (_isLoading) return false;

    if (_selectedRole == null) {
      _setError('Please select your role first');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithFacebook();

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Facebook sign up failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Clear all fields
  void clearFields() {
    _name = '';
    _email = '';
    _password = '';
    _confirmPassword = '';
    _phone = '';
    _selectedRole = null;
    _errorMessage = null;
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    notifyListeners();
  }

}
