import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/health_store.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/settings_rows.dart';

/// Kilo ve vücut kompozisyonu. Değerler kullanıcıdan alınır (akıllı tartı
/// yok); VKİ girişte boy ve kilodan hesaplanıp saklanır.
class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

/// Grafikte gösterilen dönem (gün).
enum _Span {
  month(30),
  quarter(90),
  year(365);

  const _Span(this.days);
  final int days;
}

class _BodyScreenState extends State<BodyScreen> {
  var _span = _Span.month;

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final settings = SettingsScope.of(context);
    final store = c.store;
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.bodyTitle)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final now = DateTime.now();
          final all = store.measurements(
            MetricType.weight,
            DateTime(2000),
            now.add(const Duration(days: 1)),
          );
          final entries = [
            for (final w in all.reversed) BodyEntry.at(store, w),
          ];
          final height = settings.heightCm ?? c.profile?.heightCm;
          final from = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: _span.days - 1));
          final shown = all.where((m) => !m.time.isBefore(from)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Hero(entries: entries, onAdd: () => addBodyEntry(context)),
              const SizedBox(height: 12),
              _BmiCard(
                bmi: entries.firstOrNull?.bmi,
                hasHeight: height != null,
                onAdd: () => addBodyEntry(context),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<_Span>(
                      segments: [
                        ButtonSegment(
                          value: _Span.month,
                          label: Text(l.bodyRangeMonth),
                        ),
                        ButtonSegment(
                          value: _Span.quarter,
                          label: Text(l.bodyRange3Months),
                        ),
                        ButtonSegment(
                          value: _Span.year,
                          label: Text(l.bodyRangeYear),
                        ),
                      ],
                      selected: {_span},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          setState(() => _span = s.first),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: shown.isEmpty
                          ? Center(
                              child: Text(
                                l.bodyChartEmpty,
                                style: TextStyle(color: context.colors.muted),
                              ),
                            )
                          : WeightChart(
                              points: shown,
                              from: from,
                              days: _span.days,
                            ),
                    ),
                  ],
                ),
              ),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _LatestBox(
                          type: MetricType.bodyFat,
                          entry: entries.firstWhereOrNull(
                            (e) => e.bodyFat != null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LatestBox(
                          type: MetricType.muscleMass,
                          entry: entries.firstWhereOrNull(
                            (e) => e.muscleMass != null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 24, 4, 8),
                  child: Text(
                    l.bodyHistory,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final e in entries.take(30))
                        _HistoryRow(entry: e, now: now),
                    ],
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 0),
                child: Text(
                  l.bodyNote,
                  style: TextStyle(color: context.colors.muted, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// Aynı anda girilmiş kilo, yağ oranı, kas kütlesi ve VKİ.
class BodyEntry {
  const BodyEntry({
    required this.weight,
    this.bodyFat,
    this.muscleMass,
    this.bmi,
  });

  /// Depodaki kilo kaydının yanındaki diğer değerleri toplar.
  factory BodyEntry.at(HealthStore store, Measurement weight) {
    Measurement? find(MetricType t) {
      final list = store.measurements(
        t,
        weight.time,
        weight.time.add(const Duration(milliseconds: 1)),
      );
      return list.isEmpty ? null : list.first;
    }

    return BodyEntry(
      weight: weight,
      bodyFat: find(MetricType.bodyFat),
      muscleMass: find(MetricType.muscleMass),
      bmi: find(MetricType.bmi),
    );
  }

  final Measurement weight;
  final Measurement? bodyFat;
  final Measurement? muscleMass;
  final Measurement? bmi;

  DateTime get time => weight.time;

  List<Measurement> get all => [weight, ?bodyFat, ?muscleMass, ?bmi];
}

/// Son kilo, önceki ölçüme göre değişim ve "Ölçüm ekle".
class _Hero extends StatelessWidget {
  const _Hero({required this.entries, required this.onAdd});

  final List<BodyEntry> entries;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final latest = entries.firstOrNull;
    final previous = entries.length > 1 ? entries[1] : null;
    const type = MetricType.weight;
    String? change;
    if (latest != null && previous != null) {
      final diff = latest.weight.value - previous.weight.value;
      final text = type.format(diff.abs());
      change = text == type.format(0)
          ? l.bodyNoChange
          : l.bodyChange(ltr('${diff > 0 ? '+' : '−'}$text ${type.unit}'));
    }
    return GlassCard(
      radius: CamRadius.hero,
      padding: CamSpace.heroPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Orb(
                  palette: CamArt.orbAmber,
                  size: 44,
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (latest != null)
                Text(
                  whenText(latest.time, DateTime.now()),
                  style: TextStyle(color: colors.muted),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  latest == null ? l.noValue : type.format(latest.weight.value),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  type.unit,
                  style: TextStyle(fontSize: 20, color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            latest == null ? l.bodyEmpty : change ?? '',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(height: 16),
          GlowButton(label: l.bodyAdd, icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }
}

/// VKİ, sınıfı ve dört dilimli şerit üzerinde konumu.
class _BmiCard extends StatelessWidget {
  const _BmiCard({
    required this.bmi,
    required this.hasHeight,
    required this.onAdd,
  });

  final Measurement? bmi;
  final bool hasHeight;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final value = bmi?.value;
    final cls = value == null ? null : BmiClass.of(value);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l.metricBmi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value == null ? l.noValue : MetricType.bmi.format(value),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (cls != null)
            Text(
              bmiLabel(l, cls),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 12),
          BmiBar(value: value),
          const SizedBox(height: 12),
          Text(
            value == null && !hasHeight ? l.bodyBmiNeedsHeight : l.bodyBmiNote,
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

String bmiLabel(AppLocalizations l, BmiClass c) => switch (c) {
  BmiClass.under => l.bmiUnder,
  BmiClass.normal => l.bmiNormal,
  BmiClass.over => l.bmiOver,
  BmiClass.obese => l.bmiObese,
};

/// 15-40 arası VKİ şeridi; sınırlar 18.5, 25 ve 30. Dilim renkleri
/// sıralı tek tonun koyulaşmasıdır (iyi/kötü yargısı renge yüklenmez),
/// anlamı yanındaki metin taşır.
class BmiBar extends StatelessWidget {
  const BmiBar({super.key, required this.value});

  final double? value;

  static const _lo = 15.0, _hi = 40.0;
  static const _edges = [18.5, 25.0, 30.0];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const base = DataColors.body;
    final v = value;
    return ExcludeSemantics(
      child: SizedBox(
        height: 28,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            double x(double b) => (b - _lo) / (_hi - _lo) * w;
            final stops = [_lo, ..._edges, _hi];
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 4; i++)
                  PositionedDirectional(
                    start: x(stops[i]) + (i == 0 ? 0 : 2),
                    width: x(stops[i + 1]) - x(stops[i]) - (i == 0 ? 0 : 2),
                    top: 10,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: 0.25 + i * 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                if (v != null)
                  PositionedDirectional(
                    start: x(v.clamp(_lo, _hi)) - 7,
                    top: 7,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.text,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: base.withValues(alpha: 0.7),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kilo çizgisi: x ekseni dönemin günleri, y ekseni seçili birimde kilo.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.points,
    required this.from,
    required this.days,
  });

  final List<Measurement> points;
  final DateTime from;
  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const color = DataColors.body;
    final axis = TextStyle(color: c.muted, fontSize: 11);
    double y(Measurement m) => double.parse(MetricType.weight.format(m.value));
    double x(DateTime t) => t.difference(from).inMinutes / (24 * 60);
    final ys = points.map(y).toList();
    final lo = ys.reduce(math.min), hi = ys.reduce(math.max);
    final pad = math.max(1.0, (hi - lo) * 0.25);
    final step = days <= 30 ? 7 : (days <= 90 ? 30 : 91);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: days.toDouble(),
        minY: (lo - pad).floorToDouble(),
        maxY: (hi + pad).ceilToDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: c.grid, strokeWidth: 1),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(meta.formattedValue, style: axis),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step.toDouble(),
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                // Son etiket dönemin sonuna denk gelince kenardan taşmasın.
                if (v > days - step / 2 && v != meta.max) {
                  return const SizedBox.shrink();
                }
                final t = from.add(Duration(days: v.round()));
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    days > 90 ? monthShort(t) : dayMonth(t),
                    style: axis,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final m in points) FlSpot(x(m.time), y(m))],
            color: color,
            barWidth: 2.5,
            isCurved: true,
            preventCurveOverShooting: true,
            shadow: Shadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            dotData: FlDotData(show: points.length < 40),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.32),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yağ oranı ya da kas kütlesinin son girilen değeri.
class _LatestBox extends StatelessWidget {
  const _LatestBox({required this.type, required this.entry});

  final MetricType type;
  final BodyEntry? entry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final m = type == MetricType.bodyFat ? entry?.bodyFat : entry?.muscleMass;
    final value = m == null
        ? l.noValue
        : type.symbol == '%'
        ? l.statPercent(type.format(m.value))
        : '${type.format(m.value)} ${type.unit}';
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(type.icon, color: type.color, size: 22),
          const SizedBox(height: 8),
          Text(type.label, style: TextStyle(color: colors.muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              ltr(value),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (m != null)
            Text(
              whenText(m.time, DateTime.now()),
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

/// Geçmişteki bir giriş; dokununca silme sorulur.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.now});

  final BodyEntry entry;
  final DateTime now;

  Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final store = DeviceScope.of(context).store;
    final ok = await showCamDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.bodyDeleteTitle),
        content: Text(l.bodyDeleteBody(longDate(entry.time))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.bodyDelete),
          ),
        ],
      ),
    );
    if (ok ?? false) store.removeMeasurements(entry.all);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final extra = [
      if (entry.bodyFat case final f?)
        l.statPercent(MetricType.bodyFat.format(f.value)),
      if (entry.muscleMass case final m?)
        '${MetricType.muscleMass.format(m.value)} ${MetricType.muscleMass.unit}',
      if (entry.bmi case final b?)
        '${l.metricBmi} ${MetricType.bmi.format(b.value)}',
    ].map(ltr).join(' · ');
    return ListTile(
      minTileHeight: 60,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 8),
      title: Text(whenText(entry.time, now)),
      subtitle: extra.isEmpty
          ? null
          : Text(extra, style: TextStyle(color: colors.muted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ltr(
              '${MetricType.weight.format(entry.weight.value)} '
              '${MetricType.weight.unit}',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          IconButton(
            tooltip: l.bodyDelete,
            icon: Icon(Icons.delete_outline, color: colors.muted),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}

/// "72,5" ya da "٧٢٫٥" gibi girişleri sayıya çevirir.
double? parseDecimal(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in input.trim().split('')) {
    final i = arabic.indexOf(ch);
    buf.write(
      i >= 0
          ? '$i'
          : (ch == ',' || ch == '٫')
          ? '.'
          : ch,
    );
  }
  return double.tryParse(buf.toString());
}

/// Yeni ölçüm alt sayfasını açar; kaydedilince depoya ekler, VKİ'yi
/// hesaplar ve bileklik bağlıysa kiloyu bilekliğe yazar.
Future<void> addBodyEntry(BuildContext context) async {
  final c = DeviceScope.of(context);
  final settings = SettingsScope.of(context);
  final result = await showCamSheet<BodyInput>(
    context: context,
    builder: (_) => BodyEntrySheet(
      heightCm: settings.heightCm ?? c.profile?.heightCm,
      imperial: DisplayPrefs.imperial,
    ),
  );
  if (result == null) return;
  final t = result.time;
  final height = result.heightCm;
  c.store.addMeasurements([
    Measurement(MetricType.weight, t, result.weightKg),
    if (result.bodyFat case final f?) Measurement(MetricType.bodyFat, t, f),
    if (result.muscleKg case final m?) Measurement(MetricType.muscleMass, t, m),
    if (height != null)
      Measurement(
        MetricType.bmi,
        t,
        // Bir ondalık yeter; depoda da ekranda gördüğü değer dursun.
        (bodyMassIndex(result.weightKg, height) * 10).round() / 10,
      ),
  ]);
  if (height != null) await settings.setHeight(height);
  // Yalnızca en yeni ölçüm bilekliğe gider.
  final latest = c.store.latest(MetricType.weight);
  if (latest != null && latest.time == t) {
    await c.updateBodyInfo(weightKg: result.weightKg, heightCm: height);
  }
}

/// Alt sayfanın sonucu; kilo her zaman kilogram olarak.
class BodyInput {
  const BodyInput({
    required this.time,
    required this.weightKg,
    this.bodyFat,
    this.muscleKg,
    this.heightCm,
  });

  final DateTime time;
  final double weightKg;
  final double? bodyFat;
  final double? muscleKg;
  final int? heightCm;
}

class BodyEntrySheet extends StatefulWidget {
  const BodyEntrySheet({super.key, this.heightCm, this.imperial = false});

  final int? heightCm;
  final bool imperial;

  @override
  State<BodyEntrySheet> createState() => _BodyEntrySheetState();
}

class _BodyEntrySheetState extends State<BodyEntrySheet> {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _fat = TextEditingController();
  final _muscle = TextEditingController();
  late final _height = TextEditingController(
    text: widget.heightCm?.toString() ?? '',
  );
  DateTime? _day;

  double get _toKg => widget.imperial ? 1 / lbPerKg : 1;
  String get _massUnit => widget.imperial ? 'lb' : 'kg';

  @override
  void dispose() {
    _weight.dispose();
    _fat.dispose();
    _muscle.dispose();
    _height.dispose();
    super.dispose();
  }

  String? _range(String? v, double min, double max, {bool optional = false}) {
    final text = v?.trim() ?? '';
    if (optional && text.isEmpty) return null;
    final n = parseDecimal(text);
    if (n == null || n < min || n > max) {
      String f(double x) =>
          x == x.roundToDouble() ? x.round().toString() : x.toStringAsFixed(1);
      return context.l10n.bodyRangeError(f(min), f(max));
    }
    return null;
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    final today = DateTime(now.year, now.month, now.day);
    setState(() => _day = picked == today ? null : picked);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final now = DateTime.now();
    final day = _day;
    final weight = parseDecimal(_weight.text)! * _toKg;
    final muscle = parseDecimal(_muscle.text);
    Navigator.of(context).pop(
      BodyInput(
        // Geçmiş güne girilen ölçüm o günün öğlesine yazılır.
        time: day == null ? now : DateTime(day.year, day.month, day.day, 12),
        weightKg: (weight * 10).round() / 10,
        bodyFat: parseDecimal(_fat.text),
        muscleKg: muscle == null ? null : (muscle * _toKg * 10).round() / 10,
        heightCm: parseDecimal(_height.text)?.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final massMax = widget.imperial ? 660.0 : 300.0;
    final massMin = widget.imperial ? 44.0 : 20.0;
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫]'))];
    InputDecoration deco(String label, String unit) =>
        InputDecoration(labelText: label, suffixText: unit);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.bodySheetTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: EdgeInsets.zero,
              child: SettingsValueRow(
                label: l.bodyDate,
                value: _day == null ? l.bodyToday : longDate(_day!),
                onTap: _pickDay,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numbers,
              decoration: deco(l.metricWeight, _massUnit),
              validator: (v) => _range(v, massMin, massMax),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numbers,
              decoration: deco(l.bodyOptional(l.metricBodyFat), '%'),
              validator: (v) => _range(v, 3, 75, optional: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _muscle,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numbers,
              decoration: deco(l.bodyOptional(l.metricMuscleMass), _massUnit),
              validator: (v) {
                final r = _range(v, 5, massMax, optional: true);
                if (r != null) return r;
                final m = parseDecimal(v ?? '');
                final w = parseDecimal(_weight.text);
                if (m != null && w != null && m >= w) {
                  return l.bodyMuscleTooHigh;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _height,
              keyboardType: TextInputType.number,
              inputFormatters: numbers,
              decoration: deco(l.bodyHeight, l.profileUnitCm),
              validator: (v) => _range(v, 80, 250, optional: true),
            ),
            const SizedBox(height: 4),
            Text(
              l.bodyBmiNote,
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            GlowButton(label: l.bodySave, onTap: _save),
          ],
        ),
      ),
    );
  }
}
