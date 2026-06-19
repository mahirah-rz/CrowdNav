import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _nodes = {
  'Gate':                       LatLng(24.869579, 91.804322),
  'Bus Stop':                   LatLng(24.869571, 91.804016),
  'Shahid Minar':               LatLng(24.869337, 91.804456),
  'RKB (Rabeya Khatun Bldg)':  LatLng(24.869686, 91.804771),
  'RAB (Ragib Ali Bldg)':       LatLng(24.869634, 91.805039),
  'CSE Dept (RAB 3rd Floor)':   LatLng(24.869680, 91.805095),
  'Library (RAB 2nd Floor)':    LatLng(24.869580, 91.805100),
  'Cafeteria':                  LatLng(24.869279, 91.805294),
};

final _edges = <String, Map<String, double>>{
  'Gate': {
    'Bus Stop': 1.0,
    'Shahid Minar': 1.2,
    'RKB (Rabeya Khatun Bldg)': 1.5,
  },
  'Bus Stop': {
    'Gate': 1.0,
    'Shahid Minar': 1.3,
  },
  'Shahid Minar': {
    'Gate': 1.2,
    'Bus Stop': 1.3,
    'RKB (Rabeya Khatun Bldg)': 1.0,
    'Cafeteria': 1.2,
  },
  'RKB (Rabeya Khatun Bldg)': {
    'Gate': 1.5,
    'Shahid Minar': 1.0,
    'RAB (Ragib Ali Bldg)': 0.8,
    'Cafeteria': 1.0,
  },
  'RAB (Ragib Ali Bldg)': {
    'RKB (Rabeya Khatun Bldg)': 0.8,
    'CSE Dept (RAB 3rd Floor)': 0.2,
    'Library (RAB 2nd Floor)': 0.2,
    'Cafeteria': 0.9,
  },
  'CSE Dept (RAB 3rd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.2,
    'Library (RAB 2nd Floor)': 0.15,
  },
  'Library (RAB 2nd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.2,
    'CSE Dept (RAB 3rd Floor)': 0.15,
  },
  'Cafeteria': {
    'Shahid Minar': 1.2,
    'RKB (Rabeya Khatun Bldg)': 1.0,
    'RAB (Ragib Ali Bldg)': 0.9,
  },
};

final _crowdScore = <String, double>{
  'Gate': 0.3,
  'Bus Stop': 0.8,
  'Shahid Minar': 0.5,
  'RKB (Rabeya Khatun Bldg)': 0.4,
  'RAB (Ragib Ali Bldg)': 0.7,
  'CSE Dept (RAB 3rd Floor)': 0.6,
  'Library (RAB 2nd Floor)': 0.2,
  'Cafeteria': 0.9,
};

class _Node {
  final String name;
  final double cost;
  const _Node(this.name, this.cost);
}

List<String> _dijkstra(String start, String end, {bool avoidCrowd = false}) {
  final dist = <String, double>{};
  final prev = <String, String?>{};
  final pq = HeapPriorityQueue<_Node>((a, b) => a.cost.compareTo(b.cost));

  for (final n in _nodes.keys) {
    dist[n] = double.infinity;
    prev[n] = null;
  }

  dist[start] = 0;
  pq.add(_Node(start, 0));

  while (pq.isNotEmpty) {
    final current = pq.removeFirst();

    if (current.name == end) break;
    if (current.cost > dist[current.name]!) continue;

    for (final neighbor in (_edges[current.name] ?? {}).entries) {
      double edgeCost = neighbor.value;

      if (avoidCrowd) {
        final crowdPenalty = (_crowdScore[neighbor.key] ?? 0.0) * 2.0;
        edgeCost += crowdPenalty;
      }

      final newCost = dist[current.name]! + edgeCost;

      if (newCost < dist[neighbor.key]!) {
        dist[neighbor.key] = newCost;
        prev[neighbor.key] = current.name;
        pq.add(_Node(neighbor.key, newCost));
      }
    }
  }

  final path = <String>[];
  String? current = end;

  while (current != null) {
    path.insert(0, current);
    current = prev[current];
  }

  return (path.isNotEmpty && path.first == start) ? path : [];
}

Color _crowdColor(double score) {
  if (score >= 0.7) return Colors.redAccent;
  if (score >= 0.4) return Colors.orange;
  return const Color(0xFF2ECC71);
}

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  String _from = 'Gate';
  String _to = 'CSE Dept (RAB 3rd Floor)';
  List<String> _path = [];
  bool _avoidCrowd = false;

  void _calculateRoute() {
    setState(() {
      _path = _dijkstra(_from, _to, avoidCrowd: _avoidCrowd);
    });
  }

  List<LatLng> get _polylinePoints => _path.map((n) => _nodes[n]!).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFECF0F1),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DropdownNode(
                      label: 'From',
                      value: _from,
                      onChanged: (v) => setState(() => _from = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Color(0xFF2ECC71)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DropdownNode(
                      label: 'To',
                      value: _to,
                      onChanged: (v) => setState(() => _to = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _calculateRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Go'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Switch(
                    value: _avoidCrowd,
                    activeThumbColor: const Color(0xFF2ECC71),
                    onChanged: (v) => setState(() => _avoidCrowd = v),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Avoid crowded paths',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _avoidCrowd
                          ? const Color(0xFF1E8449)
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  _CrowdLegend(),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          flex: 3,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(24.86950, 91.80470),
              initialZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crowdnav.app',
              ),

              if (_polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints,
                      color: const Color(0xFF2ECC71),
                      strokeWidth: 5,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: _nodes.entries.map((e) {
                  final isOnPath = _path.contains(e.key);
                  final crowd = _crowdScore[e.key] ?? 0.0;

                  return Marker(
                    point: e.value,
                    width: 70,
                    height: 55,
                    child: Column(
                      children: [
                        Icon(
                          e.key == _from
                              ? Icons.trip_origin
                              : e.key == _to
                                  ? Icons.location_on
                                  : Icons.circle,
                          color: isOnPath ? _crowdColor(crowd) : Colors.grey,
                          size: isOnPath ? 24 : 16,
                        ),
                        Text(
                          e.key,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: isOnPath
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isOnPath ? _crowdColor(crowd) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        if (_path.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _avoidCrowd
                          ? 'Crowd-Aware Route (Dijkstra)'
                          : 'Shortest Path (Dijkstra)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2ECC71),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_path.length - 1} step${_path.length - 1 == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _path.map((node) {
                      final isLast = node == _path.last;
                      final crowd = _crowdScore[node] ?? 0.0;

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _crowdColor(crowd),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              node,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (!isLast)
                            const Icon(Icons.arrow_forward,
                                size: 16, color: Colors.grey),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CrowdLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(Colors.redAccent, 'High'),
        const SizedBox(width: 6),
        _dot(Colors.orange, 'Med'),
        const SizedBox(width: 6),
        _dot(const Color(0xFF2ECC71), 'Low'),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _DropdownNode extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String?) onChanged;

  const _DropdownNode({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _nodes.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: _nodes.keys
          .map((n) => DropdownMenuItem(
                value: n,
                child: Text(n, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}