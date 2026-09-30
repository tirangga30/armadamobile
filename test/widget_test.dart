import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/auth/login_screen.dart';
import 'package:armada_mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';

void main() {
  testWidgets('LoginScreen smoke test with role presets', (WidgetTester tester) async {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final authProvider = AuthProvider(apiService: api, storageService: storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify Brand title is rendered
    expect(find.text('ARMADA MOBILE'), findsOneWidget);
    expect(find.text('Owner Hub'), findsOneWidget);
    expect(find.text('Driver Armada'), findsOneWidget);
  });
}
