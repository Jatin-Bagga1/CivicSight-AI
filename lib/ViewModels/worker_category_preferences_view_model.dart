import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/category_model.dart';
import '../Services/supabase_service.dart';

class WorkerCategoryPreferencesViewModel extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  List<Category> _allCategories = [];

  /// Maps categoryId → priority rank (1 = Low, 2 = Medium, 3 = High).
  Map<int, int> _priorities = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<Category> get allCategories => _allCategories;
  Map<int, int> get priorities => _priorities;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Priority label for display.
  static String priorityLabel(int rank) {
    switch (rank) {
      case 3:
        return 'High Priority';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  /// Color for the priority level.
  static Color priorityColor(int rank) {
    switch (rank) {
      case 3:
        return const Color(0xFFE53935); // red
      case 2:
        return const Color(0xFFFFA726); // amber
      default:
        return const Color(0xFF42A5F5); // blue
    }
  }

  /// Get priority for a category (defaults to 1).
  int getPriority(int categoryId) => _priorities[categoryId] ?? 1;

  WorkerCategoryPreferencesViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      final results = await Future.wait([
        _supabase.getAllCategories(),
        _supabase.getWorkerCategoryPreferences(uid),
      ]);

      _allCategories = results[0] as List<Category>;
      final prefs = results[1] as List<WorkerCategoryPreference>;

      if (prefs.isEmpty) {
        // Default: all categories selected with Medium priority
        for (final cat in _allCategories) {
          _priorities[cat.id] = 2;
        }
      } else {
        _priorities = {
          for (final p in prefs)
            p.categoryId: p.priorityRank.clamp(1, 3),
        };
      }
    } catch (e) {
      _errorMessage = 'Failed to load preferences: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set priority rank for a category (1–3).
  void setPriority(int categoryId, int rank) {
    _priorities[categoryId] = rank.clamp(1, 3);
    _successMessage = null;
    notifyListeners();
  }

  /// Remove a category from preferences.
  void removeCategory(int categoryId) {
    _priorities.remove(categoryId);
    _successMessage = null;
    notifyListeners();
  }

  /// Add a category back with default Low priority.
  void addCategory(int categoryId) {
    _priorities[categoryId] = 1;
    _successMessage = null;
    notifyListeners();
  }

  /// Toggle a category on/off.
  void toggleCategory(int categoryId) {
    if (_priorities.containsKey(categoryId)) {
      removeCategory(categoryId);
    } else {
      addCategory(categoryId);
    }
  }

  /// Validate: not all categories can share the same rank.
  String? validate() {
    if (_priorities.isEmpty) {
      return 'Please select at least one category.';
    }
    if (_priorities.length > 1) {
      final ranks = _priorities.values.toSet();
      if (ranks.length == 1) {
        return 'All categories cannot have the same priority. Please vary the ranks.';
      }
    }
    return null;
  }

  Future<bool> save() async {
    final validationError = validate();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await _supabase.saveWorkerCategoryPreferences(uid, _priorities);

      _isSaving = false;
      _successMessage = 'Preferences saved successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Failed to save preferences: $e';
      notifyListeners();
      return false;
    }
  }
}
