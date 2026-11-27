import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/aggregate.dart';
import '../../data/bedtime.dart';
import '../../data/day_summary.dart';
import '../../data/progress.dart';
import '../../data/recovery.dart';
import '../../data/strain.dart';
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
import '../widgets/home/energy_gem.dart';
import '../widgets/home/home_card.dart';
import '../widgets/family_alerts.dart';
import '../widgets/insights.dart';
import 'ai_report_screen.dart';
import 'bedtime_screen.dart';
import 'biological_age_screen.dart';
import 'strain_screen.dart';
import 'ecg_screen.dart';
import 'metric_detail_screen.dart';
import 'progress_screen.dart';
import 'recovery_screen.dart';
import 'training_plan.dart';
import 'sleep_screen.dart';
import 'spot_measure_screen.dart';
import 'workout_detail_screen.dart';

/// Ana Sayfa (Cam): başlık ve tarih gezgini; öneri ve uyku, toparlanma,
/// yük göstergeleri; AI analizi; uyku, aktivite, denge, nabız ve SpO2
/// kartları; enerji ve sağlık radarı; gece olaylarıyla zaman çizelgesi.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Gece görünümü için saat; testler sabit bir an verir.
  static DateTime Function() clock = DateTime.now;

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

  /// 22:00-05:00 arası bugün açıksa Ana Sayfa sakinleşme görünümüne geçer.
  bool get windDown => isToday && isWindDownTime(HomeScreen.clock());

  Timer? _windDownTimer;

  @override
  void initState() {
    super.initState();
    _scheduleWindDown();
  }

  /// Saat 22:00'yi ya da 05:00'i geçince görünüm kendiliğinden değişir.
  void _scheduleWindDown() {
    final now = HomeScreen.clock();
    _windDownTimer = Timer(nextWindDownChange(now).difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleWindDown();
    });
  }

  @override
  void dispose() {
    _windDownTimer?.cancel();
    super.dispose();
  }

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
        final recovery = DayRecovery.of(store, day);
        final strain = DayStrain.of(store, day, age: c.profile?.age);
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
                streak: dataStreak(store, DateTime.now()),
                onPrev: () => _shift(-1),
                onNext: isToday ? null : () => _shift(1),
                onPick: _pickDay,
              ),
              const SizedBox(height: 8),
              // Ailedeki acil durum, varsa en üstte.
              const FamilyAlertCard(),
              _Hero(
                s: s,
                energy: energy,
                yesterdayEnergy: EnergyScore.of(
                  store,
                  DateTime(day.year, day.month, day.day - 1),
                ),
                recovery: recovery,
                strain: strain,
                open: _open,
                windDown: windDown,
              ),
              gap,
              _AiCard(
                s: s,
                energy: energy,
                recovery: recovery,
                strain: strain,
                isToday: isToday,
                onReport: () => _open(AiReportScreen(day: s.day)),
              ),
              gap,
              BiologicalAgeHomeCard(
                store: store,
                day: s.day,
                age: c.profile?.age,
                onTap: () => _open(BiologicalAgeScreen(day: s.day)),
              ),
              gap,
              _SleepCard(
                s: s,
                score: energy?.sleepScore,
                onTap: () => _open(SleepScreen(day: s.day)),
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
              HealthRadarCard(
                store: store,
                day: s.day,
                baseColor: HomeSky.card,
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

/// Üst satır: profil, veri serisi, eşitleme, ölçüm ve bileklik çipi;
/// altında ortalanmış tarih gezgini.
class _Header extends StatelessWidget {
  const _Header({
    required this.day,
    required this.isToday,
    required this.streak,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final DateTime day;
  final bool isToday;
  final int streak;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final name = isToday
        ? l.homeToday
        : day == yesterday
        ? l.homeYesterday
        : weekdayLong(day.weekday);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Tooltip(
              message: l.navProfile,
              child: Pressable(
                semanticLabel: l.navProfile,
                onTap: () => AppShell.selectTab(context, 3),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: HomeSky.green,
                  ),
                  child: const Icon(Icons.person, color: HomeSky.bottom),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: l.homeStreakSemantics(streak),
              excludeSemantics: true,
              child: Container(
                height: 40,
                padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 14, 0),
                decoration: BoxDecoration(
                  color: HomeSky.pill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 20,
                      color: HomeSky.yellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Eşitleme simgesi yalnızca genişçe ekranda; her zaman aşağı
            // çekerek de eşitlenir.
            if (MediaQuery.sizeOf(context).width >= 360)
              IconButton(
                tooltip: l.healthSyncTooltip,
                onPressed: c.isConnected && !c.syncing ? c.sync : null,
                icon: const Icon(Icons.sync),
              ),
            IconButton(
              tooltip: l.homeMeasureNow,
              onPressed: c.isConnected ? () => showMeasureSheet(context) : null,
              icon: const Icon(Icons.monitor_heart_outlined),
            ),
            Flexible(
              child: _BandChip(compact: MediaQuery.sizeOf(context).width < 400),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
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
                style: TextButton.styleFrom(foregroundColor: colors.text),
                icon: const Icon(Icons.calendar_month, size: 20),
                label: Text(
                  l.homeWeekdayDate(name, dayMonth(day)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l.homeNextDay,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bileklik çipi: bağlıyken yeşil nokta ve pil, değilken gri nokta ve
/// "Bağlı değil". Dokununca bağlanır ya da bağlantıyı keser.
class _BandChip extends StatelessWidget {
  const _BandChip({this.compact = false});

  /// Dar ekranda yalnızca nokta ve pil simgesi; ad ekran okuyucuda kalır.
  final bool compact;

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
            padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: colors.glassBase,
              borderRadius: BorderRadius.circular(CamRadius.chip + 4),
              border: Border.all(color: colors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusDot(on: connected),
                if (connected && percent != null) ...[
                  const SizedBox(width: 6),
                  Icon(_batteryIcon(percent), size: 16, color: colors.muted),
                ],
                if (!compact) const SizedBox(width: 4),
                if (!compact)
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

/// Üst bölüm (kartsız, gökyüzü üstünde): zümrüt kristalde enerji skoru,
/// düne göre değişim, uyku/toparlanma/yük göstergeleri ve iki hap düğme.
/// Arkada kodla çizilen dağ silueti.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.s,
    required this.energy,
    required this.yesterdayEnergy,
    required this.recovery,
    required this.strain,
    required this.open,
    this.windDown = false,
  });

  final DaySummary s;
  final EnergyScore? energy;
  final EnergyScore? yesterdayEnergy;
  final DayRecovery? recovery;
  final DayStrain? strain;
  final void Function(Widget) open;

  /// Gece: enerji kristali yerine yıldızlı sakinleşme çağrısı.
  final bool windDown;

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final e = energy;
    final level = e == null
        ? null
        : switch (e.level) {
            EnergyLevel.high => l.homeEnergyHigh,
            EnergyLevel.medium => l.homeEnergyNormal,
            EnergyLevel.low => l.homeEnergyLow,
          };
    final y = yesterdayEnergy;
    final String compare;
    if (e == null || y == null) {
      compare = l.homeEnergyNoCompare;
    } else {
      final d = e.score - y.score;
      compare = d == 0
          ? l.homeEnergySame
          : l.homeEnergyVsYesterday(ltr(d > 0 ? '+$d' : '−${-d}'));
    }
    final score = e?.score.toString() ?? l.noValue;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (windDown) const Positioned.fill(child: _StarField()),
        Column(
          children: [
            const SizedBox(height: 8),
            if (windDown)
              _WindDownIntro(onMore: () => open(BedtimeScreen(day: s.day)))
            else ...[
              Pressable(
                semanticLabel: e == null
                    ? l.energyEmpty
                    : l.energySemantics(e.score, level!),
                onTap: () => open(ProgressScreen(day: s.day)),
                child: EnergyGem(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: HomeSky.snow, size: 22),
                        Text(
                          l.homeEnergyLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          score,
                          style: const TextStyle(
                            fontSize: 60,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (level != null)
                          Text(
                            level,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: HomeSky.pill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(compare, style: const TextStyle(fontSize: 14)),
              ),
            ],
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Gauge(
                    label: l.homeSleepScore,
                    value: e?.sleepScore?.toString(),
                    progress: (e?.sleepScore ?? 0) / 100,
                    color: HomeSky.green,
                    onTap: () => open(SleepScreen(day: s.day)),
                  ),
                  VerticalDivider(color: colors.outline, width: 1),
                  _Gauge(
                    label: l.homeDailyRecovery,
                    value: recovery == null
                        ? null
                        : l.homePercent(recovery!.score),
                    progress: (recovery?.score ?? 0) / 100,
                    color: HomeSky.blue,
                    onTap: () => open(RecoveryScreen(day: s.day)),
                  ),
                  VerticalDivider(color: colors.outline, width: 1),
                  _Gauge(
                    label: l.homeDailyLoad,
                    value: strain == null
                        ? null
                        : ltr(oneDecimal(strain!.score)),
                    progress: (strain?.score ?? 0) / DayStrain.max,
                    color: HomeSky.green,
                    onTap: () => open(StrainScreen(day: s.day)),
                  ),
                ],
              ),
            ),
            if (issueText(c) case final issue?) ...[
              const SizedBox(height: 12),
              Text(issue, style: TextStyle(color: colors.danger)),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    icon: Icons.directions_run,
                    label: l.homeStartWorkout,
                    onTap: () => AppShell.selectTab(context, 2),
                  ),
                ),
                const SizedBox(width: CamSpace.gap),
                Expanded(
                  child: _PillButton(
                    icon: Icons.auto_awesome,
                    label: l.homeTrainingPlan,
                    onTap: () => showTrainingPlan(
                      context,
                      recovery: recovery,
                      age: c.profile?.age,
                      onStart: () => AppShell.selectTab(context, 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}

/// Gece görünümünün başı: ay ikonu, başlık, kısa açıklama ve Yatma
/// Düzeni ekranına giden düğme.
class _WindDownIntro extends StatelessWidget {
  const _WindDownIntro({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: HomeSky.pill,
              ),
              child: const Icon(
                Icons.nights_stay_outlined,
                color: HomeSky.snow,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              l.homeLateNightTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.homeLateNightBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onMore,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              foregroundColor: colors.text,
              backgroundColor: HomeSky.pill.withValues(alpha: 0.18),
              side: const BorderSide(color: HomeSky.border),
              shape: const StadiumBorder(),
            ),
            child: Text(
              l.homeNightMore,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Gece görünümünün arkasındaki yıldızlar: kodla, sabit tohumla çizilir
/// (her açılışta aynı gökyüzü); hareket etmez.
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(child: CustomPaint(painter: _StarPainter())),
    ),
  );
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(22);
    final dot = Paint();
    // Aşağıya doğru seyrelir; dağın üstünde yıldız kalmaz.
    for (var i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = pow(rnd.nextDouble(), 1.6) * size.height * 0.75;
      final r = 0.4 + rnd.nextDouble() * 1.1;
      final a = 0.25 + rnd.nextDouble() * 0.6;
      canvas.drawCircle(
        Offset(x, y.toDouble()),
        r,
        dot..color = HomeSky.snow.withValues(alpha: a),
      );
    }
    // Birkaç parlak, dört kollu yıldız.
    final glint = Paint()
      ..color = HomeSky.snow.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final c = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height * 0.55,
      );
      final arm = 3.0 + rnd.nextDouble() * 2.5;
      canvas
        ..drawLine(c.translate(-arm, 0), c.translate(arm, 0), glint)
        ..drawLine(c.translate(0, -arm), c.translate(0, arm), glint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// Yarı saydam hap düğme.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      foregroundColor: context.colors.text,
      backgroundColor: HomeSky.pill.withValues(alpha: 0.18),
      side: const BorderSide(color: HomeSky.border),
      shape: const StadiumBorder(),
    ),
    icon: Icon(icon),
    label: Text(
      label,
      maxLines: 2,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    ),
  );
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    this.onTap,
  });

  final String label;
  final String? value;
  final double progress;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = value ?? context.l10n.noValue;
    final semantics = context.l10n.homeGaugeSemantics(label, shown);
    final tap = onTap;
    Widget wrap(Widget child) => tap == null
        ? Semantics(label: semantics, excludeSemantics: true, child: child)
        : Pressable(
            semanticLabel: semantics,
            pressedScale: 0.95,
            onTap: tap,
            child: child,
          );
    return Expanded(
      child: wrap(
        Padding(
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

/// Bugünkü AI analizi: günün kısa değerlendirmesi; açılıp kapanır.
/// Altta verinin güncellendiği saat ve ayrıntılı rapora geçiş.
class _AiCard extends StatefulWidget {
  const _AiCard({
    required this.s,
    required this.energy,
    required this.recovery,
    required this.strain,
    required this.isToday,
    required this.onReport,
  });

  final DaySummary s;
  final EnergyScore? energy;
  final DayRecovery? recovery;
  final DayStrain? strain;
  final bool isToday;
  final VoidCallback onReport;

  @override
  State<_AiCard> createState() => _AiCardState();
}

class _AiCardState extends State<_AiCard> {
  bool _open = true;

  List<String> _lines(BuildContext context) {
    final l = context.l10n;
    final s = widget.s;
    final night = s.night;
    final hrv = s.recoveryHrv;
    final hrvBand = hrv == null ? null : bandOf(MetricType.hrv, hrv);
    final out = <String>[];
    if (night == null) {
      if (widget.isToday) out.add(l.homeNoSleepTonightHint);
    } else {
      final slept = duration(night.asleepMinutes);
      out.add(
        hrv == null
            ? l.homeSleptSummary(slept)
            : hrvBand == null
            ? l.homeSleptHrvSummary(slept, hrv.round())
            : l.homeSleptHrvBandSummary(slept, hrv.round(), hrvBand.label),
      );
    }
    if (widget.recovery case final r?) out.add(r.level.comment);
    if (widget.strain case final st?) {
      out.add(l.homeAiLoad(ltr(oneDecimal(st.score))));
    }
    if (out.isEmpty) out.add(l.homeAiNoData);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final synced = DeviceScope.of(context).lastSync;
    final text = _lines(context).join(' ');
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CamRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeSky.ai, HomeSky.aiBlue],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: HomeSky.inner,
            borderRadius: BorderRadius.circular(CamRadius.card - 1.5),
          ),
          child: Padding(
            padding: CamSpace.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: HomeSky.ai),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.homeAiTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: HomeSky.ai,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _open = !_open),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.muted,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: Icon(
                          _open ? Icons.expand_less : Icons.expand_more,
                        ),
                        label: Text(
                          _open ? l.homeAiCollapse : l.homeAiExpand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedSize(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    text,
                    maxLines: _open ? null : 2,
                    overflow: _open ? null : TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.45, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: synced == null
                          ? const SizedBox.shrink()
                          : Text(
                              l.homeAiUpdated(hhmm(synced)),
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 12,
                              ),
                            ),
                    ),
                    Flexible(
                      child: TextButton(
                        onPressed: widget.onReport,
                        style: TextButton.styleFrom(
                          foregroundColor: HomeSky.green,
                        ),
                        child: Text(
                          l.homeAiReanalyze,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          BigValue(sc?.toString(), caption: label, color: HomeSky.green),
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
              color: HomeSky.chart,
              child: BigValue(
                l.homePercent(percent),
                caption: label,
                color: HomeSky.blue,
              ),
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

/// Şeritte evreler beyazın tonlarıyla: derin en açık, uyanık en koyu.
Color _stripColor(SleepStage s) => switch (s) {
  SleepStage.deep => HomeSky.chart,
  SleepStage.light => HomeSky.chart.withValues(alpha: 0.55),
  SleepStage.rem => HomeSky.chart.withValues(alpha: 0.32),
  SleepStage.awake => HomeSky.chart.withValues(alpha: 0.14),
};

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
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 28,
          child: runs.isEmpty
              ? ColoredBox(color: context.colors.surfaceHigh)
              : Row(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (stage, minutes) in runs)
                      Expanded(
                        flex: minutes,
                        child: ColoredBox(color: _stripColor(stage)),
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
            color: HomeSky.green,
            caption: band == null
                ? l.homeAverageStress
                : l.homeAverageStressBand(band.label),
          ),
          const SizedBox(height: 16),
          DayBars(
            values: s.hourlyStress,
            max: 100,
            colorOf: (_) => HomeSky.chart,
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
            color: HomeSky.chart,
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
      baseColor: HomeSky.card,
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
        SleepScreen(day: night.day),
      ),
      FellAsleepEvent(:final night) => (
        Icons.bedtime,
        DataColors.sleepRem,
        l.homeFellAsleep,
        l.homeFellAsleepSubtitle,
        SleepScreen(day: night.day),
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
