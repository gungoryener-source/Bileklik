import 'package:flutter/painting.dart';

/// "Cam" tasarım dilinin renkleri. Ekranlar renkleri buradan okur,
/// widget içinde yeni renk tanımlamaz.
abstract final class AppColors {
  // Zemin degradesi
  static const bgTop = Color(0xFF140D38);
  static const bgMid = Color(0xFF0B0A22);
  static const bgBottom = Color(0xFF08142E);

  // Aurora ışıkları
  static const auroraPink = Color(0xFFFF2E88);
  static const auroraViolet = Color(0xFF6C4BFF);
  static const auroraCyan = Color(0xFF00C8FF);
  static const auroraLime = Color(0xFF9DFF3D);

  // Metin
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xBFFFFFFF); // %75 beyaz
  static const textMuted = Color(0xC7FFFFFF); // %78 beyaz (pasif menü)

  // Cam yüzey
  static const glassBase = Color(0x66141030); // koyu taban, %40
  static const glassSheenStart = Color(0x29FFFFFF); // %16 beyaz
  static const glassSheenEnd = Color(0x0AFFFFFF); // %4 beyaz
  static const glassBorder = Color(0x2EFFFFFF); // %18 beyaz
  static const navBase = Color(0x8C161234); // alt menü tabanı, %55

  // Kart renk tonları
  static const heroTintStart = Color(0x61FF408C);
  static const heroTintEnd = Color(0x297828C8);
  static const sleepTintStart = Color(0x6B7C5CFF);
  static const sleepTintEnd = Color(0x2E281E78);

  // Butonlar
  static const ctaStart = Color(0xFFD9225F);
  static const ctaEnd = Color(0xFF6A3DF0);
  static const ctaGlow = Color(0x80D9225F);
  static const navActiveStart = Color(0xFF7B5CFF);
  static const navActiveEnd = Color(0xFFD9225F);
  static const navActiveGlow = Color(0x8C9646FF);

  // Durum
  static const online = Color(0xFF9DFF3D);
  static const offline = Color(0x80FFFFFF);

  // Haftalık grafik
  static const barTodayStart = Color(0xFFFF8CC0);
  static const barTodayEnd = Color(0xFFE62A68);
  static const barTodayGlow = Color(0x99E62A68);
  static const barStart = Color(0x57FFFFFF);
  static const barEnd = Color(0x14FFFFFF);
  static const barEmpty = Color(0x14FFFFFF);
  static const dayToday = Color(0xFFFFB0D3);
}
