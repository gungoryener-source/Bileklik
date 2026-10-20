import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Veri renkleri: ölçüm türlerini ayırt eder. Koyu Cam zeminde parlak
/// kalacak tonlar seçildi; metin olarak değil, ikon, çizgi ve sütunlarda
/// kullanılır.
abstract final class DataColors {
  static const heart = Color(0xFFFF5C84);
  static const hrv = Color(0xFF2EE6C9);
  static const oxygen = Color(0xFF4FC3FF);
  static const temperature = Color(0xFFFFAA5C);
  static const steps = Color(0xFF9BE15D);
  static const stress = Color(0xFFC59BFF);
  static const respiration = Color(0xFF6FE3F5);
  static const pressure = Color(0xFFFF9DB4);
  static const sleepDeep = Color(0xFF5C6CFF);
  static const sleepLight = Color(0xFF8FA6FF);
  static const sleepRem = Color(0xFFD08CFF);
}

/// "Cam" tasarım dilinin renkleri. Uygulama yalnızca koyu temada çalışır.
/// Ekranlar `context.colors` ile alır, sabit renk yazılmaz.
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
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.auroraPink,
    required this.auroraViolet,
    required this.auroraCyan,
    required this.auroraLime,
    required this.scrim,
    required this.glassBase,
    required this.glassSheenStart,
    required this.glassSheenEnd,
    required this.glassBorder,
    required this.floating,
    required this.heroTintStart,
    required this.heroTintEnd,
    required this.sleepTintStart,
    required this.sleepTintEnd,
    required this.ctaStart,
    required this.ctaEnd,
    required this.ctaGlow,
    required this.navBase,
    required this.navActiveStart,
    required this.navActiveEnd,
    required this.navActiveGlow,
    required this.online,
    required this.offline,
    required this.grid,
    required this.shadow,
  });

  /// Düz zemin rengi (degradenin ortası); degrade çizilemeyen yerlerde.
  final Color background;

  /// Kart içi dolgu (yarı saydam).
  final Color surface;

  /// Kart içindeki gömük alanlar (ör. alt istatistik satırı).
  final Color surfaceHigh;

  /// Cam kenar çizgisi.
  final Color outline;

  /// İkon arka planı gibi hafif vurgu dolgusu.
  final Color glow;

  /// Anahtar, onay kutusu, bağlantı ve ilerleme rengi.
  final Color accent;
  final Color onAccent;
  final Color text;

  /// İkincil metin; en parlak aurora üstünde bile en az 4.5:1 karşıtlık.
  final Color muted;

  /// Hata ve uyarı metni.
  final Color danger;

  // Zemin degradesi (yukarıdan aşağı).
  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;

  // Aurora ışıkları (merkezdeki opaklıkla).
  final Color auroraPink;
  final Color auroraViolet;
  final Color auroraCyan;
  final Color auroraLime;

  /// Auroranın üstüne serilen koyu perde; metin karşıtlığını korur.
  final Color scrim;

  // Cam kart.
  final Color glassBase;
  final Color glassSheenStart;
  final Color glassSheenEnd;
  final Color glassBorder;

  /// Yüzen yüzeylerin (alt sayfa, diyalog, bildirim) bulanıklık üstü tabanı.
  final Color floating;

  // Kart tonları.
  final Color heroTintStart;
  final Color heroTintEnd;
  final Color sleepTintStart;
  final Color sleepTintEnd;

  // Ana buton.
  final Color ctaStart;
  final Color ctaEnd;
  final Color ctaGlow;

  // Alt menü.
  final Color navBase;
  final Color navActiveStart;
  final Color navActiveEnd;
  final Color navActiveGlow;

  /// Bileklik bağlı noktası ve parıltısı.
  final Color online;
  final Color offline;

  /// Grafik ızgarası.
  final Color grid;

  /// Yüzen yüzeylerin altındaki gölge.
  final Color shadow;

  static const cam = AppColors(
    background: Color(0xFF0B0A22),
    surface: Color(0x66141030),
    surfaceHigh: Color(0x14FFFFFF),
    outline: Color(0x2EFFFFFF),
    glow: Color(0x338F7BFF),
    accent: Color(0xFFA996FF),
    onAccent: Color(0xFF0B0A22),
    text: Color(0xFFFFFFFF),
    muted: Color(0xBFFFFFFF),
    danger: Color(0xFFFFB8C8),
    bgTop: Color(0xFF140D38),
    bgMid: Color(0xFF0B0A22),
    bgBottom: Color(0xFF08142E),
    auroraPink: Color(0xF2FF2E88),
    auroraViolet: Color(0xFF6C4BFF),
    auroraCyan: Color(0xBF00C8FF),
    auroraLime: Color(0x739DFF3D),
    scrim: Color(0x730B0A22),
    glassBase: Color(0x66141030),
    glassSheenStart: Color(0x29FFFFFF),
    glassSheenEnd: Color(0x0AFFFFFF),
    glassBorder: Color(0x2EFFFFFF),
    floating: Color(0xB8161234),
    heroTintStart: Color(0x61FF408C),
    heroTintEnd: Color(0x297828C8),
    sleepTintStart: Color(0x6B7C5CFF),
    sleepTintEnd: Color(0x2E281E78),
    ctaStart: Color(0xFFD9225F),
    ctaEnd: Color(0xFF6A3DF0),
    ctaGlow: Color(0x80D9225F),
    navBase: Color(0x8C161234),
    navActiveStart: Color(0xFF7B5CFF),
    navActiveEnd: Color(0xFFD9225F),
    navActiveGlow: Color(0x8C9646FF),
    online: Color(0xFF9DFF3D),
    offline: Color(0x80FFFFFF),
    grid: Color(0x14FFFFFF),
    shadow: Color(0x73000000),
  );

  // Tek tema olduğu için kopyalama ve geçiş kendisini döndürür.
  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => this;
}

extension AppColorsOf on BuildContext {
  /// Cam temasının renkleri.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Yazı tipi: Manrope (OFL, assets/fonts). Arapça harfleri yok; Arapça
/// metin sistem fontuna düşer.
const appFontFamily = 'Manrope';
const appFontFallback = [
  'Noto Sans Arabic',
  'Roboto',
  '.SF Arabic',
  'Geeza Pro',
  'sans-serif',
];

/// Sistem çubukları: saydam, açık ikonlu (edge-to-edge).
const camSystemOverlay = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  systemNavigationBarColor: Color(0x00000000),
  systemNavigationBarDividerColor: Color(0x00000000),
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

/// Uygulamanın tek teması: koyu Cam.
ThemeData buildTheme() {
  const c = AppColors.cam;
  final shape16 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: appFontFamily,
    fontFamilyFallback: appFontFallback,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: Brightness.dark,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      surface: c.bgMid,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      outline: c.glassBorder,
      outlineVariant: c.grid,
      error: c.danger,
      surfaceTint: const Color(0x00000000),
    ),
    // Her rota zeminini CamScaffold ile kendisi çizer.
    scaffoldBackgroundColor: const Color(0x00000000),
    canvasColor: c.bgMid,
    splashFactory: InkSparkle.splashFactory,
    extensions: const [c],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    cardTheme: CardThemeData(
      color: c.glassBase,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: c.glassBorder),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0x00000000),
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: const Color(0x00000000),
      centerTitle: false,
      systemOverlayStyle: camSystemOverlay,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: c.text,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.floating,
      surfaceTintColor: const Color(0x00000000),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: c.glassBorder),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0x00000000),
      surfaceTintColor: Color(0x00000000),
      modalBackgroundColor: Color(0x00000000),
      elevation: 0,
      modalElevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.bgTop,
      contentTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        color: c.text,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: c.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: c.glassBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        backgroundColor: c.surfaceHigh,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: c.glassBorder),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontFamilyFallback: appFontFallback,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(48, 48),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: c.text,
        minimumSize: const Size(48, 48),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.muted,
      textColor: c.text,
      subtitleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        color: c.muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.text : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? c.navActiveStart : c.surfaceHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const Color(0x00000000)
            : c.glassBorder,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? c.accent
            : const Color(0x00000000),
      ),
      checkColor: WidgetStatePropertyAll(c.onAccent),
      side: BorderSide(color: c.muted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.muted,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceHigh,
      circularTrackColor: const Color(0x00000000),
    ),
    dividerTheme: DividerThemeData(color: c.grid, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: c.glassBase,
      side: BorderSide(color: c.glassBorder),
      labelStyle: TextStyle(
        fontFamily: appFontFamily,
        fontFamilyFallback: appFontFallback,
        color: c.text,
        fontWeight: FontWeight.w700,
      ),
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceHigh,
      labelStyle: TextStyle(color: c.muted),
      hintStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: c.text,
        selectedForegroundColor: c.text,
        selectedBackgroundColor: c.glow,
        side: BorderSide(color: c.glassBorder),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.bgTop,
      surfaceTintColor: const Color(0x00000000),
      shape: shape16,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.bgTop,
      surfaceTintColor: const Color(0x00000000),
      headerForegroundColor: c.text,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: c.glassBorder),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.bgTop,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.glassBorder),
      ),
      textStyle: TextStyle(color: c.text, fontSize: 12),
    ),
  );
}

/// 3D çizimlerin ve kürelerin ışık-gölge tonları. Işık hep sol üstten
/// gelir: her liste açık, ana, koyu (ve en koyu) sırasıyla.
abstract final class CamArt {
  static const heart = [
    Color(0xFFFFC9DF),
    Color(0xFFFF4F93),
    Color(0xFFD4145E),
    Color(0xFF8A0A44),
  ];
  static const heartGlow = Color(0x80FF2E88);
  static const heartRim = Color(0x66FFA6CC);

  static const moon = [
    Color(0xFFFFFFFF),
    Color(0xFFDCD4FF),
    Color(0xFF8C78FF),
    Color(0xFF3E2DB3),
  ];
  static const moonGlow = Color(0x997C5CFF);
  static const moonCrater = [Color(0x8C6E5AE8), Color(0x1AB9ADFF)];

  static const flame = [
    Color(0xFFFFF3A6),
    Color(0xFFFFC23D),
    Color(0xFFFF6A3D),
    Color(0xFFE5245A),
  ];
  static const flameCore = [Color(0xE6FFFFFF), Color(0xE6FFE27A)];
  static const flameGlow = Color(0x99FF783C);

  static const ring = [Color(0xFFC6FF4D), Color(0xFF00C8FF)];
  static const ringGlow = Color(0x8000C8FF);

  /// Işık lekesi ve yere düşen gölge.
  static const highlight = Color(0x99FFFFFF);
  static const softHighlight = Color(0x59FFFFFF);
  static const groundShadow = Color(0x73000000);
  static const track = Color(0x1FFFFFFF);

  // Küre (Orb) paletleri.
  static const orbPink = OrbPalette([
    Color(0xFFFF8AB8),
    Color(0xFFFF5C9D),
    Color(0xFFC4124F),
  ], Color(0x80FF2E88));
  static const orbLime = OrbPalette([
    Color(0xFFC8FF8A),
    Color(0xFF8CF04A),
    Color(0xFF16A05E),
  ], Color(0x736EE646));
  static const orbCyan = OrbPalette([
    Color(0xFF9BEAFF),
    Color(0xFF4FDDFF),
    Color(0xFF4B4FF0),
  ], Color(0x7300C8FF));
  static const orbViolet = OrbPalette([
    Color(0xFFD9CCFF),
    Color(0xFF9B7BFF),
    Color(0xFF5A35D8),
  ], Color(0x739646FF));
  static const orbAmber = OrbPalette([
    Color(0xFFFFE3A6),
    Color(0xFFFFB13D),
    Color(0xFFE5622A),
  ], Color(0x73FF9A3C));
}

/// Kürenin açık, ana, koyu tonu ve parıltısı.
@immutable
class OrbPalette {
  const OrbPalette(this.colors, this.glow);
  final List<Color> colors;
  final Color glow;
}
