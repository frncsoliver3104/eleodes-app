import 'package:flutter/material.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:ELEODES/app/startup_screen.dart';

class AWGApp extends StatelessWidget {
  const AWGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance.darkModeChanges,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ELEODES',

        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeAnimationDuration: const Duration(milliseconds: 320),
        themeAnimationCurve: Curves.easeInOutCubic,
        themeMode: AppSettings.instance.darkMode
            ? ThemeMode.dark
            : ThemeMode.light,

        home: const LoadingScreen(),
      ),
    );
  }
}
