import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';
import '../../data/models/delivery_model.dart';
import '../../data/repositories/armada_api_service.dart';

class DriverTrackingProvider extends ChangeNotifier {
  final ArmadaApiService _apiService;
  final LocationService _locationService;

  bool _isTracking = false;
  Timer? _trackingTimer;
  Position? _currentPosition;
  DateTime? _lastSyncTime;
  int _syncCount = 0;
  String _trackingStatusText = 'Tracking Tidak Aktif';
  String? _lastError;

  // Active Driver Tasks
  List<DeliveryModel> _assignedDeliveries = [];
  bool _isLoadingDeliveries = false;

  // SOS state
  bool _isTriggeringSos = false;
  String? _sosStatusMessage;

  DriverTrackingProvider({
    required ArmadaApiService apiService,
    required LocationService locationService,
  })  : _apiService = apiService,
        _locationService = locationService;

  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncCount => _syncCount;
  String get trackingStatusText => _trackingStatusText;
  String? get lastError => _lastError;

  List<DeliveryModel> get assignedDeliveries => _assignedDeliveries;
  bool get isLoadingDeliveries => _isLoadingDeliveries;
  bool get isTriggeringSos => _isTriggeringSos;
  String? get sosStatusMessage => _sosStatusMessage;

  /// Start automatic GPS tracking loop
  Future<void> startTracking({int intervalSeconds = 15}) async {
    if (_isTracking) return;

    _isTracking = true;
    _trackingStatusText = 'Memeriksa Izin GPS...';
    _lastError = null;
    notifyListeners();

    // Check GPS permission
    final perm = await _locationService.checkAndRequestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      _isTracking = false;
      _trackingStatusText = 'Izin Lokasi Ditolak';
      _lastError = 'Aplikasi memerlukan izin GPS untuk mengirim posisi ke Owner.';
      notifyListeners();
      return;
    }

    _trackingStatusText = 'GPS Aktif - Mengirim Lokasi...';
    notifyListeners();

    // Perform immediate first ping
    await _sendGpsPing();

    // Setup periodic timer
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      await _sendGpsPing();
    });
  }

  /// Stop GPS tracking loop
  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _isTracking = false;
    _trackingStatusText = 'Tracking Dihentikan';
    notifyListeners();
  }

  /// Single GPS ping to backend /v1/me/location
  Future<void> _sendGpsPing() async {
    try {
      final pos = await _locationService.getCurrentPosition();

      // Fallback coordinates (Jakarta Center) if indoor/emulator cannot get satellite fix
      final lat = pos?.latitude ?? -6.2088;
      final lng = pos?.longitude ?? 106.8456;
      final accuracy = pos?.accuracy ?? 6.5;
      final speed = pos?.speed ?? 0.0;
      final heading = pos?.heading ?? 0.0;

      _currentPosition = pos;

      final payload = _locationService.buildLocationPayload(
        latitude: lat,
        longitude: lng,
        accuracyM: accuracy,
        speedMps: speed,
        headingDeg: heading,
      );

      await _apiService.sendDriverLocation(payload);

      _lastSyncTime = DateTime.now();
      _syncCount++;
      _trackingStatusText = 'GPS Aktif (Tersinkron #$_syncCount)';
      _lastError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing GPS ping: $e');
      _lastError = 'Gagal mengirim koordinat: $e';
      _trackingStatusText = 'Gagal Mengirim Lokasi (Retry...)';
      notifyListeners();
    }
  }

  /// Manual ping trigger from UI
  Future<void> pingNow() async {
    await _sendGpsPing();
  }

  /// Fetch deliveries assigned to this driver
  Future<void> loadDriverDeliveries({String? driverId}) async {
    _isLoadingDeliveries = true;
    notifyListeners();

    try {
      _assignedDeliveries = await _apiService.getDeliveries(driverId: driverId);
    } catch (e) {
      debugPrint('Error loading driver deliveries: $e');
    } finally {
      _isLoadingDeliveries = false;
      notifyListeners();
    }
  }

  /// Driver advances delivery state machine
  Future<void> updateDeliveryState(String deliveryId, String newStatus) async {
    final idx = _assignedDeliveries.indexWhere((d) => d.id == deliveryId);
    if (idx != -1) {
      _assignedDeliveries[idx] = _assignedDeliveries[idx].copyWith(status: newStatus);
      notifyListeners();
      await _apiService.updateDeliveryStatus(deliveryId, newStatus);
    }
  }

  EmergencyModel? _activeEmergency;

  EmergencyModel? get activeEmergency => _activeEmergency;

  /// Check if the driver currently has an active emergency alert in the backend
  Future<void> checkActiveEmergency() async {
    try {
      _activeEmergency = await _apiService.getActiveDriverEmergency();
      notifyListeners();
    } catch (e) {
      debugPrint('Check active emergency notice: $e');
    }
  }

  /// Trigger emergency SOS alert directly to POST /v1/me/emergencies
  Future<bool> triggerEmergencyAlert({
    required String emergencyType,
    String? note,
  }) async {
    _isTriggeringSos = true;
    _sosStatusMessage = null;
    notifyListeners();

    try {
      final pos = await _locationService.getCurrentPosition();
      final lat = pos?.latitude ?? -6.2088;
      final lng = pos?.longitude ?? 106.8456;

      final em = await _apiService.triggerEmergency(
        latitude: lat,
        longitude: lng,
        emergencyType: emergencyType,
        note: note ?? 'Sinyal Darurat SOS diaktifkan oleh Driver melalui Armada Mobile.',
      );

      _activeEmergency = em;
      _sosStatusMessage = 'Sinyal Darurat SOS Berhasil Dikirimkan ke Pusat Armada!';
      _isTriggeringSos = false;
      notifyListeners();
      return true;
    } catch (e) {
      _sosStatusMessage = 'Gagal mengirim sinyal SOS: $e';
      _isTriggeringSos = false;
      notifyListeners();
      return false;
    }
  }

  /// Resolve or cancel active emergency from driver side
  Future<bool> resolveActiveEmergency() async {
    if (_activeEmergency == null) return false;
    try {
      await _apiService.updateEmergencyStatus(_activeEmergency!.id, 'RESOLVED');
      _activeEmergency = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing active emergency: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}
