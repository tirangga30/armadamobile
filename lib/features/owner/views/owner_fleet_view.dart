import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/fleet_driver_model.dart';
import '../../../providers/fleet_provider.dart';

class OwnerFleetView extends StatefulWidget {
  const OwnerFleetView({super.key});

  @override
  State<OwnerFleetView> createState() => _OwnerFleetViewState();
}

class _OwnerFleetViewState extends State<OwnerFleetView> {
  String _filter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();

    final filteredDrivers = fleet.drivers.where((d) {
      final matchesFilter = _filter == 'ALL' || d.operationalStatus == _filter;
      final matchesSearch = _searchQuery.isEmpty ||
          d.driverName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Pelacakan & Radar Armada',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => fleet.fetchAllData(),
            tooltip: 'Perbarui Radar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Fleet Radar Hero Map Simulation Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Stack(
              children: [
                // Radar Rings Graphic
                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2), width: 1.5),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1.5),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Driver marker dots on radar
                Positioned(
                  top: 35,
                  right: 90,
                  child: _buildRadarPin('EMP-001', AppTheme.statusSuccess),
                ),
                // Top Info Bar
                Positioned(
                  top: 14,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LIVE FLEET RADAR',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DKI Jakarta & Sekitarnya',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${fleet.onlineDrivers} Armada Terhubung',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'GPS Ping: Auto Sync',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.statusSuccess,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari nama driver atau kode armada...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Semua (${fleet.drivers.length})'),
                _buildFilterChip('AVAILABLE', 'Tersedia (${fleet.availableDrivers})'),
                _buildFilterChip('DELIVERING', 'Sedang Kirim (${fleet.deliveringDrivers})'),
                _buildFilterChip('OFFLINE', 'Offline'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Driver List
          Expanded(
            child: filteredDrivers.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada driver sesuai filter.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, idx) {
                      final driver = filteredDrivers[idx];
                      return _buildDriverCard(driver);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarPin(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _buildDriverCard(FleetDriver driver) {
    final isAvailable = driver.operationalStatus == 'AVAILABLE';
    final isDelivering = driver.operationalStatus == 'DELIVERING' || driver.operationalStatus == 'DRIVING';

    Color statusColor = const Color(0xFF64748B);
    if (isAvailable) statusColor = AppTheme.statusSuccess;
    if (isDelivering) statusColor = AppTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.drive_eta_rounded, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.driverName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            driver.employeeCode,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  driver.operationalStatus,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Kendaraan: ${driver.plateNumber ?? "Belum Diatur"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                driver.location != null
                    ? 'GPS: ${driver.location!.latitude.toStringAsFixed(4)}, ${driver.location!.longitude.toStringAsFixed(4)}'
                    : 'Lokasi: Hub Cakung',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
