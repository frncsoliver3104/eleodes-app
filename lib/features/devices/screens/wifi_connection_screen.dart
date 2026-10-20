import 'package:ELEODES/core/theme/app_theme.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ELEODES/features/devices/services/ble_wifi_provisioning_service.dart';
import 'package:ELEODES/features/devices/services/device_pairing_store.dart';

class WifiConnectionScreen extends StatefulWidget {
  const WifiConnectionScreen({super.key});

  @override
  State<WifiConnectionScreen> createState() => _WifiConnectionScreenState();
}

class _WifiConnectionScreenState extends State<WifiConnectionScreen> {

  final BleWifiProvisioningService _bleService = BleWifiProvisioningService();


  final TextEditingController ssidController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();


  StreamSubscription<String>? _statusSubscription;


  bool isScanning = false;
  bool isConnectingWifi = false;

  bool bleConnected = false;
  bool wifiConnected = false;

  bool showPassword = false;
  Timer? _wifiTimeout;
  bool _saving = false;
  String? _provisioningId;
  String? _provisioningName;
  String? _submittedSsid;

  String esp32Status = 'ESP32 not connected';

  String connectedWifi = 'Not Connected';


  @override
  void initState() {
    super.initState();

    _statusSubscription = _bleService.statusStream.listen(_handleBleStatus);
    _restoreSetup();
  }

  Future<void> _restoreSetup() async {
    final store = DevicePairingStore.instance;
    await store.initialize();
    if (!mounted) return;
    _provisioningId = store.verifiedId;
    _provisioningName = store.verifiedName;
    ssidController.text = store.wifiName ?? '';
    if (_provisioningId != null) await findESP32();
  }

  Future<void> _saveConfiguredDevice() async {
    if (_saving || _submittedSsid == null || _provisioningId == null) return;
    _saving = true;
    _wifiTimeout?.cancel();
    try {
      await DevicePairingStore.instance.complete(
        id: _provisioningId!,
        name: _provisioningName ?? 'AWG Machine',
        ssid: _submittedSsid!,
      );
      if (!mounted) return;
      passwordController.clear();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showMessage('Wi-Fi connected, but saving failed: $e');
    } finally {
      _saving = false;
    }
  }


  void _handleBleStatus(String status) {
    if (!mounted) {
      return;
    }

    final message = status.trim();

    if (message == 'WIFI_CONNECTED') {
      if (_submittedSsid == null || !isConnectingWifi) return;
      unawaited(_saveConfiguredDevice());
    }
    if (message == 'WIFI_FAILED' ||
        message == 'WIFI_INVALID' ||
        message == 'ESP32 disconnected') {
      _wifiTimeout?.cancel();
      _submittedSsid = null;
    }

    setState(() {

      if (message == 'ESP32 connected' || message == 'BLE_CONNECTED') {
        bleConnected = true;

        esp32Status = 'ESP32 connected';
      }


      if (message == 'BLE communication ready') {
        bleConnected = true;

        esp32Status = 'ESP32 ready for Wi-Fi setup';
      }


      if (message == 'ESP32 disconnected') {
        bleConnected = false;

        wifiConnected = false;

        isConnectingWifi = false;

        esp32Status = 'ESP32 disconnected';

        connectedWifi = 'Not Connected';
      }


      if (message == 'Bluetooth is turned off') {
        bleConnected = false;

        esp32Status = 'Bluetooth is turned off';
      }


      if (message == 'Bluetooth LE is not supported on this phone') {
        bleConnected = false;

        esp32Status = 'Bluetooth LE is not supported';
      }


      if (message.startsWith('Searching for')) {
        esp32Status = 'Searching for ELEODES ESP32...';
      }


      if (message.startsWith('Found ')) {
        esp32Status = 'ELEODES ESP32 found';
      }


      if (message == 'ESP32 not found') {
        bleConnected = false;

        esp32Status = 'ELEODES ESP32 not found';
      }


      if (message.startsWith('BLE scan error:')) {
        bleConnected = false;

        esp32Status = 'BLE scan error';
      }


      if (message == 'Connecting to ESP32...') {
        esp32Status = 'Connecting to ESP32...';
      }


      if (message.startsWith('ESP32 connection failed:')) {
        bleConnected = false;

        esp32Status = 'ESP32 connection failed';
      }


      if (message == 'WIFI_NOT_CONFIGURED') {
        isConnectingWifi = false;

        wifiConnected = false;

        connectedWifi = 'Not Connected';

        esp32Status = 'Wi-Fi not configured';
      }


      if (message == 'WIFI_CONNECTING') {
        isConnectingWifi = true;

        wifiConnected = false;

        esp32Status = 'Connecting ESP32 to Wi-Fi...';
      }


      if (message == 'WIFI_CONNECTED') {
        isConnectingWifi = false;

        wifiConnected = true;

        esp32Status = 'ESP32 connected to Wi-Fi';

        connectedWifi = ssidController.text.trim();
      }


      if (message == 'WIFI_FAILED') {
        isConnectingWifi = false;

        wifiConnected = false;

        esp32Status = 'Wi-Fi connection failed';
      }


      if (message == 'WIFI_INVALID') {
        isConnectingWifi = false;

        wifiConnected = false;

        esp32Status = 'Invalid Wi-Fi information';
      }


      if (message == 'Credentials sent' && isConnectingWifi) {
        esp32Status = 'ESP32 is connecting to Wi-Fi...';
      }
    });
  }


  Future<void> findESP32() async {
    if (isScanning || isConnectingWifi || _saving) {
      return;
    }

    setState(() {
      isScanning = true;

      bleConnected = false;

      wifiConnected = false;

      isConnectingWifi = false;

      esp32Status = 'Searching for ELEODES ESP32...';
    });

    try {
      final bool found = await _bleService.scanAndConnect();

      if (!mounted) {
        return;
      }

      setState(() {
        isScanning = false;

        if (found) {
          bleConnected = true;

          esp32Status = 'ESP32 ready for Wi-Fi setup';
        } else {
          bleConnected = false;

          esp32Status = 'ESP32 not found';
        }
      });

      if (!found) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ELEODES ESP32 was not found. '
              'Make sure the ESP32 is powered on '
              'and Bluetooth is enabled.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isScanning = false;

        bleConnected = false;

        esp32Status = 'Connection failed';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ESP32 connection error: $e')));
    }
  }


  Future<void> sendWifiCredentials() async {
    if (isConnectingWifi || _saving) {
      return;
    }
    if (_provisioningId == null) {
      _showMessage('Verify your Device ID and Device Secret first.');
      return;
    }

    final String ssid = ssidController.text.trim();

    final String password = passwordController.text;


    if (!bleConnected || !_bleService.isConnected) {
      _showMessage('Find and connect to the ESP32 first.');

      return;
    }


    if (ssid.isEmpty) {
      _showMessage('Please enter the Wi-Fi name.');

      return;
    }


    if (password.isEmpty) {
      _showMessage('Please enter the Wi-Fi password.');

      return;
    }

    setState(() {
      isConnectingWifi = true;

      wifiConnected = false;

      esp32Status = 'Sending Wi-Fi credentials...';
    });

    _submittedSsid = ssid;
    _wifiTimeout?.cancel();
    _wifiTimeout = Timer(const Duration(seconds: 45), () {
      if (!mounted || !isConnectingWifi) return;
      _submittedSsid = null;
      setState(() {
        isConnectingWifi = false;
        esp32Status = 'No Wi-Fi confirmation received. Please retry.';
      });
    });
    try {
      await _bleService.sendWifiCredentials(ssid: ssid, password: password);

      if (!mounted || !isConnectingWifi) {
        return;
      }

      setState(() {
        esp32Status = 'ESP32 is connecting to Wi-Fi...';
      });

      _showMessage('Wi-Fi credentials sent to ESP32.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isConnectingWifi = false;

        wifiConnected = false;

        esp32Status = 'Failed to send Wi-Fi credentials';
      });

      _showMessage('Failed to send Wi-Fi credentials: $e');
      _wifiTimeout?.cancel();
      _submittedSsid = null;
    }
  }


  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  void dispose() {
    _wifiTimeout?.cancel();
    _statusSubscription?.cancel();

    ssidController.dispose();

    passwordController.dispose();

    _bleService.dispose();

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFC8F7E6)),

      appBar: AppBar(
        elevation: 0,

        backgroundColor: Colors.transparent,

        centerTitle: false,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.text(context, Colors.black),
            size: 28,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          'AWG',

          style: TextStyle(
            color: AppTheme.text(context, Colors.black),
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SafeArea(
        top: false,

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

          child: Column(
            children: [
              Container(
                width: double.infinity,

                padding: const EdgeInsets.fromLTRB(20, 35, 20, 25),

                decoration: BoxDecoration(
                  color: AppTheme.surface(
                    context,
                    const Color(0xFFBFE9DB),
                  ).withValues(alpha: 0.65),

                  borderRadius: BorderRadius.circular(25),
                ),

                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,

                      decoration: BoxDecoration(
                        color: AppTheme.surface(
                          context,
                          const Color(0xFFD9D9D9),
                        ),

                        borderRadius: BorderRadius.circular(2),
                      ),

                      child: Icon(
                        Icons.memory,
                        size: 42,
                        color: AppTheme.muted(context, Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      'ELEODES ESP32',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text(context, Colors.black),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      esp32Status,

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.text(context, Colors.black),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,

                      height: 62,

                      child: ElevatedButton(
                        onPressed: isScanning ? null : findESP32,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surface(
                            context,
                            const Color(0xFFF5FFFC),
                          ),

                          disabledBackgroundColor: AppTheme.surface(
                            context,
                            const Color(0xFFE0EAE7),
                          ),

                          foregroundColor: AppTheme.text(context, Colors.black),

                          elevation: 2,

                          shadowColor: Colors.black.withValues(alpha: 0.25),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),

                        child: isScanning
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,

                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.text(
                                        context,
                                        Colors.black,
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  Text(
                                    'Finding ESP32...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Icon(
                                    bleConnected
                                        ? Icons.bluetooth_connected
                                        : Icons.bluetooth_searching,
                                    size: 25,
                                    color: AppTheme.muted(
                                      context,
                                      Colors.black54,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Text(
                                    bleConnected
                                        ? 'ESP32 Connected'
                                        : 'Find Esp 32',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // WIFI SETUP
              //
              // THIS ONLY APPEARS AFTER BLE CONNECTION
              // ==================================================
              AnimatedSize(
                duration: const Duration(milliseconds: 350),

                curve: Curves.easeInOut,

                child: bleConnected
                    ? Column(
                        children: [
                          const SizedBox(height: 18),

                          _buildWifiCard(),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: AppTheme.surface(
                    context,
                    const Color(0xFFBFE9DB),
                  ).withValues(alpha: 0.65),

                  borderRadius: BorderRadius.circular(25),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Container(
                      width: 30,
                      height: 30,

                      decoration: BoxDecoration(
                        color: AppTheme.surface(
                          context,
                          const Color(0xFFD9D9D9),
                        ),

                        borderRadius: BorderRadius.circular(2),
                      ),

                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.muted(context, Colors.black54),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Find your ELEODES ESP32 first. '
                        'Once connected through Bluetooth, '
                        'the Wi-Fi setup will appear below. '
                        'Enter your Wi-Fi credentials to '
                        'connect the machine to your network.',

                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppTheme.text(context, Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildWifiCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),

      decoration: BoxDecoration(
        color: const Color(0xFFBFBFBF).withValues(alpha: 0.75),

        borderRadius: BorderRadius.circular(25),
      ),

      child: Column(
        children: [
          TextFormField(
            initialValue: BleWifiProvisioningService.deviceName,

            readOnly: true,

            decoration: InputDecoration(
              hintText: 'Device ID',

              filled: true,

              fillColor: AppTheme.surface(context, Colors.white),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),

                borderSide: BorderSide.none,
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),

            style: TextStyle(
              fontSize: 14,
              color: AppTheme.text(context, Colors.black87),
            ),
          ),

          const SizedBox(height: 18),

          Align(
            alignment: Alignment.centerLeft,

            child: Text(
              'Wi-Fi',

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.text(context, Colors.black),
              ),
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: ssidController,

            autocorrect: false,

            enableSuggestions: false,

            textInputAction: TextInputAction.next,

            decoration: InputDecoration(
              hintText: 'Wi-Fi Name (SSID)',

              filled: true,

              fillColor: AppTheme.surface(context, Colors.white),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),

                borderSide: BorderSide.none,
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),

            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: passwordController,

            obscureText: !showPassword,

            autocorrect: false,

            enableSuggestions: false,

            textInputAction: TextInputAction.done,

            onSubmitted: (_) {
              if (!isConnectingWifi) {
                sendWifiCredentials();
              }
            },

            decoration: InputDecoration(
              hintText: 'Wi-Fi Password',

              filled: true,

              fillColor: AppTheme.surface(context, Colors.white),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),

                borderSide: BorderSide.none,
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),

              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },

                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),

            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 45,

            child: ElevatedButton(
              onPressed: isConnectingWifi ? null : sendWifiCredentials,

              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surface(
                  context,
                  const Color(0xFFF5FFFC),
                ),

                foregroundColor: AppTheme.text(context, Colors.black),

                disabledBackgroundColor: AppTheme.muted(
                  context,
                  Colors.grey.shade300,
                ),

                elevation: 2,

                minimumSize: const Size(110, 45),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),

              child: isConnectingWifi
                  ? SizedBox(
                      width: 20,
                      height: 20,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.text(context, Colors.black),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Icon(
                          wifiConnected ? Icons.wifi : Icons.wifi_outlined,
                          size: 19,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          wifiConnected ? 'Connected' : 'Connect',

                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (wifiConnected) ...[
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const Icon(Icons.check_circle, size: 17, color: Colors.green),

                const SizedBox(width: 6),

                Flexible(
                  child: Text(
                    connectedWifi.isEmpty
                        ? 'Wi-Fi connected'
                        : 'Connected to $connectedWifi',

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
