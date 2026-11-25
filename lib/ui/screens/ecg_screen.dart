import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/ecg_analysis.dart';
import '../../data/models.dart';
import '../../device/protocol/ecg.dart';
import '../../l10n/l10n.dart';
import '../../state/device_controller.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ecg_trace.dart';
import '../widgets/stat_tile.dart';
import '../widgets/cam/cam.dart';
import 'diagnostics_screen.dart';

/// EKG: yeni ölçüm ve aylara göre EKG raporu.
///
/// Rapor, seçilen ayın her kaydı için tarih, üç satırlık dalga şeridi ve
/// dört bulgu (ritim, yüksek/düşük kalp hızı, atriyal fibrilasyon) gösterir.
class EcgScreen extends StatefulWidget {
  const EcgScreen({super.key});

  @override
  State<EcgScreen> createState() => _EcgScreenState();
}

class _EcgScreenState extends State<EcgScreen> {
  /// Seçilen ay (günü 1). Boşsa en son kaydın ayı, kayıt yoksa bu ay.
  DateTime? _month;

  // Bulgular her çizimde yeniden hesaplanmasın; kayıt değişmez.
  final _findings = Expando<EcgFindings>();

  EcgFindings _findingsOf(EcgRecording r) => _findings[r] ??= EcgFindings.of(
    EcgSummary.analyze(r.samples, r.sampleRate),
  );

  void _start(BuildContext context) {
    final c = DeviceScope.of(context);
    if (!c.isConnected) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.ecgConnectFirst)));
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EcgPrepareScreen()));
  }

  static DateTime _monthOf(DateTime t) => DateTime(t.year, t.month);

  Future<void> _pickMonth(
    BuildContext context,
    List<EcgRecording> records,
    DateTime current,
  ) async {
    final counts = <DateTime, int>{};
    for (final r in records) {
      counts.update(_monthOf(r.start), (n) => n + 1, ifAbsent: () => 1);
    }
    counts.putIfAbsent(current, () => 0);
    final months = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    final picked = await showCamSheet<DateTime>(
      context: context,
      builder: (ctx) {
        final l = ctx.l10n;
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 20, 12, 12),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, bottom: 8),
                child: Text(
                  l.ecgReportPickMonth,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final m in months)
                ListTile(
                  minTileHeight: 56,
                  title: Text(monthYear(m)),
                  subtitle: Text(l.ecgReportMonthCount(counts[m]!)),
                  trailing: m == current
                      ? Icon(Icons.check, color: ctx.colors.accent)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(m),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null && mounted) setState(() => _month = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.ecgTitle)),
      body: ListenableBuilder(
        listenable: c.store,
        builder: (context, _) {
          final all = c.store.ecgRecordings();
          final month =
              _month ?? _monthOf(all.firstOrNull?.start ?? DateTime.now());
          final records = [
            for (final r in all)
              if (_monthOf(r.start) == month) r,
          ];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlowButton(
                onTap: () => _start(context),
                icon: Icons.monitor_heart,
                label: l.ecgStartButton,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.ecgReportTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MonthButton(
                    label: monthYear(month),
                    onTap: () => _pickMonth(context, all, month),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (records.isEmpty)
                GlassCard(
                  child: Text(
                    all.isEmpty
                        ? l.ecgNoRecords
                        : l.ecgReportMonthEmpty(monthYear(month)),
                    style: TextStyle(color: context.colors.muted),
                  ),
                )
              else ...[
                for (final r in records)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: EcgReportCard(
                      recording: r,
                      findings: _findingsOf(r),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EcgDetailScreen(recording: r),
                        ),
                      ),
                    ),
                  ),
                Text(
                  l.ecgReportNote,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.colors.muted),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Raporun sağ üstündeki ay seçici.
class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: context.colors.text,
      side: BorderSide(color: context.colors.outline),
    ),
    iconAlignment: IconAlignment.end,
    icon: const Icon(Icons.expand_more, size: 20),
    label: Text(label),
  );
}

/// Rapordaki bir EKG kaydı: tarih ve nabız, dalga şeridi ve bulgular.
class EcgReportCard extends StatelessWidget {
  const EcgReportCard({
    super.key,
    required this.recording,
    required this.findings,
    this.onTap,
  });

  final EcgRecording recording;
  final EcgFindings findings;
  final VoidCallback? onTap;

  /// Şeritte gösterilen satır sayısı ve satır başına süre.
  static const rows = 3;
  static const secondsPerRow = 6;

  @override
  Widget build(BuildContext context) {
    final r = recording;
    final l = context.l10n;
    final muted = context.colors.muted;
    final perRow = secondsPerRow * r.sampleRate;
    final shown = (r.samples.length / perRow).ceil().clamp(1, rows);
    final f = findings;
    final when = l.ecgReportWhen(longDate(r.start), hhmm(r.start));
    final card = GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  when,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: muted),
                ),
              ),
              if (r.averageHeartRate case final bpm?)
                Text(
                  l.ecgAverageBpm(bpm),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DataColors.heart,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Icon(Icons.chevron_right, color: muted),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                for (var i = 0; i < shown; i++)
                  EcgTrace(
                    samples: r.samples,
                    sampleRate: r.sampleRate,
                    seconds: secondsPerRow.toDouble(),
                    height: 72,
                    offset: i * perRow,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!f.assessable)
            _Finding(FindingState.unknown, l.ecgFindingUnknown)
          else ...[
            _Finding(
              f.normalRhythm,
              f.normalRhythm == FindingState.ok
                  ? l.ecgFindingNormalOk
                  : l.ecgFindingNormalFlagged,
            ),
            _Finding(
              f.highRate,
              f.highRate == FindingState.ok
                  ? l.ecgFindingHighOk
                  : l.ecgFindingHighFlagged,
            ),
            _Finding(
              f.lowRate,
              f.lowRate == FindingState.ok
                  ? l.ecgFindingLowOk
                  : l.ecgFindingLowFlagged,
            ),
            _Finding(
              f.afib,
              f.afib == FindingState.ok
                  ? l.ecgFindingAfibOk
                  : l.ecgFindingAfibFlagged,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: [
        when,
        if (r.averageHeartRate case final bpm?) l.ecgAverageBpm(bpm),
      ].join(', '),
      child: card,
    );
  }
}

/// Tek bulgu satırı: yuvarlak simge ve metin.
class _Finding extends StatelessWidget {
  const _Finding(this.state, this.text);

  final FindingState state;
  final String text;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      FindingState.ok => (Icons.check, DataColors.steps),
      FindingState.flagged => (Icons.priority_high, context.colors.danger),
      FindingState.unknown => (Icons.question_mark, context.colors.muted),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Bilekliğin takıldığı el (I. derivasyonda dalganın yönünü belirler).
enum EcgHand { left, right }

/// EKG öncesi hazırlık: el seçimi, takma önerisi ve ölçüm talimatları.
class EcgPrepareScreen extends StatefulWidget {
  const EcgPrepareScreen({super.key});

  /// Seçilen el telefonda saklanır; sonraki ölçümde hazır gelir.
  static const handKey = 'ecg_hand';

  @override
  State<EcgPrepareScreen> createState() => _EcgPrepareScreenState();
}

class _EcgPrepareScreenState extends State<EcgPrepareScreen> {
  EcgHand _hand = EcgHand.left;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  // Tercih okunamazsa (ör. depo yok) sol el varsayılır; ölçüm yine yapılır.
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(EcgPrepareScreen.handKey);
      if (!mounted || saved == null) return;
      setState(() => _hand = EcgHand.values.asNameMap()[saved] ?? _hand);
    } catch (_) {}
  }

  Future<void> _select(EcgHand hand) async {
    setState(() => _hand = hand);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(EcgPrepareScreen.handKey, hand.name);
    } catch (_) {}
  }

  Future<void> _start() async {
    final c = DeviceScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    if (!c.isConnected) {
      messenger.showSnackBar(SnackBar(content: Text(l.ecgConnectFirst)));
      return;
    }
    setState(() => _starting = true);
    final ok = await c.startEcg(invert: _hand == EcgHand.right);
    if (!mounted) return;
    setState(() => _starting = false);
    if (ok) {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const EcgMeasureScreen()),
      );
    } else if (issueText(c) case final message?) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final tips = [
      (Icons.event_seat_outlined, l.ecgTip1Title, l.ecgTip1Body),
      (Icons.table_restaurant_outlined, l.ecgTip2Title, l.ecgTip2Body),
      (Icons.volume_off_outlined, l.ecgTip3Title, l.ecgTip3Body),
      (Icons.touch_app_outlined, l.ecgTip4Title, l.ecgTip4Body),
    ];
    return CamScaffold(
      appBar: AppBar(title: Text(l.ecgPrepareTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
          children: [
            _WristPicture(hand: _hand),
            const SizedBox(height: 20),
            Text(
              l.ecgHandQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final h in EcgHand.values) ...[
                  if (h != EcgHand.values.first) const SizedBox(width: 12),
                  Expanded(
                    child: _HandButton(
                      label: h == EcgHand.left ? l.ecgHandLeft : l.ecgHandRight,
                      selected: _hand == h,
                      onTap: () => _select(h),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.ecgWearTip,
              style: TextStyle(color: colors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            GlowButton(
              onTap: _starting ? null : _start,
              loading: _starting,
              icon: Icons.monitor_heart,
              label: l.ecgStartMeasure,
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Column(
                children: [
                  for (final (i, t) in tips.indexed) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _Tip(icon: t.$1, title: t.$2, body: t.$3),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bileklik takılı bilek ve diğer elin parmağı; seçilen ele göre aynalanır.
class _WristPicture extends StatelessWidget {
  const _WristPicture({required this.hand});
  final EcgHand hand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Sol bilekte bileklik solda, dokunan parmak sağdan gelir.
    final watchOnStart = hand == EcgHand.left;
    final watch = Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(color: colors.glow, shape: BoxShape.circle),
      child: Icon(Icons.watch, size: 48, color: colors.accent),
    );
    final finger = Transform.flip(
      flipX: !watchOnStart,
      child: Icon(Icons.touch_app, size: 56, color: colors.text),
    );
    return GlassCard(
      child: SizedBox(
        height: 132,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedSwitcher(
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: Row(
              key: ValueKey(hand),
              mainAxisAlignment: MainAxisAlignment.center,
              children: watchOnStart
                  ? [watch, const SizedBox(width: 24), finger]
                  : [finger, const SizedBox(width: 24), watch],
            ),
          ),
        ),
      ),
    );
  }
}

class _HandButton extends StatelessWidget {
  const _HandButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme.titleMedium;
    final style = selected
        ? FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: colors.text,
            foregroundColor: colors.background,
            textStyle: text?.copyWith(fontWeight: FontWeight.w700),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: colors.text,
            side: BorderSide(color: colors.outline),
            textStyle: text?.copyWith(fontWeight: FontWeight.w500),
          );
    return Semantics(
      selected: selected,
      button: true,
      child: selected
          ? FilledButton(onPressed: onTap, style: style, child: Text(label))
          : OutlinedButton(onPressed: onTap, style: style, child: Text(label)),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: colors.glow, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: colors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: colors.muted, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Süren ölçüm: son 5 saniyenin çizgisi ve kalan süre.
class EcgMeasureScreen extends StatefulWidget {
  const EcgMeasureScreen({super.key});

  @override
  State<EcgMeasureScreen> createState() => _EcgMeasureScreenState();
}

class _EcgMeasureScreenState extends State<EcgMeasureScreen> {
  DeviceController? _controller;
  bool _closing = false;

  /// Sinyal beklenirken geçen süreyi göstermek için saniyede bir yenilenir.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = DeviceScope.of(context);
    if (c != _controller) {
      _controller?.removeListener(_onChange);
      _controller = c..addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _controller?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final c = _controller!;
    if (c.ecg != null || _closing) return;
    _closing = true;
    final r = c.lastEcg;
    final navigator = Navigator.of(context);
    if (r == null) {
      navigator.pop();
      if (issueText(c) case final message?) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => EcgDetailScreen(recording: r)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final s = c.ecg;
    final samples = s?.samples ?? const <int>[];
    final rate = s?.rate ?? ecgSampleRate;
    final shown = (5 * rate).clamp(0, samples.length);
    final live = samples.length > 3 * rate
        ? EcgSummary.analyze(samples.sublist(samples.length - 3 * rate), rate)
        : null;
    final waiting = s?.waiting ?? false;
    final waited = s == null ? 0 : DateTime.now().difference(s.start).inSeconds;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && c.ecg != null) c.cancelEcg();
      },
      child: CamScaffold(
        appBar: AppBar(title: Text(l.ecgMeasuringTitle)),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, color: DataColors.heart, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${live?.averageHeartRate ?? l.noValue}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(l.ecgBpm, style: TextStyle(color: colors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: EdgeInsets.zero,
                child: EcgTrace(
                  samples: samples,
                  sampleRate: rate,
                  offset: samples.length - shown,
                ),
              ),
              const SizedBox(height: 20),
              if (waiting) ...[
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l.ecgWaitingElapsed(waited),
                        style: TextStyle(color: colors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l.ecgWaitingTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l.ecgWaitingBody,
                  style: TextStyle(color: colors.muted, height: 1.4),
                ),
                if (waited >= 15) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.ecgNoSignalYetTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.ecgNoSignalYetBody,
                          style: TextStyle(color: colors.muted, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DiagnosticsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.troubleshoot),
                          label: Text(l.diagOpen),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      s == null ? l.noValue : '${s.remaining.inSeconds}',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.ecgSecondsUnit,
                      style: TextStyle(fontSize: 22, color: colors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: s?.progress ?? 1,
                  color: DataColors.heart,
                  backgroundColor: colors.surface,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  l.ecgKeepStill,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l.ecgLiveDisclaimer,
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  _closing = true;
                  await c.cancelEcg();
                  navigator.pop();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(l.ecgCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EcgDetailScreen extends StatelessWidget {
  const EcgDetailScreen({super.key, required this.recording});

  final EcgRecording recording;

  @override
  Widget build(BuildContext context) {
    final r = recording;
    final l = context.l10n;
    final summary = EcgSummary.analyze(r.samples, r.sampleRate);
    const secondsPerRow = 5;
    final rows = (r.samples.length / (secondsPerRow * r.sampleRate)).ceil();
    return CamScaffold(
      appBar: AppBar(
        title: Text(l.ecgDetailTitle(dayMonth(r.start), hhmm(r.start))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              StatTile(
                l.ecgAverageHeartRate,
                r.averageHeartRate?.toString(),
                unit: l.ecgBpm,
              ),
              StatTile(
                l.ecgRange,
                r.minHeartRate == null || r.maxHeartRate == null
                    ? null
                    : l.ecgRangeValue(r.minHeartRate!, r.maxHeartRate!),
                unit: l.ecgBpm,
              ),
              StatTile(l.ecgBeats, '${r.beats}'),
              StatTile(l.ecgSdnn, r.sdnn?.round().toString(), unit: l.ecgMs),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l.ecgRecordHeader(r.duration.inSeconds, secondsPerRow),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: EcgTrace(
                  samples: r.samples,
                  sampleRate: r.sampleRate,
                  seconds: secondsPerRow.toDouble(),
                  height: 110,
                  offset: i * secondsPerRow * r.sampleRate,
                  peaks: summary.peaks,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(l.ecgDisclaimer, style: TextStyle(color: context.colors.muted)),
        ],
      ),
    );
  }
}
