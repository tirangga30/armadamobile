import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../data/models/outbox_event_model.dart';

class LocalOutboxService {
  static final LocalOutboxService _instance = LocalOutboxService._internal();
  factory LocalOutboxService() => _instance;
  LocalOutboxService._internal();

  final List<OutboxEventItemDto> _queue = [];
  final _uuid = const Uuid();

  /// Enqueues an offline mutation event with persistent UUIDs
  Future<void> enqueue({
    required String eventType,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    final event = OutboxEventItemDto(
      clientEventId: _uuid.v4(),
      idempotencyKey: idempotencyKey ?? _uuid.v4(),
      eventType: eventType,
      occurredAt: DateTime.now().toUtc(),
      payload: payload,
    );
    _queue.add(event);
  }

  /// Total pending items in the offline queue
  int get pendingCount => _queue.length;

  /// Returns up to [limit] events from the queue (strictly capped at 50 per backend contract)
  List<OutboxEventItemDto> getPendingEvents({int limit = 50}) {
    final effectiveLimit = min(min(limit, 50), _queue.length);
    return List.unmodifiable(_queue.take(effectiveLimit));
  }

  /// Acknowledges and removes processed event IDs from the offline queue
  Future<void> acknowledge(List<String> clientEventIds) async {
    final idSet = clientEventIds.toSet();
    _queue.removeWhere((e) => idSet.contains(e.clientEventId));
  }

  /// Clears the queue (used for testing or resetting session)
  void clear() {
    _queue.clear();
  }
}
