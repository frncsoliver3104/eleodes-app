import 'package:flutter/material.dart';
import '../services/notification_time.dart';

import 'package:ELEODES/core/theme/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String type;
  final bool read;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.read,
  });

  String _displayTime(BuildContext context) {
    final parsed = parseNotificationTime(time);
    if (parsed == null) return 'Time unavailable';
    final date = parsed.toUtc().add(const Duration(hours: 8));
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final clock = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(date),
        alwaysUse24HourFormat: false,
      );
    if (day == today) return 'Today, $clock (PHT)';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday, $clock (PHT)';
    }
    return '${MaterialLocalizations.of(context).formatMediumDate(date)}, $clock (PHT)';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.text(context, Colors.black);
    return Opacity(
      opacity: read ? 0.65 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.blend(
            context,
            const Color(0xFFD0D0D0),
            const Color(0xFF343434),
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, color: color)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: TextStyle(fontSize: 15, color: color)),
                  const SizedBox(height: 10),
                  Text(
                    _displayTime(context),
                    style: TextStyle(fontSize: 15, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
