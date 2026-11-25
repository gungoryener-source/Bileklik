import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/ecg_analysis.dart';
import '../../data/hrv_analysis.dart';
import '../../data/models.dart';
import '../../data/progress.dart';
import '../../device/protocol/history.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'body_screen.dart';
import 'ecg_screen.dart';
import 'metric_detail_screen.dart';
import 'sleep_screen.dart';
import 'spot_measure_screen.dart';

/// Sağlık sekmesi: üstte günün hareket halkaları, altında her ölçümün
/// kartı (son değer, durum, saat ve gün içi mini grafik). Karta dokununca
/// ayrıntı açılır; bileklikle ölçülebilen kartlarda "Ölçüm" düğmesi var.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final store = c.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final today = PeriodRange.of(Period.day, now);
        final l = context.l10n;

        double total(MetricType t) => store
            .measurements(t, today.start, today.end)
            .fold(0.0, (s, m) => s + m.value);

        List<double?> hourly(MetricType t) =>
            aggregate(store.measurements(t, today.start, today.end), today, t);

        String? timeOf(DateTime? t) => t == null
            ? null
            : DateUtils.isSameDay(t, now)
            ? hhmm(t)
            : dayMonth(t);

        void open(Widget screen) =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen));

        void openDetail(
          MetricType type, {
          MetricType? secondary,
          String? title,
        }) => open(
          MetricDetailScreen(type: type, secondary: secondary, title: title),
        );

        /// Bileklikten gelen tek değerli ölçüm kartı.
        Widget metric(
          MetricType type, {
          bool line = false,
          VoidCallback? onMeasure,
        }) {
          final latest = store.latest(type);
          final percent = type.symbol == '%';
          return _MetricCard(
            title: type.label,
            icon: type.icon,
            color: type.color,
            time: timeOf(latest?.time),
            value: latest == null
                ? null
                : percent
                ? l.statPercent(type.format(latest.value))
                : type.format(latest.value),
            unit: percent ? '' : type.unit,
            status: latest == null
                ? l.healthNoMeasurement
                : bandOf(type, latest.value)?.label,
            chart: onMeasure == null
                ? _MiniChart(
                    values: hourly(type),
                    color: type.color,
                    line: line,
                  )
                : null,
            action: onMeasure == null
                ? null
                : _CardAction(
                    l.healthMeasure,
                    Icons.monitor_heart_outlined,
                    onMeasure,
                  ),
            onTap: () => openDetail(type),
          );
        }

        Widget bloodPressure() {
          final sys = store.latest(MetricType.systolic);
          final dia = store.latest(MetricType.diastolic);
          final band = sys == null
              ? null
              : bandOf(MetricType.systolic, sys.value);
          return _MetricCard(
            title: l.healthBloodPressure,
            icon: MetricType.systolic.icon,
            color: MetricType.systolic.color,
            time: timeOf(sys?.time),
            value: sys == null || dia == null
                ? null
                : '${MetricType.systolic.format(sys.value)}/'
                      '${MetricType.diastolic.format(dia.value)}',
            unit: MetricType.systolic.unit,
            status: sys == null
                ? l.healthNoMeasurement
                : band == null
                ? l.healthEstimated
                : l.healthBloodPressureSubtitle(band.label),
            chart: _MiniChart(
              values: hourly(MetricType.systolic),
              color: MetricType.systolic.color,
            ),
            onTap: () => openDetail(
              MetricType.systolic,
              secondary: MetricType.diastolic,
              title: l.healthBloodPressure,
            ),
          );
        }

        Widget sleep() {
          final night = NightSleep.group(
            store.sleepBetween(now.subtract(const Duration(days: 2)), now),
          ).lastOrNull;
          final minutes = night?.asleepMinutes;
          return _MetricCard(
            title: l.healthSleep,
            icon: Icons.bedtime,
            color: DataColors.sleepLight,
            time: timeOf(night?.end),
            value: minutes == null ? null : duration(minutes),
            unit: '',
            status: minutes == null
                ? l.healthNoRecord
                : minutes < 6 * 60
                ? l.healthSleepShort
                : minutes > 9 * 60
                ? l.healthSleepLong
                : l.healthSleepGood,
            chart: night == null ? null : _SleepBar(night),
            onTap: () => open(const SleepScreen()),
          );
        }

        Widget vo2() {
          final age = c.profile?.age;
          final resting = restingHeartRate(store, now);
          final v = age == null || resting == null
              ? null
              : estimateVo2Max(age: age, restingHeartRate: resting);
          return _MetricCard(
            title: l.vo2MaxTitle,
            icon: Icons.air,
            color: DataColors.oxygen,
            value: v?.toStringAsFixed(1),
            unit: v == null ? '' : l.healthVo2Unit,
            status: v == null ? l.healthVo2NeedsData : l.healthEstimated,
            onTap: () => openDetail(MetricType.hrv),
          );
        }

        Widget weight() {
          final w = store.latest(MetricType.weight);
          final bmi = w == null
              ? null
              : store
                    .measurements(
                      MetricType.bmi,
                      w.time,
                      w.time.add(const Duration(milliseconds: 1)),
                    )
                    .firstOrNull;
          return _MetricCard(
            title: MetricType.weight.label,
            icon: MetricType.weight.icon,
            color: MetricType.weight.color,
            time: timeOf(w?.time),
            value: w == null ? null : MetricType.weight.format(w.value),
            unit: MetricType.weight.unit,
            status: w == null
                ? l.healthWeightPrompt
                : bmi == null
                ? null
                : l.healthWeightBmi(
                    MetricType.bmi.format(bmi.value),
                    whenText(w.time, now),
                  ),
            action: _CardAction(
              l.healthAdd,
              Icons.add,
              () => addBodyEntry(context),
            ),
            onTap: () => open(const BodyScreen()),
          );
        }

        Widget ecg() {
          final last = store.ecgRecordings().firstOrNull;
          final f = last == null
              ? null
              : EcgFindings.of(
                  EcgSummary.analyze(last.samples, last.sampleRate),
                );
          return _MetricCard(
            title: l.healthEcg,
            icon: Icons.monitor_heart,
            color: DataColors.heart,
            time: last == null
                ? null
                : l.ecgReportWhen(dayMonth(last.start), hhmm(last.start)),
            value: f == null
                ? null
                : !f.assessable
                ? l.healthEcgUnassessed
                : f.normalRhythm == FindingState.ok
                ? l.ecgFindingNormalOk
                : l.ecgFindingNormalFlagged,
            valueIsText: true,
            unit: '',
            status: last?.averageHeartRate == null
                ? (last == null ? l.healthEcgPrompt : null)
                : l.ecgAverageBpm(last!.averageHeartRate!),
            action: _CardAction(
              l.healthMeasure,
              Icons.monitor_heart_outlined,
              () => c.isConnected
                  ? open(const EcgPrepareScreen())
                  : ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l.ecgConnectFirst))),
            ),
            onTap: () => open(const EcgScreen()),
          );
        }

        return RefreshIndicator(
          onRefresh: c.sync,
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              20,
              20,
              20,
              GlassNavBar.clearance(context),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.navHealth,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (c.syncing)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: l.healthSyncTooltip,
                      onPressed: c.isConnected ? c.sync : null,
                      icon: const Icon(Icons.sync),
                    ),
                ],
              ),
              Text(
                c.lastSync == null
                    ? (c.isConnected ? l.healthSyncing : l.healthConnectHint)
                    : l.healthLastSync(hhmm(c.lastSync!)),
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 16),
              _ActivityCard(
                steps: total(MetricType.steps),
                calories: total(MetricType.calories),
                distanceKm: total(MetricType.distance),
                onTap: () => openDetail(MetricType.steps),
              ),
              metric(MetricType.heartRate, line: true),
              metric(
                MetricType.spo2,
                onMeasure: () => startSpotMeasurement(context, MetricType.spo2),
              ),
              sleep(),
              metric(MetricType.hrv),
              metric(MetricType.temperature, line: true),
              metric(MetricType.stress),
              metric(MetricType.respiratoryRate, line: true),
              bloodPressure(),
              vo2(),
              weight(),
              ecg(),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hareket kartı
// ---------------------------------------------------------------------------

/// Günün adım, kalori ve mesafesi; hedefe göre iç içe üç halka.
class _ActivityCard extends StatelessWidget {
  /// Halkalar birbirinden ayrılsın diye adım, kalori ve mesafe için ayrı
  /// veri renkleri (adım ve mesafenin kendi renkleri aynı tondadır).
  static const ringColors = [
    DataColors.oxygen,
    DataColors.steps,
    DataColors.temperature,
  ];

  const _ActivityCard({
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.onTap,
  });

  final double steps;
  final double calories;
  final double distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rows = [
      (
        MetricType.steps,
        steps.round().toString(),
        '$dailyStepGoal',
        steps / dailyStepGoal,
      ),
      (
        MetricType.calories,
        calories.round().toString(),
        '$dailyCalorieGoal',
        calories / dailyCalorieGoal,
      ),
      (
        MetricType.distance,
        distanceValue(distanceKm),
        distanceValue(dailyDistanceGoalKm),
        distanceKm / dailyDistanceGoalKm,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        semanticLabel: [
          for (final (type, value, goal, _) in rows)
            '${type.label} $value ${l.healthGoalValue(goal)}',
        ].join(', '),
        child: GlassCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, (type, value, goal, _)) in rows.indexed) ...[
                      Row(
                        children: [
                          _IconChip(type.icon, ringColors[i], size: 26),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              type == MetricType.steps || type.unit.isEmpty
                                  ? type.label
                                  : '${type.label} (${type.unit})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.colors.muted),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 34,
                          top: 2,
                          bottom: 10,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: value,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${l.healthGoalValue(goal)}',
                                  style: TextStyle(
                                    color: context.colors.muted,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ActivityRings(
                progress: [for (final r in rows) r.$4],
                colors: ringColors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İç içe ilerleme halkaları; dıştan içe verilen sırayla.
class _ActivityRings extends StatelessWidget {
  const _ActivityRings({required this.progress, required this.colors});

  final List<double> progress;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 132,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => CustomPaint(
            painter: _RingsPainter(
              [for (final p in progress) p.clamp(0.0, 1.0) * t],
              colors,
              Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.progress, this.colors, this.direction);

  final List<double> progress;
  final List<Color> colors;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0, gap = 4.0;
    final center = size.center(Offset.zero);
    final sign = direction == TextDirection.rtl ? -1 : 1;
    for (var i = 0; i < progress.length; i++) {
      final r = size.width / 2 - stroke / 2 - i * (stroke + gap);
      final rect = Rect.fromCircle(center: center, radius: r);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(
        center,
        r,
        paint..color = colors[i].withValues(alpha: 0.16),
      );
      if (progress[i] > 0) {
        canvas.drawArc(
          rect,
          -pi / 2,
          sign * max(progress[i], 0.01) * 2 * pi,
          false,
          paint..color = colors[i],
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.direction != direction ||
      !_listEquals(old.progress, progress) ||
      !_listEquals(old.colors, colors);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// Ölçüm kartı
// ---------------------------------------------------------------------------

/// Kartın sağ altındaki düğme (ör. "Ölçüm", "Ekle").
class _CardAction {
  const _CardAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Renkli başlık ve saat; altında büyük değer, durum metni ve sağda mini
/// grafik ya da düğme.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.onTap,
    this.time,
    this.status,
    this.chart,
    this.action,
    this.valueIsText = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? time;
  final String? value;
  final String unit;
  final String? status;
  final Widget? chart;
  final _CardAction? action;
  final VoidCallback onTap;

  /// Değer sayı değil cümle (EKG bulgusu); daha küçük yazılır.
  final bool valueIsText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final shown = value ?? context.l10n.noValue;
    final valueStyle = valueIsText && value != null
        ? text.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        : const TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _IconChip(icon, color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (time != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Text(
                          time!,
                          style: text.bodySmall?.copyWith(color: colors.muted),
                        ),
                      ),
                    Icon(Icons.chevron_right, color: colors.muted, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: shown, style: valueStyle),
                                  if (unit.isNotEmpty && value != null)
                                    TextSpan(
                                      text: ' $unit',
                                      style: TextStyle(
                                        color: colors.muted,
                                        fontSize: 15,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (status != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              status!,
                              style: text.bodyMedium?.copyWith(
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(width: 12),
                      // Dar ekranda ve büyük yazıda değerle yarı yarıya
                      // paylaşır; uzun etiket kısaltılır.
                      Flexible(
                        child: OutlinedButton.icon(
                          onPressed: action!.onTap,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 16,
                            ),
                            foregroundColor: colors.text,
                            side: BorderSide(color: colors.outline),
                          ),
                          icon: Icon(action!.icon, size: 18),
                          label: Text(
                            action!.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ] else if (chart != null) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: SizedBox(width: 128, height: 52, child: chart),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuvarlatılmış kare içinde ölçümün simgesi.
class _IconChip extends StatelessWidget {
  const _IconChip(this.icon, this.color, {this.size = 34});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(icon, color: color, size: size * 0.58),
  );
}

/// Gün içindeki saatlik değerler: çubuk ya da çizgi. Değer yoksa boş zemin.
class _MiniChart extends StatelessWidget {
  const _MiniChart({
    required this.values,
    required this.color,
    this.line = false,
  });

  final List<double?> values;
  final Color color;
  final bool line;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _MiniChartPainter(
        values,
        color,
        line,
        context.colors.surfaceHigh,
        Directionality.of(context),
      ),
    ),
  );
}

class _MiniChartPainter extends CustomPainter {
  _MiniChartPainter(
    this.values,
    this.color,
    this.line,
    this.background,
    this.direction,
  );

  final List<double?> values;
  final Color color;
  final bool line;
  final Color background;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = background,
    );
    final present = values.nonNulls.toList();
    if (present.isEmpty || values.isEmpty) return;
    var lo = present.reduce(min), hi = present.reduce(max);
    if (hi - lo < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    const pad = 6.0;
    final w = size.width - 2 * pad, h = size.height - 2 * pad;
    final step = w / values.length;
    double x(int i) {
      final ltr = pad + (i + 0.5) * step;
      return direction == TextDirection.rtl ? size.width - ltr : ltr;
    }

    // En küçük değer de görünsün diye çubuklar yüksekliğin %15'inden başlar.
    double y(double v) => pad + h - (0.15 + 0.85 * (v - lo) / (hi - lo)) * h;

    if (line) {
      final path = Path();
      var started = false;
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        if (v == null) continue;
        started ? path.lineTo(x(i), y(v)) : path.moveTo(x(i), y(v));
        started = true;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      final last = values.lastIndexWhere((v) => v != null);
      canvas.drawCircle(
        Offset(x(last), y(values[last]!)),
        3.5,
        Paint()..color = color,
      );
    } else {
      final bar = Paint()
        ..color = color
        ..strokeWidth = max(2.0, step * 0.55)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < values.length; i++) {
        final v = values[i];
        if (v == null) continue;
        canvas.drawLine(Offset(x(i), pad + h), Offset(x(i), y(v)), bar);
      }
    }
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) =>
      old.color != color ||
      old.line != line ||
      old.background != background ||
      old.direction != direction ||
      old.values.length != values.length ||
      !identical(old.values, values);
}

/// Gecenin evre oranları tek yatay çubukta: derin, hafif, REM, uyanık.
class _SleepBar extends StatelessWidget {
  const _SleepBar(this.night);

  final NightSleep night;

  @override
  Widget build(BuildContext context) {
    const order = [
      SleepStage.deep,
      SleepStage.light,
      SleepStage.rem,
      SleepStage.awake,
    ];
    return ExcludeSemantics(
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in order)
                  if (night.minutesIn(s) > 0)
                    Expanded(
                      flex: night.minutesIn(s),
                      child: ColoredBox(color: s.color),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
