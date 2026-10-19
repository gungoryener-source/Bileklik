import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/day_summary.dart';
import '../../data/models.dart';
import '../../device/protocol/history.dart';
import '../../device/transport.dart';
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
    final next = DateTime(day.year, day.month, day.day + by);
    setState(() => _day = next.isBefore(_today()) ? next : null);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: _today().subtract(const Duration(days: 365)),
      lastDate: _today(),
      helpText: 'Gün seçin',
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
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = DaySummary.of(store, day);
        return DecoratedBox(
          // Üstte hafif bir renk geçişi; görsel ya da fotoğraf kullanılmaz.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment(0, -0.2),
              colors: [AppColors.glow, AppColors.background],
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
                if (c.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    c.error!,
                    style: const TextStyle(color: AppColors.heart),
                  ),
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
                  title: 'Kalp Atış Hızı',
                  type: MetricType.heartRate,
                  values: s.hourlyHeartRate,
                  stats: s.heartRateStats,
                  hintIcon: Icons.monitor_heart_outlined,
                  hint: 'Kalp atış hızınızı görmek için bilekliği gün boyu takın.',
                  onTap: () => _open(
                    const MetricDetailScreen(type: MetricType.heartRate),
                  ),
                ),
                const SizedBox(height: 12),
                _DayChartCard(
                  title: 'Kan Oksijen Doygunluğu',
                  type: MetricType.spo2,
                  values: s.hourlySpo2,
                  stats: s.spo2Stats,
                  hintIcon: Icons.water_drop_outlined,
                  hint:
                      'Kan oksijeninizi görmek için bilekliği gün boyu takın.',
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
    final connecting = c.connection == DeviceConnectionState.connecting;
    final status = switch (c.connection) {
      DeviceConnectionState.connected =>
        'Bağlı · %${c.battery?.percent ?? '--'}',
      DeviceConnectionState.connecting => 'Bağlanıyor…',
      DeviceConnectionState.disconnected => 'Bağlan',
    };
    return Row(
      children: [
        IconButton(
          tooltip: 'Profil',
          onPressed: () => AppShell.selectTab(context, 3),
          icon: const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            child: Icon(Icons.person, size: 20),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: c.isConnected ? 'Bağlantıyı kes' : 'Bilekliğe bağlan',
              child: ActionChip(
                avatar: Icon(
                  Icons.watch,
                  size: 18,
                  color: c.isConnected ? AppColors.accent : AppColors.muted,
                ),
                label: Text(status, overflow: TextOverflow.ellipsis),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.outline),
                shape: const StadiumBorder(),
                onPressed: connecting
                    ? null
                    : (c.isConnected ? c.disconnect : c.connect),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Eşitle',
          onPressed: c.isConnected && !c.syncing ? c.sync : null,
          icon: c.syncing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
        IconButton(
          tooltip: 'EKG ölç',
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
    final label = isToday
        ? 'Bugün, ${dayMonth(day)}'
        : day == yesterday
        ? 'Dün, ${dayMonth(day)}'
        : '${weekdaysLong[day.weekday - 1]}, ${dayMonth(day)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Önceki gün',
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
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ),
        IconButton(
          tooltip: 'Sonraki gün',
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

    final String title;
    final String body;
    if (night == null) {
      title = isToday
          ? 'Dün gece uyku ölçülmedi'
          : 'Bu gün için uyku kaydı yok';
      body = isToday
          ? 'Bilekliği bu gece takın; sabah uyku ve toparlanma özetiniz burada olacak.'
          : 'Bilekliğin takılı olduğu günlerin özeti burada görünür.';
    } else {
      title = isToday ? _greeting(DateTime.now()) : 'Günün özeti';
      final parts = [
        '${duration(night.asleepMinutes)} uyudunuz',
        if (hrv != null)
          'gece HRV ortalamanız ${hrv.round()} ms${hrvBand == null ? '' : ' (${hrvBand.label})'}',
      ];
      body = '${parts.join(', ')}.';
    }

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.wb_twilight, color: AppColors.accent),
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
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        IntrinsicHeight(
          child: Row(
            children: [
              _SummaryItem(
                night == null ? null : duration(night.asleepMinutes),
                'Uyku',
              ),
              const VerticalDivider(color: AppColors.outline, width: 1),
              _SummaryItem(hrvBand?.label, 'Toparlanma'),
              const VerticalDivider(color: AppColors.outline, width: 1),
              _SummaryItem(stressBand?.label, 'Stres yükü'),
            ],
          ),
        ),
      ],
    );
  }

  static String _greeting(DateTime t) => switch (t.hour) {
    >= 5 && < 11 => 'Günaydın',
    >= 11 && < 18 => 'İyi günler',
    _ => 'İyi akşamlar',
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
              value ?? '--',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
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
      foregroundColor: Colors.white,
      side: const BorderSide(color: AppColors.outline),
      backgroundColor: AppColors.surface,
      shape: const StadiumBorder(),
    );
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: () => AppShell.selectTab(context, 2),
            icon: const Icon(Icons.directions_run, color: AppColors.steps),
            label: const Text(
              'Egzersize başla',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: onEcg,
            icon: const Icon(Icons.monitor_heart, color: AppColors.heart),
            label: const Text('EKG ölç', overflow: TextOverflow.ellipsis),
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
    return HomeCard(
      title: 'Uyku',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigValue(
            n == null ? null : duration(n.asleepMinutes),
            caption: n == null ? 'Kayıt yok' : 'Derin uyku ${duration(deep!)}',
          ),
          const SizedBox(height: 16),
          _StageStrip(night: n),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.bedtime_outlined,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                n == null ? '--' : hhmm(n.start),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                n == null ? '--' : hhmm(n.end),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.wb_sunny_outlined,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          MiniStats([
            (n == null ? null : duration(n.asleepMinutes), 'Süre'),
            (
              s.sleepHeartRate == null
                  ? null
                  : '${s.sleepHeartRate!.round()} bpm',
              'Kalp atış hızı',
            ),
            (
              s.sleepSpo2 == null ? null : '%${s.sleepSpo2!.round()}',
              'Kan oksijeni',
            ),
          ]),
        ],
      ),
    );
  }
}

/// Gecenin evreleri soldan sağa, yatıştan uyanışa.
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
    return Semantics(
      label: n == null
          ? 'Uyku evresi yok'
          : 'Uyku evreleri: ${[for (final st in SleepStage.values) '${st.label} ${duration(n.minutesIn(st))}'].join(', ')}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 20,
          child: runs.isEmpty
              ? const ColoredBox(color: AppColors.surfaceHigh)
              : Row(
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
    return HomeCard(
      title: 'Aktivite',
      onTap: onTap,
      child: Column(
        children: [
          Semantics(
            label: 'Adım hedefi: $steps / $dailyStepGoal, yüzde $pct',
            child: ActivityGauge(
              progress: steps / dailyStepGoal,
              color: AppColors.steps,
              child: BigValue(
                hasData ? '$steps' : null,
                caption: hasData
                    ? '%$pct · hedef $dailyStepGoal'
                    : 'Hedef $dailyStepGoal adım',
              ),
            ),
          ),
          const SizedBox(height: 16),
          MiniStats([
            (hasData ? '$steps' : null, 'Adım'),
            (hasData ? kcal.round().toString() : null, 'Kalori (kcal)'),
            (hasData ? km.toStringAsFixed(2) : null, 'Kilometre'),
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
    < 25 => AppColors.accent,
    < 51 => AppColors.steps,
    < 76 => AppColors.temperature,
    _ => AppColors.heart,
  };

  @override
  Widget build(BuildContext context) {
    final stress = s.averageStress;
    final band = stress == null ? null : bandOf(MetricType.stress, stress);
    final hrv = s.recoveryHrv;
    return HomeCard(
      title: 'Denge',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigValue(
            stress?.round().toString(),
            caption: band == null
                ? 'Ortalama stres'
                : 'Ortalama stres · ${band.label}',
          ),
          const SizedBox(height: 16),
          DayBars(
            values: s.hourlyStress,
            max: 100,
            colorOf: _stressColor,
            semanticLabel: 'Saatlik stres sütunları',
          ),
          const SizedBox(height: 16),
          MiniStats([
            (
              hrv == null ? null : '${hrv.round()} ms',
              'Kalp atış hızı değişkenliği',
            ),
            (band?.label, 'Stres düzeyi'),
          ]),
          if (stress == null) ...[
            const SizedBox(height: 12),
            const EmptyHint(
              icon: Icons.self_improvement,
              text: 'Stres ve HRV, bileklik takılıyken gün içinde ölçülür.',
            ),
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
    return HomeCard(
      title: title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (st != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${type.format(st.min)}-${type.format(st.max)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Text(type.unit, style: const TextStyle(color: AppColors.muted)),
                const Spacer(),
                Text(
                  'Ort. ${type.format(st.average)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          DayLineChart(
            values: values,
            color: type.color,
            semanticLabel: st == null
                ? '$title: ölçüm yok'
                : '$title: en düşük ${type.format(st.min)}, en yüksek ${type.format(st.max)} ${type.unit}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zaman çizelgesi',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text('Günün kayıtları', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        if (events.isEmpty)
          const EmptyHint(
            icon: Icons.info_outline,
            text: 'Egzersiz, EKG ve uyku kayıtlarınız burada saat sırasıyla görünür.',
          )
        else
          for (final e in events) _eventTile(e),
      ],
    );
  }

  Widget _eventTile(TimelineEvent e) {
    final (
      IconData icon,
      Color color,
      String title,
      String sub,
      Widget to,
    ) = switch (e) {
      WorkoutEvent(:final workout) => (
        sportIcon(workout.type),
        AppColors.steps,
        sportLabel(workout.type),
        '${clock(workout.duration)} · ${workout.calories.round()} kcal',
        WorkoutDetailScreen(workout: workout),
      ),
      EcgEvent(:final recording) => (
        Icons.monitor_heart,
        AppColors.heart,
        'EKG',
        recording.averageHeartRate == null
            ? '${recording.duration.inSeconds} sn'
            : '${recording.averageHeartRate} bpm · ${recording.duration.inSeconds} sn',
        EcgDetailScreen(recording: recording),
      ),
      SleepEvent(:final night) => (
        Icons.bedtime,
        SleepStage.light.color,
        'Uyandınız',
        '${duration(night.asleepMinutes)} uyku · ${hhmm(night.start)} yatış',
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
      subtitle: Text(sub, style: const TextStyle(color: AppColors.muted)),
      trailing: Text(
        hhmm(e.time),
        style: const TextStyle(color: AppColors.muted),
      ),
      onTap: () => open(to),
    );
  }
}
