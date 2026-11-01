/// DTO for sending an E2EE encrypted message to POST /v1/conversations/:id/messages
class SendMessageDto {
  final String recipientDeviceId;
  final int protocolVersion;
  final String ciphertextBlob;
  final Map<String, dynamic> headerJson;
  final String? idempotencyKey;

  SendMessageDto({
    required this.recipientDeviceId,
    this.protocolVersion = 1,
    required this.ciphertextBlob,
    required this.headerJson,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'recipientDeviceId': recipientDeviceId,
        'protocolVersion': protocolVersion,
        'ciphertextBlob': ciphertextBlob,
        'headerJson': headerJson,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      };

  factory SendMessageDto.fromJson(Map<String, dynamic> json) => SendMessageDto(
        recipientDeviceId: json['recipientDeviceId']?.toString() ?? '',
        protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 1,
        ciphertextBlob: json['ciphertextBlob']?.toString() ?? '',
        headerJson: json['headerJson'] is Map<String, dynamic>
            ? json['headerJson'] as Map<String, dynamic>
            : {},
        idempotencyKey: json['idempotencyKey']?.toString(),
      );
}

/// 1:1 conversation model between Owner and Driver
class ConversationModel {
  final String id;
  final String? participantAId;
  final String? participantBId;
  final String? driverId;
  final String? driverName;
  final String? plateNumber;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String status;
  final DateTime? createdAt;

  ConversationModel({
    required this.id,
    this.participantAId,
    this.participantBId,
    String? driverId,
    this.driverName,
    this.plateNumber,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.status = 'ACTIVE',
    this.createdAt,
  }) : driverId = driverId ?? participantBId;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      participantAId: json['participantAId']?.toString() ?? json['ownerId']?.toString(),
      participantBId: json['participantBId']?.toString() ?? json['driverId']?.toString(),
      driverId: json['driverId']?.toString() ?? json['participantBId']?.toString(),
      driverName: json['driverName']?.toString() ??
          (json['driver'] is Map ? json['driver']['displayName']?.toString() : null),
      plateNumber: json['plateNumber']?.toString() ??
          (json['driver'] is Map ? json['driver']['plateNumber']?.toString() : null),
      lastMessagePreview: json['lastMessagePreview']?.toString() ??
          (json['lastMessage'] is Map ? json['lastMessage']['preview']?.toString() : null),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (participantAId != null) 'participantAId': participantAId,
        if (participantBId != null) 'participantBId': participantBId,
        if (driverId != null) 'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (plateNumber != null) 'plateNumber': plateNumber,
        if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
        if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
        'unreadCount': unreadCount,
        'status': status,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

/// Individual encrypted chat message model
class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderUserId;
  final String? senderDeviceId;
  final String? recipientDeviceId;
  final int protocolVersion;
  final String ciphertextBlob;
  final Map<String, dynamic> headerJson;
  final DateTime sentAt;
  final bool isDelivered;
  final bool isRead;
  final String? plaintextBody;
  final bool isOutgoing;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    String? senderId,
    String? senderUserId,
    this.senderDeviceId,
    this.recipientDeviceId,
    this.protocolVersion = 1,
    required this.ciphertextBlob,
    required this.headerJson,
    DateTime? sentAt,
    DateTime? createdAt,
    this.isDelivered = false,
    this.isRead = false,
    this.plaintextBody,
    this.isOutgoing = false,
  })  : senderId = senderId ?? senderUserId ?? '',
        senderUserId = senderUserId ?? senderId,
        sentAt = sentAt ?? createdAt ?? DateTime.now();

  DateTime get createdAt => sentAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId']?.toString() ?? json['senderUserId']?.toString() ?? '';
    final timeStr = json['sentAt']?.toString() ?? json['createdAt']?.toString();
    final time = timeStr != null ? DateTime.tryParse(timeStr) ?? DateTime.now() : DateTime.now();

    final read = json['isRead'] == true || json['readAt'] != null;
    final delivered = json['isDelivered'] == true || json['deliveredAt'] != null || read;

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: sender,
      senderUserId: json['senderUserId']?.toString() ?? sender,
      senderDeviceId: json['senderDeviceId']?.toString(),
      recipientDeviceId: json['recipientDeviceId']?.toString(),
      protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 1,
      ciphertextBlob: json['ciphertextBlob']?.toString() ?? '',
      headerJson: json['headerJson'] is Map<String, dynamic>
          ? json['headerJson'] as Map<String, dynamic>
          : {},
      sentAt: time,
      isDelivered: delivered,
      isRead: read,
      plaintextBody: json['plaintextBody']?.toString() ?? json['decryptedText']?.toString(),
      isOutgoing: json['isOutgoing'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        if (senderUserId != null) 'senderUserId': senderUserId,
        if (senderDeviceId != null) 'senderDeviceId': senderDeviceId,
        if (recipientDeviceId != null) 'recipientDeviceId': recipientDeviceId,
        'protocolVersion': protocolVersion,
        'ciphertextBlob': ciphertextBlob,
        'headerJson': headerJson,
        'sentAt': sentAt.toIso8601String(),
        'isDelivered': isDelivered,
        'isRead': isRead,
        if (plaintextBody != null) 'plaintextBody': plaintextBody,
        'isOutgoing': isOutgoing,
      };

  ChatMessageModel copyWith({
    String? plaintextBody,
    bool? isDelivered,
    bool? isRead,
    bool? isOutgoing,
  }) {
    return ChatMessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderUserId: senderUserId,
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipientDeviceId,
      protocolVersion: protocolVersion,
      ciphertextBlob: ciphertextBlob,
      headerJson: headerJson,
      sentAt: sentAt,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      plaintextBody: plaintextBody ?? this.plaintextBody,
      isOutgoing: isOutgoing ?? this.isOutgoing,
    );
  }
}
