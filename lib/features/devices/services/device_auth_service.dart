import 'package:firebase_database/firebase_database.dart';
import 'device_pairing_store.dart';

class DevicePairingException implements Exception {
  const DevicePairingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Checks the entered ID and secret against the public Firebase device record.
/// The secret is not saved on the phone.
class DeviceAuthService {
  DeviceAuthService({
    DevicePairingStore? store,
    Future<Map<String, dynamic>?> Function()? readDevice,
  }) : _store = store ?? DevicePairingStore.instance,
       _readDevice = readDevice ?? _readFirebaseDevice;

  static final instance = DeviceAuthService();
  final DevicePairingStore _store;
  final Future<Map<String, dynamic>?> Function() _readDevice;

  static Future<Map<String, dynamic>?> _readFirebaseDevice() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('AWG/device')
        .get()
        .timeout(const Duration(seconds: 20));
    final value = snapshot.value;
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> restoreSession() async {
    await _store.initialize();
  }

  Future<void> signOut() async {}

  Future<void> pair(String rawId, String rawSecret) async {
    final id = rawId.trim();
    final secret = rawSecret.trim();
    if (id.isEmpty || id.length > 128 || secret.isEmpty || secret.length > 512) {
      throw const DevicePairingException(
        'Enter a valid Device ID and Device Secret.',
      );
    }

    Map<String, dynamic>? device;
    try {
      device = await _readDevice();
    } catch (_) {
      throw const DevicePairingException(
        'Could not read the device record from Firebase. Check the database connection and rules.',
      );
    }

    if (device == null ||
        device['deviceId'] is! String ||
        device['deviceSecret'] is! String) {
      throw const DevicePairingException(
        'Firebase is missing AWG/device/deviceId or AWG/device/deviceSecret.',
      );
    }

    final registeredId = (device['deviceId'] as String).trim();
    final registeredSecret = (device['deviceSecret'] as String).trim();
    if (id.toUpperCase() != registeredId.toUpperCase() ||
        secret != registeredSecret) {
      throw const DevicePairingException('Invalid Device ID or Device Secret.');
    }

    final name = device['deviceName'] is String &&
            (device['deviceName'] as String).trim().isNotEmpty
        ? (device['deviceName'] as String).trim()
        : 'AWG Machine';
    await _store.verify(registeredId, name);
  }
}
