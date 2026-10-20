import 'package:ELEODES/features/notifications/services/sensor_alert_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SensorAlertEvaluator evaluator;
  setUp(() => evaluator = SensorAlertEvaluator());

  test('all 15 pH chart entries produce color and classification messages', () {
    const colors = [
      'Deep Red',
      'Red',
      'Red-Orange',
      'Orange',
      'Light Orange',
      'Yellow',
      'Yellow-Green',
      'Pure Green',
      'Blue-Green',
      'Light Blue',
      'Deep Blue',
      'Violet',
      'Deep Violet',
      'Purple',
      'Deep Purple',
    ];
    for (var level = 0; level <= 14; level++) {
      final alert = evaluator
          .evaluate(enabled: true, online: true, ph: level.toDouble())
          .single;
      expect(alert.message, contains('${colors[level]};'));
      expect(alert.message, contains('chart pH $level'));
      expect(
        alert.type,
        level <= 3 || level >= 12
            ? 'danger'
            : (level == 7 || level == 8 ? 'info' : 'warning'),
      );
    }
  });

  test('pH alerts suppress repeats and report range transitions', () {
    List<SensorAlert> read(double ph) =>
        evaluator.evaluate(enabled: true, online: true, ph: ph);
    expect(read(6.4).single.type, 'warning');
    expect(read(6.45), isEmpty);
    final normal = read(6.5).single;
    expect(normal.type, 'info');
    expect(normal.message, contains('pH alone does not confirm'));
    expect(read(7), isEmpty);
    expect(read(7.1), isEmpty);
    expect(read(8.5).single.type, 'info');
    expect(read(8.51).single.type, 'warning');
    expect(read(9), isEmpty);
    expect(read(12).single.type, 'danger');
    evaluator.retry('ph_12_high_extreme');
    expect(read(12), hasLength(1));
  });

  test('pH ignores missing, invalid, disabled and offline readings', () {
    for (final ph in <double?>[null, -1, 15, double.nan, double.infinity]) {
      expect(evaluator.evaluate(enabled: true, online: true, ph: ph), isEmpty);
    }
    expect(evaluator.evaluate(enabled: false, online: true, ph: 0), isEmpty);
    expect(evaluator.evaluate(enabled: true, online: false, ph: 0), isEmpty);
    expect(
      evaluator.evaluate(enabled: true, online: true, ph: 0),
      hasLength(1),
    );
    evaluator.reset();
    expect(
      evaluator.evaluate(enabled: true, online: true, ph: 0),
      hasLength(1),
    );
  });

  test('normal and missing readings do not trigger alerts', () {
    expect(evaluator.evaluate(enabled: true, online: true), isEmpty);
    expect(
      evaluator.evaluate(
        enabled: true,
        online: true,
        temperature: 25,
        humidity: 60,
        waterLevel: 50,
      ),
      isEmpty,
    );
  });

  test('sensor thresholds alert once and rearm after recovery', () {
    List<SensorAlert> read(double temp, double humidity) => evaluator.evaluate(
      enabled: true,
      online: true,
      temperature: temp,
      humidity: humidity,
    );
    expect(read(35, 90).map((a) => a.key), ['temperature', 'humidity']);
    expect(read(36, 91), isEmpty);
    expect(read(34.9, 89), isEmpty);
    expect(read(35, 90), isEmpty);
    expect(read(33, 87), isEmpty);
    expect(read(35, 90), hasLength(2));
  });

  test('nearly full at 90%, full at 100%, rearm below 85%', () {
    List<SensorAlert> read(double level) =>
        evaluator.evaluate(enabled: true, online: true, waterLevel: level);
    expect(read(89), isEmpty);
    expect(read(90).single.key, 'tankNearlyFull');
    expect(read(92), isEmpty);
    expect(read(100).single.key, 'tankFull');
    expect(read(99), isEmpty);
    expect(read(84), isEmpty);
    expect(read(90).single.key, 'tankNearlyFull');
  });

  test('full sensor flag produces only full alert', () {
    expect(
      evaluator
          .evaluate(enabled: true, online: true, waterLevel: 95, tankFull: true)
          .map((a) => a.key),
      ['tankFull'],
    );
  });

  test('disabled and offline readings do not alert; enabling rearms', () {
    expect(
      evaluator.evaluate(
        enabled: false,
        online: true,
        temperature: 40,
        waterLevel: 95,
      ),
      isEmpty,
    );
    expect(
      evaluator.evaluate(
        enabled: true,
        online: false,
        temperature: 40,
        waterLevel: 95,
      ),
      isEmpty,
    );
    expect(
      evaluator.evaluate(
        enabled: true,
        online: true,
        temperature: 40,
        waterLevel: 95,
      ),
      hasLength(2),
    );
    evaluator.evaluate(enabled: false, online: true);
    expect(
      evaluator.evaluate(
        enabled: true,
        online: true,
        temperature: 40,
        waterLevel: 95,
      ),
      hasLength(2),
    );
  });

  test('invalid sensor values cannot generate alerts', () {
    expect(
      evaluator.evaluate(
        enabled: true,
        online: true,
        temperature: double.nan,
        humidity: 101,
        waterLevel: double.infinity,
      ),
      isEmpty,
    );
  });

  test('low water alerts at 20% and only rearms above 25%', () {
    List<SensorAlert> read(double level) =>
        evaluator.evaluate(enabled: true, online: true, waterLevel: level);
    expect(read(20.1), isEmpty);
    final alert = read(20).single;
    expect(alert.key, 'tankLow');
    expect(alert.title, 'Low Water Level');
    expect(
      alert.message,
      'Water level is low. Please refill or check the water tank.',
    );
    expect(alert.type, 'warning');
    expect(read(10), isEmpty);
    expect(read(0), isEmpty);
    expect(read(25), isEmpty);
    expect(read(20), isEmpty);
    expect(read(25.1), isEmpty);
    expect(read(19).single.key, 'tankLow');
  });

  test('empty tank alerts but missing and invalid levels do not', () {
    for (final level in <double?>[
      null,
      -1,
      101,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        evaluator.evaluate(enabled: true, online: true, waterLevel: level),
        isEmpty,
      );
    }
    expect(
      evaluator.evaluate(enabled: true, online: true, waterLevel: 0).single.key,
      'tankLow',
    );
    evaluator.evaluate(enabled: true, online: true, waterLevel: 101);
    expect(
      evaluator.evaluate(enabled: true, online: true, waterLevel: 10),
      isEmpty,
    );
  });

  test('low water respects notification switch and connection status', () {
    expect(
      evaluator.evaluate(enabled: false, online: true, waterLevel: 10),
      isEmpty,
    );
    expect(
      evaluator.evaluate(enabled: true, online: false, waterLevel: 10),
      isEmpty,
    );
    expect(
      evaluator
          .evaluate(enabled: true, online: true, waterLevel: 10)
          .single
          .key,
      'tankLow',
    );
    evaluator.evaluate(enabled: true, online: false, waterLevel: 50);
    expect(
      evaluator.evaluate(enabled: true, online: true, waterLevel: 10),
      isEmpty,
    );
    evaluator.evaluate(enabled: false, online: true, waterLevel: 10);
    expect(
      evaluator
          .evaluate(enabled: true, online: true, waterLevel: 10)
          .single
          .key,
      'tankLow',
    );
  });

  test(
    'full flag prevents contradictory low water and failed delivery retries',
    () {
      expect(
        evaluator
            .evaluate(
              enabled: true,
              online: true,
              waterLevel: 10,
              tankFull: true,
            )
            .map((alert) => alert.key),
        ['tankFull'],
      );
      expect(
        evaluator
            .evaluate(enabled: true, online: true, waterLevel: 10)
            .single
            .key,
        'tankLow',
      );
      evaluator.retry('tankLow');
      expect(
        evaluator
            .evaluate(enabled: true, online: true, waterLevel: 10)
            .single
            .key,
        'tankLow',
      );
    },
  );
}
