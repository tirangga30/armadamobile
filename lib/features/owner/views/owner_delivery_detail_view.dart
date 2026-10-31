import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/delivery_model.dart';
import '../../../data/models/create_delivery_dto.dart';
import '../../../data/models/route_geometry_model.dart';
import '../../../providers/fleet_provider.dart';
import '../widgets/assign_driver_modal_sheet.dart';
import '../widgets/route_optimizer_sheet.dart';

class OwnerDeliveryDetailView extends StatefulWidget {
  final DeliveryModel delivery;

  const OwnerDeliveryDetailView({
    super.key,
    required this.delivery,
  });

  @override
  State<OwnerDeliveryDetailView> createState() => _OwnerDeliveryDetailViewState();
}

class _OwnerDeliveryDetailViewState extends State<OwnerDeliveryDetailView> {
  late DeliveryModel _currentDelivery;

  @override
  void initState() {
    super.initState();
    _currentDelivery = widget.delivery;
  }

  void _openAssignSheet(BuildContext context) {
    final fleet = context.read<FleetProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignDriverModalSheet(
        deliveryId: _currentDelivery.id,
        deliveryCode: _currentDelivery.orderNumber,
        totalCargoWeightKg: _currentDelivery.totalWeightKg,
        availableDrivers: fleet.drivers,
        onAssign: (AssignDeliveryDto dto) async {
          final assignedDriver = fleet.drivers.firstWhere(
            (d) => d.id == dto.driverId,
            orElse: () => fleet.drivers.first,
          );
          setState(() {
            _currentDelivery = _currentDelivery.copyWith(
              status: 'ASSIGNED',
              assignedDriver: assignedDriver.driverName,
              plateNumber: assignedDriver.plateNumber ?? 'B 1234 SXZ',
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Armada berhasil ditugaskan!'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
        },
      ),
    );
  }

  void _openRouteOptimizerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RouteOptimizerSheet(
        deliveryId: _currentDelivery.id,
        currentDistanceM: 14500,
        currentDurationS: 2100,
        recommendedDistanceM: 12000,
        recommendedDurationS: 1750,
        reorderedStopNames: _currentDelivery.stops.map((s) => s.destinationName).toList(),
        onApply: (SelectRouteDto dto) async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rute rekomendasi 2-Opt berhasil diterapkan!'),
              backgroundColor: AppTheme.statusSuccess,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentDelivery;

    Color statusColor = AppTheme.primaryBlue;
    if (item.status == 'DELIVERED' || item.status == 'COMPLETED') {
      statusColor = AppTheme.statusSuccess;
    } else if (item.status == 'ASSIGNED') {
      statusColor = AppTheme.statusWarning;
    } else if (item.status == 'FAILED') {
      statusColor = AppTheme.statusDanger;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pengiriman',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              'Informasi Order & Rute Armada',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Order Header Card
          Container(
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
                        fontSize: 17,
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
                const SizedBox(height: 6),
                Text(
                  item.clientName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 14),

                // Origin to Destination
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.warehouse_rounded, size: 16, color: AppTheme.primaryBlue),
                          Container(width: 1.5, height: 20, color: const Color(0xFFCBD5E1)),
                          const Icon(Icons.location_on, size: 16, color: AppTheme.statusDanger),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.origin,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.destination,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Cargo Metrics Pill
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Total Item: ${item.totalItems} Barang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Berat: ${item.totalWeightKg.toStringAsFixed(1)} kg',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Driver & Vehicle Card
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
                Text(
                  'Armada & Driver Bertugas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (item.assignedDriver != null && item.assignedDriver!.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.assignedDriver!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Plat Nomor: ${item.plateNumber ?? "Belum Ditugaskan"}',
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
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Belum ada driver yang ditugaskan ke order ini.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAssignSheet(context),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Tugaskan Armada & Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Waypoints Timeline
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Rincian Titik Pengantaran',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (item.stops.length > 1)
                      TextButton.icon(
                        onPressed: () => _openRouteOptimizerSheet(context),
                        icon: const Icon(Icons.alt_route_rounded, size: 16),
                        label: const Text('Optimasi (2-Opt)'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (item.stops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada titik singgah yang tercatat.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
                    ),
                  )
                else
                  ...item.stops.map((stop) {
                    Color stopColor = const Color(0xFF64748B);
                    if (stop.status == 'DELIVERED' || stop.status == 'COMPLETED') {
                      stopColor = AppTheme.statusSuccess;
                    } else if (stop.status == 'EN_ROUTE' || stop.status == 'DEPARTED') {
                      stopColor = AppTheme.statusInfo;
                    } else if (stop.status == 'ARRIVED') {
                      stopColor = const Color(0xFF8B5CF6);
                    } else if (stop.status == 'FAILED') {
                      stopColor = AppTheme.statusDanger;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: stopColor,
                            child: Text(
                              '${stop.sequence}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stop.destinationName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stopColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        stop.status,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: stopColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (stop.address.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    stop.address,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                                if (stop.pod != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Penerima: ${stop.pod!.receiverName}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.statusSuccess,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Audit Activity Trail
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
                Text(
                  'Riwayat Audit Log Aktivitas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildAuditItem('Perintah Kirim (DO) Diterbitkan', item.createdAt ?? 'Baru saja', isDone: true),
                _buildAuditItem(
                  'Penugasan Driver & Armada',
                  item.assignedDriver != null ? 'Ditugaskan ke ${item.assignedDriver}' : 'Menunggu penugasan',
                  isDone: item.assignedDriver != null,
                ),
                _buildAuditItem(
                  'Perjalanan Armada (En Route)',
                  item.status == 'EN_ROUTE' || item.status == 'DELIVERED' || item.status == 'COMPLETED'
                      ? 'Sedang berlangsung'
                      : 'Belum dimulai',
                  isDone: item.status == 'EN_ROUTE' || item.status == 'DELIVERED' || item.status == 'COMPLETED',
                ),
                _buildAuditItem(
                  'Bukti Serah Terima (POD) & Selesai',
                  item.status == 'DELIVERED' || item.status == 'COMPLETED'
                      ? 'Seluruh stop terselesaikan'
                      : 'Menunggu serah terima',
                  isDone: item.status == 'DELIVERED' || item.status == 'COMPLETED',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditItem(String title, String time, {bool isDone = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.statusSuccess : const Color(0xFFCBD5E1),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 24,
                color: isDone ? AppTheme.statusSuccess : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppTheme.textPrimary : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}
