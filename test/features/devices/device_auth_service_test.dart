import 'package:ELEODES/features/devices/services/device_auth_service.dart';
import 'package:ELEODES/features/devices/services/device_pairing_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DevicePairingStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = DevicePairingStore();
    await store.initialize();
  });

  DeviceAuthService service({
    Future<Map<String, dynamic>?> Function()? readDevice,
  }) => DeviceAuthService(
    store: store,
    readDevice:
        readDevice ??
        () async => {
          'deviceId': 'Awg-1',
          'deviceName': 'Existing AWG',
          'deviceSecret': 'same-secret',
        },
  );

  test('correct ID and secret verify and save the device name', () async {
    await service().pair(' awg-1 ', 'same-secret');
    expect(store.verifiedId, 'Awg-1');
    expect(store.verifiedName, 'Existing AWG');

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getKeys().map(prefs.get).join();
    expect(saved, isNot(contains('same-secret')));
  });

  test('wrong ID or secret is rejected', () async {
    for (final credentials in [
      ('other-id', 'same-secret'),
      ('Awg-1', 'wrong-secret'),
    ]) {
      await expectLater(
        service().pair(credentials.$1, credentials.$2),
        throwsA(isA<DevicePairingException>()),
      );
      expect(store.verifiedId, isNull);
    }
  });

  test('missing plaintext secret explains which Firebase record is needed', () async {
    await expectLater(
      service(
        readDevice: () async => {'deviceId': 'Awg-1', 'deviceName': 'Existing AWG'},
      ).pair('Awg-1', 'same-secret'),
      throwsA(
        isA<DevicePairingException>().having(
          (error) => error.message,
          'message',
          contains('AWG/device/deviceSecret'),
        ),
      ),
    );
    expect(store.verifiedId, isNull);
  });

  test('database read errors are reported as Firebase connection failures', () async {
    await expectLater(
      service(readDevice: () async => throw StateError('database offline')).pair(
        'Awg-1',
        'same-secret',
      ),
      throwsA(
        isA<DevicePairingException>().having(
          (error) => error.message,
          'message',
          contains('Could not read the device record from Firebase'),
        ),
      ),
    );
    expect(store.verifiedId, isNull);
  });

  test('existing local verification is restored without a server session', () async {
    await store.verify('Awg-1', 'Existing AWG');
    await service().restoreSession();
    expect(store.verifiedId, 'Awg-1');
  });
}
