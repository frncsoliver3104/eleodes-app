import 'ph_indication.dart';

class SensorAlert {
  final String key;
  final String title;
  final String message;
  final String type;
  const SensorAlert(this.key, this.title, this.message, this.type);
}

/// Alerts on entry into a condition, with hysteresis to avoid sensor chatter.
class SensorAlertEvaluator {
  final Set<String> _active = {};
  static const double nearlyFullPercent = 90;
  static const double lowWaterPercent = 20;
  static const double lowWaterRecoveryPercent = 25;

  void reset() => _active.clear();
  void retry(String key) => _active.remove(key);

  List<SensorAlert> evaluate({
    required bool enabled,
    required bool online,
    double? temperature,
    double? humidity,
    double? waterLevel,
    double? ph,
    bool tankFull = false,
  }) {
    if (!enabled) {
      reset();
      return [];
    }
    if (!online) return [];
    final alerts = <SensorAlert>[];
    void check(
      String key,
      bool triggered,
      bool recovered,
      String title,
      String message,
      String type,
    ) {
      if (recovered) _active.remove(key);
      if (triggered && _active.add(key)) {
        alerts.add(SensorAlert(key, title, message, type));
      }
    }

    if (temperature != null && temperature.isFinite) {
      check(
        'temperature',
        temperature >= 35,
        temperature < 34,
        'High Temperature',
        'Temperature reached ${temperature.toStringAsFixed(0)}°C.',
        'danger',
      );
    }
    if (humidity != null &&
        humidity.isFinite &&
        humidity >= 0 &&
        humidity <= 100) {
      check(
        'humidity',
        humidity >= 90,
        humidity < 88,
        'High Humidity',
        'Humidity reached ${humidity.toStringAsFixed(0)}%.',
        'warning',
      );
    }
    final validWater =
        waterLevel != null &&
        waterLevel.isFinite &&
        waterLevel >= 0 &&
        waterLevel <= 100;
    final full = tankFull || (validWater && waterLevel >= 100);
    check(
      'tankFull',
      full,
      !full && validWater && waterLevel < 95,
      'Water Tank Full',
      'The water tank is full. Please check the tank.',
      'info',
    );
    if (full) _active.add('tankNearlyFull');
    if (validWater) {
      check(
        'tankLow',
        !full && waterLevel <= lowWaterPercent,
        waterLevel > lowWaterRecoveryPercent,
        'Low Water Level',
        'Water level is low. Please refill or check the water tank.',
        'warning',
      );
      check(
        'tankNearlyFull',
        !full && waterLevel >= nearlyFullPercent,
        waterLevel < 85,
        'Water Tank Nearly Full',
        'The water tank is ${waterLevel.toStringAsFixed(0)}% full.',
        'warning',
      );
    }
    if (ph != null && ph.isFinite && ph >= 0 && ph <= 14) {
      // Use the nearest whole-number chart entry, retaining the actual reading.
      final level = ph.round();
      final indication = PhIndication.chart[level];
      final status = PhIndication.status(ph);
      final key = 'ph_${level}_$status';
      final extreme = ph <= 3 || ph >= 12;
      final severityKey = '${key}_${extreme ? 'extreme' : 'regular'}';
      if (!_active.contains(severityKey)) {
        _active.removeWhere((entry) => entry.startsWith('ph_'));
        _active.add(severityKey);
        alerts.add(
          SensorAlert(
            severityKey,
            'pH Level: ${ph.toStringAsFixed(2)}',
            'Approximate indicator: ${indication.color}; '
                '${indication.classification} (chart pH $level). '
                '${PhIndication.guidance(ph)}',
            extreme ? 'danger' : (status == 'normal' ? 'info' : 'warning'),
          ),
        );
      }
    }
    return alerts;
  }
}
