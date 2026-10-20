import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final instance = AppSettings();
  final Map<String, bool> _values = {
    'notification': true,
    'sound': true,
    'vibration': false,
    'darkMode': false,
  };
  String _alertFilter = 'all';
  SharedPreferences? _prefs;
  Future<void>? _initializing;
  final ValueNotifier<bool> darkModeChanges = ValueNotifier(false);

  bool get darkMode => _values['darkMode']!;
  bool get sensorAlertsEnabled => _values['notification']!;
  bool value(String key) => _values[key]!;
  String get alertFilter => _alertFilter;

  Future<void> initialize() => _initializing ??= _load();

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    for (final key in _values.keys) {
      _values[key] = _prefs!.getBool(key) ?? _values[key]!;
    }
    final savedFilter = _prefs!.getString('alertFilter');
    if (const {'all', 'critical', 'warning', 'info'}.contains(savedFilter)) {
      _alertFilter = savedFilter!;
    }
    darkModeChanges.value = darkMode;
    notifyListeners();
  }

  Future<void> setValue(String key, bool value) async {
    await initialize();
    if (!_values.containsKey(key)) throw ArgumentError.value(key);
    if (_values[key] == value) return;
    if (!await _prefs!.setBool(key, value)) {
      throw StateError('Unable to save this setting');
    }
    _values[key] = value;
    if (key == 'darkMode') darkModeChanges.value = value;
    notifyListeners();
  }

  Future<void> setAlertFilter(String value) async {
    await initialize();
    if (!const {'all', 'critical', 'warning', 'info'}.contains(value)) {
      throw ArgumentError.value(value, 'value');
    }
    if (_alertFilter == value) return;
    if (!await _prefs!.setString('alertFilter', value)) {
      throw StateError('Unable to save this setting');
    }
    _alertFilter = value;
    notifyListeners();
  }

  @override
  void dispose() {
    darkModeChanges.dispose();
    super.dispose();
  }
}
