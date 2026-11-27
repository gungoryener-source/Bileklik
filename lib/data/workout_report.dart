import 'dart:math';

import 'health_store.dart';
import 'hrv_analysis.dart' as hrv_analysis;
import 'insights.dart';
import 'models.dart';
import 'recovery.dart';
import 'strain.dart';

/// Egzersizin metabolik yoğunluğu (MET'e göre).
enum MetIntensity {
  /// 3 MET altı.
  light,

  /// 3–6 MET.
  moderate,

  /// 6 MET ve üstü.
  vigorous;

  static MetIntensity of(double met) => met < 3
      ? light
      : met < 6
      ? moderate
      : vigorous;
}

/// Bir egzersizin raporu: egzersiz yükü (0–21), metabolik eşdeğer (MET),
/// o günün toparlanması, nabız aralığı ve bölgelere dağılım. Yük, günlük
/// yükle aynı TRIMP benzeri hesaptır. Uygulamanın kendi tahminidir, tıbbi
/// değildir.
class WorkoutReport {
  const WorkoutReport({
    required this.workout,
    required this.heartRate,
    required this.load,
    this.averageHeartRate,
    this.peakHeartRate,
    this.lowHeartRate,
    this.met,
    this.recovery,
    this.zoneMaxHr,
    this.zones = const {},
  });

  final Workout workout;

  /// Egzersiz süresindeki nabız ölçümleri, zamana göre sıralı.
  final List<Measurement> heartRate;

  /// Egzersiz yükü 0–21, bir ondalık.
  final double load;
  final int? averageHeartRate;
  final int? peakHeartRate;
  final int? lowHeartRate;

  /// Metabolik eşdeğer; hesaplanamıyorsa null.
  final double? met;

  /// Egzersiz gününün toparlanması; bilinmiyorsa null.
  final DayRecovery? recovery;

  /// Bölgelerin hesaplandığı azami nabız; yaş bilinmiyorsa null.
  final int? zoneMaxHr;

  /// Bölgelerde geçen süre; yaş bilinmiyorsa boş.
  final Map<HeartRateZone, Duration> zones;

  MetIntensity? get intensity => met == null ? null : MetIntensity.of(met!);

  /// MET göstergesinin üst sınırı.
  static const metMax = 12.0;

  /// Bölgelerde geçen toplam süre.
  Duration get zonedTime => zones.values.fold(Duration.zero, (a, b) => a + b);

  /// [age] verilirse bölgeler ve yük yaşa göre azami nabızla hesaplanır;
  /// yoksa yük için 190 alınır, bölgeler boş kalır. [weightKg] MET için;
  /// yoksa 70 kg varsayılır.
  static WorkoutReport of(
    HealthStore store,
    Workout w, {
    int? age,
    int? weightKg,
  }) {
    final hr = [
      for (final m in store.measurements(MetricType.heartRate, w.start, w.end))
        if (m.value > 0) m,
    ]..sort((a, b) => a.time.compareTo(b.time));
    final values = [for (final m in hr) m.value];
    final avg = w.averageHeartRate > 0
        ? w.averageHeartRate
        : values.isEmpty
        ? null
        : (values.reduce((a, b) => a + b) / values.length).round();
    final maxBpm = values.isEmpty ? avg : values.reduce(max).round();
    final minBpm = values.isEmpty ? avg : values.reduce(min).round();

    final rest = hrv_analysis.restingHeartRate(store, w.start, days: 7) ?? 60;
    final hrMax = age == null ? 190 : maxHeartRate(age);
    double reserve(num bpm) =>
        hrMax <= rest ? 0 : (bpm - rest) / (hrMax - rest);

    // Ölçüm varsa her ölçüm bir sonrakine kadar (en çok 5 dk) sürmüş
    // sayılır; yoksa egzersizin ortalama nabzı tüm süreye yayılır.
    var trimp = 0.0;
    if (hr.length >= 2) {
      for (var i = 0; i < hr.length; i++) {
        final next = i + 1 < hr.length ? hr[i + 1].time : w.end;
        final minutes = min(next.difference(hr[i].time).inSeconds / 60, 5.0);
        trimp += minutes * DayStrain.trimp(reserve(hr[i].value));
      }
    } else if (avg != null) {
      trimp = w.duration.inSeconds / 60 * DayStrain.trimp(reserve(avg));
    }
    final load = (DayStrain.scale(trimp) * 10).round() / 10;

    // MET: kalori / (kilo × saat). Kalori yoksa nabız yedeğinden kaba
    // tahmin.
    final hours = w.duration.inSeconds / 3600;
    double? met;
    if (hours > 0 && w.calories > 0) {
      met = w.calories / ((weightKg ?? 70) * hours);
    } else if (avg != null) {
      met = 1 + 10 * reserve(avg).clamp(0, 1);
    }
    if (met != null) met = (met.clamp(1, metMax) * 10).round() / 10;

    return WorkoutReport(
      workout: w,
      heartRate: hr,
      load: load,
      averageHeartRate: avg,
      peakHeartRate: maxBpm,
      lowHeartRate: minBpm,
      met: met,
      recovery: DayRecovery.of(store, w.start),
      zoneMaxHr: age == null ? null : hrMax,
      zones: age == null || hr.isEmpty ? const {} : zoneDurations(hr, hrMax),
    );
  }
}
