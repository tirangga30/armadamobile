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

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'type': 'ACCIDENT',
      'label': 'Kecelakaan Lalu Lintas',
      'icon': Icons.car_crash_rounded,
      'desc': 'Tabrakan, benturan, atau insiden fisik di jalan raya'
    },
    {
      'type': 'VEHICLE_BREAKDOWN',
      'label': 'Kendaraan Rusak / Mogok',
      'icon': Icons.build_circle_rounded,
      'desc': 'Masalah mesin, ban pecah, transmisi atau kelistrikan'
    },
    {
      'type': 'MEDICAL',
      'label': 'Darurat Medis / Sakit',
      'icon': Icons.medical_services_rounded,
      'desc': 'Kondisi kesehatan mendesak yang membutuhkan ambulans'
    },
    {
      'type': 'SECURITY',
      'label': 'Gangguan Keamanan / Begal',
      'icon': Icons.shield_rounded,
      'desc': 'Tindak kriminalitas, perampokan, atau ancaman fisik'
    },
    {
      'type': 'OTHER',
      'label': 'Situasi Darurat Lainnya',
      'icon': Icons.help_outline_rounded,
      'desc': 'Hambatan rute ekstrem atau bencana alam lokal'
    },
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleTriggerSos(BuildContext context) async {
    final tracking = context.read<DriverTrackingProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.statusDanger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.statusDanger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Konfirmasi SOS Darurat',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Sinyal darurat beserta koordinat lokasi GPS akurat Anda akan langsung dipancarkan ke Dashboard Admin & Owner Pusat secara real-time. Aktifkan sekarang?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Ya, Kirim Sinyal Darurat',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
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
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Sinyal Darurat Berhasil Aktif & Diterima Pusat Komando!'
                      : (tracking.sosStatusMessage ?? 'Gagal memancarkan sinyal darurat.'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: success ? AppTheme.statusSuccess : AppTheme.statusDanger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleResolveActiveSos(BuildContext context) async {
    final tracking = context.read<DriverTrackingProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Akhiri Status Darurat?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Tandai bahwa situasi di lapangan sudah teratasi dan armada kembali dalam kondisi aman.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusSuccess),
            child: const Text('Situasi Aman'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await tracking.resolveActiveEmergency();
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status darurat telah diselesaikan. Armada kembali operasional.'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<DriverTrackingProvider>();
    final activeEm = tracking.activeEmergency;
    final hasActiveSos = activeEm != null && activeEm.status == 'TRIGGERED';

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // If active emergency is ongoing
          if (hasActiveSos) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.statusDanger.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SINYAL DARURAT AKTIF',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'ID: ${activeEm.id.substring(0, 8)}...',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kategori: ${activeEm.emergencyType}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tim Pusat & Owner telah menerima koordinat Anda dan sedang memantau kondisi armada secara langsung.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleResolveActiveSos(context),
                      icon: const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF991B1B)),
                      label: Text(
                        'Tandai Sudah Aman (Batalkan SOS)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Guidance Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.statusDanger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: AppTheme.statusDanger, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pusat Bantuan & Keselamatan Lapangan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Tekan tombol darurat hanya saat menghadapi situasi darurat di perjalanan.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Big Emergency SOS Button Hero
          Center(
            child: GestureDetector(
              onTap: tracking.isTriggeringSos ? null : () => _handleTriggerSos(context),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  gradient: AppTheme.emergencyGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.statusDanger.withOpacity(0.4),
                      blurRadius: 28,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
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
                              size: 54,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'PENCET SOS',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'KIRIM KOORDINAT',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Emergency Category Selection Cards
          Text(
            'Pilih Kategori Insiden',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ..._emergencyTypes.map((item) {
            final isSelected = _selectedType == item['type'];
            return GestureDetector(
              onTap: () => setState(() => _selectedType = item['type']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.statusDanger : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.statusDanger.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.statusDanger.withOpacity(0.12)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? AppTheme.statusDanger : const Color(0xFF64748B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isSelected ? AppTheme.statusDanger : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['desc'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: item['type'] as String,
                      groupValue: _selectedType,
                      activeColor: AppTheme.statusDanger,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Additional Note Input
          Text(
            'Catatan Tambahan Lapangan (Opsional)',
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
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
