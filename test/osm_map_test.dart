import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:armada_mobile/core/widgets/armada_osm_map.dart';

void main() {
  testWidgets('ArmadaOsmMap accepts polylines and renders PolylineLayer', (tester) async {
    final points = [const LatLng(-6.2, 106.8), const LatLng(-6.21, 106.81)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArmadaOsmMap(
            initialCenter: const LatLng(-6.2, 106.8),
            polylines: [
              Polyline(points: points, strokeWidth: 4.0, color: Colors.blue),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(PolylineLayer), findsOneWidget);
  });

  test('ArmadaOsmMap.buildStopMarker creates numbered marker with correct coordinates', () {
    final marker = ArmadaOsmMap.buildStopMarker(
      sequence: 1,
      name: 'Toko Sumber Rejeki',
      status: 'PENDING',
      position: const LatLng(-6.2088, 106.8456),
    );

    expect(marker.point.latitude, -6.2088);
    expect(marker.point.longitude, 106.8456);
    expect(marker.width, greaterThan(30));
  });

  test('ArmadaOsmMap.buildRoutePolyline creates Polyline with given points', () {
    final polyline = ArmadaOsmMap.buildRoutePolyline(
      points: [const LatLng(-6.2, 106.8), const LatLng(-6.21, 106.81)],
      color: Colors.blue,
    );

    expect(polyline.points.length, 2);
    expect(polyline.strokeWidth, 4.0);
  });
}
