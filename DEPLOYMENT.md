# Panduan Deployment Lengkap Rana Market (Production)

Dokumen ini adalah panduan teknis mendalam untuk men-deploy Rana Market ke lingkungan produksi. Panduan ini mencakup persiapan server, konfigurasi database, integrasi layanan pihak ketiga (API Keys), dan perilisan aplikasi mobile.

---

## 🏗️ Arsitektur Sistem

*   **Backend**: Node.js (Express.js) + Prisma ORM.
*   **Database**: PostgreSQL.
*   **Web Server**: Nginx (Reverse Proxy).
*   **Mobile App**: Flutter (Android/iOS).
*   **Process Manager**: PM2.
*   **Integrasi Pihak Ketiga**:
    *   **Digiflazz**: Untuk layanan PPOB (Pulsa, Token Listrik).
    *   **OpenStreetMap**: Untuk peta lokasi.
    *   **WhatsApp Gateway** (Opsional): Untuk notifikasi pesanan.

---

## 🖥️ BAGIAN 1: Server Deployment (VPS)

### 1. Persiapan Server
Rekomendasi: Ubuntu 20.04/22.04 LTS, RAM minimal 2GB.

Login ke VPS Anda:
```bash
ssh root@ip_server_anda
```

Update & Install Dependencies Utama:
```bash
# Update System
sudo apt update && sudo apt upgrade -y

# Install Node.js v18 (LTS)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Database & Web Server
sudo apt install -y postgresql postgresql-contrib nginx git certbot python3-certbot-nginx

# Install Process Manager
sudo npm install -g pm2
```

### 2. Setup Database PostgreSQL
```bash
# Masuk ke user postgres
sudo -i -u postgres

# Masuk console psql
psql
```

Jalankan query SQL berikut (GANTI `password_super_rahasia` dengan password kuat Anda):
```sql
CREATE DATABASE rana_market;
CREATE USER rana_user WITH ENCRYPTED PASSWORD 'password_super_rahasia';
GRANT ALL PRIVILEGES ON DATABASE rana_market TO rana_user;
ALTER DATABASE rana_market OWNER TO rana_user;
\q
```
Keluar dari user postgres: `exit`

### 3. Setup Aplikasi Backend
Clone atau upload source code ke `/var/www/rana-server`.

```bash
cd /var/www/rana-server
# Jika folder belum ada, buat dulu atau git clone
```

Install library project:
```bash
npm install
```

### 4. Konfigurasi Environment Variables (.env)
Ini adalah langkah **KRUSIAL**. Buat file `.env` di root folder server.

```bash
nano .env
```

Salin dan sesuaikan konfigurasi di bawah ini:

```env
# --- SERVER CONFIG ---
PORT=4000
NODE_ENV=production

# --- DATABASE ---
# Format: postgresql://USER:PASSWORD@HOST:PORT/DB_NAME?schema=public
DATABASE_URL="postgresql://rana_user:password_super_rahasia@localhost:5432/rana_market?schema=public"

# --- SECURITY ---
# Kunci rahasia untuk enkripsi token JWT. Ganti dengan string acak panjang.
JWT_SECRET="ganti_ini_dengan_random_string_minimal_32_karakter_!@#$"
# (Opsional) Kunci enkripsi settings di DB jika berbeda dari JWT_SECRET
SETTINGS_ENCRYPTION_KEY="ganti_ini_juga_dengan_kunci_lain"

# --- DIGIFLAZZ (PPOB) ---
# Daftar di https://member.digiflazz.com/
DIGIFLAZZ_USERNAME="username_digiflazz_anda"
DIGIFLAZZ_API_KEY="api_key_production_anda"
# Mode: 'development' (untuk testing) atau 'production' (transaksi asli)
DIGIFLAZZ_MODE="production" 
# Base URL API (biasanya tidak perlu diubah)
DIGIFLAZZ_BASE_URL="https://api.digiflazz.com/v1"
# Markup Global (Keuntungan per transaksi)
DIGIFLAZZ_MARKUP_FLAT="500"      # Tambah Rp 500 per transaksi
DIGIFLAZZ_MARKUP_PERCENT="0"     # Atau gunakan persen

# --- WHATSAPP (Opsional) ---
# Jika menggunakan layanan gateway pihak ketiga
WA_GATEWAY_URL="https://api.fonnte.com/send"
WA_API_KEY="api_key_fonnte_anda"
```

Simpan file (`Ctrl+X` > `Y` > `Enter`).

### 5. Migrasi Database & Build
Terapkan struktur tabel ke database baru Anda.

```bash
npx prisma generate
npx prisma migrate deploy

# (Opsional) Isi data awal PPOB & Menu Standar
npm run seed:ppob
npm run seed:menus
```

### 6. Jalankan dengan PM2
Agar aplikasi berjalan terus menerus di background.

```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
# Copy paste perintah yang muncul dari output 'pm2 startup'
```

### 7. Konfigurasi Domain & SSL (Nginx)
Edit file konfigurasi Nginx yang sudah disiapkan di `deploy/nginx.conf` jika perlu, lalu aktifkan.

```bash
# Edit server_name sesuai domain Anda
nano deploy/nginx.conf

# Copy ke Nginx
sudo cp deploy/nginx.conf /etc/nginx/sites-available/rana-market
sudo ln -s /etc/nginx/sites-available/rana-market /etc/nginx/sites-enabled/

# Test & Restart
sudo nginx -t
sudo systemctl restart nginx

# Pasang SSL Gratis (HTTPS)
sudo certbot --nginx -d api.ranamarket.com
```

---

## 🔌 BAGIAN 2: Integrasi Layanan Pihak Ketiga (API Keys)

### 1. Digiflazz (PPOB)
Layanan ini digunakan untuk penjualan pulsa, paket data, dan token listrik.
1.  **Daftar**: Buka [Member Digiflazz](https://member.digiflazz.com/) dan daftar akun.
2.  **Topup**: Isi saldo deposit agar bisa bertransaksi.
3.  **API Key**:
    *   Masuk ke menu **Pengaturan API**.
    *   Minta **Production Key**.
    *   **PENTING**: Anda harus mendaftarkan **IP Public VPS** Anda di whitelist IP Digiflazz agar transaksi tidak ditolak.
4.  Masukkan Username & API Key ke file `.env` di server (lihat langkah BAGIAN 1 poin 4).

### 2. WhatsApp Gateway (Notifikasi)
Saat ini sistem menggunakan mock (console log). Untuk mengaktifkan notifikasi WA asli:
1.  Pilih provider (contoh: Fonnte, Twilio, atau Watzap.id).
2.  Daftar dan dapatkan API Key.
3.  Edit file `d:\rana\server\src\services\whatsappService.js` dan implementasikan request HTTP ke provider tersebut di fungsi `sendWhatsApp`.

### 3. Peta (OpenStreetMap)
Aplikasi menggunakan OpenStreetMap yang gratis dan tidak memerlukan API Key. Namun untuk fitur pencarian lokasi, aplikasi menggunakan URL Scheme Google Maps yang juga gratis.
*   Tidak ada konfigurasi API Key yang diperlukan untuk peta saat ini.

---

## 📱 BAGIAN 3: Deployment Mobile App (Android)

### 1. Menghubungkan Aplikasi ke Server Production
Agar aplikasi mobile mengakses server VPS Anda, bukan localhost.

**Cara A: Edit `api_config.dart` (Permanen)**
Buka `d:\rana\mobile_buyer\lib\config\api_config.dart`:
Ubah variabel `_prodUrl`:
```dart
static const String _prodUrl = 'https://api.ranamarket.com/api'; // Ganti dengan domain Anda
```

**Cara B: Menggunakan Build Arguments (Fleksibel)**
Anda bisa menyuntikkan URL saat build tanpa mengubah kode.
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.ranamarket.com/api
```

### 2. Generate Keystore (Signing Key)
Lakukan ini sekali seumur hidup aplikasi. Simpan file `.jks` di tempat aman (Google Drive/Brankas).

```powershell
cd d:\rana\mobile_buyer
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Update `d:\rana\mobile_buyer\android\key.properties`:
```properties
storePassword=password_anda
keyPassword=password_anda
keyAlias=upload
storeFile=../../upload-keystore.jks
```

### 3. Build & Release
1.  **Ganti App ID** (Opsional tapi disarankan):
    *   Edit `android/app/build.gradle`: `applicationId "com.namaanda.ranamarket"`
2.  **Ganti Nama Aplikasi**:
    *   Edit `android/app/src/main/AndroidManifest.xml`: `android:label="Nama Toko Anda"`
3.  **Build App Bundle**:
    ```bash
    flutter clean
    flutter pub get
    flutter build appbundle --release
    ```
4.  File `build/app/outputs/bundle/release/app-release.aab` siap diupload ke Google Play Console.

---

## 🛠️ BAGIAN 4: Monitoring & Maintenance

### Cek Status Server
```bash
pm2 status
pm2 logs rana-server
```

### Backup Database
Buat cronjob untuk backup rutin.
```bash
# Contoh backup manual
pg_dump -U rana_user -h localhost rana_market > backup_rana_$(date +%F).sql
```

### Update Aplikasi (Server)
Jika ada perubahan kode di server:
```bash
cd /var/www/rana-server
git pull origin main
npm install
npx prisma migrate deploy
pm2 restart rana-server
```

### Update Aplikasi (Mobile)
Jika ada update fitur mobile:
1.  Naikkan versi di `pubspec.yaml` (contoh: `version: 1.0.1+2`).
2.  Build ulang `.aab`.
3.  Upload versi baru ke Play Store.
