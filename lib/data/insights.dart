import 'dart:math';

import 'aggregate.dart';
import 'health_store.dart';
import 'hrv_analysis.dart';
import 'models.dart';

// Uygulamanın kendi hesapladığı içgörüler: nabız bölgeleri, vücut ısısı
// sapması, biyolojik yaş ve Sağlık Radarı. Hiçbiri tıbbi ölçüm ya da tanı
// değildir; ekranlarda bu not her zaman yanlarında durur.

// ---------------------------------------------------------------------------
// Nabız bölgeleri
// ---------------------------------------------------------------------------

/// Azami nabzın yüzdesine göre beş bölge.
enum HeartRateZone {
  /// %50–60.
  warmUp(0.5),

  /// %60–70.
  fatBurn(0.6),

  /// %70–80.
  aerobic(0.7),

  /// %80–90.
  anaerobic(0.8),

  /// %90 ve üstü.
  maximum(0.9);

  const HeartRateZone(this.lower);

  /// Bölgenin alt sınırı, azami nabzın oranı olarak.
  final double lower;

  /// Bölgenin üst sınırı; son bölgede null.
  double? get upper => this == maximum ? null : values[index + 1].lower;

  /// [maxHr] için bölgenin atım/dk aralığı; son bölgenin üstü açıktır.
  (int, int?) bpmRange(int maxHr) => (
    (lower * maxHr).round(),
    upper == null ? null : (upper! * maxHr).round() - 1,
  );

  /// Nabzın düştüğü bölge; %50'nin altı (dinlenme) null.
  static HeartRateZone? of(double bpm, int maxHr) {
    final r = bpm / maxHr;
    if (r < warmUp.lower) return null;
    for (final z in values.reversed) {
      if (r >= z.lower) return z;
    }
    return null;
  }
}

/// Azami nabız tahmini: 208 − 0,7 × yaş (Tanaka, 2001). VO2 Max tahmini de
/// aynı formülü kullanır.
int maxHeartRate(int age) => (208 - 0.7 * age).round();

/// Ölçümler arasındaki boşluk bundan uzunsa bileklik takılı değildi
/// sayılır; o aralık hiçbir bölgeye yazılmaz.
const _maxZoneGap = Duration(minutes: 10);

/// Her bölgede geçen süre. Her ölçüm, bir sonraki ölçüme kadar (en çok
/// 10 dk) sürmüş sayılır; son ölçüm ölçümler arasındaki tipik süre kadar.
/// [hr] zamana göre sıralı olmalı.
Map<HeartRateZone, Duration> zoneDurations(List<Measurement> hr, int maxHr) {
  final out = {for (final z in HeartRateZone.values) z: Duration.zero};
  if (hr.isEmpty) return out;
  final gaps = <Duration>[
    for (var i = 1; i < hr.length; i++) hr[i].time.difference(hr[i - 1].time),
  ]..sort();
  final typical = gaps.isEmpty
      ? const Duration(minutes: 1)
      : gaps[gaps.length ~/ 2];
  for (var i = 0; i < hr.length; i++) {
    final m = hr[i];
    if (m.value <= 0) continue;
    final z = HeartRateZone.of(m.value, maxHr);
    if (z == null) continue;
    var span = i + 1 < hr.length ? hr[i + 1].time.difference(m.time) : typical;
    if (span > _maxZoneGap) span = _maxZoneGap;
    out[z] = out[z]! + span;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Vücut ısısı sapması
// ---------------------------------------------------------------------------

/// Kişinin kendi temel ısısı: ısı ölçümü olan ilk 7 günün günlük
/// ortalamalarının ortalaması. Bilekten ölçülen ısı kişiden kişiye
/// değiştiği için grafik ham değeri değil bu temele göre farkı gösterir.
class TemperatureBaseline {
  const TemperatureBaseline({
    required this.value,
    required this.days,
    required this.from,
    required this.to,
  });

  /// °C.
  final double value;

  /// Temele giren gün sayısı (en az [minBaselineDays], en çok 7).
  final int days;

  /// Temele giren ilk ve son gün.
  final DateTime from;
  final DateTime to;

  /// Temelin oluşması için gereken en az gün sayısı.
  static const minBaselineDays = 3;

  /// Verisi olan ilk [days] günden temel; [minBaselineDays] günden az veri
  /// varsa null. [now] sonrası hesaba girmez.
  static TemperatureBaseline? of(
    HealthStore store,
    DateTime now, {
    int days = 7,
  }) {
    final daily = _dailyAverages(
      store.measurements(MetricType.temperature, DateTime(2000), now),
    );
    if (daily.length < minBaselineDays) return null;
    final first = daily.entries.take(days).toList();
    return TemperatureBaseline(
      value: first.map((e) => e.value).reduce((a, b) => a + b) / first.length,
      days: first.length,
      from: first.first.key,
      to: first.last.key,
    );
  }
}

/// Günlük ortalamalar, günlere göre sıralı. Sıfır ve olanaksız değerler
/// (bileklik takılı değilken gelen) atılır.
Map<DateTime, double> _dailyAverages(List<Measurement> items) {
  final sums = <DateTime, (double, int)>{};
  for (final m in items) {
    if (m.value < 30 || m.value > 43) continue;
    final d = DateTime(m.time.year, m.time.month, m.time.day);
    final (s, n) = sums[d] ?? (0.0, 0);
    sums[d] = (s + m.value, n + 1);
  }
  final keys = sums.keys.toList()..sort();
  return {for (final k in keys) k: sums[k]!.$1 / sums[k]!.$2};
}

/// Dönemin her sütunu için temele göre fark (°C); verisi olmayan sütun null.
List<double?> temperatureDeviation(
  HealthStore store,
  PeriodRange range,
  TemperatureBaseline baseline,
) {
  final items = [
    for (final m in store.measurements(
      MetricType.temperature,
      range.start,
      range.end,
    ))
      if (m.value >= 30 && m.value <= 43) m,
  ];
  return [
    for (final v in aggregate(items, range, MetricType.temperature))
      v == null ? null : v - baseline.value,
  ];
}

// ---------------------------------------------------------------------------
// Biyolojik yaş
// ---------------------------------------------------------------------------

/// Biyolojik yaşa katkı veren etkenler.
enum AgeFactor { restingHeartRate, steps, sleep, bmi }

/// Bir etkenin katkısı: ölçülen değer ve yıl olarak etkisi (eksi gençleştirir).
class AgeContribution {
  const AgeContribution(this.factor, this.value, this.years);

  final AgeFactor factor;

  /// Dinlenik nabız atım/dk, günlük adım, gece uykusu dakika ya da VKİ.
  final double value;
  final double years;
}

/// Biyolojik yaş: takvim yaşına son 21 günün dinlenik nabzı, adımı, uykusu
/// ve (girildiyse) VKİ'sinden gelen katkıların eklenmesi. Toplam katkı
/// ±10 yılla sınırlıdır. Uygulamanın kendi tahminidir; tıbbi değildir.
class BiologicalAge {
  const BiologicalAge({
    required this.age,
    required this.chronologicalAge,
    required this.contributions,
    required this.daysWithData,
    required this.day,
  });

  /// Yuvarlanmış biyolojik yaş.
  final int age;
  final int chronologicalAge;
  final List<AgeContribution> contributions;

  /// Penceredeki verisi olan gün sayısı.
  final int daysWithData;

  /// Pencerenin son günü.
  final DateTime day;

  /// Takvim yaşına göre fark; eksi daha genç demektir.
  int get difference => age - chronologicalAge;

  /// Kayan pencerenin uzunluğu.
  static const window = 21;

  /// Hesap için pencerede en az bu kadar gün verisi gerekir.
  static const minDays = 7;

  /// [day] gününe biten 21 günlük pencereden; yaş bilinmiyorsa, yeterli gün
  /// yoksa ya da ikiden az etken hesaplanabiliyorsa null.
  static BiologicalAge? of(HealthStore store, DateTime day, int age) {
    if (age < 18 || age > 90) return null;
    final end = DateTime(day.year, day.month, day.day + 1);
    final start = DateTime(day.year, day.month, day.day - window + 1);

    final stepsByDay = <DateTime, double>{};
    for (final m in store.measurements(MetricType.steps, start, end)) {
      final d = DateTime(m.time.year, m.time.month, m.time.day);
      stepsByDay.update(d, (v) => v + m.value, ifAbsent: () => m.value);
    }
    final hrDays = {
      for (final m in store.measurements(MetricType.heartRate, start, end))
        if (m.value > 0) DateTime(m.time.year, m.time.month, m.time.day),
    };
    final days = {
      ...hrDays,
      for (final e in stepsByDay.entries)
        if (e.value > 0) e.key,
    };
    if (days.length < minDays) return null;

    final out = <AgeContribution>[];
    final resting = restingHeartRate(
      store,
      end.subtract(const Duration(milliseconds: 1)),
      days: window,
    );
    if (resting != null) {
      // 62 atım/dk olağan; her 4 atım bir yıl.
      out.add(
        AgeContribution(
          AgeFactor.restingHeartRate,
          resting.toDouble(),
          ((resting - 62) / 4).clamp(-3, 4).toDouble(),
        ),
      );
    }
    final stepDays = [
      for (final v in stepsByDay.values)
        if (v > 0) v,
    ];
    if (stepDays.length >= minDays) {
      final avg = stepDays.reduce((a, b) => a + b) / stepDays.length;
      // 7000 adım olağan; her 2000 adım bir yıl.
      out.add(
        AgeContribution(
          AgeFactor.steps,
          avg,
          ((7000 - avg) / 2000).clamp(-2, 3).toDouble(),
        ),
      );
    }
    final nights = [
      for (final n in NightSleep.group(
        store.sleepBetween(start.subtract(const Duration(hours: 12)), end),
      ))
        if (!n.day.isBefore(start) &&
            n.day.isBefore(end) &&
            n.asleepMinutes > 0)
          n.asleepMinutes.toDouble(),
    ];
    if (nights.length >= minDays) {
      final avg = nights.reduce((a, b) => a + b) / nights.length;
      final hours = avg / 60;
      // 7–9 saat bir yıl gençleştirir; dışında kalan her saat 1,5 yıl.
      final off = hours < 7 ? 7 - hours : (hours > 9 ? hours - 9 : 0.0);
      out.add(
        AgeContribution(
          AgeFactor.sleep,
          avg,
          off == 0 ? -1 : min(off * 1.5, 3).toDouble(),
        ),
      );
    }
    final bmi = store.measurements(MetricType.bmi, DateTime(2000), end);
    if (bmi.isNotEmpty) {
      final v = bmi.last.value;
      final years = v < 18.5
          ? 1.0
          : v <= 25
          ? 0.0
          : ((v - 25) / 2.5).clamp(0, 3).toDouble();
      out.add(AgeContribution(AgeFactor.bmi, v, years));
    }
    if (out.length < 2) return null;
    final total = out.fold(0.0, (s, c) => s + c.years).clamp(-10.0, 10.0);
    return BiologicalAge(
      age: (age + total).round(),
      chronologicalAge: age,
      contributions: out,
      daysWithData: days.length,
      day: DateTime(day.year, day.month, day.day),
    );
  }

  /// Son [weeks] haftanın her birinin son gününde hesaplanan biyolojik
  /// yaş; eskiden yeniye. Hesaplanamayan hafta null.
  static List<BiologicalAge?> trend(
    HealthStore store,
    DateTime day,
    int age, {
    int weeks = 8,
  }) => [
    for (var w = weeks - 1; w >= 0; w--)
      of(store, DateTime(day.year, day.month, day.day - 7 * w), age),
  ];
}

// ---------------------------------------------------------------------------
// Sağlık Radarı
// ---------------------------------------------------------------------------

/// Kişinin kendi olağanından sapan gece değerleri.
enum RadarSignal {
  /// Gece nabzı olağandan en az 7 atım/dk yüksek.
  heartRateUp,

  /// Gece HRV'si olağanın %75'inin altında.
  hrvDown,

  /// Gece vücut ısısı olağandan en az 0,5 °C yüksek.
  temperatureUp,

  /// Gece SpO2 ortalaması olağandan en az 3 puan düşük.
  spo2Down,
}

/// Bir sapma: o gecenin değeri ve son 14 gecenin ortancası.
class RadarFinding {
  const RadarFinding(this.signal, this.value, this.baseline);

  final RadarSignal signal;
  final double value;
  final double baseline;

  double get delta => value - baseline;
}

/// [day] sabahına biten geceyi son 14 geceyle karşılaştırır. Belirti
/// ortaya çıkmadan önce vücudun verdiği işaretleri (yükselen gece nabzı,
/// düşen HRV, yükselen ısı, düşen oksijen) kişinin kendi olağanına göre
/// yakalamayı amaçlar. Tanı koymaz.
class HealthRadar {
  const HealthRadar({
    required this.day,
    required this.findings,
    required this.baselineNights,
    required this.hasTonight,
  });

  final DateTime day;
  final List<RadarFinding> findings;

  /// Son 14 gecenin kaçında karşılaştırılabilir veri var.
  final int baselineNights;

  /// O gecenin verisi var mı.
  final bool hasTonight;

  /// Karşılaştırma için gereken en az gece.
  static const minNights = 5;

  static const lookback = 14;

  /// Temel oluştu ve o gecenin verisi var.
  bool get ready => baselineNights >= minNights && hasTonight;

  /// İki ya da daha çok işaret birlikteyse dinlenme önerilir.
  bool get strong => findings.length >= 2;

  static HealthRadar of(HealthStore store, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final tonight = _nightValues(store, d);
    final past = [
      for (var i = 1; i <= lookback; i++)
        _nightValues(store, DateTime(d.year, d.month, d.day - i)),
    ];
    final findings = <RadarFinding>[];

    void check(
      RadarSignal signal,
      double? Function(_Night) pick,
      bool Function(double value, double base) off,
    ) {
      final v = pick(tonight);
      if (v == null) return;
      final base = _median([for (final n in past) ?pick(n)]);
      if (base == null) return;
      final count = past.where((n) => pick(n) != null).length;
      if (count < minNights) return;
      if (off(v, base)) findings.add(RadarFinding(signal, v, base));
    }

    check(RadarSignal.heartRateUp, (n) => n.heartRate, (v, b) => v - b >= 7);
    check(RadarSignal.hrvDown, (n) => n.hrv, (v, b) => v <= b * 0.75);
    check(
      RadarSignal.temperatureUp,
      (n) => n.temperature,
      (v, b) => v - b >= 0.5,
    );
    check(RadarSignal.spo2Down, (n) => n.spo2, (v, b) => b - v >= 3);

    return HealthRadar(
      day: d,
      findings: findings,
      baselineNights: past.where((n) => !n.isEmpty).length,
      hasTonight: !tonight.isEmpty,
    );
  }
}

/// Bir gecenin karşılaştırılan değerleri.
class _Night {
  const _Night(this.heartRate, this.hrv, this.temperature, this.spo2);

  final double? heartRate;
  final double? hrv;
  final double? temperature;
  final double? spo2;

  bool get isEmpty =>
      heartRate == null && hrv == null && temperature == null && spo2 == null;
}

/// Uyku kaydı varsa uyku süresince, yoksa gece penceresinde (önceki gün
/// 22:00 – o gün 07:00) ortalamalar.
_Night _nightValues(HealthStore store, DateTime day) {
  final n = NightSleep.group(
    store.sleepBetween(
      day.subtract(const Duration(hours: 12)),
      day.add(const Duration(days: 1)),
    ),
  ).where((x) => x.day == day).lastOrNull;
  final (from, to) = n != null
      ? (n.start, n.end)
      : (
          DateTime(day.year, day.month, day.day - 1, 22),
          DateTime(day.year, day.month, day.day, 7),
        );
  double? avg(MetricType t, {double lo = 1, double hi = double.infinity}) =>
      Stats.of([
        for (final m in store.measurements(t, from, to))
          if (m.value >= lo && m.value <= hi) m.value,
      ])?.average;
  return _Night(
    avg(MetricType.heartRate, lo: 30, hi: 200) ??
        nightHrv(store, day)?.meanHeartRate,
    avg(MetricType.hrv),
    avg(MetricType.temperature, lo: 30, hi: 43),
    avg(MetricType.spo2, lo: 70, hi: 100),
  );
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final v = [...values]..sort();
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}
