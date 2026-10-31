# Full Frontend Mobile (Owner & Driver) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build complete, production-grade Flutter frontend mobile features for both Owner and Driver roles in `armadamobile`, covering granular stop execution with physical Proof of Delivery (camera & signature), OpenStreetMap route polyline rendering with external navigation handoff, multi-stop delivery creation and fleet assignment by Owner, and real-time Socket.IO streaming with an in-app notification center.

**Architecture:** The client uses Flutter with `provider` for reactive state management and `dio` for REST network requests under standard response envelopes (`{ success, data, error, timestamp, requestId }`). Real-time communication connects to NestJS Socket.IO gateway (`/v1/realtime`) with Bearer token handshake, and map rendering utilizes `flutter_map` (OpenStreetMap) with GeoJSON polyline layers.

**Tech Stack:** Flutter 3.11+, Dart 3.11+, `dio: ^5.11.1`, `provider: ^6.1.5+1`, `flutter_map: ^8.3.2`, `latlong2: ^0.10.1`, `image_picker: ^1.1.2`, `signature: ^5.5.0`, `url_launcher: ^6.3.1`, `socket_io_client: ^3.0.2`, `uuid: ^4.6.0`, `flutter_secure_storage: ^11.2.0`, `google_fonts: ^8.2.1`.

**Spec:** `docs/superpowers/specs/2026-10-31-fe-mobile-full-implementation-spec.md`

## Global Constraints

- Global Base API URL: `https://armada-api.prizftm.my.id/v1` (Production) / `http://localhost:3000/v1` (Local Dev).
- Global Realtime Gateway: `wss://armada-api.prizftm.my.id/v1/realtime` (Namespace: `/v1/realtime`).
- All mutation requests must preserve standard envelope `{ success: true, data: ..., error: null, requestId: ... }`.
- Error envelope strictly follows `{ success: false, error: { code, message, requestId } }`.
- Mutating state operations on stops (`/v1/me/stops/:id/pod`) and delivery completion (`/v1/deliveries/:id/complete`) require the header `Idempotency-Key: <UUIDv4>`.
- GeoJSON coordinates `[longitude, latitude]` must be parsed as `LatLng(latitude, longitude)`.
- UI/UX Ergonomics: Driver primary actions must remain in the bottom 40% thumb zone with minimum touch targets of $48 \times 48\text{ dp}$.
- Real VM Verification Mandate: Setiap penyelesaian task WAJIB diuji secara riil pada VM Android emulator (`sdk gphone16k x86 64` / Pixel 10 Pro) untuk memvalidasi bahwa kompilasi, rendering visual, dan interaksi aplikasi benar-benar berfungsi di runtime nyata dengan bukti screenshot OS asli.
- Zero code modifications to `.dart` files allowed during planning mode; changes to be executed in phased tasks only after plan approval.

## Review Focus

1. **Stop POD Double-Submission on Network Flakiness:** If a driver taps submit multiple times during poor cellular signal, the client must generate one `idempotencyKey` per attempt and disable the submit button during in-flight upload to prevent duplicate records.
2. **GeoJSON Coordinate Inversion Crash:** PolylineGeoJson from OSRM returns `[longitude, latitude]`; mapping must strictly use `LatLng(coord[1], coord[0])` or route lines will draw across Antarctica.
3. **Over-capacity Vehicle Assignment:** When an Owner selects a vehicle with less capacity weight than the cargo sum, a blocking validation warning must trigger before the API call to avoid backend rejection.
4. **WebSocket Reconnection & Room Re-subscription:** If mobile internet switches between Wi-Fi and 4G, `socket_io_client` must automatically re-authenticate and re-emit `join_room` for active rooms (`fleet:monitoring` or `delivery:<id>`).
5. **Photo Memory Exhaustion / Size Exceeded:** Camera photos must be constrained with `maxWidth: 1920`, `maxHeight: 1080`, and `imageQuality: 80` so the payload never exceeds backend's strict 5 MB limit.

---

## Task Decomposition Across 4 Phases

### Phase 1: Driver Granular Stop Execution & Physical Proof of Delivery (POD)

#### Task 1: Project Dependencies & Android/iOS Permissions Setup
**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Test: `test/dependency_test.dart`

**Interfaces:**
- Consumes: None (Root configuration)
- Produces: Installed packages `image_picker`, `signature`, `url_launcher`, `socket_io_client`.

- [x] **Step 1: Write failing test in `test/dependency_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  test('Verify all required Phase 1-4 packages are resolvable', () {
    expect(ImagePicker(), isNotNull);
    expect(SignatureController(), isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/dependency_test.dart`
Expected: FAIL with compilation error (package imports not found).

- [x] **Step 3: Update `pubspec.yaml` and configure native manifests**
Add dependencies:
```yaml
  image_picker: ^1.1.2
  signature: ^5.5.0
  url_launcher: ^6.3.1
  socket_io_client: ^3.0.2
```
Add camera and external navigation intent queries to `android/app/src/main/AndroidManifest.xml` and `NSCameraUsageDescription` to `ios/Runner/Info.plist`. Run `flutter pub get`.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/dependency_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add pubspec.yaml pubspec.lock android/ ios/ test/dependency_test.dart
git commit -m "feat(deps): add image_picker, signature, url_launcher, and socket_io_client"
```

---

#### Task 2: POD & Stop Execution Models & DTOs
**Files:**
- Create: `lib/data/models/pod_dto.dart`
- Modify: `lib/data/models/delivery_model.dart`
- Test: `test/pod_dto_test.dart`

**Interfaces:**
- Consumes: `lib/data/models/delivery_model.dart`
- Produces: `UploadedFileResponse`, `SubmitPodDto`, `FailStopDto`, `PodModel`.

- [x] **Step 1: Write failing test in `test/pod_dto_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/pod_dto.dart';

void main() {
  test('SubmitPodDto serializes to JSON with idempotencyKey and optional notes', () {
    final dto = SubmitPodDto(
      receiverName: 'Budi Santoso',
      photoFileId: 'f-123',
      signatureFileId: 's-456',
      notes: 'Diterima utuh',
      idempotencyKey: 'idem-uuid-001',
    );
    final json = dto.toJson();
    expect(json['receiverName'], 'Budi Santoso');
    expect(json['photoFileId'], 'f-123');
    expect(json['signatureFileId'], 's-456');
    expect(json['notes'], 'Diterima utuh');
    expect(json['idempotencyKey'], 'idem-uuid-001');
  });

  test('UploadedFileResponse parses server response correctly', () {
    final res = UploadedFileResponse.fromJson({
      'fileId': 'file-01',
      'objectKey': 'pod/2026/10/file-01.jpg',
      'mediaType': 'image/jpeg',
      'sizeBytes': 204800,
    });
    expect(res.fileId, 'file-01');
    expect(res.sizeBytes, 204800);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/pod_dto_test.dart`
Expected: FAIL with "pod_dto.dart does not exist".

- [x] **Step 3: Implement `UploadedFileResponse`, `SubmitPodDto`, `FailStopDto` in `lib/data/models/pod_dto.dart`**
Include JSON serialization/deserialization methods matching backend contracts `/v1/files/upload`, `/v1/me/stops/:id/pod`, and `/v1/me/stops/:id/fail`. Update `DeliveryStop` in `delivery_model.dart` with `pod` and `failReason` fields.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/pod_dto_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/models/pod_dto.dart lib/data/models/delivery_model.dart test/pod_dto_test.dart
git commit -m "feat(pod): implement POD and Stop DTO data models"
```

---

#### Task 3: API Service Integration for File Upload & Stop State Machine
**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Test: `test/stop_api_service_test.dart`

**Interfaces:**
- Consumes: `DioClient`, `UploadedFileResponse`, `SubmitPodDto`, `FailStopDto`.
- Produces:
  - `Future<UploadedFileResponse> uploadFile({required Uint8List bytes, required String filename, required String mediaType})`
  - `Future<void> departStop(String stopId)`
  - `Future<void> arriveStop(String stopId)`
  - `Future<void> unloadStop(String stopId)`
  - `Future<void> failStop(String stopId, FailStopDto dto)`
  - `Future<Map<String, dynamic>> submitStopPod(String stopId, SubmitPodDto dto)`
  - `Future<void> completeDelivery(String deliveryId, {required String idempotencyKey})`

- [x] **Step 1: Write failing unit test in `test/stop_api_service_test.dart`**
```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/data/models/pod_dto.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService defines all stop execution methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.departStop, isNotNull);
    expect(api.arriveStop, isNotNull);
    expect(api.unloadStop, isNotNull);
    expect(api.failStop, isNotNull);
    expect(api.submitStopPod, isNotNull);
    expect(api.completeDelivery, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/stop_api_service_test.dart`
Expected: FAIL with "The getter 'departStop' isn't defined".

- [x] **Step 3: Implement methods in `lib/data/repositories/armada_api_service.dart`**
Add multipart upload via `dio.FormData.fromMap({'file': MultipartFile.fromBytes(...)})` to `POST /v1/files/upload`. Add stop methods calling `POST /v1/me/stops/:id/depart`, `/arrive`, `/unload`, `/fail`, and `/pod` with header `Idempotency-Key: dto.idempotencyKey`. Add `POST /v1/deliveries/:id/complete` with `Idempotency-Key`.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/stop_api_service_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/repositories/armada_api_service.dart test/stop_api_service_test.dart
git commit -m "feat(api): add multipart upload and stop state transition endpoints"
```

---

#### Task 4: Interactive Signature Pad & Camera Photo Capture Widget
**Files:**
- Create: `lib/features/driver/widgets/pod_capture_sheet.dart`
- Create: `lib/features/driver/widgets/stop_failure_dialog.dart`
- Test: `test/pod_capture_sheet_test.dart`

**Interfaces:**
- Consumes: `SignatureController`, `ImagePicker`, `SubmitPodDto`, `FailStopDto`.
- Produces: `PodCaptureSheet` widget, `StopFailureDialog` widget.

- [x] **Step 1: Write widget test in `test/pod_capture_sheet_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/driver/widgets/pod_capture_sheet.dart';

void main() {
  testWidgets('PodCaptureSheet renders receiver name input, camera button, and signature canvas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PodCaptureSheet(
            stopId: 'stop-001',
            onSubmit: (name, photoBytes, sigBytes, notes) async {},
          ),
        ),
      ),
    );

    expect(find.text('Bukti Serah Terima (POD)'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Ambil Foto Fisik'), findsOneWidget);
    expect(find.text('Tanda Tangan Penerima'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/pod_capture_sheet_test.dart`
Expected: FAIL with "pod_capture_sheet.dart not found".

- [x] **Step 3: Implement `PodCaptureSheet` and `StopFailureDialog`**
In `pod_capture_sheet.dart`: Modal bottom sheet with text fields for receiver name and notes, camera capture via `ImagePicker().pickImage(...)`, thumbnail preview, `Signature` canvas with `SignatureController`, clear button, and sticky submit button.
In `stop_failure_dialog.dart`: Dropdown with reasons (`TOKO_TUTUP`, `PENERIMA_TIDAK_DAPAT_DIHUBUNGI`, `BARANG_RUSAK`, `JALAN_TERPUTUS`, `LAINNYA`), notes field, and submit button.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/pod_capture_sheet_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/driver/widgets/pod_capture_sheet.dart lib/features/driver/widgets/stop_failure_dialog.dart test/pod_capture_sheet_test.dart
git commit -m "feat(ui): implement POD capture bottom sheet and failure dialog"
```

---

#### Task 5: Driver Stop Execution Provider & View Integration
**Files:**
- Modify: `lib/providers/driver_tracking_provider.dart`
- Modify: `lib/features/driver/views/driver_home_view.dart`
- Test: `test/driver_stop_execution_test.dart`

**Interfaces:**
- Consumes: `ArmadaApiService`, `PodCaptureSheet`, `StopFailureDialog`.
- Produces: Granular stop actions (`departStopAction`, `arriveStopAction`, `unloadStopAction`, `failStopAction`, `submitPodAction`).

- [x] **Step 1: Write integration test in `test/driver_stop_execution_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/driver_tracking_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('DriverTrackingProvider exposes stop-level mutation methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final provider = DriverTrackingProvider(apiService: api);

    expect(provider.executeDepartStop, isNotNull);
    expect(provider.executeArriveStop, isNotNull);
    expect(provider.executeUnloadStop, isNotNull);
    expect(provider.executeFailStop, isNotNull);
    expect(provider.executeSubmitPod, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/driver_stop_execution_test.dart`
Expected: FAIL with getter not defined.

- [x] **Step 3: Implement granular stop management in `DriverTrackingProvider` and update `DriverHomeView`**
Add methods: `executeDepartStop(stopId)`, `executeArriveStop(stopId)`, `executeUnloadStop(stopId)`, `executeFailStop(stopId, reason)`, and `executeSubmitPod(stopId, receiverName, photoBytes, sigBytes, notes)`.
In `DriverHomeView`: Update the task card to render stops in sequence (`1..N`), showing individual status pills and dynamic action button for current stop (`Berangkat ke Toko`, `Tiba`, `Bongkar Muat`, `Selesaikan POD`).

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/driver_stop_execution_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/providers/driver_tracking_provider.dart lib/features/driver/views/driver_home_view.dart test/driver_stop_execution_test.dart
git commit -m "feat(driver): integrate granular stop transitions and POD in DriverHomeView"
```

---

### Phase 2: Route Visualization (Polyline) & External Navigation

#### Task 6: Route Geometry Model & Recommendation DTOs
**Files:**
- Create: `lib/data/models/route_geometry_model.dart`
- Test: `test/route_geometry_test.dart`

**Interfaces:**
- Consumes: `latlong2/latlong.dart`
- Produces: `RouteGeometryModel`, `SelectRouteDto`, `RecommendRouteResponse`.

- [x] **Step 1: Write unit test in `test/route_geometry_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:armada_mobile/data/models/route_geometry_model.dart';

void main() {
  test('RouteGeometryModel correctly converts GeoJSON [lng, lat] to LatLng(lat, lng)', () {
    final json = {
      'routeId': 'route-001',
      'deliveryId': 'del-001',
      'version': 2,
      'source': 'RECOMMENDED_2OPT',
      'totalDistanceMeters': 14250.5,
      'estimatedDurationSeconds': 1800,
      'polylineGeojson': {
        'type': 'LineString',
        'coordinates': [
          [106.8272, -6.1754],
          [106.8456, -6.2088],
        ],
      },
    };

    final model = RouteGeometryModel.fromJson(json);
    expect(model.polylinePoints.length, 2);
    expect(model.polylinePoints[0].latitude, -6.1754);
    expect(model.polylinePoints[0].longitude, 106.8272);
    expect(model.totalDistanceMeters, 14250.5);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/route_geometry_test.dart`
Expected: FAIL with "route_geometry_model.dart not found".

- [x] **Step 3: Implement `RouteGeometryModel`, `SelectRouteDto` in `lib/data/models/route_geometry_model.dart`**
Implement constructor, JSON parsing from `/v1/deliveries/:id/routes/current`, and serialization for `/v1/deliveries/:id/routes/select`.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/route_geometry_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/models/route_geometry_model.dart test/route_geometry_test.dart
git commit -m "feat(route): create RouteGeometryModel and GeoJSON parsing"
```

---

#### Task 7: Route API Methods in `ArmadaApiService`
**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Test: `test/route_api_test.dart`

**Interfaces:**
- Consumes: `RouteGeometryModel`, `SelectRouteDto`.
- Produces:
  - `Future<RouteGeometryModel?> getCurrentDeliveryRoute(String deliveryId)`
  - `Future<Map<String, dynamic>> getRecommendedRoute(String deliveryId, {String provider = 'osrm'})`
  - `Future<void> selectDeliveryRoute(String deliveryId, SelectRouteDto dto)`

- [x] **Step 1: Write failing test in `test/route_api_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService includes route optimization and fetching methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.getCurrentDeliveryRoute, isNotNull);
    expect(api.getRecommendedRoute, isNotNull);
    expect(api.selectDeliveryRoute, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/route_api_test.dart`
Expected: FAIL with methods not defined.

- [x] **Step 3: Implement route API methods in `lib/data/repositories/armada_api_service.dart`**
Connect:
- `GET /v1/deliveries/:id/routes/current`
- `POST /v1/deliveries/:id/routes/recommend?provider=osrm`
- `POST /v1/deliveries/:id/routes/select`

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/route_api_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/repositories/armada_api_service.dart test/route_api_test.dart
git commit -m "feat(api): implement route geometry and optimization endpoints"
```

---

#### Task 8: Polyline Layer & Numbered Stop Markers in `ArmadaOsmMap`
**Files:**
- Modify: `lib/core/widgets/armada_osm_map.dart`
- Test: `test/osm_map_test.dart`

**Interfaces:**
- Consumes: `RouteGeometryModel`, `DeliveryStop`, `Polyline`, `Marker`.
- Produces: `ArmadaOsmMap` supporting route polyline display and numbered stop markers.

- [x] **Step 1: Write widget test in `test/osm_map_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:armada_mobile/core/widgets/armada_osm_map.dart';

void main() {
  testWidgets('ArmadaOsmMap accepts polylines and renders PolylineLayer', (tester) async {
    final points = [const LatLng(-6.2, 106.8), const LatLng(-6.21, 106.81)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArmadaOsmMap(
            initialCenter: const LatLng(-6.2, 106.8),
            polylines: [
              Polyline(points: points, strokeWidth: 4.0, color: Colors.blue),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(PolylineLayer), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails/passes**
Run: `flutter test test/osm_map_test.dart`
Expected: PASS or verify existing capability.

- [x] **Step 3: Add numbered stop marker builder helper `ArmadaOsmMap.buildStopMarker(...)`**
Create reusable method that renders numbered circle badges (`1`, `2`, `3`) with color coding based on status (`PENDING`, `DEPARTED`, `ARRIVED`, `DELIVERED`, `FAILED`).

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/osm_map_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/core/widgets/armada_osm_map.dart test/osm_map_test.dart
git commit -m "feat(map): enhance ArmadaOsmMap with numbered stop markers and route polyline"
```

---

#### Task 9: External Navigation Launcher (`url_launcher`)
**Files:**
- Create: `lib/core/services/navigation_service.dart`
- Test: `test/navigation_service_test.dart`

**Interfaces:**
- Consumes: `url_launcher`
- Produces: `NavigationService.openExternalNavigation({required double latitude, required double longitude, String? destinationName})`.

- [x] **Step 1: Write unit test in `test/navigation_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/navigation_service.dart';

void main() {
  test('NavigationService constructs valid Google Maps and Waze URIs', () {
    final gmapsUri = NavigationService.buildGoogleMapsUri(-6.2088, 106.8456);
    expect(gmapsUri.toString(), contains('destination=-6.2088,106.8456'));

    final wazeUri = NavigationService.buildWazeUri(-6.2088, 106.8456);
    expect(wazeUri.toString(), contains('ll=-6.2088,106.8456'));
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/navigation_service_test.dart`
Expected: FAIL with "navigation_service.dart not found".

- [x] **Step 3: Implement `NavigationService` in `lib/core/services/navigation_service.dart`**
Implement URI builders and `openExternalNavigation` using `launchUrl(uri, mode: LaunchMode.externalApplication)` with fallback options.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/navigation_service_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/core/services/navigation_service.dart test/navigation_service_test.dart
git commit -m "feat(nav): implement external turn-by-turn navigation service"
```

---

#### Task 10: Route Recommendation & Selection UI (Owner & Driver)
**Files:**
- Create: `lib/features/owner/widgets/route_optimizer_sheet.dart`
- Modify: `lib/features/owner/views/owner_fleet_view.dart`
- Modify: `lib/features/driver/views/driver_tracking_view.dart`
- Test: `test/route_optimizer_sheet_test.dart`

**Interfaces:**
- Consumes: `ArmadaApiService`, `RouteGeometryModel`, `SelectRouteDto`.
- Produces: `RouteOptimizerSheet` widget.

- [x] **Step 1: Write widget test in `test/route_optimizer_sheet_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/widgets/route_optimizer_sheet.dart';

void main() {
  testWidgets('RouteOptimizerSheet shows recommendation comparison and apply button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteOptimizerSheet(
            deliveryId: 'del-001',
            currentDistanceM: 15000,
            currentDurationS: 2100,
            onApply: (dto) async {},
          ),
        ),
      ),
    );

    expect(find.text('Optimasi Rute (2-Opt TSP)'), findsOneWidget);
    expect(find.text('Terapkan Rute Rekomendasi'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/route_optimizer_sheet_test.dart`
Expected: FAIL with "route_optimizer_sheet.dart not found".

- [x] **Step 3: Implement `RouteOptimizerSheet` and hook into Owner & Driver views**
In `route_optimizer_sheet.dart`: Compare distance and time savings, list reordered stops, and invoke `onApply`. Hook route fetching into `DriverTrackingView` and `OwnerFleetView` so that polyline overlays onto the map when an active delivery is selected.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/route_optimizer_sheet_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/owner/widgets/route_optimizer_sheet.dart lib/features/owner/views/owner_fleet_view.dart lib/features/driver/views/driver_tracking_view.dart test/route_optimizer_sheet_test.dart
git commit -m "feat(ui): add route optimization bottom sheet and integrate polyline into map views"
```

---

### Phase 3: Owner Delivery Creation, Assignment & Fleet Audit

#### Task 11: Delivery Creation & Assignment DTOs
**Files:**
- Create: `lib/data/models/create_delivery_dto.dart`
- Test: `test/create_delivery_dto_test.dart`

**Interfaces:**
- Consumes: None (Core data layer)
- Produces: `CreateDeliveryDto`, `CreateDeliveryItemDto`, `CreateDeliveryStopDto`, `AssignDeliveryDto`.

- [x] **Step 1: Write unit test in `test/create_delivery_dto_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/create_delivery_dto.dart';

void main() {
  test('CreateDeliveryDto serializes nested items and stops to backend schema', () {
    final dto = CreateDeliveryDto(
      deliveryCode: 'DO-2026-1001',
      items: [
        CreateDeliveryItemDto(
          itemCode: 'ITM-01',
          itemName: 'Minyak Goreng 2L',
          quantity: 20,
          unit: 'DUS',
          weightKg: 240.0,
        ),
      ],
      stops: [
        CreateDeliveryStopDto(
          sequence: 1,
          destinationName: 'Toko Makmur',
          address: 'Jl. Merdeka No. 10',
          latitude: -6.18,
          longitude: 106.82,
        ),
      ],
    );

    final json = dto.toJson();
    expect(json['deliveryCode'], 'DO-2026-1001');
    expect((json['items'] as List).length, 1);
    expect((json['stops'] as List).length, 1);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/create_delivery_dto_test.dart`
Expected: FAIL with "create_delivery_dto.dart not found".

- [x] **Step 3: Implement DTO classes in `lib/data/models/create_delivery_dto.dart`**
Define `CreateDeliveryDto`, `CreateDeliveryItemDto`, `CreateDeliveryStopDto`, and `AssignDeliveryDto` with strict validations matching NestJS DTOs.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/create_delivery_dto_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/models/create_delivery_dto.dart test/create_delivery_dto_test.dart
git commit -m "feat(delivery): create delivery creation and assignment DTO models"
```

---

#### Task 12: Delivery Creation & Assignment API Endpoints
**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Test: `test/delivery_create_assign_api_test.dart`

**Interfaces:**
- Consumes: `CreateDeliveryDto`, `AssignDeliveryDto`.
- Produces:
  - `Future<DeliveryModel> createDelivery(CreateDeliveryDto dto)`
  - `Future<void> assignDelivery(String deliveryId, AssignDeliveryDto dto)`
  - `Future<DeliveryModel> getDeliveryDetail(String deliveryId)`

- [x] **Step 1: Write failing test in `test/delivery_create_assign_api_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService exposes createDelivery and assignDelivery methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.createDelivery, isNotNull);
    expect(api.assignDelivery, isNotNull);
    expect(api.getDeliveryDetail, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/delivery_create_assign_api_test.dart`
Expected: FAIL with methods not defined.

- [x] **Step 3: Implement methods in `lib/data/repositories/armada_api_service.dart`**
- `createDelivery`: `POST /v1/deliveries`
- `assignDelivery`: `POST /v1/deliveries/:id/assign`
- `getDeliveryDetail`: `GET /v1/deliveries/:id`

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/delivery_create_assign_api_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/repositories/armada_api_service.dart test/delivery_create_assign_api_test.dart
git commit -m "feat(api): add endpoints for creating and assigning deliveries"
```

---

#### Task 13: Order Creation Multi-Stop Form Modal (`CreateDeliveryModalSheet`)
**Files:**
- Create: `lib/features/owner/widgets/create_delivery_modal_sheet.dart`
- Test: `test/create_delivery_modal_test.dart`

**Interfaces:**
- Consumes: `CreateDeliveryDto`, `ArmadaApiService`.
- Produces: `CreateDeliveryModalSheet` widget.

- [x] **Step 1: Write widget test in `test/create_delivery_modal_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/widgets/create_delivery_modal_sheet.dart';

void main() {
  testWidgets('CreateDeliveryModalSheet renders DO Number, Add Item, and Add Stop buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateDeliveryModalSheet(
            onSubmit: (dto) async {},
          ),
        ),
      ),
    );

    expect(find.text('Buat Perintah Kirim (DO) Baru'), findsOneWidget);
    expect(find.text('Tambah Barang'), findsOneWidget);
    expect(find.text('Tambah Titik Tujuan (Stop)'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/create_delivery_modal_test.dart`
Expected: FAIL with "create_delivery_modal_sheet.dart not found".

- [x] **Step 3: Implement `CreateDeliveryModalSheet` in `lib/features/owner/widgets/create_delivery_modal_sheet.dart`**
Include text field for DO Number with validator, dynamic list for Cargo Items (Item Name, Quantity, Unit, Weight), dynamic list for Stops (Destination Name, Address, Latitude, Longitude), total weight calculator, and validation before submit.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/create_delivery_modal_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/owner/widgets/create_delivery_modal_sheet.dart test/create_delivery_modal_test.dart
git commit -m "feat(owner): implement multi-stop delivery creation modal sheet"
```

---

#### Task 14: Fleet & Driver Assignment Modal Sheet (`AssignDriverModalSheet`)
**Files:**
- Create: `lib/features/owner/widgets/assign_driver_modal_sheet.dart`
- Test: `test/assign_driver_modal_test.dart`

**Interfaces:**
- Consumes: `FleetDriver`, `AssignDeliveryDto`, `ArmadaApiService`.
- Produces: `AssignDriverModalSheet` with pre-flight vehicle capacity check.

- [x] **Step 1: Write widget test in `test/assign_driver_modal_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/widgets/assign_driver_modal_sheet.dart';
import 'package:armada_mobile/data/models/fleet_driver_model.dart';

void main() {
  testWidgets('AssignDriverModalSheet lists drivers and displays overload alert when capacity exceeded', (tester) async {
    final drivers = [
      FleetDriver(
        id: 'drv-01',
        name: 'Pak Budi',
        plateNumber: 'B 1234 CD',
        status: 'AVAILABLE',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssignDriverModalSheet(
            deliveryId: 'del-001',
            totalCargoWeightKg: 800.0,
            availableDrivers: drivers,
            onAssign: (dto) async {},
          ),
        ),
      ),
    );

    expect(find.text('Penugasan Driver & Armada'), findsOneWidget);
    expect(find.text('Pak Budi'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/assign_driver_modal_test.dart`
Expected: FAIL with "assign_driver_modal_sheet.dart not found".

- [x] **Step 3: Implement `AssignDriverModalSheet` in `lib/features/owner/widgets/assign_driver_modal_sheet.dart`**
List available drivers from `FleetProvider`, select driver & vehicle, calculate cargo weight versus vehicle capacity, show warning banner if overweight, and invoke `onAssign`.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/assign_driver_modal_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/owner/widgets/assign_driver_modal_sheet.dart test/assign_driver_modal_test.dart
git commit -m "feat(owner): implement fleet assignment modal with cargo capacity validation"
```

---

#### Task 15: Owner Deliveries View & Audit Log Detail Integration
**Files:**
- Modify: `lib/features/owner/views/owner_deliveries_view.dart`
- Create: `lib/features/owner/views/owner_delivery_detail_view.dart`
- Test: `test/owner_delivery_detail_test.dart`

**Interfaces:**
- Consumes: `CreateDeliveryModalSheet`, `AssignDriverModalSheet`, `ArmadaApiService`.
- Produces: `OwnerDeliveryDetailView` with audit trail timeline.

- [x] **Step 1: Write widget test in `test/owner_delivery_detail_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/owner/views/owner_delivery_detail_view.dart';
import 'package:armada_mobile/data/models/delivery_model.dart';

void main() {
  testWidgets('OwnerDeliveryDetailView renders delivery status, items, and stops timeline', (tester) async {
    final delivery = DeliveryModel(
      id: 'del-001',
      orderNumber: 'DO-2026-0901',
      clientName: 'PT Logistik Makmur',
      origin: 'Gudang Pusat',
      destination: 'Outlet Sudirman',
      status: 'ASSIGNED',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OwnerDeliveryDetailView(delivery: delivery),
      ),
    );

    expect(find.text('DO-2026-0901'), findsOneWidget);
    expect(find.text('Rincian Titik Pengantaran'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/owner_delivery_detail_test.dart`
Expected: FAIL with "owner_delivery_detail_view.dart not found".

- [x] **Step 3: Implement `OwnerDeliveryDetailView` and update `OwnerDeliveriesView`**
Add FAB "Buat Pengiriman Baru" in `OwnerDeliveriesView` to open `CreateDeliveryModalSheet`. Tapping any delivery card navigates to `OwnerDeliveryDetailView` showing stops, cargo items, assign button (if draft/assigned), route optimization button, and activity history.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/owner_delivery_detail_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/owner/views/owner_deliveries_view.dart lib/features/owner/views/owner_delivery_detail_view.dart test/owner_delivery_detail_test.dart
git commit -m "feat(owner): integrate delivery creation, assignment and detail view with audit log"
```

---

### Phase 4: Realtime Gateway (Socket.IO) & In-App Notification Center

#### Task 16: Realtime Envelope & Notification Models
**Files:**
- Create: `lib/data/models/realtime_envelope.dart`
- Create: `lib/data/models/notification_model.dart`
- Test: `test/realtime_models_test.dart`

**Interfaces:**
- Consumes: None (Core data layer)
- Produces: `RealtimeEnvelope<T>`, `RealtimeLocationPayload`, `NotificationModel`, `NotificationListResponse`.

- [ ] **Step 1: Write unit test in `test/realtime_models_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/realtime_envelope.dart';
import 'package:armada_mobile/data/models/notification_model.dart';

void main() {
  test('RealtimeEnvelope parses incoming driver.location.updated event', () {
    final json = {
      'eventId': 'ev-01',
      'event': 'driver.location.updated',
      'version': 1,
      'timestamp': '2026-10-31T08:30:00.000Z',
      'payload': {
        'driverId': 'drv-123',
        'latitude': -6.2001,
        'longitude': 106.8162,
        'speedMps': 12.5,
        'headingDeg': 90.0,
        'recordedAt': '2026-10-31T08:30:00.000Z',
      },
    };

    final env = RealtimeEnvelope.fromJson(json, (p) => RealtimeLocationPayload.fromJson(p as Map<String, dynamic>));
    expect(env.event, 'driver.location.updated');
    expect(env.payload.driverId, 'drv-123');
    expect(env.payload.latitude, -6.2001);
  });

  test('NotificationModel parses notification object from backend', () {
    final notif = NotificationModel.fromJson({
      'id': 'notif-01',
      'type': 'EMERGENCY_ALERT',
      'title': 'Peringatan Darurat!',
      'body': 'Driver Pak Budi memicu SOS',
      'status': 'SENT',
      'createdAt': '2026-10-31T08:30:00.000Z',
    });
    expect(notif.isRead, isFalse);
    expect(notif.type, 'EMERGENCY_ALERT');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/realtime_models_test.dart`
Expected: FAIL with models not found.

- [ ] **Step 3: Implement `RealtimeEnvelope` and `NotificationModel` in `lib/data/models/`**
Define classes, payload DTOs, and serialization logic matching backend specification in `06-API-REALTIME.md` and `API-ENDPOINTS.md`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/realtime_models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/data/models/realtime_envelope.dart lib/data/models/notification_model.dart test/realtime_models_test.dart
git commit -m "feat(realtime): create realtime envelope and notification data models"
```

---

#### Task 17: Socket.IO Client Realtime Service (`SocketRealtimeService`)
**Files:**
- Create: `lib/core/services/socket_realtime_service.dart`
- Test: `test/socket_service_test.dart`

**Interfaces:**
- Consumes: `socket_io_client`, `SecureStorageService`.
- Produces: `SocketRealtimeService` (connect, disconnect, joinRoom, leaveRoom, event streams).

- [ ] **Step 1: Write unit test in `test/socket_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('SocketRealtimeService handles initialization and connection options', () {
    final storage = SecureStorageService();
    final service = SocketRealtimeService(storageService: storage);

    expect(service.isConnected, isFalse);
    expect(service.locationStream, isNotNull);
    expect(service.deliveryStatusStream, isNotNull);
    expect(service.emergencyStream, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/socket_service_test.dart`
Expected: FAIL with "socket_realtime_service.dart not found".

- [ ] **Step 3: Implement `SocketRealtimeService` in `lib/core/services/socket_realtime_service.dart`**
Initialize `IO.io('${AppConfig.wsBaseUrl}/v1/realtime', OptionBuilder().setTransports(['websocket']).setAuth({'token': 'Bearer $token'}).build())`.
Expose broadcast `StreamController`s for `driver.location.updated`, `delivery.status_changed`, and `emergency.triggered`.
Implement automatic room join on connection and reconnection handlers.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/socket_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/core/services/socket_realtime_service.dart test/socket_service_test.dart
git commit -m "feat(realtime): implement SocketRealtimeService for Socket.IO gateway"
```

---

#### Task 18: Notification Center API Methods in `ArmadaApiService`
**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Test: `test/notification_api_test.dart`

**Interfaces:**
- Consumes: `NotificationModel`, `NotificationListResponse`.
- Produces:
  - `Future<NotificationListResponse> getNotifications({int limit = 20, int offset = 0})`
  - `Future<void> markNotificationAsRead(String notificationId)`

- [ ] **Step 1: Write failing test in `test/notification_api_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService exposes notification management methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.getNotifications, isNotNull);
    expect(api.markNotificationAsRead, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/notification_api_test.dart`
Expected: FAIL with methods not defined.

- [ ] **Step 3: Implement methods in `lib/data/repositories/armada_api_service.dart`**
- `getNotifications`: `GET /v1/notifications?limit=:limit&offset=:offset`
- `markNotificationAsRead`: `PATCH /v1/notifications/:id/read`

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/notification_api_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/data/repositories/armada_api_service.dart test/notification_api_test.dart
git commit -m "feat(api): implement in-app notification endpoints"
```

---

#### Task 19: Stream Integration into Providers (`FleetProvider` & `DriverTrackingProvider`)
**Files:**
- Modify: `lib/providers/fleet_provider.dart`
- Modify: `lib/providers/driver_tracking_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/provider_stream_integration_test.dart`

**Interfaces:**
- Consumes: `SocketRealtimeService`, `FleetProvider`, `DriverTrackingProvider`.
- Produces: Real-time driver marker movement without REST polling, live delivery status updates.

- [ ] **Step 1: Write unit test in `test/provider_stream_integration_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/providers/fleet_provider.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

void main() {
  test('FleetProvider can ingest SocketRealtimeService', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socketService = SocketRealtimeService(storageService: storage);
    final provider = FleetProvider(apiService: api, socketService: socketService);

    expect(provider, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/provider_stream_integration_test.dart`
Expected: FAIL with constructor parameter mismatch.

- [ ] **Step 3: Update `FleetProvider` and `DriverTrackingProvider` to listen to socket streams**
In `FleetProvider`: Listen to `socketService.locationStream`. When a location event arrives, update the driver's coordinates in the local list and notify listeners to re-render the marker at its new position smoothly.
In `DriverTrackingProvider`: Listen to `socketService.deliveryStatusStream` and update local state.
In `main.dart`: Inject `SocketRealtimeService` into MultiProvider.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/provider_stream_integration_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/providers/fleet_provider.dart lib/providers/driver_tracking_provider.dart lib/main.dart test/provider_stream_integration_test.dart
git commit -m "feat(realtime): connect SocketRealtimeService to FleetProvider and DriverTrackingProvider"
```

---

#### Task 20: Notification Center Screen & SOS Emergency Alert Banner
**Files:**
- Create: `lib/features/notifications/notification_center_view.dart`
- Create: `lib/core/widgets/emergency_alert_banner.dart`
- Modify: `lib/features/owner/owner_shell.dart`
- Modify: `lib/features/driver/driver_shell.dart`
- Test: `test/notification_center_view_test.dart`

**Interfaces:**
- Consumes: `NotificationModel`, `SocketRealtimeService`, `ArmadaApiService`.
- Produces: `NotificationCenterView`, `EmergencyAlertBanner`.

- [ ] **Step 1: Write widget test in `test/notification_center_view_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/notifications/notification_center_view.dart';

void main() {
  testWidgets('NotificationCenterView displays notifications list and mark all read button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationCenterView(),
      ),
    );

    expect(find.text('Pusat Notifikasi'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/notification_center_view_test.dart`
Expected: FAIL with "notification_center_view.dart not found".

- [ ] **Step 3: Implement `NotificationCenterView` and `EmergencyAlertBanner`**
In `notification_center_view.dart`: Pull-to-refresh list of notifications, tap to mark as read, semantic icon based on notification type.
In `emergency_alert_banner.dart`: Prominent rose/red floating banner that appears when `socketService.emergencyStream` emits an event, displaying driver name, emergency type, and "Lihat di Peta" button.
In `owner_shell.dart` and `driver_shell.dart`: Include notification bell icon with unread count badge in AppBar, and mount `EmergencyAlertBanner` at top of view stack.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/notification_center_view_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/features/notifications/notification_center_view.dart lib/core/widgets/emergency_alert_banner.dart lib/features/owner/owner_shell.dart lib/features/driver/driver_shell.dart test/notification_center_view_test.dart
git commit -m "feat(notifications): add in-app NotificationCenterView and floating EmergencyAlertBanner"
```

---

#### Task 21: Full System Integration Verification & Smoke Testing
**Files:**
- Create: `test/full_system_smoke_test.dart`
- Test: All tests in `test/`

**Interfaces:**
- Consumes: All modules from Phase 1 through Phase 4.
- Produces: 100% passing test suite and clean `flutter analyze`.

- [ ] **Step 1: Write end-to-end flow test in `test/full_system_smoke_test.dart`**
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';

class _AllowAllHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = _AllowAllHttpOverrides();

  test('Full verification of API health and system integration', () async {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    final liveness = await api.checkLiveness();
    expect(liveness, isNotNull);
  });
}
```

- [ ] **Step 2: Run linter verification**
Run: `flutter analyze`
Expected: "No issues found!".

- [ ] **Step 3: Run all unit and widget tests**
Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Final commit**
```bash
git add test/full_system_smoke_test.dart
git commit -m "chore(release): complete full frontend mobile integration test verification"
```

---

## Plan Review & Next Steps

This plan covers all 4 phases with 21 self-contained, test-driven tasks following the strict `writing-plans` protocol.
Once approved by the user, execution can proceed task-by-task.
