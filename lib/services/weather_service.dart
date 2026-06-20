import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String description;
  final double tempC;
  final double feelsLikeC;
  final double humidity;
  final double windSpeed;
  final String iconCode;
  final bool isRaining;
  final String cityName;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const WeatherData({
    required this.description,
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windSpeed,
    required this.iconCode,
    required this.isRaining,
    required this.cityName,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get commuteTip {
    final d = description.toLowerCase();
    if (isRaining || d.contains('rain') || d.contains('drizzle') || d.contains('thunder')) {
      return 'Rain risk today — carry an umbrella and allow extra commute time.';
    }
    if (tempC >= 34) return 'Hot weather — drink water and avoid long outdoor waits.';
    if (tempC <= 18) return 'Cool weather — carry a light jacket.';
    if (windSpeed >= 10) return 'Windy condition — be careful while walking near open roads.';
    return 'Weather looks good for campus commuting.';
  }

  String get fetchedAtFormatted {
    final h = fetchedAt.hour.toString().padLeft(2, '0');
    final m = fetchedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class WeatherForecastItem {
  final DateTime time;
  final double tempC;
  final double rainChance;
  final String description;
  final String iconCode;

  const WeatherForecastItem({
    required this.time,
    required this.tempC,
    required this.rainChance,
    required this.description,
    required this.iconCode,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get hourLabel {
    final hour = time.hour;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class WeatherBundle {
  final WeatherData current;
  final List<WeatherForecastItem> forecast;

  const WeatherBundle({required this.current, required this.forecast});
}

class WeatherService {
  static const _apiKey = '46d0ae609409e76de04e042f17926759';
  static const _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  static Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('location_service_disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('location_permission_denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('location_permission_denied_forever');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low)
        .timeout(const Duration(seconds: 25));
  }

  static WeatherData _parseCurrent(Map<String, dynamic> json, {String? cityFallback, double? latFallback, double? lonFallback}) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = (json['wind'] as Map?) ?? const {};
    final coord = (json['coord'] as Map?) ?? const {};

    return WeatherData(
      description: (weather['description'] ?? 'Unknown').toString(),
      tempC: (main['temp'] as num).toDouble(),
      feelsLikeC: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toDouble(),
      windSpeed: ((wind['speed'] ?? 0) as num).toDouble(),
      iconCode: (weather['icon'] ?? '01d').toString(),
      isRaining: weather['main'].toString().toLowerCase().contains('rain'),
      cityName: (json['name'] ?? cityFallback ?? 'Weather').toString(),
      latitude: ((coord['lat'] ?? latFallback ?? 0) as num).toDouble(),
      longitude: ((coord['lon'] ?? lonFallback ?? 0) as num).toDouble(),
      fetchedAt: DateTime.now(),
    );
  }

  static List<WeatherForecastItem> _parseForecast(Map<String, dynamic> json) {
    final list = (json['list'] as List? ?? const []).take(8);
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      final main = map['main'] as Map<String, dynamic>;
      final weather = (map['weather'] as List).first as Map<String, dynamic>;
      return WeatherForecastItem(
        time: DateTime.fromMillisecondsSinceEpoch(((map['dt'] ?? 0) as num).toInt() * 1000),
        tempC: (main['temp'] as num).toDouble(),
        rainChance: (((map['pop'] ?? 0) as num).toDouble() * 100).clamp(0, 100),
        description: (weather['description'] ?? '').toString(),
        iconCode: (weather['icon'] ?? '01d').toString(),
      );
    }).toList();
  }

  static Future<WeatherData?> fetchWeatherByCity(String city) async {
    try {
      final uri = Uri.parse('$_weatherUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return _parseCurrent(jsonDecode(response.body), cityFallback: city);
    } catch (_) {
      return null;
    }
  }

  static Future<List<WeatherForecastItem>> fetchForecastByCity(String city) async {
    try {
      final uri = Uri.parse('$_forecastUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];
      return _parseForecast(jsonDecode(response.body));
    } catch (_) {
      return const [];
    }
  }

  static Future<WeatherBundle?> fetchWeatherBundleByCity(String city) async {
    final current = await fetchWeatherByCity(city);
    if (current == null) return null;
    final forecast = await fetchForecastByCity(city);
    return WeatherBundle(current: current, forecast: forecast);
  }

  static Future<WeatherData?> fetchWeather() async {
    final position = await _getPosition();
    return _fetchByCoords(position.latitude, position.longitude);
  }

  static Future<WeatherBundle?> fetchWeatherBundle() async {
    final position = await _getPosition();
    final current = await _fetchByCoords(position.latitude, position.longitude);
    if (current == null) return null;
    final forecast = await _fetchForecastByCoords(position.latitude, position.longitude);
    return WeatherBundle(current: current, forecast: forecast);
  }

  static Future<WeatherData?> _fetchByCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_weatherUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      var cityName = (json['name'] ?? 'Your Location').toString();
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.subAdministrativeArea?.isNotEmpty == true
              ? p.subAdministrativeArea!
              : p.locality?.isNotEmpty == true
                  ? p.locality!
                  : p.administrativeArea ?? cityName;
        }
      } catch (_) {}
      json['name'] = cityName;
      return _parseCurrent(json, latFallback: lat, lonFallback: lng);
    } catch (_) {
      return null;
    }
  }

  static Future<List<WeatherForecastItem>> _fetchForecastByCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_forecastUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];
      return _parseForecast(jsonDecode(response.body));
    } catch (_) {
      return const [];
    }
  }
}
