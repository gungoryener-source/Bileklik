import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
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

        void open(Widget screen) =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen));

        Widget card(
          MetricType type, {
          String? value,
          String? subtitle,
          MetricType? secondary,
          String? title,
        }) {
          final latest = store.latest(type);
          final second = secondary == null ? null : store.latest(secondary);
          final shown =
              value ??
              (latest == null
                  ? null
                  : second == null
                  ? type.format(latest.value)
                  : '${type.format(latest.value)}/${secondary!.format(second.value)}');
          final band = latest == null ? null : bandOf(type, latest.value);
          return _HealthCard(
            title: title ?? type.label,
            icon: type.icon,
            color: type.color,
            value: shown,
            unit: type.unit,
            subtitle:
                subtitle ??
                (latest == null
                    ? 'Ölçüm yok'
                    : [
                        if (band != null) band.label,
                        whenText(latest.time, now),
                      ].join(' · ')),
            onTap: () => open(
              MetricDetailScreen(
                type: type,
                secondary: secondary,
                title: title,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: c.sync,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sağlık',
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
                      tooltip: 'Bileklikten güncelle',
                      onPressed: c.isConnected ? c.sync : null,
                      icon: const Icon(Icons.sync),
                    ),
                ],
              ),
              Text(
                c.lastSync == null
                    ? (c.isConnected
                          ? 'Bileklikten veriler alınıyor…'
                          : 'Verileri görmek için Ana Sayfa\'dan bilekliği bağlayın.')
                    : 'Son güncelleme ${hhmm(c.lastSync!)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _HealthCard(
                title: 'EKG',
                icon: Icons.monitor_heart,
                color: AppColors.heart,
                value: lastEcg?.averageHeartRate?.toString(),
                unit: lastEcg?.averageHeartRate == null ? '' : 'bpm',
                subtitle: lastEcg == null
                    ? '30 saniyelik ölçüm yapın'
                    : 'Son ölçüm · ${whenText(lastEcg.start, now)}',
                onTap: () => open(const EcgScreen()),
              ),
              card(
                MetricType.steps,
                value: todaySteps.round().toString(),
                subtitle: 'Bugün · hedef 10000',
              ),
              _HealthCard(
                title: 'Uyku',
                icon: Icons.bedtime,
                color: const Color(0xFF6C8CFF),
                value: lastNight == null
                    ? null
                    : duration(lastNight.asleepMinutes),
                unit: '',
                subtitle: lastNight == null
                    ? 'Kayıt yok'
                    : 'Dün gece · ${hhmm(lastNight.start)} - ${hhmm(lastNight.end)}',
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
                title: 'Tansiyon',
              ),
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
      child: Card(
        clipBehavior: Clip.antiAlias,
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
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  value ?? '--',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: const TextStyle(color: AppColors.muted)),
                ],
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
