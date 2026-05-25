import 'package:flutter/material.dart';

abstract class RegistrosColors {
  static const Color primary = Color(0xFF0D47A1);
  static const Color accent = Color(0xFF00BCD4);
  static const Color surface = Color(0xFFF8FAFF);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF5C6B8A);
  static const Color border = Color(0xFFDDE3F0);
  static const Color success = Color(0xFF00897B);
  static const Color warning = Color(0xFFF57C00);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
