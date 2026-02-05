import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../Models/user_model.dart';
import '../Services/auth_service.dart';

/// Login ViewModel - Manages login screen state and business logic
class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Form fields
  String _email = '';
  String _password = '';
  
  // State
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  UserModel? _user;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get isPasswordVisible => _isPasswordVisible;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  // Setters with validation - optimized to only notify when value changes
  void setEmail(String value) {
    final trimmed = value.trim();
    if (_email == trimmed) return;
    _email = trimmed;
    _clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    if (_password == value) return;
    _password = value;
    _clearError();
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login() async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithEmailPassword(
        email: _email,
        password: _password,
      );

      if (result.success && result.user != null) {
        _user = result.user;
        HapticFeedback.lightImpact();
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Login failed. Please try again.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email
  Future<bool> forgotPassword() async {
    if (_email.isEmpty) {
      _setError('Please enter your email address first');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.sendPasswordResetEmail(_email);

      _setLoading(false);
      
      if (result.success) {
        return true;
      } else {
        _setError(result.errorMessage ?? 'Failed to send reset email');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithGoogle();

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Google login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Login with Facebook
  Future<bool> loginWithFacebook() async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithFacebook();

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Facebook login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Login with Microsoft
  Future<bool> loginWithMicrosoft() async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithMicrosoft();

      if (result.success && result.user != null) {
        _user = result.user;
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage ?? 'Microsoft login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _email = '';
    _password = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all fields
  void clearFields() {
    _email = '';
    _password = '';
    _errorMessage = null;
    _isPasswordVisible = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
