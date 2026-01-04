# Panduan Setup Localhost (Testing Mode)

Panduan ini untuk menjalankan Rana Market secara full (Server + Aplikasi) di komputer lokal Anda.

## 1. Persiapan Server
1. Pastikan **PostgreSQL** sudah berjalan.
   - Database URL default: `postgresql://postgres:simpledark67@localhost:5432/rana_pos`
   - Jika password beda, edit file `server/.env`.
2. Jalankan script **`start_server.bat`** (double click).
3. Tunggu sampai muncul pesan "Server is running on port 4000".

## 2. Persiapan Mobile App
Lokasi file config: `mobile_buyer/lib/config/api_config.dart`

### Opsi A: Menggunakan Emulator Android (Bawaan Android Studio)
- Tidak perlu setting apa-apa.
- Aplikasi otomatis konek ke `http://10.0.2.2:4000` (Localhost via Emulator).

### Opsi B: Menggunakan HP Fisik (Real Device)
1. Pastikan HP dan Laptop konek ke **WiFi yang sama**.
2. Cek IP Address Laptop:
   - Buka CMD, ketik `ipconfig`.
   - Cari **IPv4 Address** (Contoh: `192.168.1.8`).
3. Edit file `mobile_buyer/lib/config/api_config.dart`:
   ```dart
   static const String _localIp = '192.168.1.8'; // Masukkan IP Laptop Anda
   ```
4. Jalankan aplikasi di HP (`flutter run`).

## 3. Troubleshooting
- **Server Error (Database):** Pastikan service PostgreSQL nyala. Cek password di `.env`.
- **Aplikasi tidak bisa login (Network Error):**
  - Matikan Firewall Windows sementara.
  - Pastikan IP Address di `api_config.dart` sudah benar.
  - Coba buka browser di HP, akses `http://192.168.1.8:4000`. Jika muncul "Rana POS Server is Running", berarti koneksi aman.

## 4. Reset Data (Opsional)
Jika ingin mereset database ke kondisi awal:
1. Buka terminal di folder `server`.
2. Jalankan:
   ```bash
   npx prisma migrate reset
   npm run seed:ppob
   npm run seed:menus
   ```
