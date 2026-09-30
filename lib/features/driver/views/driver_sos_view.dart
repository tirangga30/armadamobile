import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../providers/driver_tracking_provider.dart';

class DriverSosView extends StatefulWidget {
  const DriverSosView({super.key});

  @override
  State<DriverSosView> createState() => _DriverSosViewState();
}

class _DriverSosViewState extends State<DriverSosView> {
  String _selectedType = 'ACCIDENT';
  final _noteController = TextEditingController();

  final List<Map<String, String>> _emergencyTypes = [
    {'type': 'ACCIDENT', 'label': 'Kecelakaan Lalu Lintas'},
    {'type': 'VEHICLE_BREAKDOWN', 'label': 'Kendaraan Mogok / Rusak'},
    {'type': 'MEDICAL', 'label': 'Darurat Medis / Sakit'},
    {'type': 'SECURITY', 'label': 'Keamanan / Pembegalan'},
    {'type': 'OTHER', 'label': 'Kendala Darurat Lainnya'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _triggerSos(BuildContext context) async {
    final tracking = context.read<DriverTrackingProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.statusDanger, size: 28),
            const SizedBox(width: 10),
            Text(
              'Konfirmasi SOS Darurat',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Sinyal darurat beserta koordinat GPS lokasi Anda saat ini akan segera dikirimkan ke Tim Operasional Owner & Admin Pusat. Lanjutkan?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusDanger,
            ),
            child: const Text('Kirim Sinyal Darurat!'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await tracking.triggerEmergencyAlert(
        emergencyType: _selectedType,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Sinyal SOS Berhasil Dikirimkan ke Pusat Armada!'
                : (tracking.sosStatusMessage ?? 'Gagal mengirim sinyal SOS.'),
          ),
          backgroundColor: success ? AppTheme.statusSuccess : AppTheme.statusDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<DriverTrackingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Bantuan Darurat (SOS)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Warning Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.statusDanger, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gunakan fitur ini hanya dalam situasi kritis atau bahaya di perjalanan distribusi.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF991B1B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Big Emergency SOS Button Hero
          Center(
            child: GestureDetector(
              onTap: tracking.isTriggeringSos ? null : () => _triggerSos(context),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  gradient: AppTheme.emergencyGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.statusDanger.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 4,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: tracking.isTriggeringSos
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emergency_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'AKTIFKAN SOS',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Emergency Type Selector
          Text(
            'Kategori Situasi Darurat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                items: _emergencyTypes.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['type'],
                    child: Text(
                      t['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional Note
          Text(
            'Keterangan Tambahan (Opsional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: Ban pecah di km 24 Tol Jagorawi arah Ciawi',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
