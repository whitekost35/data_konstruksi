# Implementation Plan - Data Konstruksi (macOS Style Refinement & Data Integration)

Melanjutkan visi dari Andrew untuk membangun dashboard konstruksi berbasis web dengan estetika iMac. Fokus utama adalah menghubungkan UI ke Supabase, mengimplementasikan chart real, dan meningkatkan efisiensi input absensi.

## User Review Required

> [!IMPORTANT]
> **Akses Supabase**: Pastikan `anonKey` yang ada di `main.dart` masih valid dan memiliki izin (RLS) untuk membaca/menulis ke tabel `gondes_workers`, `gondes_attendance`, dll.
> **Gaya Chart**: Saya akan menggunakan `fl_chart` dengan gradien halus sesuai estetika Apple. Apakah ada preferensi khusus untuk jenis chart di dashboard (misal: Line Chart untuk tren pengeluaran vs Pie Chart untuk kategori)?

## Proposed Changes

### 1. Dashboard Enhancements
Menghubungkan card ringkasan ke data real dan mengganti placeholder chart.

#### [MODIFY] [dashboard_screen.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/screens/dashboard_screen.dart)
- Menggunakan `StreamBuilder` atau `FutureBuilder` untuk mengambil total pengeluaran dari Supabase.
- Implementasi `LineChart` menggunakan `fl_chart` untuk "Visualisasi Pengeluaran".
- Memperbarui daftar "Aktivitas Terbaru" agar mengambil data dari tabel `transactions`.

### 2. Weekly Attendance Spreadsheet UI
Mengubah `DataTable` statis menjadi input berbasis grid yang lebih responsif dan mendukung pengisian massal.

#### [MODIFY] [attendance_screen.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/screens/attendance_screen.dart)
- Implementasi grid yang memungkinkan user mengisi kehadiran (Full, 1/2, Lembur) secara cepat untuk seluruh pekerja dalam satu minggu.
- Penambahan logika perhitungan gaji otomatis berdasarkan kehadiran dan rate per pekerja.
- Integrasi tombol "Simpan" yang melakukan `upsert` massal ke Supabase.

### 3. iMac Style Polish
Mempertajam efek visual agar lebih menyerupai macOS.

#### [MODIFY] [main_shell.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/screens/main_shell.dart)
- Penambahan animasi transisi antar menu.
- Penyesuaian `sigma` blur pada sidebar untuk kedalaman yang lebih baik.

#### [MODIFY] [summary_card.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/widgets/summary_card.dart)
- Penambahan efek `hover` (sedikit lebih terang/shadow lebih besar saat mouse di atas kartu).

### 4. Missing Features Scaffolding
Menyiapkan kerangka untuk fitur yang masih kosong.

#### [NEW] [worker_screen.dart](file:///C:/Users/aidan/AndroidStudioProjects/data_konstruksi/lib/screens/worker_screen.dart)
- Daftar pekerja dengan fitur tambah/edit.

## Verification Plan

### Automated Tests
- Menjalankan `flutter test` untuk memastikan model data `Worker` dan `AttendanceRecord` melakukan mapping dengan benar.

### Manual Verification
- Verifikasi visual: Memastikan efek glassmorphism terlihat konsisten di browser (Chrome/Edge).
- Verifikasi data: Menambah data absensi dan memastikan data tersimpan di dashboard Supabase.
