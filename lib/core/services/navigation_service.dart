import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationService {
  /// Builds Google Maps driving directions URI
  static Uri buildGoogleMapsUri(double lat, double lng) {
    return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
  }

  /// Builds Waze navigation URI
  static Uri buildWazeUri(double lat, double lng) {
    return Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
  }

  /// Builds Android native geo intent URI with optional label
  static Uri buildGeoUri(double lat, double lng, {String? label}) {
    final query = label != null && label.isNotEmpty ? '$lat,$lng($label)' : '$lat,$lng';
    return Uri(
      scheme: 'geo',
      path: '$lat,$lng',
      queryParameters: {'q': query},
    );
  }

  /// Launches external turn-by-turn navigation (Google Maps / Waze / Native Geo)
  static Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    String? destinationName,
  }) async {
    // 1. Try Google Maps Web/App standard link
    try {
      final gmapsUri = buildGoogleMapsUri(latitude, longitude);
      if (await canLaunchUrl(gmapsUri)) {
        final launched = await launchUrl(gmapsUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('Google Maps launch failed: $e');
    }

    // 2. Fallback to Native geo intent
    try {
      final geoUri = buildGeoUri(latitude, longitude, label: destinationName);
      if (await canLaunchUrl(geoUri)) {
        final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('Geo intent launch failed: $e');
    }

    // 3. Fallback to Waze
    try {
      final wazeUri = buildWazeUri(latitude, longitude);
      if (await canLaunchUrl(wazeUri)) {
        final launched = await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }
    } catch (e) {
      debugPrint('Waze launch failed: $e');
    }

    return false;
  }
}
