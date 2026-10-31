import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/navigation_service.dart';

void main() {
  test('NavigationService constructs valid Google Maps and Waze URIs', () {
    final gmapsUri = NavigationService.buildGoogleMapsUri(-6.2088, 106.8456);
    expect(gmapsUri.toString(), contains('destination=-6.2088,106.8456'));

    final wazeUri = NavigationService.buildWazeUri(-6.2088, 106.8456);
    expect(wazeUri.toString(), contains('ll=-6.2088,106.8456'));
  });

  test('NavigationService constructs geo fallback URI', () {
    final geoUri = NavigationService.buildGeoUri(-6.2088, 106.8456, label: 'Supermarket Puri');
    expect(geoUri.scheme, 'geo');
    expect(geoUri.toString(), contains('-6.2088,106.8456'));
  });
}
