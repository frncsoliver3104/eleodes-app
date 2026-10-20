class SensorData {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorData &&
          temperature == other.temperature &&
          humidity == other.humidity &&
          waterLevel == other.waterLevel &&
          ph == other.ph &&
          system == other.system;

  @override
  int get hashCode =>
      Object.hash(temperature, humidity, waterLevel, ph, system);

  final double humidity;

  final double temperature;

  final double waterLevel;

  final double ph; // Added pH level

  final bool system;

  const SensorData({
    required this.humidity,

    required this.temperature,

    required this.waterLevel,

    required this.ph,

    required this.system,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> sensors, bool system) {
    return SensorData(
      humidity: (sensors["humidity"] ?? 0).toDouble(),

      temperature: (sensors["temperature"] ?? 0).toDouble(),

      waterLevel: (sensors["waterLevel"] ?? 0).toDouble(),

      ph: (sensors["ph"] ?? 0).toDouble(), // Read pH from Firebase

      system: system,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "humidity": humidity,

      "temperature": temperature,

      "waterLevel": waterLevel,

      "ph": ph,

      "system": system,
    };
  }
}
