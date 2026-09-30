class DeliveryModel {
  final String id;
  final String orderNumber;
  final String clientName;
  final String origin;
  final String destination;
  final String status; // ASSIGNED, ACCEPTED, EN_ROUTE, ARRIVED, UNLOADING, DELIVERED, COMPLETED, FAILED, CANCELLED
  final String? assignedDriver;
  final String? driverId;
  final String? plateNumber;
  final int totalItems;
  final double totalWeightKg;
  final String? createdAt;
  final List<DeliveryStop> stops;

  DeliveryModel({
    required this.id,
    required this.orderNumber,
    required this.clientName,
    required this.origin,
    required this.destination,
    required this.status,
    this.assignedDriver,
    this.driverId,
    this.plateNumber,
    this.totalItems = 1,
    this.totalWeightKg = 0.0,
    this.createdAt,
    this.stops = const [],
  });

  bool get isAssigned => status == 'ASSIGNED';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isEnRoute => status == 'EN_ROUTE';
  bool get isArrived => status == 'ARRIVED';
  bool get isDelivered => status == 'DELIVERED';
  bool get isCompleted => status == 'COMPLETED';

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    List<DeliveryStop> parsedStops = [];
    if (json['stops'] != null && json['stops'] is List) {
      parsedStops = (json['stops'] as List)
          .map((s) => DeliveryStop.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return DeliveryModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? json['id']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? 'Klien Distribusi',
      origin: json['origin']?.toString() ?? 'Gudang Pusat',
      destination: json['destination']?.toString() ?? 'Tujuan Pengiriman',
      status: (json['status']?.toString() ?? 'ASSIGNED').toUpperCase(),
      assignedDriver: json['assignedDriver']?.toString() ?? json['driver']?['displayName']?.toString(),
      driverId: json['driverId']?.toString() ?? json['driver']?['id']?.toString(),
      plateNumber: json['plateNumber']?.toString() ?? json['vehicle']?['plateNumber']?.toString(),
      totalItems: (json['totalItems'] is int)
          ? json['totalItems']
          : int.tryParse(json['totalItems']?.toString() ?? '1') ?? 1,
      totalWeightKg: (json['totalWeightKg'] is num)
          ? (json['totalWeightKg'] as num).toDouble()
          : double.tryParse(json['totalWeightKg']?.toString() ?? '0.0') ?? 0.0,
      createdAt: json['createdAt']?.toString(),
      stops: parsedStops,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'clientName': clientName,
      'origin': origin,
      'destination': destination,
      'status': status,
      'assignedDriver': assignedDriver,
      'driverId': driverId,
      'plateNumber': plateNumber,
      'totalItems': totalItems,
      'totalWeightKg': totalWeightKg,
      'createdAt': createdAt,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }

  DeliveryModel copyWith({
    String? status,
    String? assignedDriver,
    String? driverId,
    String? plateNumber,
  }) {
    return DeliveryModel(
      id: id,
      orderNumber: orderNumber,
      clientName: clientName,
      origin: origin,
      destination: destination,
      status: status ?? this.status,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      driverId: driverId ?? this.driverId,
      plateNumber: plateNumber ?? this.plateNumber,
      totalItems: totalItems,
      totalWeightKg: totalWeightKg,
      createdAt: createdAt,
      stops: stops,
    );
  }
}

class DeliveryStop {
  final String id;
  final int sequence;
  final String destinationName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String status; // PENDING, ARRIVED, COMPLETED, FAILED

  DeliveryStop({
    required this.id,
    required this.sequence,
    required this.destinationName,
    required this.address,
    this.latitude,
    this.longitude,
    this.status = 'PENDING',
  });

  factory DeliveryStop.fromJson(Map<String, dynamic> json) {
    return DeliveryStop(
      id: json['id']?.toString() ?? '',
      sequence: (json['sequence'] is int)
          ? json['sequence']
          : int.tryParse(json['sequence']?.toString() ?? '1') ?? 1,
      destinationName: json['destinationName']?.toString() ?? 'Stop',
      address: json['address']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequence': sequence,
      'destinationName': destinationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
