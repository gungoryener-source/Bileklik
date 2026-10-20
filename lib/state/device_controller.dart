import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/ecg_analysis.dart';
import '../data/health_store.dart';
import '../data/sync_service.dart';
import '../data/models.dart';
import '../device/protocol/commands.dart';
import '../device/protocol/ecg.dart';
import '../device/protocol/exercise.dart';
import '../device/transport.dart';
import '../device/wristband_client.dart';

/// Kullanıcıya gösterilen hata türleri.
enum DeviceIssue {
  /// Bileklik başka bir egzersizde ya da ölçümde.
  busy,

  /// EKG sırasında sinyal gelmedi.
  noEcgSignal,

  /// Elle nabız/SpO2 ölçümünde değer gelmedi.
  noSpotSignal,

  /// Bağlantı ya da komut hatası; ayrıntı `error` içinde.
  failed,
}

/// Ekranların bileklik durumunu dinlediği tek nokta.
///
/// Hangi cihaz katmanının (sahte ya da gerçek) kullanılacağı dışarıdan verilir.
class DeviceController extends ChangeNotifier {
  DeviceController(this._transport, {HealthStore? store})
    : _client = WristbandClient(_transport),
      store = store ?? MemoryHealthStore() {
    _sync = SyncService(_client, this.store);
    _stateSub = _transport.state.listen((s) {
      connection = s;
      notifyListeners();
    });
    _realtimeSub = _client.realtime.listen((d) {
      live = d;
      lastUpdate = DateTime.now();
      if (spot case final s?) {
        _onSpot(s, d);
      } else {
        notifyListeners();
      }
    });
    _exerciseSub = _client.exerciseEvents.listen(_onExercise);
    _ecgSub = _client.ecg.listen(_onEcg);
  }

  final DeviceTransport _transport;
  final WristbandClient _client;
  late final SyncService _sync;

  /// Bileklikten çekilen geçmiş ölçümler.
  final HealthStore store;
  late final StreamSubscription<DeviceConnectionState> _stateSub;
  late final StreamSubscription<RealtimeData> _realtimeSub;
  late final StreamSubscription<ExerciseEvent> _exerciseSub;
  late final StreamSubscription<EcgPacket> _ecgSub;

  DeviceConnectionState connection = DeviceConnectionState.disconnected;
  RealtimeData? live;
  BatteryStatus? battery;
  PersonalInfo? profile;
  DateTime? lastUpdate;

  /// Son hatanın teknik ayrıntısı (kayıt ve hata ayıklama için).
  String? get error => _error;
  String? _error;
  set error(String? v) {
    _error = v;
    issue = v == null ? null : DeviceIssue.failed;
  }

  /// Son hatanın türü; ekran bunu kullanıcının dilinde gösterir.
  DeviceIssue? issue;
  bool syncing = false;
  DateTime? lastSync;

  /// Devam eden egzersiz; yoksa null.
  ActiveExercise? exercise;

  /// En son biten egzersiz; özet ekranı bunu gösterir.
  Workout? lastWorkout;

  /// Süren EKG ölçümü; yoksa null.
  EcgSession? ecg;

  /// En son tamamlanan EKG kaydı.
  EcgRecording? lastEcg;

  String get deviceName => _transport.name;
  bool get isConnected => connection == DeviceConnectionState.connected;

  Future<void> connect() async {
    error = null;
    try {
      await _transport.connect();
      await _client.syncTime(DateTime.now());
      battery = await _client.getBattery();
      profile = await _client.getPersonalInfo();
      await _client.startRealtime();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
    if (isConnected) await sync();
  }

  /// Bileklikteki geçmiş verileri depoya çeker (yalnızca yeni kayıtlar).
  Future<void> sync() async {
    if (!isConnected || syncing) return;
    syncing = true;
    error = null;
    notifyListeners();
    try {
      await _sync.syncAll();
      lastSync = DateTime.now();
    } catch (e) {
      error = e.toString();
    }
    syncing = false;
    notifyListeners();
  }

  /// Arama sürüyor mu.
  bool scanning = false;

  /// Son aramada bulunan bileklikler.
  List<DiscoveredDevice> found = const [];

  /// Yakındaki bileklikleri arar.
  Future<List<DiscoveredDevice>> scan() async {
    if (scanning) return found;
    scanning = true;
    error = null;
    notifyListeners();
    try {
      found = await _transport.scan();
    } catch (e) {
      error = e.toString();
      found = const [];
    }
    scanning = false;
    notifyListeners();
    return found;
  }

  /// Aramada seçilen bilekliğe bağlanır. Sahte cihazda tek bileklik var;
  /// gerçek BLE katmanı adresi kullanacak (bileklik gelince).
  Future<void> connectTo(DiscoveredDevice device) => connect();

  /// Süren elle nabız/SpO2 ölçümü; yoksa null.
  SpotSession? spot;

  /// En son tamamlanan elle ölçüm.
  Measurement? lastSpot;

  Future<void> disconnect() async {
    spot?.watchdog?.cancel();
    await _transport.disconnect();
    live = null;
    exercise = null;
    ecg = null;
    spot = null;
    notifyListeners();
  }

  Future<void> saveProfile(PersonalInfo info) async {
    error = null;
    try {
      await _client.setPersonalInfo(info);
      profile = await _client.getPersonalInfo();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  /// Egzersizi başlatır. Bileklik başka bir modda ise false döner.
  Future<bool> startExercise(SportType type) async {
    error = null;
    try {
      final r = await _client.controlExercise(ExerciseAction.start, type);
      if (!r.ok) {
        error = 'device busy';
        issue = DeviceIssue.busy;
      } else {
        exercise = ActiveExercise(type, r.startedAt ?? DateTime.now());
      }
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
    return exercise != null;
  }

  Future<void> pauseExercise() => _setPaused(true);
  Future<void> resumeExercise() => _setPaused(false);

  Future<void> _setPaused(bool paused) async {
    final ex = exercise;
    if (ex == null) return;
    try {
      await _client.controlExercise(
        paused ? ExerciseAction.pause : ExerciseAction.resume,
        ex.type,
      );
      ex.paused = paused;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  /// Kullanıcı hareketsizlik uyarısında "devam et" dedi.
  void dismissExercisePrompt() {
    exercise?.prompt = null;
    notifyListeners();
  }

  Future<void> stopExercise() async {
    final ex = exercise;
    if (ex == null) return;
    try {
      await _client.controlExercise(ExerciseAction.end, ex.type);
    } catch (e) {
      error = e.toString();
    }
    await _finishExercise(ex);
  }

  Future<void> _finishExercise(ActiveExercise ex) async {
    exercise = null;
    lastWorkout = null;
    notifyListeners();
    // Bileklik biten egzersizi 0x5C geçmişine yazar; oradan çekiyoruz.
    if (!syncing) {
      try {
        await _sync.workouts();
      } catch (e) {
        error = e.toString();
      }
    }
    lastWorkout = store
        .workoutsBetween(
          ex.startedAt.subtract(const Duration(minutes: 1)),
          DateTime.now().add(const Duration(days: 1)),
        )
        .firstOrNull;
    notifyListeners();
  }

  void _onExercise(ExerciseEvent e) {
    final ex = exercise;
    if (ex == null) return;
    switch (e) {
      case ExerciseLive():
        ex.live = e;
        if (e.heartRate > 0) ex.heartRates.add(e.heartRate);
      case ExerciseInactive():
        ex.prompt = e;
      case ExerciseEnded():
        ex.endedByDevice = true;
        unawaited(_finishExercise(ex));
        return;
    }
    notifyListeners();
  }

  /// EKG ölçümünü başlatır. Bileklik [seconds] boyunca ham veri gönderir.
  Future<bool> startEcg({int seconds = 30}) async {
    if (ecg != null) return true;
    error = null;
    lastEcg = null;
    final session = EcgSession(DateTime.now(), seconds);
    ecg = session;
    notifyListeners();
    try {
      await _client.startEcg(seconds: seconds);
      // Paketler gelmezse ölçüm süresi ve 10 sn pay sonunda bitir.
      session.watchdog = Timer(Duration(seconds: seconds + 10), () {
        if (ecg == session) _completeEcg(session);
      });
    } catch (e) {
      error = e.toString();
      ecg = null;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> cancelEcg() async {
    final session = ecg;
    if (session == null) return;
    session.watchdog?.cancel();
    ecg = null;
    notifyListeners();
    try {
      await _client.stopEcg();
    } catch (_) {}
  }

  void _onEcg(EcgPacket p) {
    final session = ecg;
    if (session == null) return;
    session.samples.addAll(p.samples);
    if (session.samples.length >= session.target) {
      _completeEcg(session);
    } else {
      notifyListeners();
    }
  }

  Future<void> _completeEcg(EcgSession session) async {
    session.watchdog?.cancel();
    ecg = null;
    final samples = session.samples.length > session.target
        ? session.samples.sublist(0, session.target)
        : session.samples;
    if (samples.length >= ecgSampleRate * 5) {
      final s = EcgSummary.analyze(samples, ecgSampleRate);
      final r = EcgRecording(
        start: session.start,
        sampleRate: ecgSampleRate,
        samples: List.unmodifiable(samples),
        averageHeartRate: s.averageHeartRate,
        minHeartRate: s.minHeartRate,
        maxHeartRate: s.maxHeartRate,
        sdnn: s.sdnn,
        beats: s.peaks.length,
      );
      store.addEcg(r);
      lastEcg = r;
    } else {
      error = 'no ECG signal';
      issue = DeviceIssue.noEcgSignal;
    }
    notifyListeners();
    try {
      await _client.stopEcg();
    } catch (_) {}
  }

  /// Elle nabız ya da SpO2 ölçümü başlatır ([type] heartRate ya da spo2).
  /// Bileklik [seconds] boyunca saniyede bir değer gönderir; EKG ya da
  /// egzersiz sürüyorsa başlamaz.
  Future<bool> startSpot(MetricType type, {int seconds = 30}) async {
    if (spot != null) return true;
    error = null;
    if (ecg != null || exercise != null) {
      issue = DeviceIssue.busy;
      notifyListeners();
      return false;
    }
    lastSpot = null;
    final session = SpotSession(type, DateTime.now(), seconds);
    spot = session;
    notifyListeners();
    try {
      await _client.startSpot(session.mode, seconds: seconds);
      // Bitiş paketi PDF'te yok; süre ve 10 sn pay sonunda kendimiz bitiririz
      // (gerçek cihazda doğrulanacak).
      session.watchdog = Timer(Duration(seconds: seconds + 10), () {
        if (spot == session) _completeSpot(session);
      });
    } catch (e) {
      error = e.toString();
      spot = null;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> cancelSpot() async {
    final session = spot;
    if (session == null) return;
    session.watchdog?.cancel();
    spot = null;
    notifyListeners();
    try {
      await _client.stopSpot(session.mode);
    } catch (_) {}
  }

  void _onSpot(SpotSession session, RealtimeData d) {
    session.ticks++;
    final v = session.type == MetricType.spo2 ? d.spo2 : d.heartRate;
    if (v > 0) session.readings.add(v);
    if (session.ticks >= session.seconds) {
      _completeSpot(session);
    } else {
      notifyListeners();
    }
  }

  Future<void> _completeSpot(SpotSession session) async {
    session.watchdog?.cancel();
    spot = null;
    final value = session.result;
    if (value != null) {
      final m = Measurement(session.type, DateTime.now(), value.toDouble());
      store.addMeasurements([m]);
      lastSpot = m;
    } else {
      error = 'no reading';
      issue = DeviceIssue.noSpotSignal;
    }
    notifyListeners();
    try {
      await _client.stopSpot(session.mode);
    } catch (_) {}
  }

  @override
  void dispose() {
    spot?.watchdog?.cancel();
    ecg?.watchdog?.cancel();
    _ecgSub.cancel();
    _stateSub.cancel();
    _realtimeSub.cancel();
    _exerciseSub.cancel();
    _client.dispose();
    super.dispose();
  }
}

/// Bileklikte süren egzersizin uygulamadaki görünümü.
class ActiveExercise {
  ActiveExercise(this.type, this.startedAt);

  final SportType type;
  final DateTime startedAt;
  bool paused = false;
  bool endedByDevice = false;
  ExerciseLive? live;
  final heartRates = <int>[];

  /// Bilekliğin "uzun süredir hareketsizsiniz" uyarısı; kullanıcı yanıtlayınca null olur.
  ExerciseInactive? prompt;

  Duration get elapsed => Duration(seconds: live?.durationSeconds ?? 0);

  int? get averageHeartRate => heartRates.isEmpty
      ? null
      : (heartRates.reduce((a, b) => a + b) / heartRates.length).round();
}

/// Süren EKG ölçümü.
class EcgSession {
  EcgSession(this.start, this.seconds);

  final DateTime start;
  final int seconds;
  final samples = <int>[];
  Timer? watchdog;

  int get target => seconds * ecgSampleRate;
  double get progress => (samples.length / target).clamp(0, 1);
  Duration get remaining =>
      Duration(seconds: seconds - samples.length ~/ ecgSampleRate);
}

/// Süren elle nabız ya da SpO2 ölçümü. Bileklik saniyede bir anlık veri
/// gönderir; her paket bir saniye sayılır.
class SpotSession {
  SpotSession(this.type, this.start, this.seconds);

  final MetricType type;
  final DateTime start;
  final int seconds;
  int ticks = 0;

  /// Sıfır olmayan okumalar; sensör oturana kadar 0 gelir.
  final readings = <int>[];
  Timer? watchdog;

  MeasureMode get mode =>
      type == MetricType.spo2 ? MeasureMode.spo2 : MeasureMode.heartRate;

  double get progress => (ticks / seconds).clamp(0, 1);
  Duration get remaining => Duration(seconds: max(0, seconds - ticks));

  /// En son okunan değer; ekranda canlı gösterilir.
  int? get latest => readings.isEmpty ? null : readings.last;

  /// Son 10 okumanın ortancası; tek tük sıçramalar sonucu bozmaz.
  int? get result {
    if (readings.isEmpty) return null;
    final last = readings.sublist(max(0, readings.length - 10))..sort();
    return last[last.length ~/ 2];
  }
}
