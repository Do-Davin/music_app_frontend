import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core theme colors
  static const Color background = Color.fromRGBO(18, 18, 18, 1);
  static const Color primary = Color.fromRGBO(255, 165, 0, 1);
  static const Color error = Color.fromRGBO(255, 82, 82, 1);
  static const Color warning = Color.fromRGBO(244, 211, 94, 1);

  // Surfaces
  static const Color surface = Color.fromRGBO(30, 30, 30, 1);
  static const Color card = Color.fromRGBO(36, 36, 36, 1);

  // Navigation
  static const Color navBar = Color.fromRGBO(30, 30, 30, 1);
  static const Color navSelected = primary;
  static const Color navUnselected = Color.fromRGBO(136, 136, 136, 1);

  // Inputs
  static const Color inputBorder = Color.fromRGBO(58, 58, 58, 1);
  static const Color hint = Color.fromRGBO(117, 117, 117, 1);

  // Foreground
  static const Color onPrimary = Color.fromRGBO(18, 18, 18, 1);
  static const Color onError = Color.fromRGBO(255, 255, 255, 1);
  static const Color onWarning = Color.fromRGBO(18, 18, 18, 1);
  static const Color onSurface = Color.fromRGBO(255, 255, 255, 1);
  static const Color errorBackground = Color(0x33FF5252); // transparent red
  static const Color statusIconBrown = Color(
    0xFF3D2E00,
  ); // dark brown circle bg
  static const Color statusIconBrownRing = Color(
    0xFF5C4A00,
  ); // ring/badge color
}
