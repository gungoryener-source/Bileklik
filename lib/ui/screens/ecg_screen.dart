import 'package:flutter/material.dart';

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

/// EKG kayıtları ve yeni ölçüm.
class EcgScreen extends StatelessWidget {
  const EcgScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final c = DeviceScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!c.isConnected) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.ecgConnectFirst)),
      );
      return;
    }
    if (await c.startEcg()) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const EcgMeasureScreen()),
      );
    } else if (issueText(c) case final message?) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
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
              const _HowTo(),
              const SizedBox(height: 16),
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

class _HowTo extends StatelessWidget {
  const _HowTo();

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.ecgHowToTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.ecgHowToSteps),
        ],
      ),
    ),
  );
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
    final s = c.ecg;
    final samples = s?.samples ?? const <int>[];
    const rate = ecgSampleRate;
    final shown = (5 * rate).clamp(0, samples.length);
    final live = samples.length > 3 * rate
        ? EcgSummary.analyze(samples.sublist(samples.length - 3 * rate), rate)
        : null;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && c.ecg != null) c.cancelEcg();
      },
      child: CamScaffold(
        appBar: AppBar(title: Text(l.ecgMeasuringTitle)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text(
                s == null ? l.noValue : l.ecgSecondsLeft(s.remaining.inSeconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: s?.progress ?? 1,
              color: DataColors.heart,
              backgroundColor: context.colors.surface,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: EdgeInsets.zero,
              child: EcgTrace(
                samples: samples,
                sampleRate: rate,
                offset: samples.length - shown,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: DataColors.heart),
                const SizedBox(width: 6),
                Text(
                  '${live?.averageHeartRate ?? l.noValue}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(l.ecgBpm, style: TextStyle(color: context.colors.muted)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.ecgKeepStill,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                _closing = true;
                await c.cancelEcg();
                navigator.pop();
              },
              child: Text(l.ecgCancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir EKG kaydı: tüm çizgi (kaydırılabilir), nabız ve atım değişkenliği.
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
