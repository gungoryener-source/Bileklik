import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Işık, gölge ve parlama ile 3D görünen çizimler.
/// Hepsi CustomPainter ile çizilir; resim dosyası gerekmez.

// ---------------------------------------------------------------------------
// Kalp (nabız)
// ---------------------------------------------------------------------------

class Heart3D extends StatelessWidget {
  const Heart3D({super.key, this.size = 132});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.96,
      child: const CustomPaint(painter: _HeartPainter()),
    );
  }
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
    canvas.save();
    canvas.scale(size.width / 100);

    // Yere düşen gölge
    final shadowRect = Rect.fromCenter(center: const Offset(52, 90), width: 60, height: 10);
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x73000000), Color(0x00000000)],
        ).createShader(shadowRect),
    );

    // Renkli parıltı
    canvas.drawPath(
      _heart.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x80FF2E88)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Gövde: sol üstten ışık alan küre degradesi
    canvas.drawPath(
      _heart,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFFFFC9DF), Color(0xFFFF4F93), Color(0xFFD4145E), Color(0xFF8A0A44)],
          stops: [0, 0.35, 0.75, 1],
        ).createShader(const Rect.fromLTWH(8, 8, 84, 76)),
    );

    // Parlama ve kenar ışığı
    _softOval(canvas, const Offset(29, 24), 22, 13, -30, const Color(0x99FFFFFF), 2.5);
    _softOval(canvas, const Offset(74, 56), 20, 7, -42, const Color(0x66FFA6CC), 2.5);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Ay (uyku)
// ---------------------------------------------------------------------------

class Moon3D extends StatelessWidget {
  const Moon3D({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _MoonPainter()),
    );
  }
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64);

    const center = Offset(34, 32);
    const r = 22.0;

    canvas.drawCircle(
      center.translate(0, 6),
      r,
      Paint()
        ..color = const Color(0x997C5CFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.36, -0.4),
          radius: 0.85,
          colors: [Color(0xFFFFFFFF), Color(0xFFDCD4FF), Color(0xFF8C78FF), Color(0xFF3E2DB3)],
          stops: [0, 0.3, 0.7, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    for (final (c, cr) in const [
      (Offset(40, 27), 4.2),
      (Offset(29, 40), 3.0),
      (Offset(43, 41), 2.1),
    ]) {
      canvas.drawCircle(
        c,
        cr,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.2, -0.3),
            colors: [Color(0x8C6E5AE8), Color(0x1AB9ADFF)],
          ).createShader(Rect.fromCircle(center: c, radius: cr)),
      );
    }

    final star = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(const Offset(6, 10), 1.4, star);
    canvas.drawCircle(const Offset(12, 54), 1.0, star..color = const Color(0xCCFFFFFF));
    canvas.drawCircle(const Offset(4, 34), 0.9, star..color = const Color(0xB3FFFFFF));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Alev (kalori)
// ---------------------------------------------------------------------------

class Flame3D extends StatelessWidget {
  const Flame3D({super.key, this.width = 54});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 66 / 56,
      child: const CustomPaint(painter: _FlamePainter()),
    );
  }
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
    canvas.save();
    canvas.scale(size.width / 56);

    canvas.drawPath(
      _outer.shift(const Offset(0, 6)),
      Paint()
        ..color = const Color(0x99FF783C)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(
      _outer,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.1, 0.5),
          radius: 0.8,
          colors: [Color(0xFFFFF3A6), Color(0xFFFFC23D), Color(0xFFFF6A3D), Color(0xFFE5245A)],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(const Rect.fromLTWH(8, 3, 40, 60)),
    );

    canvas.drawPath(
      _inner,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.4),
          radius: 0.6,
          colors: [Color(0xE6FFFFFF), Color(0xE6FFE27A)],
        ).createShader(const Rect.fromLTWH(19, 34, 18, 27)),
    );

    _softOval(canvas, const Offset(17, 40), 6, 14, 0, const Color(0x59FFFFFF), 1.5);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// İlerleme halkası (adım)
// ---------------------------------------------------------------------------

class RingProgress extends StatelessWidget {
  const RingProgress({super.key, required this.progress, this.size = 64});

  /// 0 ile 1 arası.
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) =>
            CustomPaint(painter: _RingPainter(value)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64);

    const center = Offset(32, 32);
    final rect = Rect.fromCircle(center: center, radius: 25);

    canvas.drawCircle(
      center,
      25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = const Color(0x1FFFFFFF),
    );

    final sweep = 2 * math.pi * math.min(math.max(progress, 0.0), 1.0);
    if (sweep > 0) {
      // Parıltı
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x8000C8FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Halka
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFC6FF4D), Color(0xFF00C8FF)],
          ).createShader(rect),
      );
    }

    // Üst kenar ışığı
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 27.5),
      -math.pi * 0.85,
      math.pi * 0.45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x59FFFFFF),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Küre (hızlı işlem ikonları, aktif süre)
// ---------------------------------------------------------------------------

/// Işık alan parlak küre; içine ikon konur.
class Orb extends StatelessWidget {
  const Orb({
    super.key,
    required this.size,
    required this.colors,
    required this.glow,
    this.child,
  });

  final double size;

  /// Açık, ana ve koyu ton (3 renk).
  final List<Color> colors;
  final Color glow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: colors,
          stops: const [0, 0.45, 1],
        ),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: size * 0.4, offset: Offset(0, size * 0.18)),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Parlayan ilerleme çubuğu
// ---------------------------------------------------------------------------

class GlowProgressBar extends StatelessWidget {
  const GlowProgressBar({
    super.key,
    required this.progress,
    required this.colors,
    required this.glow,
  });

  final double progress;
  final List<Color> colors;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final radius = BorderRadius.circular(7);
    return SizedBox(
      width: double.infinity,
      height: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: radius),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: math.min(math.max(value, 0.0), 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(colors: colors),
                boxShadow: value > 0 ? [BoxShadow(color: glow, blurRadius: 12)] : null,
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
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(degrees * math.pi / 180);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: width, height: height),
    Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
  );
  canvas.restore();
}
