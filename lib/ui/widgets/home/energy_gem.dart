import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Kodla çizilen zümrüt kristal: altıgen dış hat, ortada düz "masa" yüzü
/// ve ışığın sol üstten geldiği 12 yüzey. İçinde [child] (enerji skoru).
class EnergyGem extends StatelessWidget {
  const EnergyGem({super.key, required this.child, this.size = 220});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.1,
    child: CustomPaint(
      painter: const _GemPainter(),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.2),
          child: child,
        ),
      ),
    ),
  );
}

class _GemPainter extends CustomPainter {
  const _GemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width / 2, size.height / 2) * 0.98;
    final inner = r * 0.6;
    Offset at(double deg, double radius) {
      final a = deg * pi / 180;
      return c + Offset(cos(a) * radius, sin(a) * radius);
    }

    // Dış köşeler sivri tepeli (-90°), iç köşeler aralarında (-60°).
    final outer = [for (var i = 0; i < 6; i++) at(-90.0 + 60 * i, r)];
    final table = [for (var i = 0; i < 6; i++) at(-60.0 + 60 * i, inner)];

    // Dış parıltı.
    canvas.drawCircle(
      c,
      r * 0.95,
      Paint()
        ..color = HomeSky.gemGlow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Işık sol üstten (-135°): yüzeyin yönü ışığa yakınsa açık.
    const light = -135 * pi / 180;
    Color shade(Offset centroid, double bias) {
      final d = centroid - c;
      final k = (cos(atan2(d.dy, d.dx) - light) + 1) / 2;
      final t = (k * 0.85 + bias).clamp(0.0, 1.0);
      return t > 0.5
          ? Color.lerp(HomeSky.gem, HomeSky.gemLight, (t - 0.5) * 2)!
          : Color.lerp(HomeSky.gemDark, HomeSky.gem, t * 2)!;
    }

    void facet(List<Offset> pts, double bias) {
      final path = Path()..addPolygon(pts, true);
      final centroid = pts.reduce((a, b) => a + b) / pts.length.toDouble();
      canvas.drawPath(path, Paint()..color = shade(centroid, bias));
    }

    for (var i = 0; i < 6; i++) {
      final o = outer[i];
      final o2 = outer[(i + 1) % 6];
      final prev = table[(i + 5) % 6];
      final cur = table[i];
      facet([prev, o, cur], 0.05); // yıldız ucu
      facet([o, o2, cur], -0.12); // kenar yüzü
    }
    // Masa: ortası aydınlık.
    final tablePath = Path()..addPolygon(table, true);
    canvas.drawPath(
      tablePath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            HomeSky.gemLight.withValues(alpha: 0.9),
            HomeSky.gem,
            HomeSky.gemDark,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: inner)),
    );
    // Masanın üstünde yazının okunması için hafif koyuluk.
    canvas.drawPath(
      tablePath,
      Paint()..color = HomeSky.gemDark.withValues(alpha: 0.35),
    );

    // Kenar çizgileri.
    final edge = Paint()
      ..color = HomeSky.gemLight.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas
      ..drawPath(Path()..addPolygon(outer, true), edge)
      ..drawPath(tablePath, edge);
    for (var i = 0; i < 6; i++) {
      canvas
        ..drawLine(outer[i], table[i], edge)
        ..drawLine(outer[i], table[(i + 5) % 6], edge);
    }

    // Sol üstte iki parlama.
    final spark = Paint()
      ..color = HomeSky.snow.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final s1 = Offset.lerp(outer[5], table[5], 0.35)!;
    canvas.drawLine(s1, s1 + Offset(r * 0.12, -r * 0.08), spark);
    final s2 = Offset.lerp(outer[0], table[4], 0.5)!;
    canvas.drawCircle(
      s2,
      3,
      Paint()
        ..color = HomeSky.snow.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_GemPainter old) => false;
}
