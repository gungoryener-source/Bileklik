import 'package:flutter/material.dart';

import '../../device/protocol/exercise.dart';
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
        title: const Text('Hareketsiz görünüyorsunuz'),
        content: Text(
          'Son ${prompt.minutes} dakikada 80 adımdan az attınız. '
          'Egzersizi bitirmek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bitir'),
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
        title: const Text('Egzersizi bitir'),
        content: const Text('Egzersiz kaydedilip özet gösterilecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bitir'),
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
                  ex.paused ? 'Duraklatıldı' : 'Süre',
                  style: const TextStyle(color: AppColors.muted),
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
                    const Icon(Icons.favorite, color: AppColors.heart),
                    const SizedBox(width: 6),
                    Text(
                      live == null || live.heartRate == 0
                          ? '--'
                          : '${live.heartRate}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('bpm', style: TextStyle(color: AppColors.muted)),
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
              StatTile('Adım', live?.steps.toString()),
              StatTile(
                'Kalori',
                live?.calories.round().toString(),
                unit: 'kcal',
              ),
              if (type.hasDistance) ...[
                StatTile(
                  'Mesafe',
                  live?.distanceKm.toStringAsFixed(2),
                  unit: 'km',
                ),
                StatTile(
                  'Tempo',
                  live == null || live.distanceKm < 0.01
                      ? null
                      : paceText(
                          Duration(
                            seconds: (live.durationSeconds / live.distanceKm)
                                .round(),
                          ),
                        ),
                  unit: '/km',
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
                  label: Text(ex.paused ? 'Devam et' : 'Duraklat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.heart,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _confirmStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Bitir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
