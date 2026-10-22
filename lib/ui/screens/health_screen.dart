import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'body_screen.dart';
import 'ecg_screen.dart';
import 'metric_detail_screen.dart';
import 'sleep_screen.dart';

/// Sağlık sekmesi: her metriğin son değeri; dokununca ayrıntı ekranı açılır.
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
        final todaySteps = store
            .measurements(MetricType.steps, today.start, today.end)
            .fold(0.0, (s, m) => s + m.value);
        final lastNight = NightSleep.group(
          store.sleepBetween(now.subtract(const Duration(days: 2)), now),
        ).lastOrNull;

        final lastEcg = store.ecgRecordings().firstOrNull;
        final l = context.l10n;

        void open(Widget screen) =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen));

        Widget card(
          MetricType type, {
          String? value,
          String? subtitle,
          MetricType? secondary,
          String? title,
          bool estimated = false,
        }) {
          final latest = store.latest(type);
          final second = secondary == null ? null : store.latest(secondary);
          final band = latest == null ? null : bandOf(type, latest.value);
          // Yüzde işaretinin yeri dile göre değişir; değerle birlikte yazılır.
          final percent = type.symbol == '%';
          final shown =
              value ??
              (latest == null
                  ? null
                  : second == null
                  ? (percent
                        ? l.statPercent(type.format(latest.value))
                        : type.format(latest.value))
                  : '${type.format(latest.value)}/${secondary!.format(second.value)}');
          final details = latest == null
              ? null
              : [
                  if (band != null) band.label,
                  whenText(latest.time, now),
                ].join(' · ');
          return _HealthCard(
            title: title ?? type.label,
            icon: type.icon,
            color: type.color,
            value: shown,
            unit: percent ? '' : type.unit,
            subtitle:
                subtitle ??
                (details == null
                    ? l.healthNoMeasurement
                    : estimated
                    ? l.healthBloodPressureSubtitle(details)
                    : details),
            onTap: () => open(
              MetricDetailScreen(
                type: type,
                secondary: secondary,
                title: title,
              ),
            ),
          );
        }

        // Kilo elle girilir; kart vücut ekranını açar.
        Widget weightCard() {
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
          return _HealthCard(
            title: MetricType.weight.label,
            icon: MetricType.weight.icon,
            color: MetricType.weight.color,
            value: w == null ? null : MetricType.weight.format(w.value),
            unit: MetricType.weight.unit,
            subtitle: w == null
                ? l.healthWeightPrompt
                : bmi == null
                ? whenText(w.time, now)
                : l.healthWeightBmi(
                    MetricType.bmi.format(bmi.value),
                    whenText(w.time, now),
                  ),
            onTap: () => open(const BodyScreen()),
          );
        }

        return RefreshIndicator(
          onRefresh: c.sync,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
              _HealthCard(
                title: l.healthEcg,
                icon: Icons.monitor_heart,
                color: DataColors.heart,
                value: lastEcg?.averageHeartRate?.toString(),
                unit: lastEcg?.averageHeartRate == null
                    ? ''
                    : MetricType.heartRate.unit,
                subtitle: lastEcg == null
                    ? l.healthEcgPrompt
                    : l.healthEcgLast(whenText(lastEcg.start, now)),
                onTap: () => open(const EcgScreen()),
              ),
              card(
                MetricType.steps,
                value: todaySteps.round().toString(),
                subtitle: l.healthStepsToday(10000),
              ),
              _HealthCard(
                title: l.healthSleep,
                icon: Icons.bedtime,
                color: DataColors.sleepLight,
                value: lastNight == null
                    ? null
                    : duration(lastNight.asleepMinutes),
                unit: '',
                subtitle: lastNight == null
                    ? l.healthNoRecord
                    : l.healthSleepLastNight(
                        hhmm(lastNight.start),
                        hhmm(lastNight.end),
                      ),
                onTap: () => open(const SleepScreen()),
              ),
              card(MetricType.heartRate),
              card(MetricType.spo2),
              card(MetricType.hrv),
              card(MetricType.stress),
              card(MetricType.temperature),
              card(MetricType.respiratoryRate),
              card(
                MetricType.systolic,
                secondary: MetricType.diastolic,
                title: l.healthBloodPressure,
                estimated: true,
              ),
              weightCard(),
            ],
          ),
        );
      },
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? value;
  final String unit;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.colors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Uzun değerler (ör. Almanca süre) dar ekranda küçülerek sığar.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value ?? context.l10n.noValue,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: TextStyle(color: context.colors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: context.colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
