import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'home_page.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'announcements_page.dart';
import 'complaint_page.dart';
import 'profile_page.dart';
import 'safety_page.dart';
import 'weather_page.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  UserModel? _driver;
  bool _loadingProfile = true;
  bool _isBroadcasting = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _uploadTimer;
  String? _errorMessage;
  DateTime? _lastUpload;
  int _currentIndex = 0;

  String _selectedRoute = 'Route 1 – Tilagor';
  final List<String> _routes = const [
    'Route 1 – Tilagor',
    'Route 2 – Surma Tower',
    'Route 3 – Lakkatura',
    'Route 4 – Tilagor (via Bypass)',
  ];

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _stopBroadcasting(updateUi: false);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await SupabaseService.getProfile();
    if (!mounted) return;
    setState(() {
      _driver = user;
      if (user?.assignedRoute != null && _routes.contains(user!.assignedRoute)) {
        _selectedRoute = user.assignedRoute!;
      }
      _loadingProfile = false;
    });
  }

  Future<bool> _checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorMessage = 'Location services are disabled. Please enable GPS.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = 'Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _errorMessage = 'Location permission permanently denied. Enable it in device settings.');
      return false;
    }

    return true;
  }

  Future<void> _startBroadcasting() async {
    setState(() => _errorMessage = null);
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    setState(() => _isBroadcasting = true);

    try {
      final firstPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() => _currentPosition = firstPosition);
        await _uploadLocation(firstPosition);
      }
    } catch (_) {}

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (position) {
        if (mounted) {
          setState(() => _currentPosition = position);
          _mapController.move(LatLng(position.latitude, position.longitude), 16);
        }
        _uploadLocation(position);
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'GPS error: ${e.toString()}';
            _isBroadcasting = false;
          });
        }
      },
    );

    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final position = _currentPosition;
      if (position != null) await _uploadLocation(position);
    });
  }

  Future<void> _uploadLocation(Position position) async {
    try {
      await SupabaseService.updateBusLocation(
        busId: _driver?.id ?? 'unknown',
        lat: position.latitude,
        lng: position.longitude,
        routeName: _selectedRoute,
        driverName: _driver?.name ?? 'Driver',
        driverPhone: _driver?.phone ?? '',
        speedKmph: position.speed >= 0 ? position.speed * 3.6 : null,
        heading: position.heading >= 0 ? position.heading : null,
      );
      if (mounted) setState(() => _lastUpload = DateTime.now());
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Upload failed: ${e.toString()}');
    }
  }

  void _stopBroadcasting({bool updateUi = true}) {
    _positionStream?.cancel();
    _positionStream = null;
    _uploadTimer?.cancel();
    _uploadTimer = null;
    if (_driver != null) {
      SupabaseService.clearBusLocation(_driver!.id);
    }
    if (updateUi && mounted) {
      setState(() {
        _isBroadcasting = false;
        _currentPosition = null;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Do you want to logout from the driver portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    _stopBroadcasting();
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt).inSeconds;
    if (diff < 60) return '${diff}s ago';
    return '${(diff / 60).floor()}m ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E8449),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text('Driver Portal', style: GoogleFonts.inter()),
              backgroundColor: const Color(0xFF1E8449),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: _confirmLogout,
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildBroadcastTab(),
          const AnnouncementsPage(),
          const WeatherPage(),
          const SafetyPage(),
          const ComplaintPage(),
          ProfilePage(onProfileUpdated: _loadProfile),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.gps_fixed), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Notice'),
          NavigationDestination(icon: Icon(Icons.cloud_outlined), label: 'Weather'),
          NavigationDestination(icon: Icon(Icons.emergency_outlined), label: 'SOS'),
          NavigationDestination(icon: Icon(Icons.report_problem_outlined), label: 'Help'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBroadcastTab() {
    return Column(
      children: [
        _buildStatusBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                _buildDriverCard(),
                const SizedBox(height: 22),
                _buildRouteSelector(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBox(),
                ],
                const SizedBox(height: 22),
                if (_currentPosition != null) ...[
                  _buildMapCard(),
                  const SizedBox(height: 22),
                ],
                _buildStartStopButton(),
                const SizedBox(height: 16),
                _buildHint(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _isBroadcasting
          ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _isBroadcasting ? const Color(0xFF2ECC71) : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isBroadcasting ? 'Broadcasting live location' : 'Location sharing is OFF',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isBroadcasting ? const Color(0xFF1E8449) : Colors.grey[600],
              ),
            ),
          ),
          if (_isBroadcasting)
            Text(
              'Last sync: ${_formatTime(_lastUpload)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF2ECC71).withValues(alpha: 0.15),
            backgroundImage: (_driver?.avatarUrl ?? '').isNotEmpty
                ? NetworkImage(_driver!.avatarUrl!)
                : null,
            child: (_driver?.avatarUrl ?? '').isEmpty
                ? const Icon(Icons.directions_bus_rounded, size: 40, color: Color(0xFF1E8449))
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            _driver?.name ?? 'Driver',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'DRIVER',
              style: TextStyle(
                color: Color(0xFF1E8449),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Route',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _routes.contains(_selectedRoute) ? _selectedRoute : _routes.first,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFECF0F1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.route, color: Color(0xFF1E8449)),
            ),
            selectedItemBuilder: (context) => _routes
                .map(
                  (route) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(route, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            items: _routes
                .map(
                  (route) => DropdownMenuItem(
                    value: route,
                    child: Text(route, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _isBroadcasting
                ? null
                : (value) => setState(() => _selectedRoute = value ?? _routes.first),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    final pos = _currentPosition!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(pos.latitude, pos.longitude),
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.crowdnav.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(pos.latitude, pos.longitude),
                  width: 60,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E8449),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E8449),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartStopButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isBroadcasting ? () => _stopBroadcasting() : _startBroadcasting,
        icon: Icon(_isBroadcasting ? Icons.stop_circle_outlined : Icons.gps_fixed, size: 22),
        label: Text(
          _isBroadcasting ? 'Stop Broadcasting' : 'Start Broadcasting',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isBroadcasting ? Colors.redAccent : const Color(0xFF2ECC71),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Text(
      _isBroadcasting
          ? 'Keep this page while sharing location.'
          : 'Choose your route and start broadcasting when the bus starts.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.w600),
    );
  }
}
