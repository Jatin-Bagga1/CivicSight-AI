import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to call the Supabase Edge Function for AI report analysis.
///
/// Flow:
///   1. Flutter uploads image to Firebase Storage → gets public URL
///   2. Sends image_url + description to this edge function
///   3. Edge function fetches categories from DB, calls Gemini, returns classification
///   4. Flutter uses the result to store the report with AI-classified data
class AIAnalysisService {
  // Singleton
  static final AIAnalysisService _instance = AIAnalysisService._internal();
  factory AIAnalysisService() => _instance;
  AIAnalysisService._internal();

  /// Your Supabase project URL
  static const String _supabaseUrl = 'https://lcyryfzfiduslebpffje.supabase.co';

  /// Your Supabase anon key (safe to use client-side — RLS protects data)
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjeXJ5ZnpmaWR1c2xlYnBmZmplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MzQ1NTYsImV4cCI6MjA4NzExMDU1Nn0.-xfC_wtwXYRdc4MCBb6VfSjos2pPiE_xo31YCF1_vqg';

  /// Calls the `analyze-report` Edge Function.
  ///
  /// [imageUrl] — Public Firebase Storage URL of the uploaded image.
  /// [description] — Optional citizen description of the issue.
  ///
  /// Returns a [ReportClassification] on success.
  /// Throws an [Exception] on failure.
  Future<ReportClassification> analyzeReport({
    required String imageUrl,
    String? description,
  }) async {
    final url = Uri.parse('$_supabaseUrl/functions/v1/analyze-report');

    final body = jsonEncode({
      'image_url': imageUrl,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_supabaseAnonKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['error'] ?? 'AI analysis failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'AI analysis returned unsuccessful');
    }

    return ReportClassification.fromJson(json['classification']);
  }

  /// Calls the `store-report` Edge Function to save report + location + image.
  ///
  /// Returns `{report_id, report_number}` on success.
  Future<Map<String, dynamic>> storeReport({
    required String citizenId,
    required String description,
    required String imageUrl,
    required Map<String, dynamic> classification,
    required Map<String, dynamic> location,
  }) async {
    final url = Uri.parse('$_supabaseUrl/functions/v1/store-report');

    final body = jsonEncode({
      'citizen_id': citizenId,
      'description': description,
      'image_url': imageUrl,
      'classification': classification,
      'location': location,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_supabaseAnonKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['error'] ?? 'Store report failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Store report returned unsuccessful');
    }

    return {
      'report_id': json['report_id'],
      'report_number': json['report_number'],
    };
  }
}

/// Structured AI classification result matching the Edge Function response.
class ReportClassification {
  final int categoryId;
  final String categoryName;
  final String categoryGroup;
  final int severity;
  final double confidence;
  final String aiDescription;
  final int dueDateDays;
  final String suggestedPriority;
  final bool isValidReport;
  final String? rejectionReason;
  final bool imageMatchesDescription;

  const ReportClassification({
    required this.categoryId,
    required this.categoryName,
    required this.categoryGroup,
    required this.severity,
    required this.confidence,
    required this.aiDescription,
    required this.dueDateDays,
    required this.suggestedPriority,
    required this.isValidReport,
    this.rejectionReason,
    required this.imageMatchesDescription,
  });

  factory ReportClassification.fromJson(Map<String, dynamic> json) {
    return ReportClassification(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      categoryGroup: json['category_group'] as String,
      severity: json['severity'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      aiDescription: json['ai_description'] as String,
      dueDateDays: json['due_date_days'] as int,
      suggestedPriority: json['suggested_priority'] as String,
      isValidReport: json['is_valid_report'] as bool? ?? true,
      rejectionReason: json['rejection_reason'] as String?,
      imageMatchesDescription:
          json['image_matches_description'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'category_name': categoryName,
    'category_group': categoryGroup,
    'severity': severity,
    'confidence': confidence,
    'ai_description': aiDescription,
    'due_date_days': dueDateDays,
    'suggested_priority': suggestedPriority,
    'is_valid_report': isValidReport,
    'rejection_reason': rejectionReason,
    'image_matches_description': imageMatchesDescription,
  };

  /// Whether the report was rejected by AI.
  bool get isRejected => !isValidReport;

  /// Calculate the actual due date from today.
  DateTime get dueDate =>
      DateTime.now().toUtc().add(Duration(days: dueDateDays));

  @override
  String toString() =>
      'ReportClassification($categoryName, severity=$severity, confidence=$confidence, valid=$isValidReport)';
}
