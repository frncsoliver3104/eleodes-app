import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ELEODES/features/devices/models/device_qr_credentials.dart';

class DeviceQrScannerScreen extends StatefulWidget {
  const DeviceQrScannerScreen({super.key});

  @override
  State<DeviceQrScannerScreen> createState() => _DeviceQrScannerScreenState();
}

class _DeviceQrScannerScreenState extends State<DeviceQrScannerScreen> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _completed = false;
  String? _message;

  void _onDetect(BarcodeCapture capture) {
    if (_completed || !mounted) return;
    for (final barcode in capture.barcodes) {
      final credentials = DeviceQrCredentials.parse(barcode.rawValue ?? '');
      if (credentials == null) continue;
      _completed = true;
      Navigator.of(context).pop(credentials);
      return;
    }
    if (_message != null) return;
    setState(() {
      _message =
          'This QR does not contain a Device ID and Device Secret. '
          'Scan the QR supplied with your AWG.';
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan device QR')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Point your camera at the QR code supplied with your AWG.',
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera unavailable. Allow camera access in your phone settings, '
                        'or return to enter the device credentials manually.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Enter manually'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_message != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_message!, textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }
}
