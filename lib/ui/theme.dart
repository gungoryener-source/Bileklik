import 'package:flutter/material.dart';

/// Veri renkleri: ölçüm türlerini ayırt eder, iki temada da aynıdır.
/// Metin olarak değil, ikon, çizgi ve sütunlarda kullanılır.
abstract final class DataColors {
  static const heart = Color(0xFFE85D75);
  static const hrv = Color(0xFF2EC4B6);
  static const oxygen = Color(0xFF4EA8DE);
  static const temperature = Color(0xFFF4A261);
  static const steps = Color(0xFF7CB356);
  static const stress = Color(0xFFB388EB);
  static const respiration = Color(0xFF5BC8DE);
  static const pressure = Color(0xFFFF8FA3);
  static const sleepDeep = Color(0xFF3A47B8);
  static const sleepLight = Color(0xFF6C8CFF);
  static const sleepRem = Color(0xFFB388EB);
}

/// Uygulamanın kendi renkleri; açık ve koyu temada farklıdır.
/// Ekranlar `context.colors` ile alır, sabit renk yazılmaz.
/// Referans uygulamanın görselleri kullanılmaz.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.glow,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.muted,
    required this.danger,
  });

  final Color background;
  final Color surface;

  /// Kart içindeki gömük alanlar (ör. alt istatistik satırı).
  final Color surfaceHigh;

  /// Kart kenar çizgisi.
  final Color outline;

  /// Ana Sayfa'nın üstündeki hafif degradenin rengi.
  final Color glow;
  final Color accent;
  final Color onAccent;
  final Color text;

  /// İkincil metin; arka planla en az 4.5:1 karşıtlık.
  final Color muted;

  /// Hata ve uyarı metni.
  final Color danger;

  static const dark = AppColors(
    background: Color(0xFF0E1116),
    surface: Color(0xFF181C23),
    surfaceHigh: Color(0xFF1F242D),
    outline: Color(0xFF2A303A),
    glow: Color(0xFF16323A),
    accent: Color(0xFF2EC4B6),
    onAccent: Color(0xFF0E1116),
    text: Color(0xFFE6EAF0),
    muted: Color(0xFF8A93A3),
    danger: Color(0xFFE85D75),
  );

  static const light = AppColors(
    background: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEEF1F4),
    outline: Color(0xFFDDE2E8),
    glow: Color(0xFFD7F0EC),
    accent: Color(0xFF0F7F75),
    onAccent: Color(0xFFFFFFFF),
    text: Color(0xFF151A21),
    muted: Color(0xFF5B6472),
    danger: Color(0xFFC0304A),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? outline,
    Color? glow,
    Color? accent,
    Color? onAccent,
    Color? text,
    Color? muted,
    Color? danger,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    outline: outline ?? this.outline,
    glow: glow ?? this.glow,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    danger: danger ?? this.danger,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      outline: l(outline, other.outline),
      glow: l(glow, other.glow),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      text: l(text, other.text),
      muted: l(muted, other.muted),
      danger: l(danger, other.danger),
    );
  }
}

extension AppColorsOf on BuildContext {
  /// Etkin temanın renkleri.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
      error: c.danger,
    ),
    scaffoldBackgroundColor: c.background,
    useMaterial3: true,
    extensions: [c],
  );
  return base.copyWith(
    cardTheme: CardThemeData(
      color: c.surface,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: brightness == Brightness.light
            ? BorderSide(color: c.outline)
            : BorderSide.none,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      centerTitle: false,
    ),
  );
}
