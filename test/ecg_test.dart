import 'dart:math';

import 'package:bileklik/data/ecg_analysis.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/fake_ecg.dart';
import 'package:bileklik/device/protocol/ecg.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

void main() {
  group('EKG protokolü', () {
    test('ölçüm komutu: 0x28 04 01 00 süre(LE)', () {
      final p = measurement(MeasureMode.ecg, start: true, seconds: 300);
      expect(p.bytes.sublist(0, 6), hex('28 04 01 00 2C 01'));
      expect(p.bytes.last, Packet.crc(p.bytes.sublist(0, 15)));
    });

    test('ham veri anahtarı: 0x07 01', () {
      expect(ecgRawSwitch(true).bytes.sublist(0, 2), [0x07, 0x01]);
    });

    test('veri paketi 3 baytlık küçük sonlu örneklere ayrılır', () {
      final raw = hex('07 05 39 30 00 3E 30 00 FF FF FF');
      expect(EcgPacket.isData(raw), isTrue);
      final p = EcgPacket.parse(raw);
      expect(p.sequence, 5);
      expect(p.samples, [12345, 12350, -1]);
    });

    test('0x07 komut yanıtı veri sanılmaz', () {
      expect(EcgPacket.isData(ecgRawSwitch(true).bytes), isFalse);
    });
  });

  group('EKG çözümleme', () {
    for (final bpm in [55.0, 72.0, 110.0]) {
      test('$bpm bpm sahte sinyalde nabız bulunur', () {
        final synth = EcgSynth(
          sampleRate: ecgSampleRate,
          heartRate: bpm,
          random: Random(1),
        );
        final samples = [
          for (var i = 0; i < 30 * ecgSampleRate; i++) synth.next(),
        ];
        final s = EcgSummary.analyze(samples, ecgSampleRate);
        expect(s.averageHeartRate, closeTo(bpm, bpm * 0.06));
        expect(s.peaks.length, closeTo(bpm / 2, 3));
        expect(s.sdnn, lessThan(60));
      });
    }

    test('düz sinyalde atım bulunmaz', () {
      final s = EcgSummary.analyze(List.filled(2500, 12000), ecgSampleRate);
      expect(s.averageHeartRate, isNull);
    });
  });

  group('sahte bileklikte EKG', () {
    late FakeDevice device;
    late DeviceController controller;

    setUp(() async {
      device = FakeDevice(
        random: Random(4),
        realtimeInterval: const Duration(seconds: 30),
        ecgPacketInterval: const Duration(microseconds: 500),
      );
      controller = DeviceController(device, store: MemoryHealthStore());
      await controller.connect();
    });

    tearDown(() async {
      await controller.disconnect();
      device.dispose();
    });

    test('30 sn ölçüm kaydedilir ve özetlenir', () async {
      expect(await controller.startEcg(), isTrue);
      expect(controller.ecg, isNotNull);
      for (var i = 0; i < 100 && controller.ecg != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(controller.ecg, isNull);
      final r = controller.lastEcg!;
      expect(r.samples.length, 30 * ecgSampleRate);
      expect(r.averageHeartRate, inInclusiveRange(55, 110));
      expect(controller.store.ecgRecordings(), [r]);
    });

    test('iptal edilen ölçüm kaydedilmez', () async {
      await controller.startEcg();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await controller.cancelEcg();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(controller.ecg, isNull);
      expect(controller.store.ecgRecordings(), isEmpty);
    });
  });
}
