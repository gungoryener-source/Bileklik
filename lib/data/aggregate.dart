import '../device/protocol/history.dart';
import 'models.dart';

/// Grafiklerde seçilen zaman aralığı.
enum Period {
  day('Gün'),
  week('Hafta'),
  month('Ay');

  const Period(this.label);
  final String label;
}

/// Bir dönemin başı ve sonu, ve grafikteki sütunlar.
class PeriodRange {
  final Period period;
  final DateTime start;
  final DateTime end;
  const PeriodRange(this.period, this.start, this.end);

  /// [anchor] gününü içeren dönem. Hafta pazartesi başlar.
  factory PeriodRange.of(Period period, DateTime anchor) {
    final d = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (period) {
      Period.day => PeriodRange(
        period,
        d,
        DateTime(d.year, d.month, d.day + 1),
      ),
      Period.week => PeriodRange(
        period,
        DateTime(d.year, d.month, d.day - (d.weekday - 1)),
        DateTime(d.year, d.month, d.day - (d.weekday - 1) + 7),
      ),
      Period.month => PeriodRange(
        period,
        DateTime(d.year, d.month),
        DateTime(d.year, d.month + 1),
      ),
    };
  }

  PeriodRange shift(int by) => PeriodRange.of(period, switch (period) {
    Period.day => DateTime(start.year, start.month, start.day + by),
    Period.week => DateTime(start.year, start.month, start.day + 7 * by),
    Period.month => DateTime(start.year, start.month + by),
  });

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  /// Gün görünümünde saatlik, diğerlerinde günlük sütunlar.
  List<DateTime> get buckets {
    final out = <DateTime>[];
    if (period == Period.day) {
      for (var h = 0; h < 24; h++) {
        out.add(DateTime(start.year, start.month, start.day, h));
      }
    } else {
      for (
        var t = start;
        t.isBefore(end);
        t = DateTime(t.year, t.month, t.day + 1)
      ) {
        out.add(t);
      }
    }
    return out;
  }

  int bucketOf(DateTime t) => period == Period.day
      ? t.hour
      : DateTime(t.year, t.month, t.day).difference(start).inDays;
}

/// Ölçümleri sütunlara toplar: adım için toplam, diğerleri için ortalama.
/// Ölçüm olmayan sütun null kalır.
List<double?> aggregate(
  List<Measurement> items,
  PeriodRange range,
  MetricType type,
) {
  final n = range.buckets.length;
  final sum = List<double>.filled(n, 0);
  final count = List<int>.filled(n, 0);
  for (final m in items) {
    if (!range.contains(m.time)) continue;
    final i = range.bucketOf(m.time);
    if (i < 0 || i >= n) continue;
    sum[i] += m.value;
    count[i]++;
  }
  final total = type.isTotal;
  return [
    for (var i = 0; i < n; i++)
      if (count[i] == 0) null else total ? sum[i] : sum[i] / count[i],
  ];
}

class Stats {
  final double average;
  final double max;
  final double min;
  final double total;
  final int count;
  const Stats(this.average, this.max, this.min, this.total, this.count);

  static Stats? of(Iterable<double> values) {
    final v = values.toList();
    if (v.isEmpty) return null;
    final total = v.reduce((a, b) => a + b);
    return Stats(
      total / v.length,
      v.reduce((a, b) => a > b ? a : b),
      v.reduce((a, b) => a < b ? a : b),
      total,
      v.length,
    );
  }
}

/// Stres ve HRV için ekranda gösterilen aralıklar.
class Band {
  final String label;
  final double from;
  final double to;
  const Band(this.label, this.from, this.to);

  bool contains(double v) => v >= from && v <= to;
}

const stressBands = [
  Band('Sakin', 0, 24),
  Band('Hafif', 25, 50),
  Band('Gergin', 51, 75),
  Band('Kaygılı', 76, 100),
];

const hrvBands = [
  Band('Düşük', 0, 24),
  Band('Normal', 25, 50),
  Band('İyi', 51, 75),
  Band('Harika', 76, 255),
];

List<Band>? bandsFor(MetricType type) => switch (type) {
  MetricType.stress => stressBands,
  MetricType.hrv => hrvBands,
  _ => null,
};

Band? bandOf(MetricType type, double value) {
  for (final b in bandsFor(type) ?? const <Band>[]) {
    if (b.contains(value.roundToDouble())) return b;
  }
  return null;
}

/// Bir gecenin uykusu: akşam 18:00'den ertesi gün 18:00'e kadar başlayan
/// kayıtlar o güne (uyanılan güne) yazılır.
class NightSleep {
  final DateTime day;
  final List<SleepSession> sessions;
  const NightSleep(this.day, this.sessions);

  DateTime get start => sessions.first.start;
  DateTime get end => sessions.last.end;

  int minutesIn(SleepStage s) =>
      sessions.fold(0, (sum, x) => sum + x.minutesIn(s));

  int get asleepMinutes =>
      sessions.fold(0, (sum, x) => sum + x.minutes.length) -
      minutesIn(SleepStage.awake);

  static DateTime dayOf(DateTime start) {
    final shifted = start.add(const Duration(hours: 6));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  static List<NightSleep> group(List<SleepSession> sessions) {
    final byDay = <DateTime, List<SleepSession>>{};
    for (final s in sessions) {
      byDay.putIfAbsent(dayOf(s.start), () => []).add(s);
    }
    return [
      for (final e in byDay.entries)
        NightSleep(e.key, e.value..sort((a, b) => a.start.compareTo(b.start))),
    ]..sort((a, b) => a.day.compareTo(b.day));
  }
}
