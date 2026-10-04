# Android → Web Feature Parity

Paket ini adalah update untuk project Flutter Web yang sudah ada. Fokusnya adalah membawa fitur Android yang sebelumnya belum terhubung/terlihat di Web tanpa mengganti backend Supabase.

## Fitur yang ditambahkan/diaktifkan

- Sidebar desktop lengkap: Dashboard, Periode Aktif, Transaksi, Periode Lainnya, Absensi, Gaji & Pembayaran, Kasbon, Pekerja.
- Transaksi: tambah, edit, hapus, filter kategori/periode, pencarian, detail transaksi.
- Detail transaksi per periode/kategori.
- Absensi 7 hari dengan pilihan FULL, HALF, LEMBUR 1, LEMBUR 2, OFF.
- Lembur manual per pekerja.
- Manajemen pekerja: tambah, edit, hapus.
- Rekap gaji: upah pokok, bonus lembur, lembur manual, potongan kasbon, gaji bersih.
- Kasbon global: tambah dan hapus serta pembuatan transaksi Gondes otomatis.
- Kasbon pribadi: tambah, edit, hapus, pembayaran, dan saldo hutang per pekerja.
- Proses pembayaran gaji + reset absensi/adjustment/kasbon global minggu berjalan.
- Navigasi periode lama ke detail transaksi.
- Export transaksi dan rekap gaji ke CSV yang dapat dibuka Excel.
- Print browser untuk laporan/PDF melalui dialog Print browser.
- Sinkronisasi semua data fitur di atas melalui Supabase yang sama dengan Android.

## File utama yang diperbarui

- `lib/services/project_provider.dart`
- `lib/services/supabase_service.dart`
- `lib/screens/main_shell.dart`
- `lib/screens/attendance_screen.dart`
- `lib/screens/salary_summary_screen.dart`
- `lib/screens/worker_screen.dart`
- `lib/screens/transaction_screen.dart`
- `lib/screens/classification_screen.dart`
- `lib/screens/history_periods_screen.dart`
- `lib/screens/kasbon_ledger_screen.dart`

## File baru

- `lib/screens/transaction_detail_screen.dart`
- `lib/screens/private_kasbon_screen.dart`
- `lib/utils/web_exporter.dart`

## Catatan penting

1. Backend tetap Supabase yang sama. Tidak membuat database baru.
2. `gondes_attendance` ditulis dengan pola delete-by-worker/date lalu insert agar tidak bergantung pada tipe primary key lokal Android.
3. Export Excel menggunakan CSV karena tidak menambah library spreadsheet baru. File CSV dapat dibuka langsung dengan Microsoft Excel/LibreOffice.
4. PDF web menggunakan Print browser. Pilih Save as PDF pada dialog print.
5. Project ini tidak dapat dijalankan dengan `flutter analyze` di lingkungan pembuatan paket karena Flutter SDK tidak tersedia di runtime ini. Source sudah diperiksa struktur kurung/bracket dan dependency yang digunakan hanya dependency yang sudah ada pada project Web.
6. Setelah mengganti source, jalankan `flutter pub get`, lalu `flutter analyze` dan `flutter build web` pada komputer yang memiliki Flutter SDK.
