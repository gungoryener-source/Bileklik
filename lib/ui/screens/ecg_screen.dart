import 'package:flutter/material.dart';

import '../../data/ecg_analysis.dart';
import '../../data/models.dart';
import '../../device/protocol/ecg.dart';
import '../../state/device_controller.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/ecg_trace.dart';
import '../widgets/stat_tile.dart';

const _disclaimer =
    'Bu ölçüm tıbbi tanı yerine geçmez. Göğüs ağrısı, nefes darlığı ya da '
    'bayılma hissi varsa hemen 112\'yi arayın.';

/// EKG kayıtları ve yeni ölçüm.
class EcgScreen extends StatelessWidget {
  const EcgScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final c = DeviceScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!c.isConnected) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Önce Ana Sayfa\'dan bilekliği bağlayın.'),
        ),
      );
      return;
    }
    if (await c.startEcg()) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const EcgMeasureScreen()),
      );
    } else if (c.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(c.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('EKG')),
      body: ListenableBuilder(
        listenable: c.store,
        builder: (context, _) {
          final records = c.store.ecgRecordings();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _HowTo(),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _start(context),
                icon: const Icon(Icons.monitor_heart),
                label: const Text('30 saniyelik ölçüm başlat'),
              ),
              const SizedBox(height: 24),
              Text('Kayıtlar', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (records.isEmpty)
                const Text(
                  'Henüz EKG kaydı yok.',
                  style: TextStyle(color: AppColors.muted),
                ),
              for (final r in records)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.monitor_heart,
                        color: AppColors.heart,
                      ),
                      title: Text(
                        r.averageHeartRate == null
                            ? 'Nabız hesaplanamadı'
                            : '${r.averageHeartRate} bpm ortalama',
                      ),
                      subtitle: Text(
                        '${whenText(r.start, DateTime.now())} · ${r.duration.inSeconds} sn',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.muted,
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
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nasıl ölçülür', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(
            '1. Bilekliği bileğinize sıkıca takın.\n'
            '2. Oturun, kolunuzu masaya koyun.\n'
            '3. Diğer elinizin parmağını bilekliğin üstündeki '
            'elektroda hafifçe dokundurun.\n'
            '4. 30 saniye boyunca hareket etmeyin ve konuşmayın.',
          ),
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
      if (c.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(c.error!)));
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
      child: Scaffold(
        appBar: AppBar(title: const Text('EKG ölçülüyor')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Text(
                s == null ? '--' : '${s.remaining.inSeconds} sn',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: s?.progress ?? 1,
              color: AppColors.heart,
              backgroundColor: AppColors.surface,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 20),
            Card(
              clipBehavior: Clip.antiAlias,
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
                const Icon(Icons.favorite, color: AppColors.heart),
                const SizedBox(width: 6),
                Text(
                  '${live?.averageHeartRate ?? '--'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('bpm', style: TextStyle(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Parmağınızı elektrottan kaldırmayın ve hareket etmeyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                _closing = true;
                await c.cancelEcg();
                navigator.pop();
              },
              child: const Text('Ölçümü iptal et'),
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
    final summary = EcgSummary.analyze(r.samples, r.sampleRate);
    const secondsPerRow = 5;
    final rows = (r.samples.length / (secondsPerRow * r.sampleRate)).ceil();
    return Scaffold(
      appBar: AppBar(
        title: Text('EKG · ${dayMonth(r.start)} ${hhmm(r.start)}'),
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
                'Ortalama nabız',
                r.averageHeartRate?.toString(),
                unit: 'bpm',
              ),
              StatTile(
                'Aralık',
                r.minHeartRate == null
                    ? null
                    : '${r.minHeartRate}-${r.maxHeartRate}',
                unit: 'bpm',
              ),
              StatTile('Atım sayısı', '${r.beats}'),
              StatTile(
                'Değişkenlik (SDNN)',
                r.sdnn?.round().toString(),
                unit: 'ms',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Kayıt (${r.duration.inSeconds} sn, satır başına 5 sn)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Card(
                clipBehavior: Clip.antiAlias,
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
          const Text(_disclaimer, style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
