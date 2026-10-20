import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../device/protocol/history.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Uyku evresinin rengi; adı `SleepStageName`'de (format.dart).
extension SleepLook on SleepStage {
  Color get color => switch (this) {
    SleepStage.deep => DataColors.sleepDeep,
    SleepStage.light => DataColors.sleepLight,
    SleepStage.rem => DataColors.sleepRem,
    SleepStage.awake => DataColors.temperature,
  };
}

/// Gece gece uyku süresi, evre çizgisi ve evrelerin dağılımı.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  int? _index;

  @override
  Widget build(BuildContext context) {
    final store = DeviceScope.of(context).store;
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.sleepTitle)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final nights = NightSleep.group(
            store.sleepBetween(
              DateTime.now().subtract(const Duration(days: 60)),
              DateTime.now(),
            ),
          );
          if (nights.isEmpty) {
            return Center(
              child: Text(
                l.sleepEmpty,
                style: TextStyle(color: context.colors.muted),
              ),
            );
          }
          final i = (_index ?? nights.length - 1).clamp(0, nights.length - 1);
          final night = nights[i];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l.sleepPreviousNight,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: i > 0
                        ? () => setState(() => _index = i - 1)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      dayMonth(night.day),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: l.sleepNextNight,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: i < nights.length - 1
                        ? () => setState(() => _index = i + 1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.sleepDuration,
                style: TextStyle(color: context.colors.muted),
              ),
              Text(
                duration(night.asleepMinutes),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: DataColors.sleepLight,
                ),
              ),
              Text(
                l.sleepTimeRange(hhmm(night.start), hhmm(night.end)),
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 16),
              _Hypnogram(night),
              const SizedBox(height: 20),
              for (final s in SleepStage.values) _StageRow(night, s),
              const SizedBox(height: 24),
              Text(
                l.sleepLast7Nights,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _WeekBars(
                nights.sublist((nights.length - 7).clamp(0, nights.length)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Gecenin dakika dakika evreleri; ardışık aynı evreler tek parça çizilir.
class _Hypnogram extends StatelessWidget {
  const _Hypnogram(this.night);
  final NightSleep night;

  @override
  Widget build(BuildContext context) {
    final minutes = [for (final s in night.sessions) ...s.minutes];
    final parts = <(SleepStage, int)>[];
    for (final m in minutes) {
      if (parts.isNotEmpty && parts.last.$1 == m) {
        parts[parts.length - 1] = (m, parts.last.$2 + 1);
      } else {
        parts.add((m, 1));
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            for (final (stage, len) in parts)
              Expanded(
                flex: len,
                child: ColoredBox(color: stage.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow(this.night, this.stage);
  final NightSleep night;
  final SleepStage stage;

  @override
  Widget build(BuildContext context) {
    final mins = night.minutesIn(stage);
    final total = night.asleepMinutes + night.minutesIn(SleepStage.awake);
    final pct = total == 0 ? 0 : (mins * 100 / total).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: stage.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(stage.label)),
          Text(duration(mins)),
          SizedBox(
            width: 52,
            child: Text(
              context.l10n.sleepPercent(pct),
              textAlign: TextAlign.end,
              style: TextStyle(color: context.colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars(this.nights);
  final List<NightSleep> nights;

  @override
  Widget build(BuildContext context) {
    final most = nights.fold(
      1,
      (m, n) => n.asleepMinutes > m ? n.asleepMinutes : m,
    );
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final n in nights)
            Expanded(
              child: Semantics(
                label: context.l10n.sleepWeekBarHint(
                  weekdayLong(n.day.weekday),
                  duration(n.asleepMinutes),
                ),
                excludeSemantics: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      (n.asleepMinutes / 60).toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 70 * n.asleepMinutes / most,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: DataColors.sleepLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekdayShort(n.day.weekday),
                      style: TextStyle(
                        color: context.colors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
