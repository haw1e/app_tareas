Release and Deployment Guide

1) Deploy Admin Backend (required for admin operations)

- Edit `server/index.js` env and deploy to a secure host (Heroku, Vercel, Render, DigitalOcean):
  - Set `SUPABASE_URL` to your Supabase project URL (e.g. https://tranonwmjqfnhxluwngt.supabase.co)
  - Set `SUPABASE_SERVICE_ROLE_KEY` to your Service Role Key (keep secret)
  - Set `ADMIN_API_KEY` to a strong random string (shared secret)

- Local run for testing:
```bash
cd server
npm install
ADMIN_API_KEY=your_admin_key SUPABASE_URL=https://your.supabase.co SUPABASE_SERVICE_ROLE_KEY=service_role_key node index.js
```

- After deployment note the public URL (e.g. https://my-admin.example)

2) Configure mobile app to call Admin API

- Open `lib/core/config.dart` and set:
  - `adminApiUrl` to your deployed admin API root (e.g. 'https://my-admin.example')
  - `adminApiKey` to the `ADMIN_API_KEY` you configured on the server (for development only)

  Note: embedding `adminApiKey` in the app is convenient for small teams but less secure. For production, consider implementing user-based auth to protect admin actions.

3) Android signing (generate a release keystore)

- Generate keystore (replace paths/passwords as desired):
```bash
keytool -genkey -v -keystore android/app/my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

- Move `my-release-key.jks` into `android/app/`.
- Create `android/key.properties` (do NOT commit to VCS) with:
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=key
storeFile=android/app/my-release-key.jks
```

- Ensure `android/app/build.gradle` contains signing config (Flutter template usually includes it). If not, add the signingConfigs block using `key.properties`.

4) Build signed APK

- Clean and get packages:
```bash
flutter clean
flutter pub get
```

- Build release APK:
```bash
flutter build apk --release
```

- The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

5) Test and distribute

- Install on a test device and verify:
  - Login persists between app restarts
  - App can read/write tasks to Supabase
  - Admin actions that require the admin API work (create worker, delete all tasks) — ensure `lib/core/config.dart` points to deployed admin API and `adminApiKey` is set for testing

- Distribute the signed APK to workers or upload an App Bundle to Google Play.

If you want, I can:
- Add a small script to `.github/workflows` to build the APK automatically.
- Help configure a deployment on Heroku or Render for the admin API.
- Show the exact `build.gradle` signing snippet to paste.

Tell me which of these you'd like next.