/// User model representing authenticated user data
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final AuthProvider authProvider;
  final UserRole? userRole;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.authProvider,
    this.userRole,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Create UserModel from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      phoneNumber: json['phoneNumber'],
      authProvider: AuthProvider.fromString(json['authProvider'] ?? 'email'),
      userRole: json['userRole'] != null 
          ? UserRole.fromString(json['userRole']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider.name,
      'userRole': userRole?.name,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    AuthProvider? authProvider,
    UserRole? userRole,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, authProvider: ${authProvider.name}, userRole: ${userRole?.name})';
  }
}

/// Enum for authentication providers
enum AuthProvider {
  email,
  google,
  facebook,
  microsoft,
  phone;

  static AuthProvider fromString(String value) {
    return AuthProvider.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AuthProvider.email,
    );
  }
}

/// Enum for user roles - Used for authorization
enum UserRole {
  civilian,
  fieldWorker;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase() || 
             (value.toLowerCase() == 'field_worker' && e == UserRole.fieldWorker),
      orElse: () => UserRole.civilian,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.civilian:
        return 'Civilian';
      case UserRole.fieldWorker:
        return 'Field Worker';
    }
  }
}
