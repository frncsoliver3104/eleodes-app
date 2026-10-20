import 'package:flutter/material.dart';

import 'package:ELEODES/features/devices/services/device_pairing_store.dart';

/// Disconnects the saved device from this app after confirmation.
Future<bool> confirmDeviceDisconnect(BuildContext context) async {
  final store = DevicePairingStore.instance;
  final id = store.verifiedId;
  if (id == null) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Disconnect device?'),
      content: Text(
        'Do you want to disconnect ${store.verifiedName ?? id} from this app?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Disconnect'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted || store.verifiedId != id) {
    return false;
  }
  try {
    await store.forget();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AWG device disconnected.')));
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not disconnect the device. Please retry.'),
        ),
      );
    }
    return false;
  }
}
