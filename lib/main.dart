import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/config/theme.dart';
import 'core/network/dio_client.dart';
import 'core/services/location_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'data/repositories/armada_api_service.dart';
import 'features/auth/login_screen.dart';
import 'features/driver/driver_shell.dart';
import 'features/owner/owner_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_tracking_provider.dart';
import 'providers/fleet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Core singletons
  final storageService = SecureStorageService();
  final dioClient = DioClient(storageService: storageService);
  final apiService = ArmadaApiService(client: dioClient);
  final locationService = LocationService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
          )..checkSession(),
        ),
        ChangeNotifierProvider<FleetProvider>(
          create: (_) => FleetProvider(apiService: apiService),
        ),
        ChangeNotifierProvider<DriverTrackingProvider>(
          create: (_) => DriverTrackingProvider(
            apiService: apiService,
            locationService: locationService,
          ),
        ),
      ],
      child: const ArmadaMobileApp(),
    ),
  );
}

class ArmadaMobileApp extends StatelessWidget {
  const ArmadaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// Dynamic Role-Based Routing Gateway
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.initial ||
        (auth.status == AuthStatus.authenticating && auth.user == null)) {
      return const SplashScreen();
    }

    if (auth.isAuthenticated && auth.user != null) {
      if (auth.isDriver) {
        return const DriverShell();
      } else {
        // OWNER or ADMIN enters the Owner Hub
        return const OwnerShell();
      }
    }

    return const LoginScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ARMADA MOBILE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Memuat Sesi Pengguna...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
