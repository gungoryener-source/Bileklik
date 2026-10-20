import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/commands.dart';
import 'package:bileklik/device/protocol/ecg.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/device/wristband_client.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/spot_measure_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

FakeDevice _device({int tickMs = 10}) => FakeDevice(
  random: Random(4),
  realtimeInterval: const Duration(seconds: 30),
  spotInterval: Duration(milliseconds: tickMs),
);

void main() {
  group('protokol', () {
    test('SpO2 ölçümü: 0x28 03 01 00 1E 00 (PDF biçimi)', () {
      final p = measurement(MeasureMode.spo2, start: true, seconds: 30);
      expect(p.bytes.sublist(0, 6), hex('28 03 01 00 1E 00'));
      expect(p.bytes.last, Packet.crc(p.bytes.sublist(0, 15)));
    });

    test('nabız ölçümünü durdurma: 0x28 02 00', () {
      final p = measurement(MeasureMode.heartRate, start: false);
      expect(p.bytes.sublist(0, 3), hex('28 02 00'));
    });

    test(
      'sahte bileklik SpO2 değerini yalnızca ölçüm sürerken gönderir',
      () async {
        final device = _device();
        final client = WristbandClient(device);
        await device.connect();
        final packets = <RealtimeData>[];
        final sub = client.realtime.listen(packets.add);
        await client.startRealtime();
        await client.startSpot(MeasureMode.spo2);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await sub.cancel();
        // İlk paket ölçümden önce, sonraki birkaçı sensör otururken 0.
        expect(packets.first.spo2, 0);
        expect(
          packets.take(FakeDevice.spotWarmup).every((p) => p.spo2 == 0),
          isTrue,
        );
        final values = packets.map((p) => p.spo2).where((v) => v > 0);
        expect(values, isNotEmpty);
        expect(values.every((v) => v >= 90 && v <= 100), isTrue);
        await device.disconnect();
        await client.dispose();
        device.dispose();
      },
    );
  });

  group('denetleyici', () {
    for (final type in [MetricType.heartRate, MetricType.spo2]) {
      test('${type.name} ölçülür ve depoya yazılır', () async {
        final device = _device();
        final store = MemoryHealthStore();
        final c = DeviceController(device, store: store);
        await c.connect();
        final before = store.latest(type)?.time;

        expect(await c.startSpot(type), isTrue);
        expect(c.spot, isNotNull);
        while (c.spot != null) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        final m = c.lastSpot!;
        expect(m.type, type);
        expect(store.latest(type), m);
        expect(m.time, isNot(before));
        if (type == MetricType.spo2) {
          expect(m.value, inInclusiveRange(90, 100));
        } else {
          expect(m.value, inInclusiveRange(40, 200));
        }
        await c.disconnect();
        device.dispose();
      });
    }

    test('EKG sürerken başlamaz', () async {
      final device = _device();
      final c = DeviceController(device, store: MemoryHealthStore());
      await c.connect();
      await c.startEcg();
      expect(await c.startSpot(MetricType.heartRate), isFalse);
      expect(c.issue, DeviceIssue.busy);
      await c.cancelEcg();
      await c.disconnect();
      device.dispose();
    });

    test('değer gelmezse sonuç yazılmaz, neden bildirilir', () {
      final s = SpotSession(MetricType.spo2, DateTime.now(), 30);
      expect(s.result, isNull);
      s.readings.addAll([97, 98, 60, 97, 99]);
      // Tek bir sıçrama ortancayı değiştirmez.
      expect(s.result, 97);
    });
  });

  testWidgets('Ana Sayfa\'dan SpO2 ölçülür, sonuç gösterilir', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = _device(tickMs: 60);
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.runAsync(() => controller.connect());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Şimdi ölç'));
    await tester.pumpAndSettle();
    expect(find.text('Ne ölçmek istersiniz?'), findsOneWidget);
    await tester.tap(find.text('Kan oksijeni (SpO2)'));
    // Sahte bileklik zamanlayıcıları test saatinde ilerler.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ölçülüyor…'), findsOneWidget);
    expect(controller.spot, isNotNull);

    await tester.pumpAndSettle(const Duration(milliseconds: 60));
    expect(controller.spot, isNull);
    final m = controller.lastSpot!;
    expect(find.text('%${m.value.round()}'), findsOneWidget);
    expect(find.textContaining('ölçümü kaydedildi'), findsOneWidget);

    await tester.tap(find.text('Bitti'));
    await tester.pumpAndSettle();
    expect(find.byType(SpotMeasureScreen), findsNothing);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });

  testWidgets('bağlı değilken uyarı verir', (tester) async {
    final device = _device();
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Şimdi ölç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nabız'));
    await tester.pumpAndSettle();
    expect(find.textContaining('bilekliği bağlayın'), findsOneWidget);
    expect(find.byType(SpotMeasureScreen), findsNothing);
    device.dispose();
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: ölçüm ekranı 320 dp\'de taşmaz', (tester) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final device = _device();
      final controller = DeviceController(device, store: MemoryHealthStore());
      await tester.pumpWidget(
        BileklikApp(
          controller: controller,
          settings: AppSettings.memory(language: lang),
        ),
      );
      await tester.runAsync(() => controller.connect());
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold).first);
      showMeasureSheet(ctx);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Navigator.of(ctx).pop();
      await tester.pumpAndSettle();

      startSpotMeasurement(ctx, MetricType.heartRate);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(SpotMeasureScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 20));
      expect(controller.lastSpot, isNotNull);
      expect(tester.takeException(), isNull);

      await tester.runAsync(() => controller.disconnect());
      device.dispose();
    });
  }
}
