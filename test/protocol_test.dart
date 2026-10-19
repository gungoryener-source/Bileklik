import 'package:bileklik/device/protocol/commands.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:flutter_test/flutter_test.dart';

/// "0x01 24 08 ..." gibi PDF örneklerini bayt listesine çevirir.
List<int> hex(String s) => s
    .split(' ')
    .where((e) => e.isNotEmpty)
    .map((e) => int.parse(e.replaceFirst('0x', ''), radix: 16))
    .toList();

void main() {
  group('Packet', () {
    test('CRC ilk 15 baytın toplamının en düşük 8 bitidir', () {
      // PDF: 0x01 komutunun başarılı yanıtı ... F5 ile biter.
      final reply = hex('01 F4 00 00 00 00 00 00 00 00 00 00 00 00 00 F5');
      expect(Packet.crc(reply), 0xF5);
      expect(Packet.parse(reply).isError, isFalse);
    });

    test('CRC hatalı paket reddedilir', () {
      final bad = hex('01 F4 00 00 00 00 00 00 00 00 00 00 00 00 00 00');
      expect(() => Packet.parse(bad), throwsFormatException);
    });

    test('hata yanıtında 7. bit 1 olur', () {
      final p = Packet.error(0x01);
      expect(p.bytes[0], 0x81);
      expect(p.isError, isTrue);
      expect(p.command, 0x01);
    });

    test('0x7F üstü komut ve 14 bayttan uzun veri reddedilir', () {
      expect(() => Packet.build(0x80), throwsArgumentError);
      expect(() => Packet.build(0x01, List.filled(15, 0)), throwsArgumentError);
    });
  });

  group('Komutlar', () {
    test('saat ayarı BCD kodlanır (PDF örneği)', () {
      final p = Commands.setTime(DateTime(2024, 8, 10, 13, 14, 59));
      expect(p.bytes.sublist(0, 7), hex('01 24 08 10 13 14 59'));
    });

    test('kişisel bilgi onaltılık yazılır (PDF örneği)', () {
      final p = Commands.setPersonalInfo(const PersonalInfo(
          isMale: false, age: 0x25, heightCm: 170, weightKg: 50));
      expect(p.bytes.sublist(0, 5), hex('02 00 25 AA 32'));
    });
  });

  group('Çözücüler', () {
    test('0x41 saat yanıtı', () {
      final raw = hex('41 24 08 08 08 10 47 06 F4 00 00 00 00 00 00 00');
      raw[15] = Packet.crc(raw);
      expect(Decoders.time(Packet.parse(raw)), DateTime(2024, 8, 8, 8, 10, 47));
    });

    test('0x42 kişisel bilgi yanıtı (PDF örneği)', () {
      final raw = hex('42 00 25 AA 32 3B 30 30 30 30 30 30 00 00 00 00');
      raw[15] = Packet.crc(raw);
      final info = Decoders.personalInfo(Packet.parse(raw));
      expect(info.isMale, isFalse);
      expect(info.age, 37);
      expect(info.heightCm, 170);
      expect(info.weightKg, 50);
      expect(info.stepLengthCm, 59);
      expect(info.mac, '30:30:30:30:30:30');
    });

    test('0x09 anlık veri yanıtı (PDF örneği)', () {
      final data = Decoders.realtime(hex(
          '09 66 00 00 00 19 01 00 00 05 00 00 00 25 00 00 00 00 00 00 00 00 '
          '5A 01 00 00 00 00 00 00 00 00'));
      expect(data.steps, 102);
      expect(data.calories, closeTo(2.81, 1e-9));
      expect(data.distanceKm, closeTo(0.05, 1e-9));
      expect(data.heartRate, 0);
      expect(data.temperatureC, closeTo(34.6, 1e-9));
      expect(data.spo2, 0);
    });
  });
}
