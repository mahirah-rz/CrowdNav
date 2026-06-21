import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


const _nodes = {
  'Gate': LatLng(24.869579, 91.804322),
  'Bus Stop': LatLng(24.869571, 91.804016),
  'Shahid Minar': LatLng(24.869337, 91.804456),
  'RKB (Rabeya Khatun Bldg)': LatLng(24.869686, 91.804771),
  'RAB (Ragib Ali Bldg)': LatLng(24.869634, 91.805039),
  'LU Cafeteria': LatLng(24.869230553721327, 91.80535191786663),
  'LU Kodom Tola': LatLng(24.869428787143374, 91.80463742462281),
  'Civil Engineering Workshop': LatLng(24.86903231998135, 91.8052211400854),
  'Mojo Shop': LatLng(24.8694244799805, 91.80406895077627),
  'CSE Dept (RAB 3rd Floor)': LatLng(24.869695454367854, 91.80516182866596),
  'Library (RAB 2nd Floor)': LatLng(24.869431251748406, 91.80527166148798),
  'EEE Dept (RAB 2nd Floor)': LatLng(24.869539247474624, 91.805327582344),
  'Business Admin Dept (RAB 2nd Floor)': LatLng(24.869681130243297, 91.80514378498674),
  'Law Dept (RAB 3rd Floor)': LatLng(24.869555282506184, 91.80530053944987),
  'English Dept (RAB 4th Floor)': LatLng(24.869757338850377, 91.80507505750941),
  'Architecture Dept (RAB 4th Floor)': LatLng(24.869561999868406, 91.80529355209515),
  'Civil Engineering Dept (RAB Ground Floor)': LatLng(24.86963, 91.80523),
  'Islamic History & Culture Dept (RAB Ground Floor)': LatLng(24.86949, 91.805305),
  'Public Health Dept (RAB Ground Floor)': LatLng(24.86947, 91.80519),
  'Gallery 1 (RAB 2nd Floor)': LatLng(24.869443225144487, 91.80494369408534),
  'Gallery 2 (RAB 3rd Floor)': LatLng(24.869461225144487, 91.80496269408533),
  'Gallery 3 (RAB 3rd Floor)': LatLng(24.869425225144486, 91.80492469408534),
  'Bangla Dept (RKB 4th Floor)': LatLng(24.869725, 91.804873),
  'THM Dept (RKB 4th Floor)': LatLng(24.869746, 91.804683),
  'Lift (RAB Ground Floor)': LatLng(24.8697078, 91.805354),
};

final _edges = <String, Map<String, double>>{
  'Gate': {
    'Bus Stop': 1.0,
    'Shahid Minar': 1.2,
    'RKB (Rabeya Khatun Bldg)': 1.5,
    'LU Kodom Tola': 1.2,
    'Mojo Shop': 1.03,
  },
  'Bus Stop': {
    'Gate': 1.0,
    'Shahid Minar': 1.3,
    'Mojo Shop': 0.57,
  },
  'Shahid Minar': {
    'Gate': 1.2,
    'Bus Stop': 1.3,
    'RKB (Rabeya Khatun Bldg)': 1.0,
    'LU Cafeteria': 1.2,
    'LU Kodom Tola': 0.7,
  },
  'RKB (Rabeya Khatun Bldg)': {
    'Gate': 1.5,
    'Shahid Minar': 1.0,
    'RAB (Ragib Ali Bldg)': 0.8,
    'LU Cafeteria': 1.0,
    'LU Kodom Tola': 1.05,
    'Bangla Dept (RKB 4th Floor)': 0.4,
    'THM Dept (RKB 4th Floor)': 0.4,
  },
  'RAB (Ragib Ali Bldg)': {
    'RKB (Rabeya Khatun Bldg)': 0.8,
    'LU Cafeteria': 0.9,
    'Civil Engineering Workshop': 2.31,
    'CSE Dept (RAB 3rd Floor)': 0.3,
    'Library (RAB 2nd Floor)': 0.2,
    'EEE Dept (RAB 2nd Floor)': 0.2,
    'Business Admin Dept (RAB 2nd Floor)': 0.2,
    'Law Dept (RAB 3rd Floor)': 0.3,
    'English Dept (RAB 4th Floor)': 0.4,
    'Architecture Dept (RAB 4th Floor)': 0.4,
    'Civil Engineering Dept (RAB Ground Floor)': 0.1,
    'Islamic History & Culture Dept (RAB Ground Floor)': 0.1,
    'Public Health Dept (RAB Ground Floor)': 0.1,
    'Gallery 1 (RAB 2nd Floor)': 0.2,
    'Gallery 2 (RAB 3rd Floor)': 0.3,
    'Gallery 3 (RAB 3rd Floor)': 0.3,
  },
  'LU Cafeteria': {
    'Shahid Minar': 1.2,
    'RKB (Rabeya Khatun Bldg)': 1.0,
    'RAB (Ragib Ali Bldg)': 0.9,
    'Civil Engineering Workshop': 0.86,
  },
  'LU Kodom Tola': {
    'Shahid Minar': 0.7,
    'RKB (Rabeya Khatun Bldg)': 1.05,
    'Gate': 1.2,
  },
  'Civil Engineering Workshop': {
    'LU Cafeteria': 0.86,
    'RAB (Ragib Ali Bldg)': 2.31,
  },
  'Mojo Shop': {
    'Bus Stop': 0.57,
    'Gate': 1.03,
  },
  'CSE Dept (RAB 3rd Floor)': {
    'Library (RAB 2nd Floor)': 0.15,
    'RAB (Ragib Ali Bldg)': 0.3,
  },
  'Library (RAB 2nd Floor)': {
    'CSE Dept (RAB 3rd Floor)': 0.15,
    'RAB (Ragib Ali Bldg)': 0.2,
  },
  'EEE Dept (RAB 2nd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.2,
  },
  'Business Admin Dept (RAB 2nd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.2,
  },
  'Law Dept (RAB 3rd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.3,
  },
  'English Dept (RAB 4th Floor)': {
    'RAB (Ragib Ali Bldg)': 0.4,
  },
  'Architecture Dept (RAB 4th Floor)': {
    'RAB (Ragib Ali Bldg)': 0.4,
  },
  'Civil Engineering Dept (RAB Ground Floor)': {
    'RAB (Ragib Ali Bldg)': 0.1,
  },
  'Islamic History & Culture Dept (RAB Ground Floor)': {
    'RAB (Ragib Ali Bldg)': 0.1,
  },
  'Public Health Dept (RAB Ground Floor)': {
    'RAB (Ragib Ali Bldg)': 0.1,
  },
  'Gallery 1 (RAB 2nd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.2,
  },
  'Gallery 2 (RAB 3rd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.3,
  },
  'Gallery 3 (RAB 3rd Floor)': {
    'RAB (Ragib Ali Bldg)': 0.3,
  },
  'Bangla Dept (RKB 4th Floor)': {
    'RKB (Rabeya Khatun Bldg)': 0.4,
  },
  'THM Dept (RKB 4th Floor)': {
    'RKB (Rabeya Khatun Bldg)': 0.4,
  },
  'Lift (RAB Ground Floor)': {
    'RAB (Ragib Ali Bldg)': 0.1,
  },
};

final _crowdScore = <String, double>{
  'Gate': 0.3,
  'Bus Stop': 0.8,
  'Shahid Minar': 0.5,
  'RKB (Rabeya Khatun Bldg)': 0.4,
  'RAB (Ragib Ali Bldg)': 0.7,
  'LU Cafeteria': 0.9,
  'LU Kodom Tola': 0.6,
  'Civil Engineering Workshop': 0.3,
  'Break Station': 0.7,
  'CSE Dept (RAB 3rd Floor)': 0.6,
  'Library (RAB 2nd Floor)': 0.2,
  'EEE Dept (RAB 2nd Floor)': 0.5,
  'Business Admin Dept (RAB 2nd Floor)': 0.5,
  'Law Dept (RAB 3rd Floor)': 0.5,
  'English Dept (RAB 4th Floor)': 0.4,
  'Architecture Dept (RAB 4th Floor)': 0.4,
  'Civil Engineering Dept (RAB Ground Floor)': 0.4,
  'Islamic History & Culture Dept (RAB Ground Floor)': 0.4,
  'Public Health Dept (RAB Ground Floor)': 0.4,
  'Gallery 1 (RAB 2nd Floor)': 0.3,
  'Gallery 2 (RAB 3rd Floor)': 0.3,
  'Gallery 3 (RAB 3rd Floor)': 0.3,
  'Bangla Dept (RKB 4th Floor)': 0.4,
  'THM Dept (RKB 4th Floor)': 0.4,
  'Lift (RAB Ground Floor)': 0.3,
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
                userAgentPackageName: 'io.crowdnav.app',
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
                          ? 'Crowd-Aware Route'
                          : 'Shortest Path',
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
      initialValue: _nodes.containsKey(value) ? value : null,
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