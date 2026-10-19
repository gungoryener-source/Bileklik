import 'packet.dart';

/// V8 API PDF'indeki komut kodları. Şimdilik ilk aşamada kullanılanlar var;
/// geçmiş veri komutları (0x51-0x66) bileklik geldiğinde eklenecek.
abstract final class Cmd {
  static const setTime = 0x01;
  static const setPersonalInfo = 0x02;
  static const realtime = 0x09;
  static const batteryLevel = 0x13;
  static const macAddress = 0x22;
  static const firmwareVersion = 0x27;
  static const getTime = 0x41;
  static const getPersonalInfo = 0x42;
}

/// Uygulamadan cihaza giden komutları üretir.
abstract final class Commands {
  /// 0x01: Cihaz saatini ayarlar. Alanlar BCD kodludur (yıl 2000'den sonrası).
  static Packet setTime(DateTime t) => Packet.build(Cmd.setTime, [
        toBcd(t.year % 100),
        toBcd(t.month),
        toBcd(t.day),
        toBcd(t.hour),
        toBcd(t.minute),
        toBcd(t.second),
      ]);

  static Packet getTime() => Packet.build(Cmd.getTime);

  /// 0x02: Cinsiyet (0 kadın, 1 erkek), yaş, boy (cm), kilo (kg).
  static Packet setPersonalInfo(PersonalInfo info) => Packet.build(
        Cmd.setPersonalInfo,
        [info.isMale ? 1 : 0, info.age, info.heightCm, info.weightKg],
      );

  static Packet getPersonalInfo() => Packet.build(Cmd.getPersonalInfo);

  static Packet batteryLevel() => Packet.build(Cmd.batteryLevel);

  /// 0x09: Anlık adım, nabız, ısı ve SpO2 akışını açar ya da kapatır.
  static Packet realtime(bool enabled) =>
      Packet.build(Cmd.realtime, [enabled ? 1 : 0]);
}

class PersonalInfo {
  final bool isMale;
  final int age;
  final int heightCm;
  final int weightKg;
  final int? stepLengthCm;
  final String? mac;

  const PersonalInfo({
    required this.isMale,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.stepLengthCm,
    this.mac,
  });
}

class BatteryStatus {
  final int percent;
  final bool charging;

  /// Gerilim baytlarının bayt sırası PDF'te belirtilmemiş; gerçek cihazla doğrulanacak.
  final int voltageRaw;

  const BatteryStatus(this.percent, this.charging, this.voltageRaw);
}

/// 0x09 yanıtı. Bu yanıt 16 bayttan uzundur ve CRC taşımaz.
class RealtimeData {
  final int steps;
  final double calories; // kcal
  final double distanceKm;
  final int heartRate; // 0 = ölçüm yok
  final double temperatureC;
  final int spo2; // 0 = ölçüm yok (0x28 ile ölçüm başlatılmalı)

  const RealtimeData({
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.heartRate,
    required this.temperatureC,
    required this.spo2,
  });
}

/// Cihazdan gelen yanıtları çözer.
abstract final class Decoders {
  /// 0x41 yanıtı: YY MM DD HH mm SS (BCD).
  static DateTime time(Packet p) {
    final d = p.payload;
    return DateTime(2000 + fromBcd(d[0]), fromBcd(d[1]), fromBcd(d[2]),
        fromBcd(d[3]), fromBcd(d[4]), fromBcd(d[5]));
  }

  /// 0x42 yanıtı: cinsiyet, yaş, boy, kilo, adım uzunluğu, 6 baytlık MAC.
  static PersonalInfo personalInfo(Packet p) {
    final d = p.payload;
    final mac = d
        .sublist(5, 11)
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
    return PersonalInfo(
      isMale: d[0] == 1,
      age: d[1],
      heightCm: d[2],
      weightKg: d[3],
      stepLengthCm: d[4],
      mac: mac,
    );
  }

  /// 0x13 yanıtı: yüzde, şarj durumu, gerilim.
  static BatteryStatus battery(Packet p) {
    final d = p.payload;
    return BatteryStatus(d[0], d[1] == 1, (d[2] << 8) | d[3]);
  }

  /// 0x09 yanıtı. Sıra: adım(4) kalori(4) mesafe(4) ayrılmış(8) nabız(1)
  /// ısı(2) SpO2(1); çok baytlı alanlar küçük sonludur.
  static RealtimeData realtime(List<int> raw) {
    if (raw.isEmpty || raw[0] != Cmd.realtime || raw.length < 25) {
      throw const FormatException('Geçersiz 0x09 yanıtı');
    }
    return RealtimeData(
      steps: readUintLE(raw, 1, 4),
      calories: readUintLE(raw, 5, 4) / 100,
      distanceKm: readUintLE(raw, 9, 4) / 100,
      heartRate: raw[21],
      temperatureC: readUintLE(raw, 22, 2) / 10,
      spo2: raw[24],
    );
  }
}
