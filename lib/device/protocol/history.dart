import 'packet.dart';

/// Geçmiş veri komutları (V8 API PDF, madde 14-21).
///
/// Cihaz kayıtları uç uca ekleyerek gönderir; her kayıt komut koduyla başlar
/// ve veri bitince `[komut, 0xFF]` gelir. Tarih ve saat alanları BCD,
/// sayısal alanlar küçük sonludur.
enum HistoryKind {
  dailyTotals(0x51, 27),
  stepDetail(0x52, 25),
  sleep(0x53, 130),
  heartRateDetail(0x54, 24),
  heartRateSingle(0x55, 10),
  hrv(0x56, 15),
  temperature(0x62, 11),
  spo2(0x66, 10),

  /// 0x5C egzersiz kayıtları (bkz. `ExerciseRecord`).
  exercise(0x5C, 25);

  const HistoryKind(this.command, this.recordLength);

  final int command;

  /// Tek kaydın bayt uzunluğu (komut baytı dahil).
  final int recordLength;

  static HistoryKind? byCommand(int command) {
    for (final k in values) {
      if (k.command == command) return k;
    }
    return null;
  }
}

/// Geçmiş istek modu (AA alanı).
abstract final class HistoryMode {
  /// Verilen zamandan sonraki kayıtları baştan okur.
  static const read = 0x00;

  /// Bir önceki 50 kaydın devamını okur.
  static const next = 0x02;

  /// Cihazdaki bu türden tüm kayıtları siler.
  static const delete = 0x99;
}

/// Bir geçmiş isteği: `cmd AA 00 00 YY MM DD HH mm SS`.
Packet historyRequest(HistoryKind kind, int mode, {DateTime? since}) {
  if (kind == HistoryKind.dailyTotals) {
    return Packet.build(kind.command);
  }
  final t = since;
  return Packet.build(kind.command, [
    mode,
    0,
    0,
    if (t != null) ...[
      toBcd(t.year % 100),
      toBcd(t.month),
      toBcd(t.day),
      toBcd(t.hour),
      toBcd(t.minute),
      toBcd(t.second),
    ],
  ]);
}

/// Bir bildirimdeki kayıtları ayırır.
///
/// `ended` true ise cihaz `[komut, 0xFF]` ile verinin bittiğini bildirmiştir.
class HistoryChunk {
  final List<List<int>> records;
  final bool ended;
  const HistoryChunk(this.records, this.ended);
}

HistoryChunk splitHistory(HistoryKind kind, List<int> data) =>
    splitRecords(kind.command, kind.recordLength, data);

/// [command] ile başlayan [recordLength] baytlık kayıtları ayırır; geçmiş
/// türleri dışında hatırlatıcı listesi (0x57) de bu biçimde gelir.
HistoryChunk splitRecords(int command, int recordLength, List<int> data) {
  final records = <List<int>>[];
  var ended = false;
  var i = 0;
  while (i < data.length) {
    final remaining = data.length - i;
    if (data[i] != command) break;
    if (remaining < recordLength) {
      // Kayıttan kısa kalan kısım yalnızca bitiş işareti olabilir.
      if (remaining >= 2 && data[i + 1] == 0xFF) ended = true;
      break;
    }
    records.add(data.sublist(i, i + recordLength));
    i += recordLength;
  }
  return HistoryChunk(records, ended);
}

DateTime _bcdDate(List<int> r, int o) =>
    DateTime(2000 + fromBcd(r[o]), fromBcd(r[o + 1]), fromBcd(r[o + 2]));

DateTime _bcdDateTime(List<int> r, int o) => DateTime(
  2000 + fromBcd(r[o]),
  fromBcd(r[o + 1]),
  fromBcd(r[o + 2]),
  fromBcd(r[o + 3]),
  fromBcd(r[o + 4]),
  fromBcd(r[o + 5]),
);

/// 0x51: günlük toplam (ID = kaç gün önce, 0 bugün; en fazla 15 gün).
class DailyTotalRecord {
  final int daysAgo;
  final DateTime date;
  final int steps;
  final int exerciseSeconds;
  final double distanceKm;
  final double calories;
  const DailyTotalRecord(
    this.daysAgo,
    this.date,
    this.steps,
    this.exerciseSeconds,
    this.distanceKm,
    this.calories,
  );

  static DailyTotalRecord parse(List<int> r) => DailyTotalRecord(
    r[1],
    _bcdDate(r, 2),
    readUintLE(r, 5, 4),
    readUintLE(r, 9, 4),
    readUintLE(r, 13, 4) / 100,
    readUintLE(r, 17, 4) / 100,
  );
}

/// 0x52: 10 dakikalık adım kaydı ve dakika dakika adımlar.
class StepDetailRecord {
  final DateTime time;
  final int steps;
  final double calories;
  final double distanceKm;
  final List<int> perMinute;
  const StepDetailRecord(
    this.time,
    this.steps,
    this.calories,
    this.distanceKm,
    this.perMinute,
  );

  static StepDetailRecord parse(List<int> r) => StepDetailRecord(
    _bcdDateTime(r, 3),
    readUintLE(r, 9, 2),
    readUintLE(r, 11, 2) / 100,
    readUintLE(r, 13, 2) / 100,
    r.sublist(15, 25),
  );
}

enum SleepStage { deep, light, rem, awake }

/// 0x53: en fazla 120 dakikalık uyku kaydı, her bayt bir dakika.
class SleepRecord {
  final DateTime start;
  final List<SleepStage> minutes;
  const SleepRecord(this.start, this.minutes);

  static SleepStage stageOf(int v) => switch (v) {
    1 => SleepStage.deep,
    2 => SleepStage.light,
    3 => SleepStage.rem,
    _ => SleepStage.awake,
  };

  static SleepRecord parse(List<int> r) {
    final len = r[9].clamp(0, 120);
    return SleepRecord(_bcdDateTime(r, 3), [
      for (final v in r.sublist(10, 10 + len)) stageOf(v),
    ]);
  }
}

/// 0x54: 5 saniyede bir ölçülen 15 nabız değeri (75 saniye).
class HeartRateDetailRecord {
  final DateTime time;
  final List<int> bpm;
  const HeartRateDetailRecord(this.time, this.bpm);

  static HeartRateDetailRecord parse(List<int> r) =>
      HeartRateDetailRecord(_bcdDateTime(r, 3), r.sublist(9, 24));

  /// Sıfır olmayan değerlerin ortalaması; hiç ölçüm yoksa null.
  double? get average {
    final v = bpm.where((b) => b > 0).toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }
}

/// 0x55 nabız ve 0x66 SpO2 gibi tek değerli kayıtlar.
class SingleValueRecord {
  final DateTime time;
  final int value;
  const SingleValueRecord(this.time, this.value);

  static SingleValueRecord parse(List<int> r) =>
      SingleValueRecord(_bcdDateTime(r, 3), r[9]);
}

/// 0x56: HRV, solunum, nabız, stres ve tansiyon (tansiyon kesinliği garantisiz).
class HrvRecord {
  final DateTime time;
  final int hrv;
  final int respiratoryRate;
  final int heartRate;
  final int stress;
  final int systolic;
  final int diastolic;
  const HrvRecord(
    this.time,
    this.hrv,
    this.respiratoryRate,
    this.heartRate,
    this.stress,
    this.systolic,
    this.diastolic,
  );

  static HrvRecord parse(List<int> r) =>
      HrvRecord(_bcdDateTime(r, 3), r[9], r[10], r[11], r[12], r[13], r[14]);
}

/// 0x62: bilek ısısı, 0,1 °C hassasiyetle.
class TemperatureRecord {
  final DateTime time;
  final double celsius;
  const TemperatureRecord(this.time, this.celsius);

  static TemperatureRecord parse(List<int> r) =>
      TemperatureRecord(_bcdDateTime(r, 3), readUintLE(r, 9, 2) / 10);
}
