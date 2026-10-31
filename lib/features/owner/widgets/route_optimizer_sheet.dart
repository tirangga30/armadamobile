import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/route_geometry_model.dart';

typedef RouteApplyCallback = Future<void> Function(SelectRouteDto dto);

class RouteOptimizerSheet extends StatefulWidget {
  final String deliveryId;
  final double currentDistanceM;
  final int currentDurationS;
  final double recommendedDistanceM;
  final int recommendedDurationS;
  final List<String> reorderedStopNames;
  final List<Map<String, dynamic>>? recommendedSequence;
  final int routeVersion;
  final RouteApplyCallback onApply;

  const RouteOptimizerSheet({
    super.key,
    required this.deliveryId,
    required this.currentDistanceM,
    required this.currentDurationS,
    this.recommendedDistanceM = 0,
    this.recommendedDurationS = 0,
    this.reorderedStopNames = const [],
    this.recommendedSequence,
    this.routeVersion = 1,
    required this.onApply,
  });

  @override
  State<RouteOptimizerSheet> createState() => _RouteOptimizerSheetState();
}

class _RouteOptimizerSheetState extends State<RouteOptimizerSheet> {
  bool _isApplying = false;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).round();
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}j ${remMins}m';
    }
    return '$mins menit';
  }

  double get _savingsPercentage {
    if (widget.currentDistanceM <= 0) return 0;
    final diff = widget.currentDistanceM - widget.recommendedDistanceM;
    if (diff <= 0) return 0;
    return (diff / widget.currentDistanceM) * 100;
  }

  Future<void> _handleApply() async {
    setState(() => _isApplying = true);
    try {
      final dto = SelectRouteDto(
        routeVersion: widget.routeVersion,
        source: 'RECOMMENDED_2OPT',
        recommendedSequence: widget.recommendedSequence ??
            widget.reorderedStopNames
                .asMap()
                .entries
                .map((e) => {'sequence': e.key + 1, 'name': e.value})
                .toList(),
        totalDistanceMeters: widget.recommendedDistanceM,
        estimatedDurationSeconds: widget.recommendedDurationS,
      );
      await widget.onApply(dto);
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerapkan rute rekomendasi: $e'),
            backgroundColor: AppTheme.statusDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = _savingsPercentage;

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
                        'Optimasi Rute (2-Opt TSP)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Evaluasi algoritma heuristik jarak terpendek',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
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

            const SizedBox(height: 16),

            // Metric Comparison Cards
            Row(
              children: [
                // Current Route Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rute Saat Ini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDistance(widget.currentDistanceM),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.currentDurationS),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Recommended Route Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.statusSuccess.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.statusSuccess.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rekomendasi 2-Opt',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.statusSuccess,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (savings > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusSuccess,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${savings.toStringAsFixed(1)}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDistance(widget.recommendedDistanceM),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.statusSuccess,
                          ),
                        ),
                        Text(
                          _formatDuration(widget.recommendedDurationS),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.statusSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Reordered Stop Sequence
            Text(
              'Urutan Kunjungan Titik Singgah:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            if (widget.reorderedStopNames.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Urutan stop sudah optimal.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              )
            else
              ...widget.reorderedStopNames.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final name = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$idx',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isApplying ? null : _handleApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isApplying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.alt_route_rounded, color: Colors.white, size: 20),
                label: Text(
                  _isApplying ? 'Menerapkan Rute...' : 'Terapkan Rute Rekomendasi',
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
