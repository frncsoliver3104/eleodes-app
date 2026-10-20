import 'dart:convert';
import 'package:http/http.dart' as http;

/// Open-Meteo model data, never a substitute for the AWG flow meter.
class WeatherHistoryService {
  static Future<Map<String, Map<String, dynamic>>> fetch(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'hourly':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'past_days': '6',
      'forecast_days': '1',
      'timezone': 'Asia/Manila',
      'timeformat': 'unixtime',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Weather service unavailable');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final records = parse(root, DateTime.now().toUtc());
    for (final record in records.values) {
      record['latitude'] = latitude;
      record['longitude'] = longitude;
    }
    return records;
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Map<String, Map<String, dynamic>> parse(
    Map<String, dynamic> root,
    DateTime now,
  ) {
    final hourly = root['hourly'] as Map?;
    final times = hourly?['time'] as List? ?? [];
    final groups = <String, List<Map<String, num>>>{};
    num? value(String field, int index) {
      final entries = hourly?[field];
      if (entries is! List || index >= entries.length) return null;
      final item = entries[index];
      return item is num && item.isFinite ? item : null;
    }

    final today = now.toUtc().add(const Duration(hours: 8));
    final first = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    for (var i = 0; i < times.length; i++) {
      final timestamp = times[i];
      if (timestamp is! num || !timestamp.isFinite) continue;
      final utc = DateTime.fromMillisecondsSinceEpoch(
        timestamp.toInt() * 1000,
        isUtc: true,
      );
      final local = utc.add(const Duration(hours: 8));
      if (utc.isAfter(now) || local.isBefore(first)) continue;
      final humidity = value('relative_humidity_2m', i);
      final temperature = value('temperature_2m', i);
      final code = value('weather_code', i);
      final wind = value('wind_speed_10m', i);
      if (humidity == null ||
          humidity < 0 ||
          humidity > 100 ||
          temperature == null ||
          code == null) {
        continue;
      }
      groups.putIfAbsent(dateKey(local), () => []).add({
        'humidity': humidity,
        'temperature': temperature,
        'weatherCode': code,
        if (wind != null) 'windSpeed': wind,
      });
    }
    final output = <String, Map<String, dynamic>>{};
    for (final entry in groups.entries) {
      final rows = entry.value;
      final counts = <int, int>{};
      for (final row in rows) {
        final code = row['weatherCode']!.toInt();
        counts[code] = (counts[code] ?? 0) + 1;
      }
      final dominant = counts.keys.reduce(
        (a, b) => counts[a]! >= counts[b]! ? a : b,
      );
      output[entry.key] = {
        'humidity':
            rows.fold<double>(0, (s, r) => s + r['humidity']!) / rows.length,
        'temperature':
            rows.fold<double>(0, (s, r) => s + r['temperature']!) / rows.length,
        'weatherCode': dominant,
        'source': 'Open-Meteo',
        'aggregation': 'daily_hourly_mean',
        'samples': rows.length,
        'fetchedAt': now.millisecondsSinceEpoch,
      };
    }
    final current = root['current'];
    if (current is Map &&
        current['time'] is num &&
        current['relative_humidity_2m'] is num &&
        current['weather_code'] is num) {
      final humidity = current['relative_humidity_2m'] as num;
      final observed = DateTime.fromMillisecondsSinceEpoch(
        (current['time'] as num).toInt() * 1000,
        isUtc: true,
      );
      if (humidity.isFinite &&
          humidity >= 0 &&
          humidity <= 100 &&
          dateKey(observed.add(const Duration(hours: 8))) == dateKey(today)) {
        output[dateKey(today)] = {
          'humidity': humidity,
          'temperature': current['temperature_2m'],
          'weatherCode': current['weather_code'],
          'windSpeed': current['wind_speed_10m'],
          'source': 'Open-Meteo',
          'aggregation': 'current',
          'observedAt': observed.millisecondsSinceEpoch,
          'fetchedAt': now.millisecondsSinceEpoch,
        };
      }
    }
    return output;
  }
}
