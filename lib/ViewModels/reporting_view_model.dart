import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/image_storage_service.dart';
import '../Services/ai_analysis_service.dart';
import '../Services/location_service.dart';

/// ViewModel for the Reporting Screen.
///
/// Full Pipeline:
///   1. Auto-detect GPS on init → reverse geocode
///   2. Citizen picks/captures image
///   3. Citizen writes description
///   4. Citizen can adjust location (pin drop / address search)
///   5. On submit:
///      a) Upload image to Firebase Storage
///      b) AI classification via analyze-report edge function
///      c) If valid, store report + location + image via store-report edge function
///      d) If rejected, delete image from Firebase Storage
class ReportingViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final ImageStorageService _imageService = ImageStorageService();
  final AIAnalysisService _aiService = AIAnalysisService();
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Form Fields ───
  String _description = '';
  File? _selectedImage;
  String? _uploadedImageUrl;

  // ─── Location ───
  ReportLocation? _location;
  bool _isLoadingLocation = false;
  String? _locationError;

  // ─── AI Classification Result ───
  ReportClassification? _classification;

  // ─── Stored Report Info ───
  String? _reportId;
  int? _reportNumber;

  // ─── State ───
  bool _isUploading = false;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  // ─── Getters ───
  String get description => _description;
  File? get selectedImage => _selectedImage;
  String? get uploadedImageUrl => _uploadedImageUrl;
  ReportLocation? get location => _location;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;
  bool get hasLocation => _location != null;
  ReportClassification? get classification => _classification;
  String? get reportId => _reportId;
  int? get reportNumber => _reportNumber;
  bool get isUploading => _isUploading;
  bool get isAnalyzing => _isAnalyzing;
  bool get isSubmitting => _isSubmitting;
  bool get isProcessing => _isUploading || _isAnalyzing || _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  double get uploadProgress => _uploadProgress;
  String get statusMessage => _statusMessage;
  bool get hasImage => _selectedImage != null;
  bool get hasClassification => _classification != null;

  // ─── Constructor — auto-detect location on init ───
  ReportingViewModel() {
    autoDetectLocation();
  }

  // ─── Setters ───
  void setDescription(String value) => _description = value.trim();

  void setLocationDescription(String value) {
    if (_location != null) {
      _location!.locationDescription = value.trim();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // ─── Location Methods ───

  /// Auto-detect GPS location and reverse geocode.
  Future<void> autoDetectLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    try {
      _location = await _locationService.autoDetectLocation();
      _isLoadingLocation = false;
      notifyListeners();
    } catch (e) {
      _isLoadingLocation = false;
      _locationError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Update location from pin drop on map.
  Future<void> updateLocationFromPin(double lat, double lng) async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      _location = await _locationService.fromPinDrop(lat, lng);
      _isLoadingLocation = false;
      _locationError = null;
      notifyListeners();
    } catch (e) {
      _isLoadingLocation = false;
      _locationError = 'Failed to get address for pin location';
      notifyListeners();
    }
  }

  /// Update location from address search.
  Future<void> updateLocationFromAddress(ReportLocation newLocation) async {
    _location = newLocation;
    _locationError = null;
    notifyListeners();
  }

  /// Get autocomplete suggestions.
  Future<List<PlaceSuggestion>> getAddressSuggestions(String input) async {
    return await _locationService.getAutocompleteSuggestions(input);
  }

  /// Get full location from a place ID.
  Future<ReportLocation?> getLocationFromPlaceId(String placeId) async {
    return await _locationService.getPlaceDetails(placeId);
  }

  // ─── Image Picking ───

  Future<void> pickFromCamera() async {
    try {
      _clearMessages();
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final compressed = await _compressImage(File(photo.path));
        _selectedImage = compressed;
        _uploadedImageUrl = null;
        _classification = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
    }
  }

  Future<void> pickFromGallery() async {
    try {
      _clearMessages();
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(photo.path)}',
        );
        await tempFile.writeAsBytes(bytes);

        final compressed = await _compressImage(tempFile);
        _selectedImage = compressed;
        _uploadedImageUrl = null;
        _classification = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to select image: $e';
      notifyListeners();
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        debugPrint(
          'Image compressed: ${file.lengthSync()} -> ${await result.length()} bytes',
        );
        return File(result.path);
      }
    } catch (e) {
      debugPrint('Compression failed, using original: $e');
    }
    return file;
  }

  void removeImage() {
    _selectedImage = null;
    _uploadedImageUrl = null;
    _classification = null;
    notifyListeners();
  }

  // ─── Upload & Submit ───

  Future<bool> _uploadImage() async {
    if (_selectedImage == null) return false;
    if (_uploadedImageUrl != null) return true;

    _isUploading = true;
    _statusMessage = 'Uploading image...';
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
      _statusMessage = '';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _analyzeWithAI() async {
    if (_uploadedImageUrl == null) return false;

    _isAnalyzing = true;
    _statusMessage = 'AI is analyzing the image...';
    notifyListeners();

    try {
      _classification = await _aiService.analyzeReport(
        imageUrl: _uploadedImageUrl!,
        description: _description.isNotEmpty ? _description : null,
      );
      _isAnalyzing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAnalyzing = false;
      _errorMessage = 'AI analysis failed: $e';
      _statusMessage = '';
      notifyListeners();
      return false;
    }
  }

  bool _validate() {
    if (_selectedImage == null) {
      _errorMessage = 'Please add a photo of the issue.';
      notifyListeners();
      return false;
    }
    if (_description.isEmpty || _description.length < 10) {
      _errorMessage = 'Please provide a description (at least 10 characters).';
      notifyListeners();
      return false;
    }
    if (_location == null) {
      _errorMessage = 'Please set a location for the report.';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Full submit pipeline:
  /// 1. Validate → 2. Upload image → 3. AI analyze
  /// 4. If valid → store in DB. If rejected → delete image.
  Future<bool> submitReport() async {
    _clearMessages();

    if (!_validate()) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      // Step 1: Upload image
      _statusMessage = 'Uploading image to server...';
      notifyListeners();
      final uploaded = await _uploadImage();
      if (!uploaded) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // Step 2: AI classification
      _statusMessage = 'AI is analyzing the image...';
      notifyListeners();
      final analyzed = await _analyzeWithAI();
      if (!analyzed) {
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // Step 3: Check if valid
      if (!_classification!.isValidReport) {
        // Delete image from Firebase Storage
        if (_uploadedImageUrl != null) {
          _statusMessage = 'Cleaning up...';
          notifyListeners();
          await _imageService.deleteImage(_uploadedImageUrl!);
          _uploadedImageUrl = null;
        }
        _isSubmitting = false;
        _statusMessage = '';
        _errorMessage =
            _classification!.rejectionReason ?? 'Report rejected by AI.';
        notifyListeners();
        return true; // Return true so UI shows the classification card
      }

      // Step 4: Store report in database
      _statusMessage = 'Saving report to database...';
      notifyListeners();

      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      final result = await _aiService.storeReport(
        citizenId: uid,
        description: _description,
        imageUrl: _uploadedImageUrl!,
        classification: _classification!.toJson(),
        location: _location!.toJson(),
      );

      _reportId = result['report_id'];
      _reportNumber = result['report_number'];

      _isSubmitting = false;
      _statusMessage = '';
      _successMessage =
          'Report #$_reportNumber submitted successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed: $e';
      _statusMessage = '';
      notifyListeners();
      return false;
    }
  }

  // ─── Helpers ───

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void resetForm() {
    _description = '';
    _selectedImage = null;
    _uploadedImageUrl = null;
    _classification = null;
    _uploadProgress = 0.0;
    _reportId = null;
    _reportNumber = null;
    notifyListeners();
  }
}
