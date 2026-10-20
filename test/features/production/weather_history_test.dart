import 'package:flutter_test/flutter_test.dart';
import 'package:ELEODES/features/production/services/weather_history_service.dart';
import 'package:ELEODES/features/production/widgets/production_comparison.dart';

void main() {
  test('moisture labels cover boundaries and invalid readings', () {
    expect(moistureStatus(44.9), startsWith('Low'));
    expect(moistureStatus(45), startsWith('Moderate'));
    expect(moistureStatus(69.9), startsWith('Moderate'));
    expect(moistureStatus(70), startsWith('Optimal'));
    expect(moistureStatus(79.9), startsWith('Optimal'));
    expect(moistureStatus(80), startsWith('Excellent'));
    expect(moistureStatus(100), startsWith('Excellent'));
    expect(moistureStatus(101), 'Not recorded');
    expect(moistureStatus(null), 'Not recorded');
  });

  test('weather history uses Philippine dates and excludes future hours', () {
    final now = DateTime.utc(2026, 9, 29, 2);
    int seconds(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
    final result = WeatherHistoryService.parse({
      'hourly': {
        'time': [
          seconds(DateTime.utc(2026, 9, 28, 14)),
          seconds(DateTime.utc(2026, 9, 28, 15)),
          seconds(DateTime.utc(2026, 9, 29, 3)),
        ],
        'relative_humidity_2m': [60, 80, 99],
        'temperature_2m': [26, 28, 32],
        'weather_code': [3, 3, 0],
      },
      'current': {
        'time': seconds(now),
        'relative_humidity_2m': 85,
        'temperature_2m': 27,
        'weather_code': 61,
        'wind_speed_10m': 8,
      },
    }, now);
    expect(result['2026-09-28']!['humidity'], 70);
    expect(result['2026-09-28']!['samples'], 2);
    expect(result['2026-09-29']!['humidity'], 85);
    expect(result['2026-09-29']!['aggregation'], 'current');
    expect(result.length, 2);
  });

  test(
    'rain icon takes priority over wind and missing codes remain unknown',
    () {
      expect(
        weatherSymbol(const DailyWeather(weatherCode: 65, windSpeed: 40)).$2,
        'Heavy Rain',
      );
      expect(
        weatherSymbol(const DailyWeather(weatherCode: 0, windSpeed: 30)).$2,
        'Windy',
      );
      expect(
        weatherSymbol(const DailyWeather(humidity: 90)).$2,
        'Weather not recorded',
      );
    },
  );
}
