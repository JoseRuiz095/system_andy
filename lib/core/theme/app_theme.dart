import 'package:flutter/material.dart';

class AppTheme {
  // Color definitions based on "The Artisanal Interface" strategy
  static const Color surface = Color(0xFFfbfbe2); // tabletop
  static const Color surfaceContainer = Color(0xFFefefd7); // tray
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // paper
  static const Color surfaceContainerHigh = Color(0xFFeaead1);
  static const Color surfaceContainerHighest = Color(0xFFe4e4cc);
  static const Color surfaceContainerLow = Color(0xFFf5f5dc);
  static const Color primary = Color(0xFF002c06);
  static const Color primaryContainer = Color(0xFF00450e);
  static const Color primaryFixed = Color(0xFF94f990);
  static const Color secondary = Color(0xFF725a42);
  static const Color secondaryContainer = Color(0xFFfedcbe);
  static const Color tertiary = Color(0xFF351f17);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFD2C4BA);
  static const Color inverseSurface = Color(0xFF303221);
  static const Color chlorophyllGreen = Color(0xFF00C853); 
  static const Color hintTextColor = Color(0xFF888888); // for high-velocity actions

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: primary,
        error: Colors.red.shade700,
        onError: Colors.white,
        surface: surface,
        onSurface: primary,
      ),
      // Typography: Manrope for display, Inter for everything else
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 56, // 3.5rem
          letterSpacing: 0.5,
          color: primary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 32,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: primary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: primary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: primary,
        ),
        // Tertiary/fine print
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: tertiary,
        ),
      ),
      // Button styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // xl roundedness
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          elevation: 0, // No harsh shadows
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          side: BorderSide.none, // No borders
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      cardColor: surfaceContainerHigh,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: InputBorder.none, // No borders
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: TextStyle(color: secondary.withAlpha((0.7 * 255).toInt())),
      ),
      dividerColor: Colors.transparent, // No dividers
      // Add more component theming as needed
    );
  }
}
