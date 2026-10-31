# Pelaksanaan Rencana Implementasi Frontend Mobile (Armada)
## Capstone Project: Sistem Manajemen Distribusi Armada
**Dokumen:** Spesifikasi Rencana Implementasi Bertahap (Frontend Mobile - Flutter)  
**Target Repositori:** `https://github.com/tirangga30/armadamobile`  
**Basis Acuan Backend:** `be-distribution-system-armada` (NestJS 10, OpenAPI 3.0, Socket.IO)  
**Status:** PROPOSAL PLAN (Awaiting Explicit User Approval)

---

## 1. Latar Belakang & Ruang Lingkup

Aplikasi mobile saat ini telah memiliki fondasi autentikasi JWT multi-role, pelacakan GPS driver lokal, radar armada interaktif berbasis OpenStreetMap (OSM), dan antarmuka pemicu darurat (SOS). Namun, untuk memenuhi seluruh kriteria operasional lapangan dan evaluasi Capstone, terdapat empat kapabilitas utama yang belum terhubung ke backend secara riil.

Rencana ini dibagi menjadi **4 Fase Bertahap (Incremental)** dengan prinsip *Strict Plan-First*, di mana setiap fase memiliki batasan pekerjaan, kontrak API yang jelas, dan kriteria verifikasi yang terukur.

---

## 2. Rincian 4 Fase Implementasi

### FASE 1: Operasional Lapangan Driver & Bukti Pengiriman Nyata (Proof of Delivery / POD)
**Fokus:** Mengubah alur pengiriman dari simulasi global menjadi eksekusi granular per-stop/toko serta bukti serah terima barang fisik nyata.

1. **Aksi Granular Tiap Stop (Per-Stop Delivery State Machine):**
   - Menghubungkan tombol aksi spesifik untuk setiap titik singgah toko (`DeliveryStop`):
     * `POST /v1/me/stops/:id/depart` — Driver mulai bergerak menuju toko tertentu.
     * `POST /v1/me/stops/:id/arrive` — Driver tiba di lokasi toko.
     * `POST /v1/me/stops/:id/unload` — Driver memulai proses bongkar muat barang.
     * `POST /v1/me/stops/:id/fail` — Pelaporan gagal kirim (toko tutup / penolakan) disertai pilihan alasan standar dan catatan.
2. **Pengambilan Bukti Foto & Tanda Tangan Digital:**
   - Menambahkan dependensi `image_picker` untuk foto fisik barang/surat jalan langsung dari kamera perangkat.
   - Menambahkan dependensi `signature` untuk kanvas tanda tangan penerima di layar HP driver.
   - Form input nama terang penerima dan nomor identitas/telepon.
3. **Integrasi Unggah Berkas & Submit POD ke Backend:**
   - Unggah foto dan tanda tangan via multipart form data ke `POST /v1/files/upload`.
   - Mengambil ID referensi berkas, lalu mengirimkan payload lengkap ke `POST /v1/me/stops/:id/pod`.
   - Header Idempotency: `Idempotency-Key: <UUIDv4>`.
4. **Kriteria Verifikasi Fase 1:**
   - Driver dapat menyelesaikan stop demi stop secara berurutan.
   - Foto dan tanda tangan berhasil terkirim ke penyimpanan backend dan tersimpan di database.
   - `flutter analyze` bersih (0 error / 0 warning).

---

### FASE 2: Visualisasi Rute Peta (Polyline) & Navigasi Eksternal
**Fokus:** Memandu driver di jalan raya dan memberikan visibilitas jalur tempuh kepada Owner.

1. **Polyline Rute di OpenStreetMap (`ArmadaOsmMap`):**
   - Mengambil data geometri rute aktual dari endpoint `GET /v1/deliveries/:id/routes/current`.
   - Merender garis rute perjalanan (`PolylineLayer`) di atas peta OSM menghubungkan Warehouse Hub $\rightarrow$ Stop 1 $\rightarrow$ Stop 2 $\rightarrow$ ... $\rightarrow$ Selesai.
2. **Navigasi Belokan Demi Belokan (Turn-by-Turn via Maps Eksternal):**
   - Menambahkan dependensi `url_launcher`.
   - Tombol *"Buka Navigasi"* pada kartu stop driver yang langsung membuka Google Maps / Waze / Apple Maps dengan koordinat toko tujuan (`geo:lat,lng` atau `https://www.google.com/maps/dir/?api=1&destination=lat,lng`).
3. **Mode Rute & Rekomendasi (Owner & Driver):**
   - Integrasi tombol evaluasi rute terbaik dari backend (algoritma 2-Opt TSP & OSRM) melalui `POST /v1/deliveries/:id/routes/recommend` dan `POST /v1/deliveries/:id/routes/select`.
4. **Kriteria Verifikasi Fase 2:**
   - Garis rute berwarna biru cerah muncul di atas peta OSM saat pengiriman dibuka.
   - Tombol navigasi berhasil memicu aplikasi Google Maps di perangkat mobile.

---

### FASE 3: Manajemen Pengiriman & Penugasan Armada (Owner Delivery Management)
**Fokus:** Memungkinkan Owner membuat instruksi kerja pengiriman baru dan menugaskan driver serta armada kendaraan secara dinamis.

1. **Form Pembuatan Order Pengiriman Baru (Create Delivery Modal):**
   - Input nomor DO / Surat Jalan.
   - Builder titik tujuan: Nama toko/outlet, alamat lengkap, titik koordinat, dan estimasi waktu.
   - Builder koli barang: Nama barang, jumlah unit, dan estimasi berat (kg).
2. **Modal Penugasan Driver & Kendaraan (Assign Delivery):**
   - Memilih driver dari daftar armada yang berstatus `AVAILABLE`.
   - Memilih armada mobil/truk yang cocok sesuai kapasitas berat muatan.
   - Mengirim mutasi penugasan ke `POST /v1/deliveries/:id/assign`.
3. **Manajemen Status & Riwayat Lengkap:**
   - Pemfilteran pengiriman aktif vs histori selesai/gagal.
   - Tampilan rincian informasi audit pengiriman (siapa yang menugaskan, kapan diterima, kapan selesai).
4. **Kriteria Verifikasi Fase 3:**
   - Owner dapat membuat order pengiriman baru dari nol di aplikasi mobile.
   - Order yang dibuat langsung muncul di daftar tugas pada aplikasi Driver Mobile terkait.

---

### FASE 4: Real-time Gateway (Socket.IO) & Pusat Notifikasi
**Fokus:** Menggantikan polling HTTP dengan komunikasi WebSocket real-time dan notifikasi in-app.

1. **Koneksi WebSocket / Socket.IO Lapangan:**
   - Menambahkan dependensi `socket_io_client`.
   - Menghubungkan client mobile ke endpoint WebSocket backend: `wss://<host>/v1/realtime` dengan autentikasi handshake token Bearer.
   - Streaming telemetri pergerakan marker driver secara mulus (*smooth marker animation*) tanpa request HTTP berulang.
2. **Layar Pusat Notifikasi (In-App Notification Center):**
   - Mengambil riwayat pemberitahuan via `GET /v1/notifications`.
   - Notifikasi penugasan baru untuk Driver, notifikasi peringatan darurat SOS untuk Owner, dan notifikasi barang selesai terkirim.
   - Fitur tanda telah dibaca (`PATCH /v1/notifications/:id/read`).
3. **Kriteria Verifikasi Fase 4:**
   - Perpindahan posisi driver di peta Owner terupdate secara seketika (*instant latency*) via WebSocket.
   - Pengujian terpadu seluruh alur dari Order dibuat $\rightarrow$ Driver jalan $\rightarrow$ Selesai POD $\rightarrow$ Owner menerima laporan.

---

## 3. Matriks Dependensi Tambahan (Pubspec)

| Package | Versi Rekomendasi | Kegunaan |
| :--- | :--- | :--- |
| `image_picker` | `^1.1.2` | Pengambilan foto bukti serah terima (POD) kamera fisik |
| `signature` | `^5.5.0` | Kanvas tanda tangan digital penerima barang |
| `url_launcher` | `^6.3.1` | Peluncur navigasi luar (Google Maps / Waze) |
| `socket_io_client` | `^3.0.2` | Komunikasi realtime WebSocket `/v1/realtime` |

---

## 4. Mekanisme Eksekusi dengan OpenCode

Sesuai aturan kerja *Strict Plan-First*:
1. Rencana dokumen ini disetujui terlebih dahulu oleh pengguna.
2. OpenCode di-spawn per fase secara modular di direktori `/home/priz/Documents/armadamobile`.
3. Setiap selesai 1 fase:
   - Dijalankan `flutter analyze` dan uji fungsional.
   - Dibuatkan laporan fase `.md`.
   - Berkas laporan dikirimkan via native Telegram attachment (`MEDIA:/home/priz/...`).
   - Menunggu persetujuan pengguna sebelum melangkah ke fase berikutnya.
