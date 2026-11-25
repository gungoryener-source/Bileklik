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

  /// Uyku sırasında görülen dikkat çekici ölçümler (düşük HRV, yüksek ya
  /// da düşük nabız, SpO2 düşüşü), saat sırasıyla.
  List<NightEvent> nightEvents = const [];

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
      nightEvents = NightEvent.detect(store, n.start, n.end);
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
      if (night case final n?) ...[
        TimelineEvent.sleep(n),
        TimelineEvent.fellAsleep(n),
      ],
      ...nightEvents,
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
  const factory TimelineEvent.fellAsleep(NightSleep n) = FellAsleepEvent;
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

/// Uykuya dalış: gecenin ilk kaydı.
class FellAsleepEvent extends TimelineEvent {
  const FellAsleepEvent(this.night);
  final NightSleep night;
  @override
  DateTime get time => night.start;
}

/// Gece görülen olayın türü.
enum NightEventKind {
  lowHrv(MetricType.hrv),
  highHeartRate(MetricType.heartRate),
  lowHeartRate(MetricType.heartRate),
  lowSpo2(MetricType.spo2);

  const NightEventKind(this.type);

  /// Olayın geldiği ölçüm türü (ayrıntı ekranı için).
  final MetricType type;
}

/// Uyku sırasında eşiği aşan bir ölçüm.
///
/// Eşikler yaygın tarama değerleridir; tanı değildir ve gerçek cihaz
/// kayıtlarıyla ayarlanacak. Aynı türden 30 dakika içindeki ölçümler tek
/// olayda birleşir, en uç değer kalır.
class NightEvent extends TimelineEvent {
  const NightEvent(this.kind, this.time, this.value);

  final NightEventKind kind;
  @override
  final DateTime time;
  final double value;

  static const lowHrvMs = 20;
  static const highBpm = 100;
  static const lowBpm = 40;
  static const lowSpo2Percent = 90;
  static const mergeWindow = Duration(minutes: 30);

  static NightEventKind? kindOf(MetricType type, double v) => switch (type) {
    MetricType.hrv when v > 0 && v < lowHrvMs => NightEventKind.lowHrv,
    MetricType.heartRate when v > highBpm => NightEventKind.highHeartRate,
    MetricType.heartRate when v > 0 && v < lowBpm =>
      NightEventKind.lowHeartRate,
    MetricType.spo2 when v > 0 && v < lowSpo2Percent => NightEventKind.lowSpo2,
    _ => null,
  };

  /// [from]-[to] arasındaki (uyku) ölçümlerden olayları çıkarır.
  static List<NightEvent> detect(
    HealthStore store,
    DateTime from,
    DateTime to,
  ) {
    final out = <NightEvent>[];
    for (final type in const [
      MetricType.hrv,
      MetricType.heartRate,
      MetricType.spo2,
    ]) {
      final items = [...store.measurements(type, from, to)]
        ..sort((a, b) => a.time.compareTo(b.time));
      final last = <NightEventKind, int>{};
      for (final m in items) {
        final kind = kindOf(type, m.value);
        if (kind == null) continue;
        final i = last[kind];
        if (i != null && m.time.difference(out[i].time) <= mergeWindow) {
          // Düşük olaylarda en düşük, yüksekte en yüksek değer kalır.
          final worse = kind == NightEventKind.highHeartRate
              ? m.value > out[i].value
              : m.value < out[i].value;
          if (worse) out[i] = NightEvent(kind, out[i].time, m.value);
          continue;
        }
        last[kind] = out.length;
        out.add(NightEvent(kind, m.time, m.value));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}
