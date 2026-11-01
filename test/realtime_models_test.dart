import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/realtime_envelope.dart';
import 'package:armada_mobile/data/models/notification_model.dart';

void main() {
  test('RealtimeEnvelope parses incoming driver.location.updated event', () {
    final json = {
      'eventId': 'ev-01',
      'event': 'driver.location.updated',
      'version': 1,
      'timestamp': '2026-10-31T08:30:00.000Z',
      'payload': {
        'driverId': 'drv-123',
        'latitude': -6.2001,
        'longitude': 106.8162,
        'speedMps': 12.5,
        'headingDeg': 90.0,
        'recordedAt': '2026-10-31T08:30:00.000Z',
      },
    };

    final env = RealtimeEnvelope.fromJson(
      json,
      (p) => RealtimeLocationPayload.fromJson(p as Map<String, dynamic>),
    );
    expect(env.event, 'driver.location.updated');
    expect(env.payload.driverId, 'drv-123');
    expect(env.payload.latitude, -6.2001);
    expect(env.payload.longitude, 106.8162);
  });

  test('NotificationModel parses notification object from backend', () {
    final notif = NotificationModel.fromJson({
      'id': 'notif-01',
      'type': 'EMERGENCY_ALERT',
      'title': 'Peringatan Darurat!',
      'body': 'Driver Pak Budi memicu SOS',
      'status': 'SENT',
      'createdAt': '2026-10-31T08:30:00.000Z',
    });
    expect(notif.isRead, isFalse);
    expect(notif.type, 'EMERGENCY_ALERT');
    expect(notif.title, 'Peringatan Darurat!');
  });
}
