import 'packet.dart';

/// EKG komutları (V8 API PDF: 0x28 elle ölçüm, 0x07 EKG ham verisi).
abstract final class EcgCmd {
  static const measure = 0x28;
  static const raw = 0x07;
}

/// 0x28 AA alanı: hangi ölçümün başlatılacağı.
enum MeasureMode {
  heartRate(0x02),
  spo2(0x03),
  ecg(0x04);

  const MeasureMode(this.code);
  final int code;
}

/// Ham EKG örnekleme hızı. PDF'te yazmıyor; yaygın değer olan 250 Hz
/// varsayıldı (gerçek cihazda doğrulanacak).
const ecgSampleRate = 250;

/// 0x28 AA BB 00 CC DD: ölçümü başlatır (BB=1) ya da durdurur (BB=0).
/// CC DD süre (sn, küçük sonlu); 30'dan azsa cihaz 30 sn ölçer.
Packet measurement(MeasureMode mode, {required bool start, int seconds = 30}) =>
    Packet.build(EcgCmd.measure, [
      mode.code,
      start ? 1 : 0,
      0,
      seconds & 0xFF,
      (seconds >> 8) & 0xFF,
    ]);

/// 0x07 AA: EKG ham veri akışını açar (1) ya da kapatır (0). Açtıktan sonra
/// ölçüm 0x28 04 01 ile başlatılmalı.
Packet ecgRawSwitch(bool enabled) =>
    Packet.build(EcgCmd.raw, [enabled ? 1 : 0]);

/// `07 SIRA D1 D2 D3 ...`: her örnek 3 bayt, küçük sonlu.
class EcgPacket {
  final int sequence;
  final List<int> samples;
  const EcgPacket(this.sequence, this.samples);

  /// 0x07 komutunun 16 baytlık yanıtı (2 + 14 bayt) 3'e bölünmez; veri
  /// paketlerinde komut ve sıra baytından sonrası hep 3'ün katıdır.
  static bool isData(List<int> raw) =>
      raw.length > 2 && raw[0] == EcgCmd.raw && (raw.length - 2) % 3 == 0;

  static EcgPacket parse(List<int> raw) => EcgPacket(raw[1], [
    for (var i = 2; i + 2 < raw.length; i += 3)
      _signed24(readUintLE(raw, i, 3)),
  ]);

  /// Değerin işaretli olup olmadığı PDF'te yazmıyor; SDK örnekleri pozitif.
  /// En üst bit 1 ise negatif sayıyoruz (gerçek cihazda doğrulanacak).
  static int _signed24(int v) => v & 0x800000 != 0 ? v - 0x1000000 : v;
}
