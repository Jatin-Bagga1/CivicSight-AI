/// User model representing authenticated user data
/// Database schema: users table in Supabase
class UserModel {
  /// Firebase UID - Primary Key (document ID in Firestore)
  final String uid;

  /// User role for authorization (citizen, worker)
  final UserRole role;

  /// Full name of the user
  final String fullName;

  /// Email address - stored for display and search
  final String email;

  /// Optional phone number
  final String? phone;

  /// User status: active, suspended
  final UserStatus status;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last profile update timestamp
  final DateTime updatedAt;

  /// Last login timestamp
  final DateTime? lastLoginAt;

  /// Authentication provider method
  final AuthProvider authProvider;

  /// Whether the user profile is complete (has fullName and role set)
  bool get isProfileComplete => fullName.isNotEmpty;

  UserModel({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.authProvider,
  });

  /// Create UserModel from Supabase row (snake_case columns)
  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'citizen'),
      fullName: data['full_name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      status: UserStatus.fromString(data['status'] ?? 'active'),
      createdAt: (data['created_at'] != null)
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: (data['updated_at'] != null)
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
      lastLoginAt: (data['last_login_at'] != null)
          ? DateTime.parse(data['last_login_at'])
          : null,
      authProvider: AuthProvider.fromString(data['auth_provider'] ?? 'email'),
    );
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'citizen'),
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      status: UserStatus.fromString(data['status'] ?? 'active'),
      createdAt: (data['createdAt'] != null)
          ? _parseDateTime(data['createdAt'])
          : DateTime.now(),
      updatedAt: (data['updatedAt'] != null)
          ? _parseDateTime(data['updatedAt'])
          : DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] != null)
          ? _parseDateTime(data['lastLoginAt'])
          : null,
      authProvider: AuthProvider.fromString(data['authProvider'] ?? 'email'),
    );
  }

  /// Create UserModel from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'citizen'),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      status: UserStatus.fromString(json['status'] ?? 'active'),
      createdAt: (json['createdAt'] != null)
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: (json['updatedAt'] != null)
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] != null)
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      authProvider: AuthProvider.fromString(json['authProvider'] ?? 'email'),
    );
  }

  /// Convert UserModel to Supabase row (snake_case columns)
  Map<String, dynamic> toSupabase() {
    return {
      'uid': uid,
      'role': role.name,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'auth_provider': authProvider.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
    };
  }

  /// Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role.name,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
      'authProvider': authProvider.name,
    };
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'role': role.name,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'authProvider': authProvider.name,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    UserRole? role,
    String? fullName,
    String? email,
    String? phone,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    AuthProvider? authProvider,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      authProvider: authProvider ?? this.authProvider,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, role: ${role.name}, status: ${status.name})';
  }

  /// Helper method to parse DateTime from Firestore Timestamp
  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
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
  citizen, // Civilian user
  worker; // Field worker

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) =>
          e.name == value.toLowerCase() ||
          (value.toLowerCase() == 'civilian' && e == UserRole.citizen) ||
          (value.toLowerCase() == 'field_worker' && e == UserRole.worker),
      orElse: () => UserRole.citizen,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.worker:
        return 'Field Worker';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.citizen:
        return '👤';
      case UserRole.worker:
        return '🔧';
    }
  }
}

/// Enum for user status
enum UserStatus {
  active,
  suspended;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }
}
