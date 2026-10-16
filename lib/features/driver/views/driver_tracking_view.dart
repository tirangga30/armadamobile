import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/armada_osm_map.dart';
import '../../../providers/driver_tracking_provider.dart';

class DriverTrackingView extends StatelessWidget {
  const DriverTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<DriverTrackingProvider>();
    final pos = tracking.currentPosition;

    // Default to central logistics Jakarta if device GPS is still initialising
    final lat = pos?.latitude ?? -6.2088;
    final lng = pos?.longitude ?? 106.8456;
    final accuracy = pos?.accuracy ?? 5.0;
    final speed = (pos?.speed ?? 0.0) * 3.6; // m/s to km/h
    final driverLatLng = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Pelacak GPS & Telemetri',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // GPS Status Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: tracking.isTracking
                  ? const LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF334155), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tracking.isTracking ? AppTheme.statusSuccess : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tracking.isTracking ? 'TRANSMISI AKTIF' : 'TRANSMISI NONAKTIF',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Tersinkron: #${tracking.syncCount}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  tracking.trackingStatusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tracking.lastSyncTime != null
                      ? 'Waktu update: ${tracking.lastSyncTime!.toIso8601String().substring(11, 19)} UTC'
                      : 'Menunggu koneksi GPS pertama...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Real Interactive OpenStreetMap
          ArmadaOsmMap(
            height: 230,
            initialCenter: driverLatLng,
            initialZoom: 15.0,
            overlayBadgeText: tracking.isTracking ? 'GPS LIVE • OSM PUBLIK' : 'GPS STANDBY',
            circles: [
              CircleMarker(
                point: driverLatLng,
                radius: (accuracy < 12 ? 14.0 : accuracy).clamp(12.0, 50.0).toDouble(),
                useRadiusInMeter: false,
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderColor: AppTheme.primaryBlue,
                borderStrokeWidth: 1.5,
              ),
            ],
            markers: [
              Marker(
                point: driverLatLng,
                width: 60,
                height: 60,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Coordinates Grid
          Text(
            'Telemetri Lokasi Fisik Device',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTelemetryBox(
                  title: 'Latitude',
                  val: lat.toStringAsFixed(6),
                  icon: Icons.explore_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryBox(
                  title: 'Longitude',
                  val: lng.toStringAsFixed(6),
                  icon: Icons.explore_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryBox(
                  title: 'Akurasi GPS',
                  val: '±${accuracy.toStringAsFixed(1)} meter',
                  icon: Icons.gps_fixed_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryBox(
                  title: 'Kecepatan',
                  val: '${speed.toStringAsFixed(1)} km/h',
                  icon: Icons.speed_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Satellites & Power Efficiency Card
          Container(
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
                  children: [
                    const Icon(Icons.satellite_alt_rounded, color: AppTheme.statusSuccess, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Status Sinyal & Diagnostik Telemetri',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Satelit Navigasi', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                    Text('Terkunci (High Accuracy)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.statusSuccess)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mode Pembaruan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                    Text('Adaptive Interval (15 Detik)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Penyedia Peta (Map Tile)', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                    Text('OpenStreetMap (OSM)', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (tracking.isTracking) {
                  tracking.stopTracking();
                } else {
                  tracking.startTracking();
                }
              },
              icon: Icon(
                tracking.isTracking ? Icons.pause_circle_outline : Icons.play_circle_outline,
                size: 22,
              ),
              label: Text(
                tracking.isTracking ? 'Jeda Sinkronisasi GPS' : 'Mulai Sinkronisasi GPS Otomatis',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tracking.isTracking ? AppTheme.statusWarning : AppTheme.statusSuccess,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => tracking.pingNow(),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                'Kirim Ping Lokasi Seketika (Manual)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBox({
    required String title,
    required String val,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 16, color: AppTheme.primaryBlue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
