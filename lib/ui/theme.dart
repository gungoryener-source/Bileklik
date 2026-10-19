import 'package:flutter/material.dart';

/// Uygulamanın kendi renkleri. Referans uygulamanın görselleri kullanılmaz.
abstract final class AppColors {
  static const background = Color(0xFF0E1116);
  static const surface = Color(0xFF181C23);
  static const accent = Color(0xFF2EC4B6);
  static const heart = Color(0xFFE85D75);
  static const oxygen = Color(0xFF4EA8DE);
  static const temperature = Color(0xFFF4A261);
  static const steps = Color(0xFF90BE6D);
  static const muted = Color(0xFF8A93A3);
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
  );
  return base.copyWith(
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background, centerTitle: false),
  );
}
