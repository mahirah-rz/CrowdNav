import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherForecastItem {
  final DateTime time;
  final double tempC;
  final String description;
  final String iconCode;
  final double rainProbability;

  const WeatherForecastItem({
    required this.time,
    required this.tempC,
    required this.description,
    required this.iconCode,
    required this.rainProbability,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get timeLabel {
    final hour = time.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $suffix';
  }
}

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
  final List<WeatherForecastItem> forecastItems;

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
    this.forecastItems = const [],
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get commuteTip {
    if (isRaining) return '🌧️ Rain expected — carry an umbrella!';
    if (tempC > 34) return '☀️ Extreme heat — stay hydrated!';
    if (tempC < 18) return '🧥 Cool weather — wear a jacket!';
    if (windSpeed > 10) return '💨 Strong wind — hold on to your things!';
    return '✅ Weather looks good for commuting!';
  }

  String get fetchedAtFormatted {
    final h = fetchedAt.hour.toString().padLeft(2, '0');
    final m = fetchedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class WeatherService {
  static const _apiKey = '46d0ae609409e76de04e042f17926759';
  static const _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  static Future<Position> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('location_service_disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('location_permission_denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('location_permission_denied_forever');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('location_timeout'),
    );
  }

  static Future<WeatherData?> fetchWeather() async {
    final position = await _getPosition();
    return _fetchByCoords(position.latitude, position.longitude);
  }

  static Future<WeatherData?> fetchWeatherByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_weatherUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final weather = (body['weather'] as List).first as Map<String, dynamic>;
      final main = body['main'] as Map<String, dynamic>;
      final wind = body['wind'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final coord = body['coord'] as Map<String, dynamic>;
      final lat = (coord['lat'] as num).toDouble();
      final lon = (coord['lon'] as num).toDouble();
      final forecast = await _fetchForecastByCity(city);

      return WeatherData(
        description: (weather['description'] ?? '').toString(),
        tempC: (main['temp'] as num).toDouble(),
        feelsLikeC: (main['feels_like'] as num).toDouble(),
        humidity: (main['humidity'] as num).toDouble(),
        windSpeed: ((wind['speed'] ?? 0) as num).toDouble(),
        iconCode: (weather['icon'] ?? '').toString(),
        isRaining: weather['main'].toString().toLowerCase().contains('rain'),
        cityName: (body['name'] ?? city).toString(),
        latitude: lat,
        longitude: lon,
        fetchedAt: DateTime.now(),
        forecastItems: forecast,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherData?> _fetchByCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_weatherUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final weather = (body['weather'] as List).first as Map<String, dynamic>;
      final main = body['main'] as Map<String, dynamic>;
      final wind = body['wind'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final forecast = await _fetchForecastByCoords(lat, lng);

      String cityName = (body['name'] ?? 'Your Location').toString();
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
      } catch (_) {
      }

      return WeatherData(
        description: (weather['description'] ?? '').toString(),
        tempC: (main['temp'] as num).toDouble(),
        feelsLikeC: (main['feels_like'] as num).toDouble(),
        humidity: (main['humidity'] as num).toDouble(),
        windSpeed: ((wind['speed'] ?? 0) as num).toDouble(),
        iconCode: (weather['icon'] ?? '').toString(),
        isRaining: weather['main'].toString().toLowerCase().contains('rain'),
        cityName: cityName,
        latitude: lat,
        longitude: lng,
        fetchedAt: DateTime.now(),
        forecastItems: forecast,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<WeatherForecastItem>> _fetchForecastByCoords(double lat, double lng) async {
    final uri = Uri.parse(
      '$_forecastUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric',
    );
    return _fetchForecast(uri);
  }

  static Future<List<WeatherForecastItem>> _fetchForecastByCity(String city) async {
    final uri = Uri.parse(
      '$_forecastUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric',
    );
    return _fetchForecast(uri);
  }

  static Future<List<WeatherForecastItem>> _fetchForecast(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['list'];
      if (list is! List) return const [];

      return list.take(8).map((raw) {
        final item = raw as Map<String, dynamic>;
        final main = item['main'] as Map<String, dynamic>;
        final weather = (item['weather'] as List).first as Map<String, dynamic>;
        final timeText = (item['dt_txt'] ?? '').toString();
        final time = DateTime.tryParse(timeText) ?? DateTime.now();

        return WeatherForecastItem(
          time: time,
          tempC: (main['temp'] as num).toDouble(),
          description: (weather['description'] ?? '').toString(),
          iconCode: (weather['icon'] ?? '').toString(),
          rainProbability: ((item['pop'] ?? 0) as num).toDouble(),
        );
      }).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
