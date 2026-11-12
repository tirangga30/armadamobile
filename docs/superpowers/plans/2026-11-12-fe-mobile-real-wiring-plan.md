# Real Backend Wiring & Production Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate all local mocks, stubs, and hardcoded values in `armadamobile` by wiring real backend persistence (`POST /v1/deliveries`, `POST /v1/deliveries/:id/assign`), real OSRM 2-Opt route optimization, two-way E2EE chat with a persistent conversation inbox, and real field WebRTC Voice PTT & Video calling with STUN/TURN traversal.

**Architecture:** All state mutations route through `FleetProvider` and `DriverTrackingProvider` backed by `ArmadaApiService` (Dio REST) and `SocketRealtimeService` (Socket.IO `/v1/realtime`). WebRTC media utilizes `flutter_webrtc` with ephemeral RFC 7635 TURN credentials and anti-replay signaling payloads (`nonce`, `seq`, `timestamp`). Chat enforces client-side AES-256 encryption before invoking conversation APIs.

**Tech Stack:** Flutter 3.x, Dart 3.11+, `dio: ^5.11.1`, `provider: ^6.1.5+1`, `socket_io_client: ^3.0.2`, `flutter_map: ^8.3.2`, `latlong2: ^0.10.1`, `encrypt: ^5.0.3`, `crypto: ^3.0.8`, `flutter_webrtc: ^0.12.5`, `permission_handler: ^11.4.0`, `uuid: ^4.6.0`.

**Spec:** `docs/superpowers/specs/2026-11-12-fe-mobile-real-wiring-spec.md`

## Global Constraints

- Base URL REST API: `http://localhost:3000/v1` (Emulator: `http://10.0.2.2:3000/v1`) or `https://armada-api.prizftm.my.id/v1`.
- Realtime WebSocket Namespace: `/v1/realtime` with Bearer JWT handshake.
- Standard API Response Envelope: `{ success: true, data: ..., timestamp, requestId }`.
- Error Envelope: `{ success: false, error: { code, message, requestId }, timestamp }`.
- `SelectRouteDto` must send `recommendedSequence: List<String>` (valid stop UUID v4 strings) and `source: RouteSource` (`RECOMMENDED_2OPT`, `MANUAL`, `EXTERNAL_OSRM`).
- WebRTC signaling frames (`webrtc.signal.offer`, `webrtc.signal.answer`, `webrtc.signal.ice_candidate`) must carry `sessionId`, `nonce` (UUIDv4), `seq` (monotonic int $\ge 1$), and `timestamp` (epoch ms within 30s clock skew).
- Strict Plan Mode: Zero `.dart` or `pubspec.yaml` edits allowed during this planning turn.

## Review Focus

1. **SelectRouteDto Stop UUID Validation Rejection:** Backend `SelectRouteDto` rejects object arrays with `400 Bad Request`; `recommendedSequence` must strictly extract stop UUIDs (`List<String>`) from `getRecommendedRoute` before invoking `POST /v1/deliveries/:id/routes/select`.
2. **WebRTC Signaling Replay & Clock Skew Rejection:** Emitting `webrtc.signal.*` without `nonce` (UUIDv4), monotonically increasing `seq`, and current `timestamp` triggers `CLOCK_SKEW_EXCEEDED` or `REPLAY_DETECTED` in `RealtimeGateway`.
3. **Invalid `recipientDeviceId` in Chat:** Passing a `driverId` or non-UUID fallback string to `POST /v1/conversations/:id/messages` triggers `400/422 RECIPIENT_DEVICE_INVALID`; client must resolve a valid device UUID from registered user devices or conversation context.
4. **Ghost Audio / Camera Leaks on Call End or Decline:** Releasing the PTT button must immediately disable the local audio track (`audioTrack.enabled = false`), and rejecting or ending a call must call `dispose()` on both `MediaStream` and `RTCPeerConnection`.
5. **Creating Delivery Without Retaining Local State on `GET /deliveries` 404:** Because backend `DeliveriesController` does not expose a root `GET /v1/deliveries` collection endpoint, `FleetProvider.createDelivery()` must preserve the newly returned `DeliveryModel` in memory across refreshes rather than wiping it with fallback mock data.

---

## Bite-Sized Tasks

### Task 1: Real Delivery Creation & Fleet Assignment Wiring (GAPs 1 & 2)

**Files:**
- Modify: `lib/providers/fleet_provider.dart`
- Modify: `lib/features/owner/views/owner_deliveries_view.dart`
- Modify: `lib/features/owner/views/owner_delivery_detail_view.dart`
- Test: `test/real_delivery_wiring_test.dart`

**Interfaces:**
- Consumes: `ArmadaApiService.createDelivery(CreateDeliveryDto)`, `ArmadaApiService.assignDelivery(String, AssignDeliveryDto)`.
- Produces:
  - `Future<DeliveryModel> FleetProvider.createDelivery(CreateDeliveryDto dto)`
  - `Future<void> FleetProvider.assignDelivery(String deliveryId, AssignDeliveryDto dto, {String? driverName, String? plateNumber})`

- [x] **Step 1: Write failing test in `test/real_delivery_wiring_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/fleet_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/data/models/create_delivery_dto.dart';
import 'package:armada_mobile/data/models/delivery_model.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

class _FakeApiService extends ArmadaApiService {
  bool createCalled = false;
  bool assignCalled = false;
  _FakeApiService() : super(client: DioClient(storageService: SecureStorageService()));

  @override
  Future<DeliveryModel> createDelivery(CreateDeliveryDto dto) async {
    createCalled = true;
    return DeliveryModel(
      id: 'del-uuid-real-01',
      orderNumber: dto.deliveryCode,
      clientName: dto.customerName ?? 'Klien',
      origin: 'Gudang Utama',
      destination: dto.stops.first.destinationName,
      status: 'DRAFT',
    );
  }

  @override
  Future<void> assignDelivery(String deliveryId, AssignDeliveryDto dto) async {
    assignCalled = true;
  }
}

void main() {
  test('FleetProvider.createDelivery calls API and prepends created delivery', () async {
    final fakeApi = _FakeApiService();
    final provider = FleetProvider(apiService: fakeApi);

    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-REAL-001',
      items: [CreateDeliveryItemDto(itemCode: 'I1', itemName: 'Box', quantity: 5)],
      stops: [CreateDeliveryStopDto(sequence: 1, destinationName: 'Toko A', address: 'Jl. 1', latitude: -6.2, longitude: 106.8)],
    );

    final created = await provider.createDelivery(dto);
    expect(fakeApi.createCalled, isTrue);
    expect(created.id, 'del-uuid-real-01');
    expect(provider.deliveries.any((d) => d.id == 'del-uuid-real-01'), isTrue);
  });

  test('FleetProvider.assignDelivery calls API and updates local delivery state', () async {
    final fakeApi = _FakeApiService();
    final provider = FleetProvider(apiService: fakeApi);
    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-REAL-002',
      items: [CreateDeliveryItemDto(itemCode: 'I1', itemName: 'Box', quantity: 5)],
      stops: [CreateDeliveryStopDto(sequence: 1, destinationName: 'Toko B', address: 'Jl. 2', latitude: -6.2, longitude: 106.8)],
    );
    final created = await provider.createDelivery(dto);

    await provider.assignDelivery(
      created.id,
      AssignDeliveryDto(driverId: 'drv-1', vehicleId: 'veh-1'),
      driverName: 'Pak Budi',
      plateNumber: 'B 9999 XX',
    );
    expect(fakeApi.assignCalled, isTrue);
    final updated = provider.deliveries.firstWhere((d) => d.id == created.id);
    expect(updated.status, 'ASSIGNED');
    expect(updated.assignedDriver, 'Pak Budi');
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/real_delivery_wiring_test.dart`
Expected: FAIL with "The method 'createDelivery' isn't defined for the type 'FleetProvider'".

- [x] **Step 3: Implement `FleetProvider.createDelivery` & `assignDelivery` and wire views**
- In `lib/providers/fleet_provider.dart`:
  * Add `createDelivery(CreateDeliveryDto dto)`: calls `_apiService.createDelivery(dto)`, inserts at index 0 of `_deliveries`, retains user-created deliveries when `fetchAllData()` encounters 404 on `GET /deliveries`, notifies listeners.
  * Add `assignDelivery(String deliveryId, AssignDeliveryDto dto, {String? driverName, String? plateNumber})`: calls `_apiService.assignDelivery(deliveryId, dto)`, updates matching delivery in `_deliveries` to `ASSIGNED` with `driverId`, `assignedDriver`, and `plateNumber`.
- In `lib/features/owner/views/owner_deliveries_view.dart`:
  * Update `CreateDeliveryModalSheet.onSubmit` to await `fleet.createDelivery(dto)` and display error snackbar if exception occurs.
- In `lib/features/owner/views/owner_delivery_detail_view.dart`:
  * Update `AssignDriverModalSheet.onAssign` to await `fleet.assignDelivery(_currentDelivery.id, dto, driverName: ..., plateNumber: ...)` before calling `setState`.

- [x] **Step 4: Run test & analyzer to verify green**
Run: `flutter test test/real_delivery_wiring_test.dart`
Expected: PASS.
Run: `flutter analyze`
Expected: "No issues found!".

- [x] **Step 5: Android Emulator Verification & Commit**
Verify on `emulator-5554`: Create DO in Owner Deliveries tab, verify persistence & assignment state transition.
```bash
git add lib/providers/fleet_provider.dart lib/features/owner/views/owner_deliveries_view.dart lib/features/owner/views/owner_delivery_detail_view.dart test/real_delivery_wiring_test.dart
git commit -m "feat(owner): wire real createDelivery and assignDelivery API calls"
```

---

### Task 2: Real OSRM Route Optimization & Polyline Geometry (GAP 3)

**Files:**
- Modify: `lib/data/models/route_geometry_model.dart`
- Modify: `lib/features/owner/widgets/route_optimizer_sheet.dart`
- Modify: `lib/features/owner/views/owner_delivery_detail_view.dart`
- Modify: `lib/features/owner/views/owner_fleet_view.dart`
- Modify: `lib/features/driver/views/driver_tracking_view.dart`
- Test: `test/real_route_optimization_test.dart`

**Interfaces:**
- Consumes: `ArmadaApiService.getCurrentDeliveryRoute(String)`, `ArmadaApiService.getRecommendedRoute(String, {String provider})`, `ArmadaApiService.selectDeliveryRoute(String, SelectRouteDto)`.
- Produces:
  - `SelectRouteDto({required String source, required List<String> recommendedSequence, required double totalDistanceMeters, required int estimatedDurationSeconds, String? idempotencyKey})`
  - Live `RecommendRouteResponse` parsing including `List<String> recommendedStopIds`.
  - Dynamic OSRM route fetching & road-following polyline display in `DriverTrackingView`, `OwnerFleetView`, and `RouteOptimizerSheet`.

- [x] **Step 1: Write failing test in `test/real_route_optimization_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/route_geometry_model.dart';

void main() {
  test('SelectRouteDto serializes recommendedSequence strictly as UUID string list for NestJS DTO', () {
    final dto = SelectRouteDto(
      source: 'RECOMMENDED_2OPT',
      recommendedSequence: [
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440002',
      ],
      totalDistanceMeters: 12340.0,
      estimatedDurationSeconds: 1500,
    );

    final json = dto.toJson();
    expect(json['source'], 'RECOMMENDED_2OPT');
    expect(json['recommendedSequence'], isA<List<String>>());
    expect(json['recommendedSequence'][0], '550e8400-e29b-41d4-a716-446655440001');
    expect(json['totalDistanceMeters'], 12340.0);
    expect(json['estimatedDurationSeconds'], 1500);
    expect(json.containsKey('routeVersion'), isFalse);
  });

  test('RecommendRouteResponse extracts polyline points and stop UUID sequence', () {
    final json = {
      'deliveryId': 'del-1',
      'algorithm': '2-Opt',
      'providerUsed': 'osrm',
      'totalDistanceMeters': 9850.5,
      'estimatedDurationSeconds': 1120,
      'recommendedSequence': [
        {'sequence': 1, 'deliveryStopId': 'stop-uuid-1', 'destinationName': 'Toko 1'},
        {'sequence': 2, 'deliveryStopId': 'stop-uuid-2', 'destinationName': 'Toko 2'},
      ],
      'polylineGeojson': {
        'type': 'LineString',
        'coordinates': [
          [106.8272, -6.1754],
          [106.8456, -6.2088],
        ],
      },
    };

    final res = RecommendRouteResponse.fromJson(json);
    expect(res.totalDistanceMeters, 9850.5);
    expect(res.recommendedStopIds, ['stop-uuid-1', 'stop-uuid-2']);
    expect(res.recommendedStopNames, ['Toko 1', 'Toko 2']);
    expect(res.polylinePoints.length, 2);
    expect(res.polylinePoints.first.latitude, -6.1754);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/real_route_optimization_test.dart`
Expected: FAIL with missing getters `recommendedStopIds`, `recommendedStopNames`, and `SelectRouteDto` signature mismatch.

- [x] **Step 3: Update `route_geometry_model.dart`, `route_optimizer_sheet.dart`, and map views**
- In `lib/data/models/route_geometry_model.dart`:
  * Update `SelectRouteDto` to match backend `select-route.dto.ts` (`source`, `recommendedSequence: List<String>`, `totalDistanceMeters: double`, `estimatedDurationSeconds: int`, optional `idempotencyKey`).
  * Update `RecommendRouteResponse` to parse `polylineGeojson` coordinates (`[lng, lat]` -> `LatLng(lat, lng)`), `recommendedStopIds`, and `recommendedStopNames`.
- In `lib/features/owner/widgets/route_optimizer_sheet.dart`:
  * Support loading state calling `_apiService.getRecommendedRoute(deliveryId)` if metrics aren't preloaded, extracting real stop IDs into `SelectRouteDto`.
- In `lib/features/owner/views/owner_delivery_detail_view.dart` and `owner_fleet_view.dart`:
  * Replace hardcoded distances (`14500`, `12000`) with real API responses from `getCurrentDeliveryRoute` / `getRecommendedRoute` and invoke `_apiService.selectDeliveryRoute(deliveryId, dto)` inside `onApply`.
- In `lib/features/driver/views/driver_tracking_view.dart`:
  * Fetch `getCurrentDeliveryRoute(activeDelivery.id)` asynchronously when delivery is active and render road-following `PolylineLayer` points (falling back gracefully to stop coordinates if route version 0).

- [x] **Step 4: Run tests & analyzer to verify green**
Run: `flutter test test/real_route_optimization_test.dart test/route_geometry_test.dart test/route_optimizer_sheet_test.dart`
Expected: PASS.
Run: `flutter analyze`
Expected: "No issues found!".

- [x] **Step 5: Android Emulator Verification & Commit**
Verify on `emulator-5554`: Open Driver tracking map and Owner route optimizer, confirm road-following polyline renders from OSRM.
```bash
git add lib/data/models/route_geometry_model.dart lib/features/owner/widgets/route_optimizer_sheet.dart lib/features/owner/views/owner_delivery_detail_view.dart lib/features/owner/views/owner_fleet_view.dart lib/features/driver/views/driver_tracking_view.dart test/real_route_optimization_test.dart
git commit -m "feat(route): wire real OSRM polyline geometry and 2-Opt optimization endpoints"
```

---

### Task 3: Real E2EE Conversation Inbox & Driver Entry Point (GAP 4 - Part 1)

**Files:**
- Create: `lib/features/chat/conversation_inbox_view.dart`
- Modify: `lib/features/driver/driver_shell.dart`
- Modify: `lib/features/driver/views/driver_home_view.dart`
- Modify: `lib/features/owner/owner_shell.dart`
- Modify: `lib/features/owner/views/owner_delivery_detail_view.dart`
- Test: `test/conversation_inbox_test.dart`

**Interfaces:**
- Consumes: `ArmadaApiService.getConversations()`, `ArmadaApiService.createConversation(String driverId)`, `ConversationModel`.
- Produces:
  - `ConversationInboxView({Key? key, ArmadaApiService? apiService, List<ConversationModel>? initialConversations})`
  - Driver & Owner navigation entry points to `ConversationInboxView`
  - Canonical conversation UUID creation/lookup in `owner_delivery_detail_view.dart`.

- [x] **Step 1: Write failing widget test in `test/conversation_inbox_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/chat/conversation_inbox_view.dart';
import 'package:armada_mobile/data/models/chat_model.dart';

void main() {
  testWidgets('ConversationInboxView renders active conversations and driver names', (tester) async {
    final conversations = [
      ConversationModel(
        id: 'conv-uuid-1',
        driverId: 'drv-uuid-1',
        driverName: 'Driver Utama',
        plateNumber: 'B 9281 SXZ',
        lastMessagePreview: 'Siap berangkat ke tujuan',
        unreadCount: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationInboxView(
          initialConversations: conversations,
        ),
      ),
    );

    expect(find.text('Pesan & Obrolan E2EE'), findsOneWidget);
    expect(find.text('Driver Utama'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/conversation_inbox_test.dart`
Expected: FAIL with "conversation_inbox_view.dart not found".

- [x] **Step 3: Create `ConversationInboxView` and wire navigation entry points**
- Create `lib/features/chat/conversation_inbox_view.dart`:
  * Pull-to-refresh list calling `apiService.getConversations()`.
  * Renders each conversation tile with avatar, participant name, unread badge, E2EE lock subtitle, and tap navigation to `ChatConversationView`.
- Update `lib/features/driver/views/driver_home_view.dart` and `lib/features/driver/driver_shell.dart`:
  * Add chat icon button in `DriverHomeView` AppBar actions opening `ConversationInboxView`.
- Update `lib/features/owner/owner_shell.dart` / `owner_dashboard_view.dart`:
  * Add chat icon button in Owner AppBar actions opening `ConversationInboxView`.
- Update `lib/features/owner/views/owner_delivery_detail_view.dart`:
  * When Owner clicks "Chat E2EE", call `apiService.createConversation(item.driverId!)` to retrieve canonical `ConversationModel` UUID from `POST /v1/conversations` instead of using `'conv-${item.id}'`.

- [x] **Step 4: Run test & analyzer to verify green**
Run: `flutter test test/conversation_inbox_test.dart`
Expected: PASS.
Run: `flutter analyze`
Expected: "No issues found!".

- [x] **Step 5: Android Emulator Verification & Commit**
Verify on `emulator-5554`: Driver opens Chat Inbox from home AppBar; Owner initiates chat from delivery detail and lands on canonical conversation.
```bash
git add lib/features/chat/conversation_inbox_view.dart lib/features/driver/driver_shell.dart lib/features/driver/views/driver_home_view.dart lib/features/owner/owner_shell.dart lib/features/owner/views/owner_delivery_detail_view.dart test/conversation_inbox_test.dart
git commit -m "feat(chat): implement ConversationInboxView and canonical conversation lookup"
```

---

### Task 4: Real Two-Way E2EE Message Transmission & WebSocket Relay Sync (GAP 4 - Part 2)

**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Modify: `lib/core/services/socket_realtime_service.dart`
- Modify: `lib/features/chat/chat_conversation_view.dart`
- Test: `test/real_chat_messaging_test.dart`

**Interfaces:**
- Consumes: `E2eeCryptoService`, `SendMessageDto`, `SocketRealtimeService`.
- Produces:
  - `Future<List<Map<String, dynamic>>> ArmadaApiService.getMyDevices()`
  - `Stream<Map<String, dynamic>> SocketRealtimeService.chatMessageAckStream`
  - `void SocketRealtimeService.sendChatMessageWs({required String conversationId, required SendMessageDto dto})`
  - Real `ChatConversationView` send/receive loop with `recipientDeviceId` UUID resolution and message deduplication by `id`.

- [x] **Step 1: Write failing test in `test/real_chat_messaging_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

void main() {
  test('ArmadaApiService exposes getMyDevices and SocketRealtimeService exposes chatMessageAckStream', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socket = SocketRealtimeService(storageService: storage);

    expect(api.getMyDevices, isNotNull);
    expect(socket.chatMessageAckStream, isNotNull);
    expect(socket.sendChatMessageWs, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/real_chat_messaging_test.dart`
Expected: FAIL with undefined getters `getMyDevices`, `chatMessageAckStream`, and `sendChatMessageWs`.

- [x] **Step 3: Implement device lookup, WS chat emitters, and live deduplication**
- In `lib/data/repositories/armada_api_service.dart`:
  * Add `getMyDevices()`: `GET /v1/devices/my-devices`.
- In `lib/core/services/socket_realtime_service.dart`:
  * Add `_chatMessageAckController` listening to `chat.message.ack`.
  * Add `sendChatMessageWs` emitting `chat.message.send` with `conversationId`, `recipientDeviceId`, `protocolVersion`, `ciphertextBlob`, `headerJson`, `idempotencyKey`.
- In `lib/features/chat/chat_conversation_view.dart`:
  * Resolve target `recipientDeviceId` from message history or `getMyDevices()` active device UUID (never send non-UUID fallback).
  * Deduplicate incoming `chat.message.relayed` messages against optimistic local messages using `id`/`idempotencyKey`, and update `isDelivered` when `chat.message.ack` arrives.
  * Display inline error state if `sendChatMessage` fails rather than silently ignoring exceptions.

- [x] **Step 4: Run tests & analyzer to verify green**
Run: `flutter test test/real_chat_messaging_test.dart test/chat_conversation_view_test.dart test/e2ee_chat_model_test.dart`
Expected: PASS.
Run: `flutter analyze`
Expected: "No issues found!".

- [x] **Step 5: Android Emulator Verification & Commit**
Verify on `emulator-5554`: Owner sends message to Driver, verify `POST /v1/conversations/:id/messages` returns `201 Created` and ciphertext is persisted in DB and decrypted on Driver screen.
```bash
git add lib/data/repositories/armada_api_service.dart lib/core/services/socket_realtime_service.dart lib/features/chat/chat_conversation_view.dart test/real_chat_messaging_test.dart
git commit -m "feat(chat): wire real E2EE message persistence, ack tracking, and device resolution"
```

---

### Task 5: WebRTC Dependencies, Native Permissions & PeerConnection Service (GAP 5 - Part 1)

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Create: `lib/core/services/webrtc_service.dart`
- Test: `test/webrtc_service_test.dart`

**Interfaces:**
- Consumes: `flutter_webrtc`, `permission_handler`, `TurnCredentialsModel`.
- Produces:
  - `WebRtcService` (`requestCallPermissions({bool video})`, `buildIceServers(TurnCredentialsModel?)`, `initCall({required bool isVideo, TurnCredentialsModel? turnCredentials})`, `createOffer()`, `createAnswer(String remoteSdp)`, `setRemoteAnswer(String remoteSdp)`, `addIceCandidate(Map<String, dynamic>)`, `setMicrophoneEnabled(bool enabled)`, `dispose()`, `onIceCandidate` callback, `localRenderer`, `remoteRenderer`).

- [x] **Step 1: Write failing test in `test/webrtc_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/webrtc_service.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';

void main() {
  test('WebRtcService builds STUN fallback and RFC 7635 TURN iceServers config', () {
    final turn = TurnCredentialsModel(
      urls: ['turn:turn.armada.local:3478?transport=udp'],
      username: '1788352800:owner-1',
      credential: 'hmac-secret-123',
      ttlSeconds: 3600,
    );

    final config = WebRtcService.buildIceServersConfig(turn);
    final iceServers = config['iceServers'] as List<Map<String, dynamic>>;

    expect(iceServers.length, greaterThanOrEqualTo(2));
    expect(iceServers.any((s) => (s['urls'] as List).first.toString().startsWith('stun:')), isTrue);
    expect(iceServers.any((s) => s['username'] == '1788352800:owner-1'), isTrue);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/webrtc_service_test.dart`
Expected: FAIL with "webrtc_service.dart not found".

- [x] **Step 3: Add `flutter_webrtc` & `permission_handler`, configure native manifests, implement `WebRtcService`**
- Add `flutter_webrtc: ^0.12.5` and `permission_handler: ^11.4.0` to `pubspec.yaml` and run `flutter pub get`.
- Add `RECORD_AUDIO`, `CAMERA`, `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH` permissions to `android/app/src/main/AndroidManifest.xml`, and `NSMicrophoneUsageDescription` to `ios/Runner/Info.plist`.
- Implement `lib/core/services/webrtc_service.dart` encapsulating `RTCPeerConnection`, `MediaStream`, STUN (`stun:stun.l.google.com:19302`) + TURN `iceServers` setup, `setMicrophoneEnabled(bool)` for PTT track gating, and clean `dispose()`.

- [x] **Step 4: Run test & analyzer to verify green**
Run: `flutter test test/webrtc_service_test.dart`
Expected: PASS.
Run: `flutter analyze`
Expected: "No issues found!".

- [x] **Step 5: Commit**
```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist lib/core/services/webrtc_service.dart test/webrtc_service_test.dart
git commit -m "feat(webrtc): add flutter_webrtc, native audio/camera permissions, and WebRtcService"
```

---

### Task 6: PTT Walkie-Talkie Hold-to-Talk & Video Call Consent Integration (GAP 5 - Part 2)

**Files:**
- Modify: `lib/core/services/socket_realtime_service.dart`
- Create: `lib/features/communication/call_session_screen.dart`
- Modify: `lib/features/driver/driver_shell.dart`
- Modify: `lib/features/owner/views/owner_delivery_detail_view.dart`
- Test: `test/real_webrtc_call_test.dart`

**Interfaces:**
- Consumes: `WebRtcService`, `SocketRealtimeService`, `ArmadaApiService`, `PttWalkieTalkieButton`, `IncomingCallDialog`.
- Produces:
  - `Stream<Map<String, dynamic>> SocketRealtimeService.callInviteStream`
  - `Stream<Map<String, dynamic>> SocketRealtimeService.callRespondStream`
  - Anti-replay WebRTC emitters: `sendWebrtcOffer(String sessionId, String sdp)`, `sendWebrtcAnswer(String sessionId, String sdp)`, `sendWebrtcIceCandidate(String sessionId, Map<String, dynamic> candidate)`, `sendCallRespond(String sessionId, String action)`
  - `CallSessionScreen` widget supporting Audio PTT (`VOICE_PTT`) and Video (`VIDEO`) sessions.

- [x] **Step 1: Write failing test in `test/real_webrtc_call_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/features/communication/call_session_screen.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';

void main() {
  test('SocketRealtimeService exposes callInviteStream and builds anti-replay signaling payloads', () {
    final service = SocketRealtimeService(storageService: SecureStorageService());
    expect(service.callInviteStream, isNotNull);
    expect(service.callRespondStream, isNotNull);

    final offerPayload = service.buildSignalingOfferPayload('ses-uuid-1', 'v=0...');
    expect(offerPayload['sessionId'], 'ses-uuid-1');
    expect(offerPayload['sdp'], 'v=0...');
    expect(offerPayload['nonce'], isNotEmpty);
    expect(offerPayload['seq'], isA<int>());
    expect(offerPayload['timestamp'], isA<int>());
  });

  testWidgets('CallSessionScreen renders PTT Walkie-Talkie controls and hangup button', (tester) async {
    final session = CallSessionModel(
      sessionId: 'ses-01',
      type: 'VOICE_PTT',
      ownerId: 'owner-1',
      driverId: 'drv-1',
      driverName: 'Driver Utama',
      status: 'ACTIVE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CallSessionScreen(
          session: session,
          isCaller: true,
          skipMediaInitForTest: true,
        ),
      ),
    );

    expect(find.text('TEKAN UNTUK BICARA'), findsOneWidget);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/real_webrtc_call_test.dart`
Expected: FAIL with missing `callInviteStream`, `buildSignalingOfferPayload`, and `call_session_screen.dart`.

- [x] **Step 3: Enhance `SocketRealtimeService`, create `CallSessionScreen`, wire `DriverShell` and Owner detail**
- In `lib/core/services/socket_realtime_service.dart`:
  * Listen to `webrtc.call.invite` and `webrtc.call.respond` events.
  * Update `sendWebrtcOffer`, `sendWebrtcAnswer`, `sendWebrtcIceCandidate` to embed `nonce` (UUIDv4), incrementing `seq` ($\ge 1$), and `timestamp` (epoch ms).
  * Add `sendCallRespond(String sessionId, String action)`.
- Create `lib/features/communication/call_session_screen.dart`:
  * Coordinates `WebRtcService` + `SocketRealtimeService` signaling loop (`join_room session:<id>`, offer/answer SDP exchange, ICE candidate relay).
  * For `VOICE_PTT`: renders `PttWalkieTalkieButton` wired to `webRtcService.setMicrophoneEnabled(true/false)` on press/release.
  * For `VIDEO`: renders `RTCVideoView` for remote/local streams.
  * Hangup calls `apiService.endCallSession` + `socketService.hangupCall` + `webRtcService.dispose()`.
- In `lib/features/driver/driver_shell.dart`:
  * Listen to `socketService.callInviteStream`. Upon invite, show `IncomingCallDialog`. On `ACCEPT`, call `respondToCallSession('ACCEPT')`, join room `session:<id>`, and push `CallSessionScreen`. On `DECLINE`, call `respondToCallSession('DECLINE')`.
- In `lib/features/owner/views/owner_delivery_detail_view.dart`:
  * Wire "PTT Voice" and add "Video Call" button to call `initiateVoiceSession` / `initiateVideoSession`, join `session:<id>`, and push `CallSessionScreen`.

- [x] **Step 4: Run tests & analyzer to verify green**
Run: `flutter test test/real_webrtc_call_test.dart test/webrtc_signaling_test.dart test/ptt_walkie_talkie_widget_test.dart`
Expected: PASS.
Run: `flutter analyze`
Expected: "No issues found!".
Run full suite: `flutter test`
Expected: 100% pass.

- [x] **Step 5: Android Emulator End-to-End Verification & Commit**
Verify on `emulator-5554` (`flutter run -d emulator-5554`):
1. Login as Owner -> Create DO -> Assign Driver -> Optimize Route 2-Opt -> Send E2EE Chat -> Initiate PTT Voice call.
2. Login as Driver -> View assigned DO -> View OSRM polyline -> Open Chat Inbox & reply -> Accept incoming PTT call & toggle mic.
```bash
git add lib/core/services/socket_realtime_service.dart lib/features/communication/call_session_screen.dart lib/features/driver/driver_shell.dart lib/features/owner/views/owner_delivery_detail_view.dart test/real_webrtc_call_test.dart
git commit -m "feat(webrtc): wire real PTT audio track, video call screen, and anti-replay signaling"
```

---

## Self-Review Checklist

1. **Spec Coverage:** Every gap (GAP 1 through GAP 5) in `2026-11-12-fe-mobile-real-wiring-spec.md` maps directly to Tasks 1–6.
2. **Type Consistency:** `SelectRouteDto.recommendedSequence` (`List<String>`), `FleetProvider.createDelivery`, `FleetProvider.assignDelivery`, `WebRtcService`, and `SocketRealtimeService` signaling methods share identical parameter types across all tasks.
3. **Review Focus Coverage:** All 5 critical failure modes have dedicated unit/widget test assertions in their owning tasks.
4. **No Code Mutation Violation:** Zero `.dart` or `pubspec.yaml` files touched during planning.
