import 'dart:math';

import 'health_store.dart';
import 'models.dart';

/// Atımdan atıma aralıklardan (PPI) hesaplanan kalp hızı değişkenliği.
class HrvStats {
  const HrvStats({
    required this.beats,
    required this.meanRr,
    required this.sdnn,
    required this.rmssd,
    required this.pnn50,
  });

  /// Hesaba giren (geçerli) aralık sayısı.
  final int beats;

  /// Ortalama aralık, ms.
  final double meanRr;

  /// Aralıkların standart sapması, ms.
  final double sdnn;

  /// Ardışık farkların karelerinin ortalamasının karekökü, ms.
  final double rmssd;

  /// Ardışık farkı 50 ms'den büyük olanların yüzdesi (0–100).
  final double pnn50;

  /// Ortalama nabız (atım/dk).
  double get meanHeartRate => 60000 / meanRr;
}

/// En az bu kadar geçerli aralık ve ardışık fark yoksa sonuç verilmez.
const minBeats = 20;
const minPairs = 10;

/// [beats]: zamana göre sıralı PPI ölçümleri (zaman = atımın bittiği an,
/// değer = aralık ms). Bileklik PPI'ı kısa pencerelerde ölçer; aralarındaki
/// boşluklar ardışık sayılmaz.
///
/// Ayıklama: 300–2000 ms dışındaki aralıklar ve bir öncekinden %20'den fazla
/// sapanlar (kaçırılan ya da fazladan algılanan atım) atılır.
HrvStats? analyzePpi(List<Measurement> beats) {
  final rr = <double>[];
  final diffs = <double>[];
  Measurement? prev;
  for (final b in beats) {
    final ms = b.value;
    final p = prev;
    // Önceki atımdan bu atıma geçen süre bu aralığa yakınsa ardışıktır.
    final linked =
        p != null &&
        (b.time.difference(p.time).inMilliseconds - ms).abs() <= 300;
    if (ms < 300 || ms > 2000) {
      prev = null;
      continue;
    }
    if (p != null && linked && (ms - p.value).abs() > p.value * 0.2) {
      // Sıçrama: bu atım ayıklanır, zincir de kopar.
      prev = null;
      continue;
    }
    rr.add(ms);
    if (p != null && linked) diffs.add(ms - p.value);
    prev = b;
  }
  if (rr.length < minBeats || diffs.length < minPairs) return null;
  final mean = rr.reduce((a, b) => a + b) / rr.length;
  final variance =
      rr.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
      rr.length;
  final meanSquare = diffs.map((d) => d * d).reduce((a, b) => a + b) / diffs.length;
  return HrvStats(
    beats: rr.length,
    meanRr: mean,
    sdnn: sqrt(variance),
    rmssd: sqrt(meanSquare),
    pnn50: 100 * diffs.where((d) => d.abs() > 50).length / diffs.length,
  );
}

/// Bir gecenin penceresi: önceki gün 18:00'den o gün 12:00'ye.
(DateTime, DateTime) nightWindow(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return (d.subtract(const Duration(hours: 6)), d.add(const Duration(hours: 12)));
}

/// [day] sabahına biten gecenin HRV'si; yeterli veri yoksa null.
HrvStats? nightHrv(HealthStore store, DateTime day) {
  final (from, to) = nightWindow(day);
  return analyzePpi(store.measurements(MetricType.ppi, from, to));
}

/// Son [days] gece içinde verisi olan en yeni gece.
({DateTime day, HrvStats stats})? latestNightHrv(
  HealthStore store,
  DateTime now, {
  int days = 7,
}) {
  for (var ago = 0; ago < days; ago++) {
    final day = DateTime(now.year, now.month, now.day - ago);
    if (nightHrv(store, day) case final s?) return (day: day, stats: s);
  }
  return null;
}

/// Dinlenik nabız: son [days] gecenin PPI'ından hesaplanan ortalama
/// nabızların ortancası. PPI yoksa aynı dönemdeki nabız ölçümlerinin alt
/// %10'luk dilimi. Veri yoksa null.
int? restingHeartRate(HealthStore store, DateTime now, {int days = 7}) {
  final nightly = <double>[];
  for (var ago = 0; ago < days; ago++) {
    final s = nightHrv(store, DateTime(now.year, now.month, now.day - ago));
    if (s != null) nightly.add(s.meanHeartRate);
  }
  if (nightly.isNotEmpty) {
    nightly.sort();
    return nightly[nightly.length ~/ 2].round();
  }
  final hr = [
    for (final m in store.measurements(
      MetricType.heartRate,
      now.subtract(Duration(days: days)),
      now,
    ))
      if (m.value > 0) m.value,
  ]..sort();
  if (hr.length < 10) return null;
  return hr[hr.length ~/ 10].round();
}

/// VO2 Max tahmini (ml/kg/dk): Uth ve ark. (2004) oranı
/// `15,3 × HRmax / HRdinlenik`, HRmax = 208 − 0,7 × yaş (Tanaka, 2001).
///
/// Laboratuvar ölçümü değildir; yalnızca eğilimi izlemek için. Girdiler
/// makul aralıkta değilse null.
double? estimateVo2Max({required int age, required int restingHeartRate}) {
  if (age < 13 || age > 90) return null;
  if (restingHeartRate < 35 || restingHeartRate > 110) return null;
  final hrMax = 208 - 0.7 * age;
  final v = 15.3 * hrMax / restingHeartRate;
  return (v * 10).round() / 10;
}
