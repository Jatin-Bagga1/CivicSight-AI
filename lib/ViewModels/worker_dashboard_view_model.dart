import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../Services/supabase_service.dart';

class WorkerDashboardViewModel extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  String? _workerUid;
  
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _historyTasks = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  bool _isUpdatingShift = false;
  String _shiftStatus = 'off_duty';

  // Filter state (assigned tasks)
  String _statusFilter = 'all';
  String _severityFilter = 'all';
  String _dueFilter = 'all';
  StreamSubscription<List<Map<String, dynamic>>>? _assignmentSubscription;

  // History filter state
  String _historyStatusFilter = 'all';
  String _historySeverityFilter = 'all';
  String _historyCategoryFilter = 'all';
  String _historyTimeFilter = 'all';
  
  // Map state
  LatLng _currentLocation = const LatLng(43.6532, -79.3832); // Toronto default
  bool _locationLoaded = false;
  Set<Marker> _markers = {};
  bool _showAllReports = false; // false = My Assigned, true = All Reports

  // Getters
  List<Map<String, dynamic>> get assignedTasks => _applyFilters(_allTasks);
  bool get hasTasks => _allTasks.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  LatLng get currentLocation => _currentLocation;
  bool get locationLoaded => _locationLoaded;
  Set<Marker> get markers => _markers;
  String get statusFilter => _statusFilter;
  String get severityFilter => _severityFilter;
  String get dueFilter => _dueFilter;
  bool get isUpdatingShift => _isUpdatingShift;
  String get shiftStatus => _shiftStatus;
  bool get showAllReports => _showAllReports;

  // History getters
  List<Map<String, dynamic>> get historyTasks => _applyHistoryFilters(_historyTasks);
  bool get hasHistory => _historyTasks.isNotEmpty;
  String get historyStatusFilter => _historyStatusFilter;
  String get historySeverityFilter => _historySeverityFilter;
  String get historyCategoryFilter => _historyCategoryFilter;
  String get historyTimeFilter => _historyTimeFilter;

  /// Unique category names from history for filter dropdown.
  List<String> get historyCategories {
    final cats = _historyTasks
        .map((t) => t['ai_category_name'] as String? ?? 'Unknown')
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }
  int get totalTasksCount => _allTasks.length;
  int get inProgressCount =>
      _allTasks.where((t) => (t['status'] as String?) == 'in_progress').length;
  int get completedTodayCount {
    final now = DateTime.now();
    return _historyTasks.where((task) {
      final completedAt = DateTime.tryParse((task['completed_at'] as String?) ?? '');
      if (completedAt == null) return false;
      final local = completedAt.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;
  }

  int get overdueCount {
    final now = DateTime.now();
    return _allTasks.where((task) {
      final status = (task['status'] as String?) ?? 'assigned';
      if (status == 'completed' || status == 'closed') return false;
      final dueDate = DateTime.tryParse((task['due_date'] as String?) ?? '');
      return dueDate != null && dueDate.isBefore(now);
    }).length;
  }

  double get averageCompletionHours {
    final durations = _historyTasks
        .map((task) {
          final assignedAt = DateTime.tryParse((task['assigned_at'] as String?) ?? '');
          final completedAt = DateTime.tryParse((task['completed_at'] as String?) ?? '');
          if (assignedAt == null || completedAt == null) return null;
          return completedAt.difference(assignedAt).inMinutes / 60.0;
        })
        .whereType<double>()
        .toList();

    if (durations.isEmpty) return 0;
    final total = durations.reduce((a, b) => a + b);
    return total / durations.length;
  }

  WorkerDashboardViewModel() {
    _init();
  }

  Future<void> _init() async {
    await _getCurrentLocation();
    await fetchTasks();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> fetchTasks() async {
    await _loadTasks(showLoading: true);
  }

  Future<void> _loadTasks({required bool showLoading}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      _workerUid = uid;

      // Only fetch shift status on initial load, not on background refreshes
      if (showLoading) {
        _shiftStatus = await _supabase.getLatestWorkerShiftStatus(uid);
      }
      _ensureRealtimeSubscription(uid);

      final tasks = await _supabase.getAssignedTasks(uid);
      debugPrint('WorkerDashboard: Loaded ${tasks.length} tasks for worker $uid');

      _allTasks = tasks;

      // Also load all reports for "All Reports" map mode
      _allReports = await _supabase.getAllReportsWithLocations();

      // Load history (completed / closed)
      _historyTasks = await _supabase.getWorkerTaskHistory(uid);

      _buildMarkers();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('WorkerDashboard: Error loading tasks: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _ensureRealtimeSubscription(String workerUid) {
    if (_assignmentSubscription != null) return;

    _assignmentSubscription = _supabase.streamWorkerAssignments(workerUid).listen(
      (_) {
        _loadTasks(showLoading: false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> updateShiftStatus(String status) async {
    if (_workerUid == null) {
      _errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isUpdatingShift = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.logWorkerShiftStatus(
        _workerUid!,
        status,
        latitude: _locationLoaded ? _currentLocation.latitude : null,
        longitude: _locationLoaded ? _currentLocation.longitude : null,
      );
      _shiftStatus = status;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isUpdatingShift = false;
      notifyListeners();
    }
  }

  void toggleMapMode(bool showAll) {
    _showAllReports = showAll;
    _buildMarkers();
    notifyListeners();
  }

  void _buildMarkers() {
    final Set<Marker> newMarkers = {};

    final source = _showAllReports ? _allReports : assignedTasks;
    for (final task in source) {
      final locations = task['report_locations'];
      double? lat;
      double? lng;

      if (locations is Map) {
        lat = (locations['latitude'] as num?)?.toDouble();
        lng = (locations['longitude'] as num?)?.toDouble();
      } else if (locations is List && locations.isNotEmpty) {
        lat = (locations.first['latitude'] as num?)?.toDouble();
        lng = (locations.first['longitude'] as num?)?.toDouble();
      }

      if (lat == null || lng == null) continue;

      final reportId = task['id'] as String? ?? '';
      final reportNumber = task['report_number'] ?? '-';
      final category = task['ai_category_name'] as String? ?? 'Unknown';
      final severity = (task['ai_severity'] as num?)?.toInt() ?? 0;
      final status = task['status'] as String? ?? 'assigned';
      
      final markerColor = _markerHue(severity);

      newMarkers.add(
        Marker(
          markerId: MarkerId(reportId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: '#$reportNumber — $category',
            snippet: '${status.replaceAll('_', ' ').toUpperCase()} • Severity $severity/5',
          ),
        ),
      );
    }

    _markers = newMarkers;
  }

  void updateStatusFilter(String value) {
    _statusFilter = value;
    _buildMarkers();
    notifyListeners();
  }

  void updateSeverityFilter(String value) {
    _severityFilter = value;
    _buildMarkers();
    notifyListeners();
  }

  void updateDueFilter(String value) {
    _dueFilter = value;
    _buildMarkers();
    notifyListeners();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> source) {
    return source.where((task) {
      final status = (task['status'] as String?) ?? 'assigned';
      final severity = (task['ai_severity'] as num?)?.toInt() ?? 0;
      final dueDate = DateTime.tryParse((task['due_date'] as String?) ?? '');
      final now = DateTime.now();

      final statusMatch =
          _statusFilter == 'all' ? true : status == _statusFilter;

      final severityMatch = switch (_severityFilter) {
        'high' => severity >= 4,
        'medium' => severity == 3,
        'low' => severity > 0 && severity <= 2,
        _ => true,
      };

      final dueMatch = switch (_dueFilter) {
        'overdue' => dueDate != null && dueDate.isBefore(now),
        'today' =>
          dueDate != null &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day,
        'next3' =>
          dueDate != null &&
          dueDate.isAfter(now) &&
          dueDate.isBefore(now.add(const Duration(days: 3))),
        _ => true,
      };

      return statusMatch && severityMatch && dueMatch;
    }).toList();
  }

  double _markerHue(int severity) {
    switch (severity) {
      case 1:
        return BitmapDescriptor.hueGreen;
      case 2:
        return BitmapDescriptor.hueCyan;
      case 3:
        return BitmapDescriptor.hueYellow;
      case 4:
        return BitmapDescriptor.hueOrange;
      case 5:
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  // ── History Filters ──

  void updateHistoryStatusFilter(String value) {
    _historyStatusFilter = value;
    notifyListeners();
  }

  void updateHistorySeverityFilter(String value) {
    _historySeverityFilter = value;
    notifyListeners();
  }

  void updateHistoryCategoryFilter(String value) {
    _historyCategoryFilter = value;
    notifyListeners();
  }

  void updateHistoryTimeFilter(String value) {
    _historyTimeFilter = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> _applyHistoryFilters(
      List<Map<String, dynamic>> source) {
    final now = DateTime.now();
    return source.where((task) {
      final status = (task['status'] as String?) ?? '';
      final severity = (task['ai_severity'] as num?)?.toInt() ?? 0;
      final category = task['ai_category_name'] as String? ?? 'Unknown';
      final completedAt =
          DateTime.tryParse((task['completed_at'] as String?) ?? '');

      // Status filter
      final statusMatch =
          _historyStatusFilter == 'all' ? true : status == _historyStatusFilter;

      // Severity filter
      final severityMatch = switch (_historySeverityFilter) {
        'high' => severity >= 4,
        'medium' => severity == 3,
        'low' => severity > 0 && severity <= 2,
        _ => true,
      };

      // Category filter
      final categoryMatch =
          _historyCategoryFilter == 'all' ? true : category == _historyCategoryFilter;

      // Time filter
      final timeMatch = switch (_historyTimeFilter) {
        'today' => completedAt != null &&
            completedAt.toLocal().year == now.year &&
            completedAt.toLocal().month == now.month &&
            completedAt.toLocal().day == now.day,
        'week' => completedAt != null &&
            completedAt.isAfter(now.subtract(const Duration(days: 7))),
        'month' => completedAt != null &&
            completedAt.isAfter(now.subtract(const Duration(days: 30))),
        'quarter' => completedAt != null &&
            completedAt.isAfter(now.subtract(const Duration(days: 90))),
        _ => true,
      };

      return statusMatch && severityMatch && categoryMatch && timeMatch;
    }).toList();
  }

  @override
  void dispose() {
    _assignmentSubscription?.cancel();
    super.dispose();
  }
}
