import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/insights.dart';
import 'ai_report_screen.dart';

extension EnergyLevelText on EnergyLevel {
  String get label => switch (this) {
    EnergyLevel.high => currentL10n.energyHigh,
    EnergyLevel.medium => currentL10n.energyMedium,
    EnergyLevel.low => currentL10n.energyLow,
  };
}

extension AchievementLook on AchievementKind {
  String get title {
    final l = currentL10n;
    return switch (this) {
      AchievementKind.firstSync => l.achFirstSync,
      AchievementKind.steps10k => l.achSteps10k,
      AchievementKind.steps20k => l.achSteps20k,
      AchievementKind.goalStreak7 => l.achGoalStreak7,
      AchievementKind.sleepStreak7 => l.achSleepStreak7,
      AchievementKind.workouts10 => l.achWorkouts10,
      AchievementKind.firstEcg => l.achFirstEcg,
      AchievementKind.marathonWeek => l.achMarathonWeek,
      AchievementKind.wear30 => l.achWear30,
    };
  }

  String get description {
    final l = currentL10n;
    return switch (this) {
      AchievementKind.firstSync => l.achFirstSyncText,
      AchievementKind.steps10k => l.achSteps10kText,
      AchievementKind.steps20k => l.achSteps20kText,
      AchievementKind.goalStreak7 => l.achGoalStreak7Text,
      AchievementKind.sleepStreak7 => l.achSleepStreak7Text,
      AchievementKind.workouts10 => l.achWorkouts10Text,
      AchievementKind.firstEcg => l.achFirstEcgText,
      AchievementKind.marathonWeek => l.achMarathonWeekText,
      AchievementKind.wear30 => l.achWear30Text,
    };
  }

  IconData get icon => switch (this) {
    AchievementKind.firstSync => Icons.sync,
    AchievementKind.steps10k => Icons.directions_walk,
    AchievementKind.steps20k => Icons.directions_run,
    AchievementKind.goalStreak7 => Icons.local_fire_department,
    AchievementKind.sleepStreak7 => Icons.bedtime,
    AchievementKind.workouts10 => Icons.fitness_center,
    AchievementKind.firstEcg => Icons.monitor_heart,
    AchievementKind.marathonWeek => Icons.emoji_events,
    AchievementKind.wear30 => Icons.watch,
  };
}

/// Ana Sayfa'daki enerji kartı; dokununca İlerleme ekranı açılır.
class EnergyCard extends StatelessWidget {
  const EnergyCard({super.key, required this.day, required this.onTap});

  final DateTime day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = DeviceScope.of(context).store;
    final l = context.l10n;
    final colors = context.colors;
    final e = EnergyScore.of(store, day);
    return Pressable(
      semanticLabel: e == null
          ? l.energyTitle
          : l.energySemantics(e.score, e.level.label),
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            RingProgress(
              progress: (e?.score ?? 0) / 100,
              size: 56,
              child: Text(
                e?.score.toString() ?? l.noValue,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.energyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e == null ? l.energyEmpty : e.level.label,
                    style: TextStyle(color: colors.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

/// İlerleme: günün enerjisi, haftalık rapor ve rozetler.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.day, this.now});

  /// Enerjisi gösterilecek gün; haftalık rapor bu günün haftasıyla açılır.
  final DateTime day;

  /// Rozetlerin ve "sonraki hafta" sınırının hesaplandığı an (testte sabit).
  final DateTime? now;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late DateTime _week = widget.day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = DeviceScope.of(context).store;
    final now = widget.now ?? DateTime.now();
    return CamScaffold(
      appBar: AppBar(title: Text(l.progressTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final energy = EnergyScore.of(store, widget.day);
            final report = WeeklyReport.of(store, _week);
            final canGoForward = report.current.range.end.isBefore(now);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _EnergySection(energy: energy, day: widget.day),
                const SizedBox(height: 12),
                HealthRadarCard(store: store, day: widget.day, showNote: true),
                const SizedBox(height: 12),
                BiologicalAgeCard(
                  store: store,
                  day: widget.day,
                  age: DeviceScope.of(context).profile?.age,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.weeklyReportTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l.metricDetailPrevious,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(
                        () => _week = report.current.range.shift(-1).start,
                      ),
                    ),
                    IconButton(
                      tooltip: l.metricDetailNext,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: canGoForward
                          ? () => setState(
                              () => _week = report.current.range.shift(1).start,
                            )
                          : null,
                    ),
                  ],
                ),
                Text(
                  l.metricDetailWeekRange(
                    dayMonth(report.current.range.start),
                    dayMonth(
                      report.current.range.end.subtract(
                        const Duration(days: 1),
                      ),
                    ),
                  ),
                  style: TextStyle(color: context.colors.muted),
                ),
                const SizedBox(height: 12),
                _WeeklyReportCard(report: report),
                const SizedBox(height: 12),
                AiReportCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AiReportScreen(day: _week),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l.achievementsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _AchievementGrid(items: achievements(store, now)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EnergySection extends StatelessWidget {
  const _EnergySection({required this.energy, required this.day});

  final EnergyScore? energy;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final e = energy;
    Widget part(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.energyDayTitle(dayMonth(day)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: RingProgress(
              progress: (e?.score ?? 0) / 100,
              size: 120,
              child: Text(
                e?.score.toString() ?? l.noValue,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            e == null ? l.energyEmpty : e.level.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (e != null) ...[
            const SizedBox(height: 12),
            part(l.energySleep, e.sleepScore?.toString() ?? l.noValue),
            part(l.energyRecovery, e.recoveryScore?.toString() ?? l.noValue),
            part(l.energyDrain, ltr('−${e.drain}')),
          ],
          const SizedBox(height: 12),
          Text(l.energyNote, style: TextStyle(color: colors.muted)),
        ],
      ),
    );
  }
}

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final now = report.current;
    final before = report.previous;
    if (now.isEmpty) {
      return GlassCard(
        child: Text(l.reportEmpty, style: TextStyle(color: colors.muted)),
      );
    }

    /// Bir satır: ad, değer ve önceki haftaya göre değişim.
    Widget row(
      String label,
      String value,
      int? change, {
      bool lowerIsBetter = false,
    }) {
      final up = change != null && change > 0;
      final good = change == null || change == 0 ? null : up != lowerIsBetter;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(color: colors.muted)),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(
              width: 72,
              child: change == null || change == 0
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          up ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: good == true ? colors.accent : colors.danger,
                          semanticLabel: up ? l.reportUp : l.reportDown,
                        ),
                        Text(
                          l.statPercent(change.abs().toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: good == true ? colors.accent : colors.danger,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    final sleep = now.averageSleepMinutes;
    final hrv = now.averageHrv;
    final stress = now.averageStress;
    return GlassCard(
      child: Column(
        children: [
          row(
            l.reportSteps,
            now.steps.toString(),
            WeeklyReport.change(now.steps, before.steps),
          ),
          row(
            l.reportAverageSteps,
            now.averageSteps?.toString() ?? l.noValue,
            WeeklyReport.change(now.averageSteps, before.averageSteps),
          ),
          row(
            l.reportGoalDays,
            ltr('${now.goalDays}/7'),
            WeeklyReport.change(now.goalDays, before.goalDays),
          ),
          row(
            l.reportSleep,
            sleep == null ? l.noValue : duration(sleep.round()),
            WeeklyReport.change(sleep, before.averageSleepMinutes),
          ),
          row(
            l.reportHrv,
            hrv == null ? l.noValue : '${hrv.round()} ms',
            WeeklyReport.change(hrv, before.averageHrv),
          ),
          row(
            l.reportStress,
            stress == null ? l.noValue : stress.round().toString(),
            WeeklyReport.change(stress, before.averageStress),
            lowerIsBetter: true,
          ),
          row(
            l.reportWorkouts,
            now.workouts == 0
                ? l.noValue
                : l.reportWorkoutsValue(
                    now.workouts,
                    duration(now.workoutMinutes),
                  ),
            WeeklyReport.change(now.workoutMinutes, before.workoutMinutes),
          ),
          const SizedBox(height: 4),
          Text(
            l.reportVsPrevious,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({required this.items});

  final List<Achievement> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        // Dar ekranda ya da büyük yazıda tek sütun.
        final twoColumns =
            constraints.maxWidth >= 340 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final width = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final a in items)
              SizedBox(
                width: width,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: a.earned ? colors.glow : colors.surfaceHigh,
                        ),
                        child: Icon(
                          a.kind.icon,
                          color: a.earned ? colors.accent : colors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        a.kind.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.kind.description,
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      if (a.earnedOn case final on?)
                        Text(
                          l.achievementEarned(dayMonth(on)),
                          style: TextStyle(color: colors.accent, fontSize: 12),
                        )
                      else
                        LinearProgressIndicator(
                          value: a.progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          // Değer, ekran okuyucu için çubuğun kendi yüzdesi.
                          semanticsLabel: l.achievementProgress,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
