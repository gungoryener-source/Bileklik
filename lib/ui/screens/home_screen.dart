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
import '../widgets/home/activity_gauge.dart';
import '../widgets/home/day_chart.dart';
import '../widgets/home/home_card.dart';
import '../widgets/family_alerts.dart';
import '../widgets/insights.dart';
import 'ai_report_screen.dart';
import 'ecg_screen.dart';
import 'metric_detail_screen.dart';
import 'progress_screen.dart';
import 'sleep_screen.dart';
import 'spot_measure_screen.dart';
import 'workout_detail_screen.dart';

/// Ana Sayfa (Cam): başlık ve tarih gezgini; öneri ve uyku, toparlanma,
/// yük göstergeleri; AI analizi; uyku, aktivite, denge, nabız ve SpO2
/// kartları; enerji ve sağlık radarı; gece olaylarıyla zaman çizelgesi.
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
        final energy = EnergyScore.of(store, day);
        final liveHr = isToday && c.isConnected ? c.live?.heartRate ?? 0 : 0;
        final resting = s.sleepHeartRate ?? s.heartRateStats?.min;
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
              // Ailedeki acil durum, varsa en üstte.
              const FamilyAlertCard(),
              _Hero(s: s, energy: energy, isToday: isToday),
              gap,
              _AiCard(onTap: () => _open(AiReportScreen(day: s.day))),
              gap,
              _SleepCard(
                s: s,
                score: energy?.sleepScore,
                onTap: () => _open(const SleepScreen()),
              ),
              gap,
              _ActivityCard(
                s: s,
                onTap: () =>
                    _open(const MetricDetailScreen(type: MetricType.steps)),
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
                hint: c.isConnected || s.heartRateStats != null
                    ? l.homeHeartRateHint
                    : l.homeHeroEmpty,
                badge: liveHr > 0 ? _LiveChip(bpm: liveHr) : null,
                footer: [
                  (
                    resting == null ? null : l.homeBpm(resting.round()),
                    l.homeRestingLabel,
                  ),
                  (
                    s.heartRateStats == null
                        ? null
                        : l.homeBpm(s.heartRateStats!.average.round()),
                    l.homeAverageLabel,
                  ),
                ],
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
                footer: [
                  (
                    s.spo2Stats == null
                        ? null
                        : l.homePercent(s.spo2Stats!.min.round()),
                    l.homeLowestLabel,
                  ),
                  (
                    s.spo2Stats == null
                        ? null
                        : l.homePercent(s.spo2Stats!.average.round()),
                    l.homeAverageLabel,
                  ),
                ],
                onTap: () =>
                    _open(const MetricDetailScreen(type: MetricType.spo2)),
              ),
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
// Üst bölüm: öneri ve günün göstergeleri
// ---------------------------------------------------------------------------

/// Günün durumuna göre başlık ve öneri; altında uyku, toparlanma ve yük
/// göstergeleri; en altta Egzersize başla ve Şimdi ölç.
class _Hero extends StatelessWidget {
  const _Hero({required this.s, required this.energy, required this.isToday});

  final DaySummary s;
  final EnergyScore? energy;
  final bool isToday;

  /// Günlük yükün (adım ve stres harcaması, en çok 40) 0-100 ölçeği.
  static int loadOf(EnergyScore e) => (e.drain * 2.5).round().clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final now = DateTime.now();
    final night = s.night;
    final hrv = s.recoveryHrv;
    final hrvBand = hrv == null ? null : bandOf(MetricType.hrv, hrv);
    final lateNight = isToday && (now.hour >= 23 || now.hour < 5);
    final lowRecovery = (energy?.recoveryScore ?? 100) < 35;

    final String title;
    final String body;
    final IconData icon;
    if (lateNight) {
      title = l.homeLateNightTitle;
      body = l.homeLateNightBody;
      icon = Icons.nights_stay;
    } else if (night == null) {
      title = isToday ? l.homeNoSleepLastNight : l.homeNoSleepThisDay;
      body = isToday ? l.homeNoSleepTonightHint : l.homeNoSleepPastHint;
      icon = Icons.bedtime_outlined;
    } else {
      final slept = duration(night.asleepMinutes);
      final summary = hrv == null
          ? l.homeSleptSummary(slept)
          : hrvBand == null
          ? l.homeSleptHrvSummary(slept, hrv.round())
          : l.homeSleptHrvBandSummary(slept, hrv.round(), hrvBand.label);
      if (isToday && lowRecovery) {
        title = l.homeLowRecoveryTitle;
        body = '$summary ${l.homeLowRecoveryBody}';
        icon = Icons.spa;
      } else {
        title = isToday ? _greeting(l, now) : l.homeDaySummary;
        body = summary;
        icon = isToday && now.hour >= 18 ? Icons.wb_twilight : Icons.wb_sunny;
      }
    }

    final e = energy;
    return GlassCard(
      radius: CamRadius.hero,
      padding: CamSpace.heroPadding,
      tint: camTint(colors.heroTintStart, colors.heroTintEnd),
      child: Column(
        children: [
          Orb(palette: CamArt.orbViolet, size: 56, icon: icon),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Gauge(
                  label: l.homeSleepScore,
                  value: e?.sleepScore?.toString(),
                  progress: (e?.sleepScore ?? 0) / 100,
                  color: DataColors.sleepLight,
                ),
                VerticalDivider(color: colors.grid, width: 1),
                _Gauge(
                  label: l.homeDailyRecovery,
                  value: e?.recoveryScore == null
                      ? null
                      : l.homePercent(e!.recoveryScore!),
                  progress: (e?.recoveryScore ?? 0) / 100,
                  color: DataColors.hrv,
                ),
                VerticalDivider(color: colors.grid, width: 1),
                _Gauge(
                  label: l.homeDailyLoad,
                  value: e == null ? null : loadOf(e).toString(),
                  progress: e == null ? 0 : loadOf(e) / 100,
                  color: DataColors.temperature,
                ),
              ],
            ),
          ),
          if (issueText(c) case final issue?) ...[
            const SizedBox(height: 12),
            Text(issue, style: TextStyle(color: colors.danger)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AppShell.selectTab(context, 2),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                    ),
                    foregroundColor: colors.text,
                    side: BorderSide(color: colors.glassBorder),
                    backgroundColor: colors.surfaceHigh,
                  ),
                  icon: const Icon(Icons.directions_run),
                  // Dar ekranda iki satıra iner, kesilmez.
                  label: Text(
                    l.homeStartWorkout,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CamSpace.gap),
              Expanded(
                child: GlowButton(
                  label: l.homeMeasureNow,
                  icon: Icons.favorite,
                  onTap: c.isConnected ? () => showMeasureSheet(context) : null,
                ),
              ),
            ],
          ),
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

/// Büyük değer, etiket ve altında noktalı ilerleme çizgisi.
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String? value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = value ?? context.l10n.noValue;
    return Expanded(
      child: Semantics(
        label: context.l10n.homeGaugeSemantics(label, shown),
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  shown,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [
                      if (value != null) FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 10,
                child: CustomPaint(
                  size: const Size(double.infinity, 10),
                  painter: _DotLinePainter(
                    value == null ? null : progress.clamp(0.0, 1.0),
                    color,
                    colors.surfaceHigh,
                    Directionality.of(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotLinePainter extends CustomPainter {
  _DotLinePainter(this.progress, this.color, this.track, this.direction);

  /// null: değer yok, yalnızca iz çizilir.
  final double? progress;
  final Color color;
  final Color track;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4, y),
      Offset(size.width - 4, y),
      line..color = track,
    );
    final p = progress;
    if (p == null) return;
    final rtl = direction == TextDirection.rtl;
    final x = 4 + (size.width - 8) * (rtl ? 1 - p : p);
    canvas.drawLine(
      Offset(rtl ? size.width - 4 : 4, y),
      Offset(x, y),
      line..color = color.withValues(alpha: 0.8),
    );
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DotLinePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.direction != direction;
}

/// Bugünkü AI analizi: rapor ekranına geçiş.
class _AiCard extends StatelessWidget {
  const _AiCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Pressable(
      semanticLabel: l.homeAiTitle,
      onTap: onTap,
      pressedScale: 0.98,
      child: GlassCard(
        tint: camTint(
          DataColors.hrv.withValues(alpha: 0.16),
          colors.auroraViolet.withValues(alpha: 0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: DataColors.hrv),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.homeAiTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: DataColors.hrv,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, color: DataColors.hrv),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.homeAiBody, style: TextStyle(color: colors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Uyku: skor ve değerlendirme, evre şeridi (yatış-uyanış), süre, gece
/// nabzı ve SpO2.
class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.s, required this.score, required this.onTap});

  final DaySummary s;
  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final n = s.night;
    final sc = score;
    final label = sc == null
        ? null
        : sc >= 85
        ? l.homeSleepExcellent
        : sc >= 70
        ? l.homeSleepGood
        : sc >= 50
        ? l.homeSleepFair
        : l.homeSleepPoor;
    return HomeCard(
      title: l.homeSleep,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigValue(sc?.toString(), caption: label),
          const SizedBox(height: 16),
          _StageStrip(night: n),
          if (n != null) ...[
            const SizedBox(height: 6),
            Row(
              textDirection: TextDirection.ltr,
              children: [
                Icon(Icons.bedtime, size: 14, color: colors.muted),
                const SizedBox(width: 4),
                Text(
                  hhmm(n.start),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  hhmm(n.end),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.wb_sunny_outlined, size: 14, color: colors.muted),
              ],
            ),
          ],
          const SizedBox(height: 16),
          MiniStats([
            (n == null ? null : duration(n.asleepMinutes), l.homeSleepDuration),
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

/// Aktivite: adım hedefine göre yarım halka ve değerlendirme; adım,
/// kalori, mesafe.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.s, required this.onTap});

  final DaySummary s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final percent = (s.steps / dailyStepGoal * 100).round();
    final label = percent >= 100
        ? l.homeActivityDone
        : percent >= 70
        ? l.homeActivityGood
        : percent >= 30
        ? l.homeActivityFair
        : l.homeActivityLow;
    return HomeCard(
      title: l.homeActivity,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: l.homeStepGoalSemantics(s.steps, dailyStepGoal, percent),
            excludeSemantics: true,
            child: ActivityGauge(
              progress: s.steps / dailyStepGoal,
              color: DataColors.steps,
              child: BigValue(l.homePercent(percent), caption: label),
            ),
          ),
          const SizedBox(height: 16),
          MiniStats([
            ('${s.steps}', l.homeSteps),
            (s.calories.round().toString(), l.homeCalories),
            (distanceValue(s.distanceKm), l.homeKilometers),
          ]),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.bpm});

  final int bpm;

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
          const SizedBox(width: 6),
          Text(
            context.l10n.homeBpm(bpm),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
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
    this.badge,
    this.footer,
  });

  final String title;
  final MetricType type;
  final List<double?> values;
  final Stats? stats;
  final String hint;
  final IconData hintIcon;
  final VoidCallback onTap;

  /// Grafiğin üstünde (ör. canlı nabız çipi).
  final Widget? badge;

  /// Grafiğin altındaki küçük değerler (ör. dinlenik ve ortalama).
  final List<(String?, String)>? footer;

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
          if (badge case final b?) ...[
            Align(alignment: AlignmentDirectional.centerStart, child: b),
            const SizedBox(height: 12),
          ],
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
          ] else if (footer case final f?) ...[
            const SizedBox(height: 16),
            MiniStats(f),
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
          const SizedBox(height: 16),
          if (events.isEmpty)
            EmptyHint(icon: Icons.info_outline, text: l.homeTimelineEmpty)
          else
            for (final (i, e) in events.indexed)
              _eventTile(context, e, last: i == events.length - 1),
        ],
      ),
    );
  }

  Widget _eventTile(
    BuildContext context,
    TimelineEvent e, {
    required bool last,
  }) {
    final l = context.l10n;
    final colors = context.colors;
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
        Icons.wb_sunny,
        DataColors.steps,
        l.homeWokeUp,
        l.homeWokeUpSubtitle(duration(night.asleepMinutes), hhmm(night.start)),
        const SleepScreen(),
      ),
      FellAsleepEvent() => (
        Icons.bedtime,
        DataColors.sleepRem,
        l.homeFellAsleep,
        l.homeFellAsleepSubtitle,
        const SleepScreen(),
      ),
      NightEvent(:final kind, :final value) => (
        switch (kind) {
          NightEventKind.lowHrv => MetricType.hrv.icon,
          NightEventKind.highHeartRate ||
          NightEventKind.lowHeartRate => MetricType.heartRate.icon,
          NightEventKind.lowSpo2 => MetricType.spo2.icon,
        },
        kind.type.color,
        switch (kind) {
          NightEventKind.lowHrv => l.homeMs(value.round()),
          NightEventKind.highHeartRate ||
          NightEventKind.lowHeartRate => l.homeBpm(value.round()),
          NightEventKind.lowSpo2 => l.homePercent(value.round()),
        },
        switch (kind) {
          NightEventKind.lowHrv => l.homeNightLowHrv,
          NightEventKind.highHeartRate => l.homeNightHighHr,
          NightEventKind.lowHeartRate => l.homeNightLowHr,
          NightEventKind.lowSpo2 => l.homeNightLowSpo2,
        },
        MetricDetailScreen(type: kind.type),
      ),
    };
    // Simgeler alt alta noktalı bir çizgiyle bağlanır.
    return InkWell(
      onTap: () => open(to),
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.16),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  if (!last)
                    Expanded(
                      child: CustomPaint(
                        size: const Size(2, double.infinity),
                        painter: _DashPainter(colors.outline),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hhmm(e.time),
                          style: TextStyle(
                            color: colors.muted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(sub, style: TextStyle(color: colors.muted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zaman çizelgesindeki simgeleri bağlayan dikey kesikli çizgi.
class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    for (var y = 6.0; y < size.height - 2; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 3), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
