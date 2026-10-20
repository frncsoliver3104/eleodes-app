import 'dart:async';

import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ELEODES/features/devices/models/device_qr_credentials.dart';
import 'package:ELEODES/features/devices/screens/device_qr_scanner_screen.dart';
import 'package:ELEODES/features/devices/widgets/device_disconnect_dialog.dart';
import 'package:ELEODES/features/devices/services/device_auth_service.dart';
import 'package:ELEODES/features/devices/services/device_connection_status.dart';
import 'package:ELEODES/features/devices/services/device_pairing_store.dart';

import 'package:ELEODES/features/devices/screens/wifi_connection_screen.dart';

class ESP32ConfigurationScreen extends StatefulWidget {
  const ESP32ConfigurationScreen({super.key});

  @override
  State<ESP32ConfigurationScreen> createState() =>
      _ESP32ConfigurationScreenState();
}

class _ESP32ConfigurationScreenState extends State<ESP32ConfigurationScreen> {
  final TextEditingController deviceIdController = TextEditingController();

  final TextEditingController deviceSecretController = TextEditingController();

  bool loading = false;
  bool _disconnecting = false;

  bool hideSecret = true;

  bool deviceConnected = false;

  bool wifiSetupOpened = false;
  bool _scanning = false;
  bool _deviceOnline = false;
  Object? _lastSeen;
  StreamSubscription<DatabaseEvent>? _lastSeenSubscription;
  Timer? _onlineTimer;

  static const int _offlineTimeoutSeconds = 30;

  Future<void> _scanDeviceQr() async {
    if (loading || deviceConnected || _scanning) return;
    _scanning = true;
    FocusScope.of(context).unfocus();
    try {
      final credentials = await Navigator.of(context).push<DeviceQrCredentials>(
        MaterialPageRoute(builder: (_) => const DeviceQrScannerScreen()),
      );
      if (!mounted || credentials == null || deviceConnected) return;
      setState(() {
        deviceIdController.text = credentials.deviceId;
        deviceSecretController.text = credentials.deviceSecret;
        hideSecret = true;
      });
      await pairDevice();
    } finally {
      _scanning = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _restoreVerification();
  }

  Future<void> _restoreVerification() async {
    final store = DevicePairingStore.instance;
    await store.initialize();
    if (!mounted || store.verifiedId == null) return;
    setState(() {
      deviceIdController.text = store.verifiedId!;
      deviceConnected = true;
    });
    _watchDeviceStatus();
  }

  void _watchDeviceStatus() {
    _lastSeenSubscription?.cancel();
    _lastSeenSubscription = FirebaseDatabase.instance
        .ref('AWG/live/lastSeen')
        .onValue
        .listen(
          (event) {
            _lastSeen = event.snapshot.value;
            _refreshDeviceOnline();
          },
          onError: (Object _) {
            _lastSeen = null;
            _refreshDeviceOnline();
          },
        );
    _onlineTimer?.cancel();
    _onlineTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshDeviceOnline(),
    );
  }

  void _refreshDeviceOnline() {
    final online = isDeviceOnlineFromLastSeen(
      _lastSeen,
      timeout: const Duration(seconds: _offlineTimeoutSeconds),
    );
    if (!mounted || online == _deviceOnline) return;
    setState(() => _deviceOnline = online);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pairDevice() async {
    if (loading) return;

    final String enteredDeviceId = deviceIdController.text.trim();

    final String enteredDeviceSecret = deviceSecretController.text.trim();

    if (enteredDeviceId.isEmpty || enteredDeviceSecret.isEmpty) {
      _showMessage('Please enter the AWG Device ID and Device Secret.');

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await DeviceAuthService.instance.pair(
        enteredDeviceId,
        enteredDeviceSecret,
      );
      if (!mounted) return;
      deviceSecretController.clear();

      setState(() {
        loading = false;
        deviceConnected = true;
      });
      _watchDeviceStatus();
      _showMessage('Device paired. Checking its internet connection...');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage('Unable to verify AWG device: $e');
    }
  }

  Future<void> disconnectDevice() async {
    if (loading || _disconnecting || !deviceConnected) return;
    _disconnecting = true;
    try {
      final disconnected = await confirmDeviceDisconnect(context);
      if (!mounted || !disconnected) return;
      setState(() {
        deviceConnected = false;
        _deviceOnline = false;
        wifiSetupOpened = false;
        hideSecret = true;
        deviceSecretController.clear();
      });
    } finally {
      _disconnecting = false;
    }
  }

  Future<void> openWifiSetup() async {
    if (!deviceConnected) {
      _showMessage('Connect your AWG device first.');

      return;
    }

    setState(() {
      wifiSetupOpened = true;
    });

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const WifiConnectionScreen()),
    );

    if (!mounted) return;

    setState(() {
      wifiSetupOpened = false;
    });
    if (completed == true) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _lastSeenSubscription?.cancel();
    _onlineTimer?.cancel();
    deviceIdController.dispose();
    deviceSecretController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFD4FFED)),

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.text(context, Colors.black),
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          'Connect',

          style: TextStyle(
            color: AppTheme.text(context, Colors.black),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        child: Column(
          children: [
            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),

              decoration: BoxDecoration(
                color: AppTheme.surface(context, const Color(0x40BBBBBB)),

                borderRadius: BorderRadius.circular(25),
              ),

              child: Column(
                children: [
                  Text(
                    'CONNECT DEVICE',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text(context, Colors.black),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Scan your device QR or enter its credentials '
                    'to connect to your machine',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                      color: AppTheme.text(context, Colors.black),
                    ),
                  ),

                  const SizedBox(height: 22),

                  OutlinedButton.icon(
                    onPressed: loading || deviceConnected
                        ? null
                        : _scanDeviceQr,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan device QR'),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: deviceIdController,

                    enabled: !deviceConnected && !loading,

                    autocorrect: false,

                    enableSuggestions: false,

                    textInputAction: TextInputAction.next,

                    decoration: InputDecoration(
                      hintText: 'Device ID',

                      filled: true,

                      fillColor: AppTheme.surface(context, Colors.white),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: deviceSecretController,

                    enabled: !deviceConnected && !loading,

                    obscureText: hideSecret,

                    autocorrect: false,

                    enableSuggestions: false,

                    textInputAction: TextInputAction.done,

                    onSubmitted: (_) {
                      if (!loading && !deviceConnected) {
                        pairDevice();
                      }
                    },

                    decoration: InputDecoration(
                      hintText: 'Device Passkey',

                      filled: true,

                      fillColor: AppTheme.surface(context, Colors.white),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),

                        borderSide: BorderSide.none,
                      ),

                      suffixIcon: IconButton(
                        onPressed: deviceConnected
                            ? null
                            : () {
                                setState(() {
                                  hideSecret = !hideSecret;
                                });
                              },

                        icon: Icon(
                          hideSecret ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: loading
                        ? null
                        : (deviceConnected ? disconnectDevice : pairDevice),

                    child: Container(
                      width: 120,
                      height: 48,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: deviceConnected
                            ? AppTheme.accentSurface(
                                context,
                                const Color(0xFF1DE3AB),
                              )
                            : AppTheme.surface(
                                context,
                                Colors.white,
                              ).withValues(alpha: 0.75),

                        borderRadius: BorderRadius.circular(25),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),

                            blurRadius: 4,

                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,

                                color: AppTheme.text(context, Colors.black),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                if (deviceConnected)
                                  const Icon(Icons.check, size: 18),

                                if (deviceConnected) const SizedBox(width: 5),

                                Text(
                                  deviceConnected ? 'Connected' : 'Connect',

                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.text(context, Colors.black),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            if (deviceConnected) ...[
              const SizedBox(height: 18),

              _deviceOnline ? _buildOnlineStatusCard() : _buildWifiSetupCard(),

              const SizedBox(height: 18),

              _buildInformationCard(),
            ] else ...[
              const SizedBox(height: 18),

              _buildInformationCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context, const Color(0x40BBBBBB)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi, color: AppTheme.text(context, Colors.black)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your AWG is online.',
                  style: TextStyle(color: AppTheme.text(context, Colors.black)),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: wifiSetupOpened ? null : openWifiSetup,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change network'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiSetupCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(15, 18, 15, 18),

      decoration: BoxDecoration(
        color: AppTheme.surface(context, const Color(0x40BBBBBB)),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons.wifi,
                size: 25,
                color: AppTheme.text(context, Colors.black),
              ),

              SizedBox(width: 10),

              Text(
                'WI-FI SETUP',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text(context, Colors.black),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Connect your AWG machine to your Wi-Fi '
            'network so it can communicate with ELEODES.',

            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              height: 1.4,
              color: AppTheme.text(context, Colors.black),
            ),
          ),

          const SizedBox(height: 15),

          GestureDetector(
            onTap: wifiSetupOpened ? null : openWifiSetup,

            child: Container(
              width: double.infinity,

              constraints: const BoxConstraints(minHeight: 72),

              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),

              decoration: BoxDecoration(
                color: AppTheme.surface(
                  context,
                  Colors.white,
                ).withValues(alpha: 0.45),

                borderRadius: BorderRadius.circular(18),

                border: Border.all(
                  color: AppTheme.surface(
                    context,
                    Colors.white,
                  ).withValues(alpha: 0.55),

                  width: 1,
                ),
              ),

              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: AppTheme.accentSurface(
                        context,
                        const Color(0xFF1DE3AB),
                      ),

                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Icon(
                      Icons.wifi,
                      size: 25,
                      color: AppTheme.text(context, Colors.black),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Configure Wi-Fi',

                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Set the Wi-Fi network for your AWG.',

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.muted(context, Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  wifiSetupOpened
                      ? SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.muted(context, Colors.black54),
                          ),
                        )
                      : Icon(
                          Icons.chevron_right,
                          size: 27,
                          color: AppTheme.muted(context, Colors.black54),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),

      decoration: BoxDecoration(
        color: AppTheme.surface(context, const Color(0x40BBBBBB)),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 30,
            height: 30,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: AppTheme.surface(
                context,
                Colors.white,
              ).withValues(alpha: 0.60),

              borderRadius: BorderRadius.circular(8),
            ),

            child: Icon(
              Icons.info_outline,
              size: 19,
              color: AppTheme.text(context, Colors.black),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Your Device ID and Device Passkey identify your machine. '
              'Wi-Fi setup is only needed when the AWG is offline.',

              style: TextStyle(
                fontSize: 10,
                height: 1.3,
                fontWeight: FontWeight.w300,
                color: AppTheme.text(context, Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
