import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../../data/models.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/metric_chart.dart';

/// Bir metriğin gün, hafta ve ay grafiği ile özet değerleri.
///
/// Tansiyon gibi iki değerli ölçümlerde [secondary] ikinci çizgi olarak çizilir.
class MetricDetailScreen extends StatefulWidget {
  const MetricDetailScreen({
    super.key,
    required this.type,
    this.secondary,
    this.title,
  });

  final MetricType type;
  final MetricType? secondary;
  final String? title;

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  late PeriodRange _range = PeriodRange.of(Period.day, DateTime.now());

  String get _rangeText => switch (_range.period) {
    Period.day => dayMonth(_range.start),
    Period.week =>
      '${dayMonth(_range.start)} - ${dayMonth(_range.end.subtract(const Duration(days: 1)))}',
    Period.month => monthYear(_range.start),
  };

  @override
  Widget build(BuildContext context) {
    final store = DeviceScope.of(context).store;
    final type = widget.type;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? type.label)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = store.measurements(type, _range.start, _range.end);
          final values = aggregate(items, _range, type);
          final second = widget.secondary;
          final secondValues = second == null
              ? null
              : aggregate(
                  store.measurements(second, _range.start, _range.end),
                  _range,
                  second,
                );
          final isSteps = type == MetricType.steps;
          // Adımda sütun toplamları, diğerlerinde tek tek ölçümler özetlenir.
          final stats = Stats.of(
            isSteps ? values.whereType<double>() : items.map((m) => m.value),
          );
          final canGoForward = _range.end.isBefore(DateTime.now());

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<Period>(
                segments: [
                  for (final p in Period.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_range.period},
                onSelectionChanged: (s) => setState(
                  () => _range = PeriodRange.of(s.first, _range.start),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Önceki',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _range = _range.shift(-1)),
                  ),
                  Expanded(
                    child: Text(
                      _rangeText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sonraki',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: canGoForward
                        ? () => setState(() => _range = _range.shift(1))
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Headline(
                type: type,
                stats: stats,
                secondary: second,
                secondStats: second == null
                    ? null
                    : Stats.of(
                        store
                            .measurements(second, _range.start, _range.end)
                            .map((m) => m.value),
                      ),
                steps: isSteps,
                period: _range.period,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: stats == null
                    ? Center(
                        child: Text(
                          'Bu dönem için kayıt yok',
                          style: TextStyle(color: context.colors.muted),
                        ),
                      )
                    : MetricChart(
                        range: _range,
                        values: values,
                        secondary: secondValues,
                        color: type.color,
                        secondaryColor: type.color.withValues(alpha: 0.5),
                        bars: isSteps,
                      ),
              ),
              const SizedBox(height: 20),
              if (stats != null && !isSteps)
                Row(
                  children: [
                    _StatBox('Ortalama', type.format(stats.average), type.unit),
                    const SizedBox(width: 10),
                    _StatBox('En yüksek', type.format(stats.max), type.unit),
                    const SizedBox(width: 10),
                    _StatBox('En düşük', type.format(stats.min), type.unit),
                  ],
                ),
              if (bandsFor(type) case final bands?) ...[
                const SizedBox(height: 20),
                _BandLegend(type: type, bands: bands, items: items),
              ],
              if (type == MetricType.systolic) ...[
                const SizedBox(height: 16),
                Text(
                  'Bileklik tansiyonu tahmini olarak hesaplar. Tanı ve tedavi '
                  'için onaylı bir tansiyon aleti kullanın.',
                  style: TextStyle(color: context.colors.muted),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.type,
    required this.stats,
    required this.steps,
    required this.period,
    this.secondary,
    this.secondStats,
  });

  final MetricType type;
  final Stats? stats;
  final MetricType? secondary;
  final Stats? secondStats;
  final bool steps;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final String caption;
    final String value;
    if (s == null) {
      caption = 'Ölçüm yok';
      value = '--';
    } else if (steps) {
      caption = period == Period.day ? 'Toplam' : 'Günlük ortalama';
      value = (period == Period.day ? s.total : s.average).round().toString();
    } else if (secondary != null && secondStats != null) {
      caption = 'Ortalama';
      value =
          '${type.format(s.average)}/${secondary!.format(secondStats!.average)}';
    } else {
      caption = 'Ortalama';
      value = type.format(s.average);
    }
    final band = s == null || steps ? null : bandOf(type, s.average);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: TextStyle(color: context.colors.muted)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: type.color,
              ),
            ),
            const SizedBox(width: 6),
            Text(type.unit, style: TextStyle(color: context.colors.muted)),
            if (band != null) ...[
              const SizedBox(width: 12),
              Chip(label: Text(band.label)),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value, this.unit);
  final String label, value, unit;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '$value $unit',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Stres ve HRV aralıkları ve dönemdeki ölçümlerin bu aralıklara dağılımı.
class _BandLegend extends StatelessWidget {
  const _BandLegend({
    required this.type,
    required this.bands,
    required this.items,
  });

  final MetricType type;
  final List<Band> bands;
  final List<Measurement> items;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aralıklar', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final b in bands)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text(b.label)),
                    SizedBox(
                      width: 70,
                      child: Text(
                        b.to >= 100 && b.from > 0
                            ? '> ${b.from.round() - 1}'
                            : '${b.from.round()}-${b.to.round()}',
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total == 0
                            ? 0
                            : items.where((m) => b.contains(m.value)).length /
                                  total,
                        color: type.color,
                        backgroundColor: context.colors.background,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
