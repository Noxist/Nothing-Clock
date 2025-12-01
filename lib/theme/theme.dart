import 'package:flutter/material.dart';

// Nothing OS Color Palette
class NothingColors {
  static const Color black = Color(0xFF000000);
  static const Color darkGrey = Color(0xFF1C1C1E); // Surface color
  static const Color midGrey = Color(0xFF2C2C2E);
  static const Color lightGrey = Color(0xFF8E8E93);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFD71921); // Official Nothing Red
}

class NothingTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: NothingColors.red,
        onPrimary: NothingColors.white,
        surface: NothingColors.white,
        onSurface: NothingColors.black,
        secondary: NothingColors.black,
        onSecondary: NothingColors.white,
        error: NothingColors.red,
        background: NothingColors.white,
        onBackground: NothingColors.black,
      ),
      scaffoldBackgroundColor: NothingColors.white,
      fontFamily: 'Roboto',
      textTheme: _textTheme(Colors.black),
      appBarTheme: const AppBarTheme(
        backgroundColor: NothingColors.white,
        foregroundColor: NothingColors.black,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(color: NothingColors.black),
      dividerColor: NothingColors.midGrey.withOpacity(0.2),
    );
  }

  // Dark Theme (Optimized for OLED/Pixel)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: NothingColors.red,
        onPrimary: NothingColors.white,
        surface: NothingColors.black, // Pure black for OLED
        onSurface: NothingColors.white,
        secondary: NothingColors.white,
        onSecondary: NothingColors.black,
        error: NothingColors.red,
        background: NothingColors.black,
        onBackground: NothingColors.white,
      ),
      scaffoldBackgroundColor: NothingColors.black,
      fontFamily: 'Roboto',
      textTheme: _textTheme(Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: NothingColors.black,
        foregroundColor: NothingColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      iconTheme: const IconThemeData(color: NothingColors.white),
      dividerColor: NothingColors.midGrey,
    );
  }

  // Consistent Text Theme with NDot headers
  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'NDot', fontSize: 57, color: color),
      displayMedium: TextStyle(fontFamily: 'NDot', fontSize: 45, color: color),
      displaySmall: TextStyle(fontFamily: 'NDot', fontSize: 36, color: color),
      headlineLarge: TextStyle(fontFamily: 'NDot', fontSize: 32, color: color),
      headlineMedium: TextStyle(fontFamily: 'NDot', fontSize: 28, color: color),
      headlineSmall: TextStyle(fontFamily: 'NDot', fontSize: 24, color: color),
      titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w500, color: color),
      titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w500, color: color),
      titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: color),
      bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: color),
      labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: color),
    );
  }
}
