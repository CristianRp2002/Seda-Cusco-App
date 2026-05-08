// lib/core/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // =========================================================
  // COLORES PRINCIPALES
  // =========================================================

  static const Color primaryBlue = Color(0xFF0B63C9);
  static const Color darkBlue = Color(0xFF084C9E);

  static const Color accentCyan = Color(0xFF12B5EA);
  static const Color softCyan = Color(0xFFEAF8FF);

  // =========================================================
  // ESTADOS
  // =========================================================

  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color dangerRed = Color(0xFFE74C3C);

  // =========================================================
  // GRISES / FONDOS
  // =========================================================

  static const Color background = Color(0xFFF4F7FB);

  static const Color cardWhite = Colors.white;

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color borderColor = Color(0xFFE5E7EB);

  // =========================================================
  // SOMBRAS
  // =========================================================

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  // =========================================================
  // BORDER RADIUS
  // =========================================================

  static BorderRadius radiusSmall = BorderRadius.circular(10);

  static BorderRadius radiusMedium = BorderRadius.circular(16);

  static BorderRadius radiusLarge = BorderRadius.circular(22);

  // =========================================================
  // ESPACIADOS
  // =========================================================

  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;

  // =========================================================
  // THEME DATA
  // =========================================================

  static ThemeData get theme => ThemeData(
    useMaterial3: true,

    fontFamily: 'Roboto',

    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,

      primary: primaryBlue,

      secondary: accentCyan,

      background: background,
    ),

    // =====================================================
    // APP BAR
    // =====================================================

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,

      foregroundColor: Colors.white,

      elevation: 0,

      centerTitle: true,

      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    // =====================================================
    // TEXTOS
    // =====================================================

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),

      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),

      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimary,
      ),

      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    // =====================================================
    // INPUTS
    // =====================================================

    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: Colors.white,

      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMedium,
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),
    ),

    // =====================================================
    // ELEVATED BUTTON
    // =====================================================

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,

        foregroundColor: Colors.white,

        elevation: 0,

        minimumSize: const Size(double.infinity, 54),

        shape: RoundedRectangleBorder(
          borderRadius: radiusMedium,
        ),

        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),

    // =====================================================
    // FLOATING ACTION BUTTON
    // =====================================================

    floatingActionButtonTheme:
    const FloatingActionButtonThemeData(
      backgroundColor: accentCyan,

      foregroundColor: Colors.white,

      elevation: 6,
    ),

    // =====================================================
    // BOTTOM NAVIGATION
    // =====================================================

    bottomNavigationBarTheme:
    const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,

      selectedItemColor: accentCyan,

      unselectedItemColor: Colors.grey,

      elevation: 10,

      type: BottomNavigationBarType.fixed,
    ),

    // =====================================================
    // SNACKBAR
    // =====================================================

    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkBlue,

      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),

      behavior: SnackBarBehavior.floating,

      shape: RoundedRectangleBorder(
        borderRadius: radiusMedium,
      ),
    ),

    // =====================================================
    // DIVIDER
    // =====================================================

    dividerColor: borderColor,
  );
}