import 'package:ELEODES/features/devices/services/device_pairing_store.dart';
import 'package:ELEODES/features/devices/widgets/device_disconnect_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('disconnect requires confirmation and clears saved pairing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = DevicePairingStore.instance;
    await store.initialize();
    await store.verify('test-device', 'Test AWG');
    await store.complete(
      id: 'test-device',
      name: 'Test AWG',
      ssid: 'Test Wi-Fi',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmDeviceDisconnect(context),
              child: const Text('Connected'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Connected'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect device?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.verifiedId, 'test-device');
    expect(store.isConfigured, isTrue);

    await tester.tap(find.text('Connected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(store.verifiedId, isNull);
    expect(store.isConfigured, isFalse);
    expect(find.text('AWG device disconnected.'), findsOneWidget);
  });
}
