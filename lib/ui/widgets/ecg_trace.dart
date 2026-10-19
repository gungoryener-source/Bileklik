import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// EKG çizgisi, EKG kâğıdı gibi kareli zemin üzerinde.
///
/// Küçük kare 0,04 sn, büyük kare 0,2 sn. Ham değerlerin mV karşılığı
/// bilinmediğinden dikey ölçek kayıttaki en büyük sapmaya göre ayarlanır.
class EcgTrace extends StatelessWidget {
  const EcgTrace({
    super.key,
    required this.samples,
    required this.sampleRate,
    this.seconds = 5,
    this.height = 160,
    this.peaks = const [],
    this.offset = 0,
  });

  final List<int> samples;
  final int sampleRate;

  /// Ekrana sığdırılacak süre.
  final double seconds;
  final double height;

  /// İşaretlenecek R dalgaları (örnek sırası).
  final List<int> peaks;

  /// Çizime başlanacak örnek.
  final int offset;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: _EcgPainter(
        samples,
        sampleRate,
        seconds,
        peaks,
        offset,
        context.colors.text,
      ),
    ),
  );
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(
    this.samples,
    this.sampleRate,
    this.seconds,
    this.peaks,
    this.offset,
    this.lineColor,
  );

  /// Sinyal çizgisi; temaya göre açık ya da koyu.
  final Color lineColor;

  final List<int> samples;
  final int sampleRate;
  final double seconds;
  final List<int> peaks;
  final int offset;

  static const _grid = Color(0x33E85D75);
  static const _gridBold = Color(0x66E85D75);

  @override
  void paint(Canvas canvas, Size size) {
    final pxPerSec = size.width / seconds;
    final small = Paint()
      ..color = _grid
      ..strokeWidth = 0.5;
    final big = Paint()
      ..color = _gridBold
      ..strokeWidth = 1;
    final step = pxPerSec * 0.04;
    for (var i = 0; i * step <= size.width; i++) {
      canvas.drawLine(
        Offset(i * step, 0),
        Offset(i * step, size.height),
        i % 5 == 0 ? big : small,
      );
    }
    for (var i = 0; i * step <= size.height; i++) {
      canvas.drawLine(
        Offset(0, i * step),
        Offset(size.width, i * step),
        i % 5 == 0 ? big : small,
      );
    }

    final count = min((seconds * sampleRate).round(), samples.length - offset);
    if (count < 2) return;
    final window = samples.sublist(offset, offset + count);
    final sorted = [...window]..sort();
    final baseline = sorted[sorted.length ~/ 2];
    final spread = max(
      1,
      window.map((v) => (v - baseline).abs()).reduce(max),
    ).toDouble();
    final mid = size.height * 0.6;
    final scale = size.height * 0.5 / spread;

    final path = Path();
    for (var i = 0; i < count; i++) {
      final x = i / sampleRate * pxPerSec;
      final y = mid - (window[i] - baseline) * scale;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = DataColors.heart;
    for (final p in peaks) {
      final i = p - offset;
      if (i < 0 || i >= count) continue;
      canvas.drawCircle(
        Offset(
          i / sampleRate * pxPerSec,
          mid - (window[i] - baseline) * scale - 8,
        ),
        2.5,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) =>
      old.lineColor != lineColor ||
      old.samples.length != samples.length ||
      old.offset != offset ||
      !identical(old.samples, samples);
}
