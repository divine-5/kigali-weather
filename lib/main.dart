import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather.dart';

void main() {
runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
const WeatherApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Weather App',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
useMaterial3: true,
),
home: const WeatherScreen(),
);
}
}

class WeatherScreen extends StatefulWidget {
const WeatherScreen({super.key});

@override
State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
Weather? weather;
String? errorMessage;
bool isLoading = true;
City selectedCity = cities[0];

@override
void initState() {
super.initState();
initializeApp();
}

Future<void> initializeApp() async {
final prefs = await SharedPreferences.getInstance();
final savedCityName = prefs.getString('selectedCity');

if (savedCityName != null && mounted) {
setState(() {
selectedCity = cities.firstWhere(
(city) => city.name == savedCityName,
orElse: () => cities[0],
);
});
}

await loadWeather(selectedCity);
}

Future<void> selectCity(City city) async {
setState(() {
selectedCity = city;
});

final prefs = await SharedPreferences.getInstance();
await prefs.setString('selectedCity', city.name);

await loadWeather(city);
}

Future<void> loadWeather([City? city]) async {
final cityToLoad = city ?? selectedCity;

setState(() {
isLoading = true;
errorMessage = null;
});

try {
final result = await fetchWeather(cityToLoad).timeout(
const Duration(seconds: 15),
);

if (!mounted) return;

setState(() {
weather = result;
isLoading = false;
});
} catch (_) {
if (!mounted) return;

setState(() {
errorMessage =
'Unable to load weather. Please check your internet connection.';
isLoading = false;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text('${selectedCity.name} Weather'),
),
body: RefreshIndicator(
onRefresh: () => loadWeather(selectedCity),
child: ListView(
physics: const AlwaysScrollableScrollPhysics(),
children: [
Padding(
padding: const EdgeInsets.all(12),
child: Wrap(
spacing: 8,
alignment: WrapAlignment.center,
children: cities.map((city) {
return ChoiceChip(
label: Text(city.name),
selected: selectedCity.name == city.name,
onSelected: (selected) {
if (selected) {
selectCity(city);
}
},
);
}).toList(),
),
),
SizedBox(
height: MediaQuery.of(context).size.height * 0.7,
child: Center(
child: isLoading
? const CircularProgressIndicator()
    : errorMessage != null
? Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.cloud_off,
size: 48,
),
const SizedBox(height: 12),
Padding(
padding: const EdgeInsets.symmetric(
horizontal: 24,
),
child: Text(
errorMessage!,
textAlign: TextAlign.center,
),
),
const SizedBox(height: 12),
ElevatedButton(
onPressed: () => loadWeather(selectedCity),
child: const Text('Retry'),
),
],
)
    : Card(
margin: const EdgeInsets.all(24),
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'${weather!.temperature}°C',
style: const TextStyle(
fontSize: 48,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
Text(
weatherDescription(weather!.code),
style: const TextStyle(fontSize: 20),
),
const SizedBox(height: 24),
Text('Humidity: ${weather!.humidity}%'),
Text('Wind: ${weather!.wind} km/h'),
const SizedBox(height: 16),
Text('Updated at: ${weather!.time}'),
],
),
),
),
),
),
],
),
),
);
}
}

