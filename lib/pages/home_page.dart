import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/weather_service.dart';
import 'announcements_page.dart';
import 'bus_tracking_page.dart';
import 'complaint_page.dart';
import 'navigation_page.dart';
import 'profile_page.dart';
import 'safety_page.dart';
import 'weather_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  UserModel? _user;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  static const _appBarTitles = [
    'CrowdNav',
    'Live Bus Tracking',
    'Smart Navigation',
    'Notices',
    'Support',
    'Profile',
  ];

  static const Set<int> _guestLockedTabs = {1, 3, 4};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await SupabaseService.getProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoggedIn = true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _isLoggedIn = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    setState(() {
      _user = null;
      _isLoggedIn = false;
      _currentIndex = 0;
    });
  }

  void _changeTab(int index) {
    if (!_isLoggedIn && _guestLockedTabs.contains(index)) {
      _showLoginRequiredDialog(_featureName(index));
      return;
    }

    setState(() => _currentIndex = index);
    if (index == 5) _loadUser();
  }

  String _featureName(int index) {
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

  void _showLoginRequiredDialog(String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF1E8449)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Login required',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Text(
          '$feature is available after login. Guest users can use Home, Map, Weather, Emergency, and Profile login/register.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 5);
              _loadUser();
            },
            icon: const Icon(Icons.person_outline, size: 18),
            label: const Text('Open Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        user: _user,
        isLoggedIn: _isLoggedIn,
        onNavigate: _changeTab,
      ),
      _isLoggedIn
          ? const BusTrackingPage()
          : _LockedFeaturePage(
              featureName: 'Bus Tracking',
              onLoginTap: () => _changeTab(5),
            ),
      const NavigationPage(),
      _isLoggedIn
          ? const AnnouncementsPage()
          : _LockedFeaturePage(
              featureName: 'Notices',
              onLoginTap: () => _changeTab(5),
            ),
      _isLoggedIn
          ? const ComplaintPage()
          : _LockedFeaturePage(
              featureName: 'Support / Complaints',
              onLoginTap: () => _changeTab(5),
            ),
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
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Emergency',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyPage()),
            ),
          ),
          IconButton(
            icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            tooltip: _isLoggedIn ? 'Logout' : 'Login / Register',
            onPressed: _isLoggedIn ? _signOut : () => _changeTab(5),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2ECC71).withOpacity(0.16),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(_isLoggedIn ? Icons.directions_bus_outlined : Icons.lock_outline),
            selectedIcon: Icon(_isLoggedIn ? Icons.directions_bus : Icons.lock),
            label: 'Bus',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(_isLoggedIn ? Icons.campaign_outlined : Icons.lock_outline),
            selectedIcon: Icon(_isLoggedIn ? Icons.campaign : Icons.lock),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(_isLoggedIn ? Icons.support_agent_outlined : Icons.lock_outline),
            selectedIcon: Icon(_isLoggedIn ? Icons.support_agent : Icons.lock),
            label: 'Support',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  final UserModel? user;
  final bool isLoggedIn;
  final Function(int) onNavigate;

  const DashboardTab({
    super.key,
    required this.user,
    required this.isLoggedIn,
    required this.onNavigate,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  WeatherData? _weather;
  bool _weatherLoading = true;

  String get _firstName {
    final name = widget.user?.name.trim() ?? '';
    if (name.isEmpty) return widget.isLoggedIn ? 'there' : 'Guest';
    return name.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _loadHomeWeather();
  }

  Future<void> _loadHomeWeather() async {
    final data = await WeatherService.fetchWeatherByCity('Sylhet');
    if (!mounted) return;
    setState(() {
      _weather = data;
      _weatherLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHomeWeather,
      color: const Color(0xFF2ECC71),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 14),
          _buildWeatherMiniCard(),
          const SizedBox(height: 18),
          _buildSectionHeader('Guest Available Services', 'Map, weather, and emergency support'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  icon: Icons.wb_sunny_rounded,
                  title: 'Weather',
                  subtitle: 'Forecast and tips',
                  color: const Color(0xFFF39C12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeatherPage()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  icon: Icons.emergency_share_rounded,
                  title: 'Emergency',
                  subtitle: 'Safety contacts',
                  color: const Color(0xFFE74C3C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetyPage()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final role = widget.isLoggedIn
        ? (widget.user?.role ?? 'student').replaceAll('_', ' ').toUpperCase()
        : 'GUEST MODE';
    final department = widget.user?.department ?? '';

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
            color: const Color(0xFF123D35).withOpacity(0.18),
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
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    role,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Hi, $_firstName',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (department.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '$department • Leading University',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _HeroAction(
            label: widget.isLoggedIn ? 'View Notices' : 'Login to View Notices',
            icon: widget.isLoggedIn ? Icons.notifications_active_rounded : Icons.lock_outline,
            onTap: () => widget.onNavigate(3),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMiniCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _weatherLoading
            ? const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading weather...'),
                ],
              )
            : _weather == null
                ? const Row(
                    children: [
                      Icon(Icons.cloud_off, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Weather unavailable. Tap to open weather page.'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Image.network(
                        _weather!.iconUrl,
                        width: 48,
                        height: 48,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.cloud,
                          color: Color(0xFF1E8449),
                          size: 42,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_weather!.tempC.toStringAsFixed(0)}°C • ${_weather!.cityName}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF123D35),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _weather!.commuteTip,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF1E8449)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF123D35),
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _LockedFeaturePage extends StatelessWidget {
  final String featureName;
  final VoidCallback onLoginTap;

  const _LockedFeaturePage({
    required this.featureName,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 52, color: Color(0xFF1E8449)),
                const SizedBox(height: 12),
                Text(
                  '$featureName Locked',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF123D35),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please login or register from Profile to access $featureName.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onLoginTap,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Open Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF123D35),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF123D35),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
