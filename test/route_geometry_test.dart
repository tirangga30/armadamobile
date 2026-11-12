import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/route_geometry_model.dart';

void main() {
  test('RouteGeometryModel correctly converts GeoJSON [lng, lat] to LatLng(lat, lng)', () {
    final json = {
      'routeId': 'route-001',
      'deliveryId': 'del-001',
      'version': 2,
      'source': 'RECOMMENDED_2OPT',
      'totalDistanceMeters': 14250.5,
      'estimatedDurationSeconds': 1800,
      'polylineGeojson': {
        'type': 'LineString',
        'coordinates': [
          [106.8272, -6.1754],
          [106.8456, -6.2088],
        ],
      },
    };

    final model = RouteGeometryModel.fromJson(json);
    expect(model.routeId, 'route-001');
    expect(model.deliveryId, 'del-001');
    expect(model.source, 'RECOMMENDED_2OPT');
    expect(model.polylinePoints.length, 2);
    expect(model.polylinePoints[0].latitude, -6.1754);
    expect(model.polylinePoints[0].longitude, 106.8272);
    expect(model.polylinePoints[1].latitude, -6.2088);
    expect(model.polylinePoints[1].longitude, 106.8456);
    expect(model.totalDistanceMeters, 14250.5);
    expect(model.estimatedDurationSeconds, 1800);
  });

  test('SelectRouteDto serializes correctly with recommendedSequence', () {
    final dto = SelectRouteDto(
      source: 'RECOMMENDED_2OPT',
      recommendedSequence: [
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440002',
      ],
      totalDistanceMeters: 14250.5,
      estimatedDurationSeconds: 1800,
    );

    final json = dto.toJson();
    expect(json['source'], 'RECOMMENDED_2OPT');
    expect(json['recommendedSequence'].length, 2);
    expect(json['totalDistanceMeters'], 14250.5);
    expect(json['estimatedDurationSeconds'], 1800);
  });
}
