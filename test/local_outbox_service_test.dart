import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/outbox_event_model.dart';
import 'package:armada_mobile/core/services/local_outbox_service.dart';

void main() {
  test('LocalOutboxService enqueues, limits batch to 50, and acknowledges events', () async {
    final outbox = LocalOutboxService();
    outbox.clear();

    await outbox.enqueue(
      eventType: 'stop.arrived',
      payload: {'stopId': 'st-01', 'latitude': -6.2088},
    );

    final pending = outbox.getPendingEvents(limit: 50);
    expect(pending.length, 1);
    expect(pending.first.eventType, 'stop.arrived');
    expect(pending.first.clientEventId, isNotEmpty);
    expect(pending.first.idempotencyKey, isNotNull);

    await outbox.acknowledge([pending.first.clientEventId]);
    expect(outbox.pendingCount, 0);
  });

  test('OutboxSyncDto serializes events list correctly', () {
    final dto = OutboxSyncDto(events: [
      OutboxEventItemDto(
        clientEventId: 'evt-01',
        idempotencyKey: 'idem-01',
        eventType: 'stop.departed',
        occurredAt: DateTime.now(),
        payload: {'stopId': 'st-01'},
      ),
    ]);
    final json = dto.toJson();
    expect((json['events'] as List).length, 1);
    expect(json['events'][0]['eventType'], 'stop.departed');
  });
}
