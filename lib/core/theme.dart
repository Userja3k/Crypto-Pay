import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidGlassTheme {
  // Core Colors
  static const Color background = Color(0xFF000000);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color surface = Color(0xFF131313);
  static const Color onSurfaceVariant = Color(0xFFC4C7C8);
  
  // Design Tokens
  static const double marginPage = 24.0;
  static const double gutter = 16.0;
  static const double radiusLarge = 32.0;
  static const double radiusMedium = 16.0;
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        error: error,
        surface: surface,
        onSurface: primary,
      ),
      textTheme: TextTheme(
        // Display - For large balances
        displayLarge: GoogleFonts.hankenGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.04 * 48,
          color: primary,
        ),
        // Headline - For page titles
        headlineLarge: GoogleFonts.hankenGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 32,
          color: primary,
        ),
        headlineMedium: GoogleFonts.hankenGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        // Body - For general text
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primary,
        ),
        // Label - For small data/caps (using Inter since Geist is not available in GoogleFonts)
        labelSmall: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02 * 13,
          color: onSurfaceVariant,
        ),
        // Data - For monospaced values
        labelMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primary,
        ),
      ),
    );
  }
}
