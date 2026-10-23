/// Hekim raporunun hesapları: bir dönemdeki ölçümlerden özet, günlük
/// değerler, tansiyon sınıfları, uyku evreleri, egzersiz ve EKG listeleri ile
/// eşiğe dayalı "dikkat çeken bulgular".
///
/// Burada yalnızca sayılar üretilir; metin ve HTML `panel_report.dart`'ta.
/// Girdiler zaten rızaya göre süzülmüş olmalıdır.
library;

import 'dart:math';

import 'model.dart';

/// Raporda yer alan ölçümler, uygulamanın ürettiği her tür.
enum ReportMetric {
  heartRate('8867-4', ShareScope.heartRate, MetricKind.average, 'bpm'),
  hrv('80404-7', ShareScope.heartRate, MetricKind.average, 'ms'),
  spo2('59408-5', ShareScope.spo2, MetricKind.average, 'pct'),
  respiration('9279-1', ShareScope.respiration, MetricKind.average, 'perMin'),
  temperature('8310-5', ShareScope.temperature, MetricKind.average, 'cel'),
  stress('stress', ShareScope.stress, MetricKind.average, 'score'),
  bloodPressure(
    '85354-9',
    ShareScope.bloodPressure,
    MetricKind.bloodPressure,
    'mmHg',
  ),
  sleep('93832-4', ShareScope.sleep, MetricKind.sleep, 'min'),
  steps('55423-8', ShareScope.activity, MetricKind.total, 'steps'),
  distance('55430-3', ShareScope.activity, MetricKind.total, 'km'),
  calories('41981-2', ShareScope.activity, MetricKind.total, 'kcal'),
  workouts('workout', ShareScope.activity, MetricKind.list, 'min'),
  ecg('11524-6', ShareScope.ecg, MetricKind.list, 'bpm'),
  weight('29463-7', ShareScope.body, MetricKind.average, 'kg'),
  bmi('39156-5', ShareScope.body, MetricKind.average, 'kgm2'),
  bodyFat('41982-0', ShareScope.body, MetricKind.average, 'pct'),
  muscleMass('muscle-mass', ShareScope.body, MetricKind.average, 'kg');

  const ReportMetric(this.code, this.scope, this.kind, this.unit);

  /// Observation kodu (LOINC ya da yerel).
  final String code;
  final ShareScope scope;
  final MetricKind kind;

  /// Birim anahtarı (`ClinicText` içinde `u.<anahtar>`).
  final String unit;

  static ReportMetric? byCode(String code) {
    for (final m in values) {
      if (m.code == code) return m;
    }
    return null;
  }
}

enum MetricKind {
  /// Tek tek okumaların ortalaması alınır (nabız, SpO2, kilo...).
  average,

  /// Gün içinde toplanır (adım, mesafe, kalori).
  total,
  bloodPressure,
  sleep,

  /// Tek tek listelenir (egzersiz, EKG).
  list,
}

/// Bir günün değerleri. Toplanan türlerde [total], diğerlerinde
/// [min]/[mean]/[max] anlamlıdır.
class DayValue {
  const DayValue(
    this.day,
    this.count,
    this.min,
    this.mean,
    this.max,
    this.total,
  );

  /// Yerel gün (saat 00:00).
  final DateTime day;
  final int count;
  final double min, mean, max, total;

  /// Grafik ve tablodaki değer.
  double value(MetricKind kind) => kind == MetricKind.total ? total : mean;
}

/// Bir ölçüm türünün dönem özeti.
class SeriesStats {
  const SeriesStats({
    required this.count,
    required this.min,
    required this.max,
    required this.mean,
    required this.latest,
    required this.latestAt,
    required this.days,
    this.change,
  });

  /// Okuma sayısı.
  final int count;

  /// Toplanan türlerde günlük toplamların en düşüğü, en yükseği ve
  /// ortalaması; diğerlerinde tek okumaların.
  final double min, max, mean;

  /// Son okuma (toplanan türlerde son günün toplamı).
  final double latest;
  final DateTime latestAt;
  final List<DayValue> days;

  /// Dönemin ikinci yarısının ortalaması eksi ilk yarısının; en az 4 gün
  /// veri yoksa null.
  final double? change;
}

/// ESC/ESH 2018 sınıfları. Bileklik tahmini olduğu için yalnızca eğilim.
enum BpCategory {
  optimal,
  normal,
  highNormal,
  grade1,
  grade2,
  grade3;

  static BpCategory of(double sys, double dia) {
    if (sys >= 180 || dia >= 110) return grade3;
    if (sys >= 160 || dia >= 100) return grade2;
    if (sys >= 140 || dia >= 90) return grade1;
    if (sys >= 130 || dia >= 85) return highNormal;
    if (sys >= 120 || dia >= 80) return normal;
    return optimal;
  }
}

class BpStats {
  const BpStats(this.systolic, this.diastolic, this.categories);

  final SeriesStats systolic;
  final SeriesStats diastolic;
  final Map<BpCategory, int> categories;
}

class SleepNight {
  const SleepNight(this.start, this.end, this.asleep, this.stages);

  final DateTime start;
  final DateTime? end;

  /// Uykuda geçen dakika.
  final double asleep;

  /// `deep`, `light`, `rem`, `awake` evrelerinin dakikaları.
  final Map<String, double> stages;
}

class SleepStats {
  const SleepStats(this.nights, this.duration, this.stageMeans);

  final List<SleepNight> nights;

  /// Gece başına uyku süresi (dakika).
  final SeriesStats duration;

  /// Evrelerin gece başına ortalama dakikası.
  final Map<String, double> stageMeans;
}

class WorkoutEntry {
  const WorkoutEntry({
    required this.start,
    required this.type,
    this.minutes,
    this.steps,
    this.distanceKm,
    this.calories,
    this.averageHeartRate,
  });

  final DateTime start;

  /// Uygulamanın spor türü adı (ör. `running`); bilinmiyorsa null.
  final String? type;
  final double? minutes, steps, distanceKm, calories, averageHeartRate;
}

class EcgEntry {
  const EcgEntry(this.start, this.seconds, this.averageHeartRate, this.sdnn);

  final DateTime start;
  final double? seconds, averageHeartRate, sdnn;
}

/// Eşiğe dayalı bulgu türleri. Tanı değildir.
enum FindingKind {
  tachycardia,
  bradycardia,
  lowSpo2,
  hypertension,
  fever,
  tachypnea,
  shortSleep,
  lowActivity,
  weightChange,
  dataGaps,
}

class Finding {
  const Finding(this.kind, {this.n, this.total, this.value});

  final FindingKind kind;
  final int? n, total;
  final double? value;

  /// Oran (yüzde, tam sayı).
  int get percent =>
      total == null || total == 0 ? 0 : (n! * 100 / total!).round();
}

/// Bir hastanın [from]–[to] dönemi için rapor.
class PatientReport {
  PatientReport._({
    required this.from,
    required this.to,
    required this.periodDays,
    required this.observationCount,
    required this.series,
    required this.bp,
    required this.sleep,
    required this.workouts,
    required this.ecgs,
    required this.restingHeartRate,
    required this.vo2max,
    required this.daysWithData,
    required this.findings,
  });

  final DateTime from, to;
  final int periodDays;
  final int observationCount;

  /// Ortalaması ya da günlük toplamı alınan türler.
  final Map<ReportMetric, SeriesStats> series;
  final BpStats? bp;
  final SleepStats? sleep;
  final List<WorkoutEntry> workouts;
  final List<EcgEntry> ecgs;

  /// Nabız okumalarının 10. yüzdeliği (uygulamadaki yöntem).
  final int? restingHeartRate;

  /// Yaş ve dinlenik nabızdan tahmin; yaş bilinmiyorsa null.
  final double? vo2max;
  final int daysWithData;
  final List<Finding> findings;

  /// Herhangi bir veri var mı?
  bool get isEmpty => observationCount == 0;

  /// Bulgu eşikleri; raporda da yazılır.
  static const tachycardiaAbove = 100.0;
  static const bradycardiaBelow = 50.0;
  static const lowSpo2Below = 90.0;
  static const feverFrom = 38.0;
  static const tachypneaAbove = 20.0;
  static const shortSleepMinutes = 360.0;
  static const lowStepsBelow = 5000.0;
  static const weightChangeKg = 2.0;

  /// [observations] dönem içindeki ve rızaya göre süzülmüş kayıtlar.
  /// [age] biliniyorsa VO2 Max tahmini yapılır.
  factory PatientReport.build(
    List<StoredObservation> observations, {
    required DateTime from,
    required DateTime to,
    int? age,
  }) {
    final byMetric = <ReportMetric, List<StoredObservation>>{};
    final days = <DateTime>{};
    for (final o in observations) {
      final m = ReportMetric.byCode(o.code);
      if (m == null) continue;
      byMetric.putIfAbsent(m, () => []).add(o);
      days.add(_day(o.effective));
    }
    for (final list in byMetric.values) {
      list.sort((a, b) => a.effective.compareTo(b.effective));
    }

    final series = <ReportMetric, SeriesStats>{};
    for (final e in byMetric.entries) {
      final kind = e.key.kind;
      if (kind != MetricKind.average && kind != MetricKind.total) continue;
      final readings = [
        for (final o in e.value)
          if (_value(o.resource) case final v?)
            (o.effective, e.key == ReportMetric.distance ? v / 1000 : v),
      ];
      final s = _stats(readings, total: kind == MetricKind.total);
      if (s != null) series[e.key] = s;
    }

    final bp = _bloodPressure(byMetric[ReportMetric.bloodPressure]);
    final sleep = _sleep(byMetric[ReportMetric.sleep]);
    final workouts = [
      for (final o
          in byMetric[ReportMetric.workouts] ?? const <StoredObservation>[])
        _workout(o),
    ];
    final ecgs = [
      for (final o in byMetric[ReportMetric.ecg] ?? const <StoredObservation>[])
        EcgEntry(
          o.effective,
          _seconds(o.resource),
          _component(o.resource, '8867-4'),
          _component(o.resource, '80404-7'),
        ),
    ];

    final hr = [
      for (final o
          in byMetric[ReportMetric.heartRate] ?? const <StoredObservation>[])
        if (_value(o.resource) case final v? when v > 0) v,
    ]..sort();
    final resting = hr.length < 10 ? null : hr[hr.length ~/ 10].round();
    final vo2 = age == null || resting == null
        ? null
        : estimateVo2Max(age: age, restingHeartRate: resting);

    final periodDays = _day(to).difference(_day(from)).inDays + 1;
    final findings = <Finding>[];
    void count(
      ReportMetric m,
      FindingKind kind,
      bool Function(double) test,
      double Function(List<double>) pick,
    ) {
      final values = [
        for (final o in byMetric[m] ?? const <StoredObservation>[])
          ?_value(o.resource),
      ];
      final hits = values.where(test).toList();
      if (hits.isNotEmpty) {
        findings.add(
          Finding(
            kind,
            n: hits.length,
            total: values.length,
            value: pick(hits),
          ),
        );
      }
    }

    count(
      ReportMetric.heartRate,
      FindingKind.tachycardia,
      (v) => v > tachycardiaAbove,
      (l) => l.reduce(max),
    );
    count(
      ReportMetric.heartRate,
      FindingKind.bradycardia,
      (v) => v < bradycardiaBelow,
      (l) => l.reduce(min),
    );
    count(
      ReportMetric.spo2,
      FindingKind.lowSpo2,
      (v) => v < lowSpo2Below,
      (l) => l.reduce(min),
    );
    if (bp != null) {
      final high = bp.categories.entries
          .where((e) => e.key.index >= BpCategory.grade1.index)
          .fold(0, (a, e) => a + e.value);
      if (high > 0) {
        findings.add(
          Finding(FindingKind.hypertension, n: high, total: bp.systolic.count),
        );
      }
    }
    count(
      ReportMetric.temperature,
      FindingKind.fever,
      (v) => v >= feverFrom,
      (l) => l.reduce(max),
    );
    count(
      ReportMetric.respiration,
      FindingKind.tachypnea,
      (v) => v > tachypneaAbove,
      (l) => l.reduce(max),
    );
    if (sleep != null) {
      final short = sleep.nights
          .where((n) => n.asleep < shortSleepMinutes)
          .length;
      if (short > 0) {
        findings.add(
          Finding(FindingKind.shortSleep, n: short, total: sleep.nights.length),
        );
      }
    }
    if (series[ReportMetric.steps] case final s?
        when s.days.length >= 3 && s.mean < lowStepsBelow) {
      findings.add(Finding(FindingKind.lowActivity, value: s.mean));
    }
    if (series[ReportMetric.weight] case final w? when w.count >= 2) {
      final first = _value(byMetric[ReportMetric.weight]!.first.resource)!;
      final delta = w.latest - first;
      if (delta.abs() >= weightChangeKg) {
        findings.add(Finding(FindingKind.weightChange, value: delta));
      }
    }
    if (days.isNotEmpty && days.length * 2 < periodDays) {
      findings.add(
        Finding(FindingKind.dataGaps, n: days.length, total: periodDays),
      );
    }

    return PatientReport._(
      from: from,
      to: to,
      periodDays: periodDays,
      observationCount: observations.length,
      series: series,
      bp: bp,
      sleep: sleep,
      workouts: workouts,
      ecgs: ecgs,
      restingHeartRate: resting,
      vo2max: vo2,
      daysWithData: days.length,
      findings: findings,
    );
  }

  static DateTime _day(DateTime t) {
    final l = t.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// Okumalardan özet. [total] ise önce günlere toplanır.
  static SeriesStats? _stats(
    List<(DateTime, double)> readings, {
    bool total = false,
  }) {
    if (readings.isEmpty) return null;
    final grouped = <DateTime, List<double>>{};
    for (final (t, v) in readings) {
      grouped.putIfAbsent(_day(t), () => []).add(v);
    }
    final days = [
      for (final e in grouped.entries)
        DayValue(
          e.key,
          e.value.length,
          e.value.reduce(min),
          e.value.reduce((a, b) => a + b) / e.value.length,
          e.value.reduce(max),
          e.value.reduce((a, b) => a + b),
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));
    final values = total
        ? [for (final d in days) d.total]
        : [for (final (_, v) in readings) v];
    double mean(Iterable<double> l) => l.reduce((a, b) => a + b) / l.length;
    double? change;
    if (days.length >= 4) {
      final half = days.length ~/ 2;
      final kind = total ? MetricKind.total : MetricKind.average;
      change =
          mean(days.skip(days.length - half).map((d) => d.value(kind))) -
          mean(days.take(half).map((d) => d.value(kind)));
    }
    return SeriesStats(
      count: readings.length,
      min: values.reduce(min),
      max: values.reduce(max),
      mean: mean(values),
      latest: total ? days.last.total : readings.last.$2,
      latestAt: readings.last.$1,
      days: days,
      change: change,
    );
  }

  static BpStats? _bloodPressure(List<StoredObservation>? list) {
    if (list == null) return null;
    final sys = <(DateTime, double)>[];
    final dia = <(DateTime, double)>[];
    final cats = {for (final c in BpCategory.values) c: 0};
    for (final o in list) {
      final s = _component(o.resource, '8480-6');
      final d = _component(o.resource, '8462-4');
      if (s == null || d == null) continue;
      sys.add((o.effective, s));
      dia.add((o.effective, d));
      cats[BpCategory.of(s, d)] = cats[BpCategory.of(s, d)]! + 1;
    }
    final ss = _stats(sys), ds = _stats(dia);
    return ss == null || ds == null ? null : BpStats(ss, ds, cats);
  }

  static const sleepStages = ['deep', 'light', 'rem', 'awake'];

  static SleepStats? _sleep(List<StoredObservation>? list) {
    if (list == null) return null;
    final nights = <SleepNight>[];
    for (final o in list) {
      final v = _value(o.resource);
      if (v == null) continue;
      nights.add(
        SleepNight(o.effective, _end(o.resource), v, {
          for (final s in sleepStages) s: ?_component(o.resource, 'sleep-$s'),
        }),
      );
    }
    final duration = _stats([for (final n in nights) (n.start, n.asleep)]);
    if (duration == null) return null;
    return SleepStats(nights, duration, {
      for (final s in sleepStages)
        if (nights.any((n) => n.stages.containsKey(s)))
          s:
              nights.map((n) => n.stages[s] ?? 0).reduce((a, b) => a + b) /
              nights.length,
    });
  }

  static WorkoutEntry _workout(StoredObservation o) {
    final display =
        (((o.resource['code'] as Map)['coding'] as List).first
            as Map)['display'];
    final type = display is String
        ? RegExp(r'\(([a-zA-Z]+)\)').firstMatch(display)?.group(1)
        : null;
    final m = _component(o.resource, '55430-3');
    return WorkoutEntry(
      start: o.effective,
      type: type,
      minutes: _component(o.resource, 'workout-duration'),
      steps: _component(o.resource, '55423-8'),
      distanceKm: m == null ? null : m / 1000,
      calories: _component(o.resource, '41981-2'),
      averageHeartRate: _component(o.resource, '8867-4'),
    );
  }

  static double? _value(Map<String, Object?> r) =>
      ((r['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();

  static double? _component(Map<String, Object?> r, String code) {
    for (final c in (r['component'] as List?) ?? const []) {
      if (c is! Map) continue;
      final coding = ((c['code'] as Map?)?['coding'] as List?)?.firstOrNull;
      if (coding is Map && coding['code'] == code) {
        return ((c['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();
      }
    }
    return null;
  }

  static DateTime? _end(Map<String, Object?> r) =>
      switch ((r['effectivePeriod'] as Map?)?['end']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      };

  static double? _seconds(Map<String, Object?> r) {
    final p = r['effectivePeriod'] as Map?;
    final s = DateTime.tryParse('${p?['start']}');
    final e = DateTime.tryParse('${p?['end']}');
    if (s == null || e == null) return null;
    return e.difference(s).inMilliseconds / 1000;
  }
}

/// VO2 Max tahmini (ml/kg/dk): Uth ve ark. (2004) `15,3 × HRmax / HRdinlenik`,
/// HRmax = 208 − 0,7 × yaş (Tanaka, 2001). Uygulamadaki `estimateVo2Max` ile
/// aynı; girdiler makul aralıkta değilse null.
double? estimateVo2Max({required int age, required int restingHeartRate}) {
  if (age < 13 || age > 90) return null;
  if (restingHeartRate < 35 || restingHeartRate > 110) return null;
  final hrMax = 208 - 0.7 * age;
  final v = 15.3 * hrMax / restingHeartRate;
  return (v * 10).round() / 10;
}
