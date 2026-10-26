import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/aggregate.dart';
import '../../data/day_summary.dart';
import '../../data/progress.dart';
import '../../data/models.dart';
import '../../device/protocol/history.dart';
import '../../device/transport.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/home/day_chart.dart';
import '../widgets/home/home_card.dart';
import '../widgets/insights.dart';
import 'ecg_screen.dart';
import 'metric_detail_screen.dart';
import 'progress_screen.dart';
import 'sleep_screen.dart';
import 'spot_measure_screen.dart';
import 'workout_detail_screen.dart';

/// Günlük aktif süre hedefi (dakika); haftada 150 dakikanın günlük payı.
const dailyActiveGoalMinutes = 30;

/// Ana Sayfa (Cam): başlık ve tarih gezgini, canlı nabız kartı, hızlı
/// işlemler, uyku/adım/kalori/aktif süre ızgarası, günün özeti, denge,
/// nabız ve SpO2 grafikleri, zaman çizelgesi.
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
    const gap = SizedBox(height: CamSpace.gap);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = DaySummary.of(store, day);
        return RefreshIndicator(
          onRefresh: c.sync,
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              16,
              8,
              16,
              24 + GlassNavBar.clearance(context),
            ),
            children: [
              _Header(
                day: day,
                isToday: isToday,
                onPrev: () => _shift(-1),
                onNext: isToday ? null : () => _shift(1),
                onPick: _pickDay,
              ),
              const SizedBox(height: 16),
              _HeartRateHero(s: s),
              if (issueText(c) case final issue?) ...[
                gap,
                Text(issue, style: TextStyle(color: context.colors.danger)),
              ],
              const SizedBox(height: 16),
              const _QuickActions(),
              const SizedBox(height: 16),
              _EqualRow(
                start: _SleepTile(
                  s: s,
                  onTap: () => _open(const SleepScreen()),
                ),
                end: _StepsTile(
                  s: s,
                  isToday: isToday,
                  onTap: () =>
                      _open(const MetricDetailScreen(type: MetricType.steps)),
                ),
              ),
              gap,
              _EqualRow(
                start: _CaloriesTile(
                  s: s,
                  isToday: isToday,
                  onTap: () => _open(
                    const MetricDetailScreen(type: MetricType.calories),
                  ),
                ),
                end: _ActiveTimeTile(
                  s: s,
                  onTap: () => AppShell.selectTab(context, 2),
                ),
              ),
              gap,
              _Summary(s: s, isToday: isToday),
              gap,
              EnergyCard(
                day: s.day,
                onTap: () => _open(ProgressScreen(day: s.day)),
              ),
              gap,
              HealthRadarCard(
                store: store,
                day: s.day,
                onTap: () => _open(ProgressScreen(day: s.day)),
              ),
              gap,
              _BalanceCard(
                s: s,
                onTap: () =>
                    _open(const MetricDetailScreen(type: MetricType.stress)),
              ),
              gap,
              _DayChartCard(
                title: l.metricHeartRate,
                type: MetricType.heartRate,
                values: s.hourlyHeartRate,
                stats: s.heartRateStats,
                hintIcon: Icons.monitor_heart_outlined,
                hint: l.homeHeartRateHint,
                onTap: () =>
                    _open(const MetricDetailScreen(type: MetricType.heartRate)),
              ),
              gap,
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
              gap,
              _Timeline(s: s, open: _open),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Başlık
// ---------------------------------------------------------------------------

/// Gün adı ("Bugün"), bileklik çipi; altında tarih gezgini.
class _Header extends StatelessWidget {
  const _Header({
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
    final l = context.l10n;
    final colors = context.colors;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final title = isToday
        ? l.homeToday
        : day == yesterday
        ? l.homeYesterday
        : dayMonth(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const _BandChip(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _RoundIcon(
              icon: Icons.chevron_left,
              tooltip: l.homePrevDay,
              onTap: onPrev,
            ),
            Flexible(
              child: TextButton.icon(
                onPressed: onPick,
                icon: Icon(Icons.calendar_today, size: 16, color: colors.muted),
                label: Text(
                  l.homeWeekdayDate(weekdayLong(day.weekday), dayMonth(day)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _RoundIcon(
              icon: Icons.chevron_right,
              tooltip: l.homeNextDay,
              onTap: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

/// 48 dp dokunma alanlı küçük cam daire düğme.
class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: c.surfaceHigh,
        disabledBackgroundColor: const Color(0x00000000),
        side: BorderSide(color: c.glassBorder),
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

/// Bileklik çipi: bağlıyken yeşil nokta ve pil, değilken gri nokta ve
/// "Bağlı değil". Dokununca bağlanır ya da bağlantıyı keser.
class _BandChip extends StatelessWidget {
  const _BandChip();

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final connected = c.isConnected;
    final connecting = c.connection == DeviceConnectionState.connecting;
    final percent = c.battery?.percent;
    final label = switch (c.connection) {
      DeviceConnectionState.connected =>
        percent == null ? l.homeConnected : l.homeConnectedBattery(percent),
      DeviceConnectionState.connecting => l.homeConnecting,
      DeviceConnectionState.disconnected => l.homeNotConnected,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Tooltip(
        message: connected ? l.homeDisconnectTooltip : l.homeConnectTooltip,
        child: Pressable(
          semanticLabel: label,
          onTap: connecting ? null : (connected ? c.disconnect : c.connect),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
            decoration: BoxDecoration(
              color: colors.glassBase,
              borderRadius: BorderRadius.circular(CamRadius.chip + 4),
              border: Border.all(color: colors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDot(on: connected),
                const SizedBox(width: 8),
                if (connected && percent != null) ...[
                  Icon(_batteryIcon(percent), size: 16, color: colors.muted),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _batteryIcon(int p) => switch (p) {
    >= 90 => Icons.battery_full,
    >= 60 => Icons.battery_5_bar,
    >= 35 => Icons.battery_3_bar,
    >= 15 => Icons.battery_2_bar,
    _ => Icons.battery_alert,
  };
}

/// Bağlantı noktası; bağlıyken neon yeşil ve parıltılı.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? c.online : c.offline,
        boxShadow: on
            ? [BoxShadow(color: c.online.withValues(alpha: 0.7), blurRadius: 8)]
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nabız kartı
// ---------------------------------------------------------------------------

/// Büyük nabız değeri, "Canlı" çipi, dinlenik nabız, köşede 3D kalp ve
/// "Şimdi ölç" (bağlı değilken pasif).
class _HeartRateHero extends StatelessWidget {
  const _HeartRateHero({required this.s});

  final DaySummary s;

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final liveHr = c.isConnected ? c.live?.heartRate ?? 0 : 0;
    final last = c.store.latest(MetricType.heartRate);
    final int? value = liveHr > 0 ? liveHr : last?.value.round();
    final resting = s.sleepHeartRate ?? s.heartRateStats?.min;
    final String? sub = liveHr > 0
        ? null
        : last != null
        ? l.homeLastMeasured(hhmm(last.time))
        : c.isConnected
        ? null
        : l.homeHeroEmpty;

    return GlassCard(
      radius: CamRadius.hero,
      padding: CamSpace.heroPadding,
      tint: camTint(colors.heroTintStart, colors.heroTintEnd),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D kalp: Arapçada sol üst köşeye geçer, kendisi çevrilmez.
          const PositionedDirectional(
            top: -14,
            end: -14,
            child: Heart3D(size: 104),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 96),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l.measureHeartRate,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (liveHr > 0) const _LiveChip(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: value == null ? null : l.homeHeroSemantics(value),
                excludeSemantics: value != null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          value?.toString() ?? l.noValue,
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -1.5,
                            fontFeatures: [
                              if (value != null) FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MetricType.heartRate.unit,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (resting != null) ...[
                const SizedBox(height: 4),
                Text(
                  l.homeRestingHr(resting.round()),
                  style: TextStyle(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (sub != null) ...[
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(color: colors.muted)),
              ],
              const SizedBox(height: 18),
              GlowButton(
                label: l.homeMeasureNow,
                icon: Icons.favorite,
                onTap: c.isConnected ? () => showMeasureSheet(context) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(CamRadius.chip),
        border: Border.all(color: c.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StatusDot(on: true),
          const SizedBox(width: 6),
          Text(
            context.l10n.homeLive,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hızlı işlemler
// ---------------------------------------------------------------------------

/// Nabız ölç, Egzersize başla, Senkronize.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    void sync() {
      if (c.isConnected) {
        c.sync();
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.ecgConnectFirst)));
    }

    return Semantics(
      container: true,
      label: l.homeQuickActions,
      explicitChildNodes: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _QuickTile(
                palette: CamArt.orbPink,
                icon: Icons.favorite,
                label: l.homeQuickHeartRate,
                onTap: () =>
                    startSpotMeasurement(context, MetricType.heartRate),
              ),
            ),
            const SizedBox(width: CamSpace.gap),
            Expanded(
              child: _QuickTile(
                palette: CamArt.orbLime,
                icon: Icons.directions_run,
                label: l.homeStartWorkout,
                onTap: () => AppShell.selectTab(context, 2),
              ),
            ),
            const SizedBox(width: CamSpace.gap),
            Expanded(
              child: _QuickTile(
                palette: CamArt.orbCyan,
                icon: Icons.sync,
                label: c.syncing ? l.homeSyncing : l.homeQuickSync,
                busy: c.syncing,
                onTap: c.syncing ? null : sync,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final OrbPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: GlassCard(
        radius: CamRadius.tile,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 14, 8, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy
                ? SizedBox.square(
                    dimension: 44,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: palette.colors[1],
                      ),
                    ),
                  )
                : Orb(palette: palette, size: 44, icon: icon),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// İki sütunlu ızgara
// ---------------------------------------------------------------------------

/// Eşit yükseklikte iki kart.
class _EqualRow extends StatelessWidget {
  const _EqualRow({required this.start, required this.end});

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: start),
        const SizedBox(width: CamSpace.gap),
        Expanded(child: end),
      ],
    ),
  );
}

/// Izgara kartı: başlık, köşede 3D nesne, büyük değer, alt satır.
class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.title,
    required this.art,
    required this.value,
    required this.onTap,
    this.unit,
    this.caption,
    this.footer,
    this.tint,
    this.semanticLabel,
  });

  final String title;
  final Widget art;
  final String? value;
  final String? unit;
  final String? caption;
  final Widget? footer;
  final Gradient? tint;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l = context.l10n;
    return Pressable(
      semanticLabel:
          semanticLabel ??
          [
            title,
            value == null ? l.noValue : [value!, ?unit].join(' '),
            ?caption,
          ].join(l.homeListSeparator),
      onTap: onTap,
      child: GlassCard(
        tint: tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                art,
              ],
            ),
            const Spacer(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value ?? context.l10n.noValue,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontFeatures: [
                          if (value != null) FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
                if (unit != null && value != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit!,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(
                caption!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
            if (footer != null) ...[const SizedBox(height: 10), footer!],
          ],
        ),
      ),
    );
  }
}

class _SleepTile extends StatelessWidget {
  const _SleepTile({required this.s, required this.onTap});

  final DaySummary s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = s.night;
    final l = context.l10n;
    final colors = context.colors;
    final muted = TextStyle(color: colors.muted, fontSize: 11);
    return _GridTile(
      title: l.homeSleep,
      art: const Moon3D(size: 48),
      tint: camTint(colors.sleepTintStart, colors.sleepTintEnd),
      value: n == null ? null : duration(n.asleepMinutes),
      caption: n == null
          ? l.homeNoRecord
          : l.homeDeepSleep(duration(n.minutesIn(SleepStage.deep))),
      onTap: onTap,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StageStrip(night: n),
          if (n != null) ...[
            const SizedBox(height: 4),
            // Saat ekseni şeritle birlikte her dilde soldan sağa akar.
            Row(
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final t in [n.start, n.end])
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(hhmm(t), style: muted),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bugün için bileklikten gelen anlık toplamlar daha günceldir.
({int steps, double kcal, double km}) _activity(
  BuildContext context,
  DaySummary s,
  bool isToday,
) {
  final live = DeviceScope.of(context).live;
  final useLive = isToday && live != null && live.steps >= s.steps;
  return useLive
      ? (steps: live.steps, kcal: live.calories, km: live.distanceKm)
      : (steps: s.steps, kcal: s.calories, km: s.distanceKm);
}

class _StepsTile extends StatelessWidget {
  const _StepsTile({
    required this.s,
    required this.isToday,
    required this.onTap,
  });

  final DaySummary s;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = _activity(context, s, isToday);
    final hasData = a.steps > 0;
    final pct = (a.steps / dailyStepGoal * 100).round();
    final l = context.l10n;
    return _GridTile(
      title: l.homeSteps,
      semanticLabel: l.homeStepGoalSemantics(a.steps, dailyStepGoal, pct),
      art: RingProgress(progress: a.steps / dailyStepGoal, size: 48),
      value: hasData ? '${a.steps}' : null,
      caption: hasData
          ? l.homeStepGoalProgress(pct, dailyStepGoal)
          : l.homeStepGoal(dailyStepGoal),
      footer: hasData
          ? Text(
              ltr('${distanceValue(a.km)} ${MetricType.distance.unit}'),
              style: TextStyle(
                color: context.colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _CaloriesTile extends StatelessWidget {
  const _CaloriesTile({
    required this.s,
    required this.isToday,
    required this.onTap,
  });

  final DaySummary s;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = _activity(context, s, isToday);
    final l = context.l10n;
    return _GridTile(
      title: l.homeCalories,
      art: const Flame3D(width: 40),
      value: a.kcal > 0 ? a.kcal.round().toString() : null,
      unit: l.homeKcal,
      caption: a.kcal > 0 ? null : l.homeNoRecord,
      onTap: onTap,
    );
  }
}

class _ActiveTimeTile extends StatelessWidget {
  const _ActiveTimeTile({required this.s, required this.onTap});

  final DaySummary s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minutes = s.workouts.fold<int>(
      0,
      (sum, w) => sum + w.duration.inMinutes,
    );
    final l = context.l10n;
    return _GridTile(
      title: l.homeActiveTime,
      art: const Orb(palette: CamArt.orbAmber, size: 44, icon: Icons.timer),
      value: minutes > 0 ? duration(minutes) : null,
      caption: l.homeActiveGoal(dailyActiveGoalMinutes),
      footer: GlowProgressBar(
        progress: minutes / dailyActiveGoalMinutes,
        palette: CamArt.orbAmber,
        height: 10,
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Kalan kartlar
// ---------------------------------------------------------------------------

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

    return GlassCard(
      child: Column(
        children: [
          const Orb(
            palette: CamArt.orbViolet,
            size: 48,
            icon: Icons.wb_twilight,
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
                VerticalDivider(color: context.colors.grid, width: 1),
                _SummaryItem(hrvBand?.label, l.homeRecovery),
                VerticalDivider(color: context.colors.grid, width: 1),
                _SummaryItem(stressBand?.label, l.homeStressLoad),
              ],
            ),
          ),
          // Gece boyunca ölçülen nabız ve kan oksijeni.
          if (night != null) ...[
            const SizedBox(height: 16),
            MiniStats([
              (
                s.sleepHeartRate == null
                    ? null
                    : l.homeBpm(s.sleepHeartRate!.round()),
                l.homeHeartRateLabel,
              ),
              (
                s.sleepSpo2 == null
                    ? null
                    : l.homePercent(s.sleepSpo2!.round()),
                l.homeBloodOxygen,
              ),
            ]),
          ],
        ],
      ),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 12,
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.homeTimeline,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
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
      ),
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(sub, style: TextStyle(color: context.colors.muted)),
      trailing: Text(
        hhmm(e.time),
        style: TextStyle(color: context.colors.muted),
      ),
      onTap: () => open(to),
    );
  }
}
