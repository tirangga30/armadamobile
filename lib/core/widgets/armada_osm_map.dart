import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../config/theme.dart';

/// Reusable OpenStreetMap (OSM) Interactive Map Component for Armada Mobile.
class ArmadaOsmMap extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Marker> markers;
  final List<Polyline>? polylines;
  final List<CircleMarker>? circles;
  final double height;
  final bool showControls;
  final String? overlayBadgeText;
  final VoidCallback? onRecenter;

  const ArmadaOsmMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.polylines,
    this.circles,
    this.height = 240,
    this.showControls = true,
    this.overlayBadgeText,
    this.onRecenter,
  });

  /// Build a numbered visual marker representing a delivery stop
  static Marker buildStopMarker({
    required int sequence,
    required String name,
    required String status,
    required LatLng position,
    VoidCallback? onTap,
  }) {
    Color markerColor = const Color(0xFF64748B); // Slate default
    final normalized = status.toUpperCase();

    if (normalized == 'COMPLETED' || normalized == 'DELIVERED') {
      markerColor = AppTheme.statusSuccess;
    } else if (normalized == 'EN_ROUTE' || normalized == 'DEPARTED') {
      markerColor = AppTheme.primaryBlue;
    } else if (normalized == 'ARRIVED' || normalized == 'UNLOADED' || normalized == 'UNLOADING') {
      markerColor = const Color(0xFF8B5CF6);
    } else if (normalized == 'FAILED') {
      markerColor = AppTheme.statusDanger;
    }

    return Marker(
      point: position,
      width: 44,
      height: 52,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$sequence',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(10, 6),
              painter: _MarkerTrianglePainter(color: markerColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a styled Polyline for route visualization
  static Polyline buildRoutePolyline({
    required List<LatLng> points,
    Color color = AppTheme.primaryBlue,
    double strokeWidth = 4.0,
    bool isDotted = false,
  }) {
    return Polyline(
      points: points,
      strokeWidth: strokeWidth,
      color: color,
      borderColor: const Color(0xFF1E3A8A).withValues(alpha: 0.8),
      borderStrokeWidth: 1.0,
      pattern: isDotted ? const StrokePattern.dotted() : const StrokePattern.solid(),
    );
  }

  @override
  State<ArmadaOsmMap> createState() => ArmadaOsmMapState();
}

class ArmadaOsmMapState extends State<ArmadaOsmMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void moveTo(LatLng point, [double? zoom]) {
    _mapController.move(point, zoom ?? _mapController.camera.zoom);
  }

  void zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < 18.0) {
      _mapController.move(_mapController.camera.center, currentZoom + 1.0);
    }
  }

  void zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > 4.0) {
      _mapController.move(_mapController.camera.center, currentZoom - 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // FlutterMap Tile Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.armada.mobile.armada_mobile',
              ),
              if (widget.circles != null && widget.circles!.isNotEmpty)
                CircleLayer(circles: widget.circles!),
              if (widget.polylines != null && widget.polylines!.isNotEmpty)
                PolylineLayer(polylines: widget.polylines!),
              if (widget.markers.isNotEmpty)
                MarkerLayer(markers: widget.markers),
            ],
          ),

          // Top Info Pill
          if (widget.overlayBadgeText != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.overlayBadgeText!,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Map Action Controls (Zoom in, Zoom out, Recenter)
          if (widget.showControls)
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapBtn(
                    icon: Icons.add_rounded,
                    tooltip: 'Perbesar Peta',
                    onTap: zoomIn,
                  ),
                  const SizedBox(height: 6),
                  _buildMapBtn(
                    icon: Icons.remove_rounded,
                    tooltip: 'Perkecil Peta',
                    onTap: zoomOut,
                  ),
                  const SizedBox(height: 6),
                  _buildMapBtn(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Pusatkan Peta',
                    iconColor: AppTheme.primaryBlue,
                    onTap: () {
                      if (widget.onRecenter != null) {
                        widget.onRecenter!();
                      } else {
                        moveTo(widget.initialCenter, widget.initialZoom);
                      }
                    },
                  ),
                ],
              ),
            ),

          // OSM Attribution Footnote
          Positioned(
            bottom: 4,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '© OpenStreetMap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF334155),
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _MarkerTrianglePainter extends CustomPainter {
  final Color color;

  const _MarkerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
