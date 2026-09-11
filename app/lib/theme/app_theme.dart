import 'package:flutter/material.dart';

class AppTheme {
  static const _navy = Color(0xFF13213C);
  static const _blue = Color(0xFF2C6BED);
  static const mint = Color(0xFF2CB67D);

  static ThemeData light(double scale) => _theme(Brightness.light, scale);
  static ThemeData dark(double scale) => _theme(Brightness.dark, scale);

  static ThemeData _theme(Brightness brightness, double scale) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: _blue,
    );
    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F9FD)
          : const Color(0xFF0D1424),
      textTheme: base.textTheme.apply(fontSizeFactor: scale),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: brightness == Brightness.light ? _navy : Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF17233A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
