/// Cargo item definition for new delivery orders
class CreateDeliveryItemDto {
  final String itemCode;
  final String itemName;
  final int quantity;
  final String unit;
  final double weightKg;
  final double? volumeM3;

  CreateDeliveryItemDto({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    this.unit = 'DUS',
    this.weightKg = 0.0,
    this.volumeM3,
  });

  factory CreateDeliveryItemDto.fromJson(Map<String, dynamic> json) {
    return CreateDeliveryItemDto(
      itemCode: json['itemCode']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unit: json['unit']?.toString() ?? 'DUS',
      weightKg: (json['weightKg'] is num)
          ? (json['weightKg'] as num).toDouble()
          : double.tryParse(json['weightKg']?.toString() ?? '0.0') ?? 0.0,
      volumeM3: (json['volumeM3'] is num)
          ? (json['volumeM3'] as num).toDouble()
          : double.tryParse(json['volumeM3']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
    };
  }
}

/// Destination stop definition for multi-stop delivery creation
class CreateDeliveryStopDto {
  final int sequence;
  final String destinationName;
  final String address;
  final double latitude;
  final double longitude;
  final int geofenceRadiusM;
  final String? contactPerson;
  final String? contactPhone;

  CreateDeliveryStopDto({
    required this.sequence,
    required this.destinationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusM = 100,
    this.contactPerson,
    this.contactPhone,
  });

  factory CreateDeliveryStopDto.fromJson(Map<String, dynamic> json) {
    return CreateDeliveryStopDto(
      sequence: (json['sequence'] is num)
          ? (json['sequence'] as num).toInt()
          : int.tryParse(json['sequence']?.toString() ?? '1') ?? 1,
      destinationName: json['destinationName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      geofenceRadiusM: (json['geofenceRadiusM'] is num)
          ? (json['geofenceRadiusM'] as num).toInt()
          : int.tryParse(json['geofenceRadiusM']?.toString() ?? '100') ?? 100,
      contactPerson: json['contactPerson']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sequence': sequence,
      'destinationName': destinationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadiusM': geofenceRadiusM,
      if (contactPerson != null && contactPerson!.isNotEmpty) 'contactPerson': contactPerson,
      if (contactPhone != null && contactPhone!.isNotEmpty) 'contactPhone': contactPhone,
    };
  }
}

/// Request payload for creating a new delivery via POST /v1/deliveries
class CreateDeliveryDto {
  final String deliveryCode;
  final String? customerName;
  final String? notes;
  final String? plannedStartAt;
  final List<CreateDeliveryItemDto> items;
  final List<CreateDeliveryStopDto> stops;

  CreateDeliveryDto({
    required this.deliveryCode,
    this.customerName,
    this.notes,
    this.plannedStartAt,
    this.items = const [],
    this.stops = const [],
  });

  factory CreateDeliveryDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawStops = json['stops'];

    return CreateDeliveryDto(
      deliveryCode: json['deliveryCode']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? json['clientName']?.toString(),
      notes: json['notes']?.toString(),
      plannedStartAt: json['plannedStartAt']?.toString(),
      items: rawItems is List
          ? rawItems.map((e) => CreateDeliveryItemDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      stops: rawStops is List
          ? rawStops.map((e) => CreateDeliveryStopDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryCode': deliveryCode,
      if (customerName != null && customerName!.isNotEmpty) 'customerName': customerName,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (plannedStartAt != null && plannedStartAt!.isNotEmpty) 'plannedStartAt': plannedStartAt,
      'items': items.map((i) => i.toJson()).toList(),
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }

  double get totalWeightKg => items.fold(0.0, (sum, item) => sum + (item.weightKg * item.quantity));
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Request payload for assigning driver and vehicle to delivery via POST /v1/deliveries/:id/assign
class AssignDeliveryDto {
  final String driverId;
  final String vehicleId;
  final String? notes;

  AssignDeliveryDto({
    required this.driverId,
    required this.vehicleId,
    this.notes,
  });

  factory AssignDeliveryDto.fromJson(Map<String, dynamic> json) {
    return AssignDeliveryDto(
      driverId: json['driverId']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'vehicleId': vehicleId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
