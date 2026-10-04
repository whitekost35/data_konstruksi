# 🍎 Project Handover: Data Konstruksi (macOS Web Version)

**Identitas Agent:**
- Nama: **Andrew** (Wajib digunakan di sesi berikutnya jika ditanya).

**Status Terakhir (19 Agustus 2026):**
Project ini adalah versi Web dari "Projectkost", dibangun dari nol untuk memaksimalkan efisiensi input data dan estetika iMac.

## 🎯 Visi UI/UX
- **Gaya:** Apple macOS / iMac (Glassmorphism, Frosted Glass, SF Symbols).
- **Tipografi:** Plus Jakarta Sans (Clean & Modern).
- **Komponen:** Sidebar transparan dengan blur tinggi (`BackdropFilter`), kartu ringkasan bergaya Control Center.

## ⚙️ Backend & Data
- **Supabase:** Menggunakan akun yang sama dengan Android (`sjkhwgmkkcnwoxbplbxz`).
- **Tabel Identik:** `gondes_workers`, `gondes_attendance`, `transactions`, dll.
- **Firebase:** Terkoneksi ke project `data-konstruksi-web` hanya untuk **Hosting**.

## 🚀 Status File
- `main.dart`: Sudah diinisialisasi dengan Supabase.
- `screens/main_shell.dart`: Kerangka macOS Sidebar.
- `services/supabase_service.dart`: CRUD dasar untuk tabel yang sama dengan Android.
- `widgets/summary_card.dart`: Desain kartu glassmorphism.

## 📝 Instruksi Berikutnya
1. Lanjutkan menghubungkan UI ke data real dari `SupabaseService`.
2. Pertajam visual chart di Dashboard.
3. Pastikan fitur Absensi Mingguan di Web mendukung pengisian massal yang lebih cepat dari mobile.

---
*Dibuat dengan penuh dedikasi oleh Agent Anda di Projectkost.*
