/// Ephemeral TURN credentials matching RFC 7635 returned during WebRTC call initialization
class TurnCredentialsModel {
  final List<String> urls;
  final String username;
  final String credential;
  final int ttlSeconds;

  TurnCredentialsModel({
    required this.urls,
    required this.username,
    required this.credential,
    this.ttlSeconds = 3600,
  });

  factory TurnCredentialsModel.fromJson(Map<String, dynamic> json) {
    return TurnCredentialsModel(
      urls: (json['urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      username: json['username']?.toString() ?? '',
      credential: json['credential']?.toString() ?? '',
      ttlSeconds: (json['ttlSeconds'] as num?)?.toInt() ?? 3600,
    );
  }

  Map<String, dynamic> toJson() => {
        'urls': urls,
        'username': username,
        'credential': credential,
        'ttlSeconds': ttlSeconds,
      };
}

/// WebRTC Call Session model representing 1:1 Voice PTT or Video session
class CallSessionModel {
  final String sessionId;
  final String type; // VOICE_PTT or VIDEO
  final String ownerId;
  final String driverId;
  final String? driverName;
  final String status; // PENDING, ACTIVE, DECLINED, ENDED
  final String? deliveryId;
  final TurnCredentialsModel? turnCredentials;
  final DateTime? startedAt;
  final DateTime? createdAt;

  CallSessionModel({
    required this.sessionId,
    required this.type,
    required this.ownerId,
    required this.driverId,
    this.driverName,
    this.status = 'PENDING',
    this.deliveryId,
    this.turnCredentials,
    this.startedAt,
    this.createdAt,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    TurnCredentialsModel? credentials;
    if (json['turnCredentials'] is Map<String, dynamic>) {
      credentials = TurnCredentialsModel.fromJson(
        json['turnCredentials'] as Map<String, dynamic>,
      );
    }

    return CallSessionModel(
      sessionId: json['sessionId']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'VOICE_PTT',
      ownerId: json['ownerId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      deliveryId: json['deliveryId']?.toString(),
      turnCredentials: credentials,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'type': type,
        'ownerId': ownerId,
        'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        'status': status,
        if (deliveryId != null) 'deliveryId': deliveryId,
        if (turnCredentials != null)
          'turnCredentials': turnCredentials!.toJson(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
