# CrowdNav Stability Fixes

This build reduces crash loops, battery pressure, and phone-cache growth.

Changes included:
- Wrapped Firebase, Supabase, and notification startup with safe error handling so notification setup cannot stop the app from opening.
- Added global Flutter/platform error handling to prevent avoidable crash loops.
- Made FCM local-notification handling safe in foreground and background.
- Prevented duplicate FCM listeners.
- Reduced driver GPS pressure from high accuracy/5m to medium accuracy/25m and throttled Supabase location uploads.
- Reduced bus live polling from 15s to 30s.
- Reduced weather auto-refresh from 10 minutes to 30 minutes.
- Removed unused Android background-location, foreground-service, wake-lock, and call permissions.
- Enabled Android core library desugaring required by flutter_local_notifications.

Recommended clean install after replacing a crashing APK:

```powershell
adb uninstall io.crowdnav.app
adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

If installing manually on a phone, uninstall the old CrowdNav first or clear app storage/cache before installing the new APK.
