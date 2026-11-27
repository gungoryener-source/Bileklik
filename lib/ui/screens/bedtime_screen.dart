import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/bedtime.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Yatma Düzeni: sakinleşme çağrısı, haftalık yatma saati grafiği (ideal
/// saat ve aralık, uygun/sapma noktaları, hafta gezinme) ve istikrarlı bir
/// yatma saati için kısa bilgi. Ana Sayfa'nın gece görünümünden açılır.
class BedtimeScreen extends StatefulWidget {
  const BedtimeScreen({super.key, required this.day, this.now});

  final DateTime day;

  /// Testler için "şimdi"; gelecekteki haftaya geçilmez.
  final DateTime? now;

  @override
  State<BedtimeScreen> createState() => _BedtimeScreenState();
}

class _BedtimeScreenState extends State<BedtimeScreen> {
  late PeriodRange _week = PeriodRange.of(Period.week, widget.day);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = DeviceScope.of(context).store;
    final now = widget.now ?? DateTime.now();
    return CamScaffold(
      appBar: AppBar(title: Text(l.bedtimeTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final week = BedtimeWeek.of(store, _week.start);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _WindDownHeader(),
                const SizedBox(height: 24),
                _BedtimeCard(
                  week: week,
                  canForward: _week.end.isBefore(now),
                  onShift: (by) => setState(() => _week = _week.shift(by)),
                ),
                const SizedBox(height: CamSpace.gap),
                const _TipCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WindDownHeader extends StatelessWidget {
  const _WindDownHeader();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        const SizedBox(height: 8),
        // Yeşil-mavi degrade halka içinde ay.
        ExcludeSemantics(
          child: Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [HomeSky.ai, HomeSky.aiBlue],
              ),
              boxShadow: [
                BoxShadow(
                  color: HomeSky.ai.withValues(alpha: 0.3),
                  blurRadius: 28,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: HomeSky.inner,
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [HomeSky.ai, HomeSky.aiBlue],
                  ).createShader(r),
                  child: const Icon(
                    Icons.nights_stay_outlined,
                    size: 56,
                    color: HomeSky.snow,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            l.bedtimeWindDown,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HomeSky.ai,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            l.bedtimeWindDownBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BedtimeCard extends StatelessWidget {
  const _BedtimeCard({
    required this.week,
    required this.canForward,
    required this.onShift,
  });

  final BedtimeWeek week;
  final bool canForward;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final last = week.range.end.subtract(const Duration(days: 1));
    final idealText = minuteOfDay(BedtimeWeek.ideal);
    final points = <String>[
      for (var i = 0; i < 7; i++)
        if (week.bedtimes[i] case final t?)
          l.bedtimePointSemantics(
            weekdayLong(i + 1),
            hhmm(t),
            BedtimeWeek.onTrack(t) ? l.bedtimeOnTrack : l.bedtimeOff,
          ),
    ];
    return GlassCard(
      baseColor: HomeSky.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime, color: HomeSky.ai),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.bedtimeChartTitle,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: l.metricDetailPrevious,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onShift(-1),
              ),
              Expanded(
                child: Text(
                  l.recoveryRange(dayMonth(week.range.start), dayMonth(last)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: l.metricDetailNext,
                icon: const Icon(Icons.chevron_right),
                onPressed: canForward ? () => onShift(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: points.isEmpty ? l.bedtimeEmpty : points.join('; '),
            excludeSemantics: true,
            child: SizedBox(
              height: 230,
              child: Directionality(
                // Gün ekseni her dilde soldan sağa akar.
                textDirection: TextDirection.ltr,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BedtimeChartPainter(
                    bedtimes: week.bedtimes,
                    labels: [for (var d = 1; d <= 7; d++) weekdayShort(d)],
                    base: DefaultTextStyle.of(context).style,
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.3),
                    grid: colors.outline,
                    muted: colors.muted,
                    text: colors.text,
                  ),
                ),
              ),
            ),
          ),
          if (week.isEmpty) ...[
            const SizedBox(height: 12),
            Text(l.bedtimeEmpty, style: TextStyle(color: colors.muted)),
          ],
          const SizedBox(height: 16),
          _LegendRow(
            mark: const _LineMark(dashed: false),
            label: l.bedtimeIdeal,
            value: idealText,
          ),
          const SizedBox(height: 10),
          _LegendRow(
            mark: const _LineMark(dashed: true),
            label: l.bedtimeIdealRange,
            value: l.bedtimeRangeValue(
              isolate(idealText),
              BedtimeWeek.tolerance,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 24,
            runSpacing: 8,
            children: [
              _Dot(color: HomeSky.green, label: l.bedtimeOnTrack),
              _Dot(color: HomeSky.yellow, label: l.bedtimeOff),
            ],
          ),
          if (!week.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l.bedtimeWeekSummary(week.onTrackCount, week.recorded.length),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.mark,
    required this.label,
    required this.value,
  });

  final Widget mark;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      children: [
        mark,
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Açıklamadaki çizgi işareti: düz (ideal saat) ya da kesik çizgili kutu
/// (ideal aralık).
class _LineMark extends StatelessWidget {
  const _LineMark({required this.dashed});

  final bool dashed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 16,
    child: CustomPaint(painter: _LineMarkPainter(dashed)),
  );
}

class _LineMarkPainter extends CustomPainter {
  const _LineMarkPainter(this.dashed);

  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = HomeSky.green
      ..strokeWidth = 2;
    if (!dashed) {
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      return;
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = HomeSky.green.withValues(alpha: 0.14),
    );
    line.strokeWidth = 1.2;
    _dash(canvas, 0, size.width, 0, line);
    _dash(canvas, 0, size.width, size.height, line);
  }

  @override
  bool shouldRepaint(_LineMarkPainter old) => old.dashed != dashed;
}

void _dash(Canvas canvas, double x0, double x1, double y, Paint p) {
  for (var x = x0; x < x1; x += 6) {
    canvas.drawLine(Offset(x, y), Offset((x + 3).clamp(x0, x1), y), p);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 15)),
    ],
  );
}

/// Haftalık yatma saati grafiği. Dikey eksen öğleden itibaren dakikadır;
/// geç saatler yukarıda. Varsayılan aralık 21:00-01:00, dışına düşen
/// yatışlar için tam saate yuvarlanarak genişler.
class _BedtimeChartPainter extends CustomPainter {
  _BedtimeChartPainter({
    required this.bedtimes,
    required this.labels,
    required this.base,
    required this.textScaler,
    required this.grid,
    required this.muted,
    required this.text,
  });

  final List<DateTime?> bedtimes;
  final List<String> labels;

  /// Temanın yazı tipi; çizimdeki saat ve gün adları da onunla yazılır.
  final TextStyle base;
  final TextScaler textScaler;
  final Color grid;
  final Color muted;
  final Color text;

  TextPainter _label(String s, Color color, {double size = 11}) => TextPainter(
    text: TextSpan(
      text: s,
      style: base.copyWith(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
    ellipsis: '…',
  );

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final t in bedtimes) t == null ? null : BedtimeWeek.sinceNoon(t),
    ];
    final known = values.whereType<int>();
    var lo = 9 * 60; // 21:00
    var hi = 13 * 60; // 01:00
    for (final v in known) {
      if (v < lo) lo = v ~/ 60 * 60;
      if (v > hi) hi = (v + 59) ~/ 60 * 60;
    }

    String clockAt(int sinceNoon) => minuteOfDay((sinceNoon + 720) % 1440);
    const ideal = BedtimeWeek.idealSinceNoon;

    // Saatler soldaki sütunda; günler ve noktalar sağdaki alanda.
    final hiLabel = _label(clockAt(hi), muted)..layout();
    final loLabel = _label(clockAt(lo), muted)..layout();
    final idealLabel = _label(clockAt(ideal), HomeSky.green)..layout();
    final gutter =
        [hiLabel.width, loLabel.width, idealLabel.width].reduce(max) + 8;
    final x0 = gutter;
    final right = size.width;

    final dayLabel = _label('M', muted, size: 13)..layout();
    final bottomAxis = size.height - dayLabel.height - 10;
    final top = hiLabel.height / 2 + 2;
    final plotH = bottomAxis - top;
    double yOf(int v) => bottomAxis - (v - lo) / (hi - lo) * plotH;
    final colW = (right - x0) / 7;
    double xOf(int i) => x0 + colW * (i + 0.5);
    void axisLabel(TextPainter tp, double y) =>
        tp.paint(canvas, Offset(gutter - 8 - tp.width, y - tp.height / 2));

    // Üst ve alt sınır çizgileri.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final (v, tp) in [(hi, hiLabel), (lo, loLabel)]) {
      final y = yOf(v);
      canvas.drawLine(Offset(x0, y), Offset(right, y), gridPaint);
      axisLabel(tp, y);
    }

    // İdeal aralık: soluk yeşil şerit, kesik kenarlar, ortada düz çizgi.
    final bandTop = yOf(ideal + BedtimeWeek.tolerance);
    final bandBottom = yOf(ideal - BedtimeWeek.tolerance);
    canvas.drawRect(
      Rect.fromLTRB(x0, bandTop, right, bandBottom),
      Paint()..color = HomeSky.green.withValues(alpha: 0.12),
    );
    final dashPaint = Paint()
      ..color = HomeSky.green.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    _dash(canvas, x0, right, bandTop, dashPaint);
    _dash(canvas, x0, right, bandBottom, dashPaint);
    final idealY = yOf(ideal);
    canvas.drawLine(
      Offset(x0, idealY),
      Offset(right, idealY),
      Paint()
        ..color = HomeSky.green
        ..strokeWidth = 2,
    );
    axisLabel(idealLabel, idealY);

    // Günler ve noktalar.
    final stem = Paint()
      ..color = muted.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final x = xOf(i);
      final d = _label(labels[i], muted, size: 13)..layout(maxWidth: colW);
      d.paint(canvas, Offset(x - d.width / 2, bottomAxis + 8));

      final v = values[i];
      if (v == null) continue;
      final t = bedtimes[i]!;
      final y = yOf(v);
      final ok = BedtimeWeek.onTrack(t);
      final color = ok ? HomeSky.green : HomeSky.yellow;
      if (!ok) canvas.drawLine(Offset(x, idealY), Offset(x, y), stem);
      canvas
        ..drawCircle(
          Offset(x, y),
          8,
          Paint()..color = color.withValues(alpha: 0.25),
        )
        ..drawCircle(Offset(x, y), 5, Paint()..color = color);
      final tl = _label(hhmm(t), text)..layout(maxWidth: colW + 8);
      // Erken yatışta saat noktanın altında, geç yatışta üstünde.
      final below = v <= ideal;
      var ty = below ? y + 9 : y - 9 - tl.height;
      ty = ty.clamp(top, bottomAxis - tl.height);
      final tx = (x - tl.width / 2).clamp(x0, right - tl.width);
      tl.paint(canvas, Offset(tx, ty));
    }
  }

  @override
  bool shouldRepaint(_BedtimeChartPainter old) =>
      old.bedtimes != bedtimes ||
      old.base != base ||
      old.textScaler != textScaler ||
      old.grid != grid ||
      old.muted != muted ||
      old.text != text;
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CamRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeSky.green, HomeSky.aiBlue],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: HomeSky.ai),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l.bedtimeTipTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: HomeSky.ai,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l.bedtimeTipBody,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
