import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/login_page.dart';
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
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 5) _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(user: _user, onNavigate: _changeTab),
      const BusTrackingPage(),
      const NavigationPage(),
      const AnnouncementsPage(),
      const ComplaintPage(),
      ProfilePage(onProfileUpdated: _loadUser),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex], style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Emergency',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyPage())),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _signOut),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2ECC71).withOpacity(0.16),
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

class DashboardTab extends StatefulWidget {
  final UserModel? user;
  final Function(int) onNavigate;

  const DashboardTab({super.key, required this.user, required this.onNavigate});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  WeatherData? _weather;
  bool _weatherLoading = true;
  bool _dialogShown = false;

  String get _firstName {
    final name = widget.user?.name.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _loadHomeWeather();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowWeatherDialog();
  }

  Future<void> _loadHomeWeather() async {
    final data = await WeatherService.fetchWeatherByCity('Sylhet');
    if (!mounted) return;
    setState(() {
      _weather = data;
      _weatherLoading = false;
    });
    _maybeShowWeatherDialog();
  }

  void _maybeShowWeatherDialog() {
    if (_dialogShown || _weather == null || !mounted) return;
    _dialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _weather == null) return;
      final w = _weather!;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.cloud_queue_rounded, color: Color(0xFF1E8449)),
              const SizedBox(width: 8),
              Expanded(child: Text('Today\'s Weather', style: GoogleFonts.inter(fontWeight: FontWeight.w900))),
            ],
          ),
          content: Text('${w.cityName}: ${w.tempC.toStringAsFixed(0)}°C, ${w.description}.\n\n${w.commuteTip}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage()));
              },
              child: const Text('Open Weather'),
            ),
          ],
        ),
      );
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
          _buildSectionHeader('Quick Services', 'Everything you need on campus'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _QuickCard(icon: Icons.directions_bus_filled_rounded, title: 'Live Bus', subtitle: 'Driver GPS tracking', color: const Color(0xFF2E86DE), onTap: () => widget.onNavigate(1)),
              _QuickCard(icon: Icons.route_rounded, title: 'Smart Route', subtitle: 'Campus navigation', color: const Color(0xFF123D35), onTap: () => widget.onNavigate(2)),
              _QuickCard(icon: Icons.campaign_rounded, title: 'Notices', subtitle: 'Official updates', color: const Color(0xFF8E44AD), onTap: () => widget.onNavigate(3)),
              _QuickCard(icon: Icons.support_agent_rounded, title: 'Support', subtitle: 'Complaint portal', color: const Color(0xFFE67E22), onTap: () => widget.onNavigate(4)),
              _QuickCard(icon: Icons.wb_sunny_rounded, title: 'Weather', subtitle: 'Forecast and tips', color: const Color(0xFFF39C12), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage()))),
              _QuickCard(icon: Icons.emergency_share_rounded, title: 'Emergency', subtitle: 'Safety contacts', color: const Color(0xFFE74C3C), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyPage()))),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoStrip(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final role = (widget.user?.role ?? 'student').replaceAll('_', ' ').toUpperCase();
    final department = widget.user?.department ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF123D35), Color(0xFF1E6B5C)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF123D35).withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.22))),
                  child: Text(role, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Hi, $_firstName', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            department.isEmpty ? 'Navigate smarter across Leading University.' : '$department • Leading University',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroAction(label: 'Track Bus', icon: Icons.my_location_rounded, onTap: () => widget.onNavigate(1)),
              const SizedBox(width: 10),
              _HeroAction(label: 'View Notices', icon: Icons.notifications_active_rounded, onTap: () => widget.onNavigate(3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMiniCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherPage())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5))]),
        child: _weatherLoading
            ? const Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('Loading weather...')])
            : _weather == null
                ? const Row(children: [Icon(Icons.cloud_off, color: Colors.grey), SizedBox(width: 12), Expanded(child: Text('Weather unavailable. Tap to open weather page.'))])
                : Row(
                    children: [
                      Image.network(_weather!.iconUrl, width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Color(0xFF1E8449), size: 42)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_weather!.tempC.toStringAsFixed(0)}°C • ${_weather!.cityName}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
                            const SizedBox(height: 2),
                            Text(_weather!.commuteTip, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
        Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
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
              decoration: BoxDecoration(color: const Color(0xFF2ECC71).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF123D35)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Use verified profiles, live driver location, official notices, weather tips and emergency support from one app.', style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF2C3E50))),
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: const Color(0xFF123D35)),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF123D35), fontSize: 12))),
            ],
          ),
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

  const _QuickCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 28)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
