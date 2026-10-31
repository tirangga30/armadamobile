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
      routeVersion: 2,
      source: 'RECOMMENDED_2OPT',
      recommendedSequence: [
        {'stopId': 'st-1', 'sequence': 1},
        {'stopId': 'st-2', 'sequence': 2},
      ],
    );

    final json = dto.toJson();
    expect(json['routeVersion'], 2);
    expect(json['source'], 'RECOMMENDED_2OPT');
    expect(json['recommendedSequence'].length, 2);
  });
}
