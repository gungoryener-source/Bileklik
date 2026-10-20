import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Işık, gölge ve parıltıyla 3D görünen çizimler (CustomPainter; resim
/// dosyası yok). Işık her zaman sol üstten gelir, altta nesnenin renginde
/// parıltı vardır. Arapçada yalnızca konumları aynalanır, çizimin kendisi
/// çevrilmez.

/// Ekrandaki anlamı çevreleyen metinde verilir; çizimler süslemedir.
Widget _art(Widget child) => ExcludeSemantics(child: child);

// ---------------------------------------------------------------------------
// Kalp (nabız)
// ---------------------------------------------------------------------------

class Heart3D extends StatelessWidget {
  const Heart3D({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) => _art(
    SizedBox(
      width: size,
      height: size * 0.96,
      child: const CustomPaint(painter: _HeartPainter()),
    ),
  );
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter();

  // 100 x 96 birimlik çizim alanında kalp.
  static final Path _heart = Path()
    ..moveTo(50, 84)
    ..cubicTo(22, 64, 8, 49, 8, 31)
    ..cubicTo(8, 17, 18, 8, 30, 8)
    ..cubicTo(39, 8, 46, 13, 50, 21)
    ..cubicTo(54, 13, 61, 8, 70, 8)
    ..cubicTo(82, 8, 92, 17, 92, 31)
    ..cubicTo(92, 49, 78, 64, 50, 84)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 100);

    const shadowRect = Rect.fromLTWH(22, 85, 60, 10);
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            CamArt.groundShadow,
            CamArt.groundShadow.withValues(alpha: 0),
          ],
        ).createShader(shadowRect),
    );
    canvas.drawPath(
      _heart.shift(const Offset(0, 8)),
      Paint()
        ..color = CamArt.heartGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      _heart,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: CamArt.heart,
          stops: [0, 0.35, 0.75, 1],
        ).createShader(const Rect.fromLTWH(8, 8, 84, 76)),
    );
    _softOval(canvas, const Offset(29, 24), 22, 13, -30, CamArt.highlight, 2.5);
    _softOval(canvas, const Offset(74, 56), 20, 7, -42, CamArt.heartRim, 2.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Ay (uyku)
// ---------------------------------------------------------------------------

class Moon3D extends StatelessWidget {
  const Moon3D({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) => _art(
    SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _MoonPainter()),
    ),
  );
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 64);
    const center = Offset(34, 30);
    const r = 22.0;
    canvas.drawCircle(
      center.translate(0, 6),
      r,
      Paint()
        ..color = CamArt.moonGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.36, -0.4),
          radius: 0.85,
          colors: CamArt.moon,
          stops: [0, 0.3, 0.7, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    for (final (c, cr) in const [
      (Offset(40, 25), 4.2),
      (Offset(29, 38), 3.0),
      (Offset(43, 39), 2.1),
    ]) {
      canvas.drawCircle(
        c,
        cr,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.2, -0.3),
            colors: CamArt.moonCrater,
          ).createShader(Rect.fromCircle(center: c, radius: cr)),
      );
    }
    final star = Paint()..color = CamArt.highlight;
    canvas
      ..drawCircle(const Offset(6, 10), 1.4, star)
      ..drawCircle(const Offset(10, 54), 1.0, star)
      ..drawCircle(const Offset(4, 34), 0.9, star)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Alev (kalori)
// ---------------------------------------------------------------------------

class Flame3D extends StatelessWidget {
  const Flame3D({super.key, this.width = 48});

  final double width;

  @override
  Widget build(BuildContext context) => _art(
    SizedBox(
      width: width,
      height: width * 66 / 56,
      child: const CustomPaint(painter: _FlamePainter()),
    ),
  );
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter();

  // 56 x 66 birimlik çizim alanı.
  static final Path _outer = Path()
    ..moveTo(30, 3)
    ..cubicTo(34, 16, 48, 23, 48, 40)
    ..cubicTo(48, 54, 39, 63, 28, 63)
    ..cubicTo(17, 63, 8, 54, 8, 42)
    ..cubicTo(8, 31, 15, 26, 19, 17)
    ..cubicTo(21, 25, 25, 29, 28, 29)
    ..cubicTo(28, 20, 26, 11, 30, 3)
    ..close();

  static final Path _inner = Path()
    ..moveTo(28, 34)
    ..cubicTo(31, 40, 37, 44, 37, 51)
    ..cubicTo(37, 57, 33, 61, 28, 61)
    ..cubicTo(23, 61, 19, 57, 19, 52)
    ..cubicTo(19, 46, 24, 43, 28, 34)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 56)
      ..drawPath(
        _outer.shift(const Offset(0, 5)),
        Paint()
          ..color = CamArt.flameGlow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawPath(
        _outer,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.1, 0.5),
            radius: 0.8,
            colors: CamArt.flame,
            stops: [0, 0.35, 0.7, 1],
          ).createShader(const Rect.fromLTWH(8, 3, 40, 60)),
      )
      ..drawPath(
        _inner,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, 0.4),
            radius: 0.6,
            colors: CamArt.flameCore,
          ).createShader(const Rect.fromLTWH(19, 34, 18, 27)),
      );
    _softOval(
      canvas,
      const Offset(17, 40),
      6,
      14,
      0,
      CamArt.softHighlight,
      1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// İlerleme halkası (adım, aktivite)
// ---------------------------------------------------------------------------

/// Degrade ilerleme halkası; 900 ms'de dolar (hareketi azalt açıksa anında).
class RingProgress extends StatelessWidget {
  const RingProgress({
    super.key,
    required this.progress,
    this.size = 64,
    this.colors = CamArt.ring,
    this.glow = CamArt.ringGlow,
    this.child,
  });

  /// 0 ile 1 arası; dışındaki değerler kırpılır.
  final double progress;
  final double size;
  final List<Color> colors;
  final Color glow;

  /// Halkanın ortasına konan içerik.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, inner) => CustomPaint(
          painter: _RingPainter(
            value,
            colors,
            glow,
            Directionality.of(context),
          ),
          child: inner,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress, this.colors, this.glow, this.direction);

  final double progress;
  final List<Color> colors;
  final Color glow;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    canvas
      ..save()
      ..scale(s);
    const center = Offset(32, 32);
    final rect = Rect.fromCircle(center: center, radius: 25);
    canvas.drawCircle(
      center,
      25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = CamArt.track,
    );
    // Sağdan sola dillerde halka saat yönünün tersine dolar.
    final sign = direction == TextDirection.rtl ? -1 : 1;
    final sweep = sign * 2 * math.pi * progress;
    if (progress > 0) {
      canvas
        ..drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round
            ..color = glow
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        )
        ..drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ).createShader(rect),
        );
    }
    // Üst kenar ışığı (ışık sol üstten).
    canvas
      ..drawArc(
        Rect.fromCircle(center: center, radius: 27.5),
        -math.pi * 0.85,
        math.pi * 0.45,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round
          ..color = CamArt.softHighlight,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.direction != direction ||
      old.glow != glow ||
      old.colors != colors;
}

// ---------------------------------------------------------------------------
// Küre
// ---------------------------------------------------------------------------

/// Işık alan parlak küre; içine ikon konur (hızlı işlemler, aktif süre).
class Orb extends StatelessWidget {
  const Orb({super.key, required this.palette, this.size = 48, this.icon});

  final OrbPalette palette;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => _art(
    Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: palette.colors,
          stops: const [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.glow,
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.18),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.55),
          radius: 0.5,
          colors: [
            CamArt.softHighlight,
            CamArt.softHighlight.withValues(alpha: 0),
          ],
        ),
      ),
      child: icon == null
          ? null
          : Icon(icon, size: size * 0.46, color: context.colors.text),
    ),
  );
}

// ---------------------------------------------------------------------------
// Parlayan ilerleme çubuğu
// ---------------------------------------------------------------------------

/// Baştan sona dolan parlak çubuk; 900 ms easeOutCubic.
class GlowProgressBar extends StatelessWidget {
  const GlowProgressBar({
    super.key,
    required this.progress,
    required this.palette,
    this.height = 12,
  });

  final double progress;
  final OrbPalette palette;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final radius = BorderRadius.circular(height / 2);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: CamArt.track, borderRadius: radius),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: palette.colors.sublist(0, 2),
                ),
                boxShadow: value > 0
                    ? [BoxShadow(color: palette.glow, blurRadius: 12)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

void _softOval(
  Canvas canvas,
  Offset center,
  double width,
  double height,
  double degrees,
  Color color,
  double blur,
) {
  canvas
    ..save()
    ..translate(center.dx, center.dy)
    ..rotate(degrees * math.pi / 180)
    ..drawOval(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    )
    ..restore();
}
