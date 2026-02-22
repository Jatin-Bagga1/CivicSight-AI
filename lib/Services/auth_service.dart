import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user_model.dart' as models;
import 'supabase_service.dart';

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final models.UserModel? user;
  final String? errorMessage;
  final AuthErrorType? errorType;
  final bool needsProfileSetup;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.errorType,
    this.needsProfileSetup = false,
  });

  factory AuthResult.success(
    models.UserModel user, {
    bool needsProfileSetup = false,
  }) {
    return AuthResult(
      success: true,
      user: user,
      needsProfileSetup: needsProfileSetup,
    );
  }

  factory AuthResult.failure(String message, {AuthErrorType? errorType}) {
    return AuthResult(
      success: false,
      errorMessage: message,
      errorType: errorType,
    );
  }
}

/// Error types for authentication
enum AuthErrorType {
  invalidEmail,
  invalidPassword,
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  tooManyRequests,
  userDisabled,
  unknown,
}

/// Authentication Service - Handles all authentication operations with Firebase
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SupabaseService _supabase = SupabaseService();
  models.UserModel? _currentUser;

  // SharedPreferences keys
  static const String _userIdKey = 'user_id';
  static const String _lastActivityKey = 'last_activity_timestamp';
  static const int _inactivityPeriodDays = 60; // 2 months

  /// Get current authenticated user
  models.UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user needs profile setup
  bool get needsProfileSetup =>
      _currentUser != null && !_currentUser!.isProfileComplete;

  /// Get Firebase Auth instance
  FirebaseAuth get firebaseAuth => _firebaseAuth;

  /// Initialize auth service and check existing session
  Future<void> initialize() async {
    try {
      final User? firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null) {
        // Check if session is still valid (not expired)
        final isSessionValid = await _checkSessionValidity();

        if (isSessionValid) {
          // Update last activity
          await _updateLastActivity();

          // Check Firestore for user profile
          _currentUser = await _getOrCreateFirestoreUser(firebaseUser);
        } else {
          // Session expired, logout
          await logout();
        }
      }
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  /// Check if the session is still valid (not inactive for 2 months)
  Future<bool> _checkSessionValidity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityTimestamp = prefs.getInt(_lastActivityKey);

      if (lastActivityTimestamp == null) {
        return false;
      }

      final lastActivity = DateTime.fromMillisecondsSinceEpoch(
        lastActivityTimestamp,
      );
      final now = DateTime.now();
      final difference = now.difference(lastActivity).inDays;

      return difference < _inactivityPeriodDays;
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  /// Update last activity timestamp in both SharedPreferences and Supabase
  Future<void> _updateLastActivity() async {
    try {
      final now = DateTime.now();

      // Run SharedPreferences and Supabase updates in parallel
      final futures = <Future>[
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setInt(_lastActivityKey, now.millisecondsSinceEpoch),
        ),
      ];

      // Update Supabase if user is logged in
      if (_currentUser != null) {
        futures.add(_supabase.updateLastLogin(_currentUser!.uid));
      }

      await Future.wait(futures);
    } catch (e) {
      print('Error updating last activity: $e');
    }
  }

  /// Check if user exists in Supabase, create if not, return UserModel
  Future<models.UserModel> _getOrCreateFirestoreUser(User firebaseUser) async {
    final existing = await _supabase.getUser(firebaseUser.uid);

    if (existing != null) {
      // User exists - return existing profile
      return existing;
    } else {
      // User does NOT exist - create new profile with basic info
      final newUser = _userModelFromFirebaseUser(firebaseUser);

      // Save to Supabase
      await _supabase.upsertUser(newUser);

      return newUser;
    }
  }

  /// Update user profile in Supabase (called from ProfileSetupScreen)
  Future<AuthResult> updateUserProfile({
    required String fullName,
    required models.UserRole role,
    String? phone,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.failure('No user logged in');
      }

      if (fullName.trim().isEmpty) {
        return AuthResult.failure('Full name is required');
      }

      final now = DateTime.now();

      // Update Supabase row
      await _supabase.updateUser(_currentUser!.uid, {
        'full_name': fullName.trim(),
        'role': role.name,
        'phone': phone?.trim(),
      });

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        fullName: fullName.trim(),
        role: role,
        phone: phone?.trim(),
        updatedAt: now,
      );

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure(
        'Failed to update profile. Please try again.',
        errorType: AuthErrorType.unknown,
      );
    }
  }

  /// Convert Firebase User to UserModel (for new users without profile)
  models.UserModel _userModelFromFirebaseUser(
    User firebaseUser, {
    models.UserRole role = models.UserRole.citizen,
    String? fullName,
    String? phone,
  }) {
    final now = DateTime.now();
    return models.UserModel(
      uid: firebaseUser.uid,
      role: role,
      fullName: fullName ?? firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: phone,
      status: models.UserStatus.active,
      createdAt: firebaseUser.metadata.creationTime ?? now,
      updatedAt: now,
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
      authProvider: _getAuthProvider(firebaseUser),
    );
  }

  /// Determine auth provider from Firebase user
  models.AuthProvider _getAuthProvider(User firebaseUser) {
    if (firebaseUser.providerData.isEmpty) {
      return models.AuthProvider.email;
    }

    final providerId = firebaseUser.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return models.AuthProvider.google;
      case 'facebook.com':
        return models.AuthProvider.facebook;
      case 'microsoft.com':
        return models.AuthProvider.microsoft;
      case 'phone':
        return models.AuthProvider.phone;
      default:
        return models.AuthProvider.email;
    }
  }

  /// Login with email and password
  Future<AuthResult> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty) {
        return AuthResult.failure(
          'Please enter your email address',
          errorType: AuthErrorType.invalidEmail,
        );
      }

      if (!_isValidEmail(email)) {
        return AuthResult.failure(
          'Please enter a valid email address',
          errorType: AuthErrorType.invalidEmail,
        );
      }

      if (password.isEmpty) {
        return AuthResult.failure(
          'Please enter your password',
          errorType: AuthErrorType.invalidPassword,
        );
      }

      if (password.length < 6) {
        return AuthResult.failure(
          'Password must be at least 6 characters',
          errorType: AuthErrorType.weakPassword,
        );
      }

      // Firebase Authentication
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        // Check Firestore: get existing user or create new
        _currentUser = await _getOrCreateFirestoreUser(credential.user!);

        // Update last activity
        await _updateLastActivity();

        // Check if profile needs setup
        final needsSetup = !_currentUser!.isProfileComplete;

        return AuthResult.success(_currentUser!, needsProfileSetup: needsSetup);
      }

      return AuthResult.failure('Login failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
        errorType: AuthErrorType.unknown,
      );
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required models.UserRole role,
    String? phone,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty) {
        return AuthResult.failure(
          'Please enter your email address',
          errorType: AuthErrorType.invalidEmail,
        );
      }

      if (!_isValidEmail(email)) {
        return AuthResult.failure(
          'Please enter a valid email address',
          errorType: AuthErrorType.invalidEmail,
        );
      }

      if (password.isEmpty) {
        return AuthResult.failure(
          'Please enter your password',
          errorType: AuthErrorType.invalidPassword,
        );
      }

      if (password.length < 6) {
        return AuthResult.failure(
          'Password must be at least 6 characters',
          errorType: AuthErrorType.weakPassword,
        );
      }

      // Firebase Authentication - Create user
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        final firebaseUser = credential.user!;

        // Update display name in Firebase Auth
        await firebaseUser.updateDisplayName(fullName);
        await firebaseUser.reload();

        // Create user profile in Supabase with full details
        final userModel = _userModelFromFirebaseUser(
          firebaseUser,
          role: role,
          fullName: fullName,
          phone: phone,
        );

        // Save to Supabase
        await _supabase.upsertUser(userModel);

        // Update last activity
        await _updateLastActivity();

        _currentUser = userModel;

        return AuthResult.success(_currentUser!);
      }

      return AuthResult.failure('Registration failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
        errorType: AuthErrorType.unknown,
      );
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        return AuthResult.failure(
          'Please enter your email address',
          errorType: AuthErrorType.invalidEmail,
        );
      }

      if (!_isValidEmail(email)) {
        return AuthResult.failure(
          'Please enter a valid email address',
          errorType: AuthErrorType.invalidEmail,
        );
      }

      // Firebase Password Reset
      await _firebaseAuth.sendPasswordResetEmail(email: email);

      return AuthResult(
        success: true,
        errorMessage: 'Password reset email sent successfully',
      );
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthError(e);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
        errorType: AuthErrorType.unknown,
      );
    }
  }

  /// Login with Google - Placeholder for future implementation
  Future<AuthResult> loginWithGoogle() async {
    // TODO: Implement Google Sign-In
    // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    // final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    // final credential = GoogleAuthProvider.credential(
    //   accessToken: googleAuth?.accessToken,
    //   idToken: googleAuth?.idToken,
    // );
    // return await FirebaseAuth.instance.signInWithCredential(credential);

    return AuthResult.failure(
      'Google Sign-In not implemented yet',
      errorType: AuthErrorType.unknown,
    );
  }

  /// Login with Facebook - Placeholder for future implementation
  Future<AuthResult> loginWithFacebook() async {
    // TODO: Implement Facebook Sign-In
    // final LoginResult loginResult = await FacebookAuth.instance.login();
    // final OAuthCredential credential = FacebookAuthProvider.credential(loginResult.accessToken!.token);
    // return await FirebaseAuth.instance.signInWithCredential(credential);

    return AuthResult.failure(
      'Facebook Sign-In not implemented yet',
      errorType: AuthErrorType.unknown,
    );
  }

  /// Login with Microsoft - Placeholder for future implementation
  Future<AuthResult> loginWithMicrosoft() async {
    // TODO: Implement Microsoft Sign-In

    return AuthResult.failure(
      'Microsoft Sign-In not implemented yet',
      errorType: AuthErrorType.unknown,
    );
  }

  /// Login with Phone - Placeholder for future implementation
  Future<AuthResult> loginWithPhone({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    // TODO: Implement Phone Sign-In
    // await FirebaseAuth.instance.verifyPhoneNumber(
    //   phoneNumber: phoneNumber,
    //   verificationCompleted: (credential) {},
    //   verificationFailed: (e) {},
    //   codeSent: (verificationId, resendToken) {},
    //   codeAutoRetrievalTimeout: (verificationId) {},
    // );

    return AuthResult.failure(
      'Phone Sign-In not implemented yet',
      errorType: AuthErrorType.unknown,
    );
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Clear session data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityKey);
      await prefs.remove(_userIdKey);

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Error during logout: $e');
      // Clear user anyway even if Firebase signout fails
      _currentUser = null;
    }
  }

  /// Cached email regex for validation
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Validate email format
  bool _isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }

  /// Handle Firebase authentication errors
  AuthResult _handleFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthResult.failure(
          'No user found with this email',
          errorType: AuthErrorType.userNotFound,
        );
      case 'wrong-password':
        return AuthResult.failure(
          'Incorrect password',
          errorType: AuthErrorType.wrongPassword,
        );
      case 'email-already-in-use':
        return AuthResult.failure(
          'Email is already registered',
          errorType: AuthErrorType.emailAlreadyInUse,
        );
      case 'weak-password':
        return AuthResult.failure(
          'Password is too weak. Use at least 6 characters',
          errorType: AuthErrorType.weakPassword,
        );
      case 'too-many-requests':
        return AuthResult.failure(
          'Too many attempts. Please try again later',
          errorType: AuthErrorType.tooManyRequests,
        );
      case 'user-disabled':
        return AuthResult.failure(
          'This account has been disabled',
          errorType: AuthErrorType.userDisabled,
        );
      case 'invalid-email':
        return AuthResult.failure(
          'Invalid email address',
          errorType: AuthErrorType.invalidEmail,
        );
      case 'operation-not-allowed':
        return AuthResult.failure(
          'Operation not allowed. Please contact support',
          errorType: AuthErrorType.unknown,
        );
      case 'network-request-failed':
        return AuthResult.failure(
          'Network error. Please check your connection',
          errorType: AuthErrorType.networkError,
        );
      default:
        return AuthResult.failure(
          'Authentication failed: ${error.message ?? "Unknown error"}',
          errorType: AuthErrorType.unknown,
        );
    }
  }
}
