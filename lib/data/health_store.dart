import 'package:flutter/foundation.dart';

import 'models.dart';

/// Ölçümlerin saklandığı yer.
///
/// Şimdilik bellekte tutulur; kalıcı veritabanı (SQLite) bu arayüzün
/// arkasına eklenecek, ekranlar değişmeyecek.
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
}

class MemoryHealthStore extends HealthStore {
  final _data = <MetricType, List<Measurement>>{};
  final _seen = <Measurement>{};
  final _sleep = <DateTime, SleepSession>{};
  final _workouts = <DateTime, Workout>{};

  @override
  void addMeasurements(Iterable<Measurement> items) {
    var changed = false;
    for (final m in items) {
      // Aynı kayıt iki kez gelirse bir kez saklanır.
      if (!_seen.add(m)) continue;
      _data.putIfAbsent(m.type, () => []).add(m);
      changed = true;
    }
    if (!changed) return;
    for (final list in _data.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    notifyListeners();
  }

  @override
  void addSleep(Iterable<SleepSession> sessions) {
    var changed = false;
    for (final s in sessions) {
      if (_sleep.containsKey(s.start)) continue;
      _sleep[s.start] = s;
      changed = true;
    }
    if (changed) notifyListeners();
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
    var changed = false;
    for (final w in items) {
      if (_workouts.containsKey(w.start)) continue;
      _workouts[w.start] = w;
      changed = true;
    }
    if (changed) notifyListeners();
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
}
