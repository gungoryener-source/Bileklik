import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Yazı stilleri. Yazı tipi: Manrope.
abstract final class AppText {
  /// Testlerde `false` yapılır, böylece font ağdan indirilmeye çalışılmaz.
  static bool useGoogleFonts = true;

  static TextStyle style(
    double size,
    FontWeight weight, {
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
    return useGoogleFonts ? GoogleFonts.manrope(textStyle: base) : base;
  }

  /// Ana ekrandaki büyük nabız sayısı.
  static TextStyle get display =>
      style(68, FontWeight.w800, height: 1, letterSpacing: -2);

  /// Ekran başlığı ("Bugün").
  static TextStyle get title =>
      style(30, FontWeight.w800, height: 1.1, letterSpacing: -0.5);

  /// Kartlardaki büyük değer.
  static TextStyle get metric =>
      style(36, FontWeight.w800, height: 1, letterSpacing: -1);

  /// Değerin yanındaki birim (bpm, dk).
  static TextStyle get unit => style(17, FontWeight.w700, letterSpacing: 0);

  static TextStyle get cardLabel => style(15, FontWeight.w700);

  static TextStyle get caption =>
      style(13, FontWeight.w600, color: AppColors.textSecondary);

  static TextStyle get button => style(15, FontWeight.w800);

  static TextStyle get small => style(12, FontWeight.w700);

  static TextStyle get navLabel => style(11, FontWeight.w700);
}
