import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/user_model.dart';
import '../Models/citizen_profile_model.dart';

/// Service that handles all Supabase database operations.
/// Auth is handled by Firebase; Supabase is used only for data storage.
class SupabaseService {
  // Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  /// Supabase client accessor
  SupabaseClient get _client => Supabase.instance.client;

  // ════════════════════════════════════════════
  // ─── USER OPERATIONS ───
  // ════════════════════════════════════════════

  /// Fetch a user by their Firebase UID.
  /// Returns null if not found.
  Future<UserModel?> getUser(String uid) async {
    final response = await _client
        .from('users')
        .select()
        .eq('uid', uid)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromSupabase(response);
  }

  /// Insert a new user row. Uses upsert so it won't fail if the row
  /// already exists (e.g. re-registration edge cases).
  Future<void> upsertUser(UserModel user) async {
    await _client.from('users').upsert(user.toSupabase());
  }

  /// Partially update user fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('uid', uid);
  }

  /// Update last login timestamp for a user.
  Future<void> updateLastLogin(String uid) async {
    await _client
        .from('users')
        .update({'last_login_at': DateTime.now().toUtc().toIso8601String()})
        .eq('uid', uid);
  }

  // ════════════════════════════════════════════
  // ─── REPORT OPERATIONS ───
  // ════════════════════════════════════════════

  /// Insert a new report. Returns the inserted row (with generated id).
  Future<Map<String, dynamic>> addReport(Map<String, dynamic> data) async {
    final response = await _client
        .from('reports')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Fetch all reports for a given user, newest first.
  Future<List<Map<String, dynamic>>> getUserReports(String uid) async {
    final response = await _client
        .from('reports')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update report status.
  Future<void> updateReportStatus(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  // ════════════════════════════════════════════
  // ─── CITIZEN PROFILE OPERATIONS ───
  // ════════════════════════════════════════════

  /// Fetch a citizen profile by Firebase UID.
  /// Returns null if no profile exists yet.
  Future<CitizenProfile?> getCitizenProfile(String uid) async {
    final response = await _client
        .from('citizen_profiles')
        .select()
        .eq('citizen_id', uid)
        .maybeSingle();

    if (response == null) return null;
    return CitizenProfile.fromSupabase(response);
  }

  /// Insert or update a citizen profile (upsert on citizen_id PK).
  Future<void> upsertCitizenProfile(CitizenProfile profile) async {
    await _client.from('citizen_profiles').upsert(profile.toSupabase());
  }

  /// Partially update citizen profile fields.
  Future<void> updateCitizenProfile(
      String uid, Map<String, dynamic> data) async {
    await _client
        .from('citizen_profiles')
        .update(data)
        .eq('citizen_id', uid);
  }
}
