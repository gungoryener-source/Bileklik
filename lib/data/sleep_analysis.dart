import 'dart:math';

import '../device/protocol/history.dart';
import 'aggregate.dart';
import 'health_store.dart';
import 'models.dart';

/// Uyku skoru 0–100: süre (8 saate göre, 70 puan) ve dinlendirici uykunun
/// (derin + REM) uykudaki payı (%40'a göre, 30 puan). Uyku yoksa null.
int? sleepScoreOf(NightSleep night) {
  final asleep = night.asleepMinutes;
  if (asleep <= 0) return null;
  final restorative =
      night.minutesIn(SleepStage.deep) + night.minutesIn(SleepStage.rem);
  return (min(asleep / 480, 1) * 70 + min(restorative / asleep / 0.4, 1) * 30)
      .round();
}

/// Evrenin gecedeki (uyanıklık dahil) payı için önerilen aralık, yüzde.
/// Yetişkinler için genel tarama değerleridir.
(int, int) idealStageRange(SleepStage s) => switch (s) {
  SleepStage.awake => (0, 5),
  SleepStage.rem => (20, 25),
  SleepStage.light => (45, 55),
  SleepStage.deep => (15, 25),
};

/// Uyku sırasında bir ölçümün değerleri.
class NightSeries {
  const NightSeries(this.points, this.stats);

  final List<Measurement> points;
  final Stats stats;
}

/// Bir gecenin ayrıntılı uyku çözümlemesi: skor, örüntü, evre payları,
/// uyku sırasında nabız/SpO2/HRV ve gündüz şekerlemeleri.
class SleepAnalysis {
  SleepAnalysis._({
    required this.night,
    required this.naps,
    required this.score,
    required this.heartRate,
    required this.spo2,
    required this.hrv,
  });

  /// Ana uyku (şekerlemeler çıkarılmış).
  final NightSleep night;

  /// 10:00–18:00 arasında başlayan, 3 saatten kısa uykular.
  final List<SleepSession> naps;
  final int? score;
  final NightSeries? heartRate;
  final NightSeries? spo2;
  final NightSeries? hrv;

  /// Gecelik uyku ihtiyacı (dakika).
  static const needMinutes = 480;

  DateTime get bedTime => night.start;
  DateTime get wakeTime => night.end;
  int get asleepMinutes => night.asleepMinutes;

  /// Yatıştan kalkışa geçen süre (oturumlar arası boşluklar dahil).
  int get inBedMinutes => night.end.difference(night.start).inMinutes;

  /// Uykudaki sürenin yatakta kalınan süreye oranı, yüzde.
  int get efficiency =>
      inBedMinutes <= 0 ? 0 : min(100, asleepMinutes * 100 ~/ inBedMinutes);

  /// İlk uyku evresine kadar geçen uyanık dakikalar.
  int get latencyMinutes {
    var n = 0;
    for (final m in night.sessions.first.minutes) {
      if (m != SleepStage.awake) break;
      n++;
    }
    return n;
  }

  /// İhtiyaca göre eksik uyku; yeterliyse 0.
  int get debtMinutes => max(0, needMinutes - asleepMinutes);

  int stageMinutes(SleepStage s) => night.minutesIn(s);

  /// Evrenin gecedeki (uyanıklık dahil) payı, yüzde.
  int stagePercent(SleepStage s) {
    final total = asleepMinutes + night.minutesIn(SleepStage.awake);
    return total == 0 ? 0 : (night.minutesIn(s) * 100 / total).round();
  }

  bool stageInRange(SleepStage s) {
    final (lo, hi) = idealStageRange(s);
    final p = stagePercent(s);
    return p >= lo && p <= hi;
  }

  static bool isNap(SleepSession s) =>
      s.start.hour >= 10 && s.start.hour < 18 && s.minutes.length < 180;

  /// [group] bir `NightSleep.group` öğesi. Yalnızca şekerleme varsa null.
  static SleepAnalysis? of(HealthStore store, NightSleep group) {
    final main = [
      for (final s in group.sessions)
        if (!isNap(s)) s,
    ];
    if (main.isEmpty) return null;
    final night = NightSleep(group.day, main);
    NightSeries? series(MetricType type) {
      final pts = [
        for (final m in store.measurements(type, night.start, night.end))
          if (m.value > 0) m,
      ];
      final stats = Stats.of(pts.map((m) => m.value));
      return stats == null ? null : NightSeries(pts, stats);
    }

    return SleepAnalysis._(
      night: night,
      naps: [
        for (final s in group.sessions)
          if (isNap(s)) s,
      ],
      score: sleepScoreOf(night),
      heartRate: series(MetricType.heartRate),
      spo2: series(MetricType.spo2),
      hrv: series(MetricType.hrv),
    );
  }
}
