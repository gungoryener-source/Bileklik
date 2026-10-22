import 'dart:math';

import '../device/protocol/history.dart';
import 'aggregate.dart';
import 'day_summary.dart';
import 'health_store.dart';
import 'models.dart';

/// Günlük adım hedefi.
const dailyStepGoal = 10000;

// ---------------------------------------------------------------------------
// Enerji skoru
// ---------------------------------------------------------------------------

/// Günün enerjisi (0–100): gece toplanan enerjiden (uyku ve toparlanma) gün
/// içi harcamanın (adım ve stres) düşülmesiyle bulunur. Uygulamanın kendi
/// tahminidir; tıbbi bir ölçüm değildir.
class EnergyScore {
  const EnergyScore({
    required this.score,
    required this.sleepScore,
    required this.recoveryScore,
    required this.drain,
  });

  /// 0–100.
  final int score;

  /// Uyku süresi (8 saat hedef, %70) ve derin+REM payından (%30); uyku
  /// yoksa null.
  final int? sleepScore;

  /// Gecenin HRV'sinin son 14 günün ortancasına oranı; 50 olağan. HRV
  /// yoksa null.
  final int? recoveryScore;

  /// Gün içinde harcanan: adım (en çok 25) ve stres (en çok 15).
  final int drain;

  /// [day] gününün enerjisi; bugünse harcama o ana kadarki kayıtlardandır.
  /// Ne uyku ne HRV varsa null.
  static EnergyScore? of(HealthStore store, DateTime day) {
    final s = DaySummary.of(store, day);
    final night = s.night;
    int? sleep;
    if (night != null && night.asleepMinutes > 0) {
      final asleep = night.asleepMinutes;
      final restorative =
          night.minutesIn(SleepStage.deep) + night.minutesIn(SleepStage.rem);
      sleep =
          (min(asleep / 480, 1) * 70 + min(restorative / asleep / 0.4, 1) * 30)
              .round();
    }
    int? recovery;
    final hrv = s.recoveryHrv;
    if (hrv != null) {
      final base = _median([
        for (final m in store.measurements(
          MetricType.hrv,
          s.day.subtract(const Duration(days: 14)),
          s.day,
        ))
          m.value,
      ]);
      // Ortancanın üçte biri kadar sapma 0 ya da 100 eder.
      recovery = base == null || base <= 0
          ? 50
          : (50 + (hrv / base - 1) * 150).clamp(0, 100).round();
    }
    final charge = switch ((sleep, recovery)) {
      (null, null) => null,
      (final sl?, null) => sl.toDouble(),
      (null, final r?) => r.toDouble(),
      (final sl?, final r?) => 0.6 * sl + 0.4 * r,
    };
    if (charge == null) return null;
    final stepDrain = min(s.steps / 15000, 1) * 25;
    final stress = s.averageStress;
    final stressDrain = stress == null ? 0 : ((stress - 30) / 70).clamp(0, 1) * 15;
    final drain = (stepDrain + stressDrain).round();
    return EnergyScore(
      score: (charge - drain).clamp(0, 100).round(),
      sleepScore: sleep,
      recoveryScore: recovery,
      drain: drain,
    );
  }
}

/// Enerji düzeyi: ekranda renk ve kısa açıklama için.
enum EnergyLevel { low, medium, high }

extension EnergyScoreLevel on EnergyScore {
  EnergyLevel get level => score >= 67
      ? EnergyLevel.high
      : score >= 34
      ? EnergyLevel.medium
      : EnergyLevel.low;
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final v = [...values]..sort();
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}

// ---------------------------------------------------------------------------
// Haftalık rapor
// ---------------------------------------------------------------------------

/// Bir haftanın (pazartesi–pazar) özeti.
class WeekStats {
  const WeekStats({
    required this.range,
    required this.steps,
    required this.goalDays,
    required this.daysWithData,
    required this.averageSleepMinutes,
    required this.averageHrv,
    required this.averageStress,
    required this.workouts,
    required this.workoutMinutes,
  });

  final PeriodRange range;
  final int steps;

  /// Adım hedefine ulaşılan gün sayısı.
  final int goalDays;

  /// Adım ya da nabız verisi olan gün sayısı (ortalamalar bunlara bölünür).
  final int daysWithData;
  final double? averageSleepMinutes;
  final double? averageHrv;
  final double? averageStress;
  final int workouts;
  final int workoutMinutes;

  /// Günlük ortalama adım (veri olan günlere göre).
  int? get averageSteps =>
      daysWithData == 0 ? null : (steps / daysWithData).round();

  bool get isEmpty => daysWithData == 0 && averageSleepMinutes == null;

  static WeekStats of(HealthStore store, PeriodRange week) {
    var steps = 0;
    var goalDays = 0;
    var daysWithData = 0;
    final sleep = <double>[];
    for (var d = week.start; d.isBefore(week.end); d = DateTime(d.year, d.month, d.day + 1)) {
      final next = DateTime(d.year, d.month, d.day + 1);
      final daySteps = store
          .measurements(MetricType.steps, d, next)
          .fold(0.0, (sum, m) => sum + m.value)
          .round();
      final hasHr = store.measurements(MetricType.heartRate, d, next).isNotEmpty;
      if (daySteps > 0 || hasHr) daysWithData++;
      steps += daySteps;
      if (daySteps >= dailyStepGoal) goalDays++;
    }
    for (final n in NightSleep.group(
      store.sleepBetween(week.start.subtract(const Duration(hours: 12)), week.end),
    )) {
      if (week.contains(n.day)) sleep.add(n.asleepMinutes.toDouble());
    }
    final workouts = store.workoutsBetween(week.start, week.end);
    return WeekStats(
      range: week,
      steps: steps,
      goalDays: goalDays,
      daysWithData: daysWithData,
      averageSleepMinutes: Stats.of(sleep)?.average,
      averageHrv: Stats.of(
        store.measurements(MetricType.hrv, week.start, week.end).map((m) => m.value),
      )?.average,
      averageStress: Stats.of(
        store.measurements(MetricType.stress, week.start, week.end).map((m) => m.value),
      )?.average,
      workouts: workouts.length,
      workoutMinutes: workouts.fold(0, (sum, w) => sum + w.duration.inMinutes),
    );
  }
}

/// Bir hafta ve bir önceki hafta, karşılaştırma için.
class WeeklyReport {
  const WeeklyReport(this.current, this.previous);

  factory WeeklyReport.of(HealthStore store, DateTime anyDay) {
    final week = PeriodRange.of(Period.week, anyDay);
    return WeeklyReport(
      WeekStats.of(store, week),
      WeekStats.of(store, week.shift(-1)),
    );
  }

  final WeekStats current;
  final WeekStats previous;

  /// Önceki haftaya göre yüzde değişim; önceki değer yoksa ya da sıfırsa null.
  static int? change(num? now, num? before) {
    if (now == null || before == null || before == 0) return null;
    return ((now - before) / before * 100).round();
  }
}

// ---------------------------------------------------------------------------
// Rozetler
// ---------------------------------------------------------------------------

/// Kazanılabilen rozetler. Tasarım ve ölçütler uygulamaya özgüdür.
enum AchievementKind {
  /// İlk ölçüm bileklikten geldi.
  firstSync,

  /// Bir günde 10.000 adım.
  steps10k,

  /// Bir günde 20.000 adım.
  steps20k,

  /// 7 gün art arda adım hedefi.
  goalStreak7,

  /// 7 gece art arda en az 7 saat uyku.
  sleepStreak7,

  /// Toplam 10 egzersiz.
  workouts10,

  /// İlk EKG kaydı.
  firstEcg,

  /// Bir haftada 42,2 km (maraton mesafesi).
  marathonWeek,

  /// 30 farklı günde bileklik takıldı.
  wear30,
}

class Achievement {
  const Achievement(this.kind, this.progress, this.earnedOn);

  final AchievementKind kind;

  /// 0–1; kazanıldıysa 1.
  final double progress;

  /// Ölçütün ilk sağlandığı gün; kazanılmadıysa null.
  final DateTime? earnedOn;

  bool get earned => earnedOn != null;
}

/// Son [days] günün kayıtlarından rozetler. Rozetler saklanmaz; her açılışta
/// geçmişten yeniden hesaplanır, böylece silinen veriyle birlikte giderler.
List<Achievement> achievements(HealthStore store, DateTime now, {int days = 365}) {
  final today = DateTime(now.year, now.month, now.day);
  final from = DateTime(today.year, today.month, today.day - days + 1);
  final to = today.add(const Duration(days: 1));

  DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  final stepsByDay = <DateTime, double>{};
  for (final m in store.measurements(MetricType.steps, from, to)) {
    stepsByDay.update(dayOf(m.time), (v) => v + m.value, ifAbsent: () => m.value);
  }
  final distanceByDay = <DateTime, double>{};
  for (final m in store.measurements(MetricType.distance, from, to)) {
    distanceByDay.update(dayOf(m.time), (v) => v + m.value, ifAbsent: () => m.value);
  }
  final wornDays = <DateTime>{
    for (final e in stepsByDay.entries)
      if (e.value > 0) e.key,
    for (final m in store.measurements(MetricType.heartRate, from, to)) dayOf(m.time),
  };
  final sleepByDay = <DateTime, int>{
    for (final n in NightSleep.group(store.sleepBetween(from, to)))
      n.day: n.asleepMinutes,
  };
  final workouts = store.workoutsBetween(from, to);
  final ecgs = [
    for (final e in store.ecgRecordings())
      if (!e.start.isBefore(from) && e.start.isBefore(to)) e,
  ]..sort((a, b) => a.start.compareTo(b.start));

  final allDays = [
    for (var d = from; d.isBefore(to); d = DateTime(d.year, d.month, d.day + 1)) d,
  ];

  /// Günlük ölçüt ilk kez ne zaman sağlandı; en iyi değerin hedefe oranı.
  Achievement daily(AchievementKind k, Map<DateTime, num> byDay, num target) {
    DateTime? on;
    num best = 0;
    for (final d in allDays) {
      final v = byDay[d] ?? 0;
      best = max(best, v);
      if (on == null && v >= target) on = d;
    }
    return Achievement(k, on != null ? 1 : min(best / target, 1).toDouble(), on);
  }

  /// [ok] art arda [length] gün sağlandığında kazanılır.
  Achievement streak(AchievementKind k, bool Function(DateTime) ok, int length) {
    var run = 0;
    var best = 0;
    DateTime? on;
    for (final d in allDays) {
      run = ok(d) ? run + 1 : 0;
      best = max(best, run);
      if (on == null && run >= length) on = d;
    }
    return Achievement(k, on != null ? 1 : best / length, on);
  }

  /// Sıralı olaylardan [count]'uncusunun günü.
  Achievement count(AchievementKind k, List<DateTime> times, int count) => Achievement(
    k,
    min(times.length / count, 1).toDouble(),
    times.length >= count ? dayOf(times[count - 1]) : null,
  );

  final firstData = [
    ...wornDays,
    ...sleepByDay.keys,
  ]..sort();

  // Haftalık mesafe: pazartesi başlayan haftalar.
  final weekDistance = <DateTime, double>{};
  DateTime? marathonOn;
  for (final d in allDays) {
    final week = PeriodRange.of(Period.week, d).start;
    final total = weekDistance.update(
      week,
      (v) => v + (distanceByDay[d] ?? 0),
      ifAbsent: () => distanceByDay[d] ?? 0,
    );
    if (marathonOn == null && total >= 42.195) marathonOn = d;
  }
  final bestWeek = weekDistance.values.fold(0.0, max);

  return [
    count(AchievementKind.firstSync, firstData, 1),
    daily(AchievementKind.steps10k, stepsByDay, dailyStepGoal),
    daily(AchievementKind.steps20k, stepsByDay, 2 * dailyStepGoal),
    streak(
      AchievementKind.goalStreak7,
      (d) => (stepsByDay[d] ?? 0) >= dailyStepGoal,
      7,
    ),
    streak(AchievementKind.sleepStreak7, (d) => (sleepByDay[d] ?? 0) >= 7 * 60, 7),
    count(
      AchievementKind.workouts10,
      [for (final w in workouts) w.start]..sort(),
      10,
    ),
    count(AchievementKind.firstEcg, [for (final e in ecgs) e.start], 1),
    Achievement(
      AchievementKind.marathonWeek,
      marathonOn != null ? 1 : min(bestWeek / 42.195, 1).toDouble(),
      marathonOn,
    ),
    count(AchievementKind.wear30, wornDays.toList()..sort(), 30),
  ];
}
