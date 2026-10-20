import 'package:ELEODES/features/dashboard/models/sensor_data.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('equivalent sensor updates compare equal; changed readings do not', () {
    const reading = SensorData(
      temperature: 25,
      humidity: 60,
      waterLevel: 50,
      ph: 7,
      system: true,
    );
    final repeat = SensorData.fromMap({
      'temperature': 25,
      'humidity': 60,
      'waterLevel': 50,
      'ph': 7,
    }, true);
    expect(repeat, reading);
    expect(repeat.hashCode, reading.hashCode);
    for (final key in ['temperature', 'humidity', 'waterLevel', 'ph']) {
      final values = {
        'temperature': 25,
        'humidity': 60,
        'waterLevel': 50,
        'ph': 7,
      };
      values[key] = values[key]! + 1;
      expect(SensorData.fromMap(values, true), isNot(reading));
    }
    expect(
      SensorData.fromMap({
        'temperature': 25,
        'humidity': 60,
        'waterLevel': 50,
        'ph': 7,
      }, false),
      isNot(reading),
    );
  });

  test('notification settings do not trigger app theme rebuilds', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.initialize();
    var themeUpdates = 0;
    var settingsUpdates = 0;
    settings.darkModeChanges.addListener(() => themeUpdates++);
    settings.addListener(() => settingsUpdates++);
    await settings.setValue('sound', false);
    await settings.setValue('notification', false);
    expect(settingsUpdates, 2);
    expect(themeUpdates, 0);
    await settings.setValue('darkMode', true);
    expect(themeUpdates, 1);
    await settings.setValue('darkMode', true);
    expect(themeUpdates, 1);
    expect(settingsUpdates, 3);
    settings.dispose();
  });
}
