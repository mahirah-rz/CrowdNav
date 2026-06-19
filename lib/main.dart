import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'pages/announcements_page.dart';
import 'pages/bus_tracking_page.dart';
import 'pages/complaint_page.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('CrowdNav Flutter error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('CrowdNav platform error: $error');
    return true;
  };

  await runZonedGuarded<Future<void>>(() async {
    await _initializeCoreServicesSafely();
    runApp(const CrowdNavApp());
  }, (Object error, StackTrace stack) {
    debugPrint('CrowdNav uncaught zone error: $error');
  });
}

Future<void> _initializeCoreServicesSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  try {
    await NotificationService.initialize(navigatorKey: navigatorKey);
  } catch (e) {
    // Notifications must never stop the app from opening.
    debugPrint('Notification setup skipped: $e');
  }
}

class CrowdNavApp extends StatelessWidget {
  const CrowdNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrowdNav',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      routes: {
        '/announcements': (_) => const AnnouncementsPage(),
        '/complaints': (_) => const ComplaintPage(),
        '/bus': (_) => const BusTrackingPage(),
      },
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
    );
  }
}
