import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../pages/admin_page.dart';
import '../pages/driver_page.dart';
import '../pages/home_page.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting && session == null) {
          return const _SplashScreen();
        }

        if (session == null) {
          
          return const HomePage();
        }

        return FutureBuilder<UserModel?>(
          future: _loadAndSetupUser(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            if (profileSnapshot.hasError) {
              return _AuthErrorScreen(error: profileSnapshot.error.toString());
            }

            final profile = profileSnapshot.data;

            
            if (profile == null) {
              return const HomePage();
            }

            switch (profile.role.toLowerCase()) {
              case 'driver':
                return const DriverPage();
              case 'admin':
                return const AdminPage();
              default:
                return const HomePage();
            }
          },
        );
      },
    );
  }

  Future<UserModel?> _loadAndSetupUser() async {
    final profile = await SupabaseService.getProfile();

    if (profile != null) {
      await NotificationService.saveTokenToSupabase();
      await NotificationService.subscribeUserTopics(
        department: profile.department.isEmpty ? 'All' : profile.department,
        program: profile.program.isEmpty ? 'All' : profile.program,
      );
    }

    return profile;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF123D35),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_rounded, size: 64, color: Colors.white),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'CrowdNav',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String error;

  const _AuthErrorScreen({required this.error});

  Future<void> _backToLogin(BuildContext context) async {
    await SupabaseService.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Could not load your profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => _backToLogin(context),
                child: const Text('Login/Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
