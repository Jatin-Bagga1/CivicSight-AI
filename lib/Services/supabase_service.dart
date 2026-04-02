import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../Models/user_model.dart';
import '../Models/citizen_profile_model.dart';
import '../Models/category_model.dart';

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

  /// Fetch a single report by ID with its relations
  Future<Map<String, dynamic>?> getReportById(String reportId) async {
    final response = await _client
        .from('reports')
        .select('*, report_locations(*), report_images(*)')
        .eq('id', reportId)
        .maybeSingle();
    return response;
  }

  /// Fetch all reports for a given citizen, newest first.
  /// Includes report_locations and report_images via joins.
  Future<List<Map<String, dynamic>>> getUserReports(String uid) async {
    final response = await _client
        .from('reports')
        .select('*, report_locations(*), report_images(*)')
        .eq('citizen_id', uid)
        .order('reported_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update report status.
  Future<void> updateReportStatus(String reportId, String status) async {
    await _client.from('reports').update({'status': status}).eq('id', reportId);
  }

  /// Fetch all reports with locations (for map pins).
  Future<List<Map<String, dynamic>>> getAllReportsWithLocations() async {
    final response = await _client
        .from('reports')
        .select('*, report_locations(*), report_images(*)')
        .order('reported_at', ascending: false)
        .limit(200);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all tasks assigned to a specific worker
  Future<List<Map<String, dynamic>>> getAssignedTasks(String workerId) async {
    debugPrint('getAssignedTasks: querying worker_assignments for worker_id=$workerId');
    final response = await _client
        .from('worker_assignments')
        .select(
          'assignment_status, assigned_at, started_at, completed_at, report:reports(*, report_locations(*), report_images(*))',
        )
        .eq('worker_id', workerId)
        .inFilter('assignment_status', ['assigned', 'in_progress', 'completed', 'resolved'])
        .order('assigned_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response);
    debugPrint('getAssignedTasks: got ${rows.length} rows');
    return rows
        .map((row) {
          final report = row['report'];
          if (report is! Map<String, dynamic>) return null;

          // The worker portal UI expects status on report payload.
          final assignmentStatus = row['assignment_status'] as String?;
          report['status'] = assignmentStatus == 'completed'
              ? 'resolved'
              : (assignmentStatus ?? report['status']);
          report['assigned_at'] = row['assigned_at'];
          report['started_at'] = row['started_at'];
          report['completed_at'] = row['completed_at'];
          return report;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Update report status with optional resolved_at timestamp
  Future<void> updateTaskStatus(
    String reportId,
    String status, {
    required String workerId,
    String? note,
    String? proofImageUrl,
    double? latitude,
    double? longitude,
    DateTime? eventTime,
  }) async {
    final now = (eventTime ?? DateTime.now()).toUtc().toIso8601String();

    final assignment = await _client
        .from('worker_assignments')
        .select('id, assignment_status')
        .eq('report_id', reportId)
        .eq('worker_id', workerId)
        .single();

    final assignmentId = assignment['id'];
    final normalizedStatus = status == 'completed' ? 'resolved' : status;

    final assignmentUpdate = <String, dynamic>{
      'assignment_status': normalizedStatus,
      'last_update_at': now,
      if (normalizedStatus == 'in_progress') 'started_at': now,
      if (normalizedStatus == 'resolved') 'completed_at': now,
      if (note != null && note.trim().isNotEmpty) 'worker_note': note.trim(),
    };

    await _client
        .from('worker_assignments')
        .update(assignmentUpdate)
        .eq('id', assignmentId);

    final reportUpdate = <String, dynamic>{
      'status': normalizedStatus,
      'updated_at': now,
      if (normalizedStatus == 'resolved') 'resolved_at': now,
    };

    await _client.from('reports').update(reportUpdate).eq('id', reportId);
  }

  /// Add a proof image to a report
  Future<void> addProofImage(String reportId, String imageUrl) async {
    await _client.from('report_images').insert({
      'report_id': reportId,
      'image_url': imageUrl,
      'is_primary': false,
      'ai_analyzed': false,
    });
  }

  /// Realtime stream for worker assignment changes.
  Stream<List<Map<String, dynamic>>> streamWorkerAssignments(String workerId) {
    return _client
        .from('worker_assignments')
        .stream(primaryKey: ['id'])
        .eq('worker_id', workerId);
  }

  // ════════════════════════════════════════════
  // ─── WORKER SHIFT OPERATIONS ───
  // ════════════════════════════════════════════

  /// Fetch current shift status for a worker from worker_profiles.
  /// Returns one of: on_duty, break, off_duty. Defaults to off_duty.
  Future<String> getLatestWorkerShiftStatus(String workerId) async {
    try {
      final response = await _client
          .from('worker_profiles')
          .select('shift_status')
          .eq('worker_id', workerId)
          .maybeSingle();

      if (response == null) return 'off_duty';
      return (response['shift_status'] as String?) ?? 'off_duty';
    } catch (_) {
      return 'off_duty';
    }
  }

  /// Update current shift status on worker_profiles.
  Future<void> logWorkerShiftStatus(
    String workerId,
    String shiftStatus, {
    String? note,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await _client.from('worker_profiles').upsert({
        'worker_id': workerId,
        'shift_status': shiftStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'worker_id');
    } catch (_) {
      // silently fail if column not yet migrated
    }
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

  // ════════════════════════════════════════════
  // ─── COMMENTS OPERATIONS ───
  // ════════════════════════════════════════════

  /// Fetch all comments for a report, newest last.
  Future<List<Map<String, dynamic>>> getComments(String reportId) async {
    final response = await _client
        .from('comments')
        .select()
        .eq('report_id', reportId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a new comment to a report.
  Future<Map<String, dynamic>> addComment({
    required String reportId,
    required String userId,
    required String content,
    bool isInternal = false,
  }) async {
    final response = await _client.from('comments').insert({
      'report_id': reportId,
      'user_id': userId,
      'content': content,
      'is_internal': isInternal,
    }).select().single();
    return response;
  }

  // ════════════════════════════════════════════
  // ─── CATEGORY / WORKER PREFERENCE OPERATIONS ───
  // ════════════════════════════════════════════

  /// Fetch all active categories.
  Future<List<Category>> getAllCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('category_group')
        .order('name');
    return (response as List)
        .map((row) => Category.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a worker's category preferences.
  Future<List<WorkerCategoryPreference>> getWorkerCategoryPreferences(
      String workerId) async {
    final response = await _client
        .from('worker_category_preferences')
        .select()
        .eq('worker_id', workerId);
    return (response as List)
        .map((row) =>
            WorkerCategoryPreference.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  /// Replace a worker's category preferences with the given category IDs.
  Future<void> saveWorkerCategoryPreferences(
      String workerId, List<int> categoryIds) async {
    // Delete existing preferences
    await _client
        .from('worker_category_preferences')
        .delete()
        .eq('worker_id', workerId);

    // Insert new preferences
    if (categoryIds.isNotEmpty) {
      final rows = categoryIds
          .asMap()
          .entries
          .map((e) => {
                'worker_id': workerId,
                'category_id': e.value,
                'priority_rank': e.key + 1,
              })
          .toList();
      await _client.from('worker_category_preferences').insert(rows);
    }
  }

  /// Realtime stream for comments on a specific report.
  RealtimeChannel subscribeToComments(
    String reportId,
    void Function(Map<String, dynamic> newComment) onInsert,
  ) {
    return _client
        .channel('comments:$reportId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'report_id',
            value: reportId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
  }
}
