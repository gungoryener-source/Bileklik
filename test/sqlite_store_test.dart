import 'dart:io';
import 'dart:math';

import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/sqlite_health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/exercise.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bileklik_db');
    path = '${dir.path}/test.db';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<SqliteHealthStore> open() =>
      SqliteHealthStore.open(factory: databaseFactoryFfi, path: path);

  final t = DateTime(2026, 10, 19, 8, 30);
  final from = DateTime(2026, 10, 1);
  final to = DateTime(2026, 11, 1);

  test('kayıtlar kapatıp açınca aynen geri gelir', () async {
    final a = await open();
    a
      ..addMeasurements([
        Measurement(MetricType.heartRate, t, 72),
        Measurement(MetricType.steps, t, 1200),
        Measurement(MetricType.temperature, t, 36.6),
      ])
      ..addSleep([
        SleepSession(t.subtract(const Duration(hours: 8)), const [
          SleepStage.light,
          SleepStage.deep,
          SleepStage.rem,
          SleepStage.awake,
        ]),
      ])
      ..addWorkouts([
        Workout(
          type: SportType.values.first,
          start: t,
          duration: const Duration(minutes: 31, seconds: 5),
          steps: 4100,
          distanceKm: 3.25,
          calories: 210.5,
          averageHeartRate: 128,
          pace: const Duration(minutes: 9, seconds: 34),
        ),
        Workout(
          type: null,
          start: t.add(const Duration(hours: 2)),
          duration: const Duration(minutes: 10),
          steps: 0,
          distanceKm: 0,
          calories: 40,
          averageHeartRate: 95,
        ),
      ])
      ..addEcg(
        EcgRecording(
          start: t,
          sampleRate: 250,
          samples: const [0, 512, -300, 2047, -2048],
          averageHeartRate: 70,
          minHeartRate: null,
          maxHeartRate: 80,
          sdnn: 42.5,
          beats: 3,
        ),
      );
    await a.close();

    final b = await open();
    expect(b.latest(MetricType.heartRate)!.value, 72);
    expect(b.latest(MetricType.heartRate)!.time, t);
    expect(b.latest(MetricType.temperature)!.value, 36.6);
    expect(b.measurements(MetricType.steps, from, to), hasLength(1));

    final sleep = b.sleepBetween(from, to).single;
    expect(sleep.minutes, [
      SleepStage.light,
      SleepStage.deep,
      SleepStage.rem,
      SleepStage.awake,
    ]);

    final workouts = b.workoutsBetween(from, to);
    expect(workouts, hasLength(2));
    expect(workouts.last.type, SportType.values.first);
    expect(workouts.last.pace, const Duration(minutes: 9, seconds: 34));
    expect(workouts.last.distanceKm, 3.25);
    expect(workouts.first.type, isNull);
    expect(workouts.first.pace, isNull);

    final ecg = b.ecgRecordings().single;
    expect(ecg.samples, [0, 512, -300, 2047, -2048]);
    expect(ecg.minHeartRate, isNull);
    expect(ecg.sdnn, 42.5);
    await b.close();
  });

  test('aynı kayıt tekrar gelirse bir kez saklanır', () async {
    final a = await open();
    final m = Measurement(MetricType.spo2, t, 97);
    a.addMeasurements([m, m]);
    await a.close();

    final b = await open();
    var notified = 0;
    b.addListener(() => notified++);
    b.addMeasurements([m]);
    expect(notified, 0);
    await b.close();

    final c = await open();
    expect(c.measurements(MetricType.spo2, from, to), hasLength(1));
    await c.close();
  });

  test('yeniden açılınca senkron yalnızca yeni kayıtları çeker', () async {
    final store = await open();
    final device = FakeDevice(
      random: Random(5),
      realtimeInterval: const Duration(minutes: 5),
    );
    final c = DeviceController(device, store: store);
    await c.connect();
    await c.disconnect();
    final last = store.lastTime(MetricType.heartRate);
    final count = store
        .measurements(MetricType.heartRate, from, DateTime(2100))
        .length;
    expect(last, isNotNull);
    await store.close();

    // Uygulama yeniden açıldı: depo diskten dolar, artan senkron kaldığı
    // yerden sürer.
    final again = await open();
    expect(again.lastTime(MetricType.heartRate), last);
    expect(
      again.measurements(MetricType.heartRate, from, DateTime(2100)),
      hasLength(count),
    );
    await again.close();
    device.dispose();
  });
}
