import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../Services/supabase_service.dart';
import '../../Services/image_storage_service.dart';

class WorkerTaskDetailViewModel extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final ImageStorageService _imageStorage = ImageStorageService();
  final ImagePicker _picker = ImagePicker();

  final String _reportId;
  Map<String, dynamic>? _taskDetails;
  bool _isLoading = true;
  String? _errorMessage;

  // Proof Image State
  File? _proofImage;
  bool _isUploading = false;
  String _statusMessage = '';
  String _updateNote = '';

  WorkerTaskDetailViewModel(this._reportId) {
    fetchTaskDetails();
  }

  // Getters
  Map<String, dynamic>? get taskDetails => _taskDetails;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get proofImage => _proofImage;
  bool get isUploading => _isUploading;
  String get statusMessage => _statusMessage;
  bool get hasProofImage => _proofImage != null;
  String get updateNote => _updateNote;

  void setUpdateNote(String value) {
    _updateNote = value;
    notifyListeners();
  }

  Future<void> fetchTaskDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _supabase.getReportById(_reportId);
      if (data == null) throw Exception('Task not found');
      
      _taskDetails = data;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateStatus(String status) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      _isUploading = true;
      _statusMessage = 'Updating status...';
      notifyListeners();
      
      await _supabase.updateTaskStatus(
        _reportId,
        status,
        workerId: uid,
        note: _updateNote.trim().isEmpty ? null : _updateNote.trim(),
      );
      await fetchTaskDetails(); // Refresh
      
      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _isUploading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> pickProofImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo != null) {
        File originalFile = File(photo.path);
        
        // Always compress
        final compressed = await _compressImage(originalFile);
        _proofImage = compressed;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );

      if (result != null) return File(result.path);
    } catch (e) {
      debugPrint('Compression failed, using original: $e');
    }
    return file;
  }

  void removeProofImage() {
    _proofImage = null;
    notifyListeners();
  }

  Future<bool> resolveTask() async {
    if (_proofImage == null) {
      _errorMessage = 'Proof of completion is required.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _statusMessage = 'Uploading proof photo...';
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      // 1. Upload proof to Firebase Storage
      final imageUrl = await _imageStorage.uploadReportImage(_proofImage!);

      double? latitude;
      double? longitude;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission != LocationPermission.deniedForever) {
          final currentPermission = permission == LocationPermission.denied
              ? await Geolocator.requestPermission()
              : permission;
          if (currentPermission == LocationPermission.always ||
              currentPermission == LocationPermission.whileInUse) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            latitude = pos.latitude;
            longitude = pos.longitude;
          }
        }
      } catch (_) {
        // Geotag is optional for completion updates.
      }

      // 2. Add to Supabase
      _statusMessage = 'Finalizing resolution...';
      notifyListeners();
      await _supabase.addProofImage(_reportId, imageUrl);

      // 3. Update status using worker assignments workflow
      await _supabase.updateTaskStatus(
        _reportId,
        'completed',
        workerId: uid,
        note: _updateNote.trim().isEmpty
          ? 'Completed with proof image'
            : _updateNote.trim(),
        proofImageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        eventTime: DateTime.now(),
      );

      await fetchTaskDetails(); // Refresh data
      
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      _errorMessage = 'Failed to resolve task: $e';
      notifyListeners();
      return false;
    }
  }
}
