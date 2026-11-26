import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../l10n/l10n.dart';
import '../format.dart';
import '../theme.dart';
import 'cam/cam.dart';

// ---------------------------------------------------------------------------
// Toparlanma ve günlük yük ekranlarının ortak parçaları: düzey bantlı halka,
// renk açıklaması, değerlendirme kartı, gösterge satırı ve haftalık/aylık
// eğilim grafiği.
// ---------------------------------------------------------------------------

/// Ölçekte bir düzey: [floor] ile [ceiling] arası, rengi ve adı.
class ScoreBand {
  const ScoreBand(this.floor, this.ceiling, this.color, this.label);

  final double floor;
  final double ceiling;
  final Color color;
  final String label;
}

/// Büyük skor halkası: iz, değer yayı ve dış kenarda kesikli ideal aralık.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.title,
    required this.value,
    required this.levelLabel,
    required this.color,
    required this.fraction,
    required this.semantics,
    this.optimal,
  });

  final String title;
  final String value;
  final String levelLabel;
  final Color color;

  /// Doluluk 0–1.
  final double fraction;
  final String semantics;

  /// Kesikli ideal aralık (0–1 payları); null ise çizilmez.
  final (double, double)? optimal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Center(
        child: SizedBox.square(
          dimension: 260,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: fraction,
              color: color,
              track: colors.grid,
              optimalColor: colors.muted,
              optimal: optimal,
            ),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 60,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      levelLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
    required this.optimalColor,
    required this.optimal,
  });

  final double fraction;
  final Color color;
  final Color track;
  final Color optimalColor;
  final (double, double)? optimal;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 22;
    const stroke = 18.0;
    const top = -pi / 2;
    final rect = Rect.fromCircle(center: c, radius: radius);
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (optimal case (final lo, final hi)) {
      final outer = Rect.fromCircle(center: c, radius: radius + stroke / 2 + 8);
      final dash = Paint()
        ..color = optimalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final from = top + 2 * pi * lo;
      final sweep = 2 * pi * (hi - lo);
      const step = 0.06;
      for (var a = from; a < from + sweep; a += step * 2) {
        canvas.drawArc(outer, a, min(step, from + sweep - a), false, dash);
      }
    }
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweepValue = 2 * pi * fraction.clamp(0.0, 1.0);
    if (sweepValue > 0) {
      canvas.drawArc(rect, top, sweepValue, false, glow);
      canvas.drawArc(rect, top, sweepValue, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.track != track ||
      old.optimal != optimal;
}

/// Düzey renklerinin açıklaması ve kesikli ideal çizgi.
class ScoreLegend extends StatelessWidget {
  const ScoreLegend({super.key, required this.bands, this.optimalLabel});

  final List<ScoreBand> bands;
  final String? optimalLabel;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.colors.muted, fontSize: 13);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final b in bands)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 8,
                decoration: BoxDecoration(
                  color: b.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(b.label, style: muted),
            ],
          ),
        if (optimalLabel != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('- - -', style: muted),
              const SizedBox(width: 6),
              Text(optimalLabel!, style: muted),
            ],
          ),
      ],
    );
  }
}

/// AI simgeli değerlendirme kartı: başlık, cümleler ve küçük not.
class AssessmentCard extends StatelessWidget {
  const AssessmentCard({
    super.key,
    required this.title,
    required this.lines,
    this.note,
  });

  final String title;
  final List<String> lines;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      tint: camTint(colors.heroTintStart, colors.heroTintEnd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.accent),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (i, line) in lines.indexed) ...[
            if (i > 0) const SizedBox(height: 6),
            Text(line),
          ],
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(note!, style: TextStyle(color: colors.muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// Gösterge satırı: simge, ad, isteğe bağlı alt yazı, değer ve birim.
class IndicatorRow extends StatelessWidget {
  const IndicatorRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
    this.caption,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;
  final String? caption;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      label: [label, value, ?unit, ?caption].join(' '),
      excludeSemantics: true,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: TextStyle(
                        color: context.colors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(unit!, style: TextStyle(color: context.colors.muted)),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Eğilim başlığı: Hafta/Ay seçimi ve tarih aralığı okları.
class TrendHeader extends StatelessWidget {
  const TrendHeader({
    super.key,
    required this.title,
    required this.range,
    required this.now,
    required this.anchor,
    required this.onRange,
  });

  final String title;

  /// Hafta/Ay değişince dönemin kurulduğu gün.
  final DateTime anchor;
  final PeriodRange range;
  final DateTime now;
  final ValueChanged<PeriodRange> onRange;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canForward = range.end.isBefore(now);
    final last = range.end.subtract(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            SegmentedButton<Period>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: Period.week, label: Text(l.recoveryWeek)),
                ButtonSegment(
                  value: Period.month,
                  label: Text(l.recoveryMonth),
                ),
              ],
              selected: {range.period},
              onSelectionChanged: (s) =>
                  onRange(PeriodRange.of(s.first, anchor)),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: l.metricDetailPrevious,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onRange(range.shift(-1)),
            ),
            Expanded(
              child: Text(
                l.recoveryRange(dayMonth(range.start), dayMonth(last)),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.muted),
              ),
            ),
            IconButton(
              tooltip: l.metricDetailNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: canForward ? () => onRange(range.shift(1)) : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Düzey bantlı eğilim grafiği: her gün bir nokta, haftada değer yazılı.
class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({
    super.key,
    required this.series,
    required this.range,
    required this.max,
    required this.ticks,
    required this.bands,
    required this.valueText,
    required this.semantics,
  });

  final List<(DateTime, double?)> series;
  final PeriodRange range;
  final double max;
  final List<double> ticks;
  final List<ScoreBand> bands;

  /// Nokta ve eksen yazısı (yön işaretsiz düz metin).
  final String Function(double) valueText;

  /// Ortalama verilir; veri yoksa null.
  final String Function(double? average) semantics;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final values = [for (final (_, v) in series) ?v];
    final week = range.period == Period.week;
    final axis = TextStyle(color: colors.muted, fontSize: 11);
    final avg = values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
    return Semantics(
      label: semantics(avg),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrendPainter(
                      series: series,
                      max: max,
                      ticks: ticks,
                      bands: bands,
                      valueText: valueText,
                      grid: colors.grid,
                      labelColor: colors.muted,
                      font: DefaultTextStyle.of(context).style,
                      showValues: week,
                      rtl: Directionality.of(context) == TextDirection.rtl,
                    ),
                  ),
                ),
                if (values.isEmpty)
                  Center(child: Text(l.recoveryTrendEmpty, style: axis)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < series.length; i++)
                Expanded(
                  child: Text(
                    week
                        ? weekdayShort(series[i].$1.weekday)
                        : (i % 5 == 0 ? ltr('${series[i].$1.day}') : ''),
                    textAlign: TextAlign.center,
                    style: axis,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
              const SizedBox(width: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.series,
    required this.max,
    required this.ticks,
    required this.bands,
    required this.valueText,
    required this.grid,
    required this.labelColor,
    required this.font,
    required this.showValues,
    required this.rtl,
  });

  final List<(DateTime, double?)> series;
  final double max;
  final List<double> ticks;
  final List<ScoreBand> bands;
  final String Function(double) valueText;
  final Color grid;
  final Color labelColor;
  final TextStyle font;
  final bool showValues;
  final bool rtl;

  static const _axisWidth = 28.0;

  Color _colorOf(double v) =>
      bands.where((b) => v >= b.floor && v < b.ceiling).firstOrNull?.color ??
      (v >= max
          ? bands.reduce((a, b) => a.floor > b.floor ? a : b).color
          : bands.first.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _axisWidth;
    final h = size.height - 8;
    double y(num v) => 8 + h - v / max * h;
    final x0 = rtl ? _axisWidth : 0.0;

    for (final b in bands) {
      canvas.drawRect(
        Rect.fromLTRB(x0, y(b.ceiling), x0 + w, y(b.floor)),
        Paint()..color = b.color.withValues(alpha: 0.07),
      );
    }
    final dash = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in ticks) {
      for (var x = 0.0; x < w; x += 8) {
        canvas.drawLine(
          Offset(x0 + x, y(t)),
          Offset(x0 + min(x + 4, w), y(t)),
          dash,
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: valueText(t),
          style: font.copyWith(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = rtl ? 0.0 : w + 4;
      tp.paint(canvas, Offset(lx, y(t) - tp.height / 2));
    }

    final n = series.length;
    final slot = w / n;
    Offset? prev;
    final line = Paint()
      ..color = labelColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    Offset at(int i, double v) =>
        Offset(x0 + slot * ((rtl ? n - 1 - i : i) + 0.5), y(v));
    for (var i = 0; i < n; i++) {
      final v = series[i].$2;
      if (v == null) {
        prev = null;
        continue;
      }
      final p = at(i, v);
      if (prev != null) canvas.drawLine(prev, p, line);
      prev = p;
    }
    for (var i = 0; i < n; i++) {
      final v = series[i].$2;
      if (v == null) continue;
      final p = at(i, v);
      final color = _colorOf(v);
      canvas.drawCircle(p, showValues ? 5 : 3.5, Paint()..color = color);
      if (showValues) {
        final tp = TextPainter(
          text: TextSpan(
            text: valueText(v),
            style: font.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height + 6));
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.series != series || old.rtl != rtl || old.showValues != showValues;
}
