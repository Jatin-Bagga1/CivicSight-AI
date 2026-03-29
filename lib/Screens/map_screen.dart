import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../Services/map_settings_provider.dart';
import '../Services/supabase_service.dart';
import '../constants/colors.dart';

/// Map Screen — Shows Google Map centered on Toronto downtown with report pins.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  // Default: Toronto downtown
  static const LatLng _torontoDowntown = LatLng(43.6532, -79.3832);
  LatLng _currentPosition = _torontoDowntown;
  bool _locationLoaded = false;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _selectedReport;
  final SupabaseService _supabase = SupabaseService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadReportMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadReportMarkers() async {
    try {
      final reports = await _supabase.getAllReportsWithLocations();
      _reports = reports;
      final Set<Marker> markers = {};

      for (final report in reports) {
        final locations = report['report_locations'];
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

        final reportId = report['id'] as String? ?? '';
        final reportNumber = report['report_number'] ?? '-';
        final category = report['ai_category_name'] as String? ?? 'Unknown';
        final severity = (report['ai_severity'] as num?)?.toInt() ?? 0;

        final markerColor = _markerHue(severity);

        markers.add(
          Marker(
            markerId: MarkerId(reportId),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            infoWindow: InfoWindow(
              title: '#$reportNumber — $category',
              snippet: 'Tap for details',
            ),
            onTap: () {
              setState(() {
                _selectedReport = report;
              });
            },
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _markers = markers;
      });
    } catch (e) {
      debugPrint('Failed to load report markers: $e');
    }
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapSettings = context.watch<MapSettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ─── Map (shorter — not full height) ───
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _torontoDowntown,
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_locationLoaded) {
                  controller.animateCamera(
                    CameraUpdate.newLatLng(_currentPosition),
                  );
                }
              },
              markers: _markers,
              mapType: mapSettings.mapType,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onTap: (_) {
                setState(() => _selectedReport = null);
              },
            ),
          ),
        ),

        // ─── Report info panel ───
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _selectedReport != null
                ? _buildReportDetail(_selectedReport!, isDark)
                : _buildMapSummary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSummary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pin_drop, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              '${_markers.length} Reports on Map',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadReportMarkers,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh pins',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a pin to see report details',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const Spacer(),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _legendDot(Colors.green, 'Low'),
            _legendDot(Colors.cyan, 'Minor'),
            _legendDot(Colors.orange, 'Moderate'),
            _legendDot(Colors.deepOrange, 'High'),
            _legendDot(Colors.red, 'Critical'),
          ],
        ),
      ],
    );
  }

  Widget _buildReportDetail(Map<String, dynamic> report, bool isDark) {
    final reportNumber = report['report_number'] ?? '-';
    final category = report['ai_category_name'] as String? ?? 'Unknown';
    final severity = (report['ai_severity'] as num?)?.toInt() ?? 0;
    final status = report['status'] as String? ?? 'pending';
    final description = report['description'] as String? ?? '';
    final reportedAt = report['reported_at'] as String?;

    // Get location address
    final locations = report['report_locations'];
    String? address;
    if (locations is Map) {
      address = locations['formatted_address'] as String?;
    } else if (locations is List && locations.isNotEmpty) {
      address = locations.first['formatted_address'] as String?;
    }

    // Format date
    String dateStr = '';
    if (reportedAt != null) {
      final dt = DateTime.tryParse(reportedAt);
      if (dt != null) {
        dateStr =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with close button
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Report #$reportNumber',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedReport = null),
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status & Severity row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (severity > 0) ...[
                Icon(Icons.warning_rounded, size: 16, color: _severityColor(severity)),
                const SizedBox(width: 4),
                Text(
                  'Severity $severity/5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _severityColor(severity),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Category
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                category,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description
          if (description.isNotEmpty)
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
            ),

          const SizedBox(height: 8),

          // Location
          if (address != null)
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),

          if (dateStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'open':
        return AppColors.info;
      case 'in_progress':
        return AppColors.warning;
      case 'resolved':
      case 'completed':
        return AppColors.success;
      case 'closed':
        return Colors.grey;
      case 'pending':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(int severity) {
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
