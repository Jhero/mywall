import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      background: Colors.white,
      surface: Colors.white,
      onBackground: Colors.black,
      onPrimary: Colors.white,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onBackground: Colors.white,
      onPrimary: Colors.black,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF1E1E1E),
    ),
  );

  static final ThemeData blueTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary: Colors.blue.shade600,
      secondary: Colors.lightBlue.shade400,
      surface: Colors.blue.shade50,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: Colors.blue.shade50,
    chipTheme: ChipThemeData(
      backgroundColor: Colors.blue.shade100,
      selectedColor: Colors.blue.shade200,
      secondarySelectedColor: Colors.blue.shade200,
      labelStyle: const TextStyle(),
      secondaryLabelStyle: const TextStyle(),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.blue.shade50,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.blue.shade50,
      foregroundColor: Colors.blue.shade700,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.blue.shade600,
      unselectedItemColor: Colors.grey.shade600,
      backgroundColor: Colors.blue.shade50,
    ),
  );

  static final ThemeData pinkTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary: Colors.pink.shade600,
      secondary: Colors.pinkAccent.shade400,
      surface: Colors.pink.shade50,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: Colors.pink.shade50,
    chipTheme: ChipThemeData(
      backgroundColor: Colors.pink.shade100,
      selectedColor: Colors.pink.shade200,
      secondarySelectedColor: Colors.pink.shade200,
      labelStyle: const TextStyle(),
      secondaryLabelStyle: const TextStyle(),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.pink.shade50,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.pink.shade50,
      foregroundColor: Colors.pink.shade700,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.pink.shade600,
      unselectedItemColor: Colors.grey.shade600,
      backgroundColor: Colors.pink.shade50,
    ),
  );
}
