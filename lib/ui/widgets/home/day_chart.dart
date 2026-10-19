import 'package:flutter/material.dart';

import '../../theme.dart';

/// 24 saatlik küçük çizgi grafiği; ölçüm olmayan saatlerde çizgi kesilir.
class DayLineChart extends StatelessWidget {
  const DayLineChart({
    super.key,
    required this.values,
    required this.color,
    required this.semanticLabel,
  });

  final List<double?> values;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LinePainter(values, color, context.colors.outline),
            ),
          ),
          const SizedBox(height: 8),
          const _HourLabels(),
        ],
      ),
    );
  }
}

/// 24 saatlik sütunlar (ör. stres); renk değere göre seçilir.
class DayBars extends StatelessWidget {
  const DayBars({
    super.key,
    required this.values,
    required this.max,
    required this.colorOf,
    required this.semanticLabel,
  });

  final List<double?> values;
  final double max;
  final Color Function(double) colorOf;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: 72,
        // Saat ekseni her dilde soldan sağa; çizgi grafiğiyle aynı yönde.
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final v in values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: FractionallySizedBox(
                    // Ölçüm olmayan saat kısa ve soluk bir çentik olarak kalır.
                    heightFactor: v == null
                        ? 0.08
                        : (v / max).clamp(0.12, 1.0).toDouble(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: v == null
                            ? context.colors.surfaceHigh
                            : colorOf(v),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HourLabels extends StatelessWidget {
  const _HourLabels();

  static const _labels = ['00:00', '06:00', '12:00', '18:00', '24:00'];
  static const _align = [
    Alignment.centerLeft,
    Alignment.center,
    Alignment.center,
    Alignment.center,
    Alignment.centerRight,
  ];

  @override
  Widget build(BuildContext context) {
    // Dar ekranda ve büyük yazıda etiketler taşmak yerine küçülür.
    // Saat ekseni RTL dillerde de soldan sağa kalır; çizimle örtüşsün.
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        for (var i = 0; i < _labels.length; i++)
          Expanded(
            child: Align(
              alignment: _align[i],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _labels[i],
                  style: TextStyle(color: context.colors.muted, fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color, this.tickColor);

  final Color tickColor;

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final step = size.width / n;
    final mid = size.height / 2;

    // Saat çentikleri: veri olmasa da grafiğin yeri belli olsun.
    final tick = Paint()
      ..color = tickColor
      ..strokeWidth = 1.5;
    for (var i = 0; i <= n; i++) {
      final x = i * step;
      final h = i % 6 == 0 ? 8.0 : 4.0;
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), tick);
    }

    final present = values.whereType<double>().toList();
    if (present.isEmpty) return;
    var lo = present.reduce((a, b) => a < b ? a : b);
    var hi = present.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 4) {
      lo -= 2;
      hi += 2;
    }
    double y(double v) =>
        size.height - 6 - (v - lo) / (hi - lo) * (size.height - 12);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;
    Path? path;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) {
        if (path != null) canvas.drawPath(path, line);
        path = null;
        continue;
      }
      final p = Offset(i * step + step / 2, y(v));
      if (path == null) {
        path = Path()..moveTo(p.dx, p.dy);
        canvas.drawCircle(p, 2.5, dot);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    if (path != null) canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color || old.tickColor != tickColor;
}
