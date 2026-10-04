# Catatan Porting

Project ini dibuat sebagai baseline Web baru berdasarkan struktur aplikasi Android yang diberikan.

Prioritas implementasi:
1. Data contract Supabase.
2. Business rules absensi dan gajian.
3. Navigation Android → Web.
4. Desktop layout.
5. CRUD transaksi, pekerja, dan kasbon.

Sebelum production, jalankan:
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`

Pastikan RLS Supabase sudah aktif dan policy sesuai role pengguna.
