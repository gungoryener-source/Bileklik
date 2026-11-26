import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../../data/sleep_analysis.dart';
import '../../device/protocol/history.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Uyku evresinin rengi; adı `SleepStageName`'de (format.dart).
extension SleepLook on SleepStage {
  Color get color => switch (this) {
    SleepStage.deep => DataColors.sleepDeep,
    SleepStage.light => DataColors.sleepLight,
    SleepStage.rem => DataColors.sleepRem,
    SleepStage.awake => DataColors.temperature,
  };
}

/// Grafikte yukarıdan aşağı evre sırası.
const _stageOrder = [
  SleepStage.awake,
  SleepStage.rem,
  SleepStage.light,
  SleepStage.deep,
];

/// Gecenin ayrıntısı: skor ve yorum, yatış/kalkış, evre grafiği, evre
/// dağılımı ve ideal aralık, uyku örüntüsü, uyku sırasında nabız, SpO2 ve
/// HRV, kısa şekerlemeler ve son 7 gece. Bilekliğin vermediği bölüm gizlenir.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key, this.day});

  /// Açılışta gösterilecek gece (uyanılan gün); yoksa son gece.
  final DateTime? day;

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  int? _index;

  @override
  Widget build(BuildContext context) {
    final store = DeviceScope.of(context).store;
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.sleepTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final now = DateTime.now();
            final groups = NightSleep.group(
              store.sleepBetween(now.subtract(const Duration(days: 60)), now),
            );
            final nights = [
              for (final g in groups) ?SleepAnalysis.of(store, g),
            ];
            if (nights.isEmpty) {
              return Center(
                child: Text(
                  l.sleepEmpty,
                  style: TextStyle(color: context.colors.muted),
                ),
              );
            }
            final wanted = widget.day;
            final initial = wanted == null
                ? nights.length - 1
                : nights.lastIndexWhere(
                    (a) => !a.night.day.isAfter(
                      DateTime(wanted.year, wanted.month, wanted.day),
                    ),
                  );
            final i = (_index ?? max(initial, 0)).clamp(0, nights.length - 1);
            final a = nights[i];
            const gap = SizedBox(height: CamSpace.gap);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: l.sleepPreviousNight,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: i > 0
                          ? () => setState(() => _index = i - 1)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        dayMonth(a.night.day),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l.sleepNextNight,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: i < nights.length - 1
                          ? () => setState(() => _index = i + 1)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _ScoreCard(a),
                gap,
                _TimesCard(a),
                gap,
                _DistributionCard(a),
                gap,
                _PatternCard(a),
                if (a.heartRate case final s?) ...[
                  gap,
                  _SeriesCard(
                    title: l.sleepDuringHeartRate,
                    series: s,
                    analysis: a,
                    color: DataColors.heart,
                    format: (v) =>
                        '${ltr(v.round().toString())} ${MetricType.heartRate.unit}',
                  ),
                ],
                if (a.spo2 case final s?) ...[
                  gap,
                  _SeriesCard(
                    title: l.sleepDuringSpo2,
                    series: s,
                    analysis: a,
                    color: DataColors.oxygen,
                    format: (v) => l.homePercent(v.round()),
                  ),
                ],
                if (a.hrv case final s?) ...[
                  gap,
                  _SeriesCard(
                    title: l.sleepDuringHrv,
                    series: s,
                    analysis: a,
                    color: DataColors.hrv,
                    format: (v) =>
                        '${ltr(v.round().toString())} ${MetricType.hrv.unit}',
                  ),
                ],
                gap,
                _NapsCard(a.naps),
                gap,
                _Card(
                  title: l.sleepLast7Nights,
                  child: _WeekBars([
                    for (final n in nights.sublist(max(0, nights.length - 7)))
                      n.night,
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

TextStyle _muted(BuildContext context, {double? size}) =>
    TextStyle(color: context.colors.muted, fontSize: size);

/// Başlıklı cam kart.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Skor ve yorum
// ---------------------------------------------------------------------------

class _ScoreCard extends StatelessWidget {
  const _ScoreCard(this.a);

  final SleepAnalysis a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final score = a.score;
    final label = score == null
        ? null
        : score >= 85
        ? l.homeSleepExcellent
        : score >= 70
        ? l.homeSleepGood
        : score >= 50
        ? l.homeSleepFair
        : l.homeSleepPoor;
    final lines = [
      a.debtMinutes > 0
          ? l.sleepSummaryDebt(
              duration(a.asleepMinutes),
              duration(a.debtMinutes),
            )
          : l.sleepSummaryEnough(duration(a.asleepMinutes)),
      if (a.stagePercent(SleepStage.deep) < idealStageRange(SleepStage.deep).$1)
        l.sleepSummaryLowDeep,
      if (a.efficiency < 85) l.sleepSummaryLowEfficiency(a.efficiency),
    ];
    return GlassCard(
      tint: camTint(colors.sleepTintStart, colors.sleepTintEnd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (score != null)
            Semantics(
              label: '${l.sleepScoreLabel} $score, $label',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 56,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: DataColors.sleepLight,
                          ),
                        ),
                        Text(l.sleepScoreLabel, style: _muted(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            ),
          const SizedBox(height: 4),
          Text(l.sleepSummaryNote, style: _muted(context, size: 12)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saatler ve evre grafiği
// ---------------------------------------------------------------------------

class _TimesCard extends StatelessWidget {
  const _TimesCard(this.a);

  final SleepAnalysis a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tile(IconData icon, String label, DateTime t) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(CamRadius.tile),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            children: [
              Text(
                hhmm(t),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: DataColors.sleepLight),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: _muted(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              tile(Icons.bedtime_outlined, l.sleepBedTime, a.bedTime),
              const SizedBox(width: 12),
              tile(Icons.wb_sunny_outlined, l.sleepWakeTime, a.wakeTime),
            ],
          ),
          const SizedBox(height: 18),
          Text(l.sleepDuration, style: _muted(context)),
          Text(
            duration(a.asleepMinutes),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: DataColors.sleepLight,
            ),
          ),
          const SizedBox(height: 12),
          _Hypnogram(a.night),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final s in _stageOrder)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(s.label, style: _muted(context, size: 12)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Basamaklı evre grafiği: üstte uyanık, altta derin uyku.
class _Hypnogram extends StatelessWidget {
  const _Hypnogram(this.night);

  final NightSleep night;

  @override
  Widget build(BuildContext context) {
    final parts = <(DateTime, SleepStage, int)>[];
    for (final s in night.sessions) {
      for (var i = 0; i < s.minutes.length; i++) {
        final m = s.minutes[i];
        final t = s.start.add(Duration(minutes: i));
        if (parts.isNotEmpty &&
            parts.last.$2 == m &&
            parts.last.$1
                .add(Duration(minutes: parts.last.$3))
                .isAtSameMomentAs(t)) {
          parts[parts.length - 1] = (parts.last.$1, m, parts.last.$3 + 1);
        } else {
          parts.add((t, m, 1));
        }
      }
    }
    return Semantics(
      label: context.l10n.sleepStagesChart(hhmm(night.start), hhmm(night.end)),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _HypnogramPainter(
                parts: parts,
                start: night.start,
                end: night.end,
                grid: context.colors.grid,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(hhmm(night.start), style: _muted(context, size: 11)),
              const Spacer(),
              Text(hhmm(night.end), style: _muted(context, size: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({
    required this.parts,
    required this.start,
    required this.end,
    required this.grid,
    required this.rtl,
  });

  final List<(DateTime, SleepStage, int)> parts;
  final DateTime start;
  final DateTime end;
  final Color grid;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final total = max(1, end.difference(start).inMinutes);
    final row = size.height / _stageOrder.length;
    final bar = row * 0.6;
    double x(DateTime t) {
      final f = t.difference(start).inMinutes / total * size.width;
      return rtl ? size.width - f : f;
    }

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var r = 0; r <= _stageOrder.length; r++) {
      canvas.drawLine(
        Offset(0, r * row),
        Offset(size.width, r * row),
        gridPaint,
      );
    }
    final link = Paint()
      ..color = grid.withValues(alpha: 1)
      ..strokeWidth = 1;
    Offset? prev;
    for (final (t, stage, len) in parts) {
      final r = _stageOrder.indexOf(stage);
      final x1 = x(t);
      final x2 = x(t.add(Duration(minutes: len)));
      final top = r * row + (row - bar) / 2;
      final rect = Rect.fromLTRB(min(x1, x2), top, max(x1, x2), top + bar);
      if (prev != null) {
        canvas.drawLine(prev, Offset(x1, top + bar / 2), link);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = stage.color,
      );
      prev = Offset(x2, top + bar / 2);
    }
  }

  @override
  bool shouldRepaint(_HypnogramPainter old) =>
      old.parts != parts || old.rtl != rtl || old.grid != grid;
}

// ---------------------------------------------------------------------------
// Evre dağılımı
// ---------------------------------------------------------------------------

class _DistributionCard extends StatelessWidget {
  const _DistributionCard(this.a);

  final SleepAnalysis a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return _Card(
      title: l.sleepDistribution,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 10,
            decoration: BoxDecoration(
              border: Border.all(color: colors.text.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(l.sleepIdealRange, style: _muted(context, size: 12)),
        ],
      ),
      child: Column(
        children: [
          for (final s in _stageOrder)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: _StageBar(a: a, stage: s),
            ),
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar({required this.a, required this.stage});

  final SleepAnalysis a;
  final SleepStage stage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final pct = a.stagePercent(stage);
    final (lo, hi) = idealStageRange(stage);
    final ok = a.stageInRange(stage);
    return Semantics(
      label:
          '${stage.label}: ${l.sleepPercent(pct)}, '
          '${duration(a.stageMinutes(stage))}. ${l.sleepIdealValue(lo, hi)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: stage.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: duration(a.stageMinutes(stage)),
                        style: _muted(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l.sleepPercent(pct),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ok ? colors.text : DataColors.temperature,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colors.grid,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      width: w * min(pct, 100) / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: stage.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: w * lo / 100,
                      top: 0,
                      bottom: 0,
                      width: max(2, w * (hi - lo) / 100),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.text.withValues(alpha: 0.7),
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(l.sleepIdealValue(lo, hi), style: _muted(context, size: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Uyku örüntüsü
// ---------------------------------------------------------------------------

class _PatternCard extends StatelessWidget {
  const _PatternCard(this.a);

  final SleepAnalysis a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = <(String, String, double, Color)>[
      (
        l.sleepDuration,
        duration(a.asleepMinutes),
        a.asleepMinutes / SleepAnalysis.needMinutes,
        DataColors.sleepLight,
      ),
      (
        l.sleepInBed,
        duration(a.inBedMinutes),
        a.inBedMinutes / 600,
        DataColors.sleepDeep,
      ),
      (
        l.sleepEfficiency,
        l.sleepPercent(a.efficiency),
        a.efficiency / 100,
        DataColors.hrv,
      ),
      (
        l.sleepLatency,
        duration(a.latencyMinutes),
        a.latencyMinutes / 60,
        DataColors.sleepRem,
      ),
      (
        l.sleepDebt,
        a.debtMinutes == 0 ? l.sleepNoDebt : duration(a.debtMinutes),
        a.debtMinutes / SleepAnalysis.needMinutes,
        DataColors.temperature,
      ),
    ];
    return _Card(
      title: l.sleepPattern,
      child: Column(
        children: [
          for (final (label, value, fraction, color) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Semantics(
                label: '$label: $value',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(label, style: _muted(context)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            value,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0, 1).toDouble(),
                        minHeight: 5,
                        color: color,
                        backgroundColor: context.colors.grid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Uyku sırasında nabız, SpO2, HRV
// ---------------------------------------------------------------------------

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.title,
    required this.series,
    required this.analysis,
    required this.color,
    required this.format,
  });

  final String title;
  final NightSeries series;
  final SleepAnalysis analysis;
  final Color color;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    Widget stat(String value, String label) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(CamRadius.tile),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: _muted(context, size: 12)),
            ],
          ),
        ),
      ),
    );
    final avg = format(series.stats.average);
    final low = format(series.stats.min);
    return _Card(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (series.points.length >= 2) ...[
            ExcludeSemantics(
              child: SizedBox(
                height: 90,
                child: CustomPaint(
                  painter: _LinePainter(
                    points: series.points,
                    start: analysis.bedTime,
                    end: analysis.wakeTime,
                    color: color,
                    grid: colors.grid,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(hhmm(analysis.bedTime), style: _muted(context, size: 11)),
                const Spacer(),
                Text(hhmm(analysis.wakeTime), style: _muted(context, size: 11)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Semantics(
            label: '${l.homeAverageLabel} $avg, ${l.homeLowestLabel} $low',
            excludeSemantics: true,
            child: Row(
              children: [
                stat(avg, l.homeAverageLabel),
                const SizedBox(width: 12),
                stat(low, l.homeLowestLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.start,
    required this.end,
    required this.color,
    required this.grid,
    required this.rtl,
  });

  final List<Measurement> points;
  final DateTime start;
  final DateTime end;
  final Color color;
  final Color grid;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.value);
    var lo = values.reduce(min);
    var hi = values.reduce(max);
    if (hi - lo < 4) {
      lo -= 2;
      hi += 2;
    }
    final span = max(1, end.difference(start).inMinutes);
    Offset at(Measurement m) {
      final f = (m.time.difference(start).inMinutes / span).clamp(0.0, 1.0);
      final x = (rtl ? 1 - f : f) * size.width;
      final y = size.height - (m.value - lo) / (hi - lo) * size.height;
      return Offset(x, y);
    }

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      final o = at(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.rtl != rtl || old.color != color;
}

// ---------------------------------------------------------------------------
// Şekerlemeler ve son 7 gece
// ---------------------------------------------------------------------------

class _NapsCard extends StatelessWidget {
  const _NapsCard(this.naps);

  final List<SleepSession> naps;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Card(
      title: l.sleepNaps,
      child: naps.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  const Moon3D(size: 48),
                  const SizedBox(height: 8),
                  Text(l.sleepNoNaps, style: _muted(context)),
                ],
              ),
            )
          : Column(
              children: [
                for (final n in naps)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bedtime_outlined,
                          color: DataColors.sleepLight,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.sleepTimeRange(hhmm(n.start), hhmm(n.end)),
                          ),
                        ),
                        Text(
                          duration(
                            n.minutes.length - n.minutesIn(SleepStage.awake),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars(this.nights);
  final List<NightSleep> nights;

  @override
  Widget build(BuildContext context) {
    final most = nights.fold(
      1,
      (m, n) => n.asleepMinutes > m ? n.asleepMinutes : m,
    );
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final n in nights)
            Expanded(
              child: Semantics(
                label: context.l10n.sleepWeekBarHint(
                  weekdayLong(n.day.weekday),
                  duration(n.asleepMinutes),
                ),
                excludeSemantics: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      ltr((n.asleepMinutes / 60).toStringAsFixed(1)),
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      softWrap: false,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Container(
                        height: 70 * n.asleepMinutes / most,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: DataColors.sleepLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekdayShort(n.day.weekday),
                      style: _muted(context, size: 11),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
