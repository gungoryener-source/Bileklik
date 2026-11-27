import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../../data/strain.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/score_dial.dart';

extension StrainLevelLook on StrainLevel {
  String get label {
    final l = currentL10n;
    return switch (this) {
      StrainLevel.veryLow => l.strainVeryLow,
      StrainLevel.normal => l.strainNormal,
      StrainLevel.moderate => l.strainModerate,
      StrainLevel.high => l.strainHigh,
      StrainLevel.overloaded => l.strainOverloaded,
    };
  }

  Color get color => switch (this) {
    StrainLevel.veryLow => DataColors.steps,
    StrainLevel.normal => DataColors.oxygen,
    StrainLevel.moderate => DataColors.body,
    StrainLevel.high => DataColors.temperature,
    StrainLevel.overloaded => DataColors.heart,
  };

  String get comment {
    final l = currentL10n;
    return switch (this) {
      StrainLevel.veryLow => l.strainCommentVeryLow,
      StrainLevel.normal => l.strainCommentNormal,
      StrainLevel.moderate => l.strainCommentModerate,
      StrainLevel.high => l.strainCommentHigh,
      StrainLevel.overloaded => l.strainCommentOverloaded,
    };
  }
}

/// Günlük yük (0–21): halka ve toparlanmaya göre ideal aralık, AI yorumu,
/// yük göstergeleri (uyku, ortalama nabız, adım, kalori) ve haftalık/aylık
/// eğilim. Bilekliğin vermediği gösterge gizlenir.
class StrainScreen extends StatefulWidget {
  const StrainScreen({super.key, required this.day, this.now});

  final DateTime day;

  /// Testler için "şimdi"; gelecekteki günler çizilmez.
  final DateTime? now;

  static List<ScoreBand> get bands => [
    for (final level in StrainLevel.values)
      ScoreBand(level.floor, level.ceiling, level.color, level.label),
  ];

  @override
  State<StrainScreen> createState() => _StrainScreenState();
}

class _StrainScreenState extends State<StrainScreen> {
  late PeriodRange _range = PeriodRange.of(Period.week, widget.day);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = DeviceScope.of(context);
    final store = c.store;
    final age = c.profile?.age;
    final now = widget.now ?? DateTime.now();
    return CamScaffold(
      appBar: AppBar(title: Text(l.homeDailyLoad)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final s = DayStrain.of(store, widget.day, age: age);
            final series = DayStrain.series(store, _range, age: age, now: now);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (s == null)
                  GlassCard(
                    child: Text(
                      l.strainEmpty,
                      style: TextStyle(color: context.colors.muted),
                    ),
                  )
                else ...[
                  ScoreRing(
                    title: l.homeDailyLoad,
                    value: ltr(oneDecimal(s.score)),
                    levelLabel: s.level.label,
                    color: s.level.color,
                    fraction: s.score / DayStrain.max,
                    optimal: switch (s.optimal) {
                      (final lo, final hi) => (
                        lo / DayStrain.max,
                        hi / DayStrain.max,
                      ),
                      null => null,
                    },
                    semantics: l.strainRingSemantics(
                      oneDecimal(s.score),
                      s.level.label,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScoreLegend(
                    bands: StrainScreen.bands,
                    optimalLabel: s.optimal == null ? null : l.recoveryOptimal,
                  ),
                  const SizedBox(height: 16),
                  AssessmentCard(
                    title: l.strainAiTitle,
                    lines: [
                      s.level.comment,
                      if (s.optimal case (final lo, final hi)
                          when s.belowOptimal)
                        l.strainBelowOptimal(ltr(_short(lo)), ltr(_short(hi))),
                      if (s.optimal case (final lo, final hi)
                          when s.aboveOptimal)
                        l.strainAboveOptimal(ltr(_short(lo)), ltr(_short(hi))),
                    ],
                    note: l.strainNote,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.strainIndicators,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (s.sleepMinutes case final minutes?)
                    _SleepRow(s: s, minutes: minutes),
                  _Tiles(s: s),
                ],
                const SizedBox(height: 16),
                TrendHeader(
                  title: l.recoveryTrend,
                  range: _range,
                  now: now,
                  anchor: widget.day,
                  onRange: (r) => setState(() => _range = r),
                ),
                const SizedBox(height: CamSpace.gap),
                GlassCard(
                  child: ScoreTrendChart(
                    series: series,
                    range: _range,
                    max: DayStrain.max,
                    ticks: const [0, 5, 9, 13, 17, 21],
                    bands: StrainScreen.bands,
                    valueText: _short,
                    semantics: (avg) => avg == null
                        ? l.recoveryTrendEmpty
                        : l.strainTrendSemantics(
                            l.recoveryRange(
                              dayMonth(_range.start),
                              dayMonth(
                                _range.end.subtract(const Duration(days: 1)),
                              ),
                            ),
                            oneDecimal(avg),
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
}

/// Tam sayıysa ondalıksız ("10"), değilse bir ondalık ("8,2").
String _short(double v) =>
    v == v.roundToDouble() ? v.round().toString() : oneDecimal(v);

/// Uyku satırı: yatış ve kalkış saati, süre.
class _SleepRow extends StatelessWidget {
  const _SleepRow({required this.s, required this.minutes});

  final DayStrain s;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final muted = context.colors.muted;
    final small = TextStyle(
      color: muted,
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final value = duration(minutes);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: [
          l.strainSleep,
          if (s.sleepStart != null && s.sleepEnd != null)
            l.recoveryRange(hhmm(s.sleepStart!), hhmm(s.sleepEnd!)),
          value,
        ].join(', '),
        excludeSemantics: true,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              if (s.sleepStart != null && s.sleepEnd != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hhmm(s.sleepStart!), style: small),
                        const SizedBox(width: 6),
                        Icon(Icons.bedtime_outlined, size: 16, color: muted),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hhmm(s.sleepEnd!), style: small),
                        const SizedBox(width: 6),
                        Icon(Icons.wb_twilight, size: 16, color: muted),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14),
              ],
              Flexible(
                child: Text(
                  l.strainSleep,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ortalama nabız, adım, kalori ve egzersiz kutuları; olmayan gizlenir.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.s});

  final DayStrain s;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tiles = <(IconData, Color, String, String)>[
      if (s.averageHeartRate case final hr?)
        (
          Icons.monitor_heart,
          DataColors.heart,
          ltr('$hr'),
          '${l.strainAvgHr} (${MetricType.heartRate.unit})',
        ),
      if (s.steps > 0)
        (
          Icons.directions_walk,
          DataColors.steps,
          ltr('${s.steps}'),
          l.strainSteps,
        ),
      if (s.calories > 0)
        (
          Icons.local_fire_department,
          DataColors.temperature,
          ltr(s.calories.round().toString()),
          l.strainKcal,
        ),
      if (s.workoutMinutes > 0)
        (
          Icons.fitness_center,
          DataColors.oxygen,
          duration(s.workoutMinutes),
          l.strainWorkout,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    final rows = <List<(IconData, Color, String, String)>>[
      for (var i = 0; i < tiles.length; i += 3)
        tiles.sublist(i, i + 3 > tiles.length ? tiles.length : i + 3),
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (icon, color, value, label)) in row.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label: '$label $value',
                      excludeSemantics: true,
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            Icon(icon, color: color),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.colors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                for (var i = row.length; i < 3; i++) ...[
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
