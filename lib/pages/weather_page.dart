import 'dart:async';

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
  WeatherData? _weather;
  bool _loading = true;
  String? _error;
  bool _isPermissionError = false;
  bool _isManualMode = false;

  final _searchController = TextEditingController();
  static const _refreshIntervalMinutes = 10;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadGps();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: _refreshIntervalMinutes),
      (_) => _isManualMode
          ? _loadCity(_searchController.text)
          : _loadGps(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGps({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
        _isPermissionError = false;
        _isManualMode = false;
      });
    }

    try {
      final w = await WeatherService.fetchWeather();
      if (!mounted) return;
      setState(() {
        _weather = w;
        _loading = false;
        _error = w == null
            ? 'Could not fetch weather data. Check your internet connection.'
            : null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('location_service_disabled')) {
        setState(() {
          _loading = false;
          _isPermissionError = false;
          _error = 'Location services are turned off.\nPlease enable GPS and try again.';
        });
      } else if (msg.contains('location_permission_denied_forever')) {
        setState(() {
          _loading = false;
          _isPermissionError = true;
          _error = 'Location permission is permanently denied.\nPlease enable it in app settings.';
        });
      } else if (msg.contains('location_permission_denied')) {
        setState(() {
          _loading = false;
          _isPermissionError = false;
          _error = 'Location permission was denied.\nPlease allow access and try again.';
        });
      } else if (msg.contains('location_timeout')) {
        setState(() {
          _loading = false;
          _isPermissionError = false;
          _error = 'Location took too long to respond.\nTry searching a city manually instead.';
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> _loadCity(String city) async {
    if (city.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _isManualMode = true;
    });

    final w = await WeatherService.fetchWeatherByCity(city.trim());
    if (!mounted) return;

    setState(() {
      _loading = false;
      _weather = w;
      _error = w == null ? 'City "$city" not found. Try a different name.' : null;
    });
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search City',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF2ECC71),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter any city name to see its weather',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'e.g. Sylhet, Dhaka, London...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2ECC71)),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
                ),
              ),
              onSubmitted: (v) {
                Navigator.pop(context);
                _loadCity(v);
              },
            ),
            const SizedBox(height: 12),
            Text('Quick picks', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Sylhet', 'Dhaka', 'Chittagong', 'Moulvibazar', 'Habiganj', 'Comilla'].map((city) {
                return ActionChip(
                  label: Text(city, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFF2ECC71)),
                  onPressed: () {
                    _searchController.text = city;
                    Navigator.pop(context);
                    _loadCity(city);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      Navigator.pop(context);
                      _loadGps();
                    },
                    icon: const Icon(Icons.my_location, color: Color(0xFF2ECC71)),
                    label: const Text('Use My Location', style: TextStyle(color: Color(0xFF2ECC71))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2ECC71)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F6),
      appBar: AppBar(
        title: Text(
          _weather != null ? _weather!.cityName : 'Weather',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF2ECC71),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search city',
            onPressed: _showSearchSheet,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Use my location',
            onPressed: _loading ? null : _loadGps,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2ECC71)),
                  const SizedBox(height: 16),
                  Text(
                    _isManualMode ? 'Fetching weather...' : 'Getting your location...',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null
              ? _buildErrorView()
              : _buildWeatherView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPermissionError ? Icons.location_off : Icons.error_outline,
              color: Colors.redAccent,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            if (_isPermissionError)
              ElevatedButton.icon(
                onPressed: () => Geolocator.openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Open App Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _loadGps,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry GPS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showSearchSheet,
              icon: const Icon(Icons.search, color: Color(0xFF2ECC71)),
              label: const Text('Search a City Instead', style: TextStyle(color: Color(0xFF2ECC71))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2ECC71)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherView() {
    final w = _weather!;
    return RefreshIndicator(
      onRefresh: () => _isManualMode ? _loadCity(_searchController.text) : _loadGps(),
      color: const Color(0xFF2ECC71),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isManualMode) _manualModeBanner(),
          _currentWeatherCard(w),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoTile(icon: Icons.water_drop, label: 'Humidity', value: '${w.humidity.toInt()}%'),
              const SizedBox(width: 12),
              _InfoTile(icon: Icons.air, label: 'Wind', value: '${w.windSpeed.toStringAsFixed(1)} m/s'),
            ],
          ),
          const SizedBox(height: 16),
          _forecastStrip(w.forecastItems),
          const SizedBox(height: 16),
          _commuteTipCard(w),
          const SizedBox(height: 16),
          _weatherMetaCard(w),
          const SizedBox(height: 8),
          Center(
            child: Text('Pull down to refresh', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _manualModeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing weather for searched city',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
          GestureDetector(
            onTap: _loadGps,
            child: Text(
              'Use GPS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentWeatherCard(WeatherData w) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF1E8449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isManualMode ? Icons.search : Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                w.cityName,
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (w.iconCode.isNotEmpty)
            Image.network(
              w.iconUrl,
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, size: 80, color: Colors.white),
            ),
          Text(
            '${w.tempC.toStringAsFixed(1)}°C',
            style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            w.description.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Feels like ${w.feelsLikeC.toStringAsFixed(1)}°C',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _forecastStrip(List<WeatherForecastItem> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next Hours', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Forecast is temporarily unavailable.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBF9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0EEE5)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(f.timeLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        if (f.iconCode.isNotEmpty)
                          Image.network(
                            f.iconUrl,
                            width: 38,
                            height: 38,
                            errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, size: 32, color: Color(0xFF2ECC71)),
                          )
                        else
                          const Icon(Icons.wb_sunny, size: 32, color: Color(0xFF2ECC71)),
                        Text(
                          '${f.tempC.toStringAsFixed(0)}°',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${(f.rainProbability * 100).toStringAsFixed(0)}% rain',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
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

  Widget _commuteTipCard(WeatherData w) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2ECC71)),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commute Tip',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 8),
          Text(w.commuteTip, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _weatherMetaCard(WeatherData w) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _metaRow(
            Icons.my_location,
            'Coordinates',
            '${w.latitude.toStringAsFixed(4)}°N, ${w.longitude.toStringAsFixed(4)}°E',
          ),
          const Divider(height: 16),
          _metaRow(
            Icons.access_time,
            'Last updated',
            'Today at ${w.fetchedAtFormatted} (auto-refreshes every $_refreshIntervalMinutes min)',
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2ECC71)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2ECC71)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
