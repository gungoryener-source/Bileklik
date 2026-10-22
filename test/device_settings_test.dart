import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/device/protocol/settings.dart';
import 'package:bileklik/device/wristband_client.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/format.dart';
import 'package:bileklik/ui/screens/auto_measure_screen.dart';
import 'package:bileklik/ui/screens/device_screen.dart';
import 'package:bileklik/ui/screens/general_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

FakeDevice _device() => FakeDevice(
  random: Random(7),
  realtimeInterval: const Duration(seconds: 30),
  spotInterval: const Duration(milliseconds: 10),
);

void main() {
  group('protokol', () {
    test('0x2A: PDF örneği 2A 02 00 00 23 59 7F 05 00 02', () {
      const c = AutoMeasureConfig(
        type: AutoMeasureType.spo2,
        enabled: true,
        startMinute: 0,
        endMinute: 23 * 60 + 59,
        weekdays: 0x7F,
        intervalMinutes: 5,
      );
      final p = setAutoMeasureCommand(c);
      expect(p.bytes.sublist(0, 10), hex('2A 02 00 00 23 59 7F 05 00 02'));
      expect(p.bytes.last, Packet.crc(p.bytes));
    });

    test('0x2B: PDF yanıtı çözülür', () {
      final raw = [...hex('2B 02 00 00 23 59 7F 05 00 02 00 00 00 00 00'), 0];
      raw[15] = Packet.crc(raw);
      final c = decodeAutoMeasure(Packet.parse(raw), AutoMeasureType.spo2);
      expect(c.type, AutoMeasureType.spo2);
      expect(c.enabled, isTrue);
      expect(c.allDay, isTrue);
      expect(c.intervalMinutes, 5);
      for (var d = 1; d <= 7; d++) {
        expect(c.hasDay(d), isTrue);
      }
    });

    test('gün bitleri: bit0 pazar, bit1 pazartesi', () {
      const c = AutoMeasureConfig(
        type: AutoMeasureType.heartRate,
        enabled: true,
        weekdays: 0,
      );
      expect(c.withDay(DateTime.sunday, true).weekdays, 0x01);
      expect(c.withDay(DateTime.monday, true).weekdays, 0x02);
      expect(c.withDay(DateTime.saturday, true).weekdays, 0x40);
    });

    test('BCD saatler: 08:30-22:15', () {
      const c = AutoMeasureConfig(
        type: AutoMeasureType.hrv,
        enabled: true,
        startMinute: 8 * 60 + 30,
        endMinute: 22 * 60 + 15,
        intervalMinutes: 120,
      );
      expect(c.toBytes(), hex('02 08 30 22 15 7F 78 00 04'));
      expect(AutoMeasureConfig.fromBytes(c.toBytes()), c);
    });

    test('0x86 komutu ve bildirimleri', () {
      final on = wearDetectionCommand(true);
      expect(on.sublist(0, 2), hex('86 01'));
      expect(on.last, Packet.crc(on));
      expect(WearEvent.parse(hex('86 01 00 00')), isA<WearMeasureStarted>());
      expect(
        (WearEvent.parse(hex('86 02 00 00'))! as WearChanged).worn,
        isFalse,
      );
      expect(
        (WearEvent.parse(hex('86 02 01 00'))! as WearChanged).worn,
        isTrue,
      );
      expect(WearEvent.parse(hex('86 03 00 00')), isA<WearMotion>());
    });
  });

  group('sahte bileklik', () {
    test('ayar yazılır ve geri okunur', () async {
      final device = _device();
      final client = WristbandClient(device);
      await device.connect();
      final before = await client.getAutoMeasure(AutoMeasureType.heartRate);
      expect(before.enabled, isFalse);
      const next = AutoMeasureConfig(
        type: AutoMeasureType.heartRate,
        enabled: true,
        startMinute: 7 * 60,
        endMinute: 23 * 60,
        weekdays: 0x3E,
        intervalMinutes: 15,
      );
      await client.setAutoMeasure(next);
      expect(await client.getAutoMeasure(AutoMeasureType.heartRate), next);
      await client.setWearDetection(true);
      expect(device.wearDetection, isTrue);
      await device.disconnect();
      await client.dispose();
      device.dispose();
    });

    test('geçersiz saat reddedilir (0xAA)', () async {
      final device = _device();
      final client = WristbandClient(device);
      await device.connect();
      final bad = setAutoMeasureCommand(
        const AutoMeasureConfig(type: AutoMeasureType.spo2, enabled: true),
      ).bytes.toList();
      bad[1 + 1] = 0x25; // saat 25
      bad[15] = Packet.crc(bad);
      final replies = <List<int>>[];
      final sub = device.incoming.listen(replies.add);
      await device.send(bad);
      await Future<void>.delayed(Duration.zero);
      expect(replies.single.first, 0xAA);
      await sub.cancel();
      await device.disconnect();
      await client.dispose();
      device.dispose();
    });
  });

  group('denetleyici', () {
    test('bağlanınca üç türün ayarı okunur', () async {
      final device = _device();
      final c = DeviceController(device, store: MemoryHealthStore());
      await c.connect();
      expect(c.autoMeasure.keys, AutoMeasureType.values);
      expect(c.settingsFailed, isFalse);
      expect(device.wearDetection, isTrue);

      final ok = await c.saveAutoMeasure(
        c.autoMeasure[AutoMeasureType.spo2]!.copyWith(enabled: true),
      );
      expect(ok, isTrue);
      expect(device.autoMeasure[AutoMeasureType.spo2]!.enabled, isTrue);
      await c.disconnect();
      expect(c.autoMeasure, isEmpty);
      device.dispose();
    });

    test('ölçümde bileklik çıkarılınca ve hareket edince uyarır', () async {
      final device = _device();
      final c = DeviceController(device, store: MemoryHealthStore());
      await c.connect();
      await c.startSpot(MetricType.heartRate, seconds: 60);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.spot!.offWrist, isFalse);
      device.simulateWorn(false);
      await Future<void>.delayed(Duration.zero);
      expect(c.spot!.offWrist, isTrue);
      device.simulateWorn(true);
      device.simulateMotion();
      await Future<void>.delayed(Duration.zero);
      expect(c.spot!.offWrist, isFalse);
      expect(c.spot!.moving, isTrue);
      await c.cancelSpot();
      await c.disconnect();
      device.dispose();
    });

    test('takma algılaması kapalıysa bildirim gelmez', () async {
      final device = _device();
      final c = DeviceController(
        device,
        store: MemoryHealthStore(),
        wearDetection: false,
      );
      await c.connect();
      expect(device.wearDetection, isFalse);
      await c.startSpot(MetricType.heartRate, seconds: 60);
      device.simulateWorn(false);
      await Future<void>.delayed(Duration.zero);
      expect(c.spot!.offWrist, isFalse);
      await c.cancelSpot();
      await c.disconnect();
      device.dispose();
    });
  });

  group('biçim tercihleri', () {
    tearDown(() {
      DisplayPrefs.imperial = false;
      DisplayPrefs.use24h = null;
    });

    test('ABD birimleri: mil ve °F', () {
      DisplayPrefs.imperial = true;
      expect(MetricType.distance.format(1.609344), '1.00');
      expect(MetricType.distance.unit, 'mi');
      expect(MetricType.temperature.format(35), '95.0');
      expect(paceFor(600, 1.609344), const Duration(seconds: 600));
    });

    test('12 ve 24 saat', () {
      final t = DateTime(2026, 10, 22, 21, 5);
      DisplayPrefs.use24h = true;
      expect(hhmm(t), '21:05');
      DisplayPrefs.use24h = false;
      expect(hhmm(t), startsWith('9:05'));
    });
  });

  Future<(DeviceController, FakeDevice)> openDevice(
    WidgetTester tester, {
    String language = 'tr',
    Size size = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final device = _device();
    final c = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(
      BileklikApp(
        controller: c,
        settings: AppSettings.memory(language: language),
      ),
    );
    await tester.runAsync(() => c.connect());
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const DeviceScreen()));
    await tester.pumpAndSettle();
    return (c, device);
  }

  testWidgets('otomatik ölçüm açılır, aralık seçilir', (tester) async {
    final (c, device) = await openDevice(tester);
    expect(find.text('Kapalı'), findsOneWidget);
    await tester.tap(find.text('Otomatik ölçüm'));
    await tester.pumpAndSettle();
    expect(find.byType(AutoMeasureScreen), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byType(Switch).first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.autoMeasure[AutoMeasureType.heartRate]!.enabled, isTrue);
    expect(find.text('Ölçüm aralığı'), findsOneWidget);
    expect(
      find.text('Uykudayken bileklik nabzı 5 dakikada bir ölçer.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ölçüm aralığı'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('10 dakikada bir'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.autoMeasure[AutoMeasureType.heartRate]!.intervalMinutes, 10);
    expect(find.text('10 dakikada bir · Tüm gün'), findsOneWidget);

    await tester.runAsync(() => c.disconnect());
    await tester.pumpAndSettle();
    expect(find.text('Bağlan'), findsOneWidget);
    device.dispose();
  });

  testWidgets('son gün kapatılamaz', (tester) async {
    final (c, device) = await openDevice(tester);
    await tester.runAsync(
      () => c.saveAutoMeasure(
        const AutoMeasureConfig(
          type: AutoMeasureType.heartRate,
          enabled: true,
          weekdays: 0x02, // yalnızca pazartesi
        ),
      ),
    );
    await tester.tap(find.text('Otomatik ölçüm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilterChip).first);
    await tester.pumpAndSettle();
    expect(find.text('En az bir gün seçili kalmalı.'), findsOneWidget);
    expect(device.autoMeasure[AutoMeasureType.heartRate]!.weekdays, 0x02);
    await tester.runAsync(() => c.disconnect());
    device.dispose();
  });

  for (final lang in ['ar', 'de', 'en']) {
    testWidgets('$lang: ayar ekranı 320 dp\'de taşmaz', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, device) = await openDevice(
        tester,
        language: lang,
        size: const Size(960, 1920),
      );
      for (final t in AutoMeasureType.values) {
        await tester.runAsync(
          () => c.saveAutoMeasure(
            AutoMeasureConfig(
              type: t,
              enabled: true,
              startMinute: 22 * 60,
              endMinute: 6 * 60,
              intervalMinutes: 120,
            ),
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(builder: (_) => const AutoMeasureScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      nav.push(
        MaterialPageRoute<void>(builder: (_) => const GeneralSettingsScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => c.disconnect());
      device.dispose();
    });
  }

  testWidgets('birim değişince açık ekranlar yenilenir', (tester) async {
    final settings = AppSettings.memory();
    final c = DeviceController(_device(), store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: c, settings: settings));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const GeneralSettingsScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Birimler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABD (mil, °F)'));
    await tester.pumpAndSettle();
    expect(settings.units, UnitSystem.imperial);
    expect(DisplayPrefs.imperial, isTrue);
    expect(find.text('ABD (mil, °F)'), findsOneWidget);

    await tester.tap(find.text('Saat biçimi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12 saat (ÖÖ/ÖS)'));
    await tester.pumpAndSettle();
    expect(DisplayPrefs.use24h, isFalse);
    settings.setUnits(UnitSystem.metric);
    settings.setClock(ClockFormat.system);
    await tester.pumpAndSettle();
  });
}
