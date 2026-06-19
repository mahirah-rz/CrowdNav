# CrowdNav MainActivity Crash Fix

This build fixes the Android startup crash:

`ClassNotFoundException: io.crowdnav.app.MainActivity`

The fix aligns `MainActivity.kt` package with Android `namespace` and `applicationId`:

- `namespace = "io.crowdnav.app"`
- `applicationId = "io.crowdnav.app"`
- `package io.crowdnav.app` in `MainActivity.kt`
- file path: `android/app/src/main/kotlin/io/crowdnav/app/MainActivity.kt`

Before installing this APK, uninstall the old crashing app:

```powershell
adb uninstall io.crowdnav.app
```

Then build:

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define=CROWDNAV_BACKEND_URL=https://crowdnav-backend.onrender.com
```
