import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../auth/login_page.dart';
import 'bus_tracking_page.dart';
import 'navigation_page.dart';
import 'weather_page.dart';
import 'announcements_page.dart';
import 'profile_page.dart';
import 'safety_page.dart';
import 'complaint_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  UserModel? _user;
  bool _isLoading = true;

  bool get _isLoggedIn => SupabaseService.currentUserId != null;

  bool _isLockedGuestTab(int index) {
    
    return !_isLoggedIn && (index == 1 || index == 3 || index == 4);
  }

  String _lockedFeatureName(int index) {
    switch (index) {
      case 1:
        return 'Bus Tracking';
      case 3:
        return 'Notices';
      case 4:
        return 'Support / Complaints';
      default:
        return 'this feature';
    }
  }

  static const _appBarTitles = [
    'CrowdNav',
    'Live Bus Tracking',
    'Smart Navigation',
    'Notices',
    'Support',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await SupabaseService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Do you want to logout from CrowdNav?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await SupabaseService.signOut();
    if (!mounted) return;
    setState(() {
      _user = null;
      _currentIndex = 0;
    });
  }

  Future<void> _showLoginRequired(String featureName) async {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login required'),
        content: Text('$featureName is available after login or registration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.login),
            label: const Text('Login/Register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (goToLogin != true || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _changeTab(int index) {
    if (_isLockedGuestTab(index)) {
      _showLoginRequired(_lockedFeatureName(index));
      return;
    }

    setState(() => _currentIndex = index);
    if (index == 5) _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(user: _user, onNavigate: _changeTab, isLoggedIn: _isLoggedIn),
      const BusTrackingPage(),
      const NavigationPage(),
      const AnnouncementsPage(),
      const ComplaintPage(),
      ProfilePage(onProfileUpdated: _loadUser),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_currentIndex],
          style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined, color: Colors.white),
            tooltip: 'Emergency',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyPage()),
            ),
          ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: _confirmSignOut,
            ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2ECC71).withValues(alpha: 0.16),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus), label: 'Bus'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Support'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final UserModel? user;
  final Function(int) onNavigate;
  final bool isLoggedIn;

  const DashboardTab({
    super.key,
    required this.user,
    required this.onNavigate,
    required this.isLoggedIn,
  });

  String get _firstName {
    final name = user?.name.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: const Color(0xFF2ECC71),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildHeroCard(context),
          const SizedBox(height: 14),
          _EssentialBar(
            icon: Icons.wb_sunny_rounded,
            title: 'Weather',
            subtitle: 'Check commute-friendly weather updates',
            color: const Color(0xFFF39C12),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage())),
          ),
          const SizedBox(height: 10),
          _EssentialBar(
            icon: Icons.emergency_share_rounded,
            title: 'Emergency',
            subtitle: 'Safety contacts and emergency help',
            color: const Color(0xFFE74C3C),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyPage())),
          ),
          const SizedBox(height: 16),
          _buildInfoStrip(),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final role = (user?.role ?? 'Guest').replaceAll('_', ' ').toUpperCase();
    final department = user?.department ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123D35), Color(0xFF1E6B5C)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123D35).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(isLoggedIn ? 'Hi, $_firstName' : 'Welcome to CrowdNav', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            !isLoggedIn ? 'Your Complete LU Experience' : department.isEmpty ? 'Navigate smarter across Leading University.' : '$department • Leading University',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _HeroAction(label: 'View Notices', icon: Icons.notifications_active_rounded, onTap: () => onNavigate(3)),
        ],
      ),
    );
  }

  Widget _buildInfoStrip() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF123D35)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Use verified profiles, live driver location, official notices, weather tips and emergency support from one app.',
                style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF2C3E50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF123D35)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF123D35), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EssentialBar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EssentialBar({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E8E5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF1E8449)),
            ],
          ),
        ),
      ),
    );
  }
}
