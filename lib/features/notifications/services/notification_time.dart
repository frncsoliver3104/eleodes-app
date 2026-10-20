/// Legacy timezone-free timestamps were written by the Philippine app.
DateTime? parseNotificationTime(dynamic value) {
  if (value is num) {
    if (!value.isFinite || value <= 0 || value > 8640000000000000) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
  }
  if (value is! String || value.trim().isEmpty) return null;
  final text = value.trim();
  final numeric = num.tryParse(text);
  if (numeric != null) return parseNotificationTime(numeric);
  if (!text.contains('T') && !text.contains(' ')) return null;
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false).hasMatch(text);
  return DateTime.tryParse(hasZone ? text : '$text+08:00')?.toUtc();
}

int compareNotificationTimes(Map<String, dynamic> a, Map<String, dynamic> b) {
  final first = parseNotificationTime(a['time']);
  final second = parseNotificationTime(b['time']);
  if (first == null && second != null) return 1;
  if (second == null && first != null) return -1;
  final order = first == null || second == null ? 0 : second.compareTo(first);
  return order != 0 ? order : '${b['id']}'.compareTo('${a['id']}');
}
