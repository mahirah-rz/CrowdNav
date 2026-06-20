import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_gate.dart';
import 'pages/announcements_page.dart';
import 'pages/bus_tracking_page.dart';
import 'pages/complaint_page.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: 'https://kqsaszkjqbbfhkjmofmw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxc2FzemtqcWJiZmhram1vZm13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MjQ5MzAsImV4cCI6MjA5MzQwMDkzMH0.1i8NpPJ1TqlumuKtJbfUH9j3qjRHqym_gkkJxRb0Qmw',
  );

  await NotificationService.initialize(navigatorKey: navigatorKey);

  runApp(const CrowdNavApp());
}

class CrowdNavApp extends StatelessWidget {
  const CrowdNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrowdNav',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2ECC71),
          secondary: Color(0xFF1E8449),
          surface: Color(0xFFECF0F1),
        ),
        scaffoldBackgroundColor: const Color(0xFFECF0F1),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E8449),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/announcements': (_) => const AnnouncementsPage(),
        '/bus': (_) => const BusTrackingPage(),
        '/complaints': (_) => const ComplaintPage(),
      },
    );
  }
}