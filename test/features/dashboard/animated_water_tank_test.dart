import 'package:ELEODES/features/dashboard/widgets/animated_water_tank.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _tank({double? percentage, double? flowRate}) => MaterialApp(
  home: Scaffold(
    body: AnimatedWaterTank(percentage: percentage, flowRate: flowRate),
  ),
);

double _paintedLevel(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(AnimatedWaterTank),
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter != null,
      ),
    ),
  );
  final dynamic painter = paint.painter;
  final Animation<double> fill = painter.fill as Animation<double>;
  return fill.value;
}

void main() {
  testWidgets('displays firmware L/day without converting it again', (
    tester,
  ) async {
    await tester.pumpWidget(_tank(percentage: 36, flowRate: 144));

    expect(find.text('144.0 L/day', findRichText: true), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tank level 36 percent. Estimated daily production rate '
        '144.0 liters per day at the current flow.',
      ),
      findsOneWidget,
    );
    expect(_paintedLevel(tester), 0.36);
  });

  testWidgets('preserves genuine zero readings', (tester) async {
    await tester.pumpWidget(_tank(percentage: 0, flowRate: 0));

    expect(find.text('0.0 L/day', findRichText: true), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tank level 0 percent. Estimated daily production rate '
        '0.0 liters per day at the current flow.',
      ),
      findsOneWidget,
    );
    expect(_paintedLevel(tester), 0);
  });

  testWidgets('missing and invalid readings are unavailable, not empty', (
    tester,
  ) async {
    for (final percentage in <double?>[null, double.nan, -1, 101]) {
      await tester.pumpWidget(
        _tank(percentage: percentage, flowRate: double.nan),
      );

      expect(find.text('-- L/day', findRichText: true), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Tank level unavailable. Estimated daily production rate unavailable.',
        ),
        findsOneWidget,
      );
      expect(_paintedLevel(tester), 0);
    }
  });

  testWidgets('first reading and reconnect draw the actual level immediately', (
    tester,
  ) async {
    await tester.pumpWidget(_tank());
    await tester.pumpWidget(_tank(percentage: 75, flowRate: 144));
    expect(_paintedLevel(tester), 0.75);

    await tester.pump(const Duration(milliseconds: 100));
    expect(_paintedLevel(tester), 0.75);

    await tester.pumpWidget(_tank());
    expect(_paintedLevel(tester), 0);
    await tester.pumpWidget(_tank(percentage: 48, flowRate: 0));
    expect(_paintedLevel(tester), 0.48);
  });
}
