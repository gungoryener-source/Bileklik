import 'dart:convert';

import '../l10n/app_localizations.dart';
import 'aggregate.dart';
import 'health_store.dart';
import 'insights.dart';
import 'models.dart';
import 'progress.dart';

// ---------------------------------------------------------------------------
// Yapay zeka sağlık raporu
//
// Plan (docs/yapay-zeka-raporu.md): rapor portal sunucusunda Claude API ile
// üretilir; telefon yalnızca [AiReportInput]'u gönderir ve hazır raporu alır.
// Şimdilik API bağlı değil: [DemoAiReportService] aynı girdiden kurallarla
// örnek bir rapor yazar, böylece ekranlar ve rıza akışı denenebilir.
// ---------------------------------------------------------------------------

/// Rapor için sunucuya gidecek veri. İsim, cihaz adresi, ham EKG ya da tek
/// tek ölçümler yoktur; yalnızca yaş aralığı, cinsiyet ve haftalık özetler.
class AiReportInput {
  const AiReportInput({
    required this.ageGroup,
    required this.sex,
    required this.week,
    required this.previousWeek,
    required this.averageHeartRate,
    required this.radar,
    required this.biologicalAgeDifference,
  });

  /// "30-39" gibi on yıllık aralık; yaş bilinmiyorsa null.
  final String? ageGroup;

  /// "male" ya da "female"; bilinmiyorsa null.
  final String? sex;
  final WeekStats week;
  final WeekStats previousWeek;

  /// Haftanın ortalama nabzı (atım/dk).
  final double? averageHeartRate;

  /// Son gecenin Sağlık Radarı işaretleri.
  final List<RadarSignal> radar;

  /// Biyolojik yaşın takvim yaşına farkı (yıl); hesaplanamıyorsa null.
  final int? biologicalAgeDifference;

  /// Haftada hiç veri yoksa rapor yazılmaz.
  bool get isEmpty => week.isEmpty;

  /// [day] gününün haftasından girdi oluşturur.
  static AiReportInput of(
    HealthStore store,
    DateTime day, {
    int? age,
    bool? isMale,
  }) {
    final report = WeeklyReport.of(store, day);
    final w = report.current.range;
    final bio = age == null ? null : BiologicalAge.of(store, day, age);
    final radar = HealthRadar.of(store, day);
    return AiReportInput(
      ageGroup: age == null || age < 18
          ? null
          : '${age ~/ 10 * 10}-${age ~/ 10 * 10 + 9}',
      sex: isMale == null ? null : (isMale ? 'male' : 'female'),
      week: report.current,
      previousWeek: report.previous,
      averageHeartRate: Stats.of(
        store
            .measurements(MetricType.heartRate, w.start, w.end)
            .map((m) => m.value)
            .where((v) => v > 0),
      )?.average,
      radar: radar.ready
          ? [for (final f in radar.findings) f.signal]
          : const [],
      biologicalAgeDifference: bio?.difference,
    );
  }

  static Map<String, Object?> _week(WeekStats s) => {
    'start': _date(s.range.start),
    'days_with_data': s.daysWithData,
    'avg_steps': s.averageSteps,
    'step_goal_days': s.goalDays,
    'avg_sleep_min': s.averageSleepMinutes?.round(),
    'avg_hrv_ms': s.averageHrv?.round(),
    'avg_stress': s.averageStress?.round(),
    'workouts': s.workouts,
    'workout_min': s.workoutMinutes,
  };

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Sunucuya gidecek JSON; kullanıcı ekranda da görür.
  Map<String, Object?> toJson() => {
    'age_group': ageGroup,
    'sex': sex,
    'week': _week(week),
    'previous_week': _week(previousWeek),
    'avg_heart_rate': averageHeartRate?.round(),
    'radar': [for (final s in radar) s.name],
    'biological_age_difference': biologicalAgeDifference,
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Hazır rapor. Bölümler sabittir; uygulama bunları kartlarla gösterir.
class AiReport {
  const AiReport({
    required this.summary,
    required this.wins,
    required this.watch,
    required this.tips,
    required this.createdAt,
    required this.language,
    required this.demo,
  });

  /// Bir iki cümlelik genel değerlendirme.
  final String summary;

  /// İyi gidenler.
  final List<String> wins;

  /// Dikkat edilecekler.
  final List<String> watch;

  /// Koçluk önerileri.
  final List<String> tips;
  final DateTime createdAt;

  /// Raporun yazıldığı dil kodu (tr, en, ar, de).
  final String language;

  /// Kurallarla yazılmış örnek rapor mu (Claude API bağlı değil).
  final bool demo;
}

/// Rapor üreten servis. Gerçeği portal üzerinden Claude API'ye gidecek.
abstract interface class AiReportService {
  /// [input] haftasından [l] dilinde rapor; haftada veri yoksa null.
  Future<AiReport?> generate(AiReportInput input, AppLocalizations l);
}

/// Claude API bağlanana kadar kullanılan örnek rapor yazarı. Aynı girdiden
/// basit kurallarla, tanı koymayan ve ilaç önermeyen metin üretir.
class DemoAiReportService implements AiReportService {
  const DemoAiReportService({
    this.delay = const Duration(milliseconds: 1200),
    this.now,
  });

  /// Sunucuya gidip gelmeyi taklit eden bekleme.
  final Duration delay;

  /// Raporun zamanı (testte sabit).
  final DateTime Function()? now;

  /// Her bölümde en çok bu kadar madde.
  static const maxItems = 3;

  @override
  Future<AiReport?> generate(AiReportInput input, AppLocalizations l) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return write(input, l, (now ?? DateTime.now)());
  }

  /// Beklemesiz yazım; testler ve önizleme için.
  static AiReport? write(AiReportInput input, AppLocalizations l, DateTime at) {
    if (input.isEmpty) return null;
    final w = input.week;
    final p = input.previousWeek;
    final wins = <String>[];
    final watch = <String>[];
    final tips = <String>[];

    int? change(num? now, num? before) =>
        now == null || before == null || before == 0
        ? null
        : ((now - before) / before * 100).round();

    // Adım.
    final steps = w.averageSteps;
    if (steps != null) {
      final c = change(steps, p.averageSteps);
      if (steps >= dailyStepGoal) {
        wins.add(l.aiStepsGood(steps));
      } else if (steps < 6000) {
        watch.add(l.aiStepsLow(steps));
        tips.add(l.aiTipWalk);
      }
      if (c != null && c >= 10) wins.add(l.aiStepsUp(c));
      if (c != null && c <= -15) watch.add(l.aiStepsDown(-c));
    }

    // Uyku.
    final sleep = w.averageSleepMinutes;
    if (sleep != null) {
      final h = sleep ~/ 60;
      final m = (sleep % 60).round();
      if (sleep >= 420) {
        wins.add(l.aiSleepGood(h, m));
      } else if (sleep < 360) {
        watch.add(l.aiSleepShort(h, m));
        tips.add(l.aiTipSleep);
      }
    }

    // HRV ve stres.
    final hrv = change(w.averageHrv, p.averageHrv);
    if (hrv != null && hrv >= 10) wins.add(l.aiHrvUp(hrv));
    if (hrv != null && hrv <= -10) {
      watch.add(l.aiHrvDown(-hrv));
      tips.add(l.aiTipRecover);
    }
    final stress = w.averageStress;
    if (stress != null && stress >= 60) {
      watch.add(l.aiStressHigh(stress.round()));
      tips.add(l.aiTipBreathe);
    }

    // Egzersiz.
    if (w.workouts >= 3) {
      wins.add(l.aiWorkoutsGood(w.workouts, w.workoutMinutes));
    } else if (w.workoutMinutes < 150) {
      tips.add(l.aiTipMove);
    }

    // Sağlık Radarı ve biyolojik yaş.
    if (input.radar.isNotEmpty) {
      watch.insert(0, l.aiRadar);
      tips.insert(0, l.aiTipRadar);
    }
    final bio = input.biologicalAgeDifference;
    if (bio != null && bio < 0) wins.add(l.aiBioYounger(-bio));
    if (bio != null && bio > 0) watch.add(l.aiBioOlder(bio));

    if (tips.isEmpty) tips.add(l.aiTipKeep);

    final summary = w.daysWithData < 4
        ? l.aiSummaryFewDays(w.daysWithData)
        : watch.isEmpty
        ? l.aiSummaryGood
        : wins.length >= watch.length
        ? l.aiSummaryMixed
        : l.aiSummaryCare;

    List<String> top(List<String> items) => items.take(maxItems).toList();
    return AiReport(
      summary: summary,
      wins: top(wins),
      watch: top(watch),
      tips: top(tips),
      createdAt: at,
      language: l.localeName,
      demo: true,
    );
  }
}
