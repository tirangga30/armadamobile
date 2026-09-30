import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class LocationService {
  final Uuid _uuid = const Uuid();

  /// Check whether GPS location service is enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request and check location permissions
  Future<LocationPermission> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permissions are denied');
        return permission;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permissions are permanently denied.');
      return permission;
    }

    return permission;
  }

  /// Acquire the latest device position
  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await checkAndRequestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting GPS position: $e');
      return null;
    }
  }

  /// Build standard GPS payload matching Armada Backend Section 27 contract:
  /// POST /v1/me/location
  Map<String, dynamic> buildLocationPayload({
    required double latitude,
    required double longitude,
    double? accuracyM,
    double? speedMps,
    double? headingDeg,
  }) {
    return {
      'idempotencyKey': _uuid.v4(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracyM': accuracyM ?? 5.0,
      'speedMps': speedMps ?? 0.0,
      'headingDeg': headingDeg ?? 0.0,
      'recordedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
