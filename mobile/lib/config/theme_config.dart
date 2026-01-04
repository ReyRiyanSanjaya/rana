import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';

class ThemeConfig {
  // Brand Colors
  static const Color brandColor = Color(0xFFE07A5F); // Soft Terra Cotta
  static const Color beigeBackground = Color(0xFFFFF8F0); // Soft Beige

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF334155); // Slate 700
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color colorSuccess = Color(0xFF81B29A); // Sage Green
  static const Color colorError = Color(0xFFE63946); // Red
  static const Color colorWarning = Color(0xFFF4A261); // Orange

  // Shadow Colors
  static final Color shadowColor = const Color(0xFF64748B).withOpacity(0.1);
  static final Color shadowColorBrand = brandColor.withOpacity(0.4);

  // Dimensions
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Fonts
  static const String fontFamily = 'Inter';

  static TextTheme get textTheme => GoogleFonts.outfitTextTheme().apply(
        bodyColor: textSecondary,
        displayColor: textPrimary,
      );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandColor,
        primary: brandColor,
        onPrimary: textOnPrimary,
        secondary: brandColor,
        surface: Colors.white,
        surfaceContainerHighest: beigeBackground,
      ),
      dividerColor: brandColor,
      dividerTheme: const DividerThemeData(
        color: brandColor,
        thickness: 1,
      ),
      scaffoldBackgroundColor: beigeBackground,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: beigeBackground,
        foregroundColor: brandColor,
        iconTheme: IconThemeData(color: brandColor),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: Colors.transparent, width: 0),
        ),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: brandColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brandColor,
        unselectedItemColor: brandColor,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
          side: BorderSide.none,
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide(color: brandColor.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: brandColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 4,
          shadowColor: shadowColorBrand,
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: brandColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
    );
  }
}
