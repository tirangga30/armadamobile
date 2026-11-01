/// Generic envelope wrapper for WebSocket events matching backend standard
class RealtimeEnvelope<T> {
  final String eventId;
  final String event;
  final int version;
  final DateTime timestamp;
  final String? correlationId;
  final Map<String, dynamic>? actor;
  final T payload;

  RealtimeEnvelope({
    required this.eventId,
    required this.event,
    required this.version,
    required this.timestamp,
    this.correlationId,
    this.actor,
    required this.payload,
  });

  factory RealtimeEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromPayload,
  ) {
    return RealtimeEnvelope(
      eventId: json['eventId']?.toString() ?? '',
      event: json['event']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      correlationId: json['correlationId']?.toString(),
      actor: json['actor'] is Map<String, dynamic> ? json['actor'] as Map<String, dynamic> : null,
      payload: fromPayload(json['payload']),
    );
  }

  Map<String, dynamic> toJson([dynamic Function(T)? toPayload]) {
    return {
      'eventId': eventId,
      'event': event,
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      if (correlationId != null) 'correlationId': correlationId,
      if (actor != null) 'actor': actor,
      'payload': toPayload != null ? toPayload(payload) : payload,
    };
  }
}

/// Payload for 'driver.location.updated' event
class RealtimeLocationPayload {
  final String driverId;
  final String? deliveryId;
  final double latitude;
  final double longitude;
  final double? accuracyM;
  final double? speedMps;
  final double? headingDeg;
  final String? recordedAt;
  final String? receivedAt;

  RealtimeLocationPayload({
    required this.driverId,
    this.deliveryId,
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    this.speedMps,
    this.headingDeg,
    this.recordedAt,
    this.receivedAt,
  });

  factory RealtimeLocationPayload.fromJson(Map<String, dynamic> json) {
    return RealtimeLocationPayload(
      driverId: json['driverId']?.toString() ?? '',
      deliveryId: json['deliveryId']?.toString(),
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      accuracyM: (json['accuracyM'] is num)
          ? (json['accuracyM'] as num).toDouble()
          : double.tryParse(json['accuracyM']?.toString() ?? ''),
      speedMps: (json['speedMps'] is num)
          ? (json['speedMps'] as num).toDouble()
          : double.tryParse(json['speedMps']?.toString() ?? ''),
      headingDeg: (json['headingDeg'] is num)
          ? (json['headingDeg'] as num).toDouble()
          : double.tryParse(json['headingDeg']?.toString() ?? ''),
      recordedAt: json['recordedAt']?.toString(),
      receivedAt: json['receivedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      if (deliveryId != null) 'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracyM != null) 'accuracyM': accuracyM,
      if (speedMps != null) 'speedMps': speedMps,
      if (headingDeg != null) 'headingDeg': headingDeg,
      if (recordedAt != null) 'recordedAt': recordedAt,
      if (receivedAt != null) 'receivedAt': receivedAt,
    };
  }
}

/// Payload for 'delivery.status_changed' event
class RealtimeDeliveryStatusPayload {
  final String deliveryId;
  final String? previousStatus;
  final String newStatus;
  final String? updatedAt;
  final Map<String, dynamic>? actor;

  RealtimeDeliveryStatusPayload({
    required this.deliveryId,
    this.previousStatus,
    required this.newStatus,
    this.updatedAt,
    this.actor,
  });

  factory RealtimeDeliveryStatusPayload.fromJson(Map<String, dynamic> json) {
    return RealtimeDeliveryStatusPayload(
      deliveryId: json['deliveryId']?.toString() ?? '',
      previousStatus: json['previousStatus']?.toString(),
      newStatus: json['status']?.toString() ?? json['newStatus']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? json['timestamp']?.toString(),
      actor: json['actor'] is Map<String, dynamic> ? json['actor'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryId': deliveryId,
      if (previousStatus != null) 'previousStatus': previousStatus,
      'status': newStatus,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (actor != null) 'actor': actor,
    };
  }
}

/// Payload for 'emergency.triggered' event
class RealtimeEmergencyPayload {
  final String emergencyId;
  final String driverId;
  final String? driverName;
  final String emergencyType;
  final double latitude;
  final double longitude;
  final String? note;
  final String? triggeredAt;

  RealtimeEmergencyPayload({
    required this.emergencyId,
    required this.driverId,
    this.driverName,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    this.note,
    this.triggeredAt,
  });

  factory RealtimeEmergencyPayload.fromJson(Map<String, dynamic> json) {
    return RealtimeEmergencyPayload(
      emergencyId: json['emergencyId']?.toString() ?? json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString(),
      emergencyType: json['emergencyType']?.toString() ?? 'SOS',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      note: json['note']?.toString(),
      triggeredAt: json['triggeredAt']?.toString() ?? json['timestamp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emergencyId': emergencyId,
      'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      'emergencyType': emergencyType,
      'latitude': latitude,
      'longitude': longitude,
      if (note != null) 'note': note,
      if (triggeredAt != null) 'triggeredAt': triggeredAt,
    };
  }
}
