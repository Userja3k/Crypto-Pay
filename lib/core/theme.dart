import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassTheme {
  static const Color background = Color(0xFF000000);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  
  static const double marginPage = 24.0;
  static const double gutter = 16.0;
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        error: error,
        surface: Color(0xFF131313),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.hankenGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.04 * 48,
          color: primary,
        ),
        headlineLarge: GoogleFonts.hankenGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 32,
          color: primary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02 * 13,
          color: primary,
        ),
      ),
    );
  }
}
