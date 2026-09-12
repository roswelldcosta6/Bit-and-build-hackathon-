import 'package:flutter/material.dart';

/// Pocket-minimal design system (Notion-inspired):
/// - Strictly 0px corners on every component
/// - Hairline borders and light-gray dividers
/// - Monochrome foundation with one soft accessible accent
/// - System sans-serif stack (Inter when installed, otherwise SF/Roboto)
class AppTheme {
  AppTheme._();

  // Monochrome foundation
  static const bg = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF09090B);
  static const mutedInk = Color(0xFF61616B);
  static const hairline = Color(0xFFE4E4E7);

  // Soft accessible accent (blue) + semantic colors
  static const accent = Color(0xFF0F62FE);
  static const mint = Color(0xFF2CB67D);
  static const danger = Color(0xFFDA1E28);

  static const _fontFallbacks = [
    'Inter',
    'Inter Tight',
    'SF Pro Text',
    'Roboto',
    'Helvetica Neue',
    'Segoe UI',
  ];

  static ThemeData light(double scale) => _theme(Brightness.light, scale);
  static ThemeData dark(double scale) => _theme(Brightness.dark, scale);

  static ThemeData _theme(Brightness brightness, double scale) {
    final isLight = brightness == Brightness.light;
    final scheme = isLight
        ? ColorScheme.light(
            primary: accent,
            onPrimary: Colors.white,
            secondary: ink,
            onSecondary: Colors.white,
            surface: surface,
            onSurface: ink,
            onSurfaceVariant: mutedInk,
            outline: hairline,
            error: danger,
          )
        : ColorScheme.dark(
            primary: Color(0xFF78A9FF), // lighter blue for dark backgrounds
            onPrimary: Color(0xFF09090B),
            secondary: Colors.white,
            onSecondary: Color(0xFF09090B),
            surface: Color(0xFF141416),
            onSurface: Color(0xFFF4F4F5),
            onSurfaceVariant: Color(0xFFA1A1AA),
            outline: Color(0xFF2A2A2E),
            error: Color(0xFFFF8389),
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamilyFallback: _fontFallbacks,
    );

    final hair = scheme.outline;

    OutlineInputBorder squareBorder({Color? color, double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color ?? hair, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: isLight ? bg : const Color(0xFF0B0B0D),
      dividerColor: hair,
      dividerTheme: DividerThemeData(color: hair, thickness: 1, space: 1),
      textTheme: base.textTheme
          .apply(
            fontSizeFactor: scale,
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          )
          .copyWith(
            labelSmall: base.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
          fontSize: (base.textTheme.titleMedium?.fontSize ?? 16) * scale,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: hair),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: squareBorder(),
        enabledBorder: squareBorder(),
        focusedBorder: squareBorder(color: accent, width: 1.4),
        errorBorder: squareBorder(color: danger),
        focusedErrorBorder: squareBorder(color: danger, width: 1.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: hair),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const RoundedRectangleBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: hair)),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: BorderSide(color: hair),
        backgroundColor: scheme.surface,
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.withValues(alpha: .35)
              : Colors.transparent,
        ),
        trackOutlineColor: WidgetStatePropertyAll(hair),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
