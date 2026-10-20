import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/daily_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_button.dart';
import '../widgets/illustrations.dart';
import '../widgets/pressable.dart';

/// Ana ekran ("Cam" tasarım dili).
///
/// Arka plan (aurora) ve alt menü bu ekranın dışında, uygulama kabuğunda
/// çizilir; bu ekran yalnızca kaydırılan içeriği verir.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.summary,
    required this.band,
    this.bottomPadding = 120,
    this.onMeasure,
    this.onWorkout,
    this.onSync,
    this.now,
  });

  final DailySummary summary;
  final BandStatus band;

  /// Alt menünün altında içerik kalmasın diye bırakılan boşluk.
  final double bottomPadding;

  final VoidCallback? onMeasure;
  final VoidCallback? onWorkout;
  final VoidCallback? onSync;

  /// Testlerde sabit tarih vermek için. Verilmezse bugünün tarihi.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final s = summary;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        children: [
          _Header(date: today, band: band),
          const SizedBox(height: 12),
          _HeartRateCard(summary: s, band: band, onMeasure: onMeasure),
          const SizedBox(height: 12),
          _EqualHeightRow(
            gap: 10,
            children: [
              _QuickAction(
                label: 'Nabız ölç',
                icon: Icons.favorite_rounded,
                colors: const [Color(0xFFFF8AB8), Color(0xFFFF5C9D), Color(0xFFC4124F)],
                glow: const Color(0x80FF2E88),
                onTap: band.connected ? onMeasure : null,
              ),
              _QuickAction(
                label: 'Antrenman',
                icon: Icons.bolt_rounded,
                colors: const [Color(0xFFC8FF8A), Color(0xFF8CF04A), Color(0xFF16A05E)],
                glow: const Color(0x736EE646),
                onTap: onWorkout,
              ),
              _QuickAction(
                label: 'Senkronize',
                icon: Icons.sync_rounded,
                colors: const [Color(0xFF9BEAFF), Color(0xFF4FDDFF), Color(0xFF4B4FF0)],
                glow: const Color(0x7300C8FF),
                onTap: band.connected ? onSync : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EqualHeightRow(
            children: [
              _MetricCard(
                label: 'Adım',
                value: s.steps == null ? '—' : formatThousands(s.steps!),
                caption: s.steps == null
                    ? 'Veri yok'
                    : '${formatThousands(s.stepGoal)} adım hedefi',
                illustration: RingProgress(progress: s.stepProgress),
              ),
              _MetricCard(
                label: 'Uyku',
                value: s.sleepMinutes == null ? '—' : formatDuration(s.sleepMinutes!),
                caption: s.sleepMinutes == null ? 'Uyku kaydı yok' : 'Dün gece',
                illustration: const Moon3D(),
                tint: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.sleepTintStart, AppColors.sleepTintEnd],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EqualHeightRow(
            children: [
              _MetricCard(
                label: 'Kalori',
                value: s.calories == null ? '—' : formatThousands(s.calories!),
                caption: s.calories == null
                    ? 'Veri yok'
                    : '${formatThousands(s.calorieGoal)} kcal hedefi',
                illustration: const Flame3D(),
              ),
              _MetricCard(
                label: 'Aktif süre',
                value: s.activeMinutes == null ? '—' : '${s.activeMinutes}',
                unit: s.activeMinutes == null ? null : 'dk',
                caption: s.activeMinutes == null ? 'Veri yok' : '${s.activeGoal} dk hedefi',
                illustration: const Orb(
                  size: 46,
                  colors: [Color(0xFFE6FF9A), Color(0xFF8CF04A), Color(0xFF16A05E)],
                  glow: Color(0x806EE646),
                  child: Icon(Icons.bolt_rounded, size: 22, color: Color(0xFF0B3D20)),
                ),
                bottom: GlowProgressBar(
                  progress: s.activeProgress,
                  colors: const [Color(0xFFC6FF4D), Color(0xFF3DDC84)],
                  glow: const Color(0x999DFF3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WeeklyCard(values: s.weeklyRestingHr, todayIndex: today.weekday - 1),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.date, required this.band});

  final DateTime date;
  final BandStatus band;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatTurkishDate(date), style: AppText.caption),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Semantics(header: true, child: Text('Bugün', style: AppText.title)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: _BandChip(band: band)),
        ],
      ),
    );
  }
}

class _BandChip extends StatelessWidget {
  const _BandChip({required this.band});

  final BandStatus band;

  @override
  Widget build(BuildContext context) {
    final String text;
    final String semantics;
    if (!band.connected) {
      text = 'Bağlı değil';
      semantics = 'Bileklik bağlı değil';
    } else if (band.batteryPercent != null) {
      text = 'JCV8 · %${band.batteryPercent}';
      semantics = 'JCV8 bileklik bağlı, pil yüzde ${band.batteryPercent}';
    } else {
      text = 'JCV8';
      semantics = 'JCV8 bileklik bağlı';
    }

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: band.connected ? AppColors.online : AppColors.offline,
                boxShadow: band.connected
                    ? const [BoxShadow(color: AppColors.online, blurRadius: 10)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(13, FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard({required this.summary, required this.band, this.onMeasure});

  final DailySummary summary;
  final BandStatus band;
  final VoidCallback? onMeasure;

  @override
  Widget build(BuildContext context) {
    final bpm = summary.heartRateBpm;
    final resting = summary.restingHeartRateBpm;
    final live = band.connected && bpm != null;
    final String subtitle;
    if (!band.connected) {
      subtitle = 'Bileklik bağlı değil';
    } else if (bpm == null) {
      subtitle = 'Henüz ölçüm yok';
    } else if (resting != null) {
      subtitle = 'Dinlenme $resting bpm';
    } else {
      subtitle = 'Son ölçüm';
    }

    return GlassCard(
      radius: 32,
      padding: const EdgeInsets.all(22),
      tint: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.heroTintStart, AppColors.heroTintEnd],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -8,
            right: -10,
            child: ExcludeSemantics(child: Heart3D()),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text('Nabız', style: AppText.cardLabel)),
                    if (live) ...[const SizedBox(width: 8), const _LiveChip()],
                  ],
                ),
                const SizedBox(height: 28),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: bpm?.toString() ?? '—',
                      style: AppText.display,
                      children: [
                        if (bpm != null) TextSpan(text: ' bpm', style: AppText.unit),
                      ],
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppText.style(14, FontWeight.w600, color: const Color(0xD9FFFFFF)),
                ),
                const SizedBox(height: 18),
                GlowButton(
                  label: 'Şimdi ölç',
                  icon: Icons.show_chart_rounded,
                  onTap: band.connected ? onMeasure : null,
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x38FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text('Canlı', style: AppText.small),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Çocukları yan yana, aynı yükseklikte dizer.
class _EqualHeightRow extends StatelessWidget {
  const _EqualHeightRow({required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.glow,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: GlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 58),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Orb(
                  size: 36,
                  colors: colors,
                  glow: glow,
                  child: Icon(icon, size: 18, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: AppText.small),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.illustration,
    this.unit,
    this.bottom,
    this.tint,
  });

  final String label;
  final String value;
  final String? unit;
  final String caption;
  final Widget illustration;
  final Widget? bottom;
  final Gradient? tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: tint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: AppText.cardLabel)),
                const SizedBox(width: 8),
                ExcludeSemantics(child: illustration),
              ],
            ),
            const SizedBox(height: 12),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: AppText.metric,
                  children: [
                    if (unit != null) TextSpan(text: ' $unit', style: AppText.unit),
                  ],
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(caption, style: AppText.caption),
            if (bottom != null) ...[const SizedBox(height: 12), bottom!],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.values, required this.todayIndex});

  final List<int?> values;
  final int todayIndex;

  static const _days = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
  static const _dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  int? _valueAt(int i) => i < values.length ? values[i] : null;

  @override
  Widget build(BuildContext context) {
    final known = values.whereType<int>().toList();
    final minV = known.isEmpty ? 0 : known.reduce(math.min);
    final maxV = known.isEmpty ? 0 : known.reduce(math.max);

    double barHeight(int? v) {
      if (v == null) return 10;
      if (maxV == minV) return 44;
      return 30 + (v - minV) / (maxV - minV) * 28;
    }

    final spoken = [
      for (var i = 0; i < 7; i++)
        '${_dayNames[i]} ${_valueAt(i) == null ? 'veri yok' : '${_valueAt(i)} bpm'}',
    ].join(', ');

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: Text('Bu hafta', style: AppText.cardLabel)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'dinlenme nabzı',
                  textAlign: TextAlign.end,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label: 'Bu hafta dinlenme nabzı: $spoken',
            excludeSemantics: true,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    _Bar(
                      height: barHeight(_valueAt(i)),
                      today: i == todayIndex,
                      empty: _valueAt(i) == null,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  SizedBox(
                    width: _Bar.width,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _days[i],
                        style: AppText.style(
                          12,
                          FontWeight.w700,
                          color: i == todayIndex ? AppColors.dayToday : AppColors.textSecondary,
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

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.today, required this.empty});

  static const double width = 30;

  final double height;
  final bool today;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration;
    if (empty) {
      decoration = BoxDecoration(
        color: AppColors.barEmpty,
        borderRadius: BorderRadius.circular(10),
      );
    } else if (today) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.barTodayStart, AppColors.barTodayEnd],
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.barTodayGlow, blurRadius: 16, offset: Offset(0, 6)),
        ],
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.barStart, AppColors.barEnd],
        ),
      );
    }
    return Container(width: width, height: height, decoration: decoration);
  }
}
