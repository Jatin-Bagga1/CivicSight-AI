import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../ViewModels/reporting_view_model.dart';
import '../Services/ai_analysis_service.dart';
import '../Services/location_service.dart';
import '../constants/colors.dart';

/// Reporting Screen — Submit civic reports with optional image attachments.
class ReportingScreen extends StatelessWidget {
  const ReportingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportingViewModel(),
      child: const _ReportingContent(),
    );
  }
}

class _ReportingContent extends StatefulWidget {
  const _ReportingContent();

  @override
  State<_ReportingContent> createState() => _ReportingContentState();
}

class _ReportingContentState extends State<_ReportingContent> {
  final _descriptionController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _addressSearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _landmarkController.dispose();
    _addressSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showImageSourceSheet(ReportingViewModel vm) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera to capture an image'),
                onTap: () {
                  Navigator.pop(context);
                  vm.pickFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primaryOrange,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text(
                  'Select an existing image from your device',
                ),
                onTap: () {
                  Navigator.pop(context);
                  vm.pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pin Drop Map ───

  void _showPinDropMap(ReportingViewModel vm) {
    final initialLat = vm.location?.latitude ?? 43.6532;
    final initialLng = vm.location?.longitude ?? -79.3832;

    LatLng pinPosition = LatLng(initialLat, initialLng);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Drag the map to place the pin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: pinPosition,
                        zoom: 16,
                      ),
                      onCameraMove: (pos) {
                        setModalState(() {
                          pinPosition = pos.target;
                        });
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                    ),
                    const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      vm.updateLocationFromPin(
                        pinPosition.latitude,
                        pinPosition.longitude,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Address Search ───

  void _onAddressSearchChanged(String value, ReportingViewModel vm) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.trim().length < 3) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }
      final results = await vm.getAddressSuggestions(value);
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
    });
  }

  Future<void> _selectSuggestion(
    PlaceSuggestion suggestion,
    ReportingViewModel vm,
  ) async {
    setState(() {
      _showSuggestions = false;
      _addressSearchController.text = suggestion.description;
    });

    final location = await vm.getLocationFromPlaceId(suggestion.placeId);
    if (location != null) {
      vm.updateLocationFromAddress(location);
    }
  }

  Future<void> _handleSubmit(ReportingViewModel vm) async {
    HapticFeedback.mediumImpact();
    final success = await vm.submitReport();
    if (success && vm.hasClassification) {
      if (vm.classification!.isValidReport) {
        _showSnackBar(vm.successMessage ?? 'Report submitted!');
        // Reset form after success
        _descriptionController.clear();
        _landmarkController.clear();
        _addressSearchController.clear();
        vm.resetForm();
      } else {
        _showSnackBar(
          vm.classification!.rejectionReason ?? 'Report rejected by AI.',
          isError: true,
        );
        HapticFeedback.heavyImpact();
      }
    } else if (vm.errorMessage != null) {
      _showSnackBar(vm.errorMessage!, isError: true);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportingViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Report'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Image Section ───
                _buildImageSection(vm, isDark),
                const SizedBox(height: 24),

                // ─── Description (required — helps AI accuracy) ───
                _buildLabel('Description'),
                const SizedBox(height: 4),
                Text(
                  'Describe the issue (min 10 characters)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'E.g., Large pothole on Main St near the bus stop...',
                  isDark: isDark,
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: vm.setDescription,
                ),
                const SizedBox(height: 24),

                // ─── Location Section ───
                _buildLocationSection(vm, isDark),
                const SizedBox(height: 20),

                // ─── AI Processing Status ───
                if (vm.isProcessing) _buildProcessingStatus(vm, isDark),

                // ─── AI Classification Result ───
                if (vm.hasClassification && !vm.isProcessing) ...[
                  if (vm.classification!.isRejected)
                    _buildRejectionCard(vm.classification!, isDark),
                  _buildClassificationCard(vm.classification!, isDark),
                ],

                const SizedBox(height: 24),

                // ─── Submit Button ───
                _buildSubmitButton(vm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Location Section ───

  Widget _buildLocationSection(ReportingViewModel vm, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Location'),
        const SizedBox(height: 8),

        // Current location display
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.isLoadingLocation)
                const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Detecting your location...',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                )
              else if (vm.hasLocation) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.location!.formattedAddress ?? 'Location set',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: ${vm.location!.locationSource.replaceAll('_', ' ').toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ] else if (vm.locationError != null)
                Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.locationError!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'No location set',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

              const SizedBox(height: 12),

              // 3 location action buttons
              Row(
                children: [
                  _locationButton(
                    icon: Icons.my_location,
                    label: 'GPS',
                    onTap: () => vm.autoDetectLocation(),
                  ),
                  const SizedBox(width: 8),
                  _locationButton(
                    icon: Icons.pin_drop_outlined,
                    label: 'Pin Drop',
                    onTap: () => _showPinDropMap(vm),
                  ),
                  const SizedBox(width: 8),
                  _locationButton(
                    icon: Icons.search,
                    label: 'Search',
                    onTap: () {
                      _addressSearchController.clear();
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Address search field
        _buildTextField(
          controller: _addressSearchController,
          hint: 'Search address...',
          isDark: isDark,
          maxLines: 1,
          onChanged: (val) => _onAddressSearchChanged(val, vm),
        ),

        // Autocomplete suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => ListTile(
                dense: true,
                leading: const Icon(Icons.place, size: 18),
                title: Text(
                  _suggestions[i].description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectSuggestion(_suggestions[i], vm),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Landmark note
        _buildTextField(
          controller: _landmarkController,
          hint: 'Landmark note (optional) e.g., Near Tim Hortons',
          isDark: isDark,
          maxLines: 1,
          maxLength: 200,
          onChanged: vm.setLocationDescription,
        ),
      ],
    );
  }

  Widget _locationButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryBlue),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Image Section ───

  Widget _buildImageSection(ReportingViewModel vm, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Photo Evidence'),
        const SizedBox(height: 8),
        if (vm.hasImage)
          _buildImagePreview(vm, isDark)
        else
          _buildImagePicker(vm, isDark),
        if (vm.isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Compressing & uploading image...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImagePicker(ReportingViewModel vm, bool isDark) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(vm),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withOpacity(0.6)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to add a photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a photo or choose from gallery',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ReportingViewModel vm, bool isDark) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(vm.selectedImage!, fit: BoxFit.cover),
          ),
        ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              vm.removeImage();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        // Change button
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _showImageSourceSheet(vm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Change',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Form Widgets ───

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildProcessingStatus(ReportingViewModel vm, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withOpacity(0.8)
            : AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              vm.statusMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationCard(
    ReportClassification classification,
    bool isDark,
  ) {
    final severityColor = _getSeverityColor(classification.severity);
    final isValid = classification.isValidReport;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isValid
            ? null
            : Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_rounded,
                color: isValid ? AppColors.primaryBlue : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isValid ? 'AI Classification' : 'AI Analysis (Image Content)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _classificationRow('Category', classification.categoryName, isDark),
          _classificationRow('Group', classification.categoryGroup, isDark),
          _classificationRow(
            'Severity',
            '${'\u26a0\ufe0f ' * classification.severity}(${classification.severity}/5)',
            isDark,
            valueColor: severityColor,
          ),
          _classificationRow(
            'Priority',
            classification.suggestedPriority.toUpperCase(),
            isDark,
            valueColor: severityColor,
          ),
          _classificationRow(
            'Confidence',
            '${(classification.confidence * 100).toStringAsFixed(0)}%',
            isDark,
          ),
          _classificationRow(
            'Response',
            '${classification.dueDateDays} days',
            isDark,
          ),
          _classificationRow(
            'Valid Report',
            classification.isValidReport ? '\u2705 Yes' : '\u274c No',
            isDark,
          ),
          _classificationRow(
            'Image Match',
            classification.imageMatchesDescription
                ? '\u2705 Matches'
                : '\u274c Mismatch',
            isDark,
          ),
          const SizedBox(height: 8),
          Text(
            classification.aiDescription,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Red rejection banner shown when AI rejects the report.
  Widget _buildRejectionCard(ReportClassification classification, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.report_problem_rounded,
                color: AppColors.error,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Report Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            classification.rejectionReason ?? 'Report was rejected by AI.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
          if (!classification.imageMatchesDescription) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Image does not match your description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _classificationRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ReportingViewModel vm) {
    final isLoading = vm.isProcessing;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.buttonGradient,
          color: isLoading ? Colors.grey : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : () => _handleSubmit(vm),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
