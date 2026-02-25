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
        final status = report['status'] as String? ?? 'pending';
        final description = report['description'] as String? ?? '';

        final markerColor = _markerHue(severity);

        markers.add(
          Marker(
            markerId: MarkerId(reportId),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            infoWindow: InfoWindow(
              title: '#$reportNumber — $category',
              snippet:
                  '${status.replaceAll('_', ' ').toUpperCase()} • Severity $severity/5\n${description.length > 60 ? '${description.substring(0, 60)}...' : description}',
            ),
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
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ─── Report summary strip ───
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pin_drop,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_markers.length} Reports on Map',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
                // Legend row
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
            ),
          ),
        ),
      ],
    );
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
