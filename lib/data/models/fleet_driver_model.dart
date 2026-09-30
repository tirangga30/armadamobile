class FleetDriver {
  final String driverId;
  final String driverName;
  final String employeeCode;
  final String operationalStatus; // OFFLINE, ONLINE, AVAILABLE, ASSIGNED, DRIVING, ARRIVED, DELIVERING
  final String? activeVehicleId;
  final String? plateNumber;
  final String? currentDeliveryId;
  final DriverLocation? location;

  FleetDriver({
    required this.driverId,
    required this.driverName,
    required this.employeeCode,
    required this.operationalStatus,
    this.activeVehicleId,
    this.plateNumber,
    this.currentDeliveryId,
    this.location,
  });

  bool get isOnline => operationalStatus != 'OFFLINE';
  bool get isDelivering => operationalStatus == 'DELIVERING' || operationalStatus == 'DRIVING';

  factory FleetDriver.fromJson(Map<String, dynamic> json) {
    DriverLocation? loc;
    if (json['location'] != null && json['location'] is Map<String, dynamic>) {
      loc = DriverLocation.fromJson(json['location'] as Map<String, dynamic>);
    }

    return FleetDriver(
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? 'Driver',
      employeeCode: json['employeeCode']?.toString() ?? '',
      operationalStatus: (json['operationalStatus']?.toString() ?? 'OFFLINE').toUpperCase(),
      activeVehicleId: json['activeVehicleId']?.toString(),
      plateNumber: json['plateNumber']?.toString(),
      currentDeliveryId: json['currentDeliveryId']?.toString(),
      location: loc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'employeeCode': employeeCode,
      'operationalStatus': operationalStatus,
      'activeVehicleId': activeVehicleId,
      'plateNumber': plateNumber,
      'currentDeliveryId': currentDeliveryId,
      'location': location?.toJson(),
    };
  }
}

class DriverLocation {
  final double latitude;
  final double longitude;
  final double? accuracyM;
  final double? speedMps;
  final double? headingDeg;
  final String? recordedAt;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    this.speedMps,
    this.headingDeg,
    this.recordedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      accuracyM: (json['accuracyM'] is num) ? (json['accuracyM'] as num).toDouble() : double.tryParse(json['accuracyM']?.toString() ?? ''),
      speedMps: (json['speedMps'] is num) ? (json['speedMps'] as num).toDouble() : double.tryParse(json['speedMps']?.toString() ?? ''),
      headingDeg: (json['headingDeg'] is num) ? (json['headingDeg'] as num).toDouble() : double.tryParse(json['headingDeg']?.toString() ?? ''),
      recordedAt: json['recordedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracyM': accuracyM,
      'speedMps': speedMps,
      'headingDeg': headingDeg,
      'recordedAt': recordedAt,
    };
  }
}
