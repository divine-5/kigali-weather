import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class City {
  final String name;
  final double latitude;
  final double longitude;

  const City({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

const List<City> cities = [
  City(name: 'Kigali', latitude: -1.9441, longitude: 30.0619),
  City(name: 'London', latitude: 51.5072, longitude: -0.1276),
  City(name: 'Tokyo', latitude: 35.6762, longitude: 139.6503),
];

class Weather {
  final double temperature;
  final int humidity;
  final double wind;
  final int code;
  final String time;

  const Weather({
    required this.temperature,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.time,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      wind: (json['wind'] as num).toDouble(),
      code: (json['code'] as num).toInt(),
      time: json['time']?.toString() ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'wind': wind,
      'code': code,
      'time': time,
    };
  }
}

Future<Weather> fetchWeather(City city) async {
  final uri = Uri.https(
    'api.open-meteo.com',
    '/v1/forecast',
    {
      'latitude': city.latitude.toString(),
      'longitude': city.longitude.toString(),
      'current':
      'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
      'timezone': 'auto',
    },
  );

  final response = await http.get(uri).timeout(
    const Duration(seconds: 10),
  );

  if (response.statusCode != 200) {
    throw Exception('Weather service returned ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final current = data['current'] as Map<String, dynamic>;

  final weather = Weather(
    temperature: (current['temperature_2m'] as num).toDouble(),
    humidity: (current['relative_humidity_2m'] as num).toInt(),
    wind: (current['wind_speed_10m'] as num).toDouble(),
    code: (current['weather_code'] as num).toInt(),
    time: current['time']?.toString() ?? 'Unknown',
  );

  await saveCachedWeather(city, weather);
  return weather;
}

Future<void> saveCachedWeather(City city, Weather weather) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'weather_${city.name}',
    jsonEncode(weather.toJson()),
  );
}

Future<Weather?> loadCachedWeather(City city) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedData = prefs.getString('weather_${city.name}');

  if (cachedData == null) {
    return null;
  }

  try {
    final json = jsonDecode(cachedData) as Map<String, dynamic>;
    return Weather.fromJson(json);
  } catch (_) {
    return null;
  }
}

String weatherDescription(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 3) return 'Partly cloudy';
  if (code == 45 || code == 48) return 'Fog';
  if (code >= 51 && code <= 67) return 'Drizzle or rain';
  if (code >= 71 && code <= 77) return 'Snow';
  if (code >= 80 && code <= 82) return 'Rain showers';
  if (code >= 85 && code <= 86) return 'Snow showers';
  if (code >= 95) return 'Thunderstorm';
  return 'Unknown weather';
}