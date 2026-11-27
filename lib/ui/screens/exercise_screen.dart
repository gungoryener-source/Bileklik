import 'package:flutter/material.dart';

import '../../device/protocol/exercise.dart';
import '../../device/transport.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/cam_map.dart';
import 'live_exercise_screen.dart';
import 'workout_records_screen.dart';

/// Egzersiz sekmesi: toplam süre ve sayı, spor sekmeleri, harita zemininde
/// GPS / iç mekan seçimi, hedef, büyük başlat düğmesi ve spor türü.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  /// Sekmelerde doğrudan görünen türler; diğerleri "Daha fazla" altında.
  static const quick = [SportType.run, SportType.cycling, SportType.walk];

  /// Seçilebilen süre hedefleri (dakika).
  static const goals = [15, 30, 45, 60, 90];

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  SportType _sport = SportType.run;
  bool _gps = false;
  int? _goal;

  Future<void> _start() async {
    final c = DeviceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = context.l10n;
    if (c.exercise != null) {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const LiveExerciseScreen()),
      );
      return;
    }
    // Bileklik bağlı değilse önce bağlanılır; düğmeye dokunmak hiçbir şey
    // yapmıyormuş gibi görünmesin.
    if (!c.isConnected) {
      if (c.connection == DeviceConnectionState.connecting) return;
      await c.connect();
      if (!c.isConnected) {
        messenger.showSnackBar(
          SnackBar(content: Text(issueText(c) ?? l.exerciseConnectFirst)),
        );
        return;
      }
    }
    if (await c.startExercise(_sport)) {
      c.exercise?.goalMinutes = _goal;
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const LiveExerciseScreen()),
      );
    } else if (issueText(c) case final issue?) {
      messenger.showSnackBar(SnackBar(content: Text(issue)));
    }
  }

  Future<void> _pickSport() async {
    final picked = await showCamSheet<SportType>(
      context: context,
      builder: (context) => _SportSheet(selected: _sport),
    );
    if (picked != null) setState(() => _sport = picked);
  }

  Future<void> _pickGoal() async {
    final picked = await showCamSheet<int>(
      context: context,
      builder: (context) => _GoalSheet(selected: _goal),
    );
    // 0: hedef yok.
    if (picked != null) setState(() => _goal = picked == 0 ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([c, c.store]),
      builder: (context, _) {
        final active = c.exercise;
        final all = c.store.workoutsBetween(DateTime(2000), DateTime.now());
        final minutes = all.fold(0, (s, w) => s + w.duration.inMinutes);
        return SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          20,
                          20,
                          20,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.navExercise,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (active != null) ...[
                              const SizedBox(height: 12),
                              _ActiveCard(onTap: _start),
                            ],
                            const SizedBox(height: 8),
                            _RecordsLink(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const WorkoutRecordsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _Total(
                                    value: '$minutes',
                                    unit: l.exerciseMinutesUnit,
                                    label: l.exerciseTotalTime,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Total(
                                    value: '${all.length}',
                                    label: l.exerciseTotalCount,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SportTabs(
                        selected: _sport,
                        onSelected: active == null
                            ? (s) => setState(() => _sport = s)
                            : null,
                        onMore: active == null ? _pickSport : null,
                      ),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                MediaQuery.textScalerOf(context).scale(330) +
                                GlassNavBar.clearance(context),
                          ),
                          child: _MapPanel(
                            gps: _gps,
                            onGps: (v) => setState(() => _gps = v),
                            sport: _sport,
                            goal: _goal,
                            active: active != null,
                            onStart: _start,
                            onGoal: _pickGoal,
                            onSport: active == null ? _pickSport : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Süren egzersize dönüş kartı.
class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = DeviceScope.of(context).exercise!;
    final l = context.l10n;
    return GlassCard(
      padding: EdgeInsets.zero,
      tint: camTint(context.colors.heroTintStart, context.colors.heroTintEnd),
      child: ListTile(
        leading: Icon(active.type.icon, color: context.colors.accent),
        title: Text(l.exerciseInProgress(active.type.label)),
        subtitle: Text(
          active.paused
              ? l.exercisePausedAt(clock(active.elapsed))
              : clock(active.elapsed),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _RecordsLink extends StatelessWidget {
  const _RecordsLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              context.l10n.exerciseRecords,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

/// Büyük sayı, yanında küçük birim, altında açıklama.
class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label, this.unit});
  final String value, label;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.muted;
    return Semantics(
      label: '$label: $value${unit == null ? '' : ' $unit'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  ltr(value),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 6),
                  Text(unit!, style: TextStyle(fontSize: 18, color: muted)),
                ],
              ],
            ),
          ),
          Text(label, style: TextStyle(fontSize: 15, color: muted)),
        ],
      ),
    );
  }
}

/// Koşu / Bisiklet / Yürüyüş / Daha fazla. Seçilen tür üçünden biri
/// değilse dördüncü sekme onun adını gösterir.
class _SportTabs extends StatelessWidget {
  const _SportTabs({
    required this.selected,
    required this.onSelected,
    required this.onMore,
  });

  final SportType selected;
  final ValueChanged<SportType>? onSelected;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final other = !ExerciseScreen.quick.contains(selected);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final s in ExerciseScreen.quick)
            _Tab(
              label: s.label,
              selected: s == selected,
              onTap: onSelected == null ? null : () => onSelected!(s),
            ),
          _Tab(
            label: other ? selected.label : context.l10n.exerciseMore,
            selected: other,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: selected ? DataColors.steps : context.colors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                height: 3,
                width: selected ? 28 : 0,
                decoration: BoxDecoration(
                  color: DataColors.steps,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Harita zemini; üstünde GPS göstergesi, altta GPS / iç mekan seçici,
/// hedef, başlat ve spor türü düğmeleri.
class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.gps,
    required this.onGps,
    required this.sport,
    required this.goal,
    required this.active,
    required this.onStart,
    required this.onGoal,
    required this.onSport,
  });

  final bool gps;
  final ValueChanged<bool> onGps;
  final SportType sport;
  final int? goal;
  final bool active;
  final VoidCallback onStart, onGoal;
  final VoidCallback? onSport;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CamMap(
              center: CamMap.fallbackCenter,
              zoom: 11.5,
              interactive: false,
            ),
          ),
          // Haritanın altı kontrollerin okunması için koyulaşır.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.45, 1],
                    colors: [
                      c.background.withValues(alpha: 0),
                      c.background.withValues(alpha: 0.15),
                      c.background.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 12,
            end: 12,
            start: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const _GpsPill(),
                if (gps) ...[
                  const SizedBox(height: 8),
                  _Chip(text: l.exerciseGpsNote),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: GlassNavBar.clearance(context),
            child: Column(
              children: [
                _ModeSwitch(gps: gps, onChanged: onGps),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoundButton(
                      icon: Icons.track_changes,
                      label: goal == null ? l.exerciseGoal : duration(goal!),
                      highlighted: goal != null,
                      onTap: active ? null : onGoal,
                    ),
                    _GoButton(
                      label: active ? l.exerciseResume : l.exerciseGo,
                      semantics: active
                          ? l.exerciseResume
                          : l.exerciseGoSemantics(sport.label),
                      onTap: onStart,
                    ),
                    _RoundButton(
                      icon: sport.icon,
                      label: sport.label,
                      highlighted: true,
                      onTap: onSport,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// GPS göstergesi. Bileklikte GPS yok, telefon konumu egzersize henüz
/// bağlanmadı; bu yüzden çubuklar sönük.
class _GpsPill extends StatelessWidget {
  const _GpsPill();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.exerciseGpsOff,
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: MapColors.labelBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GPS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: MapColors.label,
              ),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 3),
                child: Container(
                  width: 4,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.colors.muted.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: MapColors.labelBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: MapColors.label),
      ),
    ),
  );
}

/// GPS egzersizi | İç mekan egzersizi.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.gps, required this.onChanged});
  final bool gps;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    Widget half(String text, bool selected, bool value) => Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? c.accent : c.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 30,
        baseColor: HomeSky.card,
        child: IntrinsicHeight(
          child: Row(
            children: [
              half(l.exerciseGps, gps, true),
              VerticalDivider(
                width: 1,
                indent: 14,
                endIndent: 14,
                color: c.muted.withValues(alpha: 0.4),
              ),
              half(l.exerciseIndoor, !gps, false),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Material(
              color: HomeSky.card,
              shape: CircleBorder(
                side: BorderSide(
                  color: highlighted
                      ? c.accent
                      : c.muted.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(
                    icon,
                    size: 30,
                    color: onTap == null ? c.muted : c.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortadaki büyük başlat düğmesi.
class _GoButton extends StatelessWidget {
  const _GoButton({
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final String label, semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: c.ctaGlow, blurRadius: 28, spreadRadius: 4),
          ],
        ),
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: c.ctaStart,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color.lerp(c.ctaStart, c.accent, 0.25)!, c.ctaStart],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spor türü seçimi.
class _SportSheet extends StatelessWidget {
  const _SportSheet({required this.selected});
  final SportType selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.exerciseSportTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: GridView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent:
                    52 + MediaQuery.textScalerOf(context).scale(12) * 1.4 * 2,
              ),
              children: [
                for (final s in SportType.startable)
                  Semantics(
                    selected: s == selected,
                    button: true,
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      baseColor: s == selected
                          ? c.accent.withValues(alpha: 0.18)
                          : null,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, s),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(s.icon, color: c.accent),
                              const SizedBox(height: 6),
                              Flexible(
                                child: Text(
                                  s.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Süre hedefi seçimi; 0 "hedef yok".
class _GoalSheet extends StatelessWidget {
  const _GoalSheet({required this.selected});
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.exerciseGoalTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: Text(l.exerciseGoalNone),
                selected: selected == null,
                onSelected: (_) => Navigator.pop(context, 0),
              ),
              for (final m in ExerciseScreen.goals)
                ChoiceChip(
                  label: Text(duration(m)),
                  selected: selected == m,
                  onSelected: (_) => Navigator.pop(context, m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
