import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../cam/pressable.dart';

/// Ana Sayfa zemini: yukarıda lacivert, ortada mavi, aşağıda koyu gece.
class HomeSkyBackground extends StatelessWidget {
  const HomeSkyBackground({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HomeSky.top, HomeSky.mid, HomeSky.bottom],
          stops: [0, 0.42, 0.78],
        ),
      ),
      child: SizedBox.expand(),
    ),
  );
}

/// Kodla çizilen karlı dağ silueti: uzak sıra, gün batımı ışığı alan
/// karlı ana tepe ve öndeki koyu sırt; alt kenar zemine karışır.
class MountainSilhouette extends StatelessWidget {
  const MountainSilhouette({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      // Alt kenar saydamlaşır; arkadaki gökyüzü degradesiyle sert çizgi olmaz.
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.5, 1],
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        ).createShader(r),
        child: const CustomPaint(
          painter: _MountainPainter(),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    // Ufuk ışığı.
    final glowRect = Rect.fromCircle(center: p(0.2, 0.62), radius: w * 0.7);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            HomeSky.sunGlow.withValues(alpha: 0.35),
            HomeSky.sunGlow.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    Path ridge(List<Offset> pts) {
      final path = Path()..moveTo(0, h);
      for (final o in pts) {
        path.lineTo(o.dx, o.dy);
      }
      return path
        ..lineTo(w, h)
        ..close();
    }

    // Uzak sıra.
    canvas.drawPath(
      ridge([
        p(0, 0.58),
        p(0.12, 0.5),
        p(0.22, 0.56),
        p(0.33, 0.47),
        p(0.7, 0.5),
        p(0.82, 0.44),
        p(0.92, 0.52),
        p(1, 0.48),
      ]),
      Paint()..color = HomeSky.ridgeFar.withValues(alpha: 0.7),
    );

    // Ana tepe: güneş alan yüz sıcak, gölge yüz koyu.
    final peak = p(0.5, 0.06);
    final main = ridge([
      p(0, 0.72),
      p(0.18, 0.6),
      p(0.3, 0.42),
      p(0.4, 0.26),
      peak,
      p(0.58, 0.2),
      p(0.66, 0.33),
      p(0.78, 0.45),
      p(0.9, 0.58),
      p(1, 0.64),
    ]);
    final body = Rect.fromLTWH(0, peak.dy, w, h - peak.dy);
    canvas.drawPath(
      main,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeSky.rockLight, HomeSky.ridgeMid, HomeSky.ridgeNear],
          stops: const [0.1, 0.45, 0.9],
        ).createShader(body),
    );
    // Gölge yüz: tepeden sağ alta.
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(p(0.58, 0.2).dx, p(0.58, 0.2).dy)
        ..lineTo(p(0.66, 0.33).dx, p(0.66, 0.33).dy)
        ..lineTo(p(0.78, 0.45).dx, p(0.78, 0.45).dy)
        ..lineTo(p(0.62, 0.7).dx, p(0.62, 0.7).dy)
        ..lineTo(p(0.52, 0.4).dx, p(0.52, 0.4).dy)
        ..close(),
      Paint()..color = HomeSky.ridgeNear.withValues(alpha: 0.45),
    );
    // Kar örtüsü: tepeden aşağı dişli alt kenar.
    final rnd = Random(7);
    final snow = Path()..moveTo(peak.dx, peak.dy);
    final left = [p(0.4, 0.26), p(0.3, 0.42)];
    final right = [p(0.58, 0.2), p(0.66, 0.33)];
    snow
      ..lineTo(right[0].dx, right[0].dy)
      ..lineTo(right[1].dx, right[1].dy);
    const teeth = 9;
    for (var i = 1; i <= teeth; i++) {
      final t = i / teeth;
      final x = right[1].dx + (left[1].dx - right[1].dx) * t;
      final baseY = right[1].dy + (left[1].dy - right[1].dy) * t;
      final dip = (i.isOdd ? 0.07 : 0.0) + rnd.nextDouble() * 0.04;
      snow.lineTo(x, baseY + dip * h - 0.05 * h);
    }
    snow
      ..lineTo(left[0].dx, left[0].dy)
      ..close();
    canvas.drawPath(
      snow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeSky.snow, HomeSky.snow.withValues(alpha: 0.55)],
        ).createShader(body),
    );

    // Öndeki koyu sırt ve zemine karışan alt kenar.
    canvas.drawPath(
      ridge([
        p(0, 0.8),
        p(0.15, 0.72),
        p(0.3, 0.78),
        p(0.5, 0.7),
        p(0.7, 0.8),
        p(0.86, 0.74),
        p(1, 0.8),
      ]),
      Paint()..color = HomeSky.ridgeNear.withValues(alpha: 0.9),
    );
    final fade = Rect.fromLTWH(0, h * 0.42, w, h * 0.4);
    canvas.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HomeSky.bottom.withValues(alpha: 0),
            HomeSky.bottom.withValues(alpha: 0.7),
          ],
        ).createShader(fade),
    );
  }

  @override
  bool shouldRepaint(_MountainPainter old) => false;
}

/// Alt menünün yanındaki yuvarlak AI düğmesi: koyu cam, yeşil-mavi kenar.
class AiNavButton extends StatelessWidget {
  const AiNavButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomeSky.ai, HomeSky.aiBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: HomeSky.ai.withValues(alpha: 0.45),
              blurRadius: 18,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: HomeSky.inner,
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (r) =>
                    const LinearGradient(colors: [HomeSky.ai, HomeSky.aiBlue])
                        .createShader(r),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 30,
                  color: HomeSky.snow,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
