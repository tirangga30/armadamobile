class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? phone;
  final String role; // OWNER, DRIVER, ADMIN
  final String? status;
  final String? driverId;
  final List<String> permissions;
  final DriverProfile? driver;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    required this.role,
    this.status,
    this.driverId,
    this.permissions = const [],
    this.driver,
    this.createdAt,
  });

  bool get isOwner => role.toUpperCase() == 'OWNER';
  bool get isDriver => role.toUpperCase() == 'DRIVER';
  bool get isAdmin => role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'SUPER_ADMIN';

  String get effectiveDriverId => driver?.id ?? driverId ?? '';

  String get displayName {
    if (driver?.displayName != null && driver!.displayName.isNotEmpty) {
      return driver!.displayName;
    }
    return username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If the json has a nested 'driver' object, extract its id if driverId is null
    DriverProfile? driverObj;
    if (json['driver'] != null && json['driver'] is Map<String, dynamic>) {
      driverObj = DriverProfile.fromJson(json['driver'] as Map<String, dynamic>);
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: (json['role']?.toString() ?? 'DRIVER').toUpperCase(),
      status: json['status']?.toString(),
      driverId: json['driverId']?.toString() ?? driverObj?.id,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      driver: driverObj,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'driverId': driverId,
      'permissions': permissions,
      'driver': driver?.toJson(),
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? driverId,
    List<String>? permissions,
    DriverProfile? driver,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      permissions: permissions ?? this.permissions,
      driver: driver ?? this.driver,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DriverProfile {
  final String id;
  final String? userId;
  final String? organizationId;
  final String employeeCode;
  final String displayName;
  final String? phone;
  final String? activeVehicleId;
  final String operationalStatus; // OFFLINE, ONLINE, AVAILABLE, ASSIGNED, DRIVING, ARRIVED, DELIVERING

  DriverProfile({
    required this.id,
    this.userId,
    this.organizationId,
    required this.employeeCode,
    required this.displayName,
    this.phone,
    this.activeVehicleId,
    this.operationalStatus = 'AVAILABLE',
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      organizationId: json['organizationId']?.toString(),
      employeeCode: json['employeeCode']?.toString() ?? 'DRV-001',
      displayName: json['displayName']?.toString() ?? 'Driver',
      phone: json['phone']?.toString(),
      activeVehicleId: json['activeVehicleId']?.toString(),
      operationalStatus: (json['operationalStatus']?.toString() ?? 'AVAILABLE').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'employeeCode': employeeCode,
      'displayName': displayName,
      'phone': phone,
      'activeVehicleId': activeVehicleId,
      'operationalStatus': operationalStatus,
    };
  }
}

class AuthData {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn'] is int ? json['expiresIn'] : int.tryParse(json['expiresIn']?.toString() ?? '900') ?? 900,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
