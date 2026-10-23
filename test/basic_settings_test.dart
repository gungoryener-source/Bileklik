import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/commands.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/device/protocol/settings.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

FakeDevice _device() => FakeDevice(
  random: Random(4),
  realtimeInterval: const Duration(seconds: 30),
);

void main() {
  group('V8 API V1.2 örnekleri', () {
    test('0x03 tüm gün nabız: NN son veri baytında', () {
      expect(
        setAllDayHeartRateCommand(true).bytes.sublist(0, 15),
        hex('03 00 00 00 00 00 00 00 00 00 00 00 00 00 81'),
      );
      expect(setAllDayHeartRateCommand(false).bytes[14], 0x80);
      final p = setAllDayHeartRateCommand(true).bytes;
      expect(p.last, Packet.crc(p));
    });

    test('0x04 yanıtı: 04 00 … 00 NN', () {
      final on = Packet.build(SettingsCmd.getBasic, [
        ...List.filled(13, 0),
        0x81,
      ]);
      expect(decodeAllDayHeartRate(on), isTrue);
      final off = Packet.build(SettingsCmd.getBasic, [
        ...List.filled(13, 0),
        0x80,
      ]);
      expect(decodeAllDayHeartRate(off), isFalse);
    });

    test('0x27 yazılım sürümü ve derleme tarihi', () {
      expect(Commands.firmwareVersion().bytes.sublist(0, 2), hex('27 00'));
      final fw = FirmwareInfo.parse(
        Packet.build(Cmd.firmwareVersion, hex('01 00 02 05 26 07 31')),
      );
      expect(fw.version, '1.0.2.5');
      expect(fw.date, DateTime(2026, 7, 31));
      final noDate = FirmwareInfo.parse(
        Packet.build(Cmd.firmwareVersion, hex('01 00 00 00 00 00 00')),
      );
      expect(noDate.date, isNull);
    });

    test('0x2A örneği: 2A 02 00 00 23 59 7F 05 00 02', () {
      const c = AutoMeasureConfig(
        type: AutoMeasureType.spo2,
        enabled: true,
        startMinute: 0,
        endMinute: 23 * 60 + 59,
        weekdays: 0x7F,
        intervalMinutes: 5,
      );
      expect(
        setAutoMeasureCommand(c).bytes.sublist(0, 10),
        hex('2A 02 00 00 23 59 7F 05 00 02'),
      );
    });
  });

  test('denetleyici bağlanınca okur, yazar; bağlantı kesilince boşalır', () async {
    final device = _device();
    final c = DeviceController(device, store: MemoryHealthStore());
    await c.connect();
    expect(c.allDayHeartRate, isTrue);
    expect(c.firmware!.version, '1.0.2.5');

    expect(await c.setAllDayHeartRate(false), isTrue);
    expect(device.allDayHeartRate, isFalse);

    await c.disconnect();
    expect(c.allDayHeartRate, isNull);
    expect(c.firmware, isNull);
    expect(await c.setAllDayHeartRate(true), isFalse);
    device.dispose();
  });

  testWidgets('Cihaz ekranı sürümü ve tüm gün nabız anahtarını gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final device = _device();
    final c = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(
      BileklikApp(controller: c, settings: AppSettings.memory()),
    );
    await tester.runAsync(() => c.connect());
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const DeviceScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Yazılım sürümü'), findsOneWidget);
    expect(find.text('\u20661.0.2.5\u2069'), findsOneWidget);

    final tile = find.widgetWithText(SwitchListTile, 'Tüm gün nabız takibi');
    await tester.scrollUntilVisible(tile, 200);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await tester.runAsync(() async {
      await tester.tap(tile);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.allDayHeartRate, isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.runAsync(() => c.disconnect());
    device.dispose();
  });
}
