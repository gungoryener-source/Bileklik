import 'dart:typed_data';

import 'packet.dart';

/// Ayar komutları (V8 API PDF, "Sağlık ayarları" ve "Genel ayarlar").
abstract final class SettingsCmd {
  /// 0x2A: otomatik ölçüm zaman aralığını yazar.
  static const setAutoMeasure = 0x2A;

  /// 0x2B: otomatik ölçüm zaman aralığını okur.
  static const getAutoMeasure = 0x2B;

  /// 0x03: temel parametreleri yazar; NN (B15) tüm gün nabız takibi.
  static const setBasic = 0x03;

  /// 0x04: temel parametreleri okur.
  static const getBasic = 0x04;

  /// 0x86: takma (bilekten çıkma) algılamasını açar ya da kapatır. Komut
  /// kodunun 7. biti 1 olduğu için hata yanıtıyla karışmaması adına ayrı
  /// ele alınır.
  static const wearDetection = 0x86;
}

/// Otomatik ölçülen türler; değer PDF'teki II/AA kodudur.
enum AutoMeasureType {
  heartRate(1),
  spo2(2),
  hrv(4);

  const AutoMeasureType(this.code);
  final int code;

  static AutoMeasureType? byCode(int code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// Bir türün otomatik ölçüm ayarı.
///
/// Bileklik [start]-[end] saatleri arasında, seçili günlerde, her
/// [intervalMinutes] dakikada bir 1 dakikalık ölçüm yapar. Uyku modunda
/// nabız aralığı bileklik tarafından 5 dakikaya çekilir (PDF).
class AutoMeasureConfig {
  const AutoMeasureConfig({
    required this.type,
    required this.enabled,
    this.startMinute = 0,
    this.endMinute = 23 * 60 + 59,
    this.weekdays = allDays,
    this.intervalMinutes = 30,
  });

  /// Uygulamanın önerdiği başlangıç ayarı: gün boyu, her gün, 30 dk.
  const AutoMeasureConfig.defaults(this.type)
    : enabled = true,
      startMinute = 0,
      endMinute = 23 * 60 + 59,
      weekdays = allDays,
      intervalMinutes = 30;

  /// Bit0 pazar ... bit6 cumartesi; 0x7F her gün.
  static const allDays = 0x7F;

  /// Arayüzde sunulan aralıklar (dakika). Her ölçüm 1 dakika sürer.
  static const intervalChoices = [5, 10, 15, 30, 60, 120];

  final AutoMeasureType type;
  final bool enabled;

  /// Gece yarısından itibaren dakika (0-1439).
  final int startMinute;
  final int endMinute;
  final int weekdays;
  final int intervalMinutes;

  bool get allDay => startMinute == 0 && endMinute == 23 * 60 + 59;

  /// [weekday] DateTime biçiminde (1 pazartesi ... 7 pazar).
  bool hasDay(int weekday) => weekdays & (1 << (weekday % 7)) != 0;

  AutoMeasureConfig withDay(int weekday, bool on) {
    final bit = 1 << (weekday % 7);
    return copyWith(weekdays: on ? weekdays | bit : weekdays & ~bit);
  }

  AutoMeasureConfig copyWith({
    bool? enabled,
    int? startMinute,
    int? endMinute,
    int? weekdays,
    int? intervalMinutes,
  }) => AutoMeasureConfig(
    type: type,
    enabled: enabled ?? this.enabled,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    weekdays: weekdays ?? this.weekdays,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
  );

  /// 0x2A ve 0x2B yanıtındaki 9 baytlık gövde: AA BB CC DD EE FF GG HH II.
  ///
  /// GG HH aralığı V1.2 örneğinde "05 00 = 5 dakika", yani küçük sonlu;
  /// 0x2B açıklamasındaki "big-endian" notu örnekle çelişiyor. Örneğe
  /// uyuldu; gerçek cihazda doğrulanacak.
  List<int> toBytes() => [
    enabled ? 2 : 0,
    toBcd(startMinute ~/ 60),
    toBcd(startMinute % 60),
    toBcd(endMinute ~/ 60),
    toBcd(endMinute % 60),
    weekdays & 0x7F,
    intervalMinutes & 0xFF,
    (intervalMinutes >> 8) & 0xFF,
    type.code,
  ];

  static AutoMeasureConfig fromBytes(List<int> d, {AutoMeasureType? type}) {
    final t = AutoMeasureType.byCode(d[8]) ?? type;
    if (t == null) throw const FormatException('Bilinmeyen ölçüm türü');
    final interval = d[6] | (d[7] << 8);
    return AutoMeasureConfig(
      type: t,
      enabled: d[0] == 2,
      startMinute: fromBcd(d[1]) * 60 + fromBcd(d[2]),
      endMinute: fromBcd(d[3]) * 60 + fromBcd(d[4]),
      weekdays: d[5] & 0x7F,
      intervalMinutes: interval == 0 ? 30 : interval,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AutoMeasureConfig &&
      other.type == type &&
      other.enabled == enabled &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.weekdays == weekdays &&
      other.intervalMinutes == intervalMinutes;

  @override
  int get hashCode => Object.hash(
    type,
    enabled,
    startMinute,
    endMinute,
    weekdays,
    intervalMinutes,
  );
}

/// 0x2A: otomatik ölçüm ayarını yazar.
Packet setAutoMeasureCommand(AutoMeasureConfig c) =>
    Packet.build(SettingsCmd.setAutoMeasure, c.toBytes());

/// 0x2B: bir türün otomatik ölçüm ayarını ister.
Packet getAutoMeasureCommand(AutoMeasureType t) =>
    Packet.build(SettingsCmd.getAutoMeasure, [t.code]);

/// 0x2B yanıtı: AA BB CC DD EE FF GG HH II.
AutoMeasureConfig decodeAutoMeasure(Packet p, AutoMeasureType asked) =>
    AutoMeasureConfig.fromBytes(p.payload, type: asked);

/// 0x86 AA: takma algılamasını açar (1) ya da kapatır (0).
///
/// Komut kodu 0x7F'den büyük olduğu için [Packet.build] kullanılmaz.
Uint8List wearDetectionCommand(bool enabled) {
  final bytes = Uint8List(Packet.length);
  bytes[0] = SettingsCmd.wearDetection;
  bytes[1] = enabled ? 1 : 0;
  bytes[15] = Packet.crc(bytes);
  return bytes;
}

/// 0x86 bildirimi: nabız, SpO2 ya da HRV ölçümü sürerken gelir.
sealed class WearEvent {
  const WearEvent();

  /// 0x86 AA BB ...; tanınmayan biçimde null.
  static WearEvent? parse(List<int> raw) {
    if (raw.length < 3 || raw[0] != SettingsCmd.wearDetection) return null;
    return switch (raw[1]) {
      // Ölçüm başında bileklik "çıkarılmış" varsayımıyla başlar (BB = 0).
      1 => const WearMeasureStarted(),
      2 => WearChanged(worn: raw[2] == 1),
      3 => const WearMotion(),
      // Komuta verilen onay; PDF gövdesini tanımlamıyor.
      _ => const WearAck(),
    };
  }
}

class WearMeasureStarted extends WearEvent {
  const WearMeasureStarted();
}

class WearChanged extends WearEvent {
  const WearChanged({required this.worn});
  final bool worn;
}

/// Ölçüm sırasında hareket algılandı; kullanıcıdan kıpırdamaması istenir.
class WearMotion extends WearEvent {
  const WearMotion();
}

class WearAck extends WearEvent {
  const WearAck();
}

/// 0x03 ve 0x04'teki NN değerleri (son veri baytı, B15).
abstract final class AllDayHeartRate {
  static const on = 0x81;
  static const off = 0x80;
}

/// 0x03 00 … 00 NN: tüm gün nabız takibini açar (0x81) ya da kapatır (0x80).
Packet setAllDayHeartRateCommand(bool enabled) => Packet.build(
  SettingsCmd.setBasic,
  [...List.filled(13, 0), enabled ? AllDayHeartRate.on : AllDayHeartRate.off],
);

/// 0x04: temel parametreleri ister.
Packet getBasicSettingsCommand() => Packet.build(SettingsCmd.getBasic);

/// 0x04 yanıtı: `04 00 … 00 NN`; NN 0x81 açık.
bool decodeAllDayHeartRate(Packet p) => p.payload[13] == AllDayHeartRate.on;

/// 0x27 yanıtı: `27 AA BB CC DD EE FF GG … ID`. AA-DD sürüm (BCD), EE FF GG
/// derleme tarihi (yıl, ay, gün). Sürümün yazılışı (noktalı) belgede yok.
class FirmwareInfo {
  const FirmwareInfo(this.version, this.date);

  final String version;
  final DateTime? date;

  static FirmwareInfo parse(Packet p) {
    final d = p.payload;
    final version = [for (final b in d.sublist(0, 4)) fromBcd(b)].join('.');
    final y = fromBcd(d[4]), m = fromBcd(d[5]), day = fromBcd(d[6]);
    final ok = m >= 1 && m <= 12 && day >= 1 && day <= 31;
    return FirmwareInfo(version, ok ? DateTime(2000 + y, m, day) : null);
  }
}
