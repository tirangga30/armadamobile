import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_tracking_provider.dart';
import 'views/driver_home_view.dart';
import 'views/driver_tracking_view.dart';
import 'views/driver_sos_view.dart';
import 'views/driver_profile_view.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    DriverHomeView(),
    DriverTrackingView(),
    DriverSosView(),
    DriverProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      final driverProvider = context.read<DriverTrackingProvider>();
      driverProvider.loadDriverDeliveries(driverId: user?.effectiveDriverId);
      // Auto-start GPS tracking on driver login as recommended in PRD
      driverProvider.startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<DriverTrackingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppTheme.statusSuccess.withOpacity(0.15),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded, color: AppTheme.statusSuccess),
                label: 'Tugas Saya',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: tracking.isTracking,
                  backgroundColor: AppTheme.statusSuccess,
                  smallSize: 8,
                  child: const Icon(Icons.location_on_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: tracking.isTracking,
                  backgroundColor: AppTheme.statusSuccess,
                  smallSize: 8,
                  child: const Icon(Icons.location_on_rounded, color: AppTheme.statusSuccess),
                ),
                label: 'GPS Tracker',
              ),
              const NavigationDestination(
                icon: Icon(Icons.warning_amber_rounded, color: AppTheme.statusDanger),
                selectedIcon: Icon(Icons.warning_rounded, color: AppTheme.statusDanger),
                label: 'SOS Darurat',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppTheme.statusSuccess),
                label: 'Profil Driver',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
