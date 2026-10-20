import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleWifiProvisioningService {
  bool _disposed = false;

  void _emit(String message) {
    if (!_disposed && !_statusController.isClosed) {
      _statusController.add(message);
    }
  }

  static const String deviceName = "AWG-ESP32-0001";


  // ESP32 BLE Service
  static final Guid serviceUuid = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");

  // Flutter -> ESP32
  static final Guid rxUuid = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  // ESP32 -> Flutter
  static final Guid txUuid = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");


  BluetoothDevice? _device;

  BluetoothCharacteristic? _rxCharacteristic;


  StreamSubscription<List<ScanResult>>? _scanSubscription;

  StreamSubscription<List<int>>? _notificationSubscription;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;


  bool get isConnected {
    return _device?.isConnected ?? false;
  }


  Future<bool> requestPermissions() async {
    try {
      _emit("Checking Bluetooth permissions...");

      final scanStatus = await Permission.bluetoothScan.request();

      final connectStatus = await Permission.bluetoothConnect.request();

      if (!scanStatus.isGranted) {
        _emit("Bluetooth scan permission denied");

        return false;
      }

      if (!connectStatus.isGranted) {
        _emit("Bluetooth connect permission denied");

        return false;
      }

      return true;
    } catch (e) {
      _emit("Permission error: $e");

      return false;
    }
  }


  Future<bool> checkBluetooth() async {
    try {
      final supported = await FlutterBluePlus.isSupported;

      if (!supported) {
        _emit("Bluetooth LE is not supported on this phone");

        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState
          .where((state) => state != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 5));

      if (adapterState != BluetoothAdapterState.on) {
        _emit("Bluetooth is turned off");

        return false;
      }

      return true;
    } catch (e) {
      _emit("Bluetooth error: $e");

      return false;
    }
  }


  Future<bool> scanAndConnect() async {
    if (_disposed) return false;
    try {

      _emit("Checking Bluetooth...");

      final permissions = await requestPermissions();

      if (!permissions) {
        return false;
      }


      final bluetoothReady = await checkBluetooth();

      if (!bluetoothReady) {
        return false;
      }
      if (_disposed) return false;


      try {
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }
      } catch (_) {}

      await _scanSubscription?.cancel();

      _scanSubscription = null;


      if (_device != null && _device!.isConnected) {
        try {
          await _device!.disconnect();
        } catch (_) {}
      }

      _device = null;
      _rxCharacteristic = null;


      _emit("Searching for $deviceName...");

      BluetoothDevice? foundDevice;

      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          if (foundDevice != null) {
            return;
          }

          for (final result in results) {

            final advertisedName = result.advertisementData.advName.trim();


            final platformName = result.device.platformName.trim();


            final detectedName = advertisedName.isNotEmpty
                ? advertisedName
                : platformName;


            final nameMatches = detectedName == deviceName;


            bool serviceMatches = false;

            for (final uuid in result.advertisementData.serviceUuids) {
              if (uuid == serviceUuid) {
                serviceMatches = true;
                break;
              }
            }


            if (detectedName.isNotEmpty) {
              _emit("BLE device found: $detectedName");
            }


            if (nameMatches || serviceMatches) {
              foundDevice = result.device;

              _emit("Found $deviceName");

              try {
                FlutterBluePlus.stopScan();
              } catch (_) {}

              break;
            }
          }
        },
        onError: (error) {
          _emit("BLE scan error: $error");
        },
      );


      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: false,
        androidCheckLocationServices: false,
      );


      try {
        await FlutterBluePlus.isScanning
            .where((scanning) => scanning == false)
            .first;
      } catch (_) {}

      // Give listener time to process final result.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await _scanSubscription?.cancel();

      _scanSubscription = null;


      if (_disposed) return false;
      if (foundDevice == null) {
        _emit("ESP32 not found");

        _emit("Make sure AWG-ESP32-0001 is powered on and advertising");

        return false;
      }


      _device = foundDevice;

      _emit("Connecting to ESP32...");

      await _connectToDevice(_device!);

      return true;
    } catch (e) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      await _scanSubscription?.cancel();

      _scanSubscription = null;

      _emit("BLE error: $e");

      return false;
    }
  }


  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _connectionSubscription?.cancel();

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _emit("ESP32 connected");
        }

        if (state == BluetoothConnectionState.disconnected) {
          _emit("ESP32 disconnected");
        }
      });


      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );
      if (_disposed) {
        await device.disconnect();
        throw StateError('Wi-Fi setup was closed');
      }

      _emit("ESP32 connected");


      _emit("Discovering ESP32 BLE services...");

      final services = await device.discoverServices();
      if (_disposed) throw StateError('Wi-Fi setup was closed');

      BluetoothCharacteristic? rx;
      BluetoothCharacteristic? tx;


      for (final service in services) {
        if (service.uuid != serviceUuid) {
          continue;
        }

        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == rxUuid) {
            rx = characteristic;
          }

          if (characteristic.uuid == txUuid) {
            tx = characteristic;
          }
        }
      }


      if (rx == null) {
        throw Exception("Nordic UART RX characteristic not found");
      }


      if (tx == null) {
        throw Exception("Nordic UART TX characteristic not found");
      }

      _rxCharacteristic = rx;


      _emit("Enabling ESP32 notifications...");

      await tx.setNotifyValue(true);

      await _notificationSubscription?.cancel();

      _notificationSubscription = tx.lastValueStream.listen((value) {
        if (value.isEmpty) {
          return;
        }

        String message;

        try {
          message = utf8.decode(value).trim();
        } catch (_) {
          message = String.fromCharCodes(value).trim();
        }

        if (message.isEmpty) {
          return;
        }

        _emit(message);
      });

      // --------------------------------------------------------
      // BLE READY
      //
      // WifiConnectionScreen listens for this message.
      // Once received, it should reveal the Wi-Fi setup card.
      // --------------------------------------------------------

      _emit("BLE communication ready");

      // Explicit event for the UI.
      _emit("WIFI_SETUP_READY");
    } catch (e) {
      _emit("ESP32 connection failed: $e");

      try {
        await device.disconnect();
      } catch (_) {}

      rethrow;
    }
  }


  Future<void> sendWifiCredentials({
    required String ssid,
    required String password,
  }) async {

    if (_device == null || !_device!.isConnected) {
      throw Exception("ESP32 is not connected");
    }


    if (_rxCharacteristic == null) {
      throw Exception("ESP32 Wi-Fi configuration channel is not ready");
    }


    final cleanSSID = ssid.trim();

    if (cleanSSID.isEmpty) {
      throw Exception("Wi-Fi name cannot be empty");
    }


    if (password.isEmpty) {
      throw Exception("Wi-Fi password cannot be empty");
    }


    final data = jsonEncode({"ssid": cleanSSID, "password": password});

    _emit("Sending Wi-Fi credentials...");


    final bytes = utf8.encode(data);


    await _rxCharacteristic!.write(bytes, withoutResponse: false);

    _emit("Credentials sent");
  }


  Future<void> disconnect() async {
    try {
      await _notificationSubscription?.cancel();

      _notificationSubscription = null;

      await _connectionSubscription?.cancel();

      _connectionSubscription = null;

      await _scanSubscription?.cancel();

      _scanSubscription = null;

      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}

      if (_device != null) {
        await _device!.disconnect();
      }
    } catch (_) {}

    _rxCharacteristic = null;

    _device = null;

    _emit("ESP32 disconnected");
  }

  void dispose() {
    _disposed = true;
    _scanSubscription?.cancel();

    _notificationSubscription?.cancel();

    _connectionSubscription?.cancel();

    try {
      _device?.disconnect();
    } catch (_) {}

    _statusController.close();
  }
}
