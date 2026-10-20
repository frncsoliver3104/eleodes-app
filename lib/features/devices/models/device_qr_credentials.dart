import 'dart:convert';

class DeviceQrCredentials {
  const DeviceQrCredentials(this.deviceId, this.deviceSecret);

  final String deviceId;
  final String deviceSecret;

  static DeviceQrCredentials? parse(String raw) {
    if (raw.length > 4096) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      final id = data['deviceId'];
      final secret = data['deviceSecret'];
      if (id is! String || secret is! String) return null;
      if (id.trim().isEmpty || secret.trim().isEmpty) return null;
      return DeviceQrCredentials(id.trim(), secret.trim());
    } on FormatException {
      return null;
    }
  }
}
