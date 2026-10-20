import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Uygulamanın tek ThemeData kaynağı. Cam tasarım dili koyu temadır.
abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navActiveStart,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.bgMid,
    );
    if (!AppText.useGoogleFonts) return base;
    return base.copyWith(textTheme: GoogleFonts.manropeTextTheme(base.textTheme));
  }
}
