import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:ELEODES/features/settings/screens/settings_screen.dart';
import 'package:ELEODES/features/settings/widgets/settings_tile.dart';
import 'package:ELEODES/features/legal/screens/privacy_policy_screen.dart';
import 'package:ELEODES/features/notifications/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Notification alone gates alerts and ignores the old System Alerts setting',
    () async {
      SharedPreferences.setMockInitialValues({'systemAlerts': false});
      final settings = AppSettings();
      await settings.initialize();
      expect(settings.sensorAlertsEnabled, isTrue);
      await settings.setValue('notification', false);
      expect(settings.sensorAlertsEnabled, isFalse);
      await settings.setValue('darkMode', true);
      final reopened = AppSettings();
      await reopened.initialize();
      expect(reopened.darkMode, isTrue);
      expect(reopened.sensorAlertsEnabled, isFalse);
      await reopened.setValue('notification', true);
      expect(reopened.sensorAlertsEnabled, isTrue);
      await reopened.setValue('notification', false);
      expect(reopened.sensorAlertsEnabled, isFalse);
    },
  );

  testWidgets('dark switch updates active theme and persists selection', (
    tester,
  ) async {
    await AppSettings.instance.initialize();
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppSettings.instance.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SettingsTile, 'Dark mode'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppTheme.darkBackground);
    expect((await SharedPreferences.getInstance()).getBool('darkMode'), isTrue);
    final label = tester.widget<Text>(find.text('Dark mode'));
    expect(label.style!.color, AppTheme.darkText);
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SettingsTile, 'Dark mode'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      (await SharedPreferences.getInstance()).getBool('darkMode'),
      isFalse,
    );
  });

  testWidgets('legal and notification surfaces remain dark and readable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const PrivacyPolicyScreen()),
    );
    await tester.pumpAndSettle();
    final surfaces = tester
        .widgetList<Container>(find.byType(Container))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      surfaces.any((decoration) => decoration.color == AppTheme.darkSurface),
      isTrue,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: NotificationCard(
            title: 'Water Tank Nearly Full',
            message: 'The water tank is 90% full.',
            time: 'Now',
            type: 'warning',
            read: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final contrast =
        (AppTheme.darkText.computeLuminance() + 0.05) /
        (AppTheme.darkSurface.computeLuminance() + 0.05);
    expect(contrast, greaterThan(4.5));
  });
}
