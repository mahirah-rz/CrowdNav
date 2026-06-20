import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _searchController = TextEditingController(text: 'Sylhet');
  WeatherBundle? _bundle;
  bool _loading = true;
  bool _manualMode = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCity('Sylhet');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCity(String city) async {
    final safeCity = city.trim().isEmpty ? 'Sylhet' : city.trim();
    setState(() {
      _loading = true;
      _manualMode = true;
      _error = null;
      _searchController.text = safeCity;
    });
    try {
      final data = await WeatherService.fetchWeatherBundleByCity(safeCity);
      if (!mounted) return;
      setState(() {
        _bundle = data;
        _loading = false;
        if (data == null) _error = 'Could not load weather for $safeCity. Check internet or search another city.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _loadGps() async {
    setState(() {
      _loading = true;
      _manualMode = false;
      _error = null;
    });
    try {
      final data = await WeatherService.fetchWeatherBundle();
      if (!mounted) return;
      setState(() {
        _bundle = data;
        _loading = false;
        if (data == null) _error = 'Could not load GPS weather. Try search city instead.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('location_service_disabled')) return 'Location service is turned off. Turn it on or search by city.';
    if (text.contains('location_permission_denied_forever')) return 'Location permission is permanently denied. Open app settings or search by city.';
    if (text.contains('location_permission_denied')) return 'Location permission was denied. Search by city or allow location.';
    return 'Weather could not be loaded. Check internet connection and try again.';
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Weather', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E8449)),
                hintText: 'Sylhet, Dhaka, Chattogram...',
                filled: true,
                fillColor: const Color(0xFFF4F7F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) {
                Navigator.pop(context);
                _loadCity(v);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Sylhet', 'Dhaka', 'Chattogram', 'Moulvibazar', 'Habiganj', 'Comilla']
                  .map((city) => ActionChip(
                        label: Text(city),
                        onPressed: () {
                          Navigator.pop(context);
                          _loadCity(city);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadCity(_searchController.text);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadGps();
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use GPS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _bundle?.current.cityName ?? 'Weather';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearchSheet),
          IconButton(icon: const Icon(Icons.my_location), onPressed: _loading ? null : _loadGps),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : _error != null
              ? _buildErrorView()
              : _buildWeatherView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 18),
            ElevatedButton.icon(onPressed: () => _loadCity('Sylhet'), icon: const Icon(Icons.refresh), label: const Text('Load Sylhet Weather')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _showSearchSheet, icon: const Icon(Icons.search), label: const Text('Search City')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: Geolocator.openAppSettings, icon: const Icon(Icons.settings), label: const Text('Open App Settings')),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherView() {
    final current = _bundle!.current;
    final forecast = _bundle!.forecast;

    return RefreshIndicator(
      color: const Color(0xFF2ECC71),
      onRefresh: () => _manualMode ? _loadCity(_searchController.text) : _loadGps(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _currentWeatherCard(current),
          const SizedBox(height: 14),
          if (forecast.isNotEmpty) _forecastStrip(forecast),
          if (forecast.isNotEmpty) const SizedBox(height: 14),
          Row(
            children: [
              _InfoTile(icon: Icons.thermostat, label: 'Feels like', value: '${current.feelsLikeC.toStringAsFixed(0)}°C'),
              const SizedBox(width: 10),
              _InfoTile(icon: Icons.water_drop, label: 'Humidity', value: '${current.humidity.toStringAsFixed(0)}%'),
              const SizedBox(width: 10),
              _InfoTile(icon: Icons.air, label: 'Wind', value: '${current.windSpeed.toStringAsFixed(1)} m/s'),
            ],
          ),
          const SizedBox(height: 14),
          _tipCard(current),
          const SizedBox(height: 14),
          _metaCard(current),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _currentWeatherCard(WeatherData w) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF123D35), Color(0xFF1E8449)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_manualMode ? Icons.search : Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(w.cityName, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 8),
          Image.network(w.iconUrl, width: 90, height: 90, errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, color: Colors.white, size: 80)),
          Text('${w.tempC.toStringAsFixed(0)}°C', style: GoogleFonts.poppins(fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(w.description.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, letterSpacing: 1.1)),
        ],
      ),
    );
  }

  Widget _forecastStrip(List<WeatherForecastItem> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next Hours', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF123D35))),
          const SizedBox(height: 10),
          SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final f = items[i];
                return Container(
                  width: 82,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF4F7F6), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Text(f.hourLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      Image.network(f.iconUrl, width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Color(0xFF1E8449))),
                      Text('${f.tempC.toStringAsFixed(0)}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('💧${f.rainChance.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(WeatherData w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.35))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF1E8449)),
          const SizedBox(width: 10),
          Expanded(child: Text(w.commuteTip, style: const TextStyle(height: 1.45, color: Color(0xFF2C3E50)))),
        ],
      ),
    );
  }

  Widget _metaCard(WeatherData w) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          _metaRow(Icons.access_time, 'Updated', 'Today at ${w.fetchedAtFormatted}'),
          const Divider(),
          _metaRow(Icons.my_location, 'Coordinates', '${w.latitude.toStringAsFixed(4)}, ${w.longitude.toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF1E8449)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1E8449)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
