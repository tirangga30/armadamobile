# MASTER PROMPT --- ARMADA DISTRIBUTION SYSTEM

## Real Production-Oriented Frontend Implementation

### Laravel Admin Web + Flutter Owner Mobile + Flutter Driver Mobile

> **IMPORTANT:** Prompt ini ditujukan untuk AI coding agent yang akan
> **BENAR-BENAR MEMBANGUN PROJECT**, bukan membuat contoh, prototype,
> mockup, wireframe, static demo, atau pseudo-code.

------------------------------------------------------------------------

# 0. INSTRUKSI UTAMA

Saya ingin kamu membangun **Frontend nyata dan fungsional** untuk
project:

**Sistem Manajemen Distribusi Barang berbasis Mobile dengan Pelacakan
Lokasi Driver secara Realtime dan Optimasi Rute --- Armada Distribution
System.**

Saya adalah anggota tim **FE / UI/UX**.

## Scope pekerjaan saya

Saya hanya bertanggung jawab terhadap:

1.  **Admin Web** menggunakan **Laravel**
2.  **Owner Mobile** menggunakan **Flutter**
3.  **Driver Mobile** menggunakan **Flutter**

Backend **sudah tersedia** dan dikerjakan oleh anggota tim
Backend/Security.

### Repository harus dipisahkan

Buat/kerjakan dalam repository terpisah:

``` text
armada-web/
└── Laravel Admin Web

armada-mobile/
└── Flutter Owner + Driver Mobile
```

Jangan mencampurkan Laravel Web dan Flutter Mobile ke satu repository.

Jika repository GitHub belum tersedia, siapkan struktur project dan Git
repository yang sesuai di akun GitHub:

``` text
GitHub owner: tirangga30
```

Jika kamu tidak memiliki akses untuk membuat repository remote, tetap
buat project secara lengkap secara lokal dan siapkan agar dapat langsung
di-push ke repository terpisah.

------------------------------------------------------------------------

# 1. SUMBER SPESIFIKASI --- WAJIB DIJADIKAN ACUAN

Seluruh implementasi harus mengikuti dokumen project yang telah
diberikan:

``` text
Proposal Capstone Project
01-PRD.md
02-SRS.md
03-DFD.md
04-SYSTEM-ARCHITECTURE.md
05-DOMAIN-DATA-MODEL.md
06-API-REALTIME.md
07-SECURITY-RBAC.md
08-TESTING-DEPLOYMENT-ROADMAP.md
09-PROJECT-FLOW.md
10-TEAM-RESPONSIBILITY.md
```

Dokumen-dokumen tersebut adalah **source of truth desain dan requirement
project**.

Jangan mengganti requirement utama dengan asumsi sendiri.

Jika terdapat perbedaan antara dokumentasi dan backend API aktual:

1.  Periksa backend/API aktual terlebih dahulu.
2.  Gunakan kontrak backend aktual sebagai acuan integrasi.
3.  Adaptasikan frontend tanpa merusak kontrak backend.
4.  Jangan membuat backend palsu hanya agar frontend terlihat bekerja.
5.  Jika ada ketidaksesuaian penting, dokumentasikan secara jelas.
6.  Jangan mengarang endpoint, response, field, event, atau permission
    yang tidak ada.

------------------------------------------------------------------------

# 2. DEFINISI "SELESAI"

Project **tidak dianggap selesai** hanya karena:

-   halaman login tampil;
-   dashboard terlihat bagus;
-   tombol dapat diklik;
-   data dummy tampil;
-   mock JSON digunakan;
-   API integration hanya dibuat sebagian;
-   route navigation antar halaman sudah selesai;
-   prototype UI selesai.

Project dianggap selesai jika:

-   source code benar-benar dapat dijalankan;
-   Laravel Web benar-benar terhubung ke backend;
-   Flutter benar-benar terhubung ke backend;
-   authentication benar-benar bekerja;
-   role-based UI benar-benar mengikuti role dari backend;
-   data delivery benar-benar berasal dari API;
-   GPS benar-benar berasal dari perangkat Driver;
-   realtime benar-benar menggunakan mekanisme realtime yang tersedia;
-   POD benar-benar dapat dikirim;
-   loading/error/empty/offline state ditangani;
-   permission device ditangani;
-   WebSocket/WebRTC client diimplementasikan sesuai kontrak;
-   tidak ada hardcoded mock data sebagai pengganti backend;
-   test/smoke test tersedia;
-   environment configuration benar;
-   project dapat dibuild.

**Jangan berhenti pada prototype.**

------------------------------------------------------------------------

# 3. BACKEND YANG SUDAH TERSEDIA

Backend utama:

``` text
https://github.com/friza13/be-distribution-system-armada.git
```

Backend menggunakan arsitektur NestJS/Node.js dengan PostgreSQL, Redis,
realtime gateway, object storage, maps/routing, dan service terkait.

Base URL production API:

``` text
https://armada-api.prizftm.my.id/v1
```

Health:

``` text
GET https://armada-api.prizftm.my.id/v1/health/liveness
GET https://armada-api.prizftm.my.id/v1/health/readiness
```

Readiness secara desain digunakan untuk memverifikasi:

``` text
database
redis
storage
memory
```

Sebelum implementasi frontend, lakukan pengecekan konektivitas API.

------------------------------------------------------------------------

# 4. AKUN TEST RESMI

Tersedia tiga akun permanen untuk pengujian.

## ADMIN

``` text
Role     : ADMIN
Username : admin
Password : AdminPass123!
```

Organisasi:

``` text
Armada Distribution Corp
```

## OWNER

``` text
Role     : OWNER
Username : owner
Password : OwnerPass123!
```

Organisasi:

``` text
Armada Distribution Corp
```

## DRIVER

``` text
Role     : DRIVER
Username : driver
Password : DriverPass123!
```

Driver sudah mempunyai profile dan `driverId`.

### Aturan keamanan

Credential di atas hanya digunakan sebagai:

``` text
development/testing credentials
```

Jangan:

-   hardcode password ke source production;
-   memasukkan password ke Git;
-   menaruh token JWT di repository;
-   memasukkan API secret ke Flutter;
-   memasukkan credential backend privileged ke Laravel client;
-   membuat bypass authentication.

Gunakan `.env` untuk konfigurasi environment.

------------------------------------------------------------------------

# 5. ARSITEKTUR FRONTEND

Arsitektur akhir:

``` text
                    ┌───────────────────────┐
                    │       BACKEND         │
                    │ NestJS REST API       │
                    │ WebSocket             │
                    │ WebRTC Signaling      │
                    └───────────┬───────────┘
                                │
               ┌────────────────┼────────────────┐
               │                │                │
               ▼                ▼                ▼
       ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
       │  Laravel Web │ │ Flutter      │ │ Flutter      │
       │  Admin       │ │ Owner        │ │ Driver       │
       │              │ │ Mobile       │ │ Mobile       │
       └──────────────┘ └──────────────┘ └──────────────┘
```

Admin Web:

``` text
Laravel
```

Owner Mobile:

``` text
Flutter
```

Driver Mobile:

``` text
Flutter
```

Backend:

``` text
NestJS / Node.js
```

Database/backend infrastructure:

``` text
PostgreSQL
PostGIS
Redis
Object Storage
WebSocket
WebRTC
```

------------------------------------------------------------------------

# 6. ADMIN WEB --- LARAVEL

Bangun Admin Web secara nyata menggunakan Laravel.

## Modul wajib

``` text
Authentication
Dashboard
User Management
Owner Management
Driver Management
Vehicle Management
System Configuration
Audit Log
Monitoring
Emergency
```

## Admin Dashboard

Dashboard minimal menampilkan data aktual dari backend:

-   jumlah Owner;
-   jumlah Driver;
-   jumlah kendaraan;
-   delivery aktif;
-   delivery selesai;
-   delivery gagal;
-   driver online;
-   driver sedang melakukan delivery;
-   emergency/SOS aktif;
-   aktivitas terbaru.

Jangan menggunakan angka dummy.

Jika endpoint statistik khusus tidak tersedia, gunakan endpoint resource
yang benar dan lakukan agregasi di frontend hanya jika masuk akal dan
tidak membebani backend.

------------------------------------------------------------------------

# 7. ADMIN USER MANAGEMENT

Admin harus dapat:

-   melihat daftar user;
-   search;
-   filter;
-   pagination;
-   melihat detail;
-   membuat Owner;
-   membuat Driver;
-   edit user;
-   disable user;
-   reactivate user;
-   melihat status account;
-   melihat role;
-   melihat informasi creator jika tersedia.

Status account:

``` text
PENDING_ACTIVATION
ACTIVE
SUSPENDED
DISABLED
```

UI harus membedakan status tersebut.

Admin dapat:

``` text
Admin → Owner
Admin → Driver
```

Owner tidak boleh membuat atau menaikkan user menjadi Admin.

UI harus menyembunyikan aksi yang tidak relevan, tetapi ingat:

> UI hiding bukan security boundary. Backend tetap menjadi authority.

------------------------------------------------------------------------

# 8. DRIVER MANAGEMENT --- ADMIN WEB

Buat halaman Driver Management.

Minimal:

-   list driver;
-   search;
-   filter status;
-   detail driver;
-   employee code;
-   nama;
-   phone;
-   operational status;
-   kendaraan aktif;
-   delivery aktif;
-   latest location jika API menyediakan;
-   account status.

Operational status:

``` text
OFFLINE
ONLINE
AVAILABLE
ASSIGNED
DRIVING
ARRIVED
DELIVERING
```

------------------------------------------------------------------------

# 9. OWNER MANAGEMENT --- ADMIN WEB

Admin dapat:

-   melihat Owner;
-   membuat Owner;
-   edit Owner;
-   disable/reactivate;
-   melihat status;
-   melihat organisasi/scope bila tersedia.

------------------------------------------------------------------------

# 10. VEHICLE MANAGEMENT --- ADMIN WEB

Fitur:

-   list kendaraan;
-   create;
-   edit;
-   status;
-   plate number;
-   vehicle type;
-   capacity;
-   notes;
-   assignment information.

Field domain yang relevan:

``` text
plate_number
vehicle_type
capacity_weight
capacity_volume
status
notes
```

------------------------------------------------------------------------

# 11. AUDIT LOG --- ADMIN WEB

Buat halaman audit log.

Tampilkan:

``` text
actor
action
entity
entity ID
timestamp
result
metadata jika tersedia
```

Event penting antara lain:

``` text
USER_CREATED
USER_UPDATED
USER_DISABLED
ROLE_CHANGED
PASSWORD_RESET_INITIATED
DELIVERY_CREATED
DELIVERY_UPDATED
DRIVER_ASSIGNED
ROUTE_SELECTED
ROUTE_CHANGED
POD_CREATED
POD_REPLACED
VOICE_SESSION_STARTED
VIDEO_REQUESTED
VIDEO_ACCEPTED
EMERGENCY_CREATED
EMERGENCY_RESOLVED
ADMIN_OVERRIDE
```

Audit log harus read-only dari frontend.

------------------------------------------------------------------------

# 12. SYSTEM CONFIGURATION

Buat UI untuk konfigurasi sistem hanya jika endpoint backend memang
tersedia.

Jangan membuat konfigurasi palsu yang hanya tersimpan di localStorage.

Jika backend belum menyediakan konfigurasi tertentu:

``` text
jangan pura-pura membuatnya persistent.
```

Tampilkan hanya konfigurasi yang benar-benar didukung backend.

------------------------------------------------------------------------

# 13. MONITORING ADMIN

Gunakan health endpoint yang tersedia:

``` text
/v1/health/liveness
/v1/health/readiness
```

Tampilkan status:

``` text
Backend
Database
Redis
Storage
Memory
```

Jangan membuat status service berdasarkan asumsi frontend.

------------------------------------------------------------------------

# 14. EMERGENCY ADMIN

Admin harus dapat melihat emergency/SOS aktif jika API mendukung.

Minimal informasi:

``` text
driver
vehicle
location
timestamp
status
```

Admin dapat melakukan action yang memang diizinkan backend.

------------------------------------------------------------------------

# 15. OWNER MOBILE --- FLUTTER

Owner Mobile adalah aplikasi operasional distribusi.

Modul:

``` text
Login
Dashboard
Fleet Map
Driver List
Driver Detail
Delivery Management
Delivery Detail
Route Management
Communication
Chat
Voice/PTT
Video Request
POD View
Reports
Notifications
Emergency
```

------------------------------------------------------------------------

# 16. OWNER DASHBOARD

Tampilkan data aktual:

-   delivery aktif;
-   delivery hari ini;
-   delivery selesai;
-   delivery gagal;
-   driver online;
-   driver sedang menjalankan delivery;
-   emergency aktif;
-   aktivitas terbaru.

Gunakan API backend.

------------------------------------------------------------------------

# 17. OWNER FLEET MAP

Ini adalah salah satu fitur utama.

Map harus dapat:

-   menampilkan driver aktif;
-   menampilkan marker driver;
-   menampilkan status driver;
-   menampilkan lokasi terbaru;
-   menerima update realtime;
-   membuka detail driver;
-   menampilkan delivery aktif;
-   menampilkan destination/stop jika tersedia.

Jangan polling API secara agresif jika backend sudah menyediakan
WebSocket.

------------------------------------------------------------------------

# 18. DRIVER DETAIL --- OWNER

Owner dapat melihat:

``` text
nama driver
status
kendaraan
delivery aktif
current destination
ETA
latest location
last update
accuracy
speed
heading
```

Jika data tertentu tidak tersedia dari backend, jangan membuat data
palsu.

------------------------------------------------------------------------

# 19. DELIVERY MANAGEMENT --- OWNER

Owner dapat:

-   list delivery;
-   search;
-   filter status;
-   create delivery;
-   edit delivery;
-   melihat detail;
-   menambahkan item;
-   menambahkan destination;
-   assign driver;
-   assign vehicle;
-   memilih route mode;
-   melihat route;
-   melihat status delivery;
-   memulai delivery jika permission tersedia;
-   complete/fail sesuai backend authorization.

Delivery dapat memiliki:

``` text
delivery
items
destinations/stops
driver
vehicle
route
status
events
```

------------------------------------------------------------------------

# 20. DELIVERY STATE MACHINE

Frontend harus mengikuti state machine backend.

Minimal:

``` text
ASSIGNED
    ↓
ACCEPTED
    ↓
EN_ROUTE
    ↓
ARRIVED
    ↓
UNLOADING
    ↓
DELIVERED
    ↓
COMPLETED
```

Failure path:

``` text
EN_ROUTE → FAILED
ARRIVED → FAILED
UNLOADING → FAILED
FAILED → RESCHEDULED
RESCHEDULED → ASSIGNED
```

Jangan mengizinkan UI melakukan transisi status sembarangan.

Frontend harus menampilkan action berdasarkan status aktual dan
permission.

Backend tetap menjadi authority.

------------------------------------------------------------------------

# 21. ROUTE MANAGEMENT --- OWNER

Tiga mode:

``` text
MANUAL
RECOMMENDED
AUTOMATIC
```

Manual:

``` text
Owner menentukan urutan stop.
```

Recommended:

``` text
Backend memberikan rekomendasi.
```

Automatic:

``` text
Backend menentukan sequence sesuai algoritma.
```

Owner dapat:

-   melihat stop;
-   melihat sequence;
-   memilih route;
-   meminta recommendation;
-   melihat distance;
-   melihat estimated duration;
-   melihat route version;
-   melihat route source;
-   memilih route sesuai permission.

Jangan memanggil routing API setiap GPS ping.

------------------------------------------------------------------------

# 22. DRIVER MOBILE --- FLUTTER

Driver Mobile adalah aplikasi operasional lapangan.

Modul:

``` text
Login / Activation
Home
Today's Delivery
Current Delivery
Delivery Detail
Stops
Route
Navigation
GPS Tracking
Delivery Status
Proof of Delivery
Chat
Voice Receiver
Video Receiver
SOS
Notifications
```

------------------------------------------------------------------------

# 23. DRIVER HOME

Tampilkan:

-   delivery aktif;
-   delivery berikutnya;
-   status driver;
-   route aktif;
-   tracking status;
-   notifikasi penting;
-   SOS/emergency state jika aktif.

------------------------------------------------------------------------

# 24. DRIVER DELIVERY

Driver hanya boleh melihat delivery yang memang diassign/authorized
untuk dirinya.

Jangan mengambil semua delivery lalu memfilter hanya di client sebagai
security mechanism.

Backend sudah harus membatasi data.

Frontend tetap harus menampilkan hanya data yang diberikan backend.

------------------------------------------------------------------------

# 25. DRIVER DELIVERY DETAIL

Tampilkan:

``` text
delivery code
status
items
quantity
destination
sequence
address
map
next stop
route
vehicle
```

------------------------------------------------------------------------

# 26. DRIVER ROUTE

Driver dapat:

-   melihat route;
-   melihat stop sequence;
-   memilih route jika permitted;
-   memilih manual order jika permitted;
-   menggunakan recommended route jika tersedia;
-   membuka external navigation.

Navigation MVP dapat menggunakan handoff ke aplikasi navigasi eksternal
jika backend/spec belum menyediakan embedded navigation.

------------------------------------------------------------------------

# 27. GPS TRACKING --- FITUR KRITIS

Driver Mobile harus benar-benar menggunakan GPS smartphone.

Alur:

``` text
Phone GPS
   ↓
Flutter Location Service
   ↓
Validation / filtering client
   ↓
POST /v1/me/location
   ↓
Backend
   ↓
Realtime event
   ↓
Owner Fleet Map
```

Payload sesuai contract:

``` json
{
  "idempotencyKey": "unique-value",
  "latitude": -6.20012,
  "longitude": 106.81620,
  "accuracyM": 8.4,
  "speedMps": 11.7,
  "headingDeg": 87.0,
  "recordedAt": "2026-08-26T07:32:21Z"
}
```

Field optional harus mengikuti kemampuan device dan API.

------------------------------------------------------------------------

# 28. BACKGROUND LOCATION

Driver tracking harus mempertimbangkan:

-   permission foreground;
-   permission background;
-   GPS disabled;
-   location permission denied;
-   approximate location;
-   weak GPS accuracy;
-   phone locked;
-   app background;
-   app restart;
-   low battery;
-   network lost;
-   network reconnect;
-   duplicate event;
-   stale location.

Jangan menggunakan timer sederhana yang mengabaikan lifecycle
Android/iOS.

Gunakan package Flutter yang sesuai dan production-capable setelah
memeriksa compatibility dengan versi Flutter/project.

Tracking harus adaptive:

``` text
distance threshold
+
minimum interval
+
motion state
```

Jangan mengirim GPS dengan frekuensi ekstrem yang menghabiskan baterai.

------------------------------------------------------------------------

# 29. TRACKING STATUS UI

Driver harus selalu mengetahui:

``` text
Tracking Active
Tracking Paused
Location Permission Required
GPS Disabled
Network Offline
Last Synced
```

Jika tracking aktif, tampilkan indikator yang jelas.

Jika permission dicabut, jangan diam-diam menganggap tracking tetap
berjalan.

------------------------------------------------------------------------

# 30. OFFLINE SUPPORT

Driver app harus menangani network loss.

Minimal:

``` text
Current delivery tetap dapat dilihat dari cache.
Critical status events dapat masuk queue.
POD metadata dapat diantrikan bila memungkinkan.
Location event dapat dikelola sesuai strategi backend.
Retry menggunakan backoff.
```

Setiap event retryable sebaiknya memiliki idempotency key.

Jangan membuat sinkronisasi palsu.

UI harus memberi indikator:

``` text
Online
Offline
Syncing
Pending
Failed
```

------------------------------------------------------------------------

# 31. PROOF OF DELIVERY --- DRIVER

Driver dapat membuat POD untuk stop.

Data:

``` text
photo
receiver name
signature
note
timestamp
destination
delivery
```

Foto harus benar-benar diambil/upload dari device.

Signature harus benar-benar dapat dibuat jika backend mendukung.

Flow:

``` text
Arrived
 ↓
Unloading
 ↓
POD
 ↓
Submit
 ↓
Backend
 ↓
Stop Completed
```

Jangan menyimpan binary media sebagai mock JSON.

Gunakan multipart/upload contract yang benar dari backend.

------------------------------------------------------------------------

# 32. POD --- OWNER

Owner dapat melihat POD jika permission tersedia.

Media tidak boleh dianggap public.

Jika backend memberikan signed URL:

``` text
gunakan signed URL.
```

Jangan expose object storage credential.

------------------------------------------------------------------------

# 33. CHAT

Owner ↔ Driver:

``` text
Owner → Driver
Driver → Owner
```

REST:

``` text
GET  /v1/conversations
GET  /v1/conversations/:id/messages
POST /v1/conversations/:id/messages
```

Realtime event:

``` text
message.created
```

UI harus menangani:

-   sending;
-   sent;
-   delivered;
-   read;
-   failed;
-   reconnect;
-   duplicate event;
-   pagination history.

Jangan hanya membuat UI chat lokal.

------------------------------------------------------------------------

# 34. PUSH-TO-TALK / VOICE

Owner dapat memulai voice/PTT jika authorized.

Driver:

``` text
receive
accept/participate
```

Gunakan:

``` text
POST /v1/voice-sessions
```

Kemudian realtime/media mechanism sesuai backend.

Jangan mengirim audio melalui REST biasa.

------------------------------------------------------------------------

# 35. VIDEO

Baseline:

``` text
Owner → Request Video
Driver → Accept / Decline
```

Driver tidak boleh mempunyai unrestricted driver-initiated video call
pada baseline.

Endpoint contract:

``` text
POST /v1/video-sessions
```

WebRTC harus digunakan untuk media.

Backend menangani:

``` text
authentication
authorization
session
signaling
audit metadata
```

Media tidak boleh dipaksakan melewati REST API.

Jika backend belum menyediakan media infrastructure yang benar-benar
dapat digunakan, implementasikan client sesuai contract yang tersedia
dan tandai dependency secara jelas --- jangan membuat video call palsu.

------------------------------------------------------------------------

# 36. SOS / EMERGENCY

Driver dapat menekan SOS.

Event minimal:

``` text
driver
vehicle
latest known location
timestamp
```

Owner dan Admin dapat menerima emergency event sesuai authorization.

Realtime event:

``` text
emergency.created
```

UI harus membuat SOS mudah ditemukan tetapi tetap mencegah accidental
activation dengan confirmation/hold action yang sesuai.

------------------------------------------------------------------------

# 37. NOTIFICATION

Owner:

-   driver assignment;
-   delivery event;
-   stop completed;
-   emergency;
-   operational changes.

Driver:

-   assignment;
-   route change;
-   chat;
-   operational notification;
-   emergency-related information.

Jika push provider/backend contract tersedia, gunakan push notification
aktual.

Jangan mengandalkan local notification sebagai pengganti backend event.

------------------------------------------------------------------------

# 38. AUTHENTICATION

API:

``` text
POST /v1/auth/login
POST /v1/auth/refresh
POST /v1/auth/logout
POST /v1/auth/activate
```

Frontend harus:

-   login;
-   menyimpan token dengan aman;
-   refresh token sesuai contract;
-   logout;
-   menangani 401;
-   menangani token expired;
-   redirect ke login bila session invalid;
-   tidak menyimpan password plaintext.

------------------------------------------------------------------------

# 39. TOKEN STORAGE

## Flutter

Gunakan secure platform storage.

Jangan:

``` text
SharedPreferences untuk token privileged
```

jika secure storage tersedia.

## Laravel Web

Gunakan session/cookie mechanism yang aman sesuai arsitektur
frontend/backend.

Jangan menyimpan token sensitif secara sembarangan di browser storage
jika tidak diperlukan.

------------------------------------------------------------------------

# 40. RBAC FRONTEND

Role:

``` text
ADMIN
OWNER
DRIVER
```

Frontend boleh menggunakan role untuk:

-   routing;
-   menu;
-   visibility;
-   UX;
-   permission-aware action.

Tetapi:

> Frontend bukan authority authorization.

Backend tetap menentukan:

``` text
Identity
+
Role
+
Permission
+
Resource ownership
+
Current operational state
```

Contoh:

``` text
Driver A meminta Delivery B

Authenticated? YES
Role DRIVER? YES
Assigned to A? NO

→ backend 403
```

Frontend harus menangani `403 Forbidden` dengan UX yang sesuai.

------------------------------------------------------------------------

# 41. ERROR HANDLING

Gunakan error contract backend:

``` json
{
  "error": {
    "code": "DELIVERY_NOT_ASSIGNABLE",
    "message": "Driver is not available for this delivery.",
    "requestId": "req_123"
  }
}
```

Jangan menampilkan:

``` text
SQL error
stack trace
database error
secret
JWT
internal exception
```

Jika request gagal, tampilkan pesan yang manusiawi.

Simpan `requestId` jika tersedia untuk debugging.

------------------------------------------------------------------------

# 42. API CLIENT ARCHITECTURE

Jangan menulis request HTTP secara acak di setiap screen.

Buat abstraction.

Contoh Flutter:

``` text
lib/
├── core/
│   ├── config/
│   ├── network/
│   ├── storage/
│   ├── errors/
│   ├── permissions/
│   └── realtime/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── deliveries/
│   ├── tracking/
│   ├── routes/
│   ├── communication/
│   ├── pod/
│   ├── notifications/
│   └── emergency/
└── shared/
```

Laravel:

``` text
app/
├── Http/
├── Services/
├── View/
└── ...
resources/
├── views/
├── js/
└── css/
```

Struktur aktual boleh menyesuaikan versi Laravel dan stack yang
digunakan, tetapi tetap modular.

------------------------------------------------------------------------

# 43. STATE MANAGEMENT FLUTTER

Gunakan state management yang konsisten.

Boleh menggunakan pilihan seperti:

``` text
Riverpod
Bloc/Cubit
Provider
```

Pilih satu dan gunakan secara konsisten.

Jangan mencampur banyak pola state management tanpa alasan.

Setiap feature harus menangani:

``` text
Initial
Loading
Success
Empty
Error
Offline
Refreshing
Submitting
```

------------------------------------------------------------------------

# 44. LARAVEL FRONTEND ARCHITECTURE

Laravel Web harus memiliki:

``` text
layouts
components
pages
services
API client
authentication/session handling
form validation
error handling
pagination
filters
```

Gunakan Laravel sesuai kemampuan versi project.

Jika menggunakan Blade + Alpine/Livewire/Inertia/JS layer, pilih
arsitektur yang konsisten dan cocok untuk Admin Web.

Jangan membangun Laravel sebagai website statis.

------------------------------------------------------------------------

# 45. UI/UX

Desain harus terlihat sebagai **produk operasional profesional**, bukan
template CRUD generik.

Prioritas:

## Admin

``` text
Information density
Data table
Filtering
Search
Status
Auditability
```

## Owner

``` text
Visibility
Map
Delivery
Fleet
Realtime
Communication
```

## Driver

``` text
Low cognitive load
Large actionable controls
Minimal steps
Clear status
Navigation
GPS
POD
Emergency
```

Khusus Driver:

> UI harus meminimalkan beban kognitif saat bekerja di lapangan.

------------------------------------------------------------------------

# 46. RESPONSIVE WEB

Admin Web harus responsive untuk:

``` text
desktop
tablet
```

Mobile browser bukan target utama Admin Web jika tidak diperlukan,
tetapi layout tidak boleh rusak pada viewport kecil.

------------------------------------------------------------------------

# 47. DESIGN SYSTEM

Buat design system konsisten:

``` text
Typography
Spacing
Colors
Buttons
Inputs
Cards
Tables
Badges
Dialogs
Bottom sheets
Navigation
Empty states
Error states
Loading states
Map controls
Status indicators
```

Jangan membuat style berbeda-beda per halaman.

------------------------------------------------------------------------

# 48. MAPS

Gunakan map provider yang memang didukung backend/project.

Dokumen project menyebut provider dapat berupa Google Maps atau provider
setara.

Jangan hardcode provider tanpa memeriksa requirement/backend.

Buat abstraction jika memungkinkan:

``` text
MapAdapter
RouteAdapter
```

Jangan melakukan route request pada setiap GPS update.

------------------------------------------------------------------------

# 49. DOMAIN DATA YANG HARUS DIPAHAMI FRONTEND

Entitas utama:

``` text
User
Role
Permission
Driver
Vehicle
Delivery
DeliveryItem
DeliveryStop
Route
RouteStop
LocationPoint
DeliveryEvent
ProofOfDelivery
File
Message
Conversation
RealtimeSession
Notification
AuditLog
```

Frontend harus membuat model/DTO yang sesuai response API aktual.

Jangan menganggap struktur database internal sama persis dengan JSON
API.

------------------------------------------------------------------------

# 50. DELIVERY DATA MODEL

Delivery minimal berhubungan dengan:

``` text
driver
vehicle
items
stops
route
status
events
```

Stop:

``` text
sequence
destinationName
address
latitude
longitude
geofenceRadius
status
arrivedAt
departedAt
completedAt
```

------------------------------------------------------------------------

# 51. REALTIME

Business realtime menggunakan WebSocket.

Event yang relevan:

``` text
driver.location.updated
fleet.driver.status_changed
delivery.assigned
delivery.status_changed
delivery.stop.arrived
delivery.stop.completed
delivery.route.updated
message.created
notification.created
emergency.created
voice.session.updated
video.session.updated
```

Frontend harus:

-   connect;
-   authenticate;
-   subscribe bila diperlukan;
-   receive;
-   update state;
-   reconnect;
-   handle duplicate;
-   handle disconnect;
-   handle unauthorized;
-   dispose connection saat tidak diperlukan.

Jangan membuat satu WebSocket connection baru setiap widget/screen.

------------------------------------------------------------------------

# 52. GPS REALTIME OWNER MAP

Owner flow:

``` text
Driver phone
    ↓
POST /v1/me/location
    ↓
Backend validation
    ↓
Persist latest/history
    ↓
WebSocket
    ↓
Owner
    ↓
Map marker update
```

Jangan melakukan:

``` text
GET location setiap 1 detik
```

jika WebSocket event tersedia.

------------------------------------------------------------------------

# 53. PAGINATION

Collection API harus mendukung pagination sesuai backend.

Implementasikan:

``` text
page
limit/perPage
next page
previous page
loading more
```

Jika API menggunakan cursor, ikuti cursor.

Jangan mengambil seluruh database dalam satu request.

------------------------------------------------------------------------

# 54. SEARCH & FILTER

Implementasikan search/filter pada resource yang relevan:

``` text
Users
Drivers
Vehicles
Deliveries
Audit Logs
Notifications
```

Utamakan server-side filter jika backend menyediakan query parameter.

------------------------------------------------------------------------

# 55. LOADING / ERROR / EMPTY STATE

Setiap halaman data wajib mempunyai:

### Loading

``` text
Skeleton / spinner yang sesuai konteks
```

### Empty

Contoh:

``` text
Belum ada delivery.
Belum ada driver.
Belum ada kendaraan.
```

### Error

Tampilkan pesan yang jelas + retry.

### Offline

Berikan informasi bahwa koneksi sedang tidak tersedia.

Jangan membiarkan halaman blank putih.

------------------------------------------------------------------------

# 56. FORM VALIDATION

Validasi frontend harus dilakukan untuk UX.

Tetapi jangan menganggap validasi frontend menggantikan backend
validation.

Contoh:

``` text
required
format
number
range
file type
file size
```

Backend tetap authority.

------------------------------------------------------------------------

# 57. MEDIA UPLOAD

Untuk POD:

-   validate MIME;
-   validate size;
-   compress image jika sesuai;
-   show upload progress;
-   handle failure;
-   retry;
-   avoid duplicate submission;
-   show success state.

Jangan menyimpan media besar sembarangan ke local storage permanen.

------------------------------------------------------------------------

# 58. DEVICE PERMISSIONS

Flutter harus menangani:

``` text
Location
Camera
Microphone
Notification
Photo/File
```

Permission denied harus menghasilkan UX yang jelas.

Jangan crash ketika permission ditolak.

------------------------------------------------------------------------

# 59. TESTING --- FRONTEND

Buat testing nyata.

## Flutter unit test

Minimal:

``` text
authentication state
permission state
delivery state transitions
route mode logic
GPS payload mapping
error parsing
idempotency generation
```

## Widget test

Minimal:

``` text
login
dashboard
delivery
POD
permission/error state
```

## Integration/E2E

Primary journey:

``` text
Admin creates Driver
        ↓
Driver activation/login
        ↓
Owner creates Delivery
        ↓
Owner assigns Driver
        ↓
Driver accepts
        ↓
Driver sends GPS
        ↓
Owner sees location
        ↓
Driver reaches stop
        ↓
POD submitted
        ↓
Delivery completed
```

------------------------------------------------------------------------

# 60. MOBILE FIELD TESTING

Wajib siapkan checklist untuk:

``` text
GPS permission denied
GPS disabled
weak accuracy
background location
phone locked
low battery
cellular data lost
reconnect
duplicate event
app restart
POD upload failure
```

------------------------------------------------------------------------

# 61. ADMIN WEB TESTING

Test:

``` text
login
logout
expired session
403
user CRUD
driver CRUD
vehicle CRUD
audit viewing
dashboard loading
pagination
filter
API error
empty data
network error
```

------------------------------------------------------------------------

# 62. SECURITY FRONTEND

Jangan pernah:

``` text
hardcode secret
hardcode privileged API key
store plaintext password
expose JWT in logs
log Authorization header
log refresh token
commit .env production
```

Gunakan:

``` text
.env
.env.example
secure storage
environment configuration
```

------------------------------------------------------------------------

# 63. ENVIRONMENT

Siapkan:

``` text
local
development
staging
production
```

Minimal variable yang diperlukan:

``` text
API_BASE_URL
WEBSOCKET_URL
MAPS_KEY
```

Tetapi gunakan hanya variable yang benar-benar diperlukan oleh
implementation.

Jangan commit secret.

`.env.example` boleh berisi placeholder:

``` text
API_BASE_URL=
WEBSOCKET_URL=
MAPS_KEY=
```

------------------------------------------------------------------------

# 64. API URL

Default development/testing:

``` text
API_BASE_URL=https://armada-api.prizftm.my.id/v1
```

Jangan menulis URL API di banyak file.

Gunakan satu configuration layer.

------------------------------------------------------------------------

# 65. REPOSITORY STRATEGY

Repository harus terpisah.

## Web

``` text
armada-web
```

Stack:

``` text
Laravel
```

## Mobile

``` text
armada-mobile
```

Stack:

``` text
Flutter
```

Dalam mobile, Owner dan Driver boleh berada dalam satu Flutter
repository dengan role-based application flow karena keduanya
menggunakan platform mobile yang sama.

Tidak perlu membuat dua repository Flutter terpisah kecuali requirement
tim berubah.

------------------------------------------------------------------------

# 66. GIT WORKFLOW

Gunakan:

``` text
main
develop
feature branches
```

Contoh:

``` text
main
develop

feature/fe-auth
feature/fe-admin-dashboard
feature/fe-user-management
feature/fe-delivery
feature/fe-owner-map
feature/fe-driver-gps
feature/fe-pod
feature/fe-chat
feature/fe-realtime
feature/fe-sos
```

Commit harus kecil dan bermakna.

Contoh:

``` text
chore: initialize Laravel admin web
feat(auth): implement backend login flow
feat(admin): implement user management
feat(owner): implement delivery management
feat(driver): implement active delivery
feat(tracking): implement background GPS
feat(owner): implement live fleet map
feat(pod): implement proof of delivery upload
feat(chat): implement owner-driver messaging
feat(realtime): implement websocket events
feat(emergency): implement SOS UI
test: add frontend smoke tests
chore: production hardening
```

------------------------------------------------------------------------

# 67. IMPLEMENTATION ORDER

Ikuti urutan ini agar project dapat diuji bertahap.

## Phase 0 --- Foundation

### Web

-   Laravel setup
-   environment
-   API client
-   authentication
-   layout
-   navigation
-   RBAC UI
-   error handling

### Mobile

-   Flutter setup
-   environment
-   network layer
-   secure storage
-   authentication
-   routing
-   role handling
-   common UI

------------------------------------------------------------------------

## Phase 1 --- Core Administration

### Admin Web

-   dashboard
-   users
-   owners
-   drivers
-   vehicles
-   audit

### Owner Mobile

-   dashboard
-   delivery
-   items
-   destinations
-   assignment

### Driver Mobile

-   home
-   today's delivery
-   delivery detail
-   accept delivery
-   status

------------------------------------------------------------------------

## Phase 2 --- Tracking

### Driver

-   location permission
-   GPS service
-   background tracking
-   location upload
-   tracking state

### Owner

-   fleet map
-   realtime location
-   driver detail
-   last update

------------------------------------------------------------------------

## Phase 3 --- Route

-   manual route
-   route selection
-   recommendation
-   route display
-   navigation handoff
-   route state

------------------------------------------------------------------------

## Phase 4 --- POD

-   photo
-   receiver
-   signature
-   note
-   upload
-   completion

------------------------------------------------------------------------

## Phase 5 --- Notifications

-   notification list
-   unread state
-   push integration
-   event handling

------------------------------------------------------------------------

## Phase 6 --- Communication

-   chat
-   realtime message
-   voice/PTT
-   video request
-   WebRTC client

------------------------------------------------------------------------

## Phase 7 --- Emergency

-   SOS
-   emergency list
-   realtime emergency
-   owner/admin notification
-   resolution UI

------------------------------------------------------------------------

## Phase 8 --- Hardening

-   offline
-   retry
-   idempotency
-   security
-   test
-   performance
-   accessibility
-   production build

------------------------------------------------------------------------

# 68. CRITICAL RULE --- NO FAKE BACKEND

Dilarang mengganti backend dengan:

``` text
mock API
local JSON
fake repository
hardcoded array
dummy GPS
fake WebSocket
simulated delivery
fake login
```

untuk menyatakan feature sudah selesai.

Mock boleh digunakan hanya untuk:

``` text
isolated unit test
temporary development scaffolding
```

dan harus mudah dihapus.

Feature production harus terhubung ke backend nyata.

------------------------------------------------------------------------

# 69. CRITICAL RULE --- JANGAN MEMBUAT FITUR BACKEND PALSU

Jika endpoint belum tersedia:

``` text
JANGAN membuat endpoint Laravel yang diam-diam menggantikan NestJS.
```

Laravel Web adalah frontend/client terhadap backend yang telah
disediakan.

Jika ada requirement yang belum didukung backend:

1.  identifikasi dependency;
2.  cek apakah endpoint lain mendukung;
3.  jangan bypass;
4.  dokumentasikan blocker;
5.  tetap implementasikan UI/contract layer jika masuk akal;
6.  jangan klaim feature production-ready jika backend belum
    mendukungnya.

------------------------------------------------------------------------

# 70. CRITICAL RULE --- BACKEND AUTHORITY

Frontend tidak boleh menentukan:

``` text
role
permission
ownership
delivery assignment
delivery state validity
location visibility
session authorization
```

Frontend hanya merepresentasikan state backend.

------------------------------------------------------------------------

# 71. CRITICAL RULE --- REALTIME

Realtime harus benar-benar realtime berdasarkan contract.

Jangan mensimulasikan:

``` text
setInterval(() => moveMarker(), ...)
```

untuk membuat seolah-olah driver bergerak.

Marker harus bergerak berdasarkan location event nyata.

------------------------------------------------------------------------

# 72. CRITICAL RULE --- GPS

Jangan menghasilkan koordinat random.

GPS harus:

``` text
device GPS → Flutter → backend
```

------------------------------------------------------------------------

# 73. CRITICAL RULE --- DATA

Jangan membuat:

``` text
"John Driver"
"Delivery #001"
"Jakarta"
```

sebagai data tetap hanya agar dashboard terlihat penuh.

Data harus berasal dari backend atau data yang dibuat melalui actual
workflow.

------------------------------------------------------------------------

# 74. CRITICAL RULE --- UI STATES

Semua screen harus memiliki:

``` text
loading
success
empty
error
offline
unauthorized
forbidden
```

sesuai relevansi.

------------------------------------------------------------------------

# 75. KETIDAKSESUAIAN API

Dokumen API adalah kontrak awal, bukan alasan untuk mengarang response.

Endpoint yang dirancang antara lain:

``` text
POST /v1/auth/login
POST /v1/auth/refresh
POST /v1/auth/logout
POST /v1/auth/activate

GET    /v1/users
POST   /v1/users
GET    /v1/users/:id
PATCH  /v1/users/:id
POST   /v1/users/:id/disable
POST   /v1/users/:id/reactivate

GET    /v1/drivers
GET    /v1/drivers/:id
POST   /v1/drivers
PATCH  /v1/drivers/:id

GET    /v1/vehicles
POST   /v1/vehicles
PATCH  /v1/vehicles/:id

GET    /v1/deliveries
POST   /v1/deliveries
GET    /v1/deliveries/:id
PATCH  /v1/deliveries/:id
POST   /v1/deliveries/:id/assign
POST   /v1/deliveries/:id/route/recommend
POST   /v1/deliveries/:id/route/select
POST   /v1/deliveries/:id/start
POST   /v1/deliveries/:id/complete
POST   /v1/deliveries/:id/fail

GET  /v1/me/deliveries
GET  /v1/me/deliveries/:id
POST /v1/me/deliveries/:id/accept
POST /v1/me/stops/:id/arrive
POST /v1/me/stops/:id/complete
POST /v1/me/stops/:id/pod
POST /v1/me/location

GET  /v1/conversations
GET  /v1/conversations/:id/messages
POST /v1/conversations/:id/messages
POST /v1/voice-sessions
POST /v1/video-sessions
POST /v1/realtime/sessions/:id/end
```

**Tetapi sebelum menggunakan endpoint tersebut, verifikasi endpoint
aktual backend.**

------------------------------------------------------------------------

# 76. API CONTRACT CHECKLIST

Sebelum membuat integration layer besar, periksa:

``` text
[ ] endpoint
[ ] HTTP method
[ ] authentication
[ ] request body
[ ] query parameter
[ ] path parameter
[ ] response shape
[ ] pagination
[ ] error format
[ ] HTTP status
[ ] role permission
[ ] realtime event
[ ] file upload contract
```

Buat satu dokumentasi internal frontend:

``` text
docs/frontend-api-contract.md
```

yang mencatat hasil verifikasi.

------------------------------------------------------------------------

# 77. REALTIME CONTRACT CHECKLIST

Catat:

``` text
WebSocket URL
authentication
connection lifecycle
event names
payload schema
subscription mechanism
reconnect strategy
error events
heartbeat/ping
```

Jangan mengarang event jika backend aktual menggunakan nama berbeda.

------------------------------------------------------------------------

# 78. DEFINITION OF DONE

Sebuah feature frontend hanya dianggap selesai jika:

``` text
[ ] requirement sudah dipetakan
[ ] UI selesai
[ ] API integration selesai
[ ] backend authorization dihormati
[ ] loading state tersedia
[ ] empty state tersedia
[ ] error state tersedia
[ ] offline state relevan tersedia
[ ] permission handling tersedia
[ ] validation tersedia
[ ] test tersedia
[ ] API error ditangani
[ ] tidak ada secret di source
[ ] tidak ada fake data sebagai pengganti API
[ ] manual acceptance berhasil
[ ] Git checkpoint dibuat
```

------------------------------------------------------------------------

# 79. ACCEPTANCE TEST UTAMA

Harus dapat melakukan perjalanan berikut menggunakan sistem nyata:

``` text
ADMIN LOGIN
    ↓
Admin melihat dashboard
    ↓
Admin melihat/mengelola Driver
    ↓
OWNER LOGIN
    ↓
Owner melihat dashboard
    ↓
Owner membuat Delivery
    ↓
Owner menambahkan Item
    ↓
Owner menambahkan Destination
    ↓
Owner memilih Driver
    ↓
Owner memilih Vehicle
    ↓
Driver LOGIN
    ↓
Driver melihat Delivery
    ↓
Driver Accept
    ↓
Driver memilih route
    ↓
Driver Start
    ↓
Driver memberikan GPS
    ↓
Backend menerima GPS
    ↓
Owner melihat Driver pada Map
    ↓
Driver Arrive
    ↓
Driver membuat POD
    ↓
Driver Complete
    ↓
Owner melihat delivery selesai
    ↓
Admin dapat melihat audit/activity jika tersedia
```

------------------------------------------------------------------------

# 80. QUALITY BAR

Jangan puas dengan:

``` text
"yang penting jalan"
```

Project harus:

-   maintainable;
-   modular;
-   readable;
-   typed bila stack mendukung;
-   memiliki error handling;
-   memiliki loading state;
-   memiliki validation;
-   memiliki test;
-   menggunakan API abstraction;
-   tidak mengulang code secara berlebihan;
-   tidak menyimpan secret;
-   tidak menggunakan mock sebagai production;
-   tidak memiliki dead code;
-   tidak memiliki TODO kritis yang ditinggalkan tanpa alasan.

------------------------------------------------------------------------

# 81. RESPONS TERHADAP BLOCKER

Jika menemukan blocker:

Jangan berhenti hanya dengan mengatakan:

``` text
"API belum ada."
```

Lakukan:

1.  cek repository/backend;
2.  cek API contract;
3.  cek endpoint terkait;
4.  cek response aktual;
5.  cek kemungkinan endpoint alternatif yang memang resmi;
6.  sesuaikan client;
7.  jika benar-benar tidak tersedia, dokumentasikan blocker dengan
    jelas.

Tetapi jangan mengubah backend dari scope FE.

------------------------------------------------------------------------

# 82. JIKA ADA REQUIREMENT YANG TIDAK TERSEDIA

Gunakan status:

``` text
IMPLEMENTED
INTEGRATED
BLOCKED BY BACKEND
BLOCKED BY INFRA
NEEDS VERIFICATION
```

Jangan menyatakan:

``` text
DONE
```

jika feature sebenarnya belum dapat bekerja end-to-end.

------------------------------------------------------------------------

# 83. OUTPUT YANG DIHARAPKAN DARI AI CODING AGENT

Setelah implementasi, berikan laporan:

## Repository

``` text
Web:
<repo/path>

Mobile:
<repo/path>
```

## Stack

``` text
Laravel version:
Flutter version:
Dart version:
Packages:
```

## Implemented

Daftar feature nyata yang sudah selesai.

## API integration

Daftar endpoint yang benar-benar digunakan.

## Realtime

Daftar event yang benar-benar digunakan.

## Testing

``` text
unit
widget
integration
manual smoke test
```

## Environment

Jelaskan `.env.example`.

## Build

Berikan command:

``` text
Laravel:
composer install
php artisan ...
```

dan:

``` text
Flutter:
flutter pub get
flutter run
flutter build ...
```

sesuai project aktual.

## Known limitations

Hanya tuliskan limitation yang benar-benar ada.

------------------------------------------------------------------------

# 84. JANGAN MEMBERIKAN JAWABAN BERUPA PROTOTYPE

Jika diminta:

> "Buat project ini."

Maka lakukan:

``` text
CREATE FILES
WRITE CODE
INSTALL DEPENDENCIES
CONFIGURE PROJECT
CONNECT API
IMPLEMENT FEATURES
RUN TESTS
FIX ERRORS
BUILD
```

bukan:

``` text
berikan contoh kode
```

atau:

``` text
berikan rancangan
```

atau:

``` text
buat prototype sederhana
```

------------------------------------------------------------------------

# 85. FIRST ACTION --- SEBELUM CODING

Sebelum menulis banyak kode:

## A. Inspect environment

Periksa:

``` text
OS
PHP
Composer
Node
npm
Laravel
Flutter
Dart
Android SDK
Git
```

## B. Inspect backend

Periksa repository:

``` text
friza13/be-distribution-system-armada
```

Periksa:

``` text
routes
controllers
DTO
response
auth
WebSocket
event
upload
health
```

## C. Verify API

Test:

``` text
/v1/health/liveness
/v1/health/readiness
/v1/auth/login
```

gunakan akun test.

## D. Verify role

Login:

``` text
admin
owner
driver
```

dan catat response aktual.

## E. Build frontend architecture

Baru setelah itu mulai coding.

------------------------------------------------------------------------

# 86. FIRST MILESTONE

Milestone pertama harus menghasilkan:

``` text
armada-web/
    Laravel project
    environment
    authentication
    API client
    Admin layout
    role handling
    dashboard foundation

armada-mobile/
    Flutter project
    environment
    API client
    secure storage
    authentication
    role routing
    Owner shell
    Driver shell
```

Kemudian lanjutkan secara incremental.

------------------------------------------------------------------------

# 87. FINAL INSTRUCTION

**BANGUN SISTEM INI SEBAGAI PROJECT NYATA.**

Jangan mengubahnya menjadi:

-   prototype;
-   mockup;
-   landing page;
-   demo;
-   static dashboard;
-   fake GPS;
-   fake realtime;
-   fake authentication;
-   local-only CRUD.

Gunakan backend yang sudah tersedia.

Gunakan API nyata.

Gunakan GPS perangkat nyata.

Gunakan WebSocket/WebRTC sesuai contract nyata.

Gunakan Laravel untuk Admin Web.

Gunakan Flutter untuk Owner dan Driver Mobile.

Pisahkan repository Web dan Mobile.

Ikuti PRD, SRS, DFD, Architecture, Domain Model, API Contract,
Security/RBAC, Project Flow, Testing Roadmap, dan Team Responsibility.

Prioritaskan **P0** terlebih dahulu:

``` text
Auth/RBAC
User Management
Delivery CRUD
Item/Destination
Driver/Vehicle Assignment
Driver GPS
Owner Live Map
Driver Delivery
Delivery State Machine
Chat
POD
Audit
```

Kemudian:

``` text
Route Optimization
Geofence
Notifications
PTT
SOS
Reports
Video/WebRTC
Production Hardening
```

Dan selalu ingat:

> **Backend adalah source of truth. Frontend adalah client yang
> merepresentasikan state backend.**

> **Jangan menyebut sebuah fitur "selesai" jika fitur tersebut hanya
> terlihat bekerja di UI tetapi belum bekerja terhadap backend nyata.**
