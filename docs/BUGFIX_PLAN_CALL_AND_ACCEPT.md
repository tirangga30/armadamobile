# Bugfix Plan — PTT/Video Call Tidak Masuk & Accept Terulang

Tanggal: 2026-11-17
Scope: `be-distribution-system-armada` (backend) + `armadamobile` (Flutter)
Metode eksekusi: OpenCode CLI, model `9router/ag/gemini-3.8-flash-high`

---

## BUG 1 — PTT Voice / Video Call dari Owner tidak pernah sampai ke Driver

### Gejala
Owner menekan **PTT Voice** atau **Video Call** → layar `CallSessionScreen` terbuka dan
berhenti di status "connecting". Driver tidak menerima dialog panggilan masuk sama sekali
(tidak ada notifikasi, tidak ada dering).

### Bukti
- `be-distribution-system-armada/src/modules/communication/services/call-session.service.ts:335`
  mengirim event ke room milik driver:
  ```ts
  this.realtimeGateway.server.to(`driver:${driverId}`).emit('webrtc.call.invite', envelope);
  ```
- `armadamobile/lib/features/driver/driver_shell.dart:58` berlangganan room yang sama:
  ```dart
  socketService.joinRoom('driver:$driverId');
  ```
- `be-distribution-system-armada/src/modules/realtime/services/ws-room-authorizer.service.ts`
  hanya mengenali kategori `delivery`, `conversation`, `session`, `fleet`.
  Tidak ada `case 'driver'` → permintaan `join_room` untuk `driver:<id>` ditolak dengan
  `reason: 'UNKNOWN_ROOM_PATTERN'`.
- Gateway memancarkan `room_error` ke klien (`realtime.gateway.ts:363`), tetapi
  `SocketRealtimeService` tidak punya handler `room_error`, sehingga kegagalan tidak terlihat.

**Akibat:** driver tidak pernah masuk room `driver:<driverId>`, sehingga emit
`webrtc.call.invite` tidak punya penerima. Sesi tetap `PENDING` lalu `EXPIRED` setelah 30 detik.

### Perbaikan
Backend — `ws-room-authorizer.service.ts`:
1. Tambah `case 'driver': return this.authorizeDriverRoom(socketData, resourceId, trimmedRoom);`
2. Implementasi `authorizeDriverRoom`:
   - `DRIVER` hanya boleh join `driver:<driverId miliknya sendiri>`
   - `ADMIN` / `SUPER_ADMIN` boleh join room driver mana pun (untuk audit)
   - `OWNER` **ditolak** (tidak butuh; owner sudah punya room `session:<id>`)
   - ID kosong → `MISSING_DRIVER_ID`
3. Log penolakan dengan `logger.warn` mengikuti pola Anti-IDOR yang sudah ada.

Frontend — `socket_realtime_service.dart`:
4. Tambah listener `room_error` → `debugPrint` + expose `roomErrorStream` agar kegagalan
   join terlihat saat verifikasi di emulator.

### Kriteria selesai
- Driver membuka app → log menunjukkan `room.joined` untuk `driver:<id>`.
- Owner menekan PTT → dalam < 2 detik driver menerima `IncomingCallDialog`.
- Driver menekan Accept → sesi berubah `PENDING → ACTIVE` di tabel `realtime_sessions`.

---

## BUG 2 — "Terima Tugas" terulang setiap refresh

### Gejala
Driver menekan **Terima Tugas (Accept)**. Status berubah di layar. Setelah pull-to-refresh,
tombol Accept muncul lagi seolah belum diterima.

### Bukti
- `armadamobile/lib/data/repositories/armada_api_service.dart:291`
  ```dart
  Future<void> updateDeliveryStatus(String id, String status) async {
    try {
      await _client.post('deliveries/$id/$status');   // → deliveries/<id>/ACCEPTED
    } catch (e) {
      debugPrint('Notice updating delivery status: $e');   // 404 ditelan diam-diam
    }
  }
  ```
- Route yang benar-benar ada di `deliveries.controller.ts`:
  ```
  POST /deliveries/:id/assign
  POST /deliveries/:id/accept
  POST /deliveries/:id/start
  POST /deliveries/:id/complete
  POST /deliveries/:id/cancel
  ```
  Tidak ada route generik `:id/:status`. Request `POST /deliveries/<id>/ACCEPTED`
  menghasilkan **404**, exception ditelan `catch`, state lokal tetap berubah secara optimistis,
  lalu `loadDriverDeliveries()` mengembalikan status `ASSIGNED` dari server.

### Perbaikan
Frontend — `armada_api_service.dart`:
1. Tambah pemetaan status → aksi:

   | Status aplikasi | Endpoint |
   |---|---|
   | `ACCEPTED` | `deliveries/<id>/accept` |
   | `EN_ROUTE` | `deliveries/<id>/start` |
   | `COMPLETED` / `DELIVERED` | `deliveries/<id>/complete` |
   | `CANCELLED` | `deliveries/<id>/cancel` |
   | lainnya | lempar `ArgumentError` (jangan diam-diam) |

2. `updateDeliveryStatus` mengembalikan `bool` (true bila server menerima), bukan menelan
   error. `DriverTrackingProvider.updateDeliveryState` memakai nilai balik itu untuk
   me-revert state lokal bila gagal, dan menampilkan pesan ke pengguna.

3. `arriveStop` / `departStop` sudah memakai route yang benar (`stops/:id/arrive`) —
   tidak diubah.

### Kriteria selesai
- Tekan Accept → `POST /v1/deliveries/<id>/accept` → **201**.
- Refresh → status tetap `ACCEPTED`, tombol berubah menjadi **Mulai Jalan**.
- Baris `deliveries.status` di PostgreSQL berubah permanen.

---

## BUG 3 — Peta menggambar ulang / rute berulang

### Gejala
Peta pada tab pelacakan driver menggambar ulang rute berkali-kali.

### Analisis sementara
`driver_tracking_view.dart:108` memanggil `_fetchRoadPolyline(activeDelivery.id)` dari dalam
`build()`. Guard `_loadedDeliveryId` mencegah fetch berulang **selama status delivery tidak
berubah**. Karena BUG 2 membuat status bolak-balik `ASSIGNED ↔ ACCEPTED` setiap refresh,
`activeDelivery` ikut berpindah antara DO-ROUTE-2OPT dan DO-LIVE-001, sehingga polyline
di-fetch ulang dan peta digambar ulang.

### Perbaikan
1. Pindahkan pemicu `_fetchRoadPolyline` dari `build()` ke `initState` +
   `didUpdateWidget`/listener provider, sehingga tidak ada I/O di jalur render.
2. Guard berdasarkan `deliveryId` saja (bukan status).

### Kriteria selesai
- Satu delivery = satu fetch rute.
- Tidak ada request `/routes/...` berulang di logcat saat layar diam.

---

## BUG 4 (bukan bug kode) — Driver punya 2 tugas

Query `deliveries` untuk `driver_id = 5a3d5134-04dd-4551-a4c7-0907e36e4084`:

| delivery_code | status | stops |
|---|---|---|
| DO-LIVE-001 | ASSIGNED | 1 |
| DO-ROUTE-2OPT | ASSIGNED | 3 |

Keduanya memang tersimpan sebagai dua delivery terpisah. Bukan duplikasi hasil query.
Perlu keputusan operator: pertahankan sebagai 2 penugasan, atau selesaikan/cancel salah
satunya sebagai data uji.

---

## Urutan Eksekusi

1. Backend: patch `ws-room-authorizer.service.ts` + rebuild + `pm2 reload armada-backend`.
2. Flutter: patch `socket_realtime_service.dart`, `armada_api_service.dart`,
   `driver_tracking_provider.dart`, `driver_tracking_view.dart`.
3. `flutter analyze` + `flutter test` (target: 0 issue, semua test lulus).
4. Verifikasi emulator `emulator-5554`:
   - Owner → Driver: PTT & Video (dialog masuk + sesi ACTIVE).
   - Driver accept → refresh → status tetap ACCEPTED.
   - Peta: satu polyline, tidak ada fetch berulang.
5. Commit terpisah per bug + push.

## Risiko
- Room `driver:<id>` baru bisa di-join oleh driver pemilik ID. Tidak ada perubahan hak
  akses untuk room lain.
- Pemetaan status di frontend harus mencakup semua tombol yang ada di `driver_home_view.dart`
  agar tidak ada tombol yang memanggil status tak dikenal.
