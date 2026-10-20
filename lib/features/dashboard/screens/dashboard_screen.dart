import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:ELEODES/shared/widgets/tab_header.dart';
import 'package:ELEODES/features/dashboard/widgets/animated_water_tank.dart';
import 'package:ELEODES/features/production/widgets/production_history_section.dart';
import 'package:ELEODES/features/production/widgets/production_comparison.dart';
import 'package:ELEODES/features/devices/screens/wifi_connection_screen.dart';
import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:ELEODES/features/notifications/services/notification_service.dart';
import 'package:ELEODES/features/dashboard/models/sensor_data.dart';
import 'package:ELEODES/features/dashboard/models/live_water_readings.dart';
import 'package:ELEODES/features/devices/services/device_pairing_store.dart';
import 'package:ELEODES/features/devices/services/device_connection_status.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:ELEODES/features/notifications/services/sensor_alert_evaluator.dart';
import 'package:ELEODES/features/dashboard/widgets/dashboard_topbar.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onProceedToDevice;

  const DashboardScreen({super.key, this.onProceedToDevice});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  final DatabaseReference _awgRef = FirebaseDatabase.instance.ref('AWG');

  final DatabaseReference _controlRef = FirebaseDatabase.instance.ref(
    'AWG/control',
  );

  StreamSubscription<DatabaseEvent>? _awgSubscription;
  StreamSubscription<DatabaseEvent>? _firebaseConnectionSubscription;
  bool _databaseConnected = false;
  String? _listeningDeviceId;
  int _readingsGeneration = 0;
  bool _refreshingReadings = false;
  bool _refreshOnResume = false;

  Timer? _connectionTimer;
  Timer? _uptimeTimer;

  final NotificationService _notificationService = NotificationService();

  static const int _offlineTimeoutSeconds = 30;

  int? _lastSeenTimestamp;
  int? _lastReadingTimestamp;

  bool _hasReceivedFirebaseData = false;
  bool _machineConnected = false;

  bool _machineRunning = false;

  Duration _machineUptime = Duration.zero;
  final ValueNotifier<String> _uptimeText = ValueNotifier('00:00:00');

  DateTime? _uptimeStartTime;
  int? _uptimeStartTimestamp;

  String _firebaseUptime = '00:00:00';

  SensorData? _sensorData;

  bool _hasPh = false;

  double? _waterLevel;
  double? _flowRate;
  double? _totalGeneratedWater;
  bool _disconnectNotified = false;
  String _waterLevelLabel = 'UNKNOWN';

  List<double> _productionValues = List<double>.filled(7, 0.0);
  Map<String, double> _datedProduction = {};
  Map<String, double> _waterUsage = {};
  Map<String, DailyWeather> _weatherHistory = {};

  final SensorAlertEvaluator _alertEvaluator = SensorAlertEvaluator();
  double? _alertTemperature;
  double? _alertHumidity;
  double? _alertWaterLevel;
  double? _alertPh;
  bool _alertTankFull = false;

  Color get _dashboardBackground =>
      AppTheme.background(context, const Color(0xFFD4FFED));

  Color get _cardBackground =>
      AppTheme.surface(context, const Color(0x40BBBBBB));

  static const Color _primaryGreen = Color(0xFF1DE3AB);

  Color get _darkText => AppTheme.text(context, const Color(0xFF090909));

  static const Color _stopRed = Color(0xBFFF6262);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _firebaseConnectionSubscription = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen(
          (event) {
            if (!mounted) return;
            final connected = event.snapshot.value == true;
            if (connected == _databaseConnected) return;
            _databaseConnected = connected;
            _updateConnectionStatus();
            if (connected && !_refreshingReadings) {
              unawaited(_restoreDeviceConnection(forceRefresh: true));
            }
          },
          onError: (Object error) {
            if (!mounted) return;
            _databaseConnected = false;
            _updateConnectionStatus();
          },
        );
    AppSettings.instance.addListener(_checkAlerts);
    DevicePairingStore.instance.addListener(_restoreDeviceConnection);
    _restoreDeviceConnection();
    _startConnectionChecker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readingsGeneration++;
    AppSettings.instance.removeListener(_checkAlerts);
    DevicePairingStore.instance.removeListener(_restoreDeviceConnection);
    _uptimeTimer?.cancel();
    _connectionTimer?.cancel();
    _awgSubscription?.cancel();
    _firebaseConnectionSubscription?.cancel();
    _uptimeText.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _refreshOnResume = true;
    } else if (state == AppLifecycleState.resumed && _refreshOnResume) {
      _refreshOnResume = false;
      unawaited(_restoreDeviceConnection(forceRefresh: true));
    }
  }

  Future<void> _restoreDeviceConnection({bool forceRefresh = false}) async {
    final store = DevicePairingStore.instance;
    await store.initialize();
    if (!mounted) return;
    final deviceChanged = _listeningDeviceId != store.verifiedId;
    if (!forceRefresh &&
        !deviceChanged &&
        (_awgSubscription != null || _refreshingReadings)) {
      return;
    }
    _readingsGeneration++;
    _refreshingReadings = false;
    _listeningDeviceId = store.verifiedId;
    _disconnectNotified = false;
    _alertEvaluator.reset();
    _awgSubscription?.cancel();
    _awgSubscription = null;
    _uptimeTimer?.cancel();
    setState(() {
      _lastSeenTimestamp = null;
      _machineConnected = false;
      _hasReceivedFirebaseData = false;
      _lastReadingTimestamp = null;
      if (deviceChanged) {
        _sensorData = null;
        _datedProduction = {};
        _waterUsage = {};
        _weatherHistory = {};
        _productionValues = List<double>.filled(7, 0);
        _totalGeneratedWater = null;
      }
      _waterLevel = null;
      _waterLevelLabel = 'UNKNOWN';
      _flowRate = null;
      _machineRunning = false;
    });
    if (store.verifiedId != null) unawaited(_listenToAwgData());
  }

  Future<void> _listenToAwgData() async {
    final generation = _readingsGeneration;
    bool isActive() => mounted && generation == _readingsGeneration;
    _refreshingReadings = true;
    try {
      final snapshot = await _awgRef.get().timeout(const Duration(seconds: 10));
      if (!isActive()) return;
      _applyAwgData(snapshot.value);
    } catch (error) {
      if (!isActive()) return;
      _handleFirebaseError(error);
    }
    if (!isActive()) return;
    _refreshingReadings = false;
    _awgSubscription = _awgRef.onValue.listen(
      (event) {
        if (isActive()) _applyAwgData(event.snapshot.value);
      },
      onError: (Object error) {
        if (isActive()) _handleFirebaseError(error);
      },
    );
  }

  void _applyAwgData(Object? value) {
    if (!mounted || DevicePairingStore.instance.verifiedId == null) return;

    if (value is! Map) {
      _lastSeenTimestamp = null;
      setState(() {
        _hasReceivedFirebaseData = true;
        _machineConnected = false;
        _waterLevel = null;
        _flowRate = null;
        _waterLevelLabel = 'UNKNOWN';
      });

      _uptimeTimer?.cancel();
      return;
    }

    final awgData = _mapFrom(value);
    final deviceData = _mapFrom(awgData['device']);
    final reportedDeviceId = deviceData['deviceId']?.toString().trim();
    final verifiedDeviceId = DevicePairingStore.instance.verifiedId?.trim();
    if (reportedDeviceId == null ||
        verifiedDeviceId == null ||
        reportedDeviceId.toUpperCase() != verifiedDeviceId.toUpperCase()) {
      _lastSeenTimestamp = null;
      setState(() {
        _hasReceivedFirebaseData = true;
        _machineConnected = false;
        _waterLevel = null;
        _flowRate = null;
        _waterLevelLabel = 'UNKNOWN';
      });
      return;
    }
    final liveData = _mapFrom(awgData['live']);
    final newLastSeen = deviceLastSeenMilliseconds(liveData['lastSeen']);
    if (newLastSeen != null &&
        _lastSeenTimestamp != null &&
        newLastSeen < _lastSeenTimestamp!) {
      return;
    }

    final firstReading = !_hasReceivedFirebaseData;
    _hasReceivedFirebaseData = true;

    _lastSeenTimestamp = newLastSeen;
    _lastReadingTimestamp = newLastSeen;

    final connected = _calculateConnectionStatus();

    final currentSensors = _sensorData;
    final water = LiveWaterReadings.fromMap(
      liveData,
      serverConnected: _databaseConnected,
    );
    final waterLevel = water.tankPercent;
    final temperature = _boundedNumber(liveData['temperature'], -40, 80);
    final humidity = _boundedNumber(liveData['humidity'], 0, 100);
    final ph = _boundedNumber(liveData['ph'], 0, 14);
    final newHarvesting = _asBool(liveData['harvesting']) == true;
    final hasValidSensorSnapshot = temperature != null && humidity != null;
    final newWaterLevel = waterLevel;
    final newSensorData = hasValidSensorSnapshot
        ? SensorData(
            temperature: temperature,
            humidity: humidity,
            waterLevel: waterLevel ?? currentSensors?.waterLevel ?? 0,
            ph: ph ?? 0,
            system: newHarvesting,
          )
        : currentSensors;

    final newFlowRate = water.flowLitersPerDay;
    final newTotalGeneratedWater = _nonNegativeNumber(
      liveData['generatedWater'],
    );
    final newWaterLevelLabel = newWaterLevel != null
        ? _normalizeWaterLevelLabel(newWaterLevel)
        : 'UNKNOWN';

    final newHasPh = ph != null;

    final newTankFull = _asBool(liveData['tankFull']) == true;

    final newMachineRunning = _asBool(liveData['relay']) == true;

    final machineData = _mapFrom(liveData['machine']);

    final newUptimeStart = _asInt(machineData['uptimeStart']);

    final newFirebaseUptime =
        liveData['uptime']?.toString().trim() ?? '00:00:00';

    final newProductionValues = _readProductionHistory(awgData, liveData);
    final datedProduction = Map<String, double>.from(_datedProduction);
    final waterUsage = Map<String, double>.from(_waterUsage);
    _mapFrom(awgData['usageByDate']).forEach((key, value) {
      final liters = double.tryParse(value.toString());
      if (liters != null && liters.isFinite && liters >= 0) {
        waterUsage[key.toString()] = liters;
      }
    });
    final weatherHistory = <String, DailyWeather>{};
    _mapFrom(awgData['weatherByDate']).forEach((key, value) {
      if (value is Map) {
        weatherHistory[key.toString()] = DailyWeather.fromMap(value);
      }
    });
    _mapFrom(awgData['productionByDate']).forEach((key, value) {
      final liters = double.tryParse(value.toString());
      if (liters != null && liters.isFinite && liters >= 0) {
        datedProduction[key.toString()] = liters;
      }
    });

    _alertTemperature = temperature;
    _alertHumidity = humidity;
    _alertWaterLevel = waterLevel;
    _alertPh = ph;
    _alertTankFull = newTankFull;

    _firebaseUptime = newFirebaseUptime;
    final displayChanged =
        firstReading ||
        _sensorData != newSensorData ||
        _waterLevel != newWaterLevel ||
        _flowRate != newFlowRate ||
        _totalGeneratedWater != newTotalGeneratedWater ||
        !mapEquals(_datedProduction, datedProduction) ||
        !mapEquals(_waterUsage, waterUsage) ||
        !mapEquals(_weatherHistory, weatherHistory) ||
        _waterLevelLabel != newWaterLevelLabel ||
        _hasPh != newHasPh ||
        _machineRunning != newMachineRunning ||
        _machineConnected != connected ||
        !listEquals(_productionValues, newProductionValues);
    if (displayChanged) {
      setState(() {
        _sensorData = newSensorData;

        _waterLevel = newWaterLevel;
        _flowRate = newFlowRate;
        _totalGeneratedWater = newTotalGeneratedWater;
        _waterLevelLabel = newWaterLevelLabel;

        _hasPh = newHasPh;

        _machineRunning = newMachineRunning;
        _machineConnected = connected;

        _productionValues = newProductionValues;
        _datedProduction = datedProduction;
        _waterUsage = waterUsage;
        _weatherHistory = weatherHistory;
      });
    }
    _checkAlerts();

    if (newMachineRunning && newUptimeStart != null && newUptimeStart > 0) {
      _updateUptimeStart(newUptimeStart);
    } else if (!newMachineRunning) {
      _stopUptime();
    }

    if (!connected) {
      _uptimeTimer?.cancel();
    }
    _uptimeText.value = _displayUptime();
  }

  void _handleFirebaseError(Object error) {
    _lastSeenTimestamp = null;
    debugPrint('Firebase AWG listener error: $error');

    if (!mounted) return;

    setState(() {
      _hasReceivedFirebaseData = true;
      _machineConnected = false;
      _waterLevel = null;
      _flowRate = null;
      _waterLevelLabel = 'UNKNOWN';
    });

    _uptimeTimer?.cancel();
  }

  Map<dynamic, dynamic> _mapFrom(dynamic value) {
    if (value is Map) {
      return Map<dynamic, dynamic>.from(value);
    }

    return <dynamic, dynamic>{};
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
  }

  double? _boundedNumber(dynamic value, double minimum, double maximum) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim() ?? '');
    if (number == null ||
        !number.isFinite ||
        number < minimum ||
        number > maximum) {
      return null;
    }
    return number;
  }

  double? _nonNegativeNumber(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim() ?? '');
    if (number == null || !number.isFinite || number < 0) return null;
    return number;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) {
        return null;
      }

      return int.tryParse(text);
    }

    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'on':
          return true;

        case 'false':
        case '0':
        case 'off':
          return false;
      }
    }

    return null;
  }

  String _normalizeWaterLevelLabel(double percentage) {
    if (percentage >= 80) return 'FULL';
    if (percentage >= 20) return 'PARTLY FILLED';
    return 'EMPTY';
  }

  String _displayWaterLevelLabel() {
    switch (_waterLevelLabel) {
      case 'FULL':
        return 'Full';

      case 'PARTLY FILLED':
        return 'Partly filled';

      case 'EMPTY':
        return 'Empty';

      default:
        return 'No live data';
    }
  }

  void _startConnectionChecker() {
    _updateConnectionStatus();

    _connectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateConnectionStatus(),
    );
  }

  void _updateConnectionStatus() {
    if (!mounted) return;

    final online = _calculateConnectionStatus();
    if (online) {
      _disconnectNotified = false;
    } else if (_hasReceivedFirebaseData &&
        DevicePairingStore.instance.verifiedId != null &&
        !_disconnectNotified) {
      _disconnectNotified = true;
      unawaited(
        NotificationService().sendDisconnectNotification().catchError((
          Object error,
        ) {
          debugPrint('Could not save connection notification: $error');
        }),
      );
    }

    if (online == _machineConnected &&
        (online || (_waterLevel == null && _flowRate == null))) {
      return;
    }

    setState(() {
      _machineConnected = online;
      if (!online) {
        _waterLevel = null;
        _flowRate = null;
        _waterLevelLabel = 'UNKNOWN';
      }
    });

    if (online) _checkAlerts();
    if (!online) {
      _uptimeTimer?.cancel();
    }
  }

  bool _calculateConnectionStatus() {
    return _databaseConnected &&
        DevicePairingStore.instance.verifiedId != null &&
        _isLastSeenRecent(_lastSeenTimestamp);
  }

  bool _isLastSeenRecent(int? timestamp) {
    return isDeviceOnlineFromLastSeen(
      timestamp,
      timeout: const Duration(seconds: _offlineTimeoutSeconds),
    );
  }

  void _updateUptimeStart(int timestamp) {
    if (timestamp <= 0) {
      return;
    }

    if (_uptimeStartTimestamp == timestamp) {
      if (_machineConnected && !(_uptimeTimer?.isActive ?? false)) {
        _startUptimeTimer();
      }
      _updateMachineUptime();
      return;
    }

    _uptimeStartTimestamp = timestamp;

    _uptimeStartTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    _startUptimeTimer();
  }

  void _startUptimeTimer() {
    _uptimeTimer?.cancel();

    _updateMachineUptime();

    _uptimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateMachineUptime(),
    );
  }

  void _updateMachineUptime() {
    if (!mounted || !_machineRunning || _uptimeStartTime == null) {
      return;
    }

    final elapsed = DateTime.now().difference(_uptimeStartTime!);

    if (elapsed.isNegative) {
      return;
    }

    _machineUptime = elapsed;
    _uptimeText.value = _displayUptime();
  }

  void _stopUptime() {
    _uptimeTimer?.cancel();
    _uptimeTimer = null;

    _uptimeStartTime = null;
    _uptimeStartTimestamp = null;
    _machineUptime = Duration.zero;
    _uptimeText.value = '00:00:00';
  }

  String _displayUptime() {
    if (!_machineRunning) {
      return '00:00:00';
    }

    if (_uptimeStartTime != null) {
      return _formatUptime(_machineUptime);
    }

    return _firebaseUptime.isNotEmpty ? _firebaseUptime : '00:00:00';
  }

  String _formatUptime(Duration duration) {
    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  List<double> _readProductionHistory(
    Map<dynamic, dynamic> awgData,
    Map<dynamic, dynamic> liveData,
  ) {
    dynamic history = awgData['productionHistory'];

    history ??= awgData['production'];
    history ??= liveData['productionHistory'];

    if (history is! Map) {
      return List<double>.filled(7, 0.0);
    }

    final historyMap = Map<dynamic, dynamic>.from(history);

    final result = List<double>.filled(7, 0.0);

    const keys = ['M', 'T', 'W', 'TH', 'F', 'S', 'SUN'];

    // Support weekday names.
    for (int i = 0; i < keys.length; i++) {
      if (historyMap.containsKey(keys[i])) {
        result[i] = _asDouble(historyMap[keys[i]]);
      }
    }

    // Support numeric Firebase keys:
    // 0, 1, 2, 3, 4, 5, 6
    for (int i = 0; i < 7; i++) {
      final key = i.toString();

      if (historyMap.containsKey(key)) {
        result[i] = _asDouble(historyMap[key]);
      }
    }

    // Prevent negative production values.
    for (int i = 0; i < result.length; i++) {
      if (!result[i].isFinite || result[i] < 0) {
        result[i] = 0.0;
      }
    }

    return result;
  }

  void _checkAlerts() {
    final alerts = _alertEvaluator.evaluate(
      enabled: AppSettings.instance.sensorAlertsEnabled,
      online: _calculateConnectionStatus(),
      temperature: _alertTemperature,
      humidity: _alertHumidity,
      waterLevel: _alertWaterLevel,
      ph: _alertPh,
      tankFull: _alertTankFull,
    );
    for (final alert in alerts) {
      unawaited(
        _notificationService
            .addNotification(
              title: alert.title,
              message: alert.message,
              type: alert.type,
              systemAlert: true,
            )
            .catchError((Object error) {
              _alertEvaluator.retry(alert.key);
              debugPrint('Unable to deliver system alert: $error');
            }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _dashboardBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TabHeader(child: DashboardTopBar()),
            const SizedBox(height: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildDashboardContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastUpdateLabel() {
    final timestamp = _lastReadingTimestamp;
    if (timestamp == null || timestamp <= 0) {
      return 'Last update time unavailable';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final localizations = MaterialLocalizations.of(context);
    final day = localizations.formatMediumDate(date);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return 'Last update: $day, $time';
  }

  Widget _buildDashboardContent() {
    if (DevicePairingStore.instance.verifiedId == null) {
      return _buildDeviceNotFoundScreen();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasReceivedFirebaseData && !_machineConnected)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device disconnected',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _sensorData == null
                          ? 'No readings received yet. Connect the device to Wi-Fi for live updates.'
                          : 'Showing the last received readings. These values will update when the device reconnects.',
                    ),
                    if (_sensorData != null) Text(_lastUpdateLabel()),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WifiConnectionScreen(),
                        ),
                      ),
                      child: const Text('Set up device Wi-Fi'),
                    ),
                  ],
                ),
              ),
            ),
          _buildMachineCard(),
          const SizedBox(height: 8),
          if (_sensorData != null) _buildSensorCards(),
          const SizedBox(height: 8),
          if (_sensorData != null) _buildProductionHistoryCard(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildDeviceNotFoundScreen() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.fromLTRB(17, 24, 17, 24),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: double.infinity,
                  height: 183,
                  child: Image.asset(
                    'assets/images/device_notfound.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'ERROR: Device not found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _darkText,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 189,
                height: 40,
                child: ElevatedButton(
                  onPressed: widget.onProceedToDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: _darkText,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Proceed to Device',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineCard() {
    final percentage = _waterLevel?.round();

    return Container(
      height: 205,
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 9),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                'ESP 32:AWG DEVICE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 125, height: 125, child: _buildTankVisual()),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 2, 0, 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              percentage != null ? '$percentage%' : '--%',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: _darkText,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _waterLevel != null
                                    ? _displayWaterLevelLabel()
                                    : 'No live data',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildConnectionStatus(),
                        _buildUptimeText(),
                        _buildMachineButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final checking = !_hasReceivedFirebaseData;
    final connected = !checking && _machineConnected;
    return Row(
      children: [
        Icon(
          checking
              ? Icons.wifi_find
              : connected
              ? Icons.wifi
              : Icons.wifi_off,
          size: 20,
          color: checking
              ? Colors.black45
              : connected
              ? _primaryGreen
              : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(
          checking
              ? 'Connecting…'
              : connected
              ? 'Connected'
              : 'Disconnected',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: checking
                ? Colors.black45
                : connected
                ? _primaryGreen
                : Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        if (connected)
          Flexible(
            child: Text(
              _machineRunning ? '• Harvesting' : '• Stopped',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUptimeText() {
    return ValueListenableBuilder<String>(
      valueListenable: _uptimeText,
      builder: (context, uptime, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Device Uptime  :  ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                ),
              ),
              TextSpan(
                text: uptime,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineButton() {
    final disabled = !_machineConnected;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 100,
        height: 29,
        child: ElevatedButton(
          onPressed: disabled ? null : _toggleMachine,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: disabled
                ? Colors.grey.withValues(alpha: 0.55)
                : _machineRunning
                ? _stopRed
                : _primaryGreen,
            foregroundColor: const Color(0xFF090909),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            _machineRunning ? 'Stop' : 'Start',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _buildTankVisual() {
    return AnimatedWaterTank(percentage: _waterLevel, flowRate: _flowRate);
  }

  Widget _buildSensorCards() {
    final sensor = _sensorData!;

    return SizedBox(
      height: 73,
      child: Row(
        children: [
          Expanded(
            child: _compactSensorCard(
              title: 'Humidity',
              value: '${sensor.humidity.toStringAsFixed(0)}%',
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _compactSensorCard(
              title: 'pH Level',
              value: _hasPh ? _formatPh(sensor.ph) : '--',
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _compactSensorCard(
              title: 'Temperature',
              value: '${sensor.temperature.toStringAsFixed(0)}°',
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactSensorCard({required String title, required String value}) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 17,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _darkText,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionHistoryCard() {
    return ProductionHistorySection(
      records: _datedProduction,
      totalProduction: _totalGeneratedWater,
      usageRecords: _waterUsage,
      weather: _weatherHistory,
      background: _cardBackground,
      foreground: _darkText,
    );
  }

  String _formatPh(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Future<void> _toggleMachine() async {
    if (!_machineConnected) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ESP32 is offline.')));

      return;
    }

    final targetState = !_machineRunning;

    try {
      await _controlRef.update({
        'relay': targetState,
        'systemEnabled': targetState,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            targetState
                ? 'Start command sent to ESP32.'
                : 'Stop command sent to ESP32.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Machine control error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send machine command.')),
      );
    }
  }
}
