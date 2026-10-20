import 'dart:async';

import 'package:flutter/foundation.dart';

import 'health_store.dart';
import 'models.dart';

/// Telefonun sağlık platformu: Android'de Health Connect, iOS'ta Apple Health.
enum HealthPlatformKind { healthConnect, appleHealth }

/// Platforma yazılabilen veri türleri.
///
/// Tansiyon tahmini olduğu için yazılmaz (platformda ölçülmüş değer gibi
/// görünür). EKG kaydını iki platform da üçüncü taraf uygulamadan kabul
/// etmez.
enum ExportType {
  /// Adım, mesafe ve kalori.
  activity,
  heartRate,
  spo2,

  /// Health Connect'te RMSSD, Apple Health'te SDNN istenir; bileklik hangisini
  /// verdiği gerçek cihazda doğrulanacak.
  hrv,
  temperature,
  respiratoryRate,
  sleep,
  workouts,
}

/// Bir türün platformdaki karşılığı ve ölçüm türleri.
extension ExportTypeMetrics on ExportType {
  List<MetricType> get metrics => switch (this) {
    ExportType.activity => const [
      MetricType.steps,
      MetricType.distance,
      MetricType.calories,
    ],
    ExportType.heartRate => const [MetricType.heartRate],
    ExportType.spo2 => const [MetricType.spo2],
    ExportType.hrv => const [MetricType.hrv],
    ExportType.temperature => const [MetricType.temperature],
    ExportType.respiratoryRate => const [MetricType.respiratoryRate],
    ExportType.sleep || ExportType.workouts => const [],
  };
}

/// Platforma erişen ince katman. Gerçek uygulama `health` eklentisiyle
/// yazılacak (izin metinleri AndroidManifest ve Info.plist'e eklenecek);
/// şimdilik [FakeHealthPlatform].
abstract class HealthPlatform {
  HealthPlatformKind get kind;

  /// Platform kurulu ve kullanılabilir mi (Health Connect eski Android'de
  /// ayrıca yüklenmelidir).
  Future<bool> isAvailable();

  /// Sistem izin penceresini açar; kullanıcının izin verdiği türleri döndürür.
  Future<Set<ExportType>> requestWrite(Set<ExportType> types);

  Future<void> writeMeasurements(ExportType type, List<Measurement> items);
  Future<void> writeSleep(List<SleepSession> items);
  Future<void> writeWorkouts(List<Workout> items);
}

/// Bellekte çalışan sahte platform; yazılan kayıtları sayar.
class FakeHealthPlatform implements HealthPlatform {
  FakeHealthPlatform({
    this.kind = HealthPlatformKind.healthConnect,
    this.available = true,
    this.deny = const {},
    this.latency = const Duration(milliseconds: 600),
  });

  @override
  final HealthPlatformKind kind;
  final bool available;

  /// Kullanıcının izin penceresinde kapattığı türler.
  final Set<ExportType> deny;
  final Duration latency;

  /// Tür başına yazılan kayıt sayısı.
  final written = <ExportType, int>{};

  Future<void> _wait() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);

  void _add(ExportType t, int n) => written[t] = (written[t] ?? 0) + n;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Set<ExportType>> requestWrite(Set<ExportType> types) async {
    await _wait();
    return types.difference(deny);
  }

  @override
  Future<void> writeMeasurements(ExportType t, List<Measurement> items) async =>
      _add(t, items.length);

  @override
  Future<void> writeSleep(List<SleepSession> items) async =>
      _add(ExportType.sleep, items.length);

  @override
  Future<void> writeWorkouts(List<Workout> items) async =>
      _add(ExportType.workouts, items.length);
}

/// Bileklik verisini telefonun sağlık platformuna aktarır.
///
/// Bağlıyken depo her değiştiğinde (senkron bitince) yeni kayıtlar kısa bir
/// beklemeden sonra kendiliğinden yazılır. Son 30 günün henüz yazılmamış
/// kayıtları gider; geçmiş senkronla sonradan gelen eski kayıtlar da kaçmaz.
class HealthExportService extends ChangeNotifier {
  HealthExportService(
    this.platform,
    this.store, {
    this.debounce = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    store.addListener(_onStoreChanged);
  }

  final HealthPlatform platform;
  final HealthStore store;
  final Duration debounce;
  final DateTime Function() _now;

  Set<ExportType> _granted = {};
  final _sentMeasurements = <Measurement>{};
  final _sentSleep = <DateTime>{};
  final _sentWorkouts = <DateTime>{};
  DateTime? _lastExport;
  int _lastCount = 0;
  bool _busy = false;
  Timer? _timer;

  /// Kullanıcının izin verdiği ve aktarılan türler.
  Set<ExportType> get granted => Set.unmodifiable(_granted);
  bool get connected => _granted.isNotEmpty;
  DateTime? get lastExport => _lastExport;

  /// Son aktarımda yazılan kayıt sayısı.
  int get lastCount => _lastCount;
  bool get busy => _busy;

  /// İzin ister; en az bir tür verildiyse bağlanır ve hemen aktarır.
  /// Verilen türleri döndürür.
  Future<Set<ExportType>> connect(Set<ExportType> types) async {
    _busy = true;
    notifyListeners();
    final ok = await platform.requestWrite(types);
    _granted = {...ok};
    _busy = false;
    notifyListeners();
    if (connected) await exportNow();
    return ok;
  }

  /// Aktarımı durdurur. Platforma yazılmış kayıtlar orada kalır; kullanıcı
  /// platformun kendi ayarlarından siler.
  void disconnect() {
    _timer?.cancel();
    _granted = {};
    _sentMeasurements.clear();
    _sentSleep.clear();
    _sentWorkouts.clear();
    _lastExport = null;
    _lastCount = 0;
    notifyListeners();
  }

  /// Bir türü aktarımdan çıkarır; izin platformda kalır.
  void remove(ExportType t) {
    _granted.remove(t);
    notifyListeners();
  }

  void _onStoreChanged() {
    if (!connected || _busy) return;
    _timer?.cancel();
    _timer = Timer(debounce, exportNow);
  }

  /// Henüz yazılmamış kayıtları yazar; yazılan sayıyı döndürür.
  Future<int> exportNow() async {
    if (!connected || _busy) return 0;
    _busy = true;
    notifyListeners();
    final to = _now();
    final from = to.subtract(const Duration(days: 30));
    var count = 0;
    for (final t in ExportType.values.where(_granted.contains)) {
      switch (t) {
        case ExportType.sleep:
          final s = store
              .sleepBetween(from, to)
              .where((s) => _sentSleep.add(s.start))
              .toList();
          if (s.isNotEmpty) await platform.writeSleep(s);
          count += s.length;
        case ExportType.workouts:
          final w = store
              .workoutsBetween(from, to)
              .where((w) => _sentWorkouts.add(w.start))
              .toList();
          if (w.isNotEmpty) await platform.writeWorkouts(w);
          count += w.length;
        default:
          final m = [
            for (final metric in t.metrics)
              ...store
                  .measurements(metric, from, to)
                  .where(_sentMeasurements.add),
          ];
          if (m.isNotEmpty) await platform.writeMeasurements(t, m);
          count += m.length;
      }
    }
    _lastExport = to;
    _lastCount = count;
    _busy = false;
    notifyListeners();
    return count;
  }

  @override
  void dispose() {
    _timer?.cancel();
    store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
