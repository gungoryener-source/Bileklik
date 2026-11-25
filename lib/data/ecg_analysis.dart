import 'dart:math';

/// EKG kaydından kalp atışlarını (R dalgalarını) bulur ve özetler.
///
/// Bu bir tanı aracı değildir; yalnızca nabız ve atımlar arası süreyi verir.
class EcgSummary {
  /// R dalgalarının örnek sırası.
  final List<int> peaks;

  /// Ardışık atımlar arası süreler (ms).
  final List<double> rrMs;
  const EcgSummary(this.peaks, this.rrMs);

  int? get averageHeartRate => rrMs.isEmpty
      ? null
      : (60000 / (rrMs.reduce((a, b) => a + b) / rrMs.length)).round();

  int? get minHeartRate =>
      rrMs.isEmpty ? null : (60000 / rrMs.reduce(max)).round();
  int? get maxHeartRate =>
      rrMs.isEmpty ? null : (60000 / rrMs.reduce(min)).round();

  /// Atımlar arası sürelerin standart sapması (SDNN, ms).
  double? get sdnn {
    if (rrMs.length < 2) return null;
    final mean = rrMs.reduce((a, b) => a + b) / rrMs.length;
    final v =
        rrMs.fold(0.0, (s, x) => s + (x - mean) * (x - mean)) /
        (rrMs.length - 1);
    return sqrt(v);
  }

  static EcgSummary analyze(List<int> samples, int sampleRate) {
    final peaks = detectRPeaks(samples, sampleRate);
    final rr = <double>[];
    for (var i = 1; i < peaks.length; i++) {
      final ms = (peaks[i] - peaks[i - 1]) * 1000 / sampleRate;
      // 30-220 bpm dışındaki aralıklar gürültüdür.
      if (ms >= 270 && ms <= 2000) rr.add(ms);
    }
    return EcgSummary(peaks, rr);
  }
}

/// Basitleştirilmiş Pan-Tompkins: türev, kare, kayan pencere ortalaması ve
/// uyarlanır eşik. 250 ms içinde ikinci atım kabul edilmez.
List<int> detectRPeaks(List<int> samples, int sampleRate) {
  final n = samples.length;
  if (n < sampleRate) return const [];
  final energy = List<double>.filled(n, 0);
  for (var i = 2; i < n; i++) {
    final d = (samples[i] - samples[i - 2]).toDouble();
    energy[i] = d * d;
  }
  final w = max(1, (0.12 * sampleRate).round());
  final integ = List<double>.filled(n, 0);
  var acc = 0.0;
  for (var i = 0; i < n; i++) {
    acc += energy[i];
    if (i >= w) acc -= energy[i - w];
    integ[i] = acc / w;
  }

  final refractory = (0.25 * sampleRate).round();
  final window = 2 * sampleRate;
  final peaks = <int>[];
  var i = 0;
  while (i < n) {
    // Eşik, çevresindeki 2 saniyenin en büyük değerinin yarısı.
    final from = max(0, i - window ~/ 2), to = min(n, i + window ~/ 2);
    var localMax = 0.0;
    for (var j = from; j < to; j++) {
      if (integ[j] > localMax) localMax = integ[j];
    }
    final threshold = localMax * 0.4;
    if (threshold > 0 && integ[i] > threshold) {
      // Eşiği aşan bölgenin sonunu bul, R dalgası ham sinyaldeki en büyük nokta.
      var end = i;
      while (end < n && integ[end] > threshold) {
        end++;
      }
      var best = max(0, i - w);
      for (var j = best; j < end; j++) {
        if (samples[j] > samples[best]) best = j;
      }
      if (peaks.isEmpty || best - peaks.last >= refractory) peaks.add(best);
      i = max(end, best + refractory);
    } else {
      i++;
    }
  }
  return peaks;
}

/// Bir bulgunun sonucu: sorun yok, dikkat gerekiyor ya da kayıt yetersiz.
enum FindingState { ok, flagged, unknown }

/// EKG raporundaki dört bulgu: ritim, yüksek ve düşük kalp hızı, atriyal
/// fibrilasyon belirtisi.
///
/// Uygulamanın otomatik ön değerlendirmesidir, tanı değildir. Eşikler
/// yaygın tarama ölçütlerinden alındı; klinik doğrulaması yapılmadı ve
/// gerçek cihaz kayıtlarıyla ayarlanacak.
class EcgFindings {
  const EcgFindings({
    required this.normalRhythm,
    required this.highRate,
    required this.lowRate,
    required this.afib,
  });

  /// Düzenli ve 50-100 bpm aralığında ritim.
  final FindingState normalRhythm;

  /// Ortalama nabız 100 bpm üstü (taşikardi).
  final FindingState highRate;

  /// Ortalama nabız 50 bpm altı (bradikardi).
  final FindingState lowRate;

  /// Atımlar arası süreler belirgin düzensiz.
  final FindingState afib;

  static const highBpm = 100;
  static const lowBpm = 50;

  /// Değerlendirme için gereken en az atım aralığı.
  static const minIntervals = 5;

  bool get assessable => normalRhythm != FindingState.unknown;

  static const _unknown = EcgFindings(
    normalRhythm: FindingState.unknown,
    highRate: FindingState.unknown,
    lowRate: FindingState.unknown,
    afib: FindingState.unknown,
  );

  static EcgFindings of(EcgSummary s) {
    final rr = s.rrMs;
    final avg = s.averageHeartRate;
    if (rr.length < minIntervals || avg == null) return _unknown;
    final high = avg > highBpm;
    final low = avg < lowBpm;
    final irregular = isIrregular(rr);
    FindingState flag(bool v) => v ? FindingState.flagged : FindingState.ok;
    return EcgFindings(
      normalRhythm: flag(high || low || irregular),
      highRate: flag(high),
      lowRate: flag(low),
      afib: flag(irregular),
    );
  }

  /// Ardışık farkların kareli ortalamasının kökü ortalama aralığa
  /// bölünür (nRMSSD) ve değişkenlik katsayısıyla birlikte bakılır. İkisi
  /// de yüksekse ritim "düzensiz" sayılır. Tek bir erken atım ortalamayı
  /// fazla oynatmasın diye en uç fark atılır.
  static bool isIrregular(List<double> rr) {
    if (rr.length < 8) return false;
    final mean = rr.reduce((a, b) => a + b) / rr.length;
    final diffs = [
      for (var i = 1; i < rr.length; i++) (rr[i] - rr[i - 1]).abs(),
    ]..sort();
    diffs.removeLast();
    final rmssd = sqrt(diffs.fold(0.0, (s, d) => s + d * d) / diffs.length);
    final sd = sqrt(
      rr.fold(0.0, (s, x) => s + (x - mean) * (x - mean)) / (rr.length - 1),
    );
    return rmssd / mean > 0.12 && sd / mean > 0.1;
  }
}
