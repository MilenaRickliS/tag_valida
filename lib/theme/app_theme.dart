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
    scaffoldBackgroundColor: const Color(0xFF1B1B1B),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFED7227),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B1B1B),
      foregroundColor: Color(0xFFFDF7ED),
      elevation: 0,
      centerTitle: true,
    ),
    cardColor: const Color(0xFF2A2A2A),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}