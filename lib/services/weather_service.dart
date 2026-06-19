import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

  WeatherData({
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
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

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
      desiredAccuracy: LocationAccuracy.low,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('location_timeout'),
    );
  }

  static Future<WeatherData?> fetchWeatherByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final weather = json['weather'][0];
      final main = json['main'];
      final wind = json['wind'];

      return WeatherData(
        description: weather['description'],
        tempC: (main['temp'] as num).toDouble(),
        feelsLikeC: (main['feels_like'] as num).toDouble(),
        humidity: (main['humidity'] as num).toDouble(),
        windSpeed: (wind['speed'] as num).toDouble(),
        iconCode: weather['icon'],
        isRaining: weather['main'].toString().toLowerCase().contains('rain'),
        cityName: json['name'] ?? city,
        latitude: (json['coord']['lat'] as num).toDouble(),
        longitude: (json['coord']['lon'] as num).toDouble(),
        fetchedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherData?> fetchWeather() async {
    final position = await _getPosition();
    return _fetchByCoords(position.latitude, position.longitude);
  }

  static Future<WeatherData?> _fetchByCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      final weather = json['weather'][0];
      final main = json['main'];
      final wind = json['wind'];

      String cityName = json['name'] ?? 'Your Location';
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

      return WeatherData(
        description: weather['description'],
        tempC: (main['temp'] as num).toDouble(),
        feelsLikeC: (main['feels_like'] as num).toDouble(),
        humidity: (main['humidity'] as num).toDouble(),
        windSpeed: (wind['speed'] as num).toDouble(),
        iconCode: weather['icon'],
        isRaining: weather['main'].toString().toLowerCase().contains('rain'),
        cityName: cityName,
        latitude: lat,
        longitude: lng,
        fetchedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}