import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../format.dart';
import '../theme.dart';

/// Bir dönemin sütun ya da çizgi grafiği. Boş sütunlar çizilmez.
class MetricChart extends StatelessWidget {
  const MetricChart({
    super.key,
    required this.range,
    required this.values,
    required this.color,
    this.bars = false,
    this.secondary,
    this.secondaryColor,
  });

  final PeriodRange range;
  final List<double?> values;
  final List<double?>? secondary;
  final Color color;
  final Color? secondaryColor;
  final bool bars;

  String _label(int i) {
    final t = range.buckets[i];
    return switch (range.period) {
      Period.day => i % 6 == 0 ? two(t.hour) : '',
      Period.week => weekdayShort(t.weekday),
      Period.month => (t.day - 1) % 7 == 0 ? '${t.day}' : '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final titles = FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (v, meta) => SideTitleWidget(
            meta: meta,
            child: Text(
              _label(v.toInt()),
              style: TextStyle(color: context.colors.muted, fontSize: 11),
            ),
          ),
        ),
      ),
    );
    const grid = FlGridData(drawVerticalLine: false);
    final border = FlBorderData(show: false);

    if (bars) {
      return BarChart(
        BarChartData(
          titlesData: titles,
          gridData: grid,
          borderData: border,
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i] ?? 0,
                    color: color,
                    width: range.period == Period.month ? 5 : 8,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    LineChartBarData line(List<double?> v, Color c) => LineChartBarData(
      spots: [
        for (var i = 0; i < v.length; i++)
          if (v[i] case final y?) FlSpot(i.toDouble(), y),
      ],
      color: c,
      barWidth: 2.5,
      isCurved: true,
      preventCurveOverShooting: true,
      dotData: FlDotData(show: range.period != Period.day),
    );

    final all = [...values, ...?secondary].whereType<double>();
    final lo = all.isEmpty ? 0.0 : all.reduce((a, b) => a < b ? a : b);
    final hi = all.isEmpty ? 1.0 : all.reduce((a, b) => a > b ? a : b);
    final pad = ((hi - lo) * 0.2).clamp(1.0, double.infinity);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: (lo - pad).floorToDouble(),
        maxY: (hi + pad).ceilToDouble(),
        titlesData: titles,
        gridData: grid,
        borderData: border,
        lineBarsData: [
          line(values, color),
          if (secondary case final s?) line(s, secondaryColor ?? color),
        ],
      ),
    );
  }
}
