import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../device/protocol/exercise.dart';
import '../../l10n/l10n.dart';
import '../../state/device_controller.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/stat_tile.dart';
import 'workout_detail_screen.dart';

/// Süren egzersiz: süre, nabız, adım, kalori, mesafe; duraklat ve bitir.
class LiveExerciseScreen extends StatefulWidget {
  const LiveExerciseScreen({super.key});

  @override
  State<LiveExerciseScreen> createState() => _LiveExerciseScreenState();
}

class _LiveExerciseScreenState extends State<LiveExerciseScreen> {
  DeviceController? _controller;
  ExerciseInactive? _shownPrompt;
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
    final ex = c.exercise;
    if (ex == null) {
      // Egzersiz bitti: özet hazır olunca özet ekranına geç.
      if (_closing) return;
      final w = c.lastWorkout;
      if (w == null) return;
      _closing = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => WorkoutDetailScreen(workout: w, justFinished: true),
        ),
      );
      return;
    }
    final prompt = ex.prompt;
    if (prompt != null && prompt != _shownPrompt) {
      _shownPrompt = prompt;
      WidgetsBinding.instance.addPostFrameCallback((_) => _askToEnd(prompt));
    }
  }

  Future<void> _askToEnd(ExerciseInactive prompt) async {
    final end = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.liveInactiveTitle),
        // 80 adım eşiği bilekliğin kuralı (V8 API PDF).
        content: Text(context.l10n.liveInactiveBody(prompt.minutes, 80)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.liveContinue),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.liveFinish),
          ),
        ],
      ),
    );
    final c = _controller!;
    if (end ?? false) {
      await c.stopExercise();
    } else {
      c.dismissExercisePrompt();
    }
  }

  Future<void> _confirmStop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.liveConfirmTitle),
        content: Text(context.l10n.liveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.liveCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.liveFinish),
          ),
        ],
      ),
    );
    if (ok ?? false) await _controller!.stopExercise();
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final ex = c.exercise;
    if (ex == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final live = ex.live;
    final l = context.l10n;
    final type = ex.type;
    return Scaffold(
      appBar: AppBar(title: Text(type.label)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  ex.paused ? l.livePaused : l.statDuration,
                  style: TextStyle(color: context.colors.muted),
                ),
                Text(
                  clock(ex.elapsed),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: DataColors.heart),
                    const SizedBox(width: 6),
                    Text(
                      live == null || live.heartRate == 0
                          ? l.noValue
                          : '${live.heartRate}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      MetricType.heartRate.unit,
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              StatTile(MetricType.steps.label, live?.steps.toString()),
              StatTile(
                MetricType.calories.label,
                live?.calories.round().toString(),
                unit: MetricType.calories.unit,
              ),
              if (type.hasDistance) ...[
                StatTile(
                  MetricType.distance.label,
                  live?.distanceKm.toStringAsFixed(2),
                  unit: MetricType.distance.unit,
                ),
                StatTile(
                  l.statPace,
                  live == null || live.distanceKm < 0.01
                      ? null
                      : paceText(
                          Duration(
                            seconds: (live.durationSeconds / live.distanceKm)
                                .round(),
                          ),
                        ),
                  unit: '/${MetricType.distance.unit}',
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: ex.paused ? c.resumeExercise : c.pauseExercise,
                  icon: Icon(ex.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(ex.paused ? l.liveContinue : l.livePause),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: DataColors.heart,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _confirmStop,
                  icon: const Icon(Icons.stop),
                  label: Text(l.liveFinish),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
