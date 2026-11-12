import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/route_geometry_model.dart';

void main() {
  test('SelectRouteDto serializes recommendedSequence strictly as UUID string list for NestJS DTO', () {
    final dto = SelectRouteDto(
      source: 'RECOMMENDED_2OPT',
      recommendedSequence: [
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440002',
      ],
      totalDistanceMeters: 12340.0,
      estimatedDurationSeconds: 1500,
    );

    final json = dto.toJson();
    expect(json['source'], 'RECOMMENDED_2OPT');
    expect(json['recommendedSequence'], isA<List<String>>());
    expect(json['recommendedSequence'][0], '550e8400-e29b-41d4-a716-446655440001');
    expect(json['totalDistanceMeters'], 12340.0);
    expect(json['estimatedDurationSeconds'], 1500);
    expect(json.containsKey('routeVersion'), isFalse);
  });

  test('RecommendRouteResponse extracts polyline points and stop UUID sequence', () {
    final json = {
      'deliveryId': 'del-1',
      'algorithm': '2-Opt',
      'providerUsed': 'osrm',
      'totalDistanceMeters': 9850.5,
      'estimatedDurationSeconds': 1120,
      'recommendedSequence': [
        {'sequence': 1, 'deliveryStopId': 'stop-uuid-1', 'destinationName': 'Toko 1'},
        {'sequence': 2, 'deliveryStopId': 'stop-uuid-2', 'destinationName': 'Toko 2'},
      ],
      'polylineGeojson': {
        'type': 'LineString',
        'coordinates': [
          [106.8272, -6.1754],
          [106.8456, -6.2088],
        ],
      },
    };

    final res = RecommendRouteResponse.fromJson(json);
    expect(res.totalDistanceMeters, 9850.5);
    expect(res.recommendedStopIds, ['stop-uuid-1', 'stop-uuid-2']);
    expect(res.recommendedStopNames, ['Toko 1', 'Toko 2']);
    expect(res.polylinePoints.length, 2);
    expect(res.polylinePoints.first.latitude, -6.1754);
  });
}
