import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/stat_tile.dart';
import '../widgets/cam/cam.dart';

/// Bir egzersizin özeti.
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
    final w = workout;
    final hasDistance = w.distanceKm > 0.01;
    final l = context.l10n;
    final stats = [
      (l.statDuration, clock(w.duration), ''),
      (
        MetricType.calories.label,
        w.calories.round().toString(),
        MetricType.calories.unit,
      ),
      if (w.averageHeartRate > 0)
        (
          l.statAvgHeartRate,
          '${w.averageHeartRate}',
          MetricType.heartRate.unit,
        ),
      if (w.steps > 0) (MetricType.steps.label, '${w.steps}', ''),
      if (hasDistance)
        (
          MetricType.distance.label,
          w.distanceKm.toStringAsFixed(2),
          MetricType.distance.unit,
        ),
      if (hasDistance)
        (l.statPace, paceText(w.pace), '/${MetricType.distance.unit}'),
    ];
    return CamScaffold(
      appBar: AppBar(title: Text(sportLabel(w.type))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: context.colors.accent.withValues(alpha: 0.15),
                child: Icon(
                  sportIcon(w.type),
                  color: context.colors.accent,
                  size: 30,
                ),
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
                    Text(
                      l.workoutTimeRange(
                        dayMonth(w.start),
                        hhmm(w.start),
                        hhmm(w.end),
                      ),
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              for (final (label, value, unit) in stats)
                StatTile(label, value, unit: unit),
            ],
          ),
        ],
      ),
    );
  }
}
