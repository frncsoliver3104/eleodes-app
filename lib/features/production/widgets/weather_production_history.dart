import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ELEODES/features/production/services/weather_history_service.dart';
import 'package:ELEODES/features/production/widgets/production_comparison.dart';

class WeatherProductionHistory extends StatefulWidget {
  const WeatherProductionHistory({
    super.key,
    required this.today,
    required this.records,
    required this.weather,
    required this.background,
    required this.foreground,
    this.totalProduction,
  });
  final DateTime today;
  final Map<String, double> records;
  final Map<String, DailyWeather> weather;
  final Color background;
  final Color foreground;
  final double? totalProduction;
  @override
  State<WeatherProductionHistory> createState() =>
      _WeatherProductionHistoryState();
}

class _WeatherProductionHistoryState extends State<WeatherProductionHistory> {
  final _root = FirebaseDatabase.instance.ref('AWG');
  Map<String, DailyWeather> _apiWeather = {};
  bool _busy = false;
  String _message = 'Weather uses the saved AWG location.';

  @override
  void initState() {
    super.initState();
    _loadSavedWeather();
  }

  Future<void> _loadSavedWeather() async {
    try {
      final locationSnapshot = await _root
          .child('weatherLocation')
          .get()
          .timeout(const Duration(seconds: 15));
      final saved = await _root
          .child('weatherApiByDate')
          .get()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;

      final location = locationSnapshot.value;
      if (location is! Map) {
        setState(() {
          _apiWeather = {};
          _message =
              'Set the AWG location while near the device to load its weather.';
        });
        return;
      }
      final lat = double.tryParse('${location['latitude']}');
      final lon = double.tryParse('${location['longitude']}');
      if (lat == null ||
          lon == null ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat.abs() > 90 ||
          lon.abs() > 180) {
        setState(() {
          _apiWeather = {};
          _message = 'The saved AWG location is invalid. Set it again nearby.';
        });
        return;
      }

      final cached = <String, DailyWeather>{};
      if (saved.value is Map) {
        for (final entry in (saved.value as Map).entries) {
          final value = entry.value;
          if (value is Map &&
              double.tryParse('${value['latitude']}') == lat &&
              double.tryParse('${value['longitude']}') == lon) {
            cached[entry.key.toString()] = DailyWeather.fromMap(value);
          }
        }
      }
      setState(() {
        _apiWeather = cached;
        _message = cached.isEmpty
            ? 'AWG location is saved. Tap Refresh weather to load weather.'
            : '';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not load saved weather. Check connection.',
        );
      }
    }
  }

  Future<void> _refresh({bool setLocation = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (setLocation) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw StateError('Turn on location services, then try again.');
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw StateError(
            'Location permission is needed. Enable it in phone settings.',
          );
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
        if (!mounted) return;
        // An approximate fixed site, not ongoing phone tracking.
        await _root
            .child('weatherLocation')
            .set({
              'latitude': double.parse(position.latitude.toStringAsFixed(2)),
              'longitude': double.parse(position.longitude.toStringAsFixed(2)),
              'updatedAt': ServerValue.timestamp,
            })
            .timeout(const Duration(seconds: 15));
        _apiWeather = {};
      }
      final saved = await _root
          .child('weatherApiByDate')
          .get()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final snapshot = await _root
          .child('weatherLocation')
          .get()
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final location = snapshot.value;
      if (location is! Map) {
        _apiWeather = {};
        setState(
          () => _message =
              'Set the AWG location while near the device to load its weather.',
        );
        return;
      }
      final lat = double.tryParse('${location['latitude']}');
      final lon = double.tryParse('${location['longitude']}');
      if (lat == null ||
          lon == null ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat.abs() > 90 ||
          lon.abs() > 180) {
        throw StateError('Set a valid AWG location.');
      }
      // Never show cached weather from a previously selected site.
      _apiWeather = {
        if (saved.value is Map)
          for (final entry in (saved.value as Map).entries)
            if (entry.value is Map &&
                entry.value['latitude'] == lat &&
                entry.value['longitude'] == lon)
              entry.key.toString(): DailyWeather.fromMap(entry.value as Map),
      };
      final result = await WeatherHistoryService.fetch(lat, lon);
      if (!mounted) return;
      if (result.isEmpty) {
        throw StateError('No weather readings available. Try again later.');
      }
      setState(() {
        _apiWeather = result.map(
          (key, value) => MapEntry(key, DailyWeather.fromMap(value)),
        );
        final stamp = DateTime.now().toUtc().add(const Duration(hours: 8));
        _message =
            'Weather refreshed ${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')} (Philippine time) for the saved AWG location';
      });
      try {
        await _root
            .child('weatherApiByDate')
            .update(result)
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        if (mounted) {
          setState(() => _message += ' · Could not save weather history.');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is StateError
              ? error.message
              : 'Weather unavailable. Check internet and retry. Saved readings may be out of date.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ProductionComparison(
    today: widget.today,
    records: widget.records,
    totalProduction: widget.totalProduction,
    weather: {...widget.weather, ..._apiWeather},
    background: widget.background,
    foreground: widget.foreground,
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : () => _refresh(setLocation: true),
                  style: _locationButtonStyle,
                  icon: const Icon(Icons.my_location, size: 14),
                  label: const Text('Set AWG location'),
                ),
                Tooltip(
                  message:
                      'Saves your phone’s current location as the AWG site. Use this only while near the AWG; it will not track your phone afterward.',
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 5),
                  child: Semantics(
                    button: true,
                    label: 'Set AWG location help',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 14,
                        color: widget.foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Tooltip(
              message:
                  'Fetches updated Open-Meteo weather for the saved AWG location without changing that location.',
              child: TextButton.icon(
                onPressed: _busy ? null : () => _refresh(),
                style: _locationButtonStyle,
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Refresh weather'),
              ),
            ),
          ],
        ),
        if (_busy || _message.isNotEmpty) Semantics(
          liveRegion: true,
          child: Text(
            _busy ? 'Loading weather…' : _message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: widget.foreground),
          ),
        ),
      ],
    ),
  );
  ButtonStyle get _locationButtonStyle => TextButton.styleFrom(
    backgroundColor: const Color(0xFF1DE3AB),
    foregroundColor: Colors.black,
    disabledBackgroundColor: const Color(0xFFE0E0E0),
    disabledForegroundColor: const Color(0xFF616161),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    minimumSize: const Size(0, 32),
    tapTargetSize: MaterialTapTargetSize.padded,
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 12),
  );
}
