# Deployment Guide - Rana Merchant Platform

This guide covers the steps to deploy the backend, admin dashboard, and mobile application for production.

## 1. Backend Server (Node.js)

### Prerequisites
- A VPS (Virtual Private Server) or Cloud Provider (AWS, Google Cloud, DigitalOcean, Heroku, Railway).
- PostgreSQL Database (Managed or self-hosted).
- Node.js v18+ installed on the server.

### Environment Setup
1. Copy your `.env` file to the server.
2. Update the variables for production:
   ```env
   PORT=4000
   DATABASE_URL="postgresql://user:password@host:5432/rana_db?schema=public"
   JWT_SECRET="YOUR_STRONG_PRODUCTION_SECRET"
   NODE_ENV="production"
   ```

### Deployment Steps
1. **Upload Code**: Git clone your repo to the server.
2. **Install Dependencies**:
   ```bash
   cd server
   npm install --production
   ```
3. **Database Migration**:
   ```bash
   npx prisma migrate deploy
   ```
4. **Start Server**:
   Use a process manager like **PM2** to keep the server alive.
   ```bash
   npm install -g pm2
   pm2 start src/index.js --name "rana-api"
   pm2 save
   ```

---

## 2. Admin Client (React/Vite)

### Build Configuration
1. Create a `.env.production` file in `admin_client/`:
   ```env
   VITE_API_URL=https://api.yourdomain.com/api
   ```
   *(Replace with your actual backend domain)*.

### Deployment Steps
1. **Build**:
   ```bash
   cd admin_client
   npm install
   npm run build
   ```
   This creates a `dist` folder.

2. **Serve**:
   You can serve the `dist` folder using Nginx, Apache, or upload it to Vercel/Netlify.
   - **Netlify/Vercel**: Just drag and drop the `dist` folder or connect your Git repo.
   - **Nginx**: Point `root` location to the `dist` folder.

---

## 3. Mobile App (Flutter)

### Configuration
1. Open `mobile/lib/data/remote/api_service.dart`.
2. Set `_isProduction` to `true`.
3. Update the production URL:
   ```dart
   static const bool _isProduction = true; 
    baseUrl: _isProduction 
      ? 'https://api.yourdomain.com/api' // <--- PUT YOUR DOMAIN HERE
   ```

### Build Steps (Android)
1. **KeyStore**: Ensure you have a release signing key.
2. **Build APK**:
   ```bash
   cd mobile
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### Build Steps (iOS) - Mac Only
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Configure Signing & Capabilities (Team, Provisioning Profile).
3. Product -> Archive -> Distribute App.

---

## checklist for Go-Live
- [ ] Database backed up.
- [ ] SSL Certificates (HTTPS) installed for Server and Admin Client.
- [ ] Google Play Console Account created (for App Store submission).
- [ ] Maps API Keys restricted and billing enabled (if used).
