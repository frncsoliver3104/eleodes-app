import 'package:ELEODES/features/dashboard/models/live_water_readings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 20);

  test('tank and flow load without a temperature or humidity reading', () {
    final reading = LiveWaterReadings.fromMap({
      'lastSeen': now.millisecondsSinceEpoch,
      'waterLevel': 80,
      'water': 8,
      'flowRate': 1270,
    }, now: now);

    expect(reading.tankPercent, 80);
    expect(reading.flowLitersPerDay, 1270);
  });

  test(
    'old Firebase values do not appear as live readings after reopening',
    () {
      final reading = LiveWaterReadings.fromMap({
        'lastSeen': now
            .subtract(const Duration(minutes: 2))
            .millisecondsSinceEpoch,
        'waterLevel': 80,
        'flowRate': 1270,
      }, now: now);

      expect(reading.tankPercent, isNull);
      expect(reading.flowLitersPerDay, isNull);
    },
  );

  test('current zeros replace an earlier nonzero reading', () {
    final previous = LiveWaterReadings.fromMap({
      'lastSeen': now
          .subtract(const Duration(seconds: 5))
          .millisecondsSinceEpoch,
      'waterLevel': 80,
      'flowRate': 1270,
    }, now: now);
    final current = LiveWaterReadings.fromMap({
      'lastSeen': now.millisecondsSinceEpoch,
      'waterLevel': 0,
      'flowRate': 0,
    }, now: now);

    expect(previous.tankPercent, 80);
    expect(current.tankPercent, 0);
    expect(current.flowLitersPerDay, 0);
  });

  test('a recent cached record stays hidden while Firebase is offline', () {
    final reading = LiveWaterReadings.fromMap(
      {
        'lastSeen': now.millisecondsSinceEpoch,
        'waterLevel': 80,
        'flowRate': 1270,
      },
      now: now,
      serverConnected: false,
    );

    expect(reading.tankPercent, isNull);
    expect(reading.flowLitersPerDay, isNull);
  });

  test(
    'invalid fields stay unavailable and distance is never a tank percent',
    () {
      for (final value in [null, 'bad', -1, double.nan, double.infinity]) {
        final reading = LiveWaterReadings.fromMap({
          'lastSeen': now.millisecondsSinceEpoch,
          'waterLevel': value,
          'flowRate': value,
          'water': 80,
        }, now: now);
        expect(reading.tankPercent, isNull);
        expect(reading.flowLitersPerDay, isNull);
      }
      expect(
        LiveWaterReadings.fromMap({
          'lastSeen': now.millisecondsSinceEpoch,
          'waterLevel': 101,
        }, now: now).tankPercent,
        isNull,
      );
    },
  );
}
