import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';

const _luCenter = LatLng(24.87083280576749, 91.80471333316514);

const _routes = [
  {
    'name': 'Route 1 – Tilagor',
    'color': Colors.blue,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
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
  },
  {
    'name': 'Route 2 – Surma Tower',
    'color': Colors.green,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
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
  },
  {
    'name': 'Route 3 – Lakkatura',
    'color': Colors.orange,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
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
  },
  {
    'name': 'Route 4 – Tilagor (via Bypass)',
    'color': Colors.purple,
    'schedule': '8:00 | 9:00 | 10:00 | 11:00 | 12:20',
    'return': '11:20 | 12:25 | 1:30 | 3:05 | 4:10',
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

  @override
  void initState() {
    super.initState();
    _fetchBusLocations();
    _busChannel = SupabaseService.busLocationStream(_fetchBusLocations);
    _fallbackTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchBusLocations());
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

  Future<void> _callDriver(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _routes[_selectedRoute];
    final routeName = route['name'].toString();
    final stops = List<Map<String, dynamic>>.from(route['stops'] as List);
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
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRouteHeader(route),
                if (onlineBuses.isNotEmpty) _buildDriverPanel(onlineBuses.first),
                Expanded(child: _buildStopList(stops, route, routeColor)),
              ],
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
                'Route ${i + 1}',
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
      color: hasLive ? const Color(0xFF2ECC71).withOpacity(0.12) : Colors.orange.withOpacity(0.12),
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
        ],
      ),
    );
  }

  Marker _stopMarker(Map<String, dynamic> stop, Color routeColor) {
    return Marker(
      point: LatLng((stop['lat'] as num).toDouble(), (stop['lng'] as num).toDouble()),
      width: 46,
      height: 46,
      child: Column(
        children: [
          Icon(Icons.location_on, color: routeColor, size: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            color: Colors.white,
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
      height: isSelected ? 88 : 58,
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 6)],
                ),
                child: Column(
                  children: [
                    Text(driverName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 2))],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(route['name'].toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF123D35)))),
              IconButton(icon: const Icon(Icons.refresh, size: 20), color: const Color(0xFF2ECC71), onPressed: _fetchBusLocations),
            ],
          ),
          Text("Departure: ${route['schedule']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text("Return: ${route['return']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDriverPanel(Map<String, dynamic> bus) {
    final driverName = (bus['driver_name'] ?? 'Driver').toString();
    final phone = (bus['driver_phone'] ?? '').toString();
    final speed = bus['speed_kmph'] == null ? null : (bus['speed_kmph'] as num).toDouble();
    final speedText = speed == null ? '' : ' • ${speed.toStringAsFixed(1)} km/h';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
                Text("Updated ${_lastSeen(bus['updated_at'] as String?)}$speedText", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  Widget _buildStopList(List<Map<String, dynamic>> stops, Map<String, dynamic> route, Color routeColor) {
    return ListView.separated(
      itemCount: stops.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final stop = stops[i];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: routeColor,
            radius: 14,
            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          title: Text(stop['name'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text("Departs: ${route['schedule']}", style: const TextStyle(fontSize: 10)),
          trailing: const Icon(Icons.access_time, color: Color(0xFF2ECC71), size: 18),
        );
      },
    );
  }
}
