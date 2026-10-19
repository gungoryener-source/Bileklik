import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/stat_tile.dart';

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
    final stats = [
      ('Süre', clock(w.duration), ''),
      ('Kalori', w.calories.round().toString(), 'kcal'),
      if (w.averageHeartRate > 0)
        ('Ortalama nabız', '${w.averageHeartRate}', 'bpm'),
      if (w.steps > 0) ('Adım', '${w.steps}', ''),
      if (hasDistance) ('Mesafe', w.distanceKm.toStringAsFixed(2), 'km'),
      if (hasDistance) ('Tempo', paceText(w.pace), '/km'),
    ];
    return Scaffold(
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
                      justFinished
                          ? 'Tebrikler, egzersiz kaydedildi'
                          : sportLabel(w.type),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${dayMonth(w.start)} · ${hhmm(w.start)} - ${hhmm(w.end)}',
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
