import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Location data model for a report.
class ReportLocation {
  double latitude;
  double longitude;
  String locationSource; // 'gps', 'pin_drop', 'address_search'
  double? gpsAccuracyMeters;
  String? formattedAddress;
  String? streetNumber;
  String? streetName;
  String? neighbourhood;
  String? city;
  String? province;
  String? postalCode;
  String? countryCode;
  String? locationDescription;

  ReportLocation({
    required this.latitude,
    required this.longitude,
    this.locationSource = 'gps',
    this.gpsAccuracyMeters,
    this.formattedAddress,
    this.streetNumber,
    this.streetName,
    this.neighbourhood,
    this.city,
    this.province,
    this.postalCode,
    this.countryCode,
    this.locationDescription,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'location_source': locationSource,
        if (gpsAccuracyMeters != null) 'gps_accuracy_meters': gpsAccuracyMeters,
        if (formattedAddress != null) 'formatted_address': formattedAddress,
        if (streetNumber != null) 'street_number': streetNumber,
        if (streetName != null) 'street_name': streetName,
        if (neighbourhood != null) 'neighbourhood': neighbourhood,
        if (city != null) 'city': city,
        if (province != null) 'province': province,
        if (postalCode != null) 'postal_code': postalCode,
        if (countryCode != null) 'country_code': countryCode,
        if (locationDescription != null)
          'location_description': locationDescription,
      };
}

/// Service handling GPS, reverse geocoding, and address search.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static String get _placesApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';

  /// Get current GPS position.
  Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Enable in Settings.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Auto-detect GPS location and reverse geocode it.
  Future<ReportLocation> autoDetectLocation() async {
    final position = await getCurrentPosition();

    final location = ReportLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationSource: 'gps',
      gpsAccuracyMeters: position.accuracy,
    );

    // Reverse geocode
    await _reverseGeocode(location);

    return location;
  }

  /// Reverse geocode lat/lng into address components using Google Geocoding API.
  Future<void> _reverseGeocode(ReportLocation location) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&key=$_placesApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body);
      if (json['status'] != 'OK' || (json['results'] as List).isEmpty) return;

      final result = json['results'][0];
      location.formattedAddress = result['formatted_address'];

      final components = result['address_components'] as List;
      for (final comp in components) {
        final types = List<String>.from(comp['types'] ?? []);
        final value = comp['long_name'] as String?;

        if (types.contains('street_number')) {
          location.streetNumber = value;
        } else if (types.contains('route')) {
          location.streetName = value;
        } else if (types.contains('sublocality') ||
            types.contains('neighborhood') ||
            types.contains('sublocality_level_1')) {
          location.neighbourhood = value;
        } else if (types.contains('locality')) {
          location.city = value;
        } else if (types.contains('administrative_area_level_1')) {
          location.province = value;
        } else if (types.contains('postal_code')) {
          location.postalCode = value;
        } else if (types.contains('country')) {
          location.countryCode = comp['short_name'];
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
    }
  }

  /// Reverse geocode from pin drop coordinates.
  Future<ReportLocation> fromPinDrop(double lat, double lng) async {
    final location = ReportLocation(
      latitude: lat,
      longitude: lng,
      locationSource: 'pin_drop',
    );
    await _reverseGeocode(location);
    return location;
  }

  /// Forward geocode: search an address string, return location.
  Future<ReportLocation?> searchAddress(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(query)}'
        '&key=$_placesApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json['status'] != 'OK' || (json['results'] as List).isEmpty) {
        return null;
      }

      final result = json['results'][0];
      final geo = result['geometry']['location'];

      final location = ReportLocation(
        latitude: (geo['lat'] as num).toDouble(),
        longitude: (geo['lng'] as num).toDouble(),
        locationSource: 'address_search',
        formattedAddress: result['formatted_address'],
      );

      // Parse address components
      final components = result['address_components'] as List;
      for (final comp in components) {
        final types = List<String>.from(comp['types'] ?? []);
        final value = comp['long_name'] as String?;

        if (types.contains('street_number')) {
          location.streetNumber = value;
        } else if (types.contains('route')) {
          location.streetName = value;
        } else if (types.contains('sublocality') ||
            types.contains('neighborhood') ||
            types.contains('sublocality_level_1')) {
          location.neighbourhood = value;
        } else if (types.contains('locality')) {
          location.city = value;
        } else if (types.contains('administrative_area_level_1')) {
          location.province = value;
        } else if (types.contains('postal_code')) {
          location.postalCode = value;
        } else if (types.contains('country')) {
          location.countryCode = comp['short_name'];
        }
      }

      return location;
    } catch (e) {
      debugPrint('Address search failed: $e');
      return null;
    }
  }

  /// Get place autocomplete suggestions.
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String input) async {
    if (input.trim().length < 3) return [];

    try {
      final apiKey = _placesApiKey;
      debugPrint('🔑 Places API key loaded: ${apiKey.isNotEmpty ? "${apiKey.substring(0, 10)}..." : "EMPTY!"}');

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&types=geocode'
        '&components=country:ca'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      debugPrint('📍 Autocomplete status: ${response.statusCode}, body: ${response.body.substring(0, (response.body.length > 200) ? 200 : response.body.length)}');

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body);
      if (json['status'] != 'OK') {
        debugPrint('⚠️ Places API error: ${json['status']} — ${json['error_message'] ?? 'no details'}');
        return [];
      }

      final predictions = json['predictions'] as List;
      return predictions
          .map((p) => PlaceSuggestion(
                placeId: p['place_id'],
                description: p['description'],
              ))
          .toList();
    } catch (e) {
      debugPrint('Autocomplete failed: $e');
      return [];
    }
  }

  /// Get coordinates from a place ID.
  Future<ReportLocation?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry,formatted_address,address_components'
        '&key=$_placesApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json['status'] != 'OK') return null;

      final result = json['result'];
      final geo = result['geometry']['location'];

      final location = ReportLocation(
        latitude: (geo['lat'] as num).toDouble(),
        longitude: (geo['lng'] as num).toDouble(),
        locationSource: 'address_search',
        formattedAddress: result['formatted_address'],
      );

      final components =
          (result['address_components'] as List?) ?? [];
      for (final comp in components) {
        final types = List<String>.from(comp['types'] ?? []);
        final value = comp['long_name'] as String?;

        if (types.contains('street_number')) {
          location.streetNumber = value;
        } else if (types.contains('route')) {
          location.streetName = value;
        } else if (types.contains('sublocality') ||
            types.contains('neighborhood') ||
            types.contains('sublocality_level_1')) {
          location.neighbourhood = value;
        } else if (types.contains('locality')) {
          location.city = value;
        } else if (types.contains('administrative_area_level_1')) {
          location.province = value;
        } else if (types.contains('postal_code')) {
          location.postalCode = value;
        } else if (types.contains('country')) {
          location.countryCode = comp['short_name'];
        }
      }

      return location;
    } catch (e) {
      debugPrint('Place details failed: $e');
      return null;
    }
  }
}

/// A place autocomplete suggestion.
class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}
