import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/create_delivery_dto.dart';
import '../../../data/models/fleet_driver_model.dart';

typedef AssignCallback = Future<void> Function(AssignDeliveryDto dto);

class AssignDriverModalSheet extends StatefulWidget {
  final String deliveryId;
  final String deliveryCode;
  final double totalCargoWeightKg;
  final List<FleetDriver> availableDrivers;
  final AssignCallback onAssign;

  const AssignDriverModalSheet({
    super.key,
    required this.deliveryId,
    required this.deliveryCode,
    required this.totalCargoWeightKg,
    required this.availableDrivers,
    required this.onAssign,
  });

  @override
  State<AssignDriverModalSheet> createState() => _AssignDriverModalSheetState();
}

class _AssignDriverModalSheetState extends State<AssignDriverModalSheet> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedDriverId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.availableDrivers.isNotEmpty) {
      _selectedDriverId = widget.availableDrivers.first.id;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  FleetDriver? get _selectedDriver {
    if (_selectedDriverId == null || widget.availableDrivers.isEmpty) return null;
    return widget.availableDrivers.firstWhere(
      (d) => d.id == _selectedDriverId,
      orElse: () => widget.availableDrivers.first,
    );
  }

  bool get _isOverloaded {
    final driver = _selectedDriver;
    if (driver == null) return false;
    return widget.totalCargoWeightKg > driver.vehicleCapacityKg;
  }

  Future<void> _handleConfirm() async {
    final driver = _selectedDriver;
    if (driver == null || _isOverloaded) return;

    setState(() => _isSubmitting = true);
    try {
      final dto = AssignDeliveryDto(
        driverId: driver.id,
        vehicleId: driver.activeVehicleId ?? 'veh-default-${driver.id}',
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      await widget.onAssign(dto);

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menugaskan driver: $e'),
            backgroundColor: AppTheme.statusDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overloaded = _isOverloaded;
    final driver = _selectedDriver;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penugasan Driver & Armada',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Surat Jalan: ${widget.deliveryCode}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Weight Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Berat Muatan Kargo:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${widget.totalCargoWeightKg.toStringAsFixed(1)} kg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Overload Alert Banner
            if (overloaded && driver != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.statusDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.statusDanger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.statusDanger, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PERINGATAN: MUATAN MELEBIHI KAPASITAS!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.statusDanger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total kargo (${widget.totalCargoWeightKg.toStringAsFixed(1)} kg) melebihi daya angkut aman kendaraan ${driver.assignedVehicle ?? "armada"} (${driver.vehicleCapacityKg.toStringAsFixed(1)} kg). Pilih armada dengan kapasitas lebih besar.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Available Drivers List
            Text(
              'Pilih Driver Tersedia:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (widget.availableDrivers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Tidak ada driver berstatus AVAILABLE.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ...widget.availableDrivers.map((d) {
                final isSelected = d.id == _selectedDriverId;
                final isExceeded = widget.totalCargoWeightKg > d.vehicleCapacityKg;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDriverId = d.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryBlue : const Color(0xFF94A3B8),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.driverName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${d.employeeCode} • ${d.phone ?? "No HP"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.assignedVehicle ?? "Mobil Box"} (Maks: ${d.vehicleCapacityKg.toStringAsFixed(0)} kg)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isExceeded ? AppTheme.statusDanger : AppTheme.statusSuccess,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isExceeded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.statusDanger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Overload',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusDanger,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 14),

            // Notes Input
            Text(
              'Instruksi / Catatan untuk Driver (Opsional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Harap jemput barang sebelum pukul 09:00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || overloaded || _selectedDriver == null) ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isSubmitting ? 'Memproses Penugasan...' : 'Konfirmasi Penugasan Armada',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
