import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  // Brand Colors
  static const Color brandColor = Color(0xFFE07A5F); // Soft Terra Cotta
  static const Color beigeBackground = Color(0xFFFFF8F0);
  static const Color colorInfo = Color(0xFF2196F3); // Soft Beige
  static const Color colorRating = Color(0xFFF2CC8F); // Star Color

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF334155); // Slate 700
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color colorSuccess = Color(0xFF81B29A); // Sage Green
  static const Color colorError = Color(0xFFE63946); // Red
  static const Color colorWarning = Color(0xFFF4A261); // Orange

  // Shadow Colors
  static final Color shadowColor =
      const Color(0xFF64748B).withValues(alpha: 0.1);
  static final Color shadowColorBrand = brandColor.withValues(alpha: 0.4);

  // Dimensions
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0; // Market app seems to use 16
  static const double radiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Fonts
  static const String fontFamily = 'Poppins';

  static TextTheme get textTheme => GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textSecondary,
        displayColor: textPrimary,
      );

  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }

  static int gridColumns(BuildContext context, {int mobile = 2}) {
    final w = MediaQuery.of(context).size.width;
    if (!isTablet(context)) return mobile;
    if (w >= 1200) return 5;
    if (w >= 1000) return 4;
    if (w >= 800) return 3;
    return 2;
  }

  static double tabletScale(BuildContext context, {double mobile = 1.0}) {
    return isTablet(context) ? 1.08 : mobile;
  }

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
      scaffoldBackgroundColor: beigeBackground,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: beigeBackground,
        elevation: 0,
        centerTitle: false,
        foregroundColor: brandColor,
        iconTheme: IconThemeData(color: brandColor),
        titleTextStyle: TextStyle(
          color: brandColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(
            color: brandColor.withValues(alpha: 0.1),
          ),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: brandColor.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: brandColor),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: brandColor, fontWeight: FontWeight.w600),
        ),
      ),
      dividerColor: brandColor,
      dividerTheme: const DividerThemeData(
        color: brandColor,
        thickness: 1,
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
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: brandColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: paddingMedium, vertical: paddingMedium),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
              vertical: paddingMedium, horizontal: paddingLarge),
        ),
      ),
    );
  }
}
