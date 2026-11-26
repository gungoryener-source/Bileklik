import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/insights.dart';
import '../../data/models.dart';
import '../../data/recovery.dart';
import '../../data/strain.dart';
import '../../data/workout_report.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/insights.dart';
import 'recovery_screen.dart';
import 'strain_screen.dart';

extension MetIntensityLook on MetIntensity {
  String get label {
    final l = currentL10n;
    return switch (this) {
      MetIntensity.light => l.wrMetLight,
      MetIntensity.moderate => l.wrMetModerate,
      MetIntensity.vigorous => l.wrMetVigorous,
    };
  }

  String get comment {
    final l = currentL10n;
    return switch (this) {
      MetIntensity.light => l.wrMetCommentLight,
      MetIntensity.moderate => l.wrMetCommentModerate,
      MetIntensity.vigorous => l.wrMetCommentVigorous,
    };
  }

  Color get color => switch (this) {
    MetIntensity.light => DataColors.steps,
    MetIntensity.moderate => DataColors.body,
    MetIntensity.vigorous => DataColors.temperature,
  };
}

/// Egzersiz raporu: kalori, süre, ortalama ve en yüksek nabız, egzersiz
/// yükü (0–21), metabolik eşdeğer ve günün toparlanması, yorumlar, nabız
/// bölgelerine göre renkli nabız grafiği ve bölge dağılımı. Olmayan veri
/// gizlenir.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    this.justFinished = false,
  });

  final Workout workout;

  /// Egzersiz az önce bittiyse başlıkta tebrik gösterilir.
  final bool justFinished;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final device = DeviceScope.of(context);
    final r = WorkoutReport.of(
      device.store,
      workout,
      age: device.profile?.age,
      weightKg: device.profile?.weightKg,
    );
    const gap = SizedBox(height: CamSpace.gap);
    return CamScaffold(
      appBar: AppBar(title: Text(l.wrTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Header(workout: workout, justFinished: justFinished),
            const SizedBox(height: 16),
            _Summary(r: r),
            gap,
            _Gauges(r: r),
            gap,
            if (r.heartRate.length >= 2) ...[_HeartRateChart(r: r), gap],
            if (r.averageHeartRate != null) _Zones(r: r),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.workout, required this.justFinished});

  final Workout workout;
  final bool justFinished;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final w = workout;
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent.withValues(alpha: 0.15),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Icon(sportIcon(w.type), color: colors.accent, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                justFinished ? l.workoutCongrats : sportLabel(w.type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (justFinished) Text(sportLabel(w.type)),
              Text(
                l.workoutTimeRange(
                  dayMonth(w.start),
                  hhmm(w.start),
                  hhmm(w.end),
                ),
                style: TextStyle(color: colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Özet kartı
// ---------------------------------------------------------------------------

class _Summary extends StatelessWidget {
  const _Summary({required this.r});

  final WorkoutReport r;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final w = r.workout;
    final bpm = MetricType.heartRate.unit;
    final hasDistance = w.distanceKm > 0.01;
    final level = StrainLevel.of(r.load);
    final extras = [
      if (w.steps > 0) (MetricType.steps.label, ltr('${w.steps}'), ''),
      if (hasDistance)
        (
          MetricType.distance.label,
          distanceValue(w.distanceKm),
          MetricType.distance.unit,
        ),
      if (hasDistance)
        (
          l.statPace,
          paceText(
            DisplayPrefs.imperial
                ? paceFor(w.duration.inSeconds, w.distanceKm)
                : w.pace,
          ),
          '/${MetricType.distance.unit}',
        ),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (w.calories > 0)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: ltr(w.calories.round().toString()),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: ' ${MetricType.calories.unit}',
                    style: TextStyle(color: colors.muted, fontSize: 18),
                  ),
                ],
              ),
            ),
          if (w.calories > 0) Divider(color: colors.outline, height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.schedule,
                  color: DataColors.oxygen,
                  label: l.statDuration,
                  value: ltr(clock(w.duration)),
                ),
              ),
              if (r.averageHeartRate case final avg?)
                Expanded(
                  child: _Stat(
                    icon: Icons.monitor_heart,
                    color: DataColors.heart,
                    label: l.wrAvgHr,
                    value: ltr('$avg'),
                    unit: bpm,
                  ),
                ),
              if (r.peakHeartRate case final peak?)
                Expanded(
                  child: _Stat(
                    icon: Icons.favorite,
                    color: DataColors.heart,
                    label: l.wrMaxHr,
                    value: ltr('$peak'),
                    unit: bpm,
                  ),
                ),
            ],
          ),
          if (r.averageHeartRate != null) ...[
            const SizedBox(height: 18),
            Semantics(
              label: l.wrLoadSemantics(oneDecimal(r.load)),
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ltr(oneDecimal(r.load)),
                          style: TextStyle(
                            color: level.color,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        Text(l.wrLoad, style: TextStyle(color: colors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: r.load / DayStrain.max,
                            minHeight: 12,
                            color: level.color,
                            backgroundColor: colors.surfaceHigh,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              ltr('0'),
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              ltr('21'),
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: HomeSky.inner,
                borderRadius: BorderRadius.circular(CamRadius.tile),
              ),
              child: Row(
                children: [
                  for (final (label, value, unit) in extras)
                    Expanded(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              unit.isEmpty ? value : '$value $unit',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.muted;
    return Semantics(
      label: [label, value, ?unit].join(' '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(color: muted, fontSize: 12),
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
// MET ve toparlanma göstergeleri, yorumlar
// ---------------------------------------------------------------------------

class _Gauges extends StatelessWidget {
  const _Gauges({required this.r});

  final WorkoutReport r;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final met = r.met;
    final intensity = r.intensity;
    final rec = r.recovery;
    if (met == null && rec == null) return const SizedBox.shrink();
    final metSegments = [
      for (final i in MetIntensity.values)
        (
          switch (i) {
            MetIntensity.light => 1.0,
            MetIntensity.moderate => 3.0,
            MetIntensity.vigorous => 6.0,
          },
          i.color,
        ),
    ];
    final recSegments = [
      for (final level in RecoveryLevel.values.reversed)
        (level.floor.toDouble(), level.color),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (met != null && intensity != null)
                Expanded(
                  child: _ArcGauge(
                    value: met,
                    min: 1,
                    max: WorkoutReport.metMax,
                    segments: metSegments,
                    valueText: ltr(oneDecimal(met)),
                    label: l.wrMet,
                    level: intensity.label,
                  ),
                ),
              if (met != null && rec != null) const SizedBox(width: 12),
              if (rec != null)
                Expanded(
                  child: _ArcGauge(
                    value: rec.score.toDouble(),
                    min: 0,
                    max: 100,
                    segments: recSegments,
                    valueText: ltr('${rec.score}'),
                    label: l.wrRecovery,
                    level: rec.level.label,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (intensity != null) Text(intensity.comment),
          if (intensity != null && rec != null) const SizedBox(height: 10),
          if (rec != null) Text(rec.level.comment),
          const SizedBox(height: 10),
          Text(l.wrNote, style: TextStyle(color: colors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Yarım daire gösterge: renkli dilimler, değerin düştüğü dilim parlak,
/// diğerleri soluk; ortada değer, altında ad ve düzey.
class _ArcGauge extends StatelessWidget {
  const _ArcGauge({
    required this.value,
    required this.min,
    required this.max,
    required this.segments,
    required this.valueText,
    required this.label,
    required this.level,
  });

  final double value;
  final double min;
  final double max;

  /// (alt sınır, renk); artan sırada.
  final List<(double, Color)> segments;
  final String valueText;
  final String label;
  final String level;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      label: l.wrGaugeSemantics(label, valueText, level),
      excludeSemantics: true,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2,
            child: CustomPaint(
              painter: _ArcPainter(
                fraction: ((value - min) / (max - min)).clamp(0.0, 1.0),
                segments: [
                  for (final (from, color) in segments)
                    (((from - min) / (max - min)).clamp(0.0, 1.0), color),
                ],
                marker: context.colors.text,
              ),
              child: Align(
                alignment: const Alignment(0, 0.9),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
          Text(
            level,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.fraction,
    required this.segments,
    required this.marker,
  });

  final double fraction;
  final List<(double, Color)> segments;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final radius = min(size.width / 2, size.height) - stroke;
    final c = Offset(size.width / 2, size.height - stroke / 2);
    final rect = Rect.fromCircle(center: c, radius: radius);
    const gapAngle = 0.05;
    for (var i = 0; i < segments.length; i++) {
      final from = segments[i].$1;
      final to = i + 1 < segments.length ? segments[i + 1].$1 : 1.0;
      if (to <= from) continue;
      final active = fraction >= from && (fraction < to || to == 1.0);
      final start = pi + pi * from + (i == 0 ? 0 : gapAngle / 2);
      final sweep = pi * (to - from) - (i == 0 ? gapAngle / 2 : gapAngle);
      canvas.drawArc(
        rect,
        start,
        max(sweep, 0.01),
        false,
        Paint()
          ..color = segments[i].$2.withValues(alpha: active ? 1 : 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
    final a = pi + pi * fraction;
    final p = c + Offset(cos(a), sin(a)) * radius;
    canvas.drawCircle(p, stroke / 2 + 2, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.fraction != fraction;
}

// ---------------------------------------------------------------------------
// Nabız grafiği
// ---------------------------------------------------------------------------

class _HeartRateChart extends StatelessWidget {
  const _HeartRateChart({required this.r});

  final WorkoutReport r;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final lo = r.lowHeartRate!;
    final hi = r.peakHeartRate!;
    final range = ltr('$lo – $hi');
    final w = r.workout;
    final axis = TextStyle(color: colors.muted, fontSize: 11);
    return Semantics(
      label: l.wrChartSemantics('$range ${MetricType.heartRate.unit}'),
      excludeSemantics: true,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l.wrHrChart(MetricType.heartRate.unit),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l.wrRange, style: axis),
                    Text(
                      range,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _HrBarsPainter(
                  r: r,
                  grid: colors.grid,
                  label: colors.muted,
                  font: DefaultTextStyle.of(context).style,
                  fallback: HomeSky.chart,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(ltr(hhmm(w.start)), style: axis),
                const Spacer(),
                Text(ltr(hhmm(w.end)), style: axis),
                const SizedBox(width: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HrBarsPainter extends CustomPainter {
  _HrBarsPainter({
    required this.r,
    required this.grid,
    required this.label,
    required this.font,
    required this.fallback,
    required this.rtl,
  });

  final WorkoutReport r;
  final Color grid;
  final Color label;
  final TextStyle font;
  final Color fallback;
  final bool rtl;

  static const _axis = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    final hr = r.heartRate;
    final w = r.workout;
    final lo = (r.lowHeartRate! - 10).toDouble();
    final hi = r.peakHeartRate!.toDouble();
    final span = max(hi - lo, 1.0);
    final width = size.width - _axis;
    final x0 = rtl ? _axis : 0.0;
    double y(double v) => size.height - (v - lo) / span * (size.height - 6);
    final total = max(w.duration.inSeconds, 1);
    double x(DateTime t) {
      final f = (t.difference(w.start).inSeconds / total).clamp(0.0, 1.0);
      return x0 + (rtl ? 1 - f : f) * width;
    }

    // Yatay kılavuzlar ve değerler.
    final dash = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final v = lo + span * i / 4;
      final yy = y(v);
      canvas.drawLine(Offset(x0, yy), Offset(x0 + width, yy), dash);
      if (i == 0) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: v.round().toString(),
          style: font.copyWith(color: label, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rtl ? 0 : width + 4, yy - tp.height / 2));
    }

    // Her ölçüm bir sonrakine kadar süren bir sütun; renk nabız bölgesi.
    for (var i = 0; i < hr.length; i++) {
      final m = hr[i];
      final end = i + 1 < hr.length ? hr[i + 1].time : w.end;
      final a = x(m.time), b = x(end);
      final zone = r.zoneMaxHr == null
          ? null
          : HeartRateZone.of(m.value, r.zoneMaxHr!);
      canvas.drawRect(
        Rect.fromLTRB(min(a, b), y(m.value), max(a, b), size.height),
        Paint()..color = (zone?.color ?? fallback).withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(_HrBarsPainter old) => old.r != r || old.rtl != rtl;
}

// ---------------------------------------------------------------------------
// Bölge dağılımı
// ---------------------------------------------------------------------------

class _Zones extends StatelessWidget {
  const _Zones({required this.r});

  final WorkoutReport r;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final maxHr = r.zoneMaxHr;
    final total = r.zonedTime;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.wrZones, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (maxHr == null)
            Text(l.zonesNeedsAge, style: TextStyle(color: colors.muted))
          else if (total == Duration.zero)
            Text(l.zonesEmpty, style: TextStyle(color: colors.muted))
          else ...[
            for (final z in HeartRateZone.values)
              _ZoneBar(
                zone: z,
                time: r.zones[z] ?? Duration.zero,
                share:
                    (r.zones[z] ?? Duration.zero).inSeconds / total.inSeconds,
                range: z.rangeText(maxHr),
              ),
            const SizedBox(height: 4),
            Text(
              l.zonesNote('${ltr('$maxHr')} ${MetricType.heartRate.unit}'),
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  const _ZoneBar({
    required this.zone,
    required this.time,
    required this.share,
    required this.range,
  });

  final HeartRateZone zone;
  final Duration time;
  final double share;
  final String range;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final percent = l.homePercent((share * 100).round());
    final timeText = ltr(clock(time));
    return Semantics(
      label: l.zoneSemantics(zone.label, range, '$timeText, $percent'),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 2,
              children: [
                Text(
                  zone.label,
                  style: TextStyle(
                    color: zone.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  percent,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    color: colors.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  range,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 14,
              child: CustomPaint(
                painter: _StripedBarPainter(
                  share: share,
                  color: zone.color,
                  stripe: colors.grid,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Çizgili iz üstünde dolu çubuk.
class _StripedBarPainter extends CustomPainter {
  _StripedBarPainter({
    required this.share,
    required this.color,
    required this.stripe,
    required this.rtl,
  });

  final double share;
  final Color color;
  final Color stripe;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRRect(rr, Paint()..color = stripe.withValues(alpha: 0.04));
    final p = Paint()
      ..color = stripe
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    final w = size.width * share.clamp(0.0, 1.0);
    if (w > 0) {
      final fill = Rect.fromLTWH(rtl ? size.width - w : 0, 0, w, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fill, const Radius.circular(4)),
        Paint()..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripedBarPainter old) =>
      old.share != share || old.color != color;
}
