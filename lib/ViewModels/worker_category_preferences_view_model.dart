import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/category_model.dart';
import '../Services/supabase_service.dart';

class WorkerCategoryPreferencesViewModel extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  List<Category> _allCategories = [];
  Set<int> _selectedCategoryIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<Category> get allCategories => _allCategories;
  Set<int> get selectedCategoryIds => _selectedCategoryIds;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get allSelected =>
      _allCategories.isNotEmpty &&
      _selectedCategoryIds.length == _allCategories.length;

  /// Group categories by category_group for sectioned display.
  Map<String, List<Category>> get groupedCategories {
    final map = <String, List<Category>>{};
    for (final cat in _allCategories) {
      map.putIfAbsent(cat.categoryGroup, () => []).add(cat);
    }
    return map;
  }

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

      // Fetch all categories and worker's preferences in parallel
      final results = await Future.wait([
        _supabase.getAllCategories(),
        _supabase.getWorkerCategoryPreferences(uid),
      ]);

      _allCategories = results[0] as List<Category>;
      final prefs = results[1] as List<WorkerCategoryPreference>;

      if (prefs.isEmpty) {
        // Default: all categories selected
        _selectedCategoryIds = _allCategories.map((c) => c.id).toSet();
      } else {
        _selectedCategoryIds = prefs.map((p) => p.categoryId).toSet();
      }
    } catch (e) {
      _errorMessage = 'Failed to load preferences: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleCategory(int categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    _successMessage = null;
    notifyListeners();
  }

  void selectAll() {
    _selectedCategoryIds = _allCategories.map((c) => c.id).toSet();
    _successMessage = null;
    notifyListeners();
  }

  void deselectAll() {
    _selectedCategoryIds.clear();
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> save() async {
    if (_selectedCategoryIds.isEmpty) {
      _errorMessage = 'Please select at least one category.';
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

      await _supabase.saveWorkerCategoryPreferences(
        uid,
        _selectedCategoryIds.toList(),
      );

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
