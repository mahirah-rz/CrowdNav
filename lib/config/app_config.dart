class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kqsaszkjqbbfhkjmofmw.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxc2FzemtqcWJiZmhram1vZm13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MjQ5MzAsImV4cCI6MjA5MzQwMDkzMH0.1i8NpPJ1TqlumuKtJbfUH9j3qjRHqym_gkkJxRb0Qmw',
  );

  
 
  //--dart-define=CROWDNAV_BACKEND_URL=https://crowdnav-backend.onrender.com
  static const String backendBaseUrl = String.fromEnvironment(
    'CROWDNAV_BACKEND_URL',
    defaultValue: '',
  );

  static bool get hasBackend => backendBaseUrl.trim().isNotEmpty;
}
