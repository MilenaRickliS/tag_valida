import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFDF7ED),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFED7227),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFDF7ED),
      foregroundColor: Color(0xFF282828),
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: Color(0xFFFDF7ED),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2A2828)),
      bodyMedium: TextStyle(color: Color(0xFF2A2828)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFFD4AF37),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F0F),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFD6D6D6)),
    ),
  );
}