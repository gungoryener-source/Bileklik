import 'aggregate.dart';
import 'day_summary.dart';
import 'health_store.dart';
import 'hrv_analysis.dart' as hrv_analysis;
import 'models.dart';
import 'sleep_analysis.dart';

/// Toparlanma düzeyi; sınırlar 90, 75, 60 ve 40.
enum RecoveryLevel {
  excellent,
  good,
  normal,
  poor,
  inadequate;

  static RecoveryLevel of(int score) => score >= 90
      ? excellent
      : score >= 75
      ? good
      : score >= 60
      ? normal
      : score >= 40
      ? poor
      : inadequate;

  /// Düzeyin alt sınırı.
  int get floor => switch (this) {
    excellent => 90,
    good => 75,
    normal => 60,
    poor => 40,
    inadequate => 0,
  };
}

/// Günlük toparlanma 0–100: gece HRV'si ve dinlenik nabzın kişinin son 14
/// günlük olağanına göre durumu, uyku skoru ve günün stresi. Olmayan
/// gösterge hesaba katılmaz; ne HRV ne uyku varsa hesap yok. Uygulamanın
/// kendi tahminidir, tıbbi değildir.
class DayRecovery {
  const DayRecovery({
    required this.day,
    required this.score,
    this.hrv,
    this.hrvBaseline,
    this.restingHeartRate,
    this.restingBaseline,
    this.stress,
    this.sleepScore,
  });

  final DateTime day;
  final int score;
  final double? hrv;
  final double? hrvBaseline;
  final int? restingHeartRate;
  final int? restingBaseline;
  final double? stress;
  final int? sleepScore;

  RecoveryLevel get level => RecoveryLevel.of(score);

  /// Bu değerin ve üstünün ideal sayıldığı sınır.
  static const optimal = 75;

  /// HRV olağanın %85'inin altında.
  bool get hrvLow =>
      hrv != null && hrvBaseline != null && hrv! < hrvBaseline! * 0.85;

  /// Dinlenik nabız olağandan 3 atım/dk'dan fazla yüksek.
  bool get restingHigh =>
      restingHeartRate != null &&
      restingBaseline != null &&
      restingHeartRate! > restingBaseline! + 3;

  static DayRecovery? of(HealthStore store, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DaySummary.of(store, d);
    final night = s.night;
    final sleep = night == null ? null : sleepScoreOf(night);
    final hrv = s.recoveryHrv;
    if (hrv == null && sleep == null) return null;

    final parts = <(double, double)>[]; // (puan, ağırlık)
    double? hrvBase;
    if (hrv != null) {
      hrvBase = _median([
        for (final m in store.measurements(
          MetricType.hrv,
          d.subtract(const Duration(days: 14)),
          d,
        ))
          m.value,
      ]);
      final v = hrvBase == null || hrvBase <= 0
          ? 50.0
          : (50 + (hrv / hrvBase - 1) * 150).clamp(0, 100).toDouble();
      parts.add((v, 0.35));
    }
    final endOfDay = DateTime(d.year, d.month, d.day, 23, 59);
    final rhr = hrv_analysis.restingHeartRate(store, endOfDay, days: 1);
    final rhrBase = hrv_analysis.restingHeartRate(
      store,
      DateTime(d.year, d.month, d.day - 1, 23, 59),
      days: 14,
    );
    if (rhr != null && rhrBase != null && rhrBase > 0) {
      // Olağandan %10 düşük 100, %10 yüksek 0 eder.
      parts.add((
        (50 + (rhrBase - rhr) / rhrBase * 500).clamp(0, 100).toDouble(),
        0.2,
      ));
    }
    if (sleep != null) parts.add((sleep.toDouble(), 0.3));
    final stress = s.averageStress;
    if (stress != null) parts.add(((100 - stress).clamp(0, 100), 0.15));

    final weight = parts.fold(0.0, (a, p) => a + p.$2);
    final score = parts.fold(0.0, (a, p) => a + p.$1 * p.$2) / weight;
    return DayRecovery(
      day: d,
      score: score.round().clamp(0, 100),
      hrv: hrv,
      hrvBaseline: hrvBase,
      restingHeartRate: rhr,
      restingBaseline: rhrBase,
      stress: stress,
      sleepScore: sleep,
    );
  }

  /// Dönemin her günü için toparlanma; hesaplanamayan ya da gelecekteki
  /// gün null.
  static List<(DateTime, int?)> series(
    HealthStore store,
    PeriodRange range, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    return [
      for (final d in range.buckets)
        (d, d.isAfter(today) ? null : of(store, d)?.score),
    ];
  }
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final v = [...values]..sort();
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}
