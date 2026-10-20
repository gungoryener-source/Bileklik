import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Günlük adım hedefine ilerlemeyi gösteren yarım halka.
/// İlk açılışta bir kez dolar; animasyonlar kapalıysa doğrudan çizilir.
class ActivityGauge extends StatelessWidget {
  const ActivityGauge({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
  });

  /// 0-1 arası; 1'i geçen değer tam halka çizilir.
  final double progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0);
    final still = MediaQuery.of(context).disableAnimations;
    return AspectRatio(
      aspectRatio: 1.8,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? target : 0, end: target),
        duration: still ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, p, _) => CustomPaint(
          painter: _GaugePainter(
            p,
            color,
            context.colors,
            Directionality.of(context),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.progress, this.color, this.palette, this.direction);

  /// RTL dillerde yay sağdan sola dolar.
  final TextDirection direction;

  final AppColors palette;

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (direction == TextDirection.rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final r = min(size.width / 2, size.height) - 8;
    final c = Offset(size.width / 2, size.height - 4);
    const stroke = 10.0;

    // Arka plan ve ilerleme yayı.
    final rect = Rect.fromCircle(center: c, radius: r);
    final track = Paint()
      ..color = palette.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        pi,
        pi * progress,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      final fill = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, pi, pi * progress, false, fill);
    }

    // İçteki ölçek çizgileri: dolu kısım renkli, kalan soluk.
    const ticks = 40;
    final inner = r - stroke - 6;
    for (var i = 0; i <= ticks; i++) {
      final a = pi + pi * i / ticks;
      final on = i / ticks <= progress && progress > 0;
      final p = Paint()
        ..color = on ? color.withValues(alpha: 0.7) : palette.outline
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(c + dir * inner, c + dir * (inner - 10), p);
    }

    // Yayın ucundaki nokta: zemin renginde, yay renginde kenarlı.
    final a = pi + pi * progress;
    final end = c + Offset(cos(a), sin(a)) * r;
    canvas.drawCircle(end, stroke / 2 + 2, Paint()..color = color);
    canvas.drawCircle(end, stroke / 2 - 1, Paint()..color = palette.bgMid);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.palette != palette ||
      old.direction != direction;
}
