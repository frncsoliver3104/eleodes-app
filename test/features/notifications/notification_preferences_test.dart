import 'package:ELEODES/features/notifications/services/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four preference combinations use distinct channels', () {
    final ids = <String>{};
    for (final sound in [false, true]) {
      for (final vibration in [false, true]) {
        final preference = NotificationPreferences(
          sound: sound,
          vibration: vibration,
        );
        final details = preference.androidDetails;
        ids.add(details.channelId);
        expect(details.playSound, sound);
        expect(details.enableVibration, vibration);
        expect(details.vibrationPattern, vibration ? [0, 500, 250, 500] : null);
        expect(details.channelId, isNot('awg_alerts'));
      }
    }
    expect(ids.length, 4);
  });

}
