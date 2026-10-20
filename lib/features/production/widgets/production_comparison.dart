import 'package:flutter/material.dart';

class DailyWeather {
  const DailyWeather({
    this.humidity,
    this.temperature,
    this.condition,
    this.weatherCode,
    this.windSpeed,
  });
  final double? humidity;
  final double? temperature;
  final String? condition;
  final int? weatherCode;
  final double? windSpeed;

  factory DailyWeather.fromMap(Map value) {
    double? number(dynamic raw) {
      final parsed = double.tryParse('$raw');
      return parsed != null && parsed.isFinite ? parsed : null;
    }

    final humidity = number(value['humidity']);
    final condition = value['condition']?.toString().trim();
    return DailyWeather(
      humidity: humidity != null && humidity >= 0 && humidity <= 100
          ? humidity
          : null,
      temperature: number(value['temperature']),
      condition: condition == null || condition.isEmpty ? null : condition,
      weatherCode: number(value['weatherCode'])?.toInt(),
      windSpeed: number(value['windSpeed'])?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DailyWeather &&
      humidity == other.humidity &&
      temperature == other.temperature &&
      condition == other.condition &&
      weatherCode == other.weatherCode &&
      windSpeed == other.windSpeed;
  @override
  int get hashCode =>
      Object.hash(humidity, temperature, condition, weatherCode, windSpeed);
}

String moistureStatus(double? humidity) {
  if (humidity == null || !humidity.isFinite || humidity < 0 || humidity > 100) {
    return 'Not recorded';
  }
  if (humidity >= 80) return 'Excellent\nOptimal air moisture';
  if (humidity >= 70) return 'Optimal\nGreat air moisture';
  if (humidity >= 45) return 'Moderate\nFair air moisture';
  return 'Low\nPoor air moisture';
}

(String, String) weatherSymbol(DailyWeather? weather) {
  final code = weather?.weatherCode;
  if (code == null) return ('❔', 'Weather not recorded');
  if (code >= 95) return ('⛈️', 'Thunderstorm');
  if ([65, 67, 82].contains(code)) return ('🌧️', 'Heavy Rain');
  if ([51, 53, 55, 56, 57, 61, 63, 66, 80, 81].contains(code)) {
    return ('🌧️', 'Light Rain');
  }
  if ([71, 73, 75, 77, 85, 86].contains(code)) return ('❄️', 'Snow');
  if (code == 45 || code == 48) return ('🌫️', 'Fog');
  if ((weather?.windSpeed ?? 0) >= 25) return ('💨', 'Windy');
  if (code == 3) return ('☁️', 'Overcast');
  if (code == 1 || code == 2) return ('🌤️', 'Partly Cloudy');
  if (code == 0) return ('☀️', 'Sunny');
  return ('❔', 'Unknown weather');
}

String productionDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class ProductionComparison extends StatelessWidget {
  const ProductionComparison({
    super.key,
    required this.today,
    required this.records,
    required this.weather,
    required this.background,
    required this.foreground,
    this.footer,
    this.totalProduction,
  });
  final DateTime today;
  final Map<String, double> records;
  final Map<String, DailyWeather> weather;
  final Color background;
  final Color foreground;
  final Widget? footer;
  final double? totalProduction;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(7, (i) => today.subtract(Duration(days: i)));
    final previous = List.generate(
      7,
      (i) => today.subtract(Duration(days: i + 7)),
    );
    List<double> readings(List<DateTime> days) => days
        .map((day) => records[productionDateKey(day)])
        .whereType<double>()
        .toList();
    final currentValues = readings(dates);
    final previousValues = readings(previous);
    double total(List<double> values) =>
        values.fold(0.0, (sum, value) => sum + value);
    final sum = total(currentValues);
    final previousTotal = total(previousValues);
    final delta = sum - previousTotal;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    Widget cell(String text, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
    return DefaultTextStyle(
      style: TextStyle(color: foreground, fontSize: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily & Weekly Production',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                if (totalProduction != null &&
                    totalProduction!.isFinite &&
                    totalProduction! >= 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total yield: ${totalProduction!.toStringAsFixed(3)} L',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  currentValues.isEmpty
                      ? 'Last 7 days: no production records'
                      : 'Last 7 days: ${sum.toStringAsFixed(1)} L · ${currentValues.length}/7 days recorded',
                ),
                const SizedBox(height: 4),
                Text(
                  previousValues.isEmpty
                      ? 'Previous 7 days: no production records'
                      : 'Previous 7 days: ${previousTotal.toStringAsFixed(1)} L · ${previousValues.length}/7 days recorded',
                ),
                if (currentValues.length == 7 && previousValues.length == 7)
                  Text(
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} L versus previous period (today may be incomplete)',
                  ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: constraints.maxWidth < 280
                          ? 280
                          : constraints.maxWidth,
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(.75),
                          1: FlexColumnWidth(1.15),
                          2: FlexColumnWidth(.95),
                          3: FlexColumnWidth(1.65),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            children: [
                              cell('Date', bold: true),
                              cell('Day &\nWeather', bold: true),
                              cell('Water\nYields', bold: true),
                              cell('Status &\nYield', bold: true),
                            ],
                          ),
                          for (final date in dates)
                            TableRow(
                              children: [
                                cell(
                                  '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
                                  bold: true,
                                ),
                                _weatherCell(
                                  days[date.weekday - 1],
                                  weather[productionDateKey(date)],
                                ),
                                cell(
                                  records.containsKey(productionDateKey(date))
                                      ? '${records[productionDateKey(date)]!.toStringAsFixed(1)} L'
                                      : '--',
                                  bold: true,
                                ),
                                cell(
                                  moistureStatus(
                                    weather[productionDateKey(date)]?.humidity,
                                  ),
                                  bold: true,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: 12), footer!],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherCell(String day, DailyWeather? weather) {
    final (emoji, description) = weatherSymbol(weather);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '$emoji $description',
            semanticsLabel: description,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
