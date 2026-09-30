import 'package:flutter/foundation.dart';
import '../../data/models/fleet_driver_model.dart';
import '../../data/models/emergency_model.dart';
import '../../data/models/delivery_model.dart';
import '../../data/repositories/armada_api_service.dart';

class FleetProvider extends ChangeNotifier {
  final ArmadaApiService _apiService;

  bool _isLoading = false;
  String? _errorMessage;

  List<FleetDriver> _drivers = [];
  List<EmergencyModel> _emergencies = [];
  List<DeliveryModel> _deliveries = [];

  FleetProvider({required ArmadaApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<FleetDriver> get drivers => _drivers;
  List<EmergencyModel> get emergencies => _emergencies;
  List<DeliveryModel> get deliveries => _deliveries;

  // Computed Fleet Metrics
  int get totalDrivers => _drivers.length;
  int get onlineDrivers => _drivers.where((d) => d.operationalStatus != 'OFFLINE').length;
  int get availableDrivers => _drivers.where((d) => d.operationalStatus == 'AVAILABLE').length;
  int get deliveringDrivers => _drivers.where((d) => d.operationalStatus == 'DELIVERING' || d.operationalStatus == 'DRIVING').length;
  int get activeEmergenciesCount => _emergencies.where((e) => e.status == 'TRIGGERED' || e.status == 'ACKNOWLEDGED').length;
  int get activeDeliveriesCount => _deliveries.where((d) => d.status != 'COMPLETED' && d.status != 'CANCELLED').length;

  /// Load all operational data for Owner Dashboard & Monitoring
  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getFleetLocations().catchError((e) {
          debugPrint('Fleet locations error: $e');
          return <FleetDriver>[];
        }),
        _apiService.getEmergencies().catchError((e) {
          debugPrint('Emergencies error: $e');
          return <EmergencyModel>[];
        }),
        _apiService.getDeliveries().catchError((e) {
          debugPrint('Deliveries error: $e');
          return <DeliveryModel>[];
        }),
      ]);

      _drivers = results[0] as List<FleetDriver>;
      _emergencies = results[1] as List<EmergencyModel>;
      _deliveries = results[2] as List<DeliveryModel>;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui data armada: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resolve an emergency alert
  Future<bool> resolveEmergency(String id) async {
    try {
      await _apiService.updateEmergencyStatus(id, 'RESOLVED');
      // Update local item
      final index = _emergencies.indexWhere((e) => e.id == id);
      if (index != -1) {
        _emergencies[index] = EmergencyModel(
          id: _emergencies[index].id,
          driverId: _emergencies[index].driverId,
          deliveryId: _emergencies[index].deliveryId,
          latitude: _emergencies[index].latitude,
          longitude: _emergencies[index].longitude,
          emergencyType: _emergencies[index].emergencyType,
          note: note ?? _emergencies[index].note,
          status: 'RESOLVED',
          triggeredAt: _emergencies[index].triggeredAt,
          resolvedAt: DateTime.now().toUtc().toIso8601String(),
          driver: _emergencies[index].driver,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error resolving emergency: $e');
      return false;
    }
  }

  /// Update delivery status
  Future<void> updateDeliveryStatus(String id, String newStatus) async {
    final index = _deliveries.indexWhere((d) => d.id == id);
    if (index != -1) {
      _deliveries[index] = _deliveries[index].copyWith(status: newStatus);
      notifyListeners();
      await _apiService.updateDeliveryStatus(id, newStatus);
    }
  }
}
