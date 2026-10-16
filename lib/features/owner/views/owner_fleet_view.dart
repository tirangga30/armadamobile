import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/armada_osm_map.dart';
import '../../../data/models/fleet_driver_model.dart';
import '../../../providers/fleet_provider.dart';

class OwnerFleetView extends StatefulWidget {
  const OwnerFleetView({super.key});

  @override
  State<OwnerFleetView> createState() => _OwnerFleetViewState();
}

class _OwnerFleetViewState extends State<OwnerFleetView> {
  final GlobalKey<ArmadaOsmMapState> _mapStateKey = GlobalKey<ArmadaOsmMapState>();
  String _filter = 'ALL';
  String _searchQuery = '';
  bool _isMapExpanded = false;

  // Default Central Warehouse Hub: Cakung Logistics Center, DKI Jakarta
  static const LatLng _centralHubLocation = LatLng(-6.1950, 106.9400);

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
            icon: Icon(_isMapExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
            tooltip: _isMapExpanded ? 'Perkecil Peta' : 'Perbesar Peta',
            onPressed: () {
              setState(() {
                _isMapExpanded = !_isMapExpanded;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => fleet.fetchAllData(),
            tooltip: 'Perbarui Radar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Interactive OpenStreetMap
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Stack(
              children: [
                ArmadaOsmMap(
                  key: _mapStateKey,
                  height: _isMapExpanded ? 380 : 230,
                  initialCenter: _getFleetCenter(fleet.drivers),
                  initialZoom: 12.0,
                  overlayBadgeText: '${fleet.onlineDrivers} Armada Live OSM',
                  onRecenter: () {
                    _mapStateKey.currentState?.moveTo(_getFleetCenter(fleet.drivers), 12.0);
                  },
                  markers: _buildOsmMarkers(fleet.drivers),
                  circles: [
                    CircleMarker(
                      point: _centralHubLocation,
                      radius: 35,
                      useRadiusInMeter: false,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderColor: AppTheme.primaryBlue,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

                // Map Size Toggle Button Overlay
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isMapExpanded = !_isMapExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          _isMapExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                          size: 18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
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

          // Drivers List
          Expanded(
            child: filteredDrivers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada data armada yang cocok.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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

  LatLng _getFleetCenter(List<FleetDriver> drivers) {
    for (final d in drivers) {
      if (d.location != null) {
        return LatLng(d.location!.latitude, d.location!.longitude);
      }
    }
    return _centralHubLocation;
  }

  List<Marker> _buildOsmMarkers(List<FleetDriver> drivers) {
    final markers = <Marker>[];

    // Central Hub Warehouse Marker
    markers.add(
      Marker(
        point: _centralHubLocation,
        width: 100,
        height: 60,
        child: GestureDetector(
          onTap: () {
            _showHubModal();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HUB CAKUNG',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );

    // Driver Markers
    for (int i = 0; i < drivers.length; i++) {
      final driver = drivers[i];
      final LatLng pos;
      if (driver.location != null) {
        pos = LatLng(driver.location!.latitude, driver.location!.longitude);
      } else {
        // Place standby drivers slightly offset around Cakung Hub for clear visibility
        pos = LatLng(
          _centralHubLocation.latitude + (0.012 * (i + 1)),
          _centralHubLocation.longitude + (0.015 * ((i % 2 == 0) ? 1 : -1)),
        );
      }

      final isAvailable = driver.operationalStatus == 'AVAILABLE';
      final isDelivering = driver.operationalStatus == 'DELIVERING' || driver.operationalStatus == 'DRIVING';

      Color statusColor = const Color(0xFF64748B);
      if (isAvailable) statusColor = AppTheme.statusSuccess;
      if (isDelivering) statusColor = AppTheme.primaryBlue;

      markers.add(
        Marker(
          point: pos,
          width: 90,
          height: 60,
          child: GestureDetector(
            onTap: () => _showDriverDetailSheet(driver, pos),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Text(
                    driver.employeeCode,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showHubModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.warehouse_rounded, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Distribusi Hub Cakung',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Pusat Komando & Gudang Transit Utama',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'Koordinat: ${_centralHubLocation.latitude}, ${_centralHubLocation.longitude}',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              Text(
                'Wilayah Cakupan: DKI Jakarta, Bekasi, Tangerang, & Depok',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDriverDetailSheet(FleetDriver driver, LatLng pos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.drive_eta_rounded, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.driverName,
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            driver.employeeCode,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusSuccess.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      driver.operationalStatus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusSuccess,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kendaraan', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B))),
                  Text(driver.plateNumber ?? 'Belum Ditugaskan', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Koordinat Realtime', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF64748B))),
                  Text('${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _mapStateKey.currentState?.moveTo(pos, 15.0);
                  },
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Fokus Peta ke Driver Ini'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

    final LatLng driverPos = driver.location != null
        ? LatLng(driver.location!.latitude, driver.location!.longitude)
        : _centralHubLocation;

    return InkWell(
      onTap: () {
        _mapStateKey.currentState?.moveTo(driverPos, 15.0);
        _showDriverDetailSheet(driver, driverPos);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}
