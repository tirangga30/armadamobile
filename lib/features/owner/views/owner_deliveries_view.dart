import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/delivery_model.dart';
import '../../../providers/fleet_provider.dart';

class OwnerDeliveriesView extends StatefulWidget {
  const OwnerDeliveriesView({super.key});

  @override
  State<OwnerDeliveriesView> createState() => _OwnerDeliveriesViewState();
}

class _OwnerDeliveriesViewState extends State<OwnerDeliveriesView> {
  String _statusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetProvider>();

    final deliveries = fleet.deliveries.where((d) {
      if (_statusFilter == 'ALL') return true;
      return d.status == _statusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Manajemen Pengiriman',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildChip('ALL', 'Semua (${fleet.deliveries.length})'),
                _buildChip('ASSIGNED', 'Assigned'),
                _buildChip('EN_ROUTE', 'Dalam Rute'),
                _buildChip('DELIVERED', 'Terkirim'),
                _buildChip('COMPLETED', 'Selesai'),
              ],
            ),
          ),

          Expanded(
            child: deliveries.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada order pengiriman.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: deliveries.length,
                    itemBuilder: (context, idx) {
                      final item = deliveries[idx];
                      return _buildDeliveryCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String val, String label) {
    final isSelected = _statusFilter == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryBlue,
        showCheckmark: false,
        onSelected: (_) => setState(() => _statusFilter = val),
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryModel item) {
    Color statusColor = AppTheme.primaryBlue;
    if (item.status == 'DELIVERED' || item.status == 'COMPLETED') {
      statusColor = AppTheme.statusSuccess;
    } else if (item.status == 'ASSIGNED') {
      statusColor = AppTheme.statusWarning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Text(
                item.orderNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // Origin & Destination flow
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked, size: 14, color: AppTheme.primaryBlue),
                  Container(width: 1.5, height: 26, color: const Color(0xFFCBD5E1)),
                  const Icon(Icons.location_on, size: 14, color: AppTheme.statusDanger),
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
                    const SizedBox(height: 16),
                    Text(
                      item.destination,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    item.assignedDriver ?? 'Belum Ada Driver',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              Text(
                '${item.totalItems} Barang • ${item.totalWeightKg.toInt()} kg',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
