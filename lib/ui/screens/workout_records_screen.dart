import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'workout_detail_screen.dart';

/// Tüm egzersiz kayıtları, en yeni üstte; dokununca egzersiz raporu açılır.
class WorkoutRecordsScreen extends StatelessWidget {
  const WorkoutRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = DeviceScope.of(context);
    return CamScaffold(
      appBar: AppBar(title: Text(l.exerciseRecordsTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: c.store,
          builder: (context, _) {
            final workouts = c.store.workoutsBetween(
              DateTime(2000),
              DateTime.now(),
            )..sort((a, b) => b.start.compareTo(a.start));
            if (workouts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  child: Text(
                    c.isConnected ? l.exerciseEmpty : l.exerciseConnectHint,
                    style: TextStyle(color: context.colors.muted),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: workouts.length,
              itemBuilder: (context, i) => _WorkoutTile(workouts[i]),
            );
          },
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
        '${distanceValue(w.distanceKm)} ${MetricType.distance.unit}',
      '${w.calories.round()} ${MetricType.calories.unit}',
    ].map(ltr).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
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
