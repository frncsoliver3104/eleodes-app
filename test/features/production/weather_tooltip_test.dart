import 'package:ELEODES/features/production/widgets/production_comparison.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in <(int?, double), String>{
    (3, 0): '☁️ Overcast',
    (2, 0): '🌤️ Partly Cloudy',
    (0, 0): '☀️ Sunny',
    (0, 30): '💨 Windy',
    (61, 0): '🌧️ Light Rain',
    (65, 40): '🌧️ Heavy Rain',
    (95, 0): '⛈️ Thunderstorm',
    (45, 0): '🌫️ Fog',
    (71, 0): '❄️ Snow',
    (null, 0): '❔ Weather not recorded',
  }.entries) {
    for (final width in [320.0, 570.0]) {
      testWidgets('${entry.value} is visible without tapping at width $width', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final today = DateTime.utc(2026, 10, 5);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProductionComparison(
                  today: today,
                  records: const {},
                  weather: {
                    for (var i = 0; i < 7; i++)
                      productionDateKey(
                        today.subtract(Duration(days: i)),
                      ): DailyWeather(
                        humidity: 99,
                        weatherCode: entry.key.$1,
                        windSpeed: entry.key.$2,
                      ),
                  },
                  background: Colors.grey,
                  foreground: Colors.black,
                ),
              ),
            ),
          ),
        );
        expect(find.text(entry.value), findsNWidgets(7));
        expect(find.text('99%'), findsNothing);
        expect(find.byType(Tooltip), findsNothing);
        expect(find.text('Excellent\nOptimal air moisture'), findsNWidgets(7));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
