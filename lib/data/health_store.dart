import 'package:flutter/foundation.dart';

import 'models.dart';

/// Ölçümlerin saklandığı yer.
///
/// Telefonda [SqliteHealthStore] (sqlite_health_store.dart), testlerde ve
/// web demosunda [MemoryHealthStore] kullanılır; ekranlar farkı görmez.
abstract class HealthStore extends ChangeNotifier {
  void addMeasurements(Iterable<Measurement> items);
  void addSleep(Iterable<SleepSession> sessions);

  List<Measurement> measurements(MetricType type, DateTime from, DateTime to);
  List<SleepSession> sleepBetween(DateTime from, DateTime to);
  Measurement? latest(MetricType type);

  /// Bir türün en son kaydının zamanı; artan senkron bu zamandan sonrasını ister.
  DateTime? lastTime(MetricType type);
  DateTime? lastSleepStart();

  void addWorkouts(Iterable<Workout> items);

  /// En yenisi önce.
  List<Workout> workoutsBetween(DateTime from, DateTime to);
  DateTime? lastWorkoutStart();

  void addEcg(EcgRecording r);

  /// Elle girilen bir kaydı siler (yanlış girilen kilo gibi).
  void removeMeasurements(Iterable<Measurement> items);

  /// En yenisi önce.
  List<EcgRecording> ecgRecordings();
}

/// Ölçümleri bellekte tutar. Yalnızca yeni kayıtlar [onAdded]'a gider;
/// kalıcı depo bu kancayla diske yazar.
class MemoryHealthStore extends HealthStore {
  final _data = <MetricType, List<Measurement>>{};
  final _seen = <Measurement>{};
  final _sleep = <DateTime, SleepSession>{};
  final _workouts = <DateTime, Workout>{};
  final _ecg = <EcgRecording>[];

  @override
  void addMeasurements(Iterable<Measurement> items) {
    final added = <Measurement>[];
    for (final m in items) {
      // Aynı kayıt iki kez gelirse bir kez saklanır.
      if (!_seen.add(m)) continue;
      _data.putIfAbsent(m.type, () => []).add(m);
      added.add(m);
    }
    if (added.isEmpty) return;
    onAdded(measurements: added);
    for (final list in _data.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    notifyListeners();
  }

  @override
  void addSleep(Iterable<SleepSession> sessions) {
    final added = <SleepSession>[];
    for (final s in sessions) {
      if (_sleep.containsKey(s.start)) continue;
      _sleep[s.start] = s;
      added.add(s);
    }
    if (added.isEmpty) return;
    onAdded(sleep: added);
    notifyListeners();
  }

  @override
  List<Measurement> measurements(MetricType type, DateTime from, DateTime to) =>
      (_data[type] ?? const [])
          .where((m) => !m.time.isBefore(from) && m.time.isBefore(to))
          .toList();

  @override
  List<SleepSession> sleepBetween(DateTime from, DateTime to) =>
      _sleep.values
          .where((s) => s.end.isAfter(from) && s.start.isBefore(to))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  @override
  Measurement? latest(MetricType type) {
    final list = _data[type];
    return list == null || list.isEmpty ? null : list.last;
  }

  @override
  DateTime? lastTime(MetricType type) => latest(type)?.time;

  @override
  DateTime? lastSleepStart() => _sleep.isEmpty
      ? null
      : _sleep.keys.reduce((a, b) => a.isAfter(b) ? a : b);

  @override
  void addWorkouts(Iterable<Workout> items) {
    final added = <Workout>[];
    for (final w in items) {
      if (_workouts.containsKey(w.start)) continue;
      _workouts[w.start] = w;
      added.add(w);
    }
    if (added.isEmpty) return;
    onAdded(workouts: added);
    notifyListeners();
  }

  @override
  List<Workout> workoutsBetween(DateTime from, DateTime to) =>
      _workouts.values
          .where((w) => !w.start.isBefore(from) && w.start.isBefore(to))
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));

  @override
  DateTime? lastWorkoutStart() => _workouts.isEmpty
      ? null
      : _workouts.keys.reduce((a, b) => a.isAfter(b) ? a : b);

  @override
  void addEcg(EcgRecording r) {
    // Aynı anda başlamış ikinci kayıt aynı kayıttır.
    if (_ecg.any((e) => e.start == r.start)) return;
    _ecg.add(r);
    onAdded(ecg: [r]);
    notifyListeners();
  }

  @override
  void removeMeasurements(Iterable<Measurement> items) {
    final removed = <Measurement>[];
    for (final m in items) {
      if (!_seen.remove(m)) continue;
      _data[m.type]?.remove(m);
      removed.add(m);
    }
    if (removed.isEmpty) return;
    onRemoved(removed);
    notifyListeners();
  }

  @override
  List<EcgRecording> ecgRecordings() =>
      [..._ecg]..sort((a, b) => b.start.compareTo(a.start));

  /// Belleğe yeni giren kayıtlar; tekrar gelenler buraya düşmez.
  @protected
  void onAdded({
    List<Measurement> measurements = const [],
    List<SleepSession> sleep = const [],
    List<Workout> workouts = const [],
    List<EcgRecording> ecg = const [],
  }) {}

  /// Bellekten silinen ölçümler; kalıcı depo diskten de siler.
  @protected
  void onRemoved(List<Measurement> measurements) {}
}
