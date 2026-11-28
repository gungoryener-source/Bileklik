import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';

import 'api.dart';
import 'model.dart';

/// Deneme hesaplarının oturum anahtarları.
abstract final class DemoTokens {
  static const doctor = 'demo-doctor';
  static const researcher = 'demo-research';
  static const patients = ['demo-patient', 'demo-patient-2', 'demo-patient-3'];

  /// Deneme hekiminin e-posta ve şifreyle girişi.
  static const doctorEmail = 'demo@bileklik.app';
  static const doctorPassword = 'demo-sifre-2026';
}

/// Deneme verisi: bir hekim, bir araştırma kurumu ve son 30 günün
/// ölçümleriyle üç takma kimlikli hasta. Hastalar hekime farklı türleri
/// paylaşmıştır; hekimin üç hasta kaydı vardır (ikisi bilekliğe bağlı, biri
/// davet bekliyor) ve bir bağlantı henüz kayda bağlanmamıştır.
///
/// Her şey portalın kendi API'si üzerinden kurulur (davet, rıza, FHIR
/// yükleme); böylece demo, gerçek akışın aynısını gösterir. Sunucunun
/// `--demo` kipi ve tarayıcıda çalışan demo (`demo/portal_web`) kullanır.
/// Adlar uydurmadır.
Future<void> seedDemo(PortalApi api, {DateTime? now, Random? random}) async {
  final store = api.store;
  api.panel.demoData = true;
  final t = (now ?? DateTime.now()).toUtc();
  final r = random ?? Random(42);
  store
    ..addAccount(
      const Account(
        id: 'dr-demo',
        role: Role.clinician,
        name: 'Dr. Ayşe Demir',
        organization: 'Demo Kardiyoloji Polikliniği',
        email: DemoTokens.doctorEmail,
        specialty: 'Kardiyoloji uzmanı',
        licenseNo: 'DEMO-123456',
      ),
      DemoTokens.doctor,
    )
    ..addAccount(
      const Account(
        id: 'research-demo',
        role: Role.researcher,
        name: 'Uyku ve Ritim Çalışması',
        organization: 'Demo Üniversitesi',
      ),
      DemoTokens.researcher,
    )
    ..setPassword(
      'dr-demo',
      await api.panel.passwords.hash(DemoTokens.doctorPassword, random: r),
    );
  const ids = [
    '00000000-0000-4000-8000-000000000001',
    '3f2b9c1e-5a7d-4e2f-9b1a-6c8d0e4f2a31',
    'a8c41d7e-0b2f-4c9a-8e6d-1f3b5a7c9e02',
  ];
  for (var i = 0; i < ids.length; i++) {
    store.addAccount(
      Account(id: ids[i], role: Role.patient, name: '-'),
      DemoTokens.patients[i],
    );
  }

  Future<Map<String, Object?>> call(
    String method,
    String path,
    String token,
    Object body,
  ) async {
    final res = await api.handler(
      Request(
        method,
        Uri.parse('http://demo$path'),
        headers: {'authorization': 'Bearer $token'},
        body: jsonEncode(body),
      ),
    );
    return (jsonDecode(await res.readAsString()) as Map)
        .cast<String, Object?>();
  }

  Future<String> invite(
    String actorToken,
    List<String> scopes,
    String purpose,
  ) async =>
      (await call('POST', '/invites', actorToken, {
            'purpose': purpose,
            'scopes': scopes,
            'days': 365,
          }))['code']!
          as String;

  Future<void> accept(String code, String patientToken, List<String> scopes) =>
      call('POST', '/invites/$code/accept', patientToken, {'scopes': scopes});

  /// Hekimin hasta kaydı; [invite] verilirse kabulde bilekliğe bağlanır.
  void record(
    String id,
    String name,
    DateTime birth,
    Sex sex,
    String fileNo, {
    String? invite,
    String? notes,
  }) => store.putRecord(
    PatientRecord(
      id: id,
      ownerId: 'dr-demo',
      name: name,
      created: t.subtract(const Duration(days: 40)),
      birthDate: birth,
      sex: sex,
      fileNo: fileNo,
      notes: notes,
      inviteCode: invite,
    ),
  );

  const all = [
    'heartRate',
    'spo2',
    'ecg',
    'bloodPressure',
    'sleep',
    'activity',
    'stress',
    'temperature',
    'respiration',
    'body',
  ];
  final c1 = await invite(
    DemoTokens.doctor,
    all,
    'Çarpıntı şikâyeti: ritim ve tansiyon takibi',
  );
  record(
    'rec-demo-1',
    'Elif Örnek',
    DateTime.utc(1968, 3, 14),
    Sex.female,
    'DEMO-1001',
    invite: c1,
    notes: 'Çarpıntı, ara ara baş dönmesi. Holter sonrası takip.',
  );
  await accept(c1, DemoTokens.patients[0], all);

  const hf = ['heartRate', 'activity', 'temperature', 'body', 'bloodPressure'];
  final c2 = await invite(
    DemoTokens.doctor,
    hf,
    'Kalp yetmezliği sonrası aktivite ve kilo takibi',
  );
  record(
    'rec-demo-2',
    'Murat Örnek',
    DateTime.utc(1955, 11, 2),
    Sex.male,
    'DEMO-1002',
    invite: c2,
    notes: 'KY, EF %40. Günlük kilo takibi önerildi.',
  );
  await accept(c2, DemoTokens.patients[1], hf);

  // İzlem notları ve görevler.
  final today = DateTime.utc(t.year, t.month, t.day);
  void care(
    String rec,
    CareKind kind,
    String text,
    int daysAgo, {
    int? dueIn,
  }) => store.putCare(
    CareEntry(
      id: store.nextId('care'),
      recordId: rec,
      ownerId: 'dr-demo',
      kind: kind,
      text: text,
      created: t.subtract(Duration(days: daysAgo, hours: 2)),
      due: dueIn == null ? null : today.add(Duration(days: dueIn)),
    ),
  );
  care(
    'rec-demo-1',
    CareKind.note,
    'Holter: sık SVES, kısa SVT atağı yok. Bisoprolol 2,5 mg başlandı.',
    14,
  );
  care(
    'rec-demo-1',
    CareKind.task,
    'Çarpıntı uyarısı sonrası hastayı ara',
    0,
    dueIn: 0,
  );
  care('rec-demo-1', CareKind.task, 'Kontrol randevusu ver', 3, dueIn: 10);
  care(
    'rec-demo-2',
    CareKind.note,
    'Diüretik dozu azaltıldı; günlük kilo takibine devam.',
    6,
  );
  care(
    'rec-demo-2',
    CareKind.task,
    'Haftalık kilo eğilimini gözden geçir',
    9,
    dueIn: -2,
  );

  // Kayda bağlanmamış bağlantı: hekim panelde bir kayda bağlayabilir.
  const apnea = ['sleep', 'spo2', 'respiration', 'heartRate'];
  await accept(
    await invite(DemoTokens.doctor, apnea, 'Uyku apnesi şüphesi'),
    DemoTokens.patients[2],
    apnea,
  );

  // Davet bekleyen kayıt.
  final c4 = await invite(DemoTokens.doctor, all, 'Hipertansiyon takibi');
  record(
    'rec-demo-4',
    'Kemal Örnek',
    DateTime.utc(1979, 6, 21),
    Sex.male,
    'DEMO-1003',
    invite: c4,
  );

  await accept(
    await invite(DemoTokens.researcher, [
      'sleep',
      'heartRate',
    ], 'Uyku ve gece nabzı araştırması'),
    DemoTokens.patients[0],
    ['sleep', 'heartRate'],
  );

  for (var i = 0; i < ids.length; i++) {
    await call(
      'POST',
      '/fhir',
      DemoTokens.patients[i],
      _bundle(ids[i], t, r, profile: _DemoProfile.values[i]),
    );
  }

  // Panelin genel tablosu, listesi ve sayfalaması için daha çok örnek hasta:
  // çoğu düzenli veri gönderir, bazılarında veri kesilmesi, düşük uyum,
  // yükselen tansiyon, ateş ya da azalan hareket vardır. Hepsi uydurma
  // adlı deneme hastalarıdır ("Örnek" soyadı, DEMO- dosya numarası).
  final extra = [
    ('Zeynep Örnek', DateTime.utc(1984, 5, 9), Sex.female, _DemoProfile.stable),
    (
      'Ahmet Örnek',
      DateTime.utc(1961, 1, 27),
      Sex.male,
      _DemoProfile.stableOlder,
    ),
    ('Leyla Örnek', DateTime.utc(1949, 8, 3), Sex.female, _DemoProfile.silent),
    (
      'Hasan Örnek',
      DateTime.utc(1972, 12, 11),
      Sex.male,
      _DemoProfile.lowAdherence,
    ),
    (
      'Selin Örnek',
      DateTime.utc(1966, 4, 30),
      Sex.female,
      _DemoProfile.hypertension,
    ),
    ('Can Örnek', DateTime.utc(1990, 9, 18), Sex.male, _DemoProfile.fever),
    (
      'Nermin Örnek',
      DateTime.utc(1958, 2, 6),
      Sex.female,
      _DemoProfile.slowing,
    ),
    ('Oğuz Örnek', DateTime.utc(1987, 7, 22), Sex.male, _DemoProfile.athlete),
  ];
  for (var i = 0; i < extra.length; i++) {
    final (name, birth, sex, profile) = extra[i];
    final id =
        '00000000-0000-4000-8000-${(100 + i).toString().padLeft(12, '0')}';
    final token = 'demo-patient-x$i';
    store.addAccount(Account(id: id, role: Role.patient, name: '-'), token);
    final scopes = profile == _DemoProfile.fever ? hf : all;
    final code = await invite(DemoTokens.doctor, scopes, profile.purpose);
    record('rec-demo-x$i', name, birth, sex, 'DEMO-${1004 + i}', invite: code);
    await accept(code, token, scopes);
    await call('POST', '/fhir', token, _bundle(id, t, r, profile: profile));
  }

  // Rızalar deneme verisinin başladığı güne çekilir: uyum ve kapsama 30
  // günlük geçmişle hesaplanır.
  for (final k in store.consentsForActor('dr-demo')) {
    store.addConsent(
      Consent(
        id: k.id,
        patientId: k.patientId,
        actorId: k.actorId,
        scopes: k.scopes,
        start: t.subtract(const Duration(days: 31)),
        end: t.add(const Duration(days: 334)),
        purpose: k.purpose,
        inviteCode: k.inviteCode,
        requested: k.requested,
      ),
    );
  }
}

/// Deneme hastalarının farklı bulgular gösteren veri profilleri.
enum _DemoProfile {
  /// Çarpıntı: ara ara 100'ün üzerinde nabız, sınırda yüksek tansiyon.
  palpitations(restingRate: 66, steps: 7500, weight: 68.0, height: 1.64),

  /// Kalp yetmezliği: az adım, dönem içinde artan kilo.
  heartFailure(restingRate: 74, steps: 3200, weight: 84.0, height: 1.76),

  /// Uyku apnesi şüphesi: gece SpO2 düşüşleri, kısa uyku.
  apnea(restingRate: 70, steps: 6000, weight: 97.0, height: 1.80),

  /// Düzenli veri, bulgu yok.
  stable(
    restingRate: 62,
    steps: 9000,
    weight: 61.0,
    height: 1.68,
    feverDay: null,
    purpose: 'Rutin kardiyak izlem',
  ),
  stableOlder(
    restingRate: 64,
    steps: 6500,
    weight: 79.0,
    height: 1.77,
    feverDay: null,
    purpose: 'Bypass sonrası izlem',
  ),

  /// Bileklik 38 saattir veri göndermiyor.
  silent(
    restingRate: 68,
    steps: 4200,
    weight: 66.0,
    height: 1.58,
    feverDay: null,
    silentHours: 38,
    purpose: 'Atriyal fibrilasyon izlemi',
  ),

  /// Bilekliği gün aşırı takıyor.
  lowAdherence(
    restingRate: 72,
    steps: 5500,
    weight: 88.0,
    height: 1.74,
    feverDay: null,
    everyOtherDay: true,
    purpose: 'Hipertansiyon takibi',
  ),

  /// Dönem içinde yükselen tansiyon.
  hypertension(
    restingRate: 70,
    steps: 6000,
    weight: 74.0,
    height: 1.62,
    feverDay: null,
    bpBase: 128,
    bpRise: 26,
    purpose: 'Tansiyon ilaç ayarı sonrası takip',
  ),

  /// Dün ateş.
  fever(
    restingRate: 66,
    steps: 8000,
    weight: 77.0,
    height: 1.81,
    feverDay: 0,
    purpose: 'Miyokardit sonrası izlem',
  ),

  /// Son haftada azalan hareket ve yükselen dinlenik nabız.
  slowing(
    restingRate: 67,
    steps: 7000,
    weight: 70.0,
    height: 1.60,
    feverDay: null,
    declining: true,
    purpose: 'Kalp kapak ameliyatı sonrası izlem',
  ),
  athlete(
    restingRate: 54,
    steps: 12000,
    weight: 72.0,
    height: 1.79,
    feverDay: null,
    purpose: 'Sporcu ritim taraması',
  );

  const _DemoProfile({
    required this.restingRate,
    required this.steps,
    required this.weight,
    required this.height,
    this.feverDay = 9,
    this.silentHours = 0,
    this.everyOtherDay = false,
    this.bpBase,
    this.bpRise = 0,
    this.declining = false,
    this.purpose = '',
  });

  final int restingRate;
  final int steps;
  final double weight;
  final double height;

  /// Ateşli günün kaç gün önce olduğu; yoksa null.
  final int? feverDay;

  /// Son bu kadar saatte veri yok.
  final int silentHours;

  /// Tek günlerde veri yok (bileklik takılmamış).
  final bool everyOtherDay;

  /// Sistolik taban ve 30 günde artış.
  final int? bpBase;
  final int bpRise;

  /// Son 7 günde adım yarıya iner, dinlenik nabız 7 artar.
  final bool declining;
  final String purpose;
}

Map<String, Object?> _obs(
  String patientId,
  String id,
  String code,
  DateTime at, {
  num? value,
  String? unit,
  List<(String, num, String)> components = const [],
  String system = 'http://loinc.org',
  String componentSystem = 'http://loinc.org',
}) => {
  'resourceType': 'Observation',
  'identifier': [
    {'system': 'https://bileklik.app/demo', 'value': id},
  ],
  'status': 'final',
  'code': {
    'coding': [
      {'system': system, 'code': code},
    ],
  },
  'subject': {'reference': 'urn:uuid:$patientId'},
  'effectiveDateTime': at.toIso8601String(),
  if (value != null) 'valueQuantity': {'value': value, 'unit': ?unit},
  if (components.isNotEmpty)
    'component': [
      for (final (c, v, u) in components)
        {
          'code': {
            'coding': [
              {'system': componentSystem, 'code': c},
            ],
          },
          'valueQuantity': {'value': v, 'unit': u},
        },
    ],
};

const _local = 'https://bileklik.app/fhir/CodeSystem/metric';

Map<String, Object?> _bundle(
  String patientId,
  DateTime now,
  Random r, {
  required _DemoProfile profile,
}) {
  const days = 30;
  final list = <Map<String, Object?>>[];
  final rest = profile.restingRate;
  final palp = profile == _DemoProfile.palpitations;
  final apnea = profile == _DemoProfile.apnea;
  // Nabız ve SpO2: iki saatte bir; solunum ve stres dört saatte bir.
  for (var h = 0; h < days * 24; h += 2) {
    final at = now.subtract(Duration(hours: h));
    final night = at.hour < 6;
    final rise = profile.declining && h < 7 * 24 ? 7 : 0;
    var hr = rest + rise + (night ? -6 : 8) + r.nextInt(12);
    if (palp && !night && r.nextInt(14) == 0) hr = 104 + r.nextInt(18);
    list.add(
      _obs(patientId, 'hr-$h', '8867-4', at, value: hr, unit: 'beats/minute'),
    );
    if (h % 4 == 0) {
      final low = apnea && night && r.nextInt(3) == 0;
      list
        ..add(
          _obs(
            patientId,
            'spo2-$h',
            '59408-5',
            at,
            value: low ? 85 + r.nextInt(5) : 94 + r.nextInt(5),
            unit: '%',
          ),
        )
        ..add(
          _obs(
            patientId,
            'rr-$h',
            '9279-1',
            at,
            value: (night ? 13 : 15) + r.nextInt(apnea ? 8 : 5),
            unit: 'breaths/minute',
          ),
        )
        ..add(
          _obs(
            patientId,
            'stress-$h',
            'stress',
            at,
            system: _local,
            value: night ? 15 + r.nextInt(20) : 30 + r.nextInt(45),
            unit: 'score',
          ),
        );
    }
  }
  // Hekim panelindeki uyarı panosu için yakın zamanda birer olay: uyku
  // apnesi şüphesinde dün gece 25 dk süren SpO2 düşüşü, çarpıntıda üç saat
  // önce dinlenirken 20 dk süren yüksek nabız. Ölçümler beş dakikada bir.
  final today = DateTime(now.year, now.month, now.day);
  if (apnea) {
    final start = today.subtract(const Duration(hours: 21)); // 03:00
    const values = [92, 89, 87, 86, 88, 89, 94];
    for (var i = 0; i < values.length; i++) {
      list.add(
        _obs(
          patientId,
          'spo2-dip-$i',
          '59408-5',
          start.add(Duration(minutes: 5 * i)),
          value: values[i],
          unit: '%',
        ),
      );
    }
  }
  if (palp) {
    final start = now.subtract(const Duration(hours: 3));
    const values = [118, 128, 136, 141, 133, 124, 96];
    for (var i = 0; i < values.length; i++) {
      list.add(
        _obs(
          patientId,
          'hr-run-$i',
          '8867-4',
          start.add(Duration(minutes: 5 * i)),
          value: values[i],
          unit: 'beats/minute',
        ),
      );
    }
  }
  for (var d = 0; d < days; d++) {
    // Gelecek zaman olmasın diye tüm kayıtlar şimdiden geriye sayılır.
    DateTime ago(int hours) => now.subtract(Duration(days: d, hours: hours));
    final morning = ago(3);
    final asleep = (apnea ? 300 : 360) + r.nextInt(apnea ? 90 : 120);
    final deep = (asleep * (0.15 + r.nextInt(8) / 100)).round();
    final rem = (asleep * (0.18 + r.nextInt(6) / 100)).round();
    final awake = 10 + r.nextInt(apnea ? 50 : 25);
    final sleepStart = morning.subtract(Duration(minutes: asleep + awake));
    list
      ..add(
        {
          ..._obs(
            patientId,
            'sleep-$d',
            '93832-4',
            sleepStart,
            value: asleep,
            unit: 'min',
            components: [
              ('sleep-deep', deep, 'min'),
              ('sleep-light', asleep - deep - rem, 'min'),
              ('sleep-rem', rem, 'min'),
              ('sleep-awake', awake, 'min'),
            ],
            componentSystem: _local,
          ),
          'effectivePeriod': {
            'start': sleepStart.toIso8601String(),
            'end': morning.toIso8601String(),
          },
        }..remove('effectiveDateTime'),
      )
      ..add(
        _obs(
          patientId,
          'hrv-$d',
          '80404-7',
          morning,
          value: 28 + r.nextInt(30),
          unit: 'ms',
        ),
      );
    var steps = profile.steps ~/ 2 + r.nextInt(profile.steps);
    if (profile.declining && d < 7) steps ~/= 2;
    list
      ..add(
        _obs(
          patientId,
          'steps-$d',
          '55423-8',
          ago(1),
          value: steps,
          unit: 'steps',
        ),
      )
      ..add(
        _obs(
          patientId,
          'dist-$d',
          '55430-3',
          ago(1),
          value: (steps * 0.72).round(),
          unit: 'm',
        ),
      )
      ..add(
        _obs(
          patientId,
          'kcal-$d',
          '41981-2',
          ago(1),
          value: 120 + steps ~/ 25,
          unit: 'kcal',
        ),
      )
      ..add(
        _obs(
          patientId,
          'temp-$d',
          '8310-5',
          morning,
          value: 36.2 + r.nextInt(8) / 10 + (d == profile.feverDay ? 1.6 : 0),
          unit: 'Cel',
        ),
      )
      ..add(
        _obs(
          patientId,
          'bp-$d',
          '85354-9',
          ago(2),
          components: [
            (
              '8480-6',
              (profile.bpBase ?? (palp ? 124 : 115)) +
                  profile.bpRise * (days - d) ~/ days +
                  r.nextInt(palp ? 26 : 20),
              'mm[Hg]',
            ),
            (
              '8462-4',
              (palp ? 78 : 72) +
                  profile.bpRise * (days - d) ~/ (days * 2) +
                  r.nextInt(14),
              'mm[Hg]',
            ),
          ],
        ),
      );
    // Kilo haftada üç kez elle girilir; kalp yetmezliğinde dönem içinde artar.
    if (d % 2 == 0) {
      final drift = profile == _DemoProfile.heartFailure
          ? (days - d) * 0.09
          : 0.0;
      final kg =
          ((profile.weight + drift + (r.nextInt(6) - 3) / 10) * 10).round() /
          10;
      final bmi = ((kg / (profile.height * profile.height)) * 10).round() / 10;
      list
        ..add(
          _obs(patientId, 'kg-$d', '29463-7', ago(10), value: kg, unit: 'kg'),
        )
        ..add(
          _obs(
            patientId,
            'bmi-$d',
            '39156-5',
            ago(10),
            value: bmi,
            unit: 'kg/m2',
          ),
        )
        ..add(
          _obs(
            patientId,
            'fat-$d',
            '41982-0',
            ago(10),
            value: 24 + r.nextInt(12) + 0.5,
            unit: '%',
          ),
        )
        ..add(
          _obs(
            patientId,
            'muscle-$d',
            'muscle-mass',
            ago(10),
            system: _local,
            value: ((kg * 0.42) * 10).round() / 10,
            unit: 'kg',
          ),
        );
    }
    if (d % 3 == 0) {
      final start = ago(5);
      list.add(
        {
          ..._obs(
            patientId,
            'ecg-$d',
            '11524-6',
            start,
            components: [
              ('8867-4', rest + 10 + r.nextInt(palp ? 30 : 10), 'beats/minute'),
              ('80404-7', 25 + r.nextInt(35), 'ms'),
            ],
          ),
          'effectivePeriod': {
            'start': start.toIso8601String(),
            'end': start.add(const Duration(seconds: 30)).toIso8601String(),
          },
        }..remove('effectiveDateTime'),
      );
    }
    if (d % 4 == 1 && profile != _DemoProfile.heartFailure || d % 7 == 2) {
      final start = ago(8);
      final minutes = 25 + r.nextInt(35);
      const types = ['walking', 'running', 'cycling'];
      list.add({
        'resourceType': 'Observation',
        'identifier': [
          {'system': 'https://bileklik.app/demo', 'value': 'workout-$d'},
        ],
        'status': 'final',
        'code': {
          'coding': [
            {
              'system': _local,
              'code': 'workout',
              'display': 'Workout (${types[d % 3]})',
            },
          ],
        },
        'subject': {'reference': 'urn:uuid:$patientId'},
        'effectivePeriod': {
          'start': start.toIso8601String(),
          'end': start.add(Duration(minutes: minutes)).toIso8601String(),
        },
        'component': [
          for (final (c, v, u, sys) in [
            ('workout-duration', minutes, 'min', _local),
            ('55423-8', minutes * 95, 'steps', 'http://loinc.org'),
            ('55430-3', minutes * 80, 'm', 'http://loinc.org'),
            ('41981-2', minutes * 6, 'kcal', 'http://loinc.org'),
            (
              '8867-4',
              rest + 35 + r.nextInt(20),
              'beats/minute',
              'http://loinc.org',
            ),
          ])
            {
              'code': {
                'coding': [
                  {'system': sys, 'code': c},
                ],
              },
              'valueQuantity': {'value': v, 'unit': u},
            },
        ],
      });
    }
  }
  // Veri kesilmesi ve takılmayan günler: o zamanlardaki kayıtlar çıkarılır.
  final quietFrom = now.subtract(Duration(hours: profile.silentHours));
  bool kept(Map<String, Object?> o) {
    final at = DateTime.parse(
      (o['effectiveDateTime'] ?? (o['effectivePeriod'] as Map)['start'])
          as String,
    );
    if (profile.silentHours > 0 && at.isAfter(quietFrom)) return false;
    final ago = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(at.year, at.month, at.day)).inDays;
    return !(profile.everyOtherDay && ago.isOdd);
  }

  return {
    'resourceType': 'Bundle',
    'type': 'collection',
    'entry': [
      {
        'resource': {'resourceType': 'Patient', 'id': patientId},
      },
      for (final o in list)
        if (kept(o)) {'resource': o},
    ],
  };
}
