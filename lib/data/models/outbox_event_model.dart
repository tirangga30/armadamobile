/// Single offline event item queued locally for synchronization to POST /v1/me/sync/outbox
class OutboxEventItemDto {
  final String clientEventId;
  final String idempotencyKey;
  final String eventType;
  final DateTime occurredAt;
  final Map<String, dynamic> payload;

  OutboxEventItemDto({
    required this.clientEventId,
    required this.idempotencyKey,
    required this.eventType,
    required this.occurredAt,
    required this.payload,
  });

  factory OutboxEventItemDto.fromJson(Map<String, dynamic> json) {
    return OutboxEventItemDto(
      clientEventId: json['clientEventId']?.toString() ?? '',
      idempotencyKey: json['idempotencyKey']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      occurredAt: json['occurredAt'] != null
          ? DateTime.tryParse(json['occurredAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'clientEventId': clientEventId,
        'idempotencyKey': idempotencyKey,
        'eventType': eventType,
        'occurredAt': occurredAt.toIso8601String(),
        'payload': payload,
      };
}

/// Request payload for batch offline outbox sync (Maximum 50 events per batch)
class OutboxSyncDto {
  final List<OutboxEventItemDto> events;

  OutboxSyncDto({required this.events});

  factory OutboxSyncDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['events'];
    return OutboxSyncDto(
      events: rawList is List
          ? rawList.map((e) => OutboxEventItemDto.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
      };
}

/// Response returned by POST /v1/me/sync/outbox
class OutboxSyncResponse {
  final List<String> acked;
  final List<dynamic> conflicts;

  OutboxSyncResponse({
    required this.acked,
    required this.conflicts,
  });

  factory OutboxSyncResponse.fromJson(Map<String, dynamic> json) {
    return OutboxSyncResponse(
      acked: (json['acked'] as List?)?.map((e) => e.toString()).toList() ?? [],
      conflicts: (json['conflicts'] as List?) ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'acked': acked,
        'conflicts': conflicts,
      };
}
