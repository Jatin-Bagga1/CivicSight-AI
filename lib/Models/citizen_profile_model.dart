/// Model representing a row in the `citizen_profiles` Supabase table.
class CitizenProfile {
  final String citizenId; // FK → users.uid
  final String? address;
  final String? city;
  final String? province;
  final String? zipCode;
  final int totalReports;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CitizenProfile({
    required this.citizenId,
    this.address,
    this.city,
    this.province,
    this.zipCode,
    this.totalReports = 0,
    this.createdAt,
    this.updatedAt,
  });

  // ─── Supabase serialisation ───

  factory CitizenProfile.fromSupabase(Map<String, dynamic> map) {
    return CitizenProfile(
      citizenId: map['citizen_id'] as String,
      address: map['address'] as String?,
      city: map['city'] as String?,
      province: map['province'] as String?,
      zipCode: map['zip_code'] as String?,
      totalReports: (map['total_reports'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Only the user-editable columns are sent on insert / update.
  Map<String, dynamic> toSupabase() {
    return {
      'citizen_id': citizenId,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (province != null) 'province': province,
      if (zipCode != null) 'zip_code': zipCode,
    };
  }

  CitizenProfile copyWith({
    String? address,
    String? city,
    String? province,
    String? zipCode,
    int? totalReports,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CitizenProfile(
      citizenId: citizenId,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      zipCode: zipCode ?? this.zipCode,
      totalReports: totalReports ?? this.totalReports,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
