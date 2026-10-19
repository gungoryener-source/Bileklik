import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/aggregate.dart';
import '../../data/day_summary.dart';
import '../../data/models.dart';
import '../../device/protocol/history.dart';
import '../../device/transport.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/home/activity_gauge.dart';
import '../widgets/home/day_chart.dart';
import '../widgets/home/home_card.dart';
import 'ecg_screen.dart';
import 'metric_detail_screen.dart';
import 'sleep_screen.dart';
import 'workout_detail_screen.dart';

/// Günlük adım hedefi. Ayarlar ekranı gelince kullanıcı değiştirebilecek.
const dailyStepGoal = 10000;

/// Ana Sayfa: seçilen günün özeti, uyku, etkinlik, denge, nabız, SpO2 ve
/// zaman çizelgesi. Tarih okları ile geçmiş günlere bakılır.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Seçilen gün; null bugün demektir (gece yarısı geçince kendiliğinden kayar).
  DateTime? _day;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get day => _day ?? _today();
  bool get isToday => _day == null || _day == _today();

  void _shift(int by) {
    HapticFeedback.selectionClick();
    final next = DateTime(day.year, day.month, day.day + by);
    setState(() => _day = next.isBefore(_today()) ? next : null);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: _today().subtract(const Duration(days: 365)),
      lastDate: _today(),
      helpText: context.l10n.homePickDay,
    );
    if (picked != null) {
      setState(() => _day = picked == _today() ? null : picked);
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final store = c.store;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = DaySummary.of(store, day);
        return DecoratedBox(
          // Üstte hafif bir renk geçişi; görsel ya da fotoğraf kullanılmaz.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, -0.2),
              colors: [context.colors.glow, context.colors.background],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: c.sync,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _TopBar(),
                const SizedBox(height: 8),
                _DateNav(
                  day: day,
                  isToday: isToday,
                  onPrev: () => _shift(-1),
                  onNext: isToday ? null : () => _shift(1),
                  onPick: _pickDay,
                ),
                const SizedBox(height: 16),
                _Summary(s: s, isToday: isToday),
                if (issueText(c) case final issue?) ...[
                  const SizedBox(height: 12),
                  Text(issue, style: const TextStyle(color: DataColors.heart)),
                ],
                const SizedBox(height: 16),
                _Shortcuts(onEcg: () => _open(const EcgScreen())),
                const SizedBox(height: 16),
                _SleepCard(s: s, onTap: () => _open(const SleepScreen())),
                const SizedBox(height: 12),
                _ActivityCard(
                  s: s,
                  isToday: isToday,
                  onTap: () =>
                      _open(const MetricDetailScreen(type: MetricType.steps)),
                ),
                const SizedBox(height: 12),
                _BalanceCard(
                  s: s,
                  onTap: () =>
                      _open(const MetricDetailScreen(type: MetricType.stress)),
                ),
                const SizedBox(height: 12),
                _DayChartCard(
                  title: l.metricHeartRate,
                  type: MetricType.heartRate,
                  values: s.hourlyHeartRate,
                  stats: s.heartRateStats,
                  hintIcon: Icons.monitor_heart_outlined,
                  hint: l.homeHeartRateHint,
                  onTap: () => _open(
                    const MetricDetailScreen(type: MetricType.heartRate),
                  ),
                ),
                const SizedBox(height: 12),
                _DayChartCard(
                  title: l.metricSpo2,
                  type: MetricType.spo2,
                  values: s.hourlySpo2,
                  stats: s.spo2Stats,
                  hintIcon: Icons.water_drop_outlined,
                  hint: l.homeSpo2Hint,
                  onTap: () =>
                      _open(const MetricDetailScreen(type: MetricType.spo2)),
                ),
                const SizedBox(height: 24),
                _Timeline(s: s, open: _open),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Profil, bileklik durumu, senkron ve EKG kısayolu.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final connecting = c.connection == DeviceConnectionState.connecting;
    final percent = c.battery?.percent;
    final status = switch (c.connection) {
      DeviceConnectionState.connected =>
        percent == null ? l.homeConnected : l.homeConnectedBattery(percent),
      DeviceConnectionState.connecting => l.homeConnecting,
      DeviceConnectionState.disconnected => l.homeConnect,
    };
    return Row(
      children: [
        IconButton(
          tooltip: l.homeProfileTooltip,
          onPressed: () => AppShell.selectTab(context, 3),
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: context.colors.accent,
            foregroundColor: context.colors.background,
            child: Icon(Icons.person, size: 20),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Tooltip(
              message: c.isConnected
                  ? l.homeDisconnectTooltip
                  : l.homeConnectTooltip,
              child: ActionChip(
                avatar: Icon(
                  Icons.watch,
                  size: 18,
                  color: c.isConnected
                      ? context.colors.accent
                      : context.colors.muted,
                ),
                label: Text(status, overflow: TextOverflow.ellipsis),
                backgroundColor: context.colors.surface,
                side: BorderSide(color: context.colors.outline),
                shape: const StadiumBorder(),
                onPressed: connecting
                    ? null
                    : (c.isConnected ? c.disconnect : c.connect),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l.homeSyncTooltip,
          onPressed: c.isConnected && !c.syncing ? c.sync : null,
          icon: c.syncing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
        IconButton(
          tooltip: l.homeMeasureEcg,
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const EcgScreen())),
          icon: const Icon(Icons.monitor_heart_outlined),
        ),
      ],
    );
  }
}

class _DateNav extends StatelessWidget {
  const _DateNav({
    required this.day,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final l = context.l10n;
    final date = dayMonth(day);
    final label = isToday
        ? l.homeTodayDate(date)
        : day == yesterday
        ? l.homeYesterdayDate(date)
        : l.homeWeekdayDate(weekdayLong(day.weekday), date);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l.homePrevDay,
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Flexible(
          child: TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(foregroundColor: context.colors.text),
          ),
        ),
        IconButton(
          tooltip: l.homeNextDay,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// Günün özeti: başlık cümlesi ve uyku, toparlanma, stres yükü.
class _Summary extends StatelessWidget {
  const _Summary({required this.s, required this.isToday});

  final DaySummary s;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final night = s.night;
    final hrv = s.recoveryHrv;
    final hrvBand = hrv == null ? null : bandOf(MetricType.hrv, hrv);
    final stress = s.averageStress;
    final stressBand = stress == null
        ? null
        : bandOf(MetricType.stress, stress);

    final l = context.l10n;
    final String title;
    final String body;
    if (night == null) {
      title = isToday ? l.homeNoSleepLastNight : l.homeNoSleepThisDay;
      body = isToday ? l.homeNoSleepTonightHint : l.homeNoSleepPastHint;
    } else {
      title = isToday ? _greeting(l, DateTime.now()) : l.homeDaySummary;
      final slept = duration(night.asleepMinutes);
      body = hrv == null
          ? l.homeSleptSummary(slept)
          : hrvBand == null
          ? l.homeSleptHrvSummary(slept, hrv.round())
          : l.homeSleptHrvBandSummary(slept, hrv.round(), hrvBand.label);
    }

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.accent.withValues(alpha: 0.15),
          ),
          child: Icon(Icons.wb_twilight, color: context.colors.accent),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.muted, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            children: [
              _SummaryItem(
                night == null ? null : duration(night.asleepMinutes),
                l.homeSleep,
              ),
              VerticalDivider(color: context.colors.outline, width: 1),
              _SummaryItem(hrvBand?.label, l.homeRecovery),
              VerticalDivider(color: context.colors.outline, width: 1),
              _SummaryItem(stressBand?.label, l.homeStressLoad),
            ],
          ),
        ),
      ],
    );
  }

  static String _greeting(AppLocalizations l, DateTime t) => switch (t.hour) {
    >= 5 && < 11 => l.homeGoodMorning,
    >= 11 && < 18 => l.homeGoodAfternoon,
    _ => l.homeGoodEvening,
  };
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.value, this.label);

  final String? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value ?? context.l10n.noValue,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.onEcg});

  final VoidCallback onEcg;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: context.colors.text,
      side: BorderSide(color: context.colors.outline),
      backgroundColor: context.colors.surface,
      shape: const StadiumBorder(),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: () => AppShell.selectTab(context, 2),
            icon: const Icon(Icons.directions_run, color: DataColors.steps),
            label: Text(
              context.l10n.homeStartWorkout,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: onEcg,
            icon: const Icon(Icons.monitor_heart, color: DataColors.heart),
            label: Text(
              context.l10n.homeMeasureEcg,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.s, required this.onTap});

  final DaySummary s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = s.night;
    final deep = n?.minutesIn(SleepStage.deep);
    final l = context.l10n;
    final muted = TextStyle(color: context.colors.muted, fontSize: 12);
    return HomeCard(
      title: l.homeSleep,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigValue(
            n == null ? null : duration(n.asleepMinutes),
            caption: n == null
                ? l.homeNoRecord
                : l.homeDeepSleep(duration(deep!)),
          ),
          const SizedBox(height: 16),
          _StageStrip(night: n),
          const SizedBox(height: 6),
          // Saat ekseni şeritle birlikte her dilde soldan sağa akar.
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Icon(
                Icons.bedtime_outlined,
                size: 16,
                color: context.colors.muted,
              ),
              const SizedBox(width: 4),
              Text(n == null ? l.noValue : hhmm(n.start), style: muted),
              const Spacer(),
              Text(n == null ? l.noValue : hhmm(n.end), style: muted),
              const SizedBox(width: 4),
              Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: context.colors.muted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          MiniStats([
            (n == null ? null : duration(n.asleepMinutes), l.homeDuration),
            (
              s.sleepHeartRate == null
                  ? null
                  : l.homeBpm(s.sleepHeartRate!.round()),
              l.homeHeartRateLabel,
            ),
            (
              s.sleepSpo2 == null ? null : l.homePercent(s.sleepSpo2!.round()),
              l.homeBloodOxygen,
            ),
          ]),
        ],
      ),
    );
  }
}

/// Gecenin evreleri soldan sağa, yatıştan uyanışa (RTL dillerde de;
/// zaman ekseni grafiklerdeki gibi sabit kalır).
class _StageStrip extends StatelessWidget {
  const _StageStrip({required this.night});

  final NightSleep? night;

  @override
  Widget build(BuildContext context) {
    final n = night;
    final runs = <(SleepStage, int)>[];
    if (n != null) {
      var t = n.start;
      for (final session in n.sessions) {
        final gap = session.start.difference(t).inMinutes;
        if (gap > 0) runs.add((SleepStage.awake, gap));
        for (final m in session.minutes) {
          if (runs.isNotEmpty && runs.last.$1 == m) {
            runs.last = (m, runs.last.$2 + 1);
          } else {
            runs.add((m, 1));
          }
        }
        t = session.end;
      }
    }
    final l = context.l10n;
    return Semantics(
      label: n == null
          ? l.homeNoSleepStages
          : l.homeSleepStagesSemantics(
              [
                for (final st in SleepStage.values)
                  l.homeSleepStageItem(st.label, duration(n.minutesIn(st))),
              ].join(l.homeListSeparator),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 20,
          child: runs.isEmpty
              ? ColoredBox(color: context.colors.surfaceHigh)
              : Row(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (stage, minutes) in runs)
                      Expanded(
                        flex: minutes,
                        child: ColoredBox(color: stage.color),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.s,
    required this.isToday,
    required this.onTap,
  });

  final DaySummary s;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = DeviceScope.of(context).live;
    // Bugün için bileklikten gelen anlık toplamlar daha günceldir.
    final useLive = isToday && live != null && live.steps >= s.steps;
    final steps = useLive ? live.steps : s.steps;
    final kcal = useLive ? live.calories : s.calories;
    final km = useLive ? live.distanceKm : s.distanceKm;
    final hasData = steps > 0;
    final pct = (steps / dailyStepGoal * 100).round();
    final l = context.l10n;
    return HomeCard(
      title: l.homeActivity,
      onTap: onTap,
      child: Column(
        children: [
          Semantics(
            label: l.homeStepGoalSemantics(steps, dailyStepGoal, pct),
            child: ActivityGauge(
              progress: steps / dailyStepGoal,
              color: DataColors.steps,
              child: BigValue(
                hasData ? '$steps' : null,
                caption: hasData
                    ? l.homeStepGoalProgress(pct, dailyStepGoal)
                    : l.homeStepGoal(dailyStepGoal),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MiniStats([
            (hasData ? '$steps' : null, l.homeSteps),
            (hasData ? kcal.round().toString() : null, l.homeCaloriesKcal),
            (hasData ? km.toStringAsFixed(2) : null, l.homeKilometers),
          ]),
        ],
      ),
    );
  }
}

/// Denge: günün stres dağılımı ve HRV.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.s, required this.onTap});

  final DaySummary s;
  final VoidCallback onTap;

  static Color _stressColor(double v) => switch (v) {
    < 25 => DataColors.hrv,
    < 51 => DataColors.steps,
    < 76 => DataColors.temperature,
    _ => DataColors.heart,
  };

  @override
  Widget build(BuildContext context) {
    final stress = s.averageStress;
    final band = stress == null ? null : bandOf(MetricType.stress, stress);
    final hrv = s.recoveryHrv;
    final l = context.l10n;
    return HomeCard(
      title: l.homeBalance,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigValue(
            stress?.round().toString(),
            caption: band == null
                ? l.homeAverageStress
                : l.homeAverageStressBand(band.label),
          ),
          const SizedBox(height: 16),
          DayBars(
            values: s.hourlyStress,
            max: 100,
            colorOf: _stressColor,
            semanticLabel: l.homeHourlyStressSemantics,
          ),
          const SizedBox(height: 16),
          MiniStats([
            (hrv == null ? null : l.homeMs(hrv.round()), l.homeHrvLabel),
            (band?.label, l.homeStressLevel),
          ]),
          if (stress == null) ...[
            const SizedBox(height: 12),
            EmptyHint(icon: Icons.self_improvement, text: l.homeStressHint),
          ],
        ],
      ),
    );
  }
}

class _DayChartCard extends StatelessWidget {
  const _DayChartCard({
    required this.title,
    required this.type,
    required this.values,
    required this.stats,
    required this.hint,
    required this.hintIcon,
    required this.onTap,
  });

  final String title;
  final MetricType type;
  final List<double?> values;
  final Stats? stats;
  final String hint;
  final IconData hintIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = stats;
    final l = context.l10n;
    return HomeCard(
      title: title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (st != null) ...[
            // Uzun birim (ör. Arapça) ve büyük yazıda aralık taşmak yerine küçülür.
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          l.homeRange(type.format(st.min), type.format(st.max)),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type.unit,
                          style: TextStyle(color: context.colors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.homeAverageValue(type.format(st.average)),
                  style: TextStyle(color: context.colors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          DayLineChart(
            values: values,
            color: type.color,
            semanticLabel: st == null
                ? l.homeChartNoData(title)
                : l.homeChartSemantics(
                    title,
                    type.format(st.min),
                    type.format(st.max),
                    type.unit,
                  ),
          ),
          if (st == null) ...[
            const SizedBox(height: 16),
            EmptyHint(icon: hintIcon, text: hint),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.s, required this.open});

  final DaySummary s;
  final void Function(Widget) open;

  @override
  Widget build(BuildContext context) {
    final events = s.timeline;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.homeTimeline,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          l.homeTimelineSubtitle,
          style: TextStyle(color: context.colors.muted),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          EmptyHint(icon: Icons.info_outline, text: l.homeTimelineEmpty)
        else
          for (final e in events) _eventTile(context, e),
      ],
    );
  }

  Widget _eventTile(BuildContext context, TimelineEvent e) {
    final l = context.l10n;
    final (
      IconData icon,
      Color color,
      String title,
      String sub,
      Widget to,
    ) = switch (e) {
      WorkoutEvent(:final workout) => (
        sportIcon(workout.type),
        DataColors.steps,
        sportLabel(workout.type),
        l.homeWorkoutSubtitle(
          clock(workout.duration),
          workout.calories.round(),
        ),
        WorkoutDetailScreen(workout: workout),
      ),
      EcgEvent(:final recording) => (
        Icons.monitor_heart,
        DataColors.heart,
        l.homeEcg,
        recording.averageHeartRate == null
            ? l.homeEcgSubtitleNoHr(recording.duration.inSeconds)
            : l.homeEcgSubtitle(
                recording.averageHeartRate!,
                recording.duration.inSeconds,
              ),
        EcgDetailScreen(recording: recording),
      ),
      SleepEvent(:final night) => (
        Icons.bedtime,
        SleepStage.light.color,
        l.homeWokeUp,
        l.homeWokeUpSubtitle(duration(night.asleepMinutes), hhmm(night.start)),
        const SleepScreen(),
      ),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: Icon(icon, size: 20),
      ),
      title: Text(title),
      subtitle: Text(sub, style: TextStyle(color: context.colors.muted)),
      trailing: Text(
        hhmm(e.time),
        style: TextStyle(color: context.colors.muted),
      ),
      onTap: () => open(to),
    );
  }
}
