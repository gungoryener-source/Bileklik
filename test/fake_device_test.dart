import 'dart:math';

import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/commands.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/device/wristband_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeDevice device;
  late WristbandClient client;

  setUp(() async {
    device = FakeDevice(
      random: Random(1),
      realtimeInterval: const Duration(milliseconds: 20),
    );
    client = WristbandClient(device);
    await device.connect();
  });

  tearDown(() async {
    await device.disconnect();
    await client.dispose();
    device.dispose();
  });

  test('saat ayarlanıp geri okunur', () async {
    final t = DateTime(2026, 10, 19, 17, 30, 5);
    await client.syncTime(t);
    final read = await client.getTime();
    expect(read.difference(t).inSeconds.abs(), lessThanOrEqualTo(2));
  });

  test('kişisel bilgi yazılıp okunur', () async {
    await client.setPersonalInfo(
      const PersonalInfo(isMale: false, age: 41, heightCm: 168, weightKg: 62),
    );
    final info = await client.getPersonalInfo();
    expect(info.isMale, isFalse);
    expect(info.age, 41);
    expect(info.heightCm, 168);
    expect(info.weightKg, 62);
    expect(info.mac, 'A1:B2:C3:D4:E5:F6');
  });

  test('pil seviyesi okunur', () async {
    final b = await client.getBattery();
    expect(b.percent, inInclusiveRange(1, 100));
    expect(b.charging, isFalse);
  });

  test('anlık veri akışı gerçekçi değerler üretir', () async {
    final first = client.realtime.take(3).toList();
    await client.startRealtime();
    final samples = await first;
    await client.stopRealtime();
    for (final s in samples) {
      expect(s.heartRate, inInclusiveRange(40, 200));
      // SpO2 yalnızca 0x28 03 ölçümü sürerken gelir.
      expect(s.spo2, 0);
      expect(s.temperatureC, inInclusiveRange(30, 40));
    }
    expect(samples.last.steps, greaterThanOrEqualTo(samples.first.steps));
  });

  test('bilinmeyen komut hata yanıtı alır', () async {
    final reply = device.incoming.first;
    await device.send(Packet.build(0x7E).bytes);
    final p = Packet.parse(await reply);
    expect(p.isError, isTrue);
    expect(p.command, 0x7E);
  });
}
