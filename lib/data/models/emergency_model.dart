class EmergencyModel {
  final String id;
  final String driverId;
  final String? deliveryId;
  final double latitude;
  final double longitude;
  final String emergencyType; // ACCIDENT, MEDICAL, VEHICLE_BREAKDOWN, SECURITY, OTHER
  final String? note;
  final String status; // TRIGGERED, ACKNOWLEDGED, RESOLVED, CANCELLED
  final String? triggeredAt;
  final String? resolvedAt;
  final String? resolvedBy;
  final EmergencyDriver? driver;

  EmergencyModel({
    required this.id,
    required this.driverId,
    this.deliveryId,
    required this.latitude,
    required this.longitude,
    required this.emergencyType,
    this.note,
    required this.status,
    this.triggeredAt,
    this.resolvedAt,
    this.resolvedBy,
    this.driver,
  });

  bool get isTriggered => status.toUpperCase() == 'TRIGGERED';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    EmergencyDriver? drv;
    if (json['driver'] != null && json['driver'] is Map<String, dynamic>) {
      drv = EmergencyDriver.fromJson(json['driver'] as Map<String, dynamic>);
    }

    return EmergencyModel(
      id: json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      deliveryId: json['deliveryId']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      emergencyType: json['emergencyType']?.toString() ?? 'ACCIDENT',
      note: json['note']?.toString(),
      status: json['status']?.toString() ?? 'TRIGGERED',
      triggeredAt: json['triggeredAt']?.toString(),
      resolvedAt: json['resolvedAt']?.toString(),
      resolvedBy: json['resolvedBy']?.toString(),
      driver: drv,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'deliveryId': deliveryId,
      'latitude': latitude,
      'longitude': longitude,
      'emergencyType': emergencyType,
      'note': note,
      'status': status,
      'triggeredAt': triggeredAt,
      'resolvedAt': resolvedAt,
      'resolvedBy': resolvedBy,
      'driver': driver?.toJson(),
    };
  }
}

class EmergencyDriver {
  final String id;
  final String displayName;
  final String? phone;
  final String employeeCode;

  EmergencyDriver({
    required this.id,
    required this.displayName,
    this.phone,
    required this.employeeCode,
  });

  factory EmergencyDriver.fromJson(Map<String, dynamic> json) {
    return EmergencyDriver(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Driver',
      phone: json['phone']?.toString(),
      employeeCode: json['employeeCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phone': phone,
      'employeeCode': employeeCode,
    };
  }
}
