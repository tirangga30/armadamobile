import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/delivery_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/driver_tracking_provider.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.user;
    final tracking = context.watch<DriverTrackingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ARMADA DRIVER MOBILE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.statusSuccess,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Driver Operasional Distribusi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => tracking.loadDriverDeliveries(driverId: driver?.effectiveDriverId),
            tooltip: 'Segarkan Tugas',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => tracking.loadDriverDeliveries(driverId: driver?.effectiveDriverId),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Driver Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.driverCardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: tracking.isTracking
                                    ? AppTheme.statusSuccess
                                    : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tracking.isTracking ? 'GPS Aktif' : 'GPS Jeda',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'ID: ${driver?.effectiveDriverId.isNotEmpty == true ? driver!.effectiveDriverId.substring(0, 8) : "EMP-001"}',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD1FAE5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    driver?.displayName ?? 'Driver Utama',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kode Pegawai: ${driver?.driver?.employeeCode ?? "EMP-DEFAULT-001"} • ${driver?.phone ?? "+628333333333"}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Real-time GPS Tracker Live Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tracking.isTracking
                          ? AppTheme.statusSuccess.withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: tracking.isTracking
                          ? AppTheme.statusSuccess
                          : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tracking.trackingStatusText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          tracking.lastSyncTime != null
                              ? 'Sinkron terakhir: ${tracking.lastSyncTime!.hour.toString().padLeft(2, '0')}:${tracking.lastSyncTime!.minute.toString().padLeft(2, '0')}:${tracking.lastSyncTime!.second.toString().padLeft(2, '0')} (Ping #${tracking.syncCount})'
                              : 'Menunggu pengiriman lokasi pertama...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (tracking.isTracking) {
                        tracking.stopTracking();
                      } else {
                        tracking.startTracking();
                      }
                    },
                    child: Text(
                      tracking.isTracking ? 'Jeda' : 'Mulai',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: tracking.isTracking
                            ? AppTheme.statusWarning
                            : AppTheme.statusSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tugas Pengiriman Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${tracking.assignedDeliveries.length} Pesanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deliveries List
            if (tracking.assignedDeliveries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 44, color: AppTheme.statusSuccess),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada tugas pending!',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semua pesanan distribusi telah selesai.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tracking.assignedDeliveries.map((item) {
                return _buildTaskCard(context, item, tracking);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DeliveryModel item, DriverTrackingProvider tracking) {
    Color statusColor = AppTheme.primaryBlue;
    if (item.status == 'DELIVERED' || item.status == 'COMPLETED') {
      statusColor = AppTheme.statusSuccess;
    } else if (item.status == 'ASSIGNED') {
      statusColor = AppTheme.statusWarning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.orderNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.clientName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // Route Destination
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: AppTheme.statusDanger),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tujuan Pengantaran:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        item.destination,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action State Machine Button
          _buildActionButton(context, item, tracking),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DeliveryModel item, DriverTrackingProvider tracking) {
    if (item.status == 'ASSIGNED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => tracking.updateDeliveryState(item.id, 'ACCEPTED'),
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: const Text('Terima Tugas (Accept)'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
        ),
      );
    } else if (item.status == 'ACCEPTED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => tracking.updateDeliveryState(item.id, 'EN_ROUTE'),
          icon: const Icon(Icons.navigation_rounded, size: 20),
          label: const Text('Mulai Perjalanan (En Route)'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusInfo),
        ),
      );
    } else if (item.status == 'EN_ROUTE') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => tracking.updateDeliveryState(item.id, 'ARRIVED'),
          icon: const Icon(Icons.where_to_vote_rounded, size: 20),
          label: const Text('Tiba di Lokasi Tujuan (Arrived)'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
        ),
      );
    } else if (item.status == 'ARRIVED') {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => tracking.updateDeliveryState(item.id, 'DELIVERED'),
          icon: const Icon(Icons.task_alt_rounded, size: 20),
          label: const Text('Serah Terima & Selesai (POD)'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusSuccess),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.statusSuccess.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.statusSuccess, size: 18),
            const SizedBox(width: 8),
            Text(
              'Pengiriman Selesai',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.statusSuccess,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
  }
}
