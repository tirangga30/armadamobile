import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/armada_api_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';

class NotificationCenterView extends StatefulWidget {
  final ArmadaApiService? apiService;
  final List<NotificationModel>? initialNotifications;

  const NotificationCenterView({
    super.key,
    this.apiService,
    this.initialNotifications,
  });

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  late final ArmadaApiService _apiService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ??
        ArmadaApiService(
          client: DioClient(storageService: SecureStorageService()),
        );
    if (widget.initialNotifications != null) {
      _notifications = List.from(widget.initialNotifications!);
      _isLoading = false;
    } else {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = res.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markRead(NotificationModel item) async {
    if (item.isRead) return;
    try {
      await _apiService.markNotificationAsRead(item.id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == item.id);
        if (idx != -1) {
          _notifications[idx] = _notifications[idx].copyWith(status: 'READ');
        }
      });
    } catch (_) {}
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(status: 'READ')).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua notifikasi ditandai dibaca')),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'EMERGENCY_ALERT':
      case 'SOS':
        return Icons.warning_rounded;
      case 'ORDER_ASSIGNED':
      case 'DELIVERY':
        return Icons.local_shipping_rounded;
      case 'POD_COMPLETED':
      case 'DELIVERED':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'EMERGENCY_ALERT':
      case 'SOS':
        return AppTheme.statusDanger;
      case 'ORDER_ASSIGNED':
      case 'DELIVERY':
        return AppTheme.primaryBlue;
      case 'POD_COMPLETED':
      case 'DELIVERED':
        return AppTheme.statusSuccess;
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Pusat Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Tandai Dibaca',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 54, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada notifikasi baru',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pemberitahuan operasional akan muncul di sini.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, idx) {
                        final item = _notifications[idx];
                        final icon = _getIconForType(item.type);
                        final color = _getColorForType(item.type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isRead ? const Color(0xFFE2E8F0) : color.withValues(alpha: 0.3),
                              width: item.isRead ? 1 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            onTap: () => _markRead(item),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.body,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.createdAt != null
                                        ? '${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')} • ${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year}'
                                        : 'Baru saja',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
