import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/health_store.dart';
import '../../data/insights.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../format.dart';
import '../theme.dart';
import 'cam/cam.dart';

// Uygulamanın kendi içgörüleri: nabız bölgeleri, ısı sapması, biyolojik yaş
// ve Sağlık Radarı. Hesaplar lib/data/insights.dart içinde.

extension HeartRateZoneLook on HeartRateZone {
  String get label {
    final l = currentL10n;
    return switch (this) {
      HeartRateZone.warmUp => l.zoneWarmUp,
      HeartRateZone.fatBurn => l.zoneFatBurn,
      HeartRateZone.aerobic => l.zoneAerobic,
      HeartRateZone.anaerobic => l.zoneAnaerobic,
      HeartRateZone.maximum => l.zoneMaximum,
    };
  }

  Color get color => DataColors.zones[index];

  /// "114–132 atım/dk"; son bölgede "171+ atım/dk".
  String rangeText(int maxHr) {
    final (lo, hi) = bpmRange(maxHr);
    final unit = MetricType.heartRate.unit;
    return '${ltr(hi == null ? '$lo+' : '$lo–$hi')} $unit';
  }
}

/// Sıcaklık farkı, işaretiyle ve seçili birimde: "+0.4 °C".
String temperatureDelta(double celsius) {
  final v = DisplayPrefs.imperial ? celsius * 9 / 5 : celsius;
  final text = v.abs().toStringAsFixed(1);
  final sign = v >= 0.05 ? '+' : (v <= -0.05 ? '−' : '±');
  return ltr('$sign$text ${MetricType.temperature.unit}');
}

TextStyle _title(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium!;

// ---------------------------------------------------------------------------
// Nabız bölgeleri
// ---------------------------------------------------------------------------

/// Verilen nabız ölçümlerinin bölgelere dağılımı. Nabız ayrıntısında ve
/// egzersiz özetinde kullanılır.
class HeartRateZonesCard extends StatelessWidget {
  const HeartRateZonesCard({
    super.key,
    required this.heartRate,
    required this.age,
  });

  /// Zamana göre sıralı nabız ölçümleri.
  final List<Measurement> heartRate;

  /// Kişisel bilgiden; bilinmiyorsa null.
  final int? age;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final a = age;
    if (a == null || a < 10 || a > 100) {
      return _Titled(
        title: l.zonesTitle,
        child: Text(l.zonesNeedsAge, style: TextStyle(color: colors.muted)),
      );
    }
    final maxHr = maxHeartRate(a);
    final zones = zoneDurations(heartRate, maxHr);
    final longest = zones.values.fold(Duration.zero, (m, d) => d > m ? d : m);
    return _Titled(
      title: l.zonesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (longest == Duration.zero)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l.zonesEmpty, style: TextStyle(color: colors.muted)),
            ),
          for (final z in HeartRateZone.values.reversed)
            _ZoneRow(
              zone: z,
              maxHr: maxHr,
              time: zones[z]!,
              share: longest == Duration.zero
                  ? 0
                  : zones[z]!.inSeconds / longest.inSeconds,
            ),
          const SizedBox(height: 8),
          Text(
            l.zonesNote('${ltr('$maxHr')} ${MetricType.heartRate.unit}'),
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zone,
    required this.maxHr,
    required this.time,
    required this.share,
  });

  final HeartRateZone zone;
  final int maxHr;
  final Duration time;
  final double share;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l = context.l10n;
    final minutes = time.inSeconds / 60;
    final timeText = time == Duration.zero
        ? l.noValue
        : duration(minutes < 1 ? 1 : minutes.round());
    final range = zone.rangeText(maxHr);
    return Semantics(
      label: l.zoneSemantics(zone.label, range, timeText),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: zone.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: zone.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: range,
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: share.clamp(0, 1).toDouble(),
                minHeight: 6,
                color: zone.color,
                backgroundColor: colors.surfaceHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vücut ısısı sapması
// ---------------------------------------------------------------------------

/// Isı ayrıntısında: seçili dönemin olağan ısıya göre farkı, sütun grafiği.
class TemperatureDeviationCard extends StatelessWidget {
  const TemperatureDeviationCard({
    super.key,
    required this.store,
    required this.range,
    this.now,
  });

  final HealthStore store;
  final PeriodRange range;

  /// Temelin hesaplandığı an (testte sabit).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final base = TemperatureBaseline.of(store, now ?? DateTime.now());
    if (base == null) {
      return _Titled(
        title: l.tempDevTitle,
        child: Text(
          l.tempDevNeedsData(TemperatureBaseline.minBaselineDays),
          style: TextStyle(color: colors.muted),
        ),
      );
    }
    final values = temperatureDeviation(store, range, base);
    final present = values.whereType<double>().toList();
    final avg = present.isEmpty
        ? null
        : present.reduce((a, b) => a + b) / present.length;
    return _Titled(
      title: l.tempDevTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            avg == null
                ? l.metricDetailNoData
                : l.tempDevAverage(temperatureDelta(avg)),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (avg != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: _DeviationChart(range: range, values: values),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l.tempDevBaseline(
              ltr(
                '${MetricType.temperature.format(base.value)} '
                '${MetricType.temperature.unit}',
              ),
              base.days,
              dayMonth(base.from),
              dayMonth(base.to),
            ),
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            l.tempDevNote,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Sıfır çizgisinin üstünde ve altında sütunlar: sıcak yukarı, serin aşağı.
class _DeviationChart extends StatelessWidget {
  const _DeviationChart({required this.range, required this.values});

  final PeriodRange range;
  final List<double?> values;

  String _label(int i) {
    final t = range.buckets[i];
    return switch (range.period) {
      Period.day => i % 6 == 0 ? two(t.hour) : '',
      Period.week => weekdayShort(t.weekday),
      Period.month => (t.day - 1) % 7 == 0 ? '${t.day}' : '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scale = DisplayPrefs.imperial ? 9 / 5 : 1.0;
    final shown = [for (final v in values) v == null ? null : v * scale];
    final peak = shown.whereType<double>().fold(
      0.5 * scale,
      (m, v) => v.abs() > m ? v.abs() : m,
    );
    final limit = (peak * 1.2 * 10).ceil() / 10;
    final axis = TextStyle(color: c.muted, fontSize: 11);
    final width = range.period == Period.month ? 5.0 : 9.0;
    return ExcludeSemantics(
      child: BarChart(
        BarChartData(
          minY: -limit,
          maxY: limit,
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: limit,
            getDrawingHorizontalLine: (v) => FlLine(
              color: v == 0 ? c.muted.withValues(alpha: 0.5) : c.grid,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: limit,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    v == 0
                        ? '0'
                        : (v > 0 ? '+' : '−') + v.abs().toStringAsFixed(1),
                    style: axis,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_label(v.toInt()), style: axis),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < shown.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    fromY: 0,
                    toY: shown[i] ?? 0,
                    width: width,
                    color: (shown[i] ?? 0) >= 0
                        ? DataColors.temperature
                        : DataColors.oxygen,
                    borderRadius: BorderRadius.circular(width / 2),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Biyolojik yaş
// ---------------------------------------------------------------------------

extension AgeFactorLook on AgeFactor {
  String get label {
    final l = currentL10n;
    return switch (this) {
      AgeFactor.restingHeartRate => l.bioAgeRestingHr,
      AgeFactor.steps => l.bioAgeSteps,
      AgeFactor.sleep => l.bioAgeSleep,
      AgeFactor.bmi => l.bioAgeBmi,
    };
  }

  String valueText(double v) => switch (this) {
    AgeFactor.restingHeartRate =>
      '${ltr(v.round().toString())} ${MetricType.heartRate.unit}',
    AgeFactor.steps => ltr(v.round().toString()),
    AgeFactor.sleep => duration(v.round()),
    AgeFactor.bmi => ltr(v.toStringAsFixed(1)),
  };
}

String _bioDifference(BiologicalAge b) {
  final l = currentL10n;
  final d = b.difference;
  return d < 0
      ? l.bioAgeYounger(-d)
      : d > 0
      ? l.bioAgeOlder(d)
      : l.bioAgeSame;
}

/// İlerleme ekranında: biyolojik yaş, etkenler ve son 8 haftanın eğilimi.
class BiologicalAgeCard extends StatelessWidget {
  const BiologicalAgeCard({
    super.key,
    required this.store,
    required this.day,
    required this.age,
  });

  final HealthStore store;
  final DateTime day;
  final int? age;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final a = age;
    if (a == null || a < 18 || a > 90) {
      return _Titled(
        title: l.bioAgeTitle,
        child: Text(l.bioAgeNeedsAge, style: TextStyle(color: colors.muted)),
      );
    }
    final b = BiologicalAge.of(store, day, a);
    if (b == null) {
      return _Titled(
        title: l.bioAgeTitle,
        child: Text(
          l.bioAgeNeedsData(BiologicalAge.minDays),
          style: TextStyle(color: colors.muted),
        ),
      );
    }
    final trend = BiologicalAge.trend(store, day, a);
    final diff = _bioDifference(b);
    return _Titled(
      title: l.bioAgeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: l.bioAgeSemantics(b.age, diff),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${b.age}',
                  style: const TextStyle(
                    fontSize: 48,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diff,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: b.difference <= 0
                              ? colors.accent
                              : colors.danger,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.bioAgeChronological(b.chronologicalAge),
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final c in b.contributions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.factor.label,
                          style: TextStyle(color: colors.muted),
                        ),
                        Text(
                          c.factor.valueText(c.value),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 64),
                    child: Text(
                      l.bioAgeYears(_signed(c.years)),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.years < 0
                            ? colors.accent
                            : c.years > 0
                            ? colors.danger
                            : colors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (trend.whereType<BiologicalAge>().length >= 2) ...[
            const SizedBox(height: 12),
            Text(
              l.bioAgeTrend,
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: _TrendLine(trend: trend, day: b.day),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l.bioAgeNote,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _signed(double years) {
  final r = (years * 2).round() / 2;
  if (r == 0) return ltr('0');
  final text = r == r.roundToDouble()
      ? r.abs().toStringAsFixed(0)
      : r.abs().toStringAsFixed(1);
  return ltr('${r > 0 ? '+' : '−'}$text');
}

/// Haftalık biyolojik yaş çizgisi. Baştaki hesaplanamayan haftalar
/// atlanır; altta ilk ve son haftanın tarihi yazar.
class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.trend, required this.day});

  final List<BiologicalAge?> trend;

  /// Son noktanın günü; önceki noktalar birer hafta geride.
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = trend.indexWhere((t) => t != null);
    final values = [for (final t in trend.skip(first)) t?.age.toDouble()];
    final present = values.whereType<double>();
    final lo = present.reduce((a, b) => a < b ? a : b);
    final hi = present.reduce((a, b) => a > b ? a : b);
    final last = values.length - 1;
    final axis = TextStyle(color: c.muted, fontSize: 11);
    String label(int i) =>
        dayMonth(DateTime(day.year, day.month, day.day - 7 * (last - i)));
    return ExcludeSemantics(
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: last.toDouble(),
          minY: lo - 2,
          maxY: hi + 2,
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: c.grid, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 2,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    v == meta.min || v == meta.max ? '' : meta.formattedValue,
                    style: axis,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  final show = i == 0 || i == last;
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                    child: Text(show ? label(i) : '', style: axis),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  if (values[i] case final y?) FlSpot(i.toDouble(), y),
              ],
              color: c.accent,
              barWidth: 2.5,
              isCurved: true,
              preventCurveOverShooting: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sağlık Radarı
// ---------------------------------------------------------------------------

String _findingText(RadarFinding f) {
  final l = currentL10n;
  String hr(double v) =>
      '${ltr(v.round().toString())} ${MetricType.heartRate.unit}';
  String ms(double v) => ltr('${v.round()} ms');
  String temp(double v) =>
      ltr('${MetricType.temperature.format(v)} ${MetricType.temperature.unit}');
  String o2(double v) => l.statPercent(v.round().toString());
  return switch (f.signal) {
    RadarSignal.heartRateUp => l.radarHeartRateUp(hr(f.value), hr(f.baseline)),
    RadarSignal.hrvDown => l.radarHrvDown(ms(f.value), ms(f.baseline)),
    RadarSignal.temperatureUp => l.radarTemperatureUp(
      temp(f.value),
      temp(f.baseline),
    ),
    RadarSignal.spo2Down => l.radarSpo2Down(o2(f.value), o2(f.baseline)),
  };
}

IconData _findingIcon(RadarSignal s) => switch (s) {
  RadarSignal.heartRateUp => Icons.favorite,
  RadarSignal.hrvDown => Icons.monitor_heart,
  RadarSignal.temperatureUp => Icons.thermostat,
  RadarSignal.spo2Down => Icons.water_drop,
};

Color _findingColor(RadarSignal s) => switch (s) {
  RadarSignal.heartRateUp => DataColors.heart,
  RadarSignal.hrvDown => DataColors.hrv,
  RadarSignal.temperatureUp => DataColors.temperature,
  RadarSignal.spo2Down => DataColors.oxygen,
};

/// Son gecenin kişinin olağanından sapan değerleri. Ana Sayfa'da kısa
/// ([showNote] kapalı), İlerleme ekranında açıklamasıyla gösterilir.
class HealthRadarCard extends StatelessWidget {
  const HealthRadarCard({
    super.key,
    required this.store,
    required this.day,
    this.onTap,
    this.showNote = false,
  });

  final HealthStore store;
  final DateTime day;
  final VoidCallback? onTap;
  final bool showNote;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final r = HealthRadar.of(store, day);
    final (IconData icon, Color tone, String status) = !r.hasTonight
        ? (Icons.radar, colors.muted, l.radarNoTonight)
        : r.baselineNights < HealthRadar.minNights
        ? (
            Icons.radar,
            colors.muted,
            l.radarCollecting(r.baselineNights, HealthRadar.minNights),
          )
        : r.findings.isEmpty
        ? (Icons.check_circle_outline, colors.online, l.radarAllClear)
        : r.strong
        ? (Icons.warning_amber_rounded, colors.danger, l.radarStrong)
        : (Icons.info_outline, DataColors.temperature, l.radarWatch);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tone),
            const SizedBox(width: 10),
            Expanded(child: Text(status)),
          ],
        ),
        if (r.ready)
          for (final f in r.findings)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10, start: 4),
              child: Row(
                children: [
                  Icon(
                    _findingIcon(f.signal),
                    size: 18,
                    color: _findingColor(f.signal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _findingText(f),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        if (showNote) ...[
          const SizedBox(height: 12),
          Text(
            l.radarNote,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ],
    );
    final tap = onTap;
    if (tap == null) return _Titled(title: l.radarTitle, child: body);
    return Pressable(
      semanticLabel: '${l.radarTitle}. $status',
      onTap: tap,
      child: _Titled(title: l.radarTitle, trailing: true, child: body),
    );
  }
}

/// Başlıklı cam kart.
class _Titled extends StatelessWidget {
  const _Titled({
    required this.title,
    required this.child,
    this.trailing = false,
  });

  final String title;
  final Widget child;
  final bool trailing;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: _title(context))),
            if (trailing)
              Icon(Icons.chevron_right, color: context.colors.muted),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
