# Implementasi Pengujian Android Emulator (Zero Impact on Web)

Rencana ini dirancang khusus untuk memastikan **versi Web tetap 100% identik** dalam hal fungsi, tampilan, dan performa. Kita akan menggunakan teknik *Conditional Compilation*.

## Prinsip "Zero Impact on Web"

> [!IMPORTANT]
> **Tidak ada perubahan logika pada Web.**
> Kode yang saat ini ada di Web (menggunakan `dart:html`) hanya akan dipindahkan ke file khusus Web. Saat aplikasi dijalankan di browser, Flutter akan memanggil file tersebut. Saat di Android, Flutter akan memanggil file yang berbeda.

## Rencana Teknis

### 1. Isolasi Kode Platform
Saya akan membuat "jembatan" sehingga kode Web yang sudah sempurna tidak tersentuh oleh logika Android:

- **[NEW]** `lib/utils/platform_utils/stub.dart`: File kosong sebagai perantara.
- **[NEW]** `lib/utils/platform_utils/web_impl.dart`: **Berisi salinan persis kode Web Anda saat ini.**
- **[NEW]** `lib/utils/platform_utils/mobile_impl.dart`: Berisi kode baru khusus Android.

### 2. Penyesuaian Import (Hanya Ganti Alamat)
Di file seperti `profile_dropdown.dart`, saya hanya akan mengganti:
`import 'dart:html' as html;`
menjadi
`import 'platform_utils/platform_base.dart';`

Secara teknis, saat dijalankan di Web, aplikasi akan tetap menjalankan perintah `html.FileUploadInputElement()` yang sama persis seperti sekarang.

### 3. Konfigurasi Android
- **[NEW]** Folder `android/`: Folder terpisah yang hanya dibaca saat build ke Android. Sama sekali tidak mempengaruhi folder `web/`.

## User Review Required

> [!TIP]
> Saya akan menambahkan plugin `image_picker` dan `share_plus` di `pubspec.yaml`. Di dunia Flutter, plugin ini memiliki "Web Implementation" yang jika tidak kita panggil, tidak akan merubah perilaku Web yang sudah ada.

## Verification Plan

### Manual Verification
1.  **Web**: Saya akan memverifikasi fitur "Ganti Foto" dan "Ekspor CSV". Jika ada perbedaan sekecil apapun (misal: dialog yang muncul berbeda), saya akan segera mengembalikannya.
2.  **Android**: Memastikan aplikasi bisa terbuka di emulator tanpa mengganggu database Supabase.

---
**Apakah penjelasan "Zero Impact" ini cukup melegakan? Jika ya, saya akan mulai melakukan eksekusi.**
