import 'dart:async';

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
      notifyListeners();
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
  String? error;
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

  Future<void> disconnect() async {
    await _transport.disconnect();
    live = null;
    exercise = null;
    ecg = null;
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
        error = 'Bileklik şu an başka bir egzersizde ya da ölçümde.';
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
      error = 'EKG verisi alınamadı. Bilekliği takıp parmağınızı elektroda dokundurun.';
    }
    notifyListeners();
    try {
      await _client.stopEcg();
    } catch (_) {}
  }

  @override
  void dispose() {
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
