import '../device/protocol/exercise.dart';
import '../device/protocol/history.dart';
import '../device/wristband_client.dart';
import 'health_store.dart';
import 'models.dart';

/// Bileklikteki geçmiş verileri çekip depoya yazar.
///
/// Her tür için depodaki son kaydın zamanını gönderir; cihaz yalnızca daha
/// yeni kayıtları döner (artan senkron).
class SyncService {
  SyncService(this.client, this.store);

  final WristbandClient client;
  final HealthStore store;

  Future<void> syncAll() async {
    await _steps();
    await _heartRate();
    await _single(HistoryKind.heartRateSingle, MetricType.heartRate);
    await _single(HistoryKind.spo2, MetricType.spo2);
    await _hrv();
    await _temperature();
    await _sleep();
    await workouts();
  }

  /// Yalnızca egzersiz kayıtlarını çeker; egzersiz bitince kullanılır.
  Future<void> workouts() async {
    final rows = await client.fetchHistory(
      HistoryKind.exercise,
      since: store.lastWorkoutStart(),
    );
    store.addWorkouts(rows.map(ExerciseRecord.parse).map(Workout.fromRecord));
  }

  Future<void> _steps() async {
    final rows = await client.fetchHistory(
      HistoryKind.stepDetail,
      since: store.lastTime(MetricType.steps),
    );
    store.addMeasurements([
      for (final r in rows.map(StepDetailRecord.parse)) ...[
        Measurement(MetricType.steps, r.time, r.steps.toDouble()),
        if (r.calories > 0)
          Measurement(MetricType.calories, r.time, r.calories),
        if (r.distanceKm > 0)
          Measurement(MetricType.distance, r.time, r.distanceKm),
      ],
    ]);
  }

  Future<void> _heartRate() async {
    final rows = await client.fetchHistory(
      HistoryKind.heartRateDetail,
      since: store.lastTime(MetricType.heartRate),
    );
    store.addMeasurements([
      for (final r in rows.map(HeartRateDetailRecord.parse))
        if (r.average case final avg?)
          Measurement(MetricType.heartRate, r.time, avg.roundToDouble()),
    ]);
  }

  Future<void> _single(HistoryKind kind, MetricType type) async {
    final rows = await client.fetchHistory(kind, since: store.lastTime(type));
    store.addMeasurements([
      for (final r in rows.map(SingleValueRecord.parse))
        if (r.value > 0) Measurement(type, r.time, r.value.toDouble()),
    ]);
  }

  Future<void> _hrv() async {
    final rows = await client.fetchHistory(
      HistoryKind.hrv,
      since: store.lastTime(MetricType.hrv),
    );
    final out = <Measurement>[];
    for (final r in rows.map(HrvRecord.parse)) {
      void add(MetricType t, int v) {
        if (v > 0) out.add(Measurement(t, r.time, v.toDouble()));
      }

      add(MetricType.hrv, r.hrv);
      add(MetricType.stress, r.stress);
      add(MetricType.respiratoryRate, r.respiratoryRate);
      add(MetricType.systolic, r.systolic);
      add(MetricType.diastolic, r.diastolic);
    }
    store.addMeasurements(out);
  }

  Future<void> _temperature() async {
    final rows = await client.fetchHistory(
      HistoryKind.temperature,
      since: store.lastTime(MetricType.temperature),
    );
    store.addMeasurements(
      rows
          .map(TemperatureRecord.parse)
          .map((r) => Measurement(MetricType.temperature, r.time, r.celsius)),
    );
  }

  Future<void> _sleep() async {
    final rows = await client.fetchHistory(
      HistoryKind.sleep,
      since: store.lastSleepStart(),
    );
    store.addSleep(
      rows
          .map(SleepRecord.parse)
          .where((r) => r.minutes.isNotEmpty)
          .map((r) => SleepSession(r.start, r.minutes)),
    );
  }
}
