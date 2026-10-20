int? deviceLastSeenMilliseconds(Object? value) {
  final raw = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
  if (raw == null || raw <= 0) return null;

  // ESP32 firmware may store Unix seconds, milliseconds, or microseconds.
  if (raw < 100000000000) return raw * 1000;
  if (raw > 100000000000000) return raw ~/ 1000;
  return raw;
}

bool isDeviceOnlineFromLastSeen(
  Object? value, {
  DateTime? now,
  Duration timeout = const Duration(seconds: 30),
}) {
  final timestamp = deviceLastSeenMilliseconds(value);
  if (timestamp == null) return false;

  final difference = (now ?? DateTime.now()).millisecondsSinceEpoch - timestamp;
  return difference < 0 || difference <= timeout.inMilliseconds;
}

