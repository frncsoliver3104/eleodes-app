import 'package:flutter/material.dart';
import 'production_comparison.dart';

class WaterUsageCard extends StatelessWidget {
  const WaterUsageCard({
    super.key,
    required this.today,
    required this.records,
    required this.background,
    required this.foreground,
  });

  final DateTime today;
  final Map<String, double> records;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    double? reading(DateTime day) {
      final value = records[productionDateKey(day)];
      return value != null && value.isFinite && value >= 0 ? value : null;
    }

    final todayValue = reading(today);
    // Calendar week: Monday through today in Philippine time.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final values = List.generate(
      today.weekday,
      (i) => reading(monday.add(Duration(days: i))),
    ).whereType<double>().toList();
    final weekValue = values.isEmpty
        ? null
        : values.fold<double>(0, (sum, value) => sum + value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: foreground, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Water Usage',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text('Track your daily and weekly water consumption'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _tile(
                    'Today',
                    Icons.calendar_today_outlined,
                    todayValue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tile(
                    'This week',
                    Icons.calendar_month_outlined,
                    weekValue,
                  ),
                ),
              ],
            ),
            if (values.isNotEmpty && values.length < today.weekday) ...[
              const SizedBox(height: 8),
              Text(
                'Partial week: ${values.length}/${today.weekday} days recorded',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, double? liters) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF1DE3AB),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 22),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: liters == null ? '--' : liters.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' L',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    ),
  );
}
