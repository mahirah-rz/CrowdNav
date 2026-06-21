import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherForecastItem {
  final DateTime dateTime;
  final double tempC;
  final String description;
  final String iconCode;
  final double windSpeed;
  final double humidity;
  final double rainChance;
  final bool isRaining;

  const WeatherForecastItem({
    required this.dateTime,
    required this.tempC,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.humidity,
    required this.rainChance,
    required this.isRaining,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  String get timeLabel {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute $suffix';
  }

  String get dayLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dateTime.weekday - 1];
  }

  String get tempText => '${tempC.round()}°C';

  // Compatibility getter used by your WeatherPage.
  double get rainProbability => rainChance;

  // Compatibility getters for older/newer WeatherPage UI code.
  String get time => timeLabel;
  String get label => timeLabel;
  String get day => dayLabel;
  String get condition => description;
  String get icon => iconCode;
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
        timeLimit: Duration(seconds: 30),
      ),
    ).catchError((error) {
      if (error is TimeoutException) {
        throw Exception('location_timeout');
      }
      throw error;
    });
  }

  static Future<WeatherData?> fetchWeatherByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_weatherUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = await _weatherDataFromJson(json, fallbackCity: city);
      final forecastItems = await _fetchForecastByCity(city);
      return _copyWithForecast(data, forecastItems);
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
        '$_weatherUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = await _weatherDataFromJson(json, lat: lat, lng: lng);
      final forecastItems = await _fetchForecastByCoords(lat, lng);
      return _copyWithForecast(data, forecastItems);
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherData> _weatherDataFromJson(
    Map<String, dynamic> json, {
    String fallbackCity = 'Sylhet',
    double? lat,
    double? lng,
  }) async {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;
    final wind = (json['wind'] as Map?) ?? <String, dynamic>{};
    final coord = (json['coord'] as Map?) ?? <String, dynamic>{};

    final latitude = lat ?? (coord['lat'] as num?)?.toDouble() ?? 0.0;
    final longitude = lng ?? (coord['lon'] as num?)?.toDouble() ?? 0.0;

    String cityName = (json['name']?.toString().isNotEmpty == true)
        ? json['name'].toString()
        : fallbackCity;

    if (lat != null && lng != null) {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          cityName = p.subAdministrativeArea?.isNotEmpty == true
              ? p.subAdministrativeArea!
              : p.locality?.isNotEmpty == true
                  ? p.locality!
                  : p.administrativeArea?.isNotEmpty == true
                      ? p.administrativeArea!
                      : cityName;
        }
      } catch (_) {}
    }

    final weatherMain = weather['main']?.toString().toLowerCase() ?? '';
    final description = weather['description']?.toString() ?? 'Weather update';

    return WeatherData(
      description: description,
      tempC: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLikeC: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      humidity: (main['humidity'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      iconCode: weather['icon']?.toString() ?? '01d',
      isRaining: weatherMain.contains('rain') || description.toLowerCase().contains('rain'),
      cityName: cityName,
      latitude: latitude,
      longitude: longitude,
      fetchedAt: DateTime.now(),
    );
  }

  static WeatherData _copyWithForecast(
    WeatherData data,
    List<WeatherForecastItem> forecastItems,
  ) {
    return WeatherData(
      description: data.description,
      tempC: data.tempC,
      feelsLikeC: data.feelsLikeC,
      humidity: data.humidity,
      windSpeed: data.windSpeed,
      iconCode: data.iconCode,
      isRaining: data.isRaining,
      cityName: data.cityName,
      latitude: data.latitude,
      longitude: data.longitude,
      fetchedAt: data.fetchedAt,
      forecastItems: forecastItems,
    );
  }

  static Future<List<WeatherForecastItem>> _fetchForecastByCity(String city) async {
    try {
      final uri = Uri.parse(
        '$_forecastUrl?q=${Uri.encodeComponent(city)}&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      return _parseForecastItems(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return const [];
    }
  }

  static Future<List<WeatherForecastItem>> _fetchForecastByCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_forecastUrl?lat=$lat&lon=$lng&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      return _parseForecastItems(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return const [];
    }
  }

  static List<WeatherForecastItem> _parseForecastItems(Map<String, dynamic> json) {
    final rawList = (json['list'] as List?) ?? const [];
    return rawList.take(8).map((raw) {
      final item = raw as Map<String, dynamic>;
      final main = (item['main'] as Map?) ?? <String, dynamic>{};
      final wind = (item['wind'] as Map?) ?? <String, dynamic>{};
      final weatherList = (item['weather'] as List?) ?? const [];
      final weather = weatherList.isNotEmpty
          ? weatherList.first as Map<String, dynamic>
          : <String, dynamic>{};
      final pop = (item['pop'] as num?)?.toDouble() ?? 0.0;
      final description = weather['description']?.toString() ?? 'Forecast';
      final mainText = weather['main']?.toString().toLowerCase() ?? '';

      DateTime dateTime = DateTime.now();
      final dtTxt = item['dt_txt']?.toString();
      if (dtTxt != null) {
        dateTime = DateTime.tryParse(dtTxt) ?? dateTime;
      } else if (item['dt'] is num) {
        dateTime = DateTime.fromMillisecondsSinceEpoch((item['dt'] as num).toInt() * 1000);
      }

      return WeatherForecastItem(
        dateTime: dateTime.toLocal(),
        tempC: (main['temp'] as num?)?.toDouble() ?? 0.0,
        description: description,
        iconCode: weather['icon']?.toString() ?? '01d',
        windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
        humidity: (main['humidity'] as num?)?.toDouble() ?? 0.0,
        rainChance: pop,
        isRaining: mainText.contains('rain') || description.toLowerCase().contains('rain') || pop >= 0.5,
      );
    }).toList(growable: false);
  }
}
