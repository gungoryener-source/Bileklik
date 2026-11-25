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

/// EKG kayıtları ve yeni ölçüm.
class EcgScreen extends StatelessWidget {
  const EcgScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.ecgTitle)),
      body: ListenableBuilder(
        listenable: c.store,
        builder: (context, _) {
          final records = c.store.ecgRecordings();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlowButton(
                onTap: () => _start(context),
                icon: Icons.monitor_heart,
                label: l.ecgStartButton,
              ),
              const SizedBox(height: 24),
              Text(
                l.ecgRecordsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (records.isEmpty)
                Text(
                  l.ecgNoRecords,
                  style: TextStyle(color: context.colors.muted),
                ),
              for (final r in records)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(
                        Icons.monitor_heart,
                        color: DataColors.heart,
                      ),
                      title: Text(
                        r.averageHeartRate == null
                            ? l.ecgNoHeartRate
                            : l.ecgAverageBpm(r.averageHeartRate!),
                      ),
                      subtitle: Text(
                        l.ecgRecordSubtitle(
                          whenText(r.start, DateTime.now()),
                          r.duration.inSeconds,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: context.colors.muted,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EcgDetailScreen(recording: r),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
