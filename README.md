# Armada Mobile (Owner & Driver)

Aplikasi mobile berbasis **Flutter** untuk **Armada Distribution System** (Manajemen Distribusi Barang berbasis Mobile dengan Pelacakan Lokasi Driver secara Realtime dan Optimasi Rute).

Repository: [https://github.com/tirangga30/armadamobile](https://github.com/tirangga30/armadamobile)  
Referensi Backend API: `https://armada-api.prizftm.my.id/v1`  
Referensi API Client: [https://github.com/tirangga30/armadaadmin](https://github.com/tirangga30/armadaadmin) (`app/Services/ArmadaApiClient.php`)

---

## 🚀 Fitur Utama

### 1. Sistem Otentikasi & Role-Based Routing
- Terhubung langsung ke endpoint live: `POST /v1/auth/login` & `GET /v1/users/me`.
- Penyimpanan token JWT (`accessToken`, `refreshToken`, data user, role, dan `driverId`) secara aman menggunakan **`FlutterSecureStorage`**.
- Interceptor otomatis via **Dio** yang menyertakan header `Authorization: Bearer <token>`, `X-Client-Platform: Flutter-Mobile`, dan penanganan error terstandarisasi.
- **Role Routing Otomatis** via `AuthGate`:
  - Akun **OWNER** diarahkan langsung ke **Owner Hub Shell**.
  - Akun **DRIVER** diarahkan langsung ke **Driver Operasional Shell**.

### 2. Owner Mobile Hub
- **Dashboard Operasional**: Metrik real-time total driver, driver online, armada tersedia, pengiriman aktif, dan sinyal darurat aktif.
- **Radar & Pelacakan Armada**: Visualisasi radar live, filter status operasional (`AVAILABLE`, `DELIVERING`, `OFFLINE`), serta detail telemetri GPS driver.
- **Manajemen Pengiriman (Deliveries)**: Pemantauan order distribusi (`DO-2026-0901`, dsb.), alur asal-tujuan, dan transisi status (`ASSIGNED`, `EN_ROUTE`, `DELIVERED`, `COMPLETED`).
- **Pusat Peringatan Darurat (SOS)**: Daftar sinyal darurat driver dari backend (`/v1/emergencies`) dengan opsi tindakan resolusi (`PATCH /v1/emergencies/:id/status` -> `RESOLVED`).
- **Profil Owner & Info API**: Informasi identitas, organisasi, dan kontrol logout sesi.

### 3. Driver Mobile
- **Tugas Pengiriman Lapangan**: Penerimaan order dengan tombol transisi state machine:
  - `ASSIGNED` ➔ `ACCEPTED` (Terima Tugas)
  - `ACCEPTED` ➔ `EN_ROUTE` (Mulai Perjalanan)
  - `EN_ROUTE` ➔ `ARRIVED` (Tiba di Lokasi)
  - `ARRIVED` ➔ `DELIVERED` (Serah Terima / POD)
- **Pelacak GPS Telemetri Nyata**:
  - Mengambil koordinat GPS fisik smartphone secara real-time via `geolocator`.
  - Mengirim payload telemetri periodik ke `POST /v1/me/location` dengan format:
    ```json
    {
      "idempotencyKey": "<uuid-v4>",
      "latitude": -6.2088,
      "longitude": 106.8456,
      "accuracyM": 5.0,
      "speedMps": 0.0,
      "headingDeg": 0.0,
      "recordedAt": "2026-09-30T16:23:30.821Z"
    }
    ```
  - Indikator status transmisi (Aktif / Jeda) dan tombol manual ping seketika.
- **Tombol SOS Darurat**:
  - Tombol aksi darurat dengan konfirmasi dan pilihan kategori (`ACCIDENT`, `VEHICLE_BREAKDOWN`, `MEDICAL`, `SECURITY`, `OTHER`).
  - Mengirim sinyal darurat beserta koordinat lokasi terkini ke `POST /v1/emergencies`.
- **Profil Driver**: Informasi kode pegawai (`EMP-DEFAULT-001`), UUID driver dari backend, status operasional, dan logout.

---

## 🔑 Akun Uji Coba Resmi (Testing Credentials)

| Role | Username | Password | Tampilan Utama |
|---|---|---|---|
| **OWNER** | `owner` | `OwnerPass123!` | Owner Hub (Dashboard, Radar Armada, Pengiriman, SOS) |
| **DRIVER** | `driver` | `DriverPass123!` | Driver Shell (Tugas Lapangan, GPS Tracker, SOS) |

> Halaman login dilengkapi tombol cepat (one-tap toggle) untuk memilih akun Owner atau Driver secara instan.

---

## 📁 Struktur Arsitektur Kode

```text
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart          # Base URL API, versi klien, konfigurasi timeout
│   │   └── theme.dart               # Palet warna modern, tema Google Fonts (Plus Jakarta Sans)
│   ├── network/
│   │   ├── api_exception.dart       # Wrapper error sesuai kontrak backend
│   │   └── dio_client.dart          # Klien Dio, JWT auth interceptor, unified logging
│   ├── services/
│   │   └── location_service.dart    # Handler GPS device & pembangun payload Section 27
│   └── storage/
│       └── secure_storage_service.dart # Platform secure storage untuk JWT & sesi user
├── data/
│   ├── models/
│   │   ├── user_model.dart          # UserModel, DriverProfile, AuthData
│   │   ├── fleet_driver_model.dart  # FleetDriver, DriverLocation
│   │   ├── emergency_model.dart     # EmergencyModel, EmergencyDriver
│   │   └── delivery_model.dart      # DeliveryModel, DeliveryStop
│   └── repositories/
│       └── armada_api_service.dart  # Integrasi lengkap endpoint REST backend
├── providers/
│   ├── auth_provider.dart           # State otentikasi, login, auto check session, logout
│   ├── fleet_provider.dart          # State armada, radar, list driver, metrik KPI, SOS
│   └── driver_tracking_provider.dart# Loop background GPS ping & pengiriman SOS
├── features/
│   ├── auth/
│   │   └── login_screen.dart        # Layar login modern dengan tombol cepat akun
│   ├── owner/
│   │   ├── owner_shell.dart         # Bottom nav bar Owner
│   │   └── views/
│   │       ├── owner_dashboard_view.dart
│   │       ├── owner_fleet_view.dart
│   │       ├── owner_deliveries_view.dart
│   │       ├── owner_emergency_view.dart
│   │       └── owner_profile_view.dart
│   └── driver/
│       ├── driver_shell.dart        # Bottom nav bar Driver
│       └── views/
│           ├── driver_home_view.dart
│           ├── driver_tracking_view.dart
│           ├── driver_sos_view.dart
│           └── driver_profile_view.dart
└── main.dart                        # Entry point, MultiProvider, AuthGate role router
```

---

## 🛠️ Instalasi & Menjalankan Project

### Prasyarat
- Flutter SDK (>= 3.40.0)
- Dart SDK (>= 3.10.0)
- Koneksi Internet untuk mengakses API backend

### Langkah-langkah
```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan test otomatis
flutter test

# 3. Jalankan aplikasi pada perangkat/emulator
flutter run
```

---

## 🧪 Hasil Pengujian (Automated Tests)
Semua unit test dan widget smoke test telah terverifikasi:
- `UserModel Unit Tests`: Memverifikasi parsing role Owner, Driver, dan mapping `driverId`.
- `LoginScreen Smoke Test`: Memverifikasi perenderan tampilan antarmuka login dan toggle akun.
