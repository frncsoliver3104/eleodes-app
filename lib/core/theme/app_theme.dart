import 'package:flutter/material.dart';

class ThemeTransition extends ThemeExtension<ThemeTransition> {
  final double darkAmount;
  const ThemeTransition(this.darkAmount);

  @override
  ThemeTransition copyWith({double? darkAmount}) =>
      ThemeTransition(darkAmount ?? this.darkAmount);

  @override
  ThemeTransition lerp(covariant ThemeTransition? other, double t) =>
      other == null
      ? this
      : ThemeTransition(darkAmount + (other.darkAmount - darkAmount) * t);
}

/// Mint accents with deep green surfaces in dark mode.
class AppTheme {
  static const mint = Color(0xFF1DE3AB);
  static const darkBackground = Color(0xFF101E1A);
  static const darkSurface = Color(0xFF1C3029);
  static const darkText = Color(0xFFE6F5ED);

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: mint,
      brightness: brightness,
      primary: isDark ? mint : const Color(0xFF007E59),
      onPrimary: isDark ? darkBackground : Colors.white,
      surface: isDark ? darkSurface : const Color(0xFFF5FFFA),
      onSurface: isDark ? darkText : const Color(0xFF090909),
    );
    return ThemeData(
      extensions: [ThemeTransition(isDark ? 1 : 0)],
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? darkBackground
          : const Color(0xFFD4FFED),
      dividerColor: isDark ? const Color(0xFF3B554B) : const Color(0x401B1B1B),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkBackground : const Color(0xFFD4FFED),
        foregroundColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color blend(BuildContext context, Color light, Color dark) {
    final theme = Theme.of(context);
    final amount =
        theme.extension<ThemeTransition>()?.darkAmount ??
        (theme.brightness == Brightness.dark ? 1.0 : 0.0);
    return Color.lerp(light, dark, amount)!;
  }

  static Color background(BuildContext context, Color light) =>
      blend(context, light, darkBackground);
  static Color surface(BuildContext context, Color light) =>
      blend(context, light, darkSurface);
  static Color text(BuildContext context, Color light) =>
      blend(context, light, darkText);
  static Color muted(BuildContext context, Color light) =>
      blend(context, light, const Color(0xFFA9C4B7));
  static Color accentText(BuildContext context, Color light) =>
      blend(context, light, mint);
  static Color accentSurface(BuildContext context, Color light) =>
      blend(context, light, const Color(0xFF175D46));
}
