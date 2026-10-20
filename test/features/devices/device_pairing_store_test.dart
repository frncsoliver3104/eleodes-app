import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ELEODES/features/devices/services/device_pairing_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('verification alone does not save a configured device', () async {
    final store = DevicePairingStore();
    await store.initialize();
    await store.verify('AWG-1', 'My AWG');
    final reopened = DevicePairingStore();
    await reopened.initialize();
    expect(reopened.verifiedId, 'AWG-1');
    expect(reopened.isConfigured, isFalse);
  });

  test('successful setup survives reopening and forget removes it', () async {
    final store = DevicePairingStore();
    await store.initialize();
    await store.verify('AWG-1', 'My AWG');
    await store.complete(id: 'AWG-1', name: 'My AWG', ssid: 'Home');
    final reopened = DevicePairingStore();
    await reopened.initialize();
    expect(reopened.deviceId, 'AWG-1');
    expect(reopened.deviceName, 'My AWG');
    expect(reopened.wifiName, 'Home');
    await reopened.forget();
    final forgotten = DevicePairingStore();
    await forgotten.initialize();
    expect(forgotten.isConfigured, isFalse);
    expect(forgotten.verifiedId, isNull);
  });

  test(
    'legacy pairing resumes verification without assuming Wi-Fi success',
    () async {
      SharedPreferences.setMockInitialValues({
        'pairedDeviceId': 'AWG-1',
        'pairedDeviceName': 'Old AWG',
      });
      final store = DevicePairingStore();
      await store.initialize();
      expect(store.verifiedId, 'AWG-1');
      expect(store.isConfigured, isFalse);
      await store.forget();
      final reopened = DevicePairingStore();
      await reopened.initialize();
      expect(reopened.verifiedId, isNull);
    },
  );

  test('cannot complete setup for a different device', () async {
    final store = DevicePairingStore();
    await store.initialize();
    await store.verify('AWG-1', 'My AWG');
    await expectLater(
      store.complete(id: 'AWG-2', name: 'Other', ssid: 'Home'),
      throwsStateError,
    );
    expect(store.isConfigured, isFalse);
  });
}
