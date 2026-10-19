import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/fake_history.dart';
import 'package:bileklik/device/protocol/exercise.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/device/wristband_client.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

void main() {
  group('egzersiz protokolü', () {
    test('PDF örneği: koşu başlatma komutu', () {
      expect(
        exerciseControl(ExerciseAction.start, SportType.run).bytes,
        hex('19 01 00 00 00 00 00 00 00 00 00 00 00 00 00 1A'),
      );
    });

    test('PDF örneği: başlatma yanıtı', () {
      final r = ExerciseControlResult.parse(
        Packet.parse(hex('19 01 24 09 03 15 51 47 00 00 00 00 00 00 00 F7')),
      );
      expect(r.ok, isTrue);
      expect(r.startedAt, DateTime(2024, 9, 3, 15, 51, 47));
    });

    test('PDF örneği: 0x5C egzersiz kaydı', () {
      final rec = ExerciseRecord.parse(
        hex(
          '5C 00 00 24 09 03 10 36 47 00 8A 43 00 75 00 00 00 '
          '54 2A 0E 40 80 E3 6B 3D',
        ),
      );
      expect(rec.start, DateTime(2024, 9, 3, 10, 36, 47));
      expect(rec.type, SportType.run);
      expect(rec.heartRate, 138);
      expect(rec.durationSeconds, 67);
      expect(rec.steps, 117);
      expect(rec.calories, closeTo(2.22, 0.01));
      expect(rec.distanceKm, closeTo(0.0576, 0.001));
    });

    test('0x18 canlı veri ve uyarılar ayrılır', () {
      final live = List<int>.filled(21, 0)
        ..setAll(0, [0x18, 120, 0x64, 0, 0, 0])
        ..setAll(6, FakeHistory.float32LE(3.5))
        ..setAll(10, [90, 0, 0, 0])
        ..setAll(14, FakeHistory.float32LE(0.25));
      final e = ExerciseEvent.parse(live) as ExerciseLive;
      expect(e.heartRate, 120);
      expect(e.steps, 100);
      expect(e.calories, closeTo(3.5, 1e-6));
      expect(e.durationSeconds, 90);
      expect(e.distanceKm, closeTo(0.25, 1e-6));

      expect(
        ExerciseEvent.parse(Packet.build(0x18, [0xAA, 2]).bytes),
        isA<ExerciseInactive>().having((e) => e.minutes, 'dakika', 20),
      );
      expect(
        ExerciseEvent.parse(Packet.build(0x18, [0xFF, 2]).bytes),
        isA<ExerciseEnded>().having((e) => e.autoDetected, 'otomatik', true),
      );
    });
  });

  group('sahte bileklikte egzersiz', () {
    late FakeDevice device;
    late DeviceController controller;

    setUp(() async {
      device = FakeDevice(
        random: Random(2),
        realtimeInterval: const Duration(seconds: 30),
        exerciseInterval: const Duration(milliseconds: 5),
      );
      controller = DeviceController(device, store: MemoryHealthStore());
      await controller.connect();
    });

    tearDown(() async {
      await controller.disconnect();
      device.dispose();
    });

    test('geçmiş egzersizler senkronla gelir', () async {
      final now = DateTime.now();
      final ws = controller.store.workoutsBetween(
        now.subtract(const Duration(days: 8)),
        now,
      );
      expect(ws, isNotEmpty);
      for (final w in ws) {
        expect(w.type, isNotNull);
        expect(w.duration.inMinutes, inInclusiveRange(20, 50));
      }
    });

    test('başlat, canlı veri al, bitir, özet kaydedilir', () async {
      expect(await controller.startExercise(SportType.run), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final ex = controller.exercise!;
      expect(ex.live, isNotNull);
      expect(ex.elapsed.inSeconds, greaterThan(10));
      expect(ex.live!.distanceKm, greaterThan(0));

      // İkinci başlatma reddedilir.
      final client = WristbandClient(device);
      final second = await client.controlExercise(
        ExerciseAction.start,
        SportType.walk,
      );
      expect(second.ok, isFalse);
      await client.dispose();

      await controller.pauseExercise();
      final paused = ex.elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.exercise!.elapsed, paused);
      await controller.resumeExercise();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.stopExercise();
      expect(controller.exercise, isNull);
      final w = controller.lastWorkout!;
      expect(w.type, SportType.run);
      expect(w.duration.inSeconds, greaterThan(10));
      expect(w.steps, greaterThan(0));
      expect(w.averageHeartRate, greaterThan(60));
    });

    test('hareketsizlik uyarısı ve otomatik bitiş', () async {
      await controller.startExercise(SportType.walk);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      device.simulateInactivity(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.exercise!.prompt?.minutes, 10);
      controller.dismissExercisePrompt();
      expect(controller.exercise!.prompt, isNull);

      device.simulateAutoEnd();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.exercise, isNull);
      expect(controller.lastWorkout?.type, SportType.walk);
    });

    test('egzersiz geçmiş türü 0x5C kayıt uzunluğu', () {
      expect(HistoryKind.exercise.recordLength, ExerciseRecord.length);
    });
  });
}
