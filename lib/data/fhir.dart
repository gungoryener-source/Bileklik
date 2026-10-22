import 'dart:convert';
import 'dart:math';

import '../device/protocol/history.dart';
import 'health_store.dart';
import 'models.dart';

/// Ölçümleri FHIR R4 kaynaklarına çevirir (portala aktarım ve dosyaya dışa
/// aktarma için).
///
/// - Her ölçüm bir `Observation`; kod LOINC, birim UCUM.
/// - Tansiyon tek panel (85354-9) olarak, sistolik/diastolik bileşenlerle;
///   değer tahmini olduğu için not düşülür.
/// - EKG, tek derivasyon (bilekteki ölçüm D1'e benzer) `SampledData` ile.
/// - Hepsi bir `Bundle` (collection) içinde, hasta kaynağına `urn:uuid:` ile
///   bağlanır. Hasta kaynağında kimlik bilgisi yoktur (KVKK: takma kimlik).
///
/// Her Observation'ın `identifier`'ı türden ve zamandan üretilir; portal aynı
/// kaydı ikinci kez alırsa tanır. LOINC kodlarının seçimi portal tarafında
/// (ROADMAP 19) bir kez daha gözden geçirilecek.
class FhirExporter {
  FhirExporter({required this.patientId, Random? random, DateTime Function()? clock})
    : _random = random ?? Random.secure(),
      _now = clock ?? DateTime.now;

  /// Takma hasta kimliği (UUID); telefonda bir kez üretilip saklanır.
  final String patientId;
  final Random _random;
  final DateTime Function() _now;

  static const loinc = 'http://loinc.org';
  static const ucum = 'http://unitsofmeasure.org';
  static const mdc = 'urn:oid:2.16.840.1.113883.6.24';
  static const categorySystem =
      'http://terminology.hl7.org/CodeSystem/observation-category';

  /// LOINC karşılığı olmayan değerler için uygulamanın kod sistemi.
  static const localSystem = 'https://bileklik.app/fhir/CodeSystem/metric';
  static const identifierSystem = 'https://bileklik.app/fhir/observation';

  String get _patientRef => 'urn:uuid:$patientId';

  /// [from]–[to] arasındaki kayıtlar tek Bundle'da.
  Map<String, Object?> bundle(
    HealthStore store, {
    required DateTime from,
    required DateTime to,
    bool includeEcg = true,
  }) {
    final resources = <Map<String, Object?>>[
      for (final type in MetricType.values)
        if (type != MetricType.systolic && type != MetricType.diastolic)
          for (final m in store.measurements(type, from, to))
            ?observation(m),
      ...bloodPressure(
        store.measurements(MetricType.systolic, from, to),
        store.measurements(MetricType.diastolic, from, to),
      ),
      for (final s in store.sleepBetween(from, to)) sleep(s),
      for (final w in store.workoutsBetween(from, to)) workout(w),
      if (includeEcg)
        for (final e in store.ecgRecordings())
          if (!e.start.isBefore(from) && e.start.isBefore(to)) ecg(e),
    ];
    return {
      'resourceType': 'Bundle',
      'id': _uuid(),
      'meta': {'lastUpdated': fhirDateTime(_now())},
      'type': 'collection',
      'timestamp': fhirDateTime(_now()),
      'entry': [
        {
          'fullUrl': _patientRef,
          'resource': {'resourceType': 'Patient', 'id': patientId},
        },
        for (final r in resources)
          {'fullUrl': 'urn:uuid:${r['id']}', 'resource': r},
      ],
    };
  }

  /// Bundle'ı JSON metnine çevirir.
  static String encode(Map<String, Object?> bundle) =>
      const JsonEncoder.withIndent(' ').convert(bundle);

  /// Bir ölçümün Observation'ı. Tansiyon ayrı ([bloodPressure]) yazılır;
  /// sistolik ya da diastolik tek başına verilirse null.
  Map<String, Object?>? observation(Measurement m) {
    final c = codeOf(m.type);
    if (c == null) return null;
    // Adım, mesafe ve kalori 10 dakikalık kayıtlardır; kaydın zamanı
    // aralığın başı sayılır (gerçek cihazda doğrulanacak).
    final period = m.type.isTotal;
    final value = m.type == MetricType.distance ? m.value * 1000 : m.value;
    return {
      ..._base(c.category, [c.coding], m.type.name, m.time),
      if (period)
        'effectivePeriod': {
          'start': fhirDateTime(m.time),
          'end': fhirDateTime(m.time.add(const Duration(minutes: 10))),
        }
      else
        'effectiveDateTime': fhirDateTime(m.time),
      'valueQuantity': _quantity(value, c.unit, c.ucumCode),
    };
  }

  /// Aynı zamandaki sistolik ve diastolik değerler tek panelde. Değer
  /// bilekten tahmin edildiği için not eklenir.
  List<Map<String, Object?>> bloodPressure(
    List<Measurement> systolic,
    List<Measurement> diastolic,
  ) {
    final dia = {for (final d in diastolic) d.time: d.value};
    return [
      for (final s in systolic)
        if (dia[s.time] case final d?)
          {
            ..._base(
              'vital-signs',
              const [
                {
                  'system': loinc,
                  'code': '85354-9',
                  'display': 'Blood pressure panel with all children optional',
                },
              ],
              'bloodPressure',
              s.time,
            ),
            'effectiveDateTime': fhirDateTime(s.time),
            'note': const [
              {
                'text':
                    'Estimated by a cuffless wristband; not a medical '
                    'blood pressure measurement.',
              },
            ],
            'component': [
              {
                'code': _code(loinc, '8480-6', 'Systolic blood pressure'),
                'valueQuantity': _quantity(s.value, 'mmHg', 'mm[Hg]'),
              },
              {
                'code': _code(loinc, '8462-4', 'Diastolic blood pressure'),
                'valueQuantity': _quantity(d, 'mmHg', 'mm[Hg]'),
              },
            ],
          },
    ];
  }

  /// Uyku oturumu: toplam süre ve evrelerin dakikaları.
  Map<String, Object?> sleep(SleepSession s) {
    final asleep = s.minutes.where((m) => m != SleepStage.awake).length;
    return {
      ..._base(
        'activity',
        const [
          {'system': loinc, 'code': '93832-4', 'display': 'Sleep duration'},
        ],
        'sleep',
        s.start,
      ),
      'effectivePeriod': {
        'start': fhirDateTime(s.start),
        'end': fhirDateTime(s.end),
      },
      'valueQuantity': _quantity(asleep.toDouble(), 'min', 'min'),
      'component': [
        for (final stage in SleepStage.values)
          {
            'code': _code(localSystem, 'sleep-${stage.name}', 'Sleep ${stage.name}'),
            'valueQuantity': _quantity(
              s.minutesIn(stage).toDouble(),
              'min',
              'min',
            ),
          },
      ],
    };
  }

  /// Egzersiz: süre, adım, mesafe, kalori ve ortalama nabız bileşenleriyle.
  Map<String, Object?> workout(Workout w) => {
    ..._base(
      'activity',
      [
        {
          'system': localSystem,
          'code': 'workout',
          'display': 'Workout${w.type == null ? '' : ' (${w.type!.name})'}',
        },
      ],
      'workout',
      w.start,
    ),
    'effectivePeriod': {
      'start': fhirDateTime(w.start),
      'end': fhirDateTime(w.end),
    },
    'component': [
      {
        'code': _code(localSystem, 'workout-duration', 'Workout duration'),
        'valueQuantity': _quantity(w.duration.inSeconds / 60, 'min', 'min'),
      },
      if (w.steps > 0)
        {
          'code': _code(loinc, '55423-8', 'Number of steps'),
          'valueQuantity': _quantity(w.steps.toDouble(), 'steps', '{steps}'),
        },
      if (w.distanceKm > 0)
        {
          'code': _code(loinc, '55430-3', 'Walking distance'),
          'valueQuantity': _quantity(w.distanceKm * 1000, 'm', 'm'),
        },
      if (w.calories > 0)
        {
          'code': _code(loinc, '41981-2', 'Calories burned'),
          'valueQuantity': _quantity(w.calories, 'kcal', 'kcal'),
        },
      if (w.averageHeartRate > 0)
        {
          'code': _code(loinc, '8867-4', 'Heart rate'),
          'valueQuantity': _quantity(
            w.averageHeartRate.toDouble(),
            'beats/minute',
            '/min',
          ),
        },
    ],
  };

  /// EKG kaydı: tek derivasyon, ham örnekler `SampledData` ile. Örneklerin
  /// birimi (ADC sayımı → µV çarpanı) PDF'te yok; çarpan 1 yazıldı (gerçek
  /// cihazda doğrulanacak).
  Map<String, Object?> ecg(EcgRecording e) => {
    ..._base(
      'procedure',
      const [
        {'system': loinc, 'code': '11524-6', 'display': 'EKG study'},
      ],
      'ecg',
      e.start,
    ),
    'effectivePeriod': {
      'start': fhirDateTime(e.start),
      'end': fhirDateTime(
        e.start.add(
          Duration(microseconds: e.samples.length * 1000000 ~/ e.sampleRate),
        ),
      ),
    },
    'component': [
      {
        'code': _code(mdc, '131329', 'MDC_ECG_ELEC_POTL_I'),
        'valueSampledData': {
          'origin': {'value': 0, 'system': ucum, 'code': '1'},
          'period': 1000 / e.sampleRate,
          'factor': 1,
          'dimensions': 1,
          'data': e.samples.join(' '),
        },
      },
      if (e.averageHeartRate case final hr?)
        {
          'code': _code(loinc, '8867-4', 'Heart rate'),
          'valueQuantity': _quantity(hr.toDouble(), 'beats/minute', '/min'),
        },
      if (e.sdnn case final sdnn?)
        {
          'code': _code(
            loinc,
            '80404-7',
            'R-R interval.standard deviation (Heart rate variability)',
          ),
          'valueQuantity': _quantity(sdnn, 'ms', 'ms'),
        },
    ],
  };

  Map<String, Object?> _base(
    String category,
    List<Map<String, String>> coding,
    String kind,
    DateTime time,
  ) => {
    'resourceType': 'Observation',
    'id': _uuid(),
    'identifier': [
      {
        'system': identifierSystem,
        'value': '$kind-${time.toUtc().millisecondsSinceEpoch}',
      },
    ],
    'status': 'final',
    'category': [
      {
        'coding': [
          {'system': categorySystem, 'code': category},
        ],
      },
    ],
    'code': {'coding': coding},
    'subject': {'reference': _patientRef},
    'device': {'display': 'JCV8 wristband'},
  };

  static Map<String, Object?> _code(String system, String code, String display) => {
    'coding': [
      {'system': system, 'code': code, 'display': display},
    ],
  };

  static Map<String, Object?> _quantity(double value, String unit, String code) => {
    // Tam sayılar "72.0" değil "72" yazılsın.
    'value': value == value.roundToDouble() ? value.round() : value,
    'unit': unit,
    'system': ucum,
    'code': code,
  };

  /// Rastgele (sürüm 4) UUID.
  String _uuid() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0F) | 0x40;
    b[8] = (b[8] & 0x3F) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  /// Bir ölçüm türünün FHIR kodu; tansiyon bileşenleri ve ham PPI için null.
  static FhirCode? codeOf(MetricType t) => switch (t) {
    MetricType.heartRate => const FhirCode(
      'vital-signs',
      {'system': loinc, 'code': '8867-4', 'display': 'Heart rate'},
      'beats/minute',
      '/min',
    ),
    MetricType.spo2 => const FhirCode(
      'vital-signs',
      {
        'system': loinc,
        'code': '59408-5',
        'display': 'Oxygen saturation in Arterial blood by Pulse oximetry',
      },
      '%',
      '%',
    ),
    MetricType.respiratoryRate => const FhirCode(
      'vital-signs',
      {'system': loinc, 'code': '9279-1', 'display': 'Respiratory rate'},
      'breaths/minute',
      '/min',
    ),
    MetricType.temperature => const FhirCode(
      'vital-signs',
      {'system': loinc, 'code': '8310-5', 'display': 'Body temperature'},
      'Cel',
      'Cel',
    ),
    MetricType.weight => const FhirCode(
      'vital-signs',
      {'system': loinc, 'code': '29463-7', 'display': 'Body weight'},
      'kg',
      'kg',
    ),
    MetricType.bmi => const FhirCode(
      'vital-signs',
      {'system': loinc, 'code': '39156-5', 'display': 'Body mass index (BMI)'},
      'kg/m2',
      'kg/m2',
    ),
    MetricType.bodyFat => const FhirCode(
      'vital-signs',
      {
        'system': loinc,
        'code': '41982-0',
        'display': 'Percentage of body fat Measured',
      },
      '%',
      '%',
    ),
    MetricType.hrv => const FhirCode(
      'vital-signs',
      {
        'system': loinc,
        'code': '80404-7',
        'display': 'R-R interval.standard deviation (Heart rate variability)',
      },
      'ms',
      'ms',
    ),
    MetricType.steps => const FhirCode(
      'activity',
      {'system': loinc, 'code': '55423-8', 'display': 'Number of steps'},
      'steps',
      '{steps}',
    ),
    MetricType.distance => const FhirCode(
      'activity',
      {'system': loinc, 'code': '55430-3', 'display': 'Walking distance'},
      'm',
      'm',
    ),
    MetricType.calories => const FhirCode(
      'activity',
      {'system': loinc, 'code': '41981-2', 'display': 'Calories burned'},
      'kcal',
      'kcal',
    ),
    MetricType.stress => const FhirCode(
      'survey',
      {'system': localSystem, 'code': 'stress', 'display': 'Stress index'},
      'score',
      '{score}',
    ),
    MetricType.muscleMass => const FhirCode(
      'vital-signs',
      {'system': localSystem, 'code': 'muscle-mass', 'display': 'Muscle mass'},
      'kg',
      'kg',
    ),
    // Tansiyon panelde yazılır; ham PPI dışa aktarılmaz.
    MetricType.systolic || MetricType.diastolic || MetricType.ppi => null,
  };
}

/// Bir ölçüm türünün FHIR kategorisi, kodu ve UCUM birimi.
class FhirCode {
  const FhirCode(this.category, this.coding, this.unit, this.ucumCode);

  final String category;
  final Map<String, String> coding;
  final String unit;
  final String ucumCode;
}

/// FHIR `dateTime`: saniye hassasiyetinde, saat dilimiyle
/// ("2026-10-22T09:30:00+03:00"; UTC için "Z").
String fhirDateTime(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date =
      '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
      'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  if (t.isUtc) return '${date}Z';
  final o = t.timeZoneOffset;
  final sign = o.isNegative ? '-' : '+';
  final m = o.inMinutes.abs();
  return '$date$sign${two(m ~/ 60)}:${two(m % 60)}';
}
