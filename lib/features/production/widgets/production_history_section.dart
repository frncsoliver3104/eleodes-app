import 'dart:async';
import 'water_usage_card.dart';
import 'package:flutter/material.dart';
import 'package:ELEODES/features/production/widgets/production_comparison.dart';
import 'package:ELEODES/features/production/widgets/weather_production_history.dart';

/// Rolling seven calendar days in Philippine time (UTC+8).
class ProductionHistorySection extends StatefulWidget {
  const ProductionHistorySection({
    super.key,
    required this.records,
    required this.background,
    required this.foreground,
    this.weather = const {},
    this.usageRecords = const {},
    this.totalProduction,
  });
  final Map<String, double> records;
  final Map<String, double> usageRecords;
  final Color background;
  final Color foreground;
  final Map<String, DailyWeather> weather;
  final double? totalProduction;

  @override
  State<ProductionHistorySection> createState() =>
      _ProductionHistorySectionState();
}

class _ProductionHistorySectionState extends State<ProductionHistorySection> {
  Timer? _timer;
  DateTime _today = _philippineToday();

  static DateTime _philippineToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateTime.utc(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final today = _philippineToday();
      if (today != _today && mounted) setState(() => _today = today);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      WeatherProductionHistory(
        today: _today,
        records: widget.records,
        totalProduction: widget.totalProduction,
        weather: widget.weather,
        background: widget.background,
        foreground: widget.foreground,
      ),
      const SizedBox(height: 12),
      WaterUsageCard(
        today: _today,
        records: widget.usageRecords,
        background: widget.background,
        foreground: widget.foreground,
      ),
    ],
  );
}
