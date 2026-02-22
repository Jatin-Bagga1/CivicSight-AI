import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/image_storage_service.dart';
import '../Services/supabase_service.dart';

/// ViewModel for the Reporting Screen.
class ReportingViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final ImageStorageService _imageService = ImageStorageService();
  final SupabaseService _supabase = SupabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Form Fields ───
  String _title = '';
  String _description = '';
  String _category = 'General';
  File? _selectedImage;
  String? _uploadedImageUrl;

  // ─── State ───
  bool _isUploading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  double _uploadProgress = 0.0;

  // ─── Categories ───
  static const List<String> categories = [
    'General',
    'Road Damage',
    'Street Light',
    'Water Leakage',
    'Garbage',
    'Public Safety',
    'Noise Complaint',
    'Other',
  ];

  // ─── Getters ───
  String get title => _title;
  String get description => _description;
  String get category => _category;
  File? get selectedImage => _selectedImage;
  String? get uploadedImageUrl => _uploadedImageUrl;
  bool get isUploading => _isUploading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  double get uploadProgress => _uploadProgress;
  bool get hasImage => _selectedImage != null;

  // ─── Setters ───
  void setTitle(String value) => _title = value.trim();
  void setDescription(String value) => _description = value.trim();

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // ─── Image Picking ───

  /// Pick an image from the camera.
  Future<void> pickFromCamera() async {
    try {
      _clearMessages();
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        _selectedImage = File(photo.path);
        _uploadedImageUrl = null; // Reset previous upload
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
    }
  }

  /// Pick an image from the gallery / file folder.
  Future<void> pickFromGallery() async {
    try {
      _clearMessages();
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        _selectedImage = File(photo.path);
        _uploadedImageUrl = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to select image: $e';
      notifyListeners();
    }
  }

  /// Remove the currently selected image.
  void removeImage() {
    _selectedImage = null;
    _uploadedImageUrl = null;
    notifyListeners();
  }

  // ─── Upload & Submit ───

  /// Upload selected image to Firebase Storage (compressed).
  Future<bool> _uploadImage() async {
    if (_selectedImage == null) return true; // No image to upload
    if (_uploadedImageUrl != null) return true; // Already uploaded

    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      _uploadedImageUrl = await _imageService.uploadReportImage(
        _selectedImage!,
      );
      _isUploading = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploading = false;
      _errorMessage = 'Image upload failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Validates form fields.
  bool _validate() {
    if (_title.isEmpty) {
      _errorMessage = 'Please enter a title for your report.';
      notifyListeners();
      return false;
    }
    if (_description.isEmpty) {
      _errorMessage = 'Please enter a description.';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Submit the complete report to Supabase.
  Future<bool> submitReport() async {
    _clearMessages();

    if (!_validate()) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      // Upload image first (if selected)
      final uploaded = await _uploadImage();
      if (!uploaded) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      await _supabase.addReport({
        'user_id': uid,
        'title': _title,
        'description': _description,
        'category': _category,
        'image_url': _uploadedImageUrl,
        'status': 'pending',
      });

      _isSubmitting = false;
      _successMessage = 'Report submitted successfully!';
      _resetForm();
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to submit report: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Helpers ───

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _resetForm() {
    _title = '';
    _description = '';
    _category = 'General';
    _selectedImage = null;
    _uploadedImageUrl = null;
    _uploadProgress = 0.0;
  }
}
