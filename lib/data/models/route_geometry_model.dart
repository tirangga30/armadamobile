import 'package:latlong2/latlong.dart';

/// Representation of delivery route polyline geometry and metrics from backend
class RouteGeometryModel {
  final String? routeId;
  final String deliveryId;
  final int version;
  final String source;
  final double totalDistanceMeters;
  final int estimatedDurationSeconds;
  final List<LatLng> polylinePoints;
  final Map<String, dynamic>? rawGeoJson;

  RouteGeometryModel({
    this.routeId,
    required this.deliveryId,
    required this.version,
    required this.source,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    required this.polylinePoints,
    this.rawGeoJson,
  });

  factory RouteGeometryModel.fromJson(Map<String, dynamic> json) {
    final List<LatLng> points = [];
    Map<String, dynamic>? geoJsonMap;

    if (json['polylineGeojson'] != null && json['polylineGeojson'] is Map<String, dynamic>) {
      geoJsonMap = json['polylineGeojson'] as Map<String, dynamic>;
      if (geoJsonMap['coordinates'] != null && geoJsonMap['coordinates'] is List) {
        final coords = geoJsonMap['coordinates'] as List;
        for (final item in coords) {
          if (item is List && item.length >= 2) {
            // CRITICAL: GeoJSON coordinates are in [longitude, latitude] order per RFC 7946.
            // LatLng expects (latitude, longitude).
            final lng = (item[0] as num).toDouble();
            final lat = (item[1] as num).toDouble();
            points.add(LatLng(lat, lng));
          }
        }
      }
    }

    return RouteGeometryModel(
      routeId: json['routeId']?.toString() ?? json['id']?.toString(),
      deliveryId: json['deliveryId']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? 'MANUAL',
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toDouble() ??
          (json['totalDistanceM'] as num?)?.toDouble() ??
          0.0,
      estimatedDurationSeconds: (json['estimatedDurationSeconds'] as num?)?.toInt() ??
          (json['estimatedDurationS'] as num?)?.toInt() ??
          0,
      polylinePoints: points,
      rawGeoJson: geoJsonMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (routeId != null) 'routeId': routeId,
      'deliveryId': deliveryId,
      'version': version,
      'source': source,
      'totalDistanceMeters': totalDistanceMeters,
      'estimatedDurationSeconds': estimatedDurationSeconds,
      'polylineGeojson': rawGeoJson ??
          {
            'type': 'LineString',
            'coordinates': polylinePoints.map((p) => [p.longitude, p.latitude]).toList(),
          },
    };
  }
}

/// Request DTO for selecting route sequence via POST /v1/deliveries/:id/routes/select
class SelectRouteDto {
  final int routeVersion;
  final String source;
  final List<dynamic> recommendedSequence;
  final double? totalDistanceMeters;
  final int? estimatedDurationSeconds;
  final String? idempotencyKey;

  SelectRouteDto({
    required this.routeVersion,
    required this.source,
    required this.recommendedSequence,
    this.totalDistanceMeters,
    this.estimatedDurationSeconds,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeVersion': routeVersion,
      'source': source,
      'recommendedSequence': recommendedSequence,
      if (totalDistanceMeters != null) 'totalDistanceMeters': totalDistanceMeters,
      if (estimatedDurationSeconds != null) 'estimatedDurationSeconds': estimatedDurationSeconds,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }
}

/// Recommendation response returned by POST /v1/deliveries/:id/routes/recommend
class RecommendRouteResponse {
  final String deliveryId;
  final String provider;
  final double totalDistanceMeters;
  final int estimatedDurationSeconds;
  final List<LatLng> polylinePoints;
  final List<dynamic> recommendedSequence;

  RecommendRouteResponse({
    required this.deliveryId,
    required this.provider,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    required this.polylinePoints,
    required this.recommendedSequence,
  });

  factory RecommendRouteResponse.fromJson(Map<String, dynamic> json) {
    final List<LatLng> points = [];
    if (json['geometry'] != null && json['geometry']['coordinates'] is List) {
      final coords = json['geometry']['coordinates'] as List;
      for (final item in coords) {
        if (item is List && item.length >= 2) {
          final lng = (item[0] as num).toDouble();
          final lat = (item[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }
    } else if (json['polylineGeojson'] != null && json['polylineGeojson']['coordinates'] is List) {
      final coords = json['polylineGeojson']['coordinates'] as List;
      for (final item in coords) {
        if (item is List && item.length >= 2) {
          final lng = (item[0] as num).toDouble();
          final lat = (item[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }
    }

    return RecommendRouteResponse(
      deliveryId: json['deliveryId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'osrm',
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationSeconds: (json['estimatedDurationSeconds'] as num?)?.toInt() ?? 0,
      polylinePoints: points,
      recommendedSequence: (json['recommendedSequence'] is List) ? json['recommendedSequence'] as List : [],
    );
  }
}
