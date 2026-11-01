import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/notifications/notification_center_view.dart';
import 'package:armada_mobile/core/widgets/emergency_alert_banner.dart';

void main() {
  testWidgets('NotificationCenterView displays title and empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationCenterView(
          initialNotifications: [],
        ),
      ),
    );

    expect(find.text('Pusat Notifikasi'), findsOneWidget);
  });

  testWidgets('EmergencyAlertBanner renders driver name and emergency type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmergencyAlertBanner(
            driverName: 'Driver Utama',
            emergencyType: 'ACCIDENT',
            onDismiss: () {},
            onViewMap: () {},
          ),
        ),
      ),
    );

    expect(find.text('PERINGATAN DARURAT: ACCIDENT'), findsOneWidget);
    expect(find.text('Driver Utama mengaktifkan sinyal SOS!'), findsOneWidget);
  });
}
