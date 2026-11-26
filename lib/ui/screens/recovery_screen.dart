import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../../data/recovery.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/score_dial.dart';

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
  late PeriodRange _range = PeriodRange.of(Period.week, widget.day);

  static List<ScoreBand> get bands => [
    for (final level in RecoveryLevel.values)
      ScoreBand(
        level.floor.toDouble(),
        level == RecoveryLevel.excellent
            ? 100
            : RecoveryLevel.values[level.index - 1].floor.toDouble(),
        level.color,
        level.label,
      ),
  ];

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
            final series = [
              for (final (d, v) in DayRecovery.series(store, _range, now: now))
                (d, v?.toDouble()),
            ];
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
                  ScoreRing(
                    title: l.homeDailyRecovery,
                    value: l.homePercent(r.score),
                    levelLabel: r.level.label,
                    color: r.level.color,
                    fraction: r.score / 100,
                    optimal: const (DayRecovery.optimal / 100, 1),
                    semantics: l.recoveryRingSemantics(
                      l.homePercent(r.score),
                      r.level.label,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScoreLegend(bands: bands, optimalLabel: l.recoveryOptimal),
                  const SizedBox(height: 16),
                  AssessmentCard(
                    title: l.recoveryAssessment,
                    lines: [
                      r.level.comment,
                      if (r.hrvLow) l.recoveryHrvLow,
                      if (r.restingHigh) l.recoveryRhrHigh,
                    ],
                    note: l.recoveryNote,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.recoveryIndicators,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ..._indicators(context, r),
                ],
                const SizedBox(height: 16),
                TrendHeader(
                  title: l.recoveryTrend,
                  range: _range,
                  now: now,
                  anchor: widget.day,
                  onRange: (r) => setState(() => _range = r),
                ),
                gap,
                GlassCard(
                  child: ScoreTrendChart(
                    series: series,
                    range: _range,
                    max: 100,
                    ticks: const [0, 40, 60, 75, 90, 100],
                    bands: bands,
                    valueText: (v) => v.round().toString(),
                    semantics: (avg) => avg == null
                        ? l.recoveryTrendEmpty
                        : l.recoveryTrendSemantics(
                            l.recoveryRange(
                              dayMonth(_range.start),
                              dayMonth(
                                _range.end.subtract(const Duration(days: 1)),
                              ),
                            ),
                            l.homePercent(avg.round()),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _indicators(BuildContext context, DayRecovery r) {
    final l = context.l10n;
    final bpm = MetricType.heartRate.unit;
    String n(num v) => ltr(v.round().toString());
    return [
      if (r.restingHeartRate case final v?)
        IndicatorRow(
          icon: Icons.favorite,
          color: DataColors.heart,
          label: l.recoveryRestingHr,
          value: n(v),
          unit: bpm,
          caption: r.restingBaseline == null
              ? null
              : l.recoveryUsual('${n(r.restingBaseline!)} $bpm'),
        ),
      if (r.hrv case final v?)
        IndicatorRow(
          icon: Icons.monitor_heart_outlined,
          color: DataColors.hrv,
          label: l.recoveryHrv,
          value: n(v),
          unit: MetricType.hrv.unit,
          caption: r.hrvBaseline == null
              ? null
              : l.recoveryUsual('${n(r.hrvBaseline!)} ${MetricType.hrv.unit}'),
        ),
      if (r.stress case final v?)
        IndicatorRow(
          icon: Icons.self_improvement,
          color: DataColors.stress,
          label: l.recoveryStress,
          value: n(v),
        ),
      if (r.sleepScore case final v?)
        IndicatorRow(
          icon: Icons.bedtime,
          color: DataColors.sleepLight,
          label: l.recoverySleepScore,
          value: n(v),
        ),
    ];
  }
}
