import 'package:flutter/material.dart';

/// Primary brand color — warm saffron representing Indian identity
const Color kPrimaryColor = Color(0xFFFF6F00);
const Color kPrimaryDark = Color(0xFFE65100);
const Color kAccentColor = Color(0xFF00BFA5);
const Color kErrorColor = Color(0xFFD32F2F);

/// Accessible text styles — min 16sp body for readability
const TextStyle kBodyLarge = TextStyle(fontSize: 18, height: 1.5);
const TextStyle kBodyMedium = TextStyle(fontSize: 16, height: 1.4);
const TextStyle kHeadlineLarge = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3);
const TextStyle kHeadlineMedium = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: kPrimaryColor,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: kHeadlineLarge,
    headlineMedium: kHeadlineMedium,
    bodyLarge: kBodyLarge,
    bodyMedium: kBodyMedium,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: kPrimaryColor,
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: const Color(0xFF1E1E1E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: kHeadlineLarge,
    headlineMedium: kHeadlineMedium,
    bodyLarge: kBodyLarge,
    bodyMedium: kBodyMedium,
  ),
);
