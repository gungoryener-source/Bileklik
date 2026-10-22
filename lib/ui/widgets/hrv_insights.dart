import 'package:flutter/material.dart';

import '../../data/health_store.dart';
import '../../data/hrv_analysis.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../format.dart';
import '../theme.dart';
import 'cam/cam.dart';

/// HRV ayrıntısı (son gecenin atım aralıklarından) ve VO2 Max tahmini.
/// HRV detay ekranının altında gösterilir.
class HrvInsights extends StatelessWidget {
  const HrvInsights({
    super.key,
    required this.store,
    required this.now,
    required this.age,
  });

  final HealthStore store;
  final DateTime now;

  /// Bileklikteki kişisel bilgiden; bilinmiyorsa null.
  final int? age;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final night = latestNightHrv(store, now);
    final resting = restingHeartRate(store, now);
    final vo2 = age == null || resting == null
        ? null
        : estimateVo2Max(age: age!, restingHeartRate: resting);
    final bpm = MetricType.heartRate.unit;

    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.hrvDetailTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          child: switch (night) {
            null => Text(
              l.hrvDetailEmpty,
              style: TextStyle(color: colors.muted),
            ),
            (:final day, :final stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.hrvDetailNight(dayMonth(day)),
                  style: TextStyle(color: colors.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    stat(l.hrvRmssd, '${stats.rmssd.round()} ms'),
                    stat(l.hrvSdnn, '${stats.sdnn.round()} ms'),
                    stat(
                      l.hrvPnn50,
                      l.statPercent(stats.pnn50.round().toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    stat(
                      l.hrvMeanHeartRate,
                      '${stats.meanHeartRate.round()} $bpm',
                    ),
                    stat(l.hrvBeats, stats.beats.toString()),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l.hrvDetailNote, style: TextStyle(color: colors.muted)),
              ],
            ),
          },
        ),
        const SizedBox(height: 20),
        Text(l.vo2MaxTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vo2 != null) ...[
                Text(
                  l.vo2MaxValue(vo2.toStringAsFixed(1)),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l.vo2MaxBasis(age!, '$resting $bpm'),
                  style: TextStyle(color: colors.muted),
                ),
              ] else
                Text(
                  age == null ? l.vo2MaxNeedsAge : l.vo2MaxNeedsData,
                  style: TextStyle(color: colors.muted),
                ),
              const SizedBox(height: 12),
              Text(l.vo2MaxNote, style: TextStyle(color: colors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
