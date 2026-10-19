import 'aggregate.dart';
import 'health_store.dart';
import 'models.dart';

/// Ana Sayfa için bir günün özeti: o güne yazılan uyku, etkinlik,
/// saatlik nabız/SpO2/stres ve günün kayıtları.
class DaySummary {
  DaySummary._(this.range, this.store);

  /// [day] gününün özetini depodaki ölçümlerden çıkarır.
  factory DaySummary.of(HealthStore store, DateTime day) {
    final s = DaySummary._(PeriodRange.of(Period.day, day), store);
    s._build();
    return s;
  }

  final PeriodRange range;
  final HealthStore store;

  DateTime get day => range.start;

  /// Bu güne (uyanılan güne) yazılan gece uykusu.
  NightSleep? night;

  /// Uyku sırasındaki ortalama nabız ve SpO2.
  double? sleepHeartRate;
  double? sleepSpo2;

  /// Gece ortalama HRV (ms); yoksa günün ortalaması.
  double? recoveryHrv;

  /// Günün ortalama stresi (0-100).
  double? averageStress;

  int steps = 0;
  double calories = 0;
  double distanceKm = 0;

  /// 24 saatlik sütunlar; ölçüm olmayan saat null.
  late List<double?> hourlyHeartRate;
  late List<double?> hourlySpo2;
  late List<double?> hourlyStress;

  List<Workout> workouts = const [];
  List<EcgRecording> ecgs = const [];

  Stats? heartRateStats;
  Stats? spo2Stats;

  List<Measurement> _day(MetricType t) =>
      store.measurements(t, range.start, range.end);

  double? _avg(MetricType t, DateTime from, DateTime to) =>
      Stats.of(store.measurements(t, from, to).map((m) => m.value))?.average;

  void _build() {
    final nights = NightSleep.group(
      store.sleepBetween(
        range.start.subtract(const Duration(hours: 12)),
        range.end,
      ),
    );
    night = nights.where((n) => n.day == day).lastOrNull;
    final n = night;
    if (n != null) {
      sleepHeartRate = _avg(MetricType.heartRate, n.start, n.end);
      sleepSpo2 = _avg(MetricType.spo2, n.start, n.end);
      recoveryHrv = _avg(MetricType.hrv, n.start, n.end);
    }
    recoveryHrv ??= _avg(MetricType.hrv, range.start, range.end);
    averageStress = _avg(MetricType.stress, range.start, range.end);

    double total(MetricType t) => _day(t).fold(0.0, (s, m) => s + m.value);
    steps = total(MetricType.steps).round();
    calories = total(MetricType.calories);
    distanceKm = total(MetricType.distance);

    final hr = _day(MetricType.heartRate);
    final o2 = _day(MetricType.spo2);
    hourlyHeartRate = aggregate(hr, range, MetricType.heartRate);
    hourlySpo2 = aggregate(o2, range, MetricType.spo2);
    hourlyStress = aggregate(_day(MetricType.stress), range, MetricType.stress);
    heartRateStats = Stats.of(hr.map((m) => m.value));
    spo2Stats = Stats.of(o2.map((m) => m.value));

    workouts = store.workoutsBetween(range.start, range.end);
    ecgs = [
      for (final e in store.ecgRecordings())
        if (range.contains(e.start)) e,
    ];
  }

  /// Günün olayları, en yenisi önce.
  List<TimelineEvent> get timeline {
    final out = <TimelineEvent>[
      for (final w in workouts) TimelineEvent.workout(w),
      for (final e in ecgs) TimelineEvent.ecg(e),
      if (night case final n?) TimelineEvent.sleep(n),
    ];
    out.sort((a, b) => b.time.compareTo(a.time));
    return out;
  }
}

/// Zaman çizelgesindeki bir olay.
sealed class TimelineEvent {
  const TimelineEvent();
  DateTime get time;

  const factory TimelineEvent.workout(Workout w) = WorkoutEvent;
  const factory TimelineEvent.ecg(EcgRecording r) = EcgEvent;
  const factory TimelineEvent.sleep(NightSleep n) = SleepEvent;
}

class WorkoutEvent extends TimelineEvent {
  const WorkoutEvent(this.workout);
  final Workout workout;
  @override
  DateTime get time => workout.start;
}

class EcgEvent extends TimelineEvent {
  const EcgEvent(this.recording);
  final EcgRecording recording;
  @override
  DateTime get time => recording.start;
}

class SleepEvent extends TimelineEvent {
  const SleepEvent(this.night);
  final NightSleep night;

  /// Uyanma zamanı çizelgede gösterilir.
  @override
  DateTime get time => night.end;
}
