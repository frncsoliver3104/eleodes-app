import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android channels retain their sound/vibration behavior after creation.
/// Use a separate channel for each preference combination.
class NotificationPreferences {
  const NotificationPreferences({required this.sound, required this.vibration});

  final bool sound;
  final bool vibration;

  String get channelId =>
      'awg_alerts_v2_s${sound ? 1 : 0}_v${vibration ? 1 : 0}';

  String get channelName => switch ((sound, vibration)) {
    (true, true) => 'AWG Alerts: sound and vibration',
    (true, false) => 'AWG Alerts: sound',
    (false, true) => 'AWG Alerts: vibration',
    (false, false) => 'AWG Alerts: silent',
  };

  AndroidNotificationDetails get androidDetails => AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: 'Alerts from the AWG system.',
    importance: Importance.high,
    priority: Priority.high,
    playSound: sound,
    enableVibration: vibration,
    vibrationPattern: vibration ? Int64List.fromList([0, 500, 250, 500]) : null,
  );
}
