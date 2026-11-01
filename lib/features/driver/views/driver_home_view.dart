import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/delivery_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/driver_tracking_provider.dart';
import '../../../core/services/navigation_service.dart';
import '../../notifications/notification_center_view.dart';
import '../widgets/pod_capture_sheet.dart';
import '../widgets/stop_failure_dialog.dart';

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
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Pusat Notifikasi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterView()),
              );
            },
          ),
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

          const SizedBox(height: 12),

          // Multi-Stop Granular Section or Fallback Single Destination
          if (item.stops.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Titik Singgah (${item.stops.length} Stop)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${item.stops.where((s) => s.status == 'DELIVERED').length}/${item.stops.length} Selesai',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusSuccess,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...item.stops.map((stop) => _buildStopItem(context, item, stop, tracking)),
          ] else ...[
            // Route Destination Fallback
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
          ],

          const SizedBox(height: 14),

          // Action State Machine Button
          _buildActionButton(context, item, tracking),
        ],
      ),
    );
  }

  Widget _buildStopItem(
    BuildContext context,
    DeliveryModel delivery,
    DeliveryStop stop,
    DriverTrackingProvider tracking,
  ) {
    Color stopStatusColor = const Color(0xFF64748B);
    String stopStatusText = 'Menunggu';

    if (stop.status == 'DELIVERED' || stop.status == 'COMPLETED') {
      stopStatusColor = AppTheme.statusSuccess;
      stopStatusText = 'Selesai';
    } else if (stop.status == 'EN_ROUTE' || stop.status == 'DEPARTED') {
      stopStatusColor = AppTheme.statusInfo;
      stopStatusText = 'Menuju Lokasi';
    } else if (stop.status == 'ARRIVED') {
      stopStatusColor = const Color(0xFF8B5CF6);
      stopStatusText = 'Tiba di Toko';
    } else if (stop.status == 'UNLOADED' || stop.status == 'UNLOADING') {
      stopStatusColor = const Color(0xFFD97706);
      stopStatusText = 'Bongkar Muat';
    } else if (stop.status == 'FAILED') {
      stopStatusColor = AppTheme.statusDanger;
      stopStatusText = 'Gagal';
    }

    final isDeliveryActive = delivery.status == 'EN_ROUTE' || delivery.status == 'ACCEPTED';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: stopStatusColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${stop.sequence}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.destinationName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (stop.address.isNotEmpty)
                      Text(
                        stop.address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stopStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stopStatusText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: stopStatusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.navigation_rounded, size: 18, color: AppTheme.primaryBlue),
                tooltip: 'Navigasi ke Toko (Maps)',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  final lat = stop.latitude ?? -6.2088;
                  final lng = stop.longitude ?? 106.8456;
                  NavigationService.launchNavigation(
                    latitude: lat,
                    longitude: lng,
                    destinationName: stop.destinationName,
                  );
                },
              ),
            ],
          ),

          if (isDeliveryActive) ...[
            const SizedBox(height: 10),
            _buildStopActionButton(context, delivery, stop, tracking),
          ],
        ],
      ),
    );
  }

  Widget _buildStopActionButton(
    BuildContext context,
    DeliveryModel delivery,
    DeliveryStop stop,
    DriverTrackingProvider tracking,
  ) {
    if (stop.status == 'PENDING') {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton.icon(
          onPressed: () => tracking.executeDepartStop(delivery.id, stop.id),
          icon: const Icon(Icons.directions_car_rounded, size: 16),
          label: const Text('Berangkat ke Toko (Depart)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.statusInfo,
            visualDensity: VisualDensity.compact,
            textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    } else if (stop.status == 'EN_ROUTE' || stop.status == 'DEPARTED') {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton.icon(
          onPressed: () => tracking.executeArriveStop(delivery.id, stop.id),
          icon: const Icon(Icons.where_to_vote_rounded, size: 16),
          label: const Text('Tiba di Toko (Arrive)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            visualDensity: VisualDensity.compact,
            textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    } else if (stop.status == 'ARRIVED') {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton.icon(
          onPressed: () => tracking.executeUnloadStop(delivery.id, stop.id),
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: const Text('Mulai Bongkar Muat (Unload)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            visualDensity: VisualDensity.compact,
            textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      );
    } else if (stop.status == 'UNLOADED' || stop.status == 'UNLOADING') {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PodCaptureSheet(
                      stopId: stop.id,
                      destinationName: stop.destinationName,
                      onSubmit: ({
                        required String receiverName,
                        required Uint8List photoBytes,
                        required Uint8List signatureBytes,
                        String? notes,
                      }) async {
                        final success = await tracking.executeSubmitPod(
                          delivery.id,
                          stop.id,
                          receiverName: receiverName,
                          photoBytes: photoBytes,
                          signatureBytes: signatureBytes,
                          notes: notes,
                        );
                        if (success && context.mounted) {
                          Navigator.of(context).maybePop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bukti POD berhasil disubmit dan stop selesai!'),
                              backgroundColor: AppTheme.statusSuccess,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Bukti POD (Foto & TTD)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusSuccess,
                  textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => StopFailureDialog(
                    stopId: stop.id,
                    destinationName: stop.destinationName,
                    onSubmit: ({required String reason, String? notes}) async {
                      final success = await tracking.executeFailStop(
                        delivery.id,
                        stop.id,
                        reason: reason,
                        notes: notes,
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Laporan kendala stop berhasil dikirim.'),
                            backgroundColor: AppTheme.statusWarning,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.statusDanger),
              label: Text(
                'Kendala',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusDanger,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.statusDanger),
              ),
            ),
          ),
        ],
      );
    } else if (stop.status == 'DELIVERED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.statusSuccess.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.statusSuccess),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'POD Diterima: ${stop.pod?.receiverName ?? "Penerima Sah"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusSuccess,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (stop.status == 'FAILED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.statusDanger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.statusDanger),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Kendala: ${stop.failReason ?? "Gagal"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusDanger,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
    } else if (item.status == 'EN_ROUTE' && item.stops.isEmpty) {
      // Fallback for single delivery with no stops defined
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
    } else if (item.status == 'ARRIVED' && item.stops.isEmpty) {
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
    } else if (item.status == 'DELIVERED' || item.status == 'COMPLETED') {
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

    return const SizedBox.shrink();
  }
}
