import 'package:ELEODES/features/production/widgets/water_usage_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget card(Map<String, double> records) => MaterialApp(home: Scaffold(
    body: WaterUsageCard(today: DateTime.utc(2026, 9, 30), records: records,
      background: Colors.grey, foreground: Colors.black),
  ));

  testWidgets('usage totals include only Monday through today', (tester) async {
    await tester.pumpWidget(card({
      '2026-09-27': 99, '2026-09-28': 4, '2026-09-29': 5,
      '2026-09-30': 3.1, '2026-10-01': 99,
    }));
    expect(find.text('3.1 L', findRichText: true), findsOneWidget);
    expect(find.text('12.1 L', findRichText: true), findsOneWidget);
    expect(find.textContaining('Partial week'), findsNothing);
  });

  testWidgets('missing usage is not presented as zero', (tester) async {
    await tester.pumpWidget(card({}));
    expect(find.text('-- L', findRichText: true), findsNWidgets(2));
  });

  testWidgets('incomplete week is clearly identified', (tester) async {
    await tester.pumpWidget(card({'2026-09-29': 2, '2026-09-30': double.nan}));
    expect(find.text('2.0 L', findRichText: true), findsOneWidget);
    expect(find.text('Partial week: 1/3 days recorded'), findsOneWidget);
  });
}
