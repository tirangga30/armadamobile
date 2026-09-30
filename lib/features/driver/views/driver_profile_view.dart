import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/driver_tracking_provider.dart';

class DriverProfileView extends StatelessWidget {
  const DriverProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final driver = auth.user;
    final tracking = context.watch<DriverTrackingProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Profil Driver Armada',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Driver Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.badge_rounded,
                    color: AppTheme.statusSuccess,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver?.displayName ?? 'Driver Utama',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kode: ${driver?.driver?.employeeCode ?? "EMP-DEFAULT-001"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.statusSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ROLE: DRIVER OPERASIONAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.statusSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Operational Identity Section
          Text(
            'Informasi Driver',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoTile('Username', driver?.username ?? 'driver'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile('Nomor Telepon', driver?.phone ?? '+628333333333'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile('Status Operasional', driver?.driver?.operationalStatus ?? 'AVAILABLE'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile(
                  'Driver UUID',
                  driver?.effectiveDriverId.isNotEmpty == true
                      ? '${driver!.effectiveDriverId.substring(0, 12)}...'
                      : '-',
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile('Organisasi', 'Armada Distribution Corp'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Vehicle & Performance Section
          Text(
            'Kendaraan & Kualifikasi Pengemudi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoTile('Kendaraan Ditugaskan', 'Gran Max Blind Van (B 9281 SXZ)'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile('Lisensi Mengemudi', 'SIM B1 Umum (Aktif)'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile('Rating Driver', '⭐ 4.9 / 5.0 (Sangat Baik)'),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildInfoTile('Status Pelacak GPS', tracking.isTracking ? 'Aktif Terhubung' : 'Jeda Sementara'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                _confirmLogout(context, auth, tracking);
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.statusDanger),
              label: Text(
                'Keluar dari Sesi Driver',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusDanger,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.statusDanger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth, DriverTrackingProvider tracking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Driver? Transmisi GPS akan dihentikan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              tracking.stopTracking();
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusDanger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
