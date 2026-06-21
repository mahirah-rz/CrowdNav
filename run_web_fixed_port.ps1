# Run Flutter Web on a fixed port so Google OAuth Authorized JavaScript Origin does not change each run.
# Add this origin in Google Cloud OAuth Web Client: http://localhost:58057
flutter run -d chrome --web-port=58057
