import 'package:ELEODES/features/devices/models/device_qr_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads device QR credentials and trims surrounding spaces', () {
    final result = DeviceQrCredentials.parse(
      '{"deviceId":" AWG-ESP32-0001 ","deviceSecret":" example-secret "}',
    );
    expect(result?.deviceId, 'AWG-ESP32-0001');
    expect(result?.deviceSecret, 'example-secret');
  });

  test(
    'rejects unrelated, malformed, incomplete and oversized QR payloads',
    () {
      for (final raw in [
        'https://example.com',
        '{}',
        '[]',
        'null',
        '{broken',
        '{"deviceId":"id"}',
        '{"deviceId":"id","deviceSecret":123}',
        '{"deviceId":" ","deviceSecret":"secret"}',
        '{"deviceId":"id","deviceSecret":" "}',
        'x' * 4097,
      ]) {
        expect(DeviceQrCredentials.parse(raw), isNull);
      }
    },
  );
}
