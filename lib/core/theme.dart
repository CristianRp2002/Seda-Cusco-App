import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0077B6);
  static const Color secondaryColor = Color(0xFF00B4D8);
  static const Color backgroundColor = Color(0xFFF0F8FF);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
        fontFamily: 'Roboto',
      );
}