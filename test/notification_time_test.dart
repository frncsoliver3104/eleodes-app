import 'package:flutter_test/flutter_test.dart';
import 'package:ELEODES/features/notifications/services/notification_time.dart';

void main() {
  test('legacy Philippine times match explicit UTC and server timestamps', () {
    final utc = DateTime.utc(2026, 9, 30, 2, 15);
    expect(parseNotificationTime('2026-09-30T10:15:00'), utc);
    expect(parseNotificationTime('2026-09-30T10:15:00+08:00'), utc);
    expect(parseNotificationTime(utc.millisecondsSinceEpoch), utc);
  });
  test('newest first with deterministic ties and unknown times last', () {
    final rows = <Map<String, dynamic>>[
      {'id': 'z', 'time': 'invalid'},
      {'id': 'a', 'time': '2026-09-30T01:00:00Z'},
      {'id': 'b', 'time': '2026-09-30T01:00:00Z'},
      {'id': 'c', 'time': '2026-09-30T02:00:00Z'},
    ]..sort(compareNotificationTimes);
    expect(rows.map((row) => row['id']), ['c', 'b', 'a', 'z']);
  });
  test('invalid timestamps remain unknown', () {
    expect(parseNotificationTime(''), isNull);
    expect(parseNotificationTime({' .sv': 'timestamp'}), isNull);
    expect(parseNotificationTime(double.infinity), isNull);
  });
}
