import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:ELEODES/features/devices/widgets/device_disconnect_dialog.dart';
import 'package:ELEODES/shared/widgets/tab_header.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:ELEODES/features/devices/services/device_pairing_store.dart';
import 'package:ELEODES/features/devices/services/device_connection_status.dart';

import 'package:ELEODES/features/devices/screens/device_setup_screen.dart';

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({super.key});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final DatabaseReference _awgRef = FirebaseDatabase.instance.ref('AWG');

  bool loading = true;
  bool _disconnecting = false;
  Timer? _statusTimer;
  StreamSubscription<DatabaseEvent>? _statusSubscription;
  Object? _lastSeen;
  final ValueNotifier<bool> _online = ValueNotifier(false);

  String? pairedDeviceId;
  String? pairedDeviceName;

  // Device is considered online when lastSeen
  // was updated within the last 30 seconds.
  static const int _offlineTimeoutSeconds = 30;

  @override
  void initState() {
    super.initState();
    DevicePairingStore.instance.addListener(loadPairedDevice);
    loadPairedDevice();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _online.value = _isDeviceOnline(_lastSeen);
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _statusSubscription?.cancel();
    _online.dispose();
    DevicePairingStore.instance.removeListener(loadPairedDevice);
    super.dispose();
  }

  Future<void> loadPairedDevice() async {
    final store = DevicePairingStore.instance;
    await store.initialize();
    final deviceId = store.verifiedId;
    final deviceName = store.verifiedName;

    if (!mounted) return;

    if (deviceId != null) {
      _statusSubscription ??= _awgRef
          .child('live/lastSeen')
          .onValue
          .listen(
            (event) {
              _lastSeen = event.snapshot.value;
              _online.value = _isDeviceOnline(_lastSeen);
            },
            onError: (Object _) {
              _lastSeen = null;
              _online.value = false;
            },
          );
    } else {
      _statusSubscription?.cancel();
      _statusSubscription = null;
      _lastSeen = null;
      _online.value = false;
    }
    if (!loading &&
        pairedDeviceId == deviceId &&
        pairedDeviceName == deviceName) {
      return;
    }

    setState(() {
      pairedDeviceId = deviceId;
      pairedDeviceName = deviceName;
      loading = false;
    });
  }

  bool _isDeviceOnline(Object? value) {
    return isDeviceOnlineFromLastSeen(
      value,
      timeout: const Duration(seconds: _offlineTimeoutSeconds),
    );
  }

  Future<void> disconnectDevice() async {
    if (_disconnecting || pairedDeviceId == null) return;
    _disconnecting = true;
    try {
      await confirmDeviceDisconnect(context);
    } finally {
      _disconnecting = false;
    }
  }

  Future<void> openConfiguration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ESP32ConfigurationScreen()),
    );

    if (!mounted) return;

    await loadPairedDevice();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFD4FFED)),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TabTitle('Devices'),

              const SizedBox(height: 24),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DE3AB),
                          ),
                        )
                      : _buildSavedDevices(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedDevices() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),

      padding: const EdgeInsets.fromLTRB(9, 14, 9, 14),

      decoration: BoxDecoration(
        color: AppTheme.surface(context, const Color(0x40B8B8B8)),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.surface(
            context,
            Colors.white,
          ).withValues(alpha: 0.35),
          width: 1,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 11, bottom: 14),
            child: Text(
              'Saved Devices',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppTheme.text(context, Colors.black),
              ),
            ),
          ),

          if (pairedDeviceId == null)
            _buildEmptyDeviceRow()
          else
            _buildDeviceStream(),
        ],
      ),
    );
  }

  Widget _buildDeviceStream() {
    return ValueListenableBuilder<bool>(
      valueListenable: _online,
      builder: (context, isOnline, _) {
        return _buildDeviceRow(
          name: pairedDeviceName ?? 'AWG Device',
          deviceId: pairedDeviceId ?? '',
          isOnline: isOnline,
        );
      },
    );
  }

  Widget _buildDeviceRow({
    required String name,
    required String deviceId,
    required bool isOnline,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),

      onTap: openConfiguration,

      child: Container(
        width: double.infinity,
        height: 62,

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withValues(alpha: 0.7),
              width: 0.5,
            ),
          ),
        ),

        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                size: 30,
                color: isOnline
                    ? AppTheme.text(context, Colors.black)
                    : AppTheme.muted(context, Colors.black54),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isOnline
                          ? AppTheme.text(context, Colors.black)
                          : AppTheme.muted(context, Colors.black54),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    isOnline ? 'Connected' : 'Offline',

                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isOnline
                          ? AppTheme.text(context, Colors.black)
                          : AppTheme.muted(context, Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            _buildConnectionButton(isOnline: isOnline),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton({required bool isOnline}) {
    return GestureDetector(
      onTap: isOnline ? disconnectDevice : openConfiguration,

      child: Container(
        width: 100,
        height: 36,

        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: isOnline
              ? AppTheme.accentSurface(context, const Color(0xFF1DE3AB))
              : AppTheme.surface(context, Colors.white).withValues(alpha: 0.55),

          borderRadius: BorderRadius.circular(25),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],

          border: !isOnline
              ? Border.all(
                  color: AppTheme.surface(
                    context,
                    Colors.white,
                  ).withValues(alpha: 0.7),
                  width: 0.8,
                )
              : null,
        ),

        child: Text(
          isOnline ? 'Connected' : 'Connect',

          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isOnline
                ? AppTheme.text(context, Colors.black)
                : AppTheme.muted(context, Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDeviceRow() {
    return GestureDetector(
      onTap: openConfiguration,

      child: Container(
        width: double.infinity,
        height: 62,

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withValues(alpha: 0.7),
              width: 0.5,
            ),
          ),
        ),

        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Icon(
                Icons.wifi_off,
                size: 30,
                color: AppTheme.muted(context, Colors.black45),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Saved Device',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted(context, Colors.black54),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Add an AWG device',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.muted(context, Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            _buildConnectionButton(isOnline: false),
          ],
        ),
      ),
    );
  }
}
