# CrowdNav clean setup and deployment guide

Follow these steps from a fresh folder. Do not use a folder that contains Git merge conflicts.

## 1) Install required tools

Install Flutter, Git, Android Studio/SDK, and JDK 17. On Windows CMD/PowerShell as Administrator:

```cmd
winget install -e --id EclipseAdoptium.Temurin.17.JDK
winget install -e --id Git.Git
```

Close and reopen VS Code after installing JDK 17.

Check:

```cmd
java -version
flutter doctor
```

Java must show version 17.

## 2) Setup Supabase database

Open Supabase Dashboard -> SQL Editor -> New Query. Paste and run:

```text
sql/supabase_schema_and_rls.sql
```

Then create your first admin manually in Supabase:

1. Register in the app or create a user from Supabase Auth.
2. Open Table Editor -> profiles.
3. Set that user's `role` column to `admin`.

## 3) Setup Firebase

1. Firebase Console -> create/open project.
2. Add Android app with package name: `io.crowdnav.app`.
3. Download `google-services.json`.
4. Put it here:

```text
android/app/google-services.json
```

5. Firebase Console -> Project Settings -> Service accounts -> Generate new private key.
6. Save it locally as:

```text
backend/firebase-service-account.json
```

Never upload this service account JSON to GitHub.

## 4) Run backend locally for testing

```cmd
cd backend
python -m venv .venv
.venv\Scripts\activate.bat
pip install -r requirements.txt
copy .env.example .env
notepad .env
```

Fill `.env` with real values:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-new-service-role-key
FIREBASE_SERVICE_ACCOUNT_JSON=backend/firebase-service-account.json
CROWDNAV_BACKEND_ADMIN_TOKEN=your-random-token
```

Run backend:

```cmd
python -m uvicorn fcm_server:app --env-file .env --host 0.0.0.0 --port 8000
```

Open:

```text
http://127.0.0.1:8000/docs
```

## 5) Deploy backend online on Render

Push this clean project to GitHub first. In Render:

- New -> Web Service
- Root Directory: `backend`
- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn fcm_server:app --host 0.0.0.0 --port $PORT`

Add environment variables:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-new-service-role-key
FIREBASE_SERVICE_ACCOUNT_JSON=/etc/secrets/firebase-service-account.json
CROWDNAV_BACKEND_ADMIN_TOKEN=your-random-token
```

Add Render Secret File:

- Filename: `firebase-service-account.json`
- Content: paste the full Firebase service account JSON

After deploy, test:

```text
https://your-render-backend-url.onrender.com/health
https://your-render-backend-url.onrender.com/docs
```

## 6) Build release APK with online backend URL

From project root:

```cmd
flutter clean
flutter pub get
flutter build apk --release --dart-define=CROWDNAV_BACKEND_URL=https://your-render-backend-url.onrender.com
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Share this APK with students. After backend is online, no USB and no `adb reverse` are needed.

## 7) Test flow

1. Install APK on phone.
2. Register/login.
3. Complete profile.
4. Allow notifications.
5. Check Supabase -> `device_tokens` has a row.
6. Login as admin.
7. Post an announcement.
8. Check Supabase -> `announcements.sent_push = true` and push counts.

## 8) Security reminder

If any service-role key or Firebase Admin JSON was exposed, rotate/regenerate it before deployment.

Do not commit:

- `backend/.env`
- `backend/firebase-service-account.json`
- `.jks` / `.keystore`
- `android/key.properties`
