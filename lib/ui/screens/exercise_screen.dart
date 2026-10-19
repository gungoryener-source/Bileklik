import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../device/protocol/exercise.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import 'live_exercise_screen.dart';
import 'workout_detail_screen.dart';

/// Egzersiz sekmesi: spor seçip başlatma ve geçmiş egzersizler.
class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  Future<void> _start(BuildContext context, SportType type) async {
    final c = DeviceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    if (!c.isConnected) {
      messenger.showSnackBar(SnackBar(content: Text(l.exerciseConnectFirst)));
      return;
    }
    if (await c.startExercise(type)) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const LiveExerciseScreen()),
      );
    } else if (issueText(c) case final issue?) {
      messenger.showSnackBar(SnackBar(content: Text(issue)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final active = c.exercise;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: c.store,
      builder: (context, _) {
        final now = DateTime.now();
        final workouts = c.store.workoutsBetween(
          now.subtract(const Duration(days: 30)),
          now,
        );
        final week = workouts.where(
          (w) => w.start.isAfter(now.subtract(const Duration(days: 7))),
        );
        final weekMinutes = week.fold(
          0,
          (sum, w) => sum + w.duration.inMinutes,
        );
        final weekKcal = week.fold(0.0, (sum, w) => sum + w.calories);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l.navExercise,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (active != null) ...[
              Card(
                color: context.colors.accent.withValues(alpha: 0.18),
                child: ListTile(
                  leading: Icon(active.type.icon, color: context.colors.accent),
                  title: Text(l.exerciseInProgress(active.type.label)),
                  subtitle: Text(
                    active.paused
                        ? l.exercisePausedAt(clock(active.elapsed))
                        : clock(active.elapsed),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LiveExerciseScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _WeekStat(l.exerciseThisWeek, l.exerciseCount(week.length)),
                const SizedBox(width: 10),
                _WeekStat(l.statDuration, duration(weekMinutes)),
                const SizedBox(width: 10),
                _WeekStat(
                  MetricType.calories.label,
                  ltr('${weekKcal.round()} ${MetricType.calories.unit}'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l.exerciseStart,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                // Simge + iki satır ad; yükseklik yazı boyutuyla büyür,
                // böylece büyük yazıda ve uzun adlarda (Almanca) taşmaz.
                mainAxisExtent:
                    48 + MediaQuery.textScalerOf(context).scale(12) * 1.4 * 2,
              ),
              children: [
                for (final s in SportType.startable)
                  _SportButton(
                    type: s,
                    onTap: active == null ? () => _start(context, s) : null,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l.exerciseLast30Days,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (workouts.isEmpty)
              Text(
                c.isConnected ? l.exerciseEmpty : l.exerciseConnectHint,
                style: TextStyle(color: context.colors.muted),
              ),
            for (final w in workouts) _WorkoutTile(w),
          ],
        );
      },
    );
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            // Uzun değer ("4 Trainings", "2 Std. 18 Min.") kesilmez, küçülür.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SportButton extends StatelessWidget {
  const _SportButton({required this.type, required this.onTap});
  final SportType type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type.icon,
                color: enabled ? context.colors.accent : context.colors.muted,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  type.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile(this.w);
  final Workout w;

  @override
  Widget build(BuildContext context) {
    final details = [
      clock(w.duration),
      if (w.distanceKm > 0)
        '${w.distanceKm.toStringAsFixed(2)} ${MetricType.distance.unit}',
      '${w.calories.round()} ${MetricType.calories.unit}',
    ].map(ltr).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.accent.withValues(alpha: 0.15),
            child: Icon(sportIcon(w.type), color: context.colors.accent),
          ),
          title: Text(sportLabel(w.type)),
          subtitle: Text('${whenText(w.start, DateTime.now())}\n$details'),
          isThreeLine: true,
          trailing: Icon(Icons.chevron_right, color: context.colors.muted),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WorkoutDetailScreen(workout: w),
            ),
          ),
        ),
      ),
    );
  }
}
