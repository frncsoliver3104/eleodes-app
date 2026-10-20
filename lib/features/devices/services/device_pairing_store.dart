import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps verification separate from a successfully provisioned device.
/// Secrets and Wi-Fi passwords are never stored on the phone.
class DevicePairingStore extends ChangeNotifier {
  DevicePairingStore();

  static final instance = DevicePairingStore();
  Future<void> Function()? beforeForget;
  SharedPreferences? _prefs;
  Future<void>? _initializing;
  Map<String, dynamic>? _saved;

  String? get deviceId => _saved?['id'] as String?;
  String? get deviceName => _saved?['name'] as String?;
  String? get wifiName => _saved?['ssid'] as String?;
  String? get verifiedId => _prefs?.getString('verifiedDeviceId') ?? deviceId;
  String? get verifiedName =>
      _prefs?.getString('verifiedDeviceName') ?? deviceName;
  bool get isConfigured => deviceId != null;

  Future<void> initialize() => _initializing ??= _load();

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString('configuredAwgDevice');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> &&
            decoded['id'] is String &&
            (decoded['id'] as String).isNotEmpty &&
            decoded['name'] is String &&
            decoded['ssid'] is String) {
          _saved = decoded;
        }
      } on FormatException {
        // A damaged record must not count as a configured device.
      }
    }
    // Older versions saved pairing before Wi-Fi succeeded. Restore it only
    // as verification, so setup can resume without claiming it is complete.
    final legacyId = _prefs!.getString('pairedDeviceId');
    if (verifiedId == null && legacyId != null && legacyId.isNotEmpty) {
      await verify(
        legacyId,
        _prefs!.getString('pairedDeviceName') ?? 'AWG Machine',
      );
    }
  }

  Future<void> verify(String id, String name) async {
    if (_prefs == null) await initialize();
    if (!await _prefs!.setString('verifiedDeviceName', name) ||
        !await _prefs!.setString('verifiedDeviceId', id)) {
      throw StateError('Unable to save device verification');
    }
    notifyListeners();
  }

  Future<void> complete({
    required String id,
    required String name,
    required String ssid,
  }) async {
    await initialize();
    if (id.isEmpty || verifiedId != id || ssid.isEmpty) {
      throw StateError('Verify this device before completing Wi-Fi setup');
    }
    final record = <String, dynamic>{'id': id, 'name': name, 'ssid': ssid};
    if (!await _prefs!.setString('configuredAwgDevice', jsonEncode(record))) {
      throw StateError('Unable to save the configured device');
    }
    _saved = record;
    notifyListeners();
  }

  Future<void> forget() async {
    await initialize();
    await beforeForget?.call();
    for (final key in [
      'configuredAwgDevice',
      'verifiedDeviceId',
      'verifiedDeviceName',
      'pairedDeviceId',
      'pairedDeviceName',
    ]) {
      if (!await _prefs!.remove(key)) {
        throw StateError('Unable to remove the saved device');
      }
    }
    _saved = null;
    notifyListeners();
  }
}
