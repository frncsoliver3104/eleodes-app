import 'package:ELEODES/features/devices/services/device_connection_status.dart';

class LiveWaterReadings {
  const LiveWaterReadings({this.tankPercent, this.flowLitersPerDay});

  final double? tankPercent;
  final double? flowLitersPerDay;

  factory LiveWaterReadings.fromMap(
    Map<dynamic, dynamic> live, {
    DateTime? now,
    bool serverConnected = true,
  }) {
    if (!serverConnected ||
        !isDeviceOnlineFromLastSeen(live['lastSeen'], now: now)) {
      return const LiveWaterReadings();
    }
    return LiveWaterReadings(
      tankPercent: _number(live['waterLevel'], maximum: 100),
      flowLitersPerDay: _number(live['flowRate']),
    );
  }

  static double? _number(Object? value, {double? maximum}) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().trim() ?? '');
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        (maximum != null && number > maximum)) {
      return null;
    }
    return number;
  }
}
