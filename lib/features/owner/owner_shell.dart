import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme.dart';
import '../../providers/fleet_provider.dart';
import 'views/owner_dashboard_view.dart';
import 'views/owner_fleet_view.dart';
import 'views/owner_deliveries_view.dart';
import 'views/owner_emergency_view.dart';
import 'views/owner_profile_view.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    OwnerDashboardView(),
    OwnerFleetView(),
    OwnerDeliveriesView(),
    OwnerEmergencyView(),
    OwnerProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Initial fetch of fleet metrics and emergency alerts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();
    final emergencyCount = fleet.activeEmergenciesCount;

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
            indicatorColor: AppTheme.primaryBlue.withOpacity(0.12),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryBlue),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping_rounded, color: AppTheme.primaryBlue),
                label: 'Armada',
              ),
              const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded, color: AppTheme.primaryBlue),
                label: 'Pesanan',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: emergencyCount > 0,
                  label: Text('$emergencyCount'),
                  backgroundColor: AppTheme.statusDanger,
                  child: const Icon(Icons.warning_amber_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: emergencyCount > 0,
                  label: Text('$emergencyCount'),
                  backgroundColor: AppTheme.statusDanger,
                  child: const Icon(Icons.warning_rounded, color: AppTheme.statusDanger),
                ),
                label: 'Darurat SOS',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
