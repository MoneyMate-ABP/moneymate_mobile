# QA Test Plan - MoneyMate Flutter App
**Tiket:** FLT-501  
**Sprint:** 1  
**Versi Dokumen:** 1.0.0  
**Tanggal Dibuat:** 2026-06-04  
**Dibuat Oleh:** QA Engineer  
**Status Dokumen:** Draft

---

## 1. Tujuan Pengujian

Dokumen ini merupakan rencana pengujian QA (Quality Assurance) untuk aplikasi **MoneyMate** yang dikembangkan menggunakan Flutter. Tujuan dari dokumen ini adalah:

- Mendefinisikan ruang lingkup dan pendekatan pengujian untuk Sprint 1.
- Menyediakan checklist QA yang dapat digunakan untuk memvalidasi hasil kerja anggota tim lain setelah fitur tersedia.
- Menetapkan standar kualitas yang harus dipenuhi sebelum rilis.
- Mendokumentasikan format pelaporan bug dan kriteria kelulusan (exit criteria).

> **Catatan:** Beberapa test case mungkin berstatus **Pending** atau **Blocked** sampai fitur terkait selesai diimplementasikan oleh anggota tim lain.

---

## 2. Ruang Lingkup Pengujian

### 2.1 Dalam Cakupan (In-Scope)

| Area | Keterangan |
|------|------------|
| Project Foundation (FLT-001) | Struktur proyek, konfigurasi dasar, build |
| Architecture & State Management (FLT-002) | Implementasi arsitektur, manajemen state |
| API Client + Auth Interceptor (FLT-003) | Koneksi API, interceptor autentikasi |
| Secure Token Storage (FLT-004) | Penyimpanan token yang aman |
| Shared Design System (FLT-005) | Komponen UI, tema, tipografi |
| App Navigation Shell (FLT-401) | Navigasi utama, bottom navigation, routing |
| QA Test Plan (FLT-501) | Validasi dokumen dan proses QA itu sendiri |

### 2.2 Di Luar Cakupan (Out-of-Scope) - Sprint 1

- Backend API (diuji terpisah oleh tim backend)
- Pengujian performa dan load testing
- Pengujian keamanan penetrasi (penetration testing)
- Fitur-fitur Sprint 2 dan seterusnya

---

## 3. Lingkungan Pengujian

### 3.1 Perangkat Target

| Platform | Versi Minimum | Versi yang Diuji |
|----------|--------------|------------------|
| Android | Android 6.0 (API 23) | Android 12, 13, 14 |
| iOS | iOS 13.0 | iOS 16, 17 |

### 3.2 Flutter & Tools

| Komponen | Versi |
|----------|-------|
| Flutter SDK | ≥ 3.x (stable channel) |
| Dart SDK | ≥ 3.x |
| Android Studio / VS Code | Versi terbaru |
| Flutter DevTools | Versi terbaru |

### 3.3 Backend & API

| Komponen | Detail |
|----------|--------|
| API Environment | Development / Staging |
| Base URL | Dikonfigurasi via `.env` / flavor |
| Auth | JWT / OAuth2 (sesuai implementasi FLT-003) |

### 3.4 Prasyarat Pengujian

- [ ] Flutter SDK terinstal dan `flutter doctor` menunjukkan status OK
- [ ] Emulator/perangkat fisik tersedia dan terhubung
- [ ] Repositori berhasil di-clone dan `flutter pub get` berjalan tanpa error
- [ ] Akses ke environment backend (dev/staging) tersedia
- [ ] Akun test tersedia untuk pengujian autentikasi

---

## 4. Definisi Status

| Status | Simbol | Keterangan |
|--------|--------|------------|
| **Pending** | ⏳ | Test case belum dapat dieksekusi karena fitur belum tersedia atau belum dijadwalkan |
| **Passed** | ✅ | Test case dieksekusi dan hasilnya sesuai ekspektasi |
| **Failed** | ❌ | Test case dieksekusi namun hasilnya tidak sesuai ekspektasi; perlu dilaporkan sebagai bug |
| **Blocked** | 🚫 | Test case tidak dapat dieksekusi karena ada dependensi yang belum terpenuhi (misalnya: API belum siap, build gagal) |

---

## 5. Sprint 1 QA Checklist

### 5.1 FLT-001: Project Foundation

**Deskripsi:** Validasi bahwa fondasi proyek Flutter telah disetup dengan benar.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT001-TC01 | Struktur folder proyek | Periksa folder `lib/`, `test/`, `assets/`, `pubspec.yaml` | Folder sesuai standar arsitektur yang ditetapkan | ⏳ Pending |
| FLT001-TC02 | Build Android (debug) | Jalankan `flutter build apk --debug` | Build berhasil tanpa error | ⏳ Pending |
| FLT001-TC03 | Build iOS (debug) | Jalankan `flutter build ios --debug --no-codesign` | Build berhasil tanpa error | ⏳ Pending |
| FLT001-TC04 | Flutter pub get | Jalankan `flutter pub get` | Semua dependensi terinstall tanpa konflik | ⏳ Pending |
| FLT001-TC05 | Flutter analyze | Jalankan `flutter analyze` | Tidak ada error; warning minimal | ⏳ Pending |
| FLT001-TC06 | Unit test dasar | Jalankan `flutter test` | Semua test bawaan lulus | ⏳ Pending |
| FLT001-TC07 | Konfigurasi flavor/env | Periksa konfigurasi dev, staging, production | Setiap flavor dapat dijalankan dan mengarah ke env yang benar | ⏳ Pending |
| FLT001-TC08 | Gitignore & file sensitif | Periksa `.gitignore` | File sensitif (`.env`, keystore) tidak ter-commit | ⏳ Pending |

---

### 5.2 FLT-002: Architecture & State Management

**Deskripsi:** Validasi implementasi arsitektur dan manajemen state aplikasi.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT002-TC01 | Struktur layer arsitektur | Periksa folder `presentation/`, `domain/`, `data/` | Pemisahan layer sesuai arsitektur yang disepakati (Clean/MVVM/dll) | ⏳ Pending |
| FLT002-TC02 | State provider terinisialisasi | Jalankan app, periksa via DevTools | Provider/Bloc/Riverpod terinisialisasi tanpa error | ⏳ Pending |
| FLT002-TC03 | State tidak bocor antar halaman | Navigasi antar halaman beberapa kali | State per halaman di-reset dengan benar saat diperlukan | ⏳ Pending |
| FLT002-TC04 | Loading state ditampilkan | Trigger aksi yang membutuhkan loading | UI menampilkan indikator loading selama proses | ⏳ Pending |
| FLT002-TC05 | Error state ditampilkan | Simulasikan error (matikan koneksi) | UI menampilkan pesan error yang informatif | ⏳ Pending |
| FLT002-TC06 | Unit test state management | Periksa file test di `test/` | Terdapat unit test untuk logic state management utama | ⏳ Pending |

---

### 5.3 FLT-003: API Client + Auth Interceptor

**Deskripsi:** Validasi klien API dan interceptor autentikasi.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT003-TC01 | Koneksi ke API berhasil | Trigger request API manapun | Response diterima dengan status 200 | ⏳ Pending |
| FLT003-TC02 | Header Authorization dikirim | Monitor request via DevTools/proxy | Header `Authorization: Bearer <token>` ada di setiap request terautentikasi | ⏳ Pending |
| FLT003-TC03 | Token refresh otomatis | Gunakan token kadaluarsa, trigger request | Token di-refresh otomatis, request diulang tanpa user perlu login ulang | ⏳ Pending |
| FLT003-TC04 | Penanganan error 401 | Gunakan token invalid | App mengarahkan user ke halaman login | ⏳ Pending |
| FLT003-TC05 | Penanganan error 500 | Simulasikan server error | App menampilkan pesan error yang sesuai, tidak crash | ⏳ Pending |
| FLT003-TC06 | Timeout request | Simulasikan koneksi lambat | App menampilkan timeout error setelah durasi yang ditetapkan | ⏳ Pending |
| FLT003-TC07 | Tidak ada koneksi internet | Matikan koneksi, trigger request | App menampilkan pesan "tidak ada koneksi internet" | ⏳ Pending |
| FLT003-TC08 | Request tanpa auth (public endpoint) | Akses endpoint publik | Request berhasil tanpa header Authorization | ⏳ Pending |

---

### 5.4 FLT-004: Secure Token Storage

**Deskripsi:** Validasi penyimpanan token secara aman.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT004-TC01 | Token tersimpan setelah login | Login, periksa storage | Token access & refresh tersimpan di secure storage | ⏳ Pending |
| FLT004-TC02 | Token tidak tersimpan di plain storage | Periksa SharedPreferences/file biasa | Token TIDAK ditemukan di penyimpanan tidak terenkripsi | ⏳ Pending |
| FLT004-TC03 | Token terhapus saat logout | Logout, periksa storage | Token access & refresh terhapus dari secure storage | ⏳ Pending |
| FLT004-TC04 | Token persisten setelah restart | Login, restart app | User tetap terautentikasi setelah restart app | ⏳ Pending |
| FLT004-TC05 | Token tidak bocor di log | Aktifkan logging, lakukan login | Token tidak muncul dalam log debug/console | ⏳ Pending |
| FLT004-TC06 | Keamanan di Android (Keystore) | Periksa implementasi | Menggunakan Android Keystore / flutter_secure_storage | ⏳ Pending |
| FLT004-TC07 | Keamanan di iOS (Keychain) | Periksa implementasi | Menggunakan iOS Keychain / flutter_secure_storage | ⏳ Pending |

---

### 5.5 FLT-005: Shared Design System

**Deskripsi:** Validasi komponen UI, tema, dan design system yang digunakan secara global.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT005-TC01 | Tema warna terdefinisi | Buka ThemeData / file tema | Palet warna primer, sekunder, error, background terdefinisi | ⏳ Pending |
| FLT005-TC02 | Tipografi konsisten | Cek semua halaman | Font dan ukuran teks konsisten sesuai design system | ⏳ Pending |
| FLT005-TC03 | Komponen tombol (Button) | Render semua varian tombol | Primary, secondary, outlined, disabled button tampil sesuai desain | ⏳ Pending |
| FLT005-TC04 | Komponen input field | Interaksi dengan text field | Normal, focused, error, disabled state tampil dengan benar | ⏳ Pending |
| FLT005-TC05 | Dark mode (jika ada) | Aktifkan dark mode di device | Seluruh UI beradaptasi ke dark mode tanpa elemen yang "terpotong" | ⏳ Pending |
| FLT005-TC06 | Responsivitas ukuran layar | Test di berbagai ukuran device | Layout tidak overflow pada layar kecil (360dp) dan besar (tablet) | ⏳ Pending |
| FLT005-TC07 | Icon dan asset | Tampilkan semua icon/gambar | Semua asset terkompilasi dan tampil dengan benar, tidak ada broken image | ⏳ Pending |
| FLT005-TC08 | Widget test komponen | Jalankan `flutter test` | Widget test untuk komponen design system lulus | ⏳ Pending |

---

### 5.6 FLT-401: App Navigation Shell

**Deskripsi:** Validasi navigasi utama dan shell aplikasi.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT401-TC01 | Bottom navigation bar tampil | Buka app setelah login | Bottom navigation bar tampil dengan semua tab yang benar | ⏳ Pending |
| FLT401-TC02 | Perpindahan tab | Klik setiap tab di bottom navigation | Halaman berpindah sesuai tab yang diklik; tab aktif terhighlight | ⏳ Pending |
| FLT401-TC03 | State tab dipertahankan | Scroll ke bawah di tab A, pindah ke tab B, kembali ke tab A | Posisi scroll di tab A dipertahankan | ⏳ Pending |
| FLT401-TC04 | Deep link / route langsung | Navigasi ke route spesifik via kode | Halaman yang benar ditampilkan | ⏳ Pending |
| FLT401-TC05 | Back navigation (Android) | Tekan tombol back di Android | Navigasi kembali ke halaman sebelumnya atau keluar app jika di root | ⏳ Pending |
| FLT401-TC06 | Swipe back (iOS) | Swipe dari kiri di iOS | Navigasi kembali ke halaman sebelumnya | ⏳ Pending |
| FLT401-TC07 | Navigation saat tidak terautentikasi | Akses halaman terproteksi tanpa login | Diarahkan ke halaman login | ⏳ Pending |
| FLT401-TC08 | Navigasi setelah login | Login berhasil | Diarahkan ke halaman utama (Dashboard) | ⏳ Pending |
| FLT401-TC09 | Navigasi setelah logout | Logout | Diarahkan ke halaman login; tidak dapat kembali ke halaman terproteksi | ⏳ Pending |

---

### 5.7 FLT-501: QA Test Plan

**Deskripsi:** Validasi bahwa dokumen dan proses QA itu sendiri telah berjalan dengan benar.

| ID | Test Case | Langkah | Ekspektasi | Status |
|----|-----------|---------|------------|--------|
| FLT501-TC01 | Dokumen QA tersedia di repositori | Periksa `docs/qa/flutter_qa_test_plan.md` | File tersedia dan dapat diakses oleh seluruh tim | ✅ Passed |
| FLT501-TC02 | Dokumen ditulis dalam Bahasa Indonesia | Review dokumen | Seluruh konten ditulis dalam Bahasa Indonesia | ✅ Passed |
| FLT501-TC03 | Semua tiket Sprint 1 tercakup | Review checklist | FLT-001 s/d FLT-005, FLT-401, FLT-501 memiliki checklist | ✅ Passed |
| FLT501-TC04 | Format bug report tersedia | Review dokumen | Template bug report tersedia di dokumen | ✅ Passed |
| FLT501-TC05 | Exit criteria terdefinisi | Review dokumen | Exit criteria jelas dan terukur | ✅ Passed |

---

## 6. Checklist Fitur Umum (Untuk Sprint Mendatang)

Checklist berikut akan digunakan saat fitur masing-masing tersedia. Status saat ini adalah **Pending** karena fitur belum diimplementasikan di Sprint 1.

### 6.1 Autentikasi (Auth)

| ID | Test Case | Status |
|----|-----------|--------|
| AUTH-TC01 | Login dengan kredensial valid | ⏳ Pending |
| AUTH-TC02 | Login dengan email salah | ⏳ Pending |
| AUTH-TC03 | Login dengan password salah | ⏳ Pending |
| AUTH-TC04 | Login dengan field kosong | ⏳ Pending |
| AUTH-TC05 | Register akun baru | ⏳ Pending |
| AUTH-TC06 | Register dengan email sudah terdaftar | ⏳ Pending |
| AUTH-TC07 | Lupa password / reset password | ⏳ Pending |
| AUTH-TC08 | Logout berhasil | ⏳ Pending |
| AUTH-TC09 | Session expired - redirect ke login | ⏳ Pending |
| AUTH-TC10 | Validasi format email di form | ⏳ Pending |
| AUTH-TC11 | Validasi kekuatan password | ⏳ Pending |
| AUTH-TC12 | Tampilkan/sembunyikan password | ⏳ Pending |

---

### 6.2 Dashboard

| ID | Test Case | Status |
|----|-----------|--------|
| DASH-TC01 | Dashboard memuat data ringkasan keuangan | ⏳ Pending |
| DASH-TC02 | Total saldo tampil dengan benar | ⏳ Pending |
| DASH-TC03 | Grafik/chart keuangan tampil | ⏳ Pending |
| DASH-TC04 | Transaksi terbaru tampil di dashboard | ⏳ Pending |
| DASH-TC05 | Pull-to-refresh memperbarui data | ⏳ Pending |
| DASH-TC06 | Dashboard tampil saat offline (cache) | ⏳ Pending |
| DASH-TC07 | Notifikasi/alert anggaran tampil | ⏳ Pending |

---

### 6.3 Transaksi (Transactions)

| ID | Test Case | Status |
|----|-----------|--------|
| TRX-TC01 | Daftar transaksi tampil dengan benar | ⏳ Pending |
| TRX-TC02 | Tambah transaksi pemasukan | ⏳ Pending |
| TRX-TC03 | Tambah transaksi pengeluaran | ⏳ Pending |
| TRX-TC04 | Edit transaksi yang sudah ada | ⏳ Pending |
| TRX-TC05 | Hapus transaksi | ⏳ Pending |
| TRX-TC06 | Filter transaksi berdasarkan tanggal | ⏳ Pending |
| TRX-TC07 | Filter transaksi berdasarkan kategori | ⏳ Pending |
| TRX-TC08 | Pencarian transaksi | ⏳ Pending |
| TRX-TC09 | Pagination / infinite scroll | ⏳ Pending |
| TRX-TC10 | Validasi field wajib saat tambah transaksi | ⏳ Pending |
| TRX-TC11 | Validasi format nominal (angka positif) | ⏳ Pending |
| TRX-TC12 | Detail transaksi tampil lengkap | ⏳ Pending |

---

### 6.4 Scan Struk / Mutasi (Scan Receipt/Mutation)

| ID | Test Case | Status |
|----|-----------|--------|
| SCAN-TC01 | Akses kamera untuk scan struk | ⏳ Pending |
| SCAN-TC02 | Upload gambar dari galeri | ⏳ Pending |
| SCAN-TC03 | OCR berhasil membaca struk | ⏳ Pending |
| SCAN-TC04 | Data struk ter-parse dan ditampilkan | ⏳ Pending |
| SCAN-TC05 | Konfirmasi dan simpan hasil scan | ⏳ Pending |
| SCAN-TC06 | Penanganan gambar buram/tidak terbaca | ⏳ Pending |
| SCAN-TC07 | Scan mutasi rekening bank | ⏳ Pending |
| SCAN-TC08 | Izin kamera/galeri ditangani dengan benar | ⏳ Pending |
| SCAN-TC09 | Izin ditolak - pesan error informatif | ⏳ Pending |

---

### 6.5 Anggaran (Budget)

| ID | Test Case | Status |
|----|-----------|--------|
| BUDG-TC01 | Daftar anggaran tampil | ⏳ Pending |
| BUDG-TC02 | Buat anggaran baru | ⏳ Pending |
| BUDG-TC03 | Edit anggaran | ⏳ Pending |
| BUDG-TC04 | Hapus anggaran | ⏳ Pending |
| BUDG-TC05 | Progress anggaran tampil (digunakan vs total) | ⏳ Pending |
| BUDG-TC06 | Notifikasi saat anggaran hampir habis | ⏳ Pending |
| BUDG-TC07 | Anggaran per kategori berfungsi | ⏳ Pending |
| BUDG-TC08 | Validasi nominal anggaran | ⏳ Pending |

---

### 6.6 Kategori (Categories)

| ID | Test Case | Status |
|----|-----------|--------|
| CAT-TC01 | Daftar kategori default tampil | ⏳ Pending |
| CAT-TC02 | Tambah kategori custom | ⏳ Pending |
| CAT-TC03 | Edit nama/ikon kategori | ⏳ Pending |
| CAT-TC04 | Hapus kategori yang tidak digunakan | ⏳ Pending |
| CAT-TC05 | Tidak bisa hapus kategori yang digunakan transaksi | ⏳ Pending |
| CAT-TC06 | Kategori tampil saat pilih transaksi | ⏳ Pending |
| CAT-TC07 | Validasi nama kategori wajib diisi | ⏳ Pending |

---

### 6.7 Profil (Profile)

| ID | Test Case | Status |
|----|-----------|--------|
| PROF-TC01 | Data profil user tampil dengan benar | ⏳ Pending |
| PROF-TC02 | Edit nama profil | ⏳ Pending |
| PROF-TC03 | Upload foto profil | ⏳ Pending |
| PROF-TC04 | Ganti password | ⏳ Pending |
| PROF-TC05 | Ganti email | ⏳ Pending |
| PROF-TC06 | Pengaturan notifikasi | ⏳ Pending |
| PROF-TC07 | Pengaturan mata uang | ⏳ Pending |
| PROF-TC08 | Logout dari halaman profil | ⏳ Pending |
| PROF-TC09 | Hapus akun | ⏳ Pending |

---

### 6.8 Navigasi (Navigation)

| ID | Test Case | Status |
|----|-----------|--------|
| NAV-TC01 | Bottom navigation berfungsi di semua tab | ⏳ Pending |
| NAV-TC02 | Tombol back hardware Android berfungsi | ⏳ Pending |
| NAV-TC03 | Swipe back iOS berfungsi | ⏳ Pending |
| NAV-TC04 | Deep link ke halaman spesifik | ⏳ Pending |
| NAV-TC05 | Navigasi tidak crash saat double tap cepat | ⏳ Pending |
| NAV-TC06 | Stack navigasi bersih (tidak ada halaman menumpuk) | ⏳ Pending |
| NAV-TC07 | Animasi transisi halaman halus | ⏳ Pending |

---

## 7. Format Pelaporan Bug

Setiap bug yang ditemukan harus dilaporkan menggunakan format berikut. Buat tiket di sistem issue tracking (Jira/GitHub Issues/Linear) dengan template ini:

---

### Template Bug Report

```
## Judul Bug
[Deskripsi singkat bug dalam satu kalimat]
Contoh: "Aplikasi crash saat tap tombol login dengan password kosong"

## ID Tiket Terkait
[Contoh: FLT-003]

## Lingkungan
- Platform       : Android / iOS
- Versi OS       : [Contoh: Android 13]
- Versi App      : [Contoh: 1.0.0+1]
- Device         : [Contoh: Samsung Galaxy S23]
- Flutter Version: [Contoh: 3.19.0]

## Tingkat Keparahan (Severity)
[ ] Critical  - App crash / data loss / fitur utama tidak berfungsi sama sekali
[ ] High      - Fitur utama tidak berfungsi, ada workaround
[ ] Medium    - Fitur tidak berfungsi optimal, ada workaround
[ ] Low       - Masalah kosmetik / UI minor

## Prioritas (Priority)
[ ] P1 - Harus diperbaiki sebelum rilis
[ ] P2 - Harus diperbaiki di sprint berikutnya
[ ] P3 - Bisa dijadwalkan kemudian

## Langkah Reproduksi
1. [Langkah pertama]
2. [Langkah kedua]
3. [Langkah ketiga]
...

## Hasil yang Diharapkan (Expected Result)
[Apa yang seharusnya terjadi]

## Hasil yang Didapat (Actual Result)
[Apa yang sebenarnya terjadi]

## Screenshot / Video
[Lampirkan screenshot atau rekaman layar jika memungkinkan]

## Log Error (jika ada)
[Tempel stack trace atau log dari console/DevTools]

## Catatan Tambahan
[Informasi tambahan yang relevan, misalnya: hanya terjadi di iOS, tidak terjadi di emulator, dll.]
```

---

### Klasifikasi Severity

| Severity | Deskripsi | Contoh |
|----------|-----------|--------|
| **Critical** | App crash, data hilang, fitur core tidak bisa digunakan | App crash saat login |
| **High** | Fitur utama tidak berfungsi, ada workaround | Tombol simpan tidak responsif |
| **Medium** | Fitur tidak optimal, ada workaround | Filter transaksi salah urutan |
| **Low** | Masalah UI/kosmetik, tidak mempengaruhi fungsi | Teks terpotong di layar kecil |

---

## 8. Kriteria Kelulusan (Exit Criteria)

Sprint 1 dianggap **LULUS QA** apabila memenuhi seluruh kriteria berikut:

### 8.1 Kriteria Wajib (Mandatory)

| # | Kriteria | Target |
|---|----------|--------|
| 1 | Tidak ada bug **Critical** yang terbuka | 0 bug Critical |
| 2 | Tidak ada bug **High** yang terbuka | 0 bug High |
| 3 | Semua test case Sprint 1 telah dieksekusi | 100% dari checklist FLT-001 s/d FLT-401 |
| 4 | Test case **Passed** ≥ 90% dari total yang dieksekusi | ≥ 90% Pass rate |
| 5 | Build sukses di Android dan iOS tanpa error | Build green |
| 6 | `flutter analyze` tanpa error | 0 analyzer error |
| 7 | `flutter test` lulus semua unit test | 0 test failure |

### 8.2 Kriteria Diharapkan (Desired)

| # | Kriteria | Target |
|---|----------|--------|
| 1 | Bug **Medium** yang terbuka didokumentasikan dengan rencana penyelesaian | Semua Medium bugs didokumentasikan |
| 2 | Code coverage unit test | ≥ 60% |
| 3 | Tidak ada warning dari `flutter analyze` | 0 warnings (atau disetujui tim) |

### 8.3 Proses Persetujuan

```
QA Engineer menyelesaikan eksekusi test
        ↓
QA membuat laporan ringkasan (test summary report)
        ↓
Review bersama tim (QA + Developer + PO)
        ↓
Semua critical & high bug diperbaiki dan diverifikasi
        ↓
PO memberikan sign-off
        ↓
Sprint 1 LULUS QA ✅
```

---

## 9. Riwayat Perubahan Dokumen

| Versi | Tanggal | Perubahan | Penulis |
|-------|---------|-----------|---------|
| 1.0.0 | 2026-06-04 | Pembuatan dokumen awal | QA Engineer (FLT-501) |

---

*Dokumen ini akan terus diperbarui seiring berjalannya Sprint 1 dan sprint-sprint berikutnya.*
