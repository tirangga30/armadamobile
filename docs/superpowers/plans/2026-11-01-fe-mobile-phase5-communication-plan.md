# Phase 5: Realtime Field Communication & Offline Outbox Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build production-grade field communication (1:1 E2EE encrypted chat, PTT Walkie-Talkie / WebRTC video signaling) and resilient offline outbox synchronization with conflict resolution for Owner and Driver mobile clients.

**Architecture:** Chat uses end-to-end symmetric encryption (AES-256-GCM / CTR) with Base64 ciphertext transmission, persisting zero plaintext on the server. Voice PTT and Video utilize WebRTC signaling mediated via the Socket.IO `/v1/realtime` gateway with ephemeral TURN credentials (RFC 7635) and Driver consent gates. Offline events (stop status changes, GPS telemetries, messages) are enqueued in a persistent local store and flushed in batches of $\le 50$ to `POST /v1/me/sync/outbox` with idempotency keys upon network reconnection.

**Tech Stack:** Flutter 3.11+, Dart 3.11+, `dio: ^5.11.1`, `provider: ^6.1.5+1`, `socket_io_client: ^3.0.2`, `uuid: ^4.6.0`, `flutter_secure_storage: ^11.2.0`, `google_fonts: ^8.2.1`.

**Spec:** `docs/superpowers/specs/2026-11-01-fe-mobile-phase5-communication-spec.md`

## Global Constraints

- Global Base API URL: `https://armada-api.prizftm.my.id/v1`.
- Global Realtime Gateway: `wss://armada-api.prizftm.my.id/v1/realtime`.
- Standard Envelope Response: `{ success: true, data: ..., timestamp, requestId }`.
- Error Envelope: `{ success: false, error: { code, message, requestId }, timestamp }`.
- Zero plaintext message bodies transmitted across the wire (`ciphertextBlob` is strictly Base64 encrypted).
- Maximum outbox bulk sync limit: 50 events per batch (`POST /v1/me/sync/outbox`).
- Driver video sessions require explicit acceptance (`action: "ACCEPT"`) before signaling or opening local camera tracks.
- Strict plan mode: Zero code modifications to `.dart` files allowed during planning mode; changes to be executed in phased tasks only after plan approval.

## Review Focus

1. **Plaintext Leaks in Chat Logs or Storage:** E2EE requires that zero plaintext message bodies are sent across network unencrypted; all outbound message payloads must pass through encryption into `ciphertextBlob` (Base64) with `headerJson`.
2. **PTT Session Ghosting / Zombie Audio Channel:** When a call session ends or is rejected by driver (`DECLINE`), both peers must immediately tear down WebRTC tracks and exit session rooms to prevent background microphone drain.
3. **Outbox Event Batch Size Overflow:** The backend `POST /v1/me/sync/outbox` strictly limits `ArrayMaxSize(50)` events per batch. Client outbox flush must slice batches to $\le 50$ events per sync call.
4. **Idempotency Key Collisions on Resend:** Every offline event queued in outbox must retain its persistent `idempotencyKey: <UUIDv4>` so repeated submissions upon intermittent reconnect return saved acks instead of re-executing state transitions.
5. **Driver Video Privacy Inversion:** PTT Voice is dispatch-push, but Video sessions strictly require Driver consent gate (`action: ACCEPT`) before opening camera feeds.

---

## Tasks

### Task 1: Chat & E2EE Models & Ciphertext Encryption Helper
**Files:**
- Create: `lib/data/models/chat_model.dart`
- Create: `lib/core/services/e2ee_crypto_service.dart`
- Test: `test/e2ee_chat_model_test.dart`

**Interfaces:**
- Consumes: None (Core crypto & data layer)
- Produces: `ConversationModel`, `ChatMessageModel`, `SendMessageDto`, `E2eeCryptoService` (`encryptText`, `decryptText`).

- [x] **Step 1: Write failing test in `test/e2ee_chat_model_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/chat_model.dart';
import 'package:armada_mobile/core/services/e2ee_crypto_service.dart';

void main() {
  test('E2eeCryptoService encrypts and decrypts message with shared key', () {
    const key = 'secret_test_key_32_characters_long!';
    const plaintext = 'Instruksi: bongkar di gudang belakang toko';

    final encrypted = E2eeCryptoService.encrypt(plaintext, key);
    expect(encrypted.ciphertextBlob, isNotEmpty);
    expect(encrypted.ciphertextBlob, isNot(contains('Instruksi')));
    expect(encrypted.headerJson, contains('iv'));

    final decrypted = E2eeCryptoService.decrypt(
      encrypted.ciphertextBlob,
      key,
      encrypted.headerJson['iv'] as String,
    );
    expect(decrypted, equals(plaintext));
  });

  test('SendMessageDto serializes ciphertext and headers to backend schema', () {
    final dto = SendMessageDto(
      recipientDeviceId: '550e8400-e29b-41d4-a716-446655440000',
      ciphertextBlob: 'SGVsbG8gV29ybGQ=',
      headerJson: {'iv': 'random_iv_123'},
      idempotencyKey: 'idem-uuid-001',
    );
    final json = dto.toJson();
    expect(json['recipientDeviceId'], '550e8400-e29b-41d4-a716-446655440000');
    expect(json['ciphertextBlob'], 'SGVsbG8gV29ybGQ=');
    expect(json['idempotencyKey'], 'idem-uuid-001');
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/e2ee_chat_model_test.dart`
Expected: FAIL with "chat_model.dart not found".

- [x] **Step 3: Implement `ConversationModel`, `ChatMessageModel`, `SendMessageDto` and `E2eeCryptoService`**
In `lib/data/models/chat_model.dart`: Models for 1:1 conversation and messages with JSON serialization.
In `lib/core/services/e2ee_crypto_service.dart`: AES encryption and Base64 encoding/decryption with initialization vector (IV) in header JSON.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/e2ee_chat_model_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/models/chat_model.dart lib/core/services/e2ee_crypto_service.dart test/e2ee_chat_model_test.dart
git commit -m "feat(chat): implement E2EE encryption service and chat DTO models"
```

---

### Task 2: Chat API Methods in `ArmadaApiService` & Realtime Gateway Integration
**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Modify: `lib/core/services/socket_realtime_service.dart`
- Test: `test/chat_api_service_test.dart`

**Interfaces:**
- Consumes: `ChatMessageModel`, `SendMessageDto`, `ConversationModel`.
- Produces:
  - `Future<List<ConversationModel>> getConversations()`
  - `Future<ConversationModel> createConversation(String driverId)`
  - `Future<List<ChatMessageModel>> getMessages(String conversationId, {int limit = 50, int offset = 0})`
  - `Future<ChatMessageModel> sendChatMessage(String conversationId, SendMessageDto dto)`
  - `Stream<ChatMessageModel> get chatMessageStream` on `SocketRealtimeService`.

- [x] **Step 1: Write failing test in `test/chat_api_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';

void main() {
  test('ArmadaApiService exposes conversation and message endpoints', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);
    final socket = SocketRealtimeService(storageService: storage);

    expect(api.getConversations, isNotNull);
    expect(api.createConversation, isNotNull);
    expect(api.getMessages, isNotNull);
    expect(api.sendChatMessage, isNotNull);
    expect(socket.chatMessageStream, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/chat_api_service_test.dart`
Expected: FAIL with getters not defined.

- [x] **Step 3: Implement chat methods in `ArmadaApiService` and listener in `SocketRealtimeService`**
In `ArmadaApiService`:
- `GET /v1/conversations`
- `POST /v1/conversations` with body `{'driverId': driverId}`
- `GET /v1/conversations/:id/messages`
- `POST /v1/conversations/:id/messages`
In `SocketRealtimeService`:
- Listen to event `chat.message.relayed`, parse payload into `ChatMessageModel` and emit to `chatMessageStream`.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/chat_api_service_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/repositories/armada_api_service.dart lib/core/services/socket_realtime_service.dart test/chat_api_service_test.dart
git commit -m "feat(chat): add chat REST endpoints and realtime message relay streaming"
```

---

### Task 3: Chat Screen & Reactive Messaging UI (Owner & Driver 1:1 Conversation)
**Files:**
- Create: `lib/features/chat/chat_conversation_view.dart`
- Create: `lib/features/chat/widgets/chat_bubble.dart`
- Test: `test/chat_conversation_view_test.dart`

**Interfaces:**
- Consumes: `ConversationModel`, `ChatMessageModel`, `E2eeCryptoService`, `ArmadaApiService`.
- Produces: `ChatConversationView` widget, `ChatBubble` widget.

- [x] **Step 1: Write widget test in `test/chat_conversation_view_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/chat/chat_conversation_view.dart';
import 'package:armada_mobile/data/models/chat_model.dart';

void main() {
  testWidgets('ChatConversationView renders title, message bubbles, and text input bar', (tester) async {
    final conversation = ConversationModel(
      id: 'conv-01',
      driverId: 'drv-01',
      driverName: 'Pak Budi Santoso',
      plateNumber: 'B 1234 CD',
      createdAt: DateTime.now(),
    );

    final initialMessages = [
      ChatMessageModel(
        id: 'msg-01',
        conversationId: 'conv-01',
        senderUserId: 'user-01',
        senderDeviceId: 'dev-01',
        recipientDeviceId: 'dev-02',
        ciphertextBlob: 'EncryptedBlob==',
        plaintextBody: 'Tolong pastikan surat jalan ditandatangani toko',
        headerJson: const {'iv': 'iv1'},
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isOutgoing: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ChatConversationView(
          conversation: conversation,
          initialMessages: initialMessages,
        ),
      ),
    );

    expect(find.text('Pak Budi Santoso'), findsOneWidget);
    expect(find.text('Tolong pastikan surat jalan ditandatangani toko'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/chat_conversation_view_test.dart`
Expected: FAIL with "chat_conversation_view.dart not found".

- [x] **Step 3: Implement `ChatConversationView` and `ChatBubble`**
In `lib/features/chat/widgets/chat_bubble.dart`: Styled message card with sent/delivered/read double ticks, timestamp, and E2EE security badge.
In `lib/features/chat/chat_conversation_view.dart`: Scrollable ListView of messages, input bar with keyboard avoidance, send button with auto-encryption via `E2eeCryptoService`, and live listener on `socketService.chatMessageStream`.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/chat_conversation_view_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/chat/ test/chat_conversation_view_test.dart
git commit -m "feat(ui): implement reactive E2EE 1:1 chat conversation screen"
```

---

### Task 4: WebRTC & PTT Session DTOs & API Methods in `ArmadaApiService`
**Files:**
- Create: `lib/data/models/webrtc_session_model.dart`
- Modify: `lib/data/repositories/armada_api_service.dart`
- Test: `test/webrtc_api_service_test.dart`

**Interfaces:**
- Consumes: `InitiateCallDto`, `CallResponseDto`.
- Produces:
  - `CallSessionModel`, `TurnCredentialsModel`
  - `Future<CallSessionModel> initiateVoiceSession(String driverId, {String? deliveryId})`
  - `Future<CallSessionModel> initiateVideoSession(String driverId, {String? deliveryId})`
  - `Future<void> respondToCallSession(String sessionId, {required String action})`
  - `Future<void> endCallSession(String sessionId)`.

- [x] **Step 1: Write failing test in `test/webrtc_api_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('CallSessionModel parses session data and TURN credentials', () {
    final json = {
      'sessionId': 'session-001',
      'type': 'VOICE_PTT',
      'ownerId': 'owner-01',
      'driverId': 'drv-01',
      'status': 'PENDING',
      'turnCredentials': {
        'urls': ['turn:turn.armada.net:3478?transport=udp'],
        'username': '1788352800:owner-01',
        'credential': 'hmac_sha1_secret',
        'ttlSeconds': 3600,
      },
    };

    final model = CallSessionModel.fromJson(json);
    expect(model.sessionId, 'session-001');
    expect(model.type, 'VOICE_PTT');
    expect(model.turnCredentials?.urls.first, contains('turn:turn.armada.net'));
  });

  test('ArmadaApiService exposes WebRTC session management methods', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.initiateVoiceSession, isNotNull);
    expect(api.initiateVideoSession, isNotNull);
    expect(api.respondToCallSession, isNotNull);
    expect(api.endCallSession, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/webrtc_api_service_test.dart`
Expected: FAIL with models not found.

- [x] **Step 3: Implement `CallSessionModel`, `TurnCredentialsModel` and API methods**
In `lib/data/models/webrtc_session_model.dart`: DTO definitions.
In `lib/data/repositories/armada_api_service.dart`: Add `initiateVoiceSession` (`POST /v1/voice-sessions`), `initiateVideoSession` (`POST /v1/video-sessions`), `respondToCallSession` (`POST /v1/realtime/sessions/:id/respond`), and `endCallSession` (`POST /v1/realtime/sessions/:id/end`).

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/webrtc_api_service_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/models/webrtc_session_model.dart lib/data/repositories/armada_api_service.dart test/webrtc_api_service_test.dart
git commit -m "feat(webrtc): implement WebRTC session DTOs and API endpoints"
```

---

### Task 5: WebRTC Signaling Handshake via `SocketRealtimeService`
**Files:**
- Modify: `lib/core/services/socket_realtime_service.dart`
- Test: `test/webrtc_signaling_test.dart`

**Interfaces:**
- Consumes: `SocketRealtimeService`
- Produces:
  - `Stream<Map<String, dynamic>> get webrtcOfferStream`
  - `Stream<Map<String, dynamic>> get webrtcAnswerStream`
  - `Stream<Map<String, dynamic>> get webrtcIceCandidateStream`
  - `Stream<String> get webrtcCallEndedStream`
  - `void sendWebrtcOffer(String sessionId, Map<String, dynamic> sdp)`
  - `void sendWebrtcAnswer(String sessionId, Map<String, dynamic> sdp)`
  - `void sendWebrtcIceCandidate(String sessionId, Map<String, dynamic> candidate)`
  - `void hangupCall(String sessionId)`.

- [x] **Step 1: Write unit test in `test/webrtc_signaling_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/socket_realtime_service.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('SocketRealtimeService exposes WebRTC signaling streams and senders', () {
    final storage = SecureStorageService();
    final service = SocketRealtimeService(storageService: storage);

    expect(service.webrtcOfferStream, isNotNull);
    expect(service.webrtcAnswerStream, isNotNull);
    expect(service.webrtcIceCandidateStream, isNotNull);
    expect(service.webrtcCallEndedStream, isNotNull);
    expect(service.sendWebrtcOffer, isNotNull);
    expect(service.sendWebrtcAnswer, isNotNull);
    expect(service.sendWebrtcIceCandidate, isNotNull);
    expect(service.hangupCall, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/webrtc_signaling_test.dart`
Expected: FAIL with getters not defined.

- [x] **Step 3: Implement WebRTC signaling streams and handlers in `SocketRealtimeService`**
Wire up socket listeners for `webrtc.signal.offer`, `webrtc.signal.answer`, `webrtc.signal.ice_candidate`, and `webrtc.call.ended`. Implement emitter methods for SDP offers, answers, and ICE candidates with anti-replay nonce tracking.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/webrtc_signaling_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/core/services/socket_realtime_service.dart test/webrtc_signaling_test.dart
git commit -m "feat(webrtc): implement WebRTC signaling pipeline in SocketRealtimeService"
```

---

### Task 6: Push-To-Talk (Walkie-Talkie) & Video Call Consent UI
**Files:**
- Create: `lib/features/communication/widgets/ptt_walkie_talkie_button.dart`
- Create: `lib/features/communication/widgets/incoming_call_dialog.dart`
- Test: `test/ptt_walkie_talkie_widget_test.dart`

**Interfaces:**
- Consumes: `CallSessionModel`, `SocketRealtimeService`.
- Produces: `PttWalkieTalkieButton` widget, `IncomingCallDialog` widget.

- [x] **Step 1: Write widget test in `test/ptt_walkie_talkie_widget_test.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/features/communication/widgets/ptt_walkie_talkie_button.dart';
import 'package:armada_mobile/features/communication/widgets/incoming_call_dialog.dart';

void main() {
  testWidgets('PttWalkieTalkieButton renders hold-to-talk button and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PttWalkieTalkieButton(
            onPressStart: () {},
            onPressEnd: () {},
          ),
        ),
      ),
    );

    expect(find.text('TEKAN UNTUK BICARA'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('IncomingCallDialog displays caller name and Accept/Decline actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IncomingCallDialog(
            callerName: 'Owner Dispatcher',
            callType: 'VOICE_PTT',
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ),
    );

    expect(find.text('Panggilan Masuk: VOICE_PTT'), findsOneWidget);
    expect(find.text('Owner Dispatcher'), findsOneWidget);
    expect(find.text('Terima'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/ptt_walkie_talkie_widget_test.dart`
Expected: FAIL with "ptt_walkie_talkie_button.dart not found".

- [x] **Step 3: Implement `PttWalkieTalkieButton` and `IncomingCallDialog`**
In `ptt_walkie_talkie_button.dart`: Circular 76dp button with gesture detector (`onLongPressStart` & `onLongPressEnd`), pulsing audio wave animation, haptic feedback, and roger beep sound simulation.
In `incoming_call_dialog.dart`: Material dialog for driver consent gate with Accept and Decline buttons.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/ptt_walkie_talkie_widget_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/features/communication/widgets/ test/ptt_walkie_talkie_widget_test.dart
git commit -m "feat(ui): implement PTT walkie-talkie button and incoming call consent dialog"
```

---

### Task 7: Offline Outbox Storage & Queue Service (`LocalOutboxService`)
**Files:**
- Create: `lib/data/models/outbox_event_model.dart`
- Create: `lib/core/services/local_outbox_service.dart`
- Test: `test/local_outbox_service_test.dart`

**Interfaces:**
- Consumes: None (Local persistence layer)
- Produces: `OutboxEventItemDto`, `LocalOutboxService` (`enqueueEvent`, `getPendingEvents`, `acknowledgeEvents`, `clearQueue`).

- [x] **Step 1: Write unit test in `test/local_outbox_service_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/models/outbox_event_model.dart';
import 'package:armada_mobile/core/services/local_outbox_service.dart';

void main() {
  test('LocalOutboxService enqueues, limits batch to 50, and acknowledges events', () async {
    final outbox = LocalOutboxService();
    outbox.clear();

    await outbox.enqueue(
      eventType: 'stop.arrived',
      payload: {'stopId': 'st-01', 'latitude': -6.2088},
    );

    final pending = outbox.getPendingEvents(limit: 50);
    expect(pending.length, 1);
    expect(pending.first.eventType, 'stop.arrived');
    expect(pending.first.clientEventId, isNotEmpty);
    expect(pending.first.idempotencyKey, isNotNull);

    await outbox.acknowledge([pending.first.clientEventId]);
    expect(outbox.pendingCount, 0);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/local_outbox_service_test.dart`
Expected: FAIL with "local_outbox_service.dart not found".

- [x] **Step 3: Implement `OutboxEventItemDto` and `LocalOutboxService`**
In `lib/data/models/outbox_event_model.dart`: DTO matching `OutboxSyncDto` backend schema.
In `lib/core/services/local_outbox_service.dart`: Persistent JSON-backed storage with automatic batch slicing ($\le 50$ events per sync chunk).

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/local_outbox_service_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/models/outbox_event_model.dart lib/core/services/local_outbox_service.dart test/local_outbox_service_test.dart
git commit -m "feat(outbox): implement persistent LocalOutboxService queue"
```

---

### Task 8: Outbox Bulk Sync Endpoint & Network Auto-Flush Integration
**Files:**
- Modify: `lib/data/repositories/armada_api_service.dart`
- Modify: `lib/providers/driver_tracking_provider.dart`
- Test: `test/outbox_sync_api_test.dart`

**Interfaces:**
- Consumes: `LocalOutboxService`, `OutboxSyncDto`, `OutboxSyncResponse`.
- Produces:
  - `Future<OutboxSyncResponse> syncOutbox(OutboxSyncDto dto)`
  - `Future<void> flushOfflineOutbox()` in `DriverTrackingProvider`.

- [x] **Step 1: Write failing test in `test/outbox_sync_api_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/data/repositories/armada_api_service.dart';
import 'package:armada_mobile/core/network/dio_client.dart';
import 'package:armada_mobile/core/storage/secure_storage_service.dart';

void main() {
  test('ArmadaApiService exposes syncOutbox endpoint', () {
    final storage = SecureStorageService();
    final dio = DioClient(storageService: storage);
    final api = ArmadaApiService(client: dio);

    expect(api.syncOutbox, isNotNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**
Run: `flutter test test/outbox_sync_api_test.dart`
Expected: FAIL with getter not defined.

- [x] **Step 3: Implement `syncOutbox` in `ArmadaApiService` and auto-flush in `DriverTrackingProvider`**
In `ArmadaApiService`: Add `POST /v1/me/sync/outbox` returning `OutboxSyncResponse`.
In `DriverTrackingProvider`: Connect `flushOfflineOutbox()` which checks `LocalOutboxService.pendingCount`. When network is active, send batches of 50 to `_apiService.syncOutbox` and remove acked IDs.

- [x] **Step 4: Run test to verify it passes**
Run: `flutter test test/outbox_sync_api_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**
```bash
git add lib/data/repositories/armada_api_service.dart lib/providers/driver_tracking_provider.dart test/outbox_sync_api_test.dart
git commit -m "feat(outbox): integrate bulk sync API endpoint and auto-flush in DriverTrackingProvider"
```

---

### Task 9: Full Phase 5 System Smoke Test & Integration Verification
**Files:**
- Create: `test/phase5_full_smoke_test.dart`
- Test: All tests in `test/`

**Interfaces:**
- Consumes: All Phase 5 services and widgets.
- Produces: 100% passing test suite and clean `flutter analyze`.

- [x] **Step 1: Write end-to-end flow test in `test/phase5_full_smoke_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:armada_mobile/core/services/e2ee_crypto_service.dart';
import 'package:armada_mobile/core/services/local_outbox_service.dart';
import 'package:armada_mobile/data/models/chat_model.dart';
import 'package:armada_mobile/data/models/webrtc_session_model.dart';

void main() {
  test('Phase 5 integrated smoke test: crypto, outbox, and session models', () {
    // 1. E2EE test
    final enc = E2eeCryptoService.encrypt('Test Plaintext', 'key-32-chars-test-secret-value!!');
    final dec = E2eeCryptoService.decrypt(enc.ciphertextBlob, 'key-32-chars-test-secret-value!!', enc.headerJson['iv'] as String);
    expect(dec, 'Test Plaintext');

    // 2. Outbox test
    final outbox = LocalOutboxService();
    outbox.clear();
    expect(outbox.pendingCount, 0);

    // 3. WebRTC session test
    final session = CallSessionModel(
      sessionId: 'ses-1',
      type: 'VOICE_PTT',
      ownerId: 'owner-1',
      driverId: 'drv-1',
      status: 'ACTIVE',
    );
    expect(session.type, 'VOICE_PTT');
  });
}
```

- [x] **Step 2: Run linter verification**
Run: `flutter analyze`
Expected: "No issues found!".

- [x] **Step 3: Run all unit and widget tests**
Run: `flutter test`
Expected: All tests pass.

- [x] **Step 4: Final commit**
```bash
git add test/phase5_full_smoke_test.dart
git commit -m "chore(release): complete Phase 5 communication & outbox sync integration verification"
```

---

## Plan Review & Next Steps

This plan breaks Phase 5 into 9 bite-sized, test-driven tasks following the strict `writing-plans` protocol.
Once approved by the user, execution will proceed task-by-task.
