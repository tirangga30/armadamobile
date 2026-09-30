import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/emergency_model.dart';
import '../../../providers/fleet_provider.dart';

class OwnerEmergencyView extends StatelessWidget {
  const OwnerEmergencyView({super.key});

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Pusat Peringatan Darurat (SOS)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => fleet.fetchAllData(),
            tooltip: 'Perbarui SOS',
          ),
        ],
      ),
      body: fleet.emergencies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.statusSuccess.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 48,
                      color: AppTheme.statusSuccess,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Semua Armada Dalam Kondisi Aman',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tidak ada sinyal SOS darurat aktif saat ini.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: fleet.emergencies.length,
              itemBuilder: (context, idx) {
                final em = fleet.emergencies[idx];
                return _buildEmergencyCard(context, em, fleet);
              },
            ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, EmergencyModel em, FleetProvider fleet) {
    final isTriggered = em.status == 'TRIGGERED';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTriggered ? AppTheme.statusDanger : const Color(0xFFE2E8F0),
          width: isTriggered ? 1.5 : 1,
        ),
        boxShadow: isTriggered
            ? [
                BoxShadow(
                  color: AppTheme.statusDanger.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isTriggered ? AppTheme.statusDanger : const Color(0xFF64748B))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: isTriggered ? AppTheme.statusDanger : const Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    em.emergencyType,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isTriggered ? AppTheme.statusDanger : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTriggered
                      ? AppTheme.statusDanger.withValues(alpha: 0.1)
                      : AppTheme.statusSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  em.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isTriggered ? AppTheme.statusDanger : AppTheme.statusSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            em.note ?? 'Peringatan darurat otomatis dari aplikasi driver.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Driver: ${em.driver?.displayName ?? "Driver #"} (${em.driver?.employeeCode ?? ""})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      em.driver?.phone ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Koordinat GPS: ${em.latitude}, ${em.longitude}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isTriggered) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ok = await fleet.resolveEmergency(em.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status darurat telah diselesaikan (RESOLVED).'),
                        backgroundColor: AppTheme.statusSuccess,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Tandai Sebagai Selesai (Resolve)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusSuccess,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
