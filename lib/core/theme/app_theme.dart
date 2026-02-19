import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define the custom color scheme for Light Mode (Midas/Modern Financial Style)
  static const FlexSchemeColor _lightScheme = FlexSchemeColor(
    primary: Color(0xFF4F46E5), // Indigo 600
    primaryContainer: Color(0xFFE0E7FF), // Indigo 100
    secondary: Color(0xFF0D9488), // Teal 600
    secondaryContainer: Color(0xFFCCFBF1), // Teal 100
    tertiary: Color(0xFFF59E0B), // Amber 500
    tertiaryContainer: Color(0xFFFEF3C7), // Amber 100
    appBarColor: Color(0xFFF8FAFC), // Slate 50
    error: Color(0xFFEF4444), // Red 500
  );

  // Define the custom color scheme for Dark Mode
  static const FlexSchemeColor _darkScheme = FlexSchemeColor(
    primary: Color(0xFF818CF8), // Indigo 400
    primaryContainer: Color(0xFF3730A3), // Indigo 800
    secondary: Color(0xFF2DD4BF), // Teal 400
    secondaryContainer: Color(0xFF115E59), // Teal 800
    tertiary: Color(0xFFFBBF24), // Amber 400
    tertiaryContainer: Color(0xFF78350F), // Amber 900
    appBarColor: Color(0xFF0F172A), // Slate 900
    error: Color(0xFFF87171), // Red 400
  );

  // Light Theme
  static ThemeData get light {
    return FlexThemeData.light(
      colors: _lightScheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7, // Slightly higher blend for softness
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        // Soft rounded corners for "2026 Modern" look
        cardRadius: 24.0,
        inputDecoratorRadius: 16.0,
        elevatedButtonRadius: 16.0,
        outlinedButtonRadius: 16.0,
        fabRadius: 16.0,
        dialogRadius: 24.0,
        bottomSheetRadius: 24.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      // Modern Financial Font
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: _textTheme,
    );
  }

  // Dark Theme
  static ThemeData get dark {
    return FlexThemeData.dark(
      colors: _darkScheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13, // Higher blend for dark mode depth
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        // consistent rounded corners
        cardRadius: 24.0,
        inputDecoratorRadius: 16.0,
        elevatedButtonRadius: 16.0,
        outlinedButtonRadius: 16.0,
        fabRadius: 16.0,
        dialogRadius: 24.0,
        bottomSheetRadius: 24.0,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      // Modern Financial Font
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: _textTheme,
    );
  }

  // Standardized Text Theme - Compact Style (Extra Reduced)
  // Base: 12sp (Very compact mobile apps)
  static TextTheme get _textTheme {
    return TextTheme(
      // Extra Large (18sp) - Page Titles
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),

      // Large (14sp) - Section Headers / Usernames / Buttons
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: -0.2,
      ),

      // Medium (12sp) - Body Text
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: -0.1,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.4,
        letterSpacing: -0.1,
      ),

      // Small (10sp) - Meta data
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        height: 1.3,
        letterSpacing: 0.1,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.1,
      ),

      // Extra Small (9sp) - Legal/Helpers
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.2,
      ),
    );
  }
}
