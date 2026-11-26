import 'dart:math';

import 'aggregate.dart';
import 'day_summary.dart';
import 'health_store.dart';
import 'hrv_analysis.dart' as hrv_analysis;
import 'insights.dart';
import 'models.dart';
import 'recovery.dart';

/// Günlük yük düzeyi; sınırlar 5, 9, 13 ve 17 (0–21 ölçeği).
enum StrainLevel {
  veryLow,
  normal,
  moderate,
  high,
  overloaded;

  static StrainLevel of(double score) => score < 5
      ? veryLow
      : score < 9
      ? normal
      : score < 13
      ? moderate
      : score < 17
      ? high
      : overloaded;

  /// Düzeyin alt sınırı.
  double get floor => switch (this) {
    veryLow => 0,
    normal => 5,
    moderate => 9,
    high => 13,
    overloaded => 17,
  };

  /// Düzeyin üst sınırı.
  double get ceiling =>
      this == overloaded ? DayStrain.max : StrainLevel.values[index + 1].floor;
}

/// Günlük yük 0–21: gün içinde nabzın dinlenik nabzın ne kadar üstünde
/// kaldığı (TRIMP benzeri, yüksek nabız katlanarak ağırlaşır), egzersizler
/// ve adımlar. Yük arttıkça ölçek doyar; 21'e yaklaşmak çok zorlaşır.
/// Uyku sırasındaki nabız sayılmaz. Uygulamanın kendi tahminidir, tıbbi
/// değildir.
class DayStrain {
  const DayStrain({
    required this.day,
    required this.score,
    this.averageHeartRate,
    this.steps = 0,
    this.calories = 0,
    this.workoutMinutes = 0,
    this.sleepStart,
    this.sleepEnd,
    this.sleepMinutes,
    this.optimal,
  });

  final DateTime day;

  /// 0–21, bir ondalık.
  final double score;

  /// Günün ortalama nabzı (uyku dahil); ölçüm yoksa null.
  final int? averageHeartRate;
  final int steps;
  final double calories;
  final int workoutMinutes;

  /// Bu güne yazılan gece uykusu; yoksa null.
  final DateTime? sleepStart;
  final DateTime? sleepEnd;
  final int? sleepMinutes;

  /// Toparlanmaya göre ideal yük aralığı; toparlanma bilinmiyorsa null.
  final (double, double)? optimal;

  static const max = 21.0;

  /// Yükün doyma sabiti: bu kadar TRIMP birimi ölçeğin yaklaşık %63'ü.
  static const _saturation = 150.0;

  StrainLevel get level => StrainLevel.of(score);

  /// Yük ideal aralığın altında / üstünde.
  bool get belowOptimal => optimal != null && score < optimal!.$1;
  bool get aboveOptimal => optimal != null && score > optimal!.$2;

  /// Toparlanma skoruna göre önerilen yük aralığı.
  static (double, double) optimalFor(int recovery) => recovery >= 75
      ? (10, 14)
      : recovery >= 60
      ? (8, 12)
      : recovery >= 40
      ? (5, 9)
      : (0, 6);

  /// Bir dakikalık nabız yükü; [reserve] nabız yedeğinin payı (0–1).
  static double trimp(double reserve) =>
      reserve <= 0.3 ? 0 : reserve * 0.64 * exp(1.92 * reserve);

  /// TRIMP birimindeki yükün 0–21 ölçeğindeki karşılığı (bir ondalık
  /// yuvarlanmadan).
  static double scale(double load) => max * (1 - exp(-load / _saturation));

  /// [day] gününün yükü; ne nabız ne adım ne egzersiz varsa null.
  /// [age] verilirse en yüksek nabız yaşa göre, yoksa 190 alınır.
  static DayStrain? of(HealthStore store, DateTime day, {int? age}) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DaySummary.of(store, d);
    final hr = store.measurements(MetricType.heartRate, d, s.range.end);
    if (hr.isEmpty && s.steps == 0 && s.workouts.isEmpty) return null;

    final rest =
        hrv_analysis.restingHeartRate(
          store,
          DateTime(d.year, d.month, d.day, 23, 59),
          days: 1,
        ) ??
        60;
    final maxHr = age == null ? 190 : maxHeartRate(age);
    double reserve(num bpm) =>
        maxHr <= rest ? 0 : (bpm - rest) / (maxHr - rest);

    final night = s.night;
    bool asleep(DateTime t) =>
        night != null && !t.isBefore(night.start) && t.isBefore(night.end);
    bool inWorkout(DateTime t) => s.workouts.any(
      (w) => !t.isBefore(w.start) && t.isBefore(w.start.add(w.duration)),
    );

    var load = 0.0;
    // Egzersiz dışındaki uyanık nabız ölçümleri; ölçümler arası en çok 15 dk.
    final sorted = [...hr]..sort((a, b) => a.time.compareTo(b.time));
    for (var i = 0; i < sorted.length; i++) {
      final m = sorted[i];
      if (m.value <= 0 || asleep(m.time) || inWorkout(m.time)) continue;
      final next = i + 1 < sorted.length ? sorted[i + 1].time : s.range.end;
      final minutes = min(next.difference(m.time).inSeconds / 60, 15.0);
      load += minutes * trimp(reserve(m.value));
    }
    var workoutMinutes = 0;
    for (final w in s.workouts) {
      workoutMinutes += w.duration.inMinutes;
      if (w.averageHeartRate > 0) {
        load += w.duration.inSeconds / 60 * trimp(reserve(w.averageHeartRate));
      }
    }
    load += s.steps / 1000 * 1.5;

    final score = scale(load);
    final recovery = DayRecovery.of(store, d);
    return DayStrain(
      day: d,
      score: (score * 10).round() / 10,
      averageHeartRate: s.heartRateStats?.average.round(),
      steps: s.steps,
      calories: s.calories,
      workoutMinutes: workoutMinutes,
      sleepStart: night?.start,
      sleepEnd: night?.end,
      sleepMinutes: night?.asleepMinutes,
      optimal: recovery == null ? null : optimalFor(recovery.score),
    );
  }

  /// Dönemin her günü için yük; hesaplanamayan ya da gelecekteki gün null.
  static List<(DateTime, double?)> series(
    HealthStore store,
    PeriodRange range, {
    int? age,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    return [
      for (final d in range.buckets)
        (d, d.isAfter(today) ? null : of(store, d, age: age)?.score),
    ];
  }
}
