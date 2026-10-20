import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/aggregate.dart';
import '../format.dart';
import '../theme.dart';

/// Bir dönemin sütun ya da çizgi grafiği. Boş sütunlar çizilmez.
///
/// Cam görünümü: çizgi veri renginde, altında solan dolgu; ızgara beyaz
/// %8; eksen yazıları ikincil metin renginde. Sütunlarda bugünün sütunu
/// degrade ve parıltılı.
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

  /// Bugünü içeren sütun; dönem bugünü içermiyorsa -1.
  int _todayIndex(DateTime now) {
    if (range.period == Period.day) return -1;
    final b = range.buckets;
    for (var i = 0; i < b.length; i++) {
      final t = b[i];
      if (t.year == now.year && t.month == now.month && t.day == now.day) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final axis = TextStyle(color: c.muted, fontSize: 11);
    final titles = FlTitlesData(
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
          interval: 1,
          getTitlesWidget: (v, meta) => SideTitleWidget(
            meta: meta,
            child: Text(_label(v.toInt()), style: axis),
          ),
        ),
      ),
    );
    final grid = FlGridData(
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => FlLine(color: c.grid, strokeWidth: 1),
    );
    final border = FlBorderData(show: false);

    if (bars) {
      final today = _todayIndex(DateTime.now());
      final width = range.period == Period.month ? 5.0 : 10.0;
      final light = Color.lerp(color, c.text, 0.35)!;
      return BarChart(
        BarChartData(
          titlesData: titles,
          gridData: grid,
          borderData: border,
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                // Bugünün sütununun arkasında daha geniş, yarı saydam bir
                // sütun parıltı gibi durur (fl_chart sütuna gölge çizmez).
                groupVertically: i == today,
                barRods: [
                  if (i == today && (values[i] ?? 0) > 0)
                    BarChartRodData(
                      toY: values[i]!,
                      color: color.withValues(alpha: 0.28),
                      width: width + 8,
                      borderRadius: BorderRadius.circular((width + 8) / 2),
                    ),
                  BarChartRodData(
                    toY: values[i] ?? 0,
                    color: i == today ? null : color.withValues(alpha: 0.7),
                    gradient: i == today
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [light, color],
                          )
                        : null,
                    width: width,
                    borderRadius: BorderRadius.circular(width / 2),
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
      shadow: Shadow(color: c.withValues(alpha: 0.5), blurRadius: 8),
      dotData: FlDotData(show: range.period != Period.day),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.withValues(alpha: 0.32), c.withValues(alpha: 0)],
        ),
      ),
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
