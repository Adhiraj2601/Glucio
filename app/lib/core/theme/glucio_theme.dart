import 'package:flutter/material.dart';

/// Glucio Design System tokens and theme configuration.
///
/// Features bold Neo-brutalist styling:
/// - Warm cream backgrounds & card surfaces
/// - Chunky 2px solid black ink borders
/// - 4px hard offset drop shadows (zero blur)
/// - LilitaOne chunky display font for headings
/// - SpaceMono monospace font for clean body text
class GlucioTheme {
  GlucioTheme._();

  // Color Tokens
  static const Color bgCream = Color(0xFFFBF7E6);
  static const Color cardCream = Color(0xFFFFFDF5);
  static const Color inkBlack = Color(0xFF111111);
  static const Color accentLime = Color(0xFFC8F000);
  static const Color primaryGreen = Color(0xFF0E9F6E);
  static const Color disabledGreen = Color(0xFF86CDB0);

  // Sugar Severity Level Colors (filled inside black-outlined pills)
  static const Color levelLow = Color(0xFF0E9F6E);
  static const Color levelMedium = Color(0xFFFFB800);
  static const Color levelHigh = Color(0xFFFF5A4F);
  static const Color levelMissing = Color(0xFF9E9E9E);

  // Typography Family Names
  static const String fontDisplay = 'LilitaOne';
  static const String fontBody = 'SpaceMono';

  /// Standard Neo-brutalist card decoration with 2px ink border and hard 4px shadow.
  static BoxDecoration cardDecoration({
    Color? surface,
    bool withShadow = true,
    double radius = 20.0,
    Color borderColor = inkBlack,
    double borderWidth = 2.0,
  }) {
    return BoxDecoration(
      color: surface ?? cardCream,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: withShadow
          ? [
              const BoxShadow(
                color: inkBlack,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ]
          : null,
    );
  }

  /// Fully rounded pill / badge decoration with 2px ink border.
  static BoxDecoration pillDecoration({
    required Color fill,
    bool withShadow = false,
  }) {
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: inkBlack, width: 2),
      boxShadow: withShadow
          ? [
              const BoxShadow(
                color: inkBlack,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ]
          : null,
    );
  }

  /// Theme data setup for MaterialApp.
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        surface: cardCream,
        onSurface: inkBlack,
        primary: primaryGreen,
        onPrimary: Colors.white,
      ),
      fontFamily: fontBody,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 34,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 28,
        ),
        displaySmall: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 22,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 26,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 22,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 18,
        ),
        titleLarge: TextStyle(
          fontFamily: fontBody,
          color: inkBlack,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          fontFamily: fontBody,
          color: inkBlack,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        titleSmall: TextStyle(
          fontFamily: fontBody,
          color: inkBlack,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontBody,
          color: inkBlack,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontBody,
          color: inkBlack,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          fontFamily: fontBody,
          color: inkBlack,
          fontSize: 11,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCream,
        foregroundColor: inkBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontDisplay,
          color: inkBlack,
          fontSize: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: inkBlack, width: 2),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkBlack,
          side: const BorderSide(color: inkBlack, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
