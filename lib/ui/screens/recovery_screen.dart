import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../../data/recovery.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

extension RecoveryLevelLook on RecoveryLevel {
  String get label {
    final l = currentL10n;
    return switch (this) {
      RecoveryLevel.excellent => l.recoveryExcellent,
      RecoveryLevel.good => l.recoveryGood,
      RecoveryLevel.normal => l.recoveryNormal,
      RecoveryLevel.poor => l.recoveryPoor,
      RecoveryLevel.inadequate => l.recoveryInadequate,
    };
  }

  Color get color => switch (this) {
    RecoveryLevel.excellent => DataColors.steps,
    RecoveryLevel.good => DataColors.oxygen,
    RecoveryLevel.normal => DataColors.body,
    RecoveryLevel.poor => DataColors.temperature,
    RecoveryLevel.inadequate => DataColors.heart,
  };

  String get comment {
    final l = currentL10n;
    return switch (this) {
      RecoveryLevel.excellent => l.recoveryCommentExcellent,
      RecoveryLevel.good => l.recoveryCommentGood,
      RecoveryLevel.normal => l.recoveryCommentNormal,
      RecoveryLevel.poor => l.recoveryCommentPoor,
      RecoveryLevel.inadequate => l.recoveryCommentInadequate,
    };
  }
}

/// Günlük toparlanma: yüzde halkası, değerlendirme, göstergeler (dinlenik
/// nabız, HRV, stres, uyku skoru) ve haftalık/aylık eğilim. Bilekliğin
/// vermediği gösterge gizlenir.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, required this.day, this.now});

  final DateTime day;

  /// Testler için "şimdi"; gelecekteki günler çizilmez.
  final DateTime? now;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Period _period = Period.week;
  late PeriodRange _range = PeriodRange.of(Period.week, widget.day);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = DeviceScope.of(context).store;
    final now = widget.now ?? DateTime.now();
    return CamScaffold(
      appBar: AppBar(title: Text(l.recoveryTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final r = DayRecovery.of(store, widget.day);
            final series = DayRecovery.series(store, _range, now: now);
            const gap = SizedBox(height: CamSpace.gap);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (r == null)
                  GlassCard(
                    child: Text(
                      l.recoveryEmpty,
                      style: TextStyle(color: context.colors.muted),
                    ),
                  )
                else ...[
                  _Ring(r),
                  const SizedBox(height: 16),
                  const _Legend(),
                  const SizedBox(height: 16),
                  _Assessment(r),
                  const SizedBox(height: 24),
                  Text(
                    l.recoveryIndicators,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ..._indicators(context, r),
                ],
                const SizedBox(height: 16),
                _trendHeader(context, now),
                gap,
                GlassCard(
                  child: _TrendChart(series: series, range: _range),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _trendHeader(BuildContext context, DateTime now) {
    final l = context.l10n;
    final canForward = _range.end.isBefore(now);
    final last = _range.end.subtract(const Duration(days: 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.recoveryTrend,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
              selected: {_period},
              onSelectionChanged: (s) => setState(() {
                _period = s.first;
                _range = PeriodRange.of(_period, widget.day);
              }),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              tooltip: l.metricDetailPrevious,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _range = _range.shift(-1)),
            ),
            Expanded(
              child: Text(
                l.recoveryRange(dayMonth(_range.start), dayMonth(last)),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.muted),
              ),
            ),
            IconButton(
              tooltip: l.metricDetailNext,
              icon: const Icon(Icons.chevron_right),
              onPressed: canForward
                  ? () => setState(() => _range = _range.shift(1))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _indicators(BuildContext context, DayRecovery r) {
    final l = context.l10n;
    final bpm = MetricType.heartRate.unit;
    String n(num v) => ltr(v.round().toString());
    final rows = <(IconData, Color, String, String, String?, String?)>[
      if (r.restingHeartRate case final v?)
        (
          Icons.favorite,
          DataColors.heart,
          l.recoveryRestingHr,
          n(v),
          bpm,
          r.restingBaseline == null
              ? null
              : l.recoveryUsual('${n(r.restingBaseline!)} $bpm'),
        ),
      if (r.hrv case final v?)
        (
          Icons.monitor_heart_outlined,
          DataColors.hrv,
          l.recoveryHrv,
          n(v),
          MetricType.hrv.unit,
          r.hrvBaseline == null
              ? null
              : l.recoveryUsual('${n(r.hrvBaseline!)} ${MetricType.hrv.unit}'),
        ),
      if (r.stress case final v?)
        (
          Icons.self_improvement,
          DataColors.stress,
          l.recoveryStress,
          n(v),
          null,
          null,
        ),
      if (r.sleepScore case final v?)
        (
          Icons.bedtime,
          DataColors.sleepLight,
          l.recoverySleepScore,
          n(v),
          null,
          null,
        ),
    ];
    return [
      for (final (icon, color, label, value, unit, usual) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            label: [label, value, ?unit, ?usual].join(' '),
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
                        if (usual != null)
                          Text(
                            usual,
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
                    Text(unit, style: TextStyle(color: context.colors.muted)),
                  ],
                ],
              ),
            ),
          ),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Halka
// ---------------------------------------------------------------------------

class _Ring extends StatelessWidget {
  const _Ring(this.r);

  final DayRecovery r;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final value = l.homePercent(r.score);
    return Semantics(
      label: l.recoveryRingSemantics(value, r.level.label),
      excludeSemantics: true,
      child: Center(
        child: SizedBox.square(
          dimension: 260,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: r.score / 100,
              color: r.level.color,
              track: colors.grid,
              optimal: colors.muted,
            ),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.homeDailyRecovery,
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
                      r.level.label,
                      style: TextStyle(
                        color: r.level.color,
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
    required this.optimal,
  });

  final double fraction;
  final Color color;
  final Color track;
  final Color optimal;

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
    // İdeal bölge (75–100): dış kenarda kesikli yay.
    final outer = Rect.fromCircle(center: c, radius: radius + stroke / 2 + 8);
    final dash = Paint()
      ..color = optimal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const from = top + 2 * pi * DayRecovery.optimal / 100;
    const sweep = 2 * pi * (100 - DayRecovery.optimal) / 100;
    const step = 0.06;
    for (var a = from; a < from + sweep; a += step * 2) {
      canvas.drawArc(outer, a, min(step, from + sweep - a), false, dash);
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
      old.fraction != fraction || old.color != color || old.track != track;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: context.colors.muted, fontSize: 13);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final level in RecoveryLevel.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 8,
                decoration: BoxDecoration(
                  color: level.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(level.label, style: muted),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('- - -', style: muted),
            const SizedBox(width: 6),
            Text(context.l10n.recoveryOptimal, style: muted),
          ],
        ),
      ],
    );
  }
}

class _Assessment extends StatelessWidget {
  const _Assessment(this.r);

  final DayRecovery r;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  l.recoveryAssessment,
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
          Text(r.level.comment),
          if (r.hrvLow) ...[const SizedBox(height: 6), Text(l.recoveryHrvLow)],
          if (r.restingHigh) ...[
            const SizedBox(height: 6),
            Text(l.recoveryRhrHigh),
          ],
          const SizedBox(height: 10),
          Text(
            l.recoveryNote,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Eğilim
// ---------------------------------------------------------------------------

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.series, required this.range});

  final List<(DateTime, int?)> series;
  final PeriodRange range;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final values = [for (final (_, v) in series) ?v];
    final week = range.period == Period.week;
    final axis = TextStyle(color: colors.muted, fontSize: 11);
    final avg = values.isEmpty
        ? null
        : (values.reduce((a, b) => a + b) / values.length).round();
    return Semantics(
      label: avg == null
          ? l.recoveryTrendEmpty
          : l.recoveryTrendSemantics(
              l.recoveryRange(
                dayMonth(range.start),
                dayMonth(range.end.subtract(const Duration(days: 1))),
              ),
              l.homePercent(avg),
            ),
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
    required this.grid,
    required this.labelColor,
    required this.font,
    required this.showValues,
    required this.rtl,
  });

  final List<(DateTime, int?)> series;
  final Color grid;
  final Color labelColor;
  final TextStyle font;
  final bool showValues;
  final bool rtl;

  static const _axisWidth = 28.0;
  static const _ticks = [0, 40, 60, 75, 90, 100];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _axisWidth;
    final h = size.height - 8;
    double y(num v) => 8 + h - v / 100 * h;
    final x0 = rtl ? _axisWidth : 0.0;

    // Düzey bantları.
    for (final level in RecoveryLevel.values) {
      final upper = level == RecoveryLevel.excellent
          ? 100
          : RecoveryLevel.values[level.index - 1].floor;
      canvas.drawRect(
        Rect.fromLTRB(x0, y(upper), x0 + w, y(level.floor)),
        Paint()..color = level.color.withValues(alpha: 0.07),
      );
    }
    final dash = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in _ticks) {
      for (var x = 0.0; x < w; x += 8) {
        canvas.drawLine(
          Offset(x0 + x, y(t)),
          Offset(x0 + min(x + 4, w), y(t)),
          dash,
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: '$t',
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
    for (var i = 0; i < n; i++) {
      final v = series[i].$2;
      if (v == null) {
        prev = null;
        continue;
      }
      final idx = rtl ? n - 1 - i : i;
      final p = Offset(x0 + slot * (idx + 0.5), y(v));
      if (prev != null) canvas.drawLine(prev, p, line);
      prev = p;
    }
    for (var i = 0; i < n; i++) {
      final v = series[i].$2;
      if (v == null) continue;
      final idx = rtl ? n - 1 - i : i;
      final p = Offset(x0 + slot * (idx + 0.5), y(v));
      final color = RecoveryLevel.of(v).color;
      canvas.drawCircle(p, showValues ? 5 : 3.5, Paint()..color = color);
      if (showValues) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$v',
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
