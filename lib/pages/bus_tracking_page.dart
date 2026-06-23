import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_service.dart';

const _luCenter = LatLng(24.87083280576749, 91.80471333316514);
const _dayGroups = ['Sunday to Thursday', 'Friday', 'Saturday'];

const _routes = [
  {
    'name': 'Route 1 – Tilagor',
    'shortName': 'Route 1',
    'startingLocation': 'Tilagor',
    'color': Colors.blue,
    'startingSchedule': {
      'Sunday to Thursday': [
        {'time': '8:00 AM', 'bus': 3},
        {'time': '9:00 AM', 'bus': 2},
        {'time': '10:00 AM', 'bus': 2},
        {'time': '11:00 AM', 'bus': 2},
        {'time': '12:20 PM', 'bus': 2},
        {'time': '1:30 PM', 'bus': 2},
      ],
      'Friday': [
        {'time': '8:00 AM', 'bus': 2},
        {'time': '9:00 AM', 'bus': 1},
        {'time': '10:00 AM', 'bus': 1},
        {'time': '11:00 AM', 'bus': 1},
      ],
      'Saturday': [
        {'time': '8:00 AM', 'bus': 2},
        {'time': '9:00 AM', 'bus': 2},
        {'time': '10:00 AM', 'bus': 2},
        {'time': '11:00 AM', 'bus': 2},
        {'time': '12:20 PM', 'bus': 1},
      ],
    },
    'returnSchedule': {
      'Sunday to Thursday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 2},
        {'time': '1:30 PM', 'bus': 2},
        {'time': '3:05 PM', 'bus': 1},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 4},
      ],
      'Friday': [
        {'time': '11:20 AM', 'bus': 2},
        {'time': '12:25 PM', 'bus': 1},
        {'time': '3:05 PM', 'bus': 2},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 4},
      ],
      'Saturday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 2},
        {'time': '3:05 PM', 'bus': 2},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 4},
      ],
    },
    'stops': [
      {'name': 'Tilagor', 'lat': 24.89642176189498, 'lng': 91.90042020715494},
      {'name': 'Amberkhana', 'lat': 24.90591570170803, 'lng': 91.87270285382317},
      {'name': 'Jalalabad', 'lat': 24.908983349045297, 'lng': 91.86242393034229},
      {'name': 'Subidbazar', 'lat': 24.90694663702242, 'lng': 91.8577506874772},
      {'name': 'Modina Market', 'lat': 24.91053796605808, 'lng': 91.84804495157724},
      {'name': 'Temukhi Point', 'lat': 24.9128877089896, 'lng': 91.82469036656404},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
    'fullStops': [
      'Tilagor',
      'Baluchar',
      'Amanullah',
      'TB Gate',
      'Raynogor Point',
      'Eidgah',
      'Electric Supply',
      'Cristal Rose',
      'City Girls Hostel',
      'Dorshondewry',
      'Jalalabad',
      'Subidbazar',
      'Londony Road',
      'Pathantula',
      'Modina Market (Dudhwala/Pollobi Pt.)',
      'Modina Market (Hatem Tai/Kalibari Pt.)',
      'Mount Adora Hospital',
      'Surma Gate',
      'SUST Gate',
      'Temukhi Point',
      'Rail Crossing',
      'Leading University',
      
    ],
  },
  {
    'name': 'Route 2 – Surma Tower',
    'shortName': 'Route 2',
    'startingLocation': 'Surma Tower',
    'color': Colors.green,
    'startingSchedule': {
      'Sunday to Thursday': [
        {'time': '8:00 AM', 'bus': 5},
        {'time': '9:00 AM', 'bus': 2},
        {'time': '10:00 AM', 'bus': 2},
        {'time': '11:00 AM', 'bus': 2},
        {'time': '12:20 PM', 'bus': 2},
        {'time': '1:30 PM', 'bus': 2},
      ],
      'Friday': [
        {'time': '8:00 AM', 'bus': 2},
        {'time': '9:00 AM', 'bus': 1},
        {'time': '10:00 AM', 'bus': 1},
        {'time': '11:00 AM', 'bus': 1},
      ],
      'Saturday': [
        {'time': '8:00 AM', 'bus': 2},
        {'time': '9:00 AM', 'bus': 2},
        {'time': '10:00 AM', 'bus': 2},
        {'time': '11:00 AM', 'bus': 2},
        {'time': '12:20 PM', 'bus': 1},
      ],
    },
    'returnSchedule': {
      'Sunday to Thursday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 3},
        {'time': '1:30 PM', 'bus': 2},
        {'time': '3:05 PM', 'bus': 1},
        {'time': '4:10 PM', 'bus': 2},
        {'time': '5:15 PM', 'bus': 5},
      ],
      'Friday': [
        {'time': '11:20 AM', 'bus': 4},
        {'time': '12:25 PM', 'bus': 1},
        {'time': '3:05 PM', 'bus': 4},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 5},
      ],
      'Saturday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 4},
        {'time': '3:05 PM', 'bus': 4},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 5},
      ],
    },
    'stops': [
      {'name': 'Surma Tower', 'lat': 24.890431115218927, 'lng': 91.86747836726342},
      {'name': 'Rikabibazar', 'lat': 24.89846994664977, 'lng': 91.8620346187078},
      {'name': 'Subidbazar', 'lat': 24.90694663702242, 'lng': 91.8577506874772},
      {'name': 'SUST Gate', 'lat': 24.911103020929485, 'lng': 91.83221881826707},
      {'name': 'Temukhi Point', 'lat': 24.9128877089896, 'lng': 91.82469036656404},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Kamal Bazar', 'lat': 24.881100914787325, 'lng': 91.80965493504439},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
    'fullStops': [
      'Surma Tower',
      'Parkview Point',
      'Jitu Miar Point',
      'Kuarpar Point',
      'Lamabazar',
      'Rikabibazar',
      'Radio Office',
      'Subidbazar',
      'Londony Road',
      'Pathantula',
      'Modina Market (Dudhwala/Pollobi Pt.)',
      'Modina Market (Hatem Tai/Kalibari Pt.)',
      'Mount Adora Hospital',
      'Surma Gate',
      'SUST Gate',
      'Temukhi Point',
      'Rail Crossing',
      'Leading University',
    ],
  },
  {
    'name': 'Route 3 – Lakkatura',
    'shortName': 'Route 3',
    'startingLocation': 'Lakkatura',
    'color': Colors.orange,
    'startingSchedule': {
      'Sunday to Thursday': [
        {'time': '8:00 AM', 'bus': 1},
        {'time': '9:00 AM', 'bus': 1},
        {'time': '10:00 AM', 'bus': 1},
        {'time': '11:00 AM', 'bus': 1},
        {'time': '12:20 PM', 'bus': 1},
        {'time': '1:30 PM', 'bus': 1},
      ],
      'Friday': [
        {'time': '8:00 AM', 'bus': 1},
        {'time': '9:00 AM', 'bus': 1},
        {'time': '10:00 AM', 'bus': 1},
        {'time': '11:00 AM', 'bus': 1},
      ],
      'Saturday': [
        {'time': '8:00 AM', 'bus': 1},
        {'time': '9:00 AM', 'bus': 1},
        {'time': '10:00 AM', 'bus': 1},
        {'time': '11:00 AM', 'bus': 1},
        {'time': '12:20 PM', 'bus': 1},
      ],
    },
    'returnSchedule': {
      'Sunday to Thursday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 1},
        {'time': '1:30 PM', 'bus': 1},
        {'time': '3:05 PM', 'bus': 1},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 1},
      ],
      'Friday': [
        {'time': '11:20 AM', 'bus': 0},
        {'time': '12:25 PM', 'bus': 1},
        {'time': '3:05 PM', 'bus': 1},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 1},
      ],
      'Saturday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 0},
        {'time': '3:05 PM', 'bus': 1},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 1},
      ],
    },
    'stops': [
      {'name': 'Lakkatura', 'lat': 24.924005190701795, 'lng': 91.8713503081673},
      {'name': 'Dorshondewry', 'lat': 24.905860505607578, 'lng': 91.86546685082078},
      {'name': 'Jalalabad', 'lat': 24.908983349045297, 'lng': 91.86242393034229},
      {'name': 'Subidbazar', 'lat': 24.90694663702242, 'lng': 91.8577506874772},
      {'name': 'Modina Market (Hatem Tai)', 'lat': 24.91053796605808, 'lng': 91.84804495157724},
      {'name': 'Temukhi Point', 'lat': 24.9128877089896, 'lng': 91.82469036656404},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
    'fullStops': [
      'Lakkatura',
      'Chowkidekhi Point',
      'Khashdobir',
      'Lichubagan',
      'Mazumdari Fulkolil',
      'Hotel Polash',
      'Amberkhana point',
      'Dorshondewry',
      'Jalalabad',
      'Subidbazar',
      'Londony Road',
      'Pathantula',
      'Modina Market (Dudhwala/Pollobi Pt.)',
      'Modina Market (Hatem Tai/Kalibari Pt.)',
      'Mount Adora Hospital',
      'Surma Gate',
      'SUST Gate',
      'Temukhi Point',
      'Rail Crossing',
      'Leading University',
    ],
  },
  {
    'name': 'Route 4 – Tilagor (via Bypass)',
    'shortName': 'Route 4',
    'startingLocation': 'Tilagor',
    'color': Colors.purple,
    'startingSchedule': {
      'Sunday to Thursday': [
        {'time': '8:00 AM', 'bus': 5},
        {'time': '9:00 AM', 'bus': 2},
        {'time': '10:00 AM', 'bus': 2},
        {'time': '11:00 AM', 'bus': 2},
        {'time': '12:20 PM', 'bus': 2},
        {'time': '1:30 PM', 'bus': 2},
      ],
      'Friday': [
        {'time': '8:00 AM', 'bus': 2},
        {'time': '9:00 AM', 'bus': 1},
        {'time': '10:00 AM', 'bus': 1},
        {'time': '11:00 AM', 'bus': 1},
      ],
      'Saturday': [
        {'time': '8:00 AM', 'bus': 2},
        {'time': '9:00 AM', 'bus': 2},
        {'time': '10:00 AM', 'bus': 2},
        {'time': '11:00 AM', 'bus': 2},
        {'time': '12:20 PM', 'bus': 1},
      ],
    },
    'returnSchedule': {
      'Sunday to Thursday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 2},
        {'time': '1:30 PM', 'bus': 2},
        {'time': '3:05 PM', 'bus': 1},
        {'time': '4:10 PM', 'bus': 2},
        {'time': '5:15 PM', 'bus': 5},
      ],
      'Friday': [
        {'time': '11:20 AM', 'bus': 4},
        {'time': '12:25 PM', 'bus': 1},
        {'time': '3:05 PM', 'bus': 4},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 5},
      ],
      'Saturday': [
        {'time': '11:20 AM', 'bus': 1},
        {'time': '12:25 PM', 'bus': 4},
        {'time': '3:05 PM', 'bus': 4},
        {'time': '4:10 PM', 'bus': 1},
        {'time': '5:15 PM', 'bus': 5},
      ],
    },
    'stops': [
      {'name': 'Tilagor', 'lat': 24.89642176189498, 'lng': 91.90042020715494},
      {'name': 'Mirabazar', 'lat': 24.897353487119297, 'lng': 91.88396163369961},
      {'name': 'Naiorpul', 'lat': 24.894819081818806, 'lng': 91.87864313779431},
      {'name': 'Subhanighat', 'lat': 24.890689108627267, 'lng': 91.8782110311111},
      {'name': 'Humayun Rashid Chattar', 'lat': 24.877669453023323, 'lng': 91.87555335331867},
      {'name': 'Chandirpul', 'lat': 24.86782296779714, 'lng': 91.85692396926362},
      {'name': 'Bypass', 'lat': 24.861026347547956, 'lng': 91.84611179436193},
      {'name': 'Rail Crossing', 'lat': 24.88603205369541, 'lng': 91.83054963650741},
      {'name': 'Leading University', 'lat': 24.86958215653915, 'lng': 91.80484679412363},
    ],
    'fullStops': [
      'Tilagor',
      'Hatim Ali Majar',
      'Shibgonj Point',
      'Dadapir Majar',
      'Mirabazar',
      'Naiorpul',
      'Subhanighat Point (Police Box)',
      'Rose View Point',
      'Humayun Rashid Chattar',
      'Chandirpul',
      'Bypass',
      'Rail Crossing',
      'Leading University',
      
    ],
  },
];

class BusTrackingPage extends StatefulWidget {
  const BusTrackingPage({super.key});

  @override
  State<BusTrackingPage> createState() => _BusTrackingPageState();
}

class _BusTrackingPageState extends State<BusTrackingPage> {
  int _selectedRoute = 0;
  List<Map<String, dynamic>> _busLocations = [];
  Timer? _fallbackTimer;
  RealtimeChannel? _busChannel;
  String? _selectedBusId;
  String _selectedDayGroup = _currentServiceDayGroup();

  static String _currentServiceDayGroup() {
    final weekday = DateTime.now().weekday;
    if (weekday == DateTime.friday) return 'Friday';
    if (weekday == DateTime.saturday) return 'Saturday';
    return 'Sunday to Thursday';
  }

  @override
  void initState() {
    super.initState();
    _fetchBusLocations();
    _busChannel = SupabaseService.busLocationStream(_fetchBusLocations);
    _fallbackTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchBusLocations());
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    final channel = _busChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _fetchBusLocations() async {
    try {
      final data = await SupabaseService.getBusLocations();
      if (mounted) setState(() => _busLocations = data);
    } catch (_) {}
  }

  bool _isOnline(String? updatedAt) {
    if (updatedAt == null) return false;
    final dt = DateTime.tryParse(updatedAt);
    if (dt == null) return false;
    return DateTime.now().difference(dt).inSeconds < 45;
  }

  String _lastSeen(String? updatedAt) {
    if (updatedAt == null) return 'Unknown';
    final dt = DateTime.tryParse(updatedAt);
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String _seatStatusLabel(String? status) {
    switch ((status ?? '').trim()) {
      case 'full':
        return 'Bus is full, no seat left';
      case 'almost_empty':
        return 'Bus is almost empty';
      case 'several_seats':
      default:
        return 'Bus has several seats';
    }
  }

  Color _seatStatusColor(String? status) {
    switch ((status ?? '').trim()) {
      case 'full':
        return Colors.redAccent;
      case 'almost_empty':
        return Colors.blueGrey;
      case 'several_seats':
      default:
        return const Color(0xFF2ECC71);
    }
  }

  IconData _seatStatusIcon(String? status) {
    switch ((status ?? '').trim()) {
      case 'full':
        return Icons.event_seat_outlined;
      case 'almost_empty':
        return Icons.directions_bus_filled_outlined;
      case 'several_seats':
      default:
        return Icons.airline_seat_recline_normal;
    }
  }

  Future<void> _callDriver(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  List<Map<String, dynamic>> _scheduleEntries(Map<String, dynamic> route, String scheduleKey) {
    final schedules = Map<String, dynamic>.from(route[scheduleKey] as Map);
    return List<Map<String, dynamic>>.from(schedules[_selectedDayGroup] as List);
  }

  @override
  Widget build(BuildContext context) {
    final route = Map<String, dynamic>.from(_routes[_selectedRoute]);
    final routeName = route['name'].toString();
    final stops = List<Map<String, dynamic>>.from(route['stops'] as List);
    final fullStops = List<String>.from(route['fullStops'] as List);
    final routeColor = route['color'] as Color;
    final polylinePoints = stops
        .map((s) => LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()))
        .toList();

    final routeBuses = _busLocations
        .where((b) => (b['route_name'] ?? '').toString() == routeName)
        .toList();
    final onlineBuses = routeBuses.where((b) => _isOnline(b['updated_at'] as String?)).toList();

    return Column(
      children: [
        _buildRouteSelector(),
        _buildLiveBanner(onlineBuses.length),
        Expanded(
          flex: 3,
          child: FlutterMap(
            options: const MapOptions(initialCenter: _luCenter, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crowdnav.app',
              ),
              PolylineLayer(polylines: [Polyline(points: polylinePoints, color: routeColor, strokeWidth: 4)]),
              MarkerLayer(markers: [
                ...stops.map((s) => _stopMarker(s, routeColor)),
                ...routeBuses.map(_busMarker),
              ]),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.white,
            child: RefreshIndicator(
              onRefresh: _fetchBusLocations,
              color: const Color(0xFF2ECC71),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                children: [
                  _buildRouteHeader(route),
                  if (onlineBuses.isNotEmpty) _buildDriverPanel(onlineBuses.first),
                  _buildScheduleCard(
                    title: 'Starting from ${route['startingLocation']}',
                    subtitle: '${route['startingLocation']} → Leading University',
                    icon: Icons.north_east_rounded,
                    color: routeColor,
                    entries: _scheduleEntries(route, 'startingSchedule'),
                  ),
                  const SizedBox(height: 10),
                  _buildScheduleCard(
                    title: 'Return from Leading University',
                    subtitle: 'Closing return time: 5:15 PM',
                    icon: Icons.south_west_rounded,
                    color: const Color(0xFF123D35),
                    entries: _scheduleEntries(route, 'returnSchedule'),
                  ),
                  const SizedBox(height: 14),
                  _buildStopList(fullStops, routeColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSelector() {
    return Container(
      height: 58,
      color: const Color(0xFFF4F7F6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _routes.length,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        itemBuilder: (context, i) {
          final selected = i == _selectedRoute;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedRoute = i;
              _selectedBusId = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF123D35) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? const Color(0xFF123D35) : const Color(0xFFE1E8E5)),
              ),
              alignment: Alignment.center,
              child: Text(
                _routes[i]['shortName'].toString(),
                style: TextStyle(color: selected ? Colors.white : const Color(0xFF123D35), fontWeight: FontWeight.w800),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveBanner(int count) {
    final hasLive = count > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: hasLive ? const Color(0xFF2ECC71).withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(hasLive ? Icons.sensors : Icons.info_outline, size: 16, color: hasLive ? const Color(0xFF123D35) : Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasLive ? '$count live bus${count == 1 ? '' : 'es'} on this route' : 'No driver is broadcasting on this route right now',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasLive ? const Color(0xFF123D35) : Colors.orange.shade800),
            ),
          ),
          TextButton.icon(
            onPressed: _fetchBusLocations,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: hasLive ? const Color(0xFF123D35) : Colors.orange.shade800,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Marker _stopMarker(Map<String, dynamic> stop, Color routeColor) {
    return Marker(
      point: LatLng((stop['lat'] as num).toDouble(), (stop['lng'] as num).toDouble()),
      width: 52,
      height: 52,
      child: Column(
        children: [
          Icon(Icons.location_on, color: routeColor, size: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Text(stop['name'].toString(), style: const TextStyle(fontSize: 8), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Marker _busMarker(Map<String, dynamic> b) {
    final online = _isOnline(b['updated_at'] as String?);
    final busId = (b['bus_id'] ?? '').toString();
    final isSelected = busId == _selectedBusId;
    final driverName = (b['driver_name'] ?? 'Driver').toString();
    final phone = (b['driver_phone'] ?? '').toString();

    return Marker(
      point: LatLng((b['latitude'] as num).toDouble(), (b['longitude'] as num).toDouble()),
      width: 96,
      height: isSelected ? 102 : 58,
      child: GestureDetector(
        onTap: () => setState(() => _selectedBusId = isSelected ? null : busId),
        child: Column(
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6)],
                ),
                child: Column(
                  children: [
                    Text(driverName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    Text(
                      _seatStatusLabel(b['seat_status'] as String?),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: _seatStatusColor(b['seat_status'] as String?), fontWeight: FontWeight.w800),
                    ),
                    if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 9, color: Color(0xFF123D35))),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: online ? Colors.redAccent : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.directions_bus, color: Colors.white, size: 19),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: online ? Colors.redAccent : Colors.grey, borderRadius: BorderRadius.circular(4)),
              child: Text(online ? 'LIVE' : 'OFF', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader(Map<String, dynamic> route) {
    final isToday = _selectedDayGroup == _currentServiceDayGroup();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  route['name'].toString(),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF123D35)),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2ECC71).withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF123D35))),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedDayGroup,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Schedule day',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.calendar_month, color: Color(0xFF123D35), size: 20),
            ),
            items: _dayGroups.map((day) => DropdownMenuItem(value: day, child: Text(day, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedDayGroup = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverPanel(Map<String, dynamic> bus) {
    final driverName = (bus['driver_name'] ?? 'Driver').toString();
    final phone = (bus['driver_phone'] ?? '').toString();
    final speed = bus['speed_kmph'] == null ? null : (bus['speed_kmph'] as num).toDouble();
    final speedText = speed == null ? '' : ' • ${speed.toStringAsFixed(1)} km/h';
    final seatStatus = (bus['seat_status'] ?? 'several_seats').toString();
    final seatColor = _seatStatusColor(seatStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE1E8E5))),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFF123D35), child: Icon(Icons.person_pin_circle, color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF123D35))),
                Text('Updated ${_lastSeen(bus['updated_at'] as String?)}$speedText', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: seatColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: seatColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_seatStatusIcon(seatStatus), size: 13, color: seatColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _seatStatusLabel(seatStatus),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: seatColor, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF123D35))),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              tooltip: 'Call driver',
              onPressed: () => _callDriver(phone),
              icon: const Icon(Icons.call, color: Color(0xFF2ECC71)),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> entries,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries.map((entry) {
              final count = entry['bus'] as int;
              return _TimeChip(
                time: entry['time'].toString(),
                busLabel: '$count bus${count == 1 ? '' : 'es'}',
                color: color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStopList(List<String> stops, Color routeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pin_drop_rounded, color: routeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bus Stoppage Points',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF123D35)),
                ),
              ),
              Text('${stops.length} stops', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(stops.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == stops.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: routeColor.withValues(alpha: 0.14),
                    child: Text('${index + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: routeColor)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stops[index],
                      style: const TextStyle(fontSize: 12, height: 1.25, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.busLabel, required this.color});

  final String time;
  final String busLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          Text(busLabel, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
