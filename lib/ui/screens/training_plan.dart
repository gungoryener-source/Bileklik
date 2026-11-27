import 'package:flutter/material.dart';

import '../../data/insights.dart';
import '../../data/recovery.dart';
import '../../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/insights.dart';
import 'recovery_screen.dart';

/// Günün toparlanmasına göre antrenman yoğunluğu.
enum PlanIntensity { intense, moderate, light, rest }

PlanIntensity planFor(RecoveryLevel level) => switch (level) {
  RecoveryLevel.excellent => PlanIntensity.intense,
  RecoveryLevel.good => PlanIntensity.moderate,
  RecoveryLevel.normal => PlanIntensity.light,
  RecoveryLevel.poor || RecoveryLevel.inadequate => PlanIntensity.rest,
};

/// Hedef nabız bölgesi; dinlenme gününde ısınma bölgesi.
HeartRateZone zoneFor(PlanIntensity p) => switch (p) {
  PlanIntensity.intense => HeartRateZone.anaerobic,
  PlanIntensity.moderate => HeartRateZone.aerobic,
  PlanIntensity.light => HeartRateZone.fatBurn,
  PlanIntensity.rest => HeartRateZone.warmUp,
};

/// Bugünkü antrenman planı: toparlanmaya göre yoğunluk, süre ve (yaş
/// biliniyorsa) hedef nabız aralığı. Uygulamanın kural tabanlı önerisidir.
Future<void> showTrainingPlan(
  BuildContext context, {
  required DayRecovery? recovery,
  required int? age,
  required VoidCallback onStart,
}) => showCamSheet<void>(
  context: context,
  builder: (ctx) => _PlanSheet(recovery: recovery, age: age, onStart: onStart),
);

class _PlanSheet extends StatelessWidget {
  const _PlanSheet({
    required this.recovery,
    required this.age,
    required this.onStart,
  });

  final DayRecovery? recovery;
  final int? age;

  /// Egzersiz sekmesine geçer; sayfa kapandıktan sonra çağrılır.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final r = recovery;
    final muted = TextStyle(color: colors.muted);
    final children = <Widget>[
      Text(l.planTitle, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
    ];
    if (r == null) {
      children.add(Text(l.planNeedsData, style: muted));
    } else {
      final plan = planFor(r.level);
      final zone = zoneFor(plan);
      final (title, body, icon) = switch (plan) {
        PlanIntensity.intense => (
          l.planIntenseTitle,
          l.planIntenseBody,
          Icons.local_fire_department,
        ),
        PlanIntensity.moderate => (
          l.planModerateTitle,
          l.planModerateBody,
          Icons.directions_run,
        ),
        PlanIntensity.light => (
          l.planLightTitle,
          l.planLightBody,
          Icons.directions_walk,
        ),
        PlanIntensity.rest => (
          l.planRestTitle,
          l.planRestBody,
          Icons.self_improvement,
        ),
      };
      final a = age;
      children.addAll([
        Row(
          children: [
            Icon(icon, color: r.level.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(body),
        const SizedBox(height: 10),
        Text(
          a == null || a < 10
              ? l.planNeedsAge
              : l.planZone(zone.rangeText(maxHeartRate(a)), zone.label),
          style: TextStyle(color: zone.color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          l.planBasedOn('${l.homePercent(r.score)} · ${r.level.label}'),
          style: muted,
        ),
      ]);
    }
    children.addAll([
      const SizedBox(height: 10),
      Text(l.planNote, style: muted.copyWith(fontSize: 12)),
      const SizedBox(height: 18),
      GlowButton(
        label: l.homeStartWorkout,
        icon: Icons.directions_run,
        onTap: () {
          Navigator.of(context).pop();
          onStart();
        },
      ),
    ]);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
