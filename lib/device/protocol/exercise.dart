import 'dart:typed_data';

import 'packet.dart';

/// Egzersiz komutları (V8 API PDF: 0x19 kontrol, 0x18 canlı veri, 0x5C geçmiş).
abstract final class ExerciseCmd {
  static const control = 0x19;
  static const live = 0x18;
  static const history = 0x5C;
}

/// Spor türleri; kodlar 0x19 ve 0x5C'deki TY alanıyla aynıdır.
enum SportType {
  run(0),
  cycling(1),
  badminton(2),
  football(3),
  tennis(4),
  yoga(5),
  meditation(6),
  dance(7),
  basketball(8),
  walk(9),
  workout(10),
  cricket(11),
  hiking(12),
  aerobics(13),
  pingPong(14),
  ropeJump(15),
  sitUps(16),
  volleyball(17);

  const SportType(this.code);
  final int code;

  static SportType? byCode(int code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// 0x19 ile başlatılabilen türler. PDF 0-14 arasını listeliyor; meditasyon
  /// ayrı parametre (süre) istiyor ve ayrıca ele alınacak.
  static List<SportType> get startable => [
    for (final s in values)
      if (s.code <= 14 && s != meditation) s,
  ];
}

enum ExerciseAction {
  start(1),
  pause(2),
  resume(3),
  end(4),
  query(5);

  const ExerciseAction(this.code);
  final int code;
}

/// 0x19 AA BB CC DD: AA eylem, BB spor türü. CC/DD yalnızca meditasyonda kullanılır.
Packet exerciseControl(
  ExerciseAction action, [
  SportType type = SportType.run,
]) => Packet.build(ExerciseCmd.control, [action.code, type.code, 0, 0]);

/// 0x19 yanıtı: başarı ve egzersizin başladığı zaman.
///
/// PDF'te başlatma yanıtı `19 01 YY MM DD ...`, diğer eylemlerin yanıtı
/// `19 01 00 YY MM DD ...` biçiminde; ikisini de kabul ediyoruz
/// (gerçek cihazda doğrulanacak).
class ExerciseControlResult {
  final bool ok;
  final DateTime? startedAt;
  const ExerciseControlResult(this.ok, this.startedAt);

  static ExerciseControlResult parse(Packet p) {
    final d = p.payload;
    final ok = d[0] == 1;
    DateTime? at(int o) {
      final month = fromBcd(d[o + 1]), day = fromBcd(d[o + 2]);
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(
        2000 + fromBcd(d[o]),
        month,
        day,
        fromBcd(d[o + 3]),
        fromBcd(d[o + 4]),
        fromBcd(d[o + 5]),
      );
    }

    return ExerciseControlResult(ok, d[1] == 0 ? at(2) : at(1));
  }
}

double readFloatLE(List<int> bytes, int offset) =>
    ByteData.sublistView(Uint8List.fromList(bytes.sublist(offset, offset + 4)))
        .getFloat32(0, Endian.little);

/// 0x18 bildirimi: egzersiz sürerken saniyede bir gelen veri ya da uyarı.
sealed class ExerciseEvent {
  const ExerciseEvent();

  /// 16 baytlık paketler uyarıdır (bitiş ya da hareketsizlik), daha uzun
  /// olanlar canlı veridir. Canlı veri CRC taşımaz.
  static ExerciseEvent parse(List<int> raw) {
    if (raw.length <= Packet.length) {
      if (raw[1] == 0xFF) return ExerciseEnded(autoDetected: raw[2] == 2);
      return ExerciseInactive(raw[2]);
    }
    return ExerciseLive(
      heartRate: raw[1],
      steps: readUintLE(raw, 2, 4),
      calories: readFloatLE(raw, 6),
      durationSeconds: readUintLE(raw, 10, 4),
      distanceKm: readFloatLE(raw, 14),
    );
  }
}

/// `18 HR S1-S4 K1-K4 T1-T4 D1-D4`: nabız, adım, kalori (float), süre (sn),
/// mesafe (float km). Süre ve mesafe birimleri gerçek cihazda doğrulanacak.
class ExerciseLive extends ExerciseEvent {
  final int heartRate;
  final int steps;
  final double calories;
  final int durationSeconds;
  final double distanceKm;
  const ExerciseLive({
    required this.heartRate,
    required this.steps,
    required this.calories,
    required this.durationSeconds,
    required this.distanceKm,
  });
}

/// `18 FF XX`: cihaz egzersizi bitirdi; XX = 2 ise hareketsizlikten otomatik.
class ExerciseEnded extends ExerciseEvent {
  final bool autoDetected;
  const ExerciseEnded({required this.autoDetected});
}

/// `18 AA 01/02`: 10 ya da 20 dakikadır 80 adımdan az; uygulama
/// kullanıcıya bitirmek isteyip istemediğini sorar.
class ExerciseInactive extends ExerciseEvent {
  final int level;
  const ExerciseInactive(this.level);

  int get minutes => level * 10;
}

/// 0x5C kaydı: `5C ID1 ID2 YYMMDDHHmmSS TY HR Tt tt SS SS PP pp K*4 D*4`.
class ExerciseRecord {
  final DateTime start;
  final SportType? type;
  final int heartRate;
  final int durationSeconds;
  final int steps;

  /// 1 km'nin kaç saniyede yürüdüğü/koşulduğu (PP dakika, pp saniye).
  final int paceSeconds;
  final double calories;
  final double distanceKm;
  const ExerciseRecord({
    required this.start,
    required this.type,
    required this.heartRate,
    required this.durationSeconds,
    required this.steps,
    required this.paceSeconds,
    required this.calories,
    required this.distanceKm,
  });

  static const length = 25;

  static ExerciseRecord parse(List<int> r) => ExerciseRecord(
    start: DateTime(
      2000 + fromBcd(r[3]),
      fromBcd(r[4]),
      fromBcd(r[5]),
      fromBcd(r[6]),
      fromBcd(r[7]),
      fromBcd(r[8]),
    ),
    type: SportType.byCode(r[9]),
    heartRate: r[10],
    durationSeconds: readUintLE(r, 11, 2),
    steps: readUintLE(r, 13, 2),
    paceSeconds: r[15] * 60 + r[16],
    calories: readFloatLE(r, 17),
    distanceKm: readFloatLE(r, 21),
  );
}
