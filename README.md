# CrowdNav

CrowdNav is a Flutter-based smart campus mobility app for Leading University. It includes authentication/profile management, real-time bus tracking, announcements, complaints, weather/safety pages, Firebase Cloud Messaging push notifications, and a FastAPI backend for admin announcement delivery.

## Main folders

- `lib/` - Flutter app source code
- `android/` - Android project files
- `backend/` - FastAPI notification backend for FCM
- `sql/` - Supabase schema and RLS setup

## Required services

- Supabase project with Auth and PostgreSQL
- Firebase project with Android app and Cloud Messaging
- Render/Railway/Fly/VPS for deploying `backend/`

## Build target

Final target: release APK + online backend URL + no USB/ADB needed.
