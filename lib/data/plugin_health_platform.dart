import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../device/protocol/exercise.dart';
import '../device/protocol/history.dart';
import 'health_platform.dart';
import 'models.dart';

/// Health Connect (Android) ve Apple Health'e (iOS) `health` eklentisiyle
/// yazan gerçek platform.
///
/// Uygulama yalnızca yazar, okumaz. Birim farkları: Apple Health yüzdeyi
/// 0–1 arası kesir, Health Connect 0–100 ister.
class PluginHealthPlatform implements HealthPlatform {
  PluginHealthPlatform({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static bool get _ios => Platform.isIOS;

  @override
  HealthPlatformKind get kind => _ios
      ? HealthPlatformKind.appleHealth
      : HealthPlatformKind.healthConnect;

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _configure();
      // iOS'ta her zaman true; Android'de Health Connect kurulu mu.
      return await _health.isHealthConnectAvailable();
    } catch (e) {
      debugPrint('Sağlık platformu denetlenemedi: $e');
      return false;
    }
  }

  /// Bir türün platformda istediği izinler.
  static List<HealthDataType> typesOf(ExportType t, {required bool ios}) =>
      switch (t) {
        ExportType.activity => [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          ios
              ? HealthDataType.DISTANCE_WALKING_RUNNING
              : HealthDataType.DISTANCE_DELTA,
        ],
        ExportType.heartRate => [HealthDataType.HEART_RATE],
        ExportType.spo2 => [HealthDataType.BLOOD_OXYGEN],
        ExportType.hrv => [
          ios
              ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
              : HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        ],
        ExportType.temperature => [HealthDataType.BODY_TEMPERATURE],
        ExportType.respiratoryRate => [HealthDataType.RESPIRATORY_RATE],
        // Health Connect'te VKİ kaydı yok; yalnızca iOS'a yazılır.
        ExportType.body => [
          HealthDataType.WEIGHT,
          HealthDataType.BODY_FAT_PERCENTAGE,
          if (ios) HealthDataType.BODY_MASS_INDEX,
        ],
        ExportType.sleep =>
          ios
              ? const [
                  HealthDataType.SLEEP_DEEP,
                  HealthDataType.SLEEP_LIGHT,
                  HealthDataType.SLEEP_REM,
                  HealthDataType.SLEEP_AWAKE,
                ]
              : const [HealthDataType.SLEEP_SESSION],
        ExportType.workouts => const [HealthDataType.WORKOUT],
      };

  @override
  Future<Set<ExportType>> requestWrite(Set<ExportType> types) async {
    await _configure();
    final ordered = ExportType.values.where(types.contains).toList();
    final all = [for (final t in ordered) ...typesOf(t, ios: _ios)];
    if (all.isEmpty) return {};
    final ok = await _health.requestAuthorization(
      all,
      permissions: List.filled(all.length, HealthDataAccess.WRITE),
    );
    final granted = <ExportType>{};
    for (final t in ordered) {
      final list = typesOf(t, ios: _ios);
      final has = await _health.hasPermissions(
        list,
        permissions: List.filled(list.length, HealthDataAccess.WRITE),
      );
      // iOS bazı durumlarda izni bildirmez (null); o zaman genel sonuca bakılır.
      if (has ?? ok) granted.add(t);
    }
    return granted;
  }

  @override
  Future<void> writeMeasurements(ExportType t, List<Measurement> items) async {
    await _configure();
    for (final m in items) {
      await _writeOne(m);
    }
  }

  Future<void> _writeOne(Measurement m) async {
    final at = m.time;
    switch (m.type) {
      // Bileklik adımı 10 dakikalık kayıtlarla verir; kaydın zamanı aralığın
      // başı sayılır (gerçek cihazda doğrulanacak).
      case MetricType.steps:
        await _write(HealthDataType.STEPS, m.value, at, _tenMinutes(at));
      case MetricType.calories:
        await _write(
          HealthDataType.ACTIVE_ENERGY_BURNED,
          m.value,
          at,
          _tenMinutes(at),
        );
      case MetricType.distance:
        await _write(
          _ios
              ? HealthDataType.DISTANCE_WALKING_RUNNING
              : HealthDataType.DISTANCE_DELTA,
          m.value * 1000,
          at,
          _tenMinutes(at),
        );
      case MetricType.heartRate:
        await _write(HealthDataType.HEART_RATE, m.value, at);
      case MetricType.spo2:
        if (_ios) {
          await _write(HealthDataType.BLOOD_OXYGEN, m.value / 100, at);
        } else {
          await _health.writeBloodOxygen(saturation: m.value, startTime: at);
        }
      case MetricType.hrv:
        await _write(
          _ios
              ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
              : HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
          m.value,
          at,
        );
      case MetricType.temperature:
        await _write(HealthDataType.BODY_TEMPERATURE, m.value, at);
      case MetricType.respiratoryRate:
        await _write(HealthDataType.RESPIRATORY_RATE, m.value, at);
      case MetricType.weight:
        await _write(
          HealthDataType.WEIGHT,
          m.value,
          at,
          null,
          RecordingMethod.manual,
        );
      case MetricType.bodyFat:
        await _write(
          HealthDataType.BODY_FAT_PERCENTAGE,
          _ios ? m.value / 100 : m.value,
          at,
          null,
          RecordingMethod.manual,
        );
      case MetricType.bmi:
        if (_ios) {
          await _write(
            HealthDataType.BODY_MASS_INDEX,
            m.value,
            at,
            null,
            RecordingMethod.manual,
          );
        }
      // Platforma yazılmayan türler (ExportType bunları istemez).
      case MetricType.stress ||
          MetricType.systolic ||
          MetricType.diastolic ||
          MetricType.muscleMass:
        return;
    }
  }

  static DateTime _tenMinutes(DateTime t) =>
      t.add(const Duration(minutes: 10));

  Future<void> _write(
    HealthDataType type,
    double value,
    DateTime start, [
    DateTime? end,
    RecordingMethod method = RecordingMethod.automatic,
  ]) async {
    final ok = await _health.writeHealthData(
      value: value,
      type: type,
      startTime: start,
      endTime: end ?? start,
      recordingMethod: method,
    );
    if (!ok) throw StateError('${type.name} yazılamadı');
  }

  @override
  Future<void> writeSleep(List<SleepSession> items) async {
    await _configure();
    for (final s in items) {
      if (s.minutes.isEmpty) continue;
      if (!_ios) {
        // Eklenti Health Connect'te her evreyi ayrı uyku oturumu olarak yazar;
        // üst üste binen oturumlar olmasın diye tek oturum yazılır, evreler
        // aktarılmaz.
        await _write(
          HealthDataType.SLEEP_SESSION,
          s.minutes.length.toDouble(),
          s.start,
          s.end,
        );
        continue;
      }
      // Apple Health evreleri ayrı örnekler olarak tutar: aynı evrenin art
      // arda gelen dakikaları tek örnek olur.
      var runStart = 0;
      for (var i = 1; i <= s.minutes.length; i++) {
        if (i < s.minutes.length && s.minutes[i] == s.minutes[runStart]) {
          continue;
        }
        await _write(
          _sleepType(s.minutes[runStart]),
          (i - runStart).toDouble(),
          s.start.add(Duration(minutes: runStart)),
          s.start.add(Duration(minutes: i)),
        );
        runStart = i;
      }
    }
  }

  static HealthDataType _sleepType(SleepStage s) => switch (s) {
    SleepStage.deep => HealthDataType.SLEEP_DEEP,
    SleepStage.light => HealthDataType.SLEEP_LIGHT,
    SleepStage.rem => HealthDataType.SLEEP_REM,
    SleepStage.awake => HealthDataType.SLEEP_AWAKE,
  };

  @override
  Future<void> writeWorkouts(List<Workout> items) async {
    await _configure();
    for (final w in items) {
      final ok = await _health.writeWorkoutData(
        activityType: activityOf(w.type),
        start: w.start,
        end: w.end,
        totalEnergyBurned: w.calories > 0 ? w.calories.round() : null,
        totalDistance: w.distanceKm > 0 ? (w.distanceKm * 1000).round() : null,
      );
      if (!ok) throw StateError('Egzersiz yazılamadı');
    }
  }

  /// Bilekliğin spor türünün iki platformda da bulunan karşılığı; yoksa OTHER.
  static HealthWorkoutActivityType activityOf(SportType? t) => switch (t) {
    SportType.run => HealthWorkoutActivityType.RUNNING,
    SportType.cycling => HealthWorkoutActivityType.BIKING,
    SportType.badminton => HealthWorkoutActivityType.BADMINTON,
    SportType.football => HealthWorkoutActivityType.SOCCER,
    SportType.tennis => HealthWorkoutActivityType.TENNIS,
    SportType.yoga => HealthWorkoutActivityType.YOGA,
    SportType.dance => HealthWorkoutActivityType.CARDIO_DANCE,
    SportType.basketball => HealthWorkoutActivityType.BASKETBALL,
    SportType.walk => HealthWorkoutActivityType.WALKING,
    SportType.cricket => HealthWorkoutActivityType.CRICKET,
    SportType.hiking => HealthWorkoutActivityType.HIKING,
    SportType.pingPong => HealthWorkoutActivityType.TABLE_TENNIS,
    SportType.ropeJump => HealthWorkoutActivityType.JUMP_ROPE,
    SportType.volleyball => HealthWorkoutActivityType.VOLLEYBALL,
    SportType.meditation ||
    SportType.workout ||
    SportType.aerobics ||
    SportType.sitUps ||
    null => HealthWorkoutActivityType.OTHER,
  };
}
