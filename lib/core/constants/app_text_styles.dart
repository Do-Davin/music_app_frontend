import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get header => GoogleFonts.oxygen(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );

  static TextStyle get subtitle => GoogleFonts.oxygen(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle get body => GoogleFonts.oxygen(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );

  static TextStyle get button =>
      GoogleFonts.oxygen(fontSize: 16, fontWeight: FontWeight.w600);
}
