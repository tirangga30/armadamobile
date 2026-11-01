import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import '../../data/models/realtime_envelope.dart';

class SocketRealtimeService {
  final SecureStorageService _storageService;
  socket_io.Socket? _socket;
  bool _isConnected = false;
  final Set<String> _activeRooms = {};

  final _locationController = StreamController<RealtimeLocationPayload>.broadcast();
  final _deliveryStatusController = StreamController<RealtimeDeliveryStatusPayload>.broadcast();
  final _emergencyController = StreamController<RealtimeEmergencyPayload>.broadcast();

  SocketRealtimeService({required SecureStorageService storageService})
      : _storageService = storageService;

  bool get isConnected => _isConnected;
  Stream<RealtimeLocationPayload> get locationStream => _locationController.stream;
  Stream<RealtimeDeliveryStatusPayload> get deliveryStatusStream => _deliveryStatusController.stream;
  Stream<RealtimeEmergencyPayload> get emergencyStream => _emergencyController.stream;

  /// Connect to backend Socket.IO Gateway on namespace /v1/realtime
  Future<void> connect({String? customToken}) async {
    final token = customToken ?? await _storageService.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('SocketRealtimeService: No token available for handshake.');
      return;
    }

    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket?.dispose();

    final wsUrl = '${AppConfig.wsBaseUrl}/v1/realtime';
    debugPrint('Connecting to Socket.IO: $wsUrl');

    _socket = socket_io.io(
      wsUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(10)
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('🌐 Socket.IO Gateway connected: ${_socket?.id}');

      // Review Focus #4: Re-subscribe to all active rooms on reconnect
      for (final room in _activeRooms) {
        _socket?.emit('join_room', {'room': room});
      }
    });

    _socket!.onDisconnect((data) {
      _isConnected = false;
      debugPrint('🔌 Socket.IO Gateway disconnected: $data');
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      debugPrint('⚠️ Socket.IO connection error: $err');
    });

    // Event 1: Telemetry location update
    _socket!.on('driver.location.updated', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final payloadData = data['payload'] is Map<String, dynamic> ? data['payload'] : data;
          final payload = RealtimeLocationPayload.fromJson(payloadData as Map<String, dynamic>);
          _locationController.add(payload);
        }
      } catch (e) {
        debugPrint('Error parsing driver.location.updated: $e');
      }
    });

    // Event 2: Delivery status changed
    _socket!.on('delivery.status_changed', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final payloadData = data['payload'] is Map<String, dynamic> ? data['payload'] : data;
          final payload = RealtimeDeliveryStatusPayload.fromJson(payloadData as Map<String, dynamic>);
          _deliveryStatusController.add(payload);
        }
      } catch (e) {
        debugPrint('Error parsing delivery.status_changed: $e');
      }
    });

    // Event 3: SOS Emergency triggered
    _socket!.on('emergency.triggered', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final payloadData = data['payload'] is Map<String, dynamic> ? data['payload'] : data;
          final payload = RealtimeEmergencyPayload.fromJson(payloadData as Map<String, dynamic>);
          _emergencyController.add(payload);
        }
      } catch (e) {
        debugPrint('Error parsing emergency.triggered: $e');
      }
    });

    _socket!.connect();
  }

  /// Subscribe to a specific real-time room (e.g. 'fleet:monitoring', 'delivery:`<id>`')
  void joinRoom(String room) {
    _activeRooms.add(room);
    if (_isConnected && _socket != null) {
      _socket!.emit('join_room', {'room': room});
      debugPrint('Joined room: $room');
    }
  }

  /// Unsubscribe from a room
  void leaveRoom(String room) {
    _activeRooms.remove(room);
    if (_isConnected && _socket != null) {
      _socket!.emit('leave_room', {'room': room});
      debugPrint('Left room: $room');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _locationController.close();
    _deliveryStatusController.close();
    _emergencyController.close();
  }
}
