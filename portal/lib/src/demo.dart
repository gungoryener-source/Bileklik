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
}

/// Deneme verisi: bir hekim, bir araştırma kurumu ve son 7 günün ölçümleriyle
/// üç takma kimlikli hasta. Hastalar hekime farklı türleri paylaşmıştır.
///
/// Her şey portalın kendi API'si üzerinden kurulur (davet, rıza, FHIR
/// yükleme); böylece demo, gerçek akışın aynısını gösterir. Sunucunun
/// `--demo` kipi ve tarayıcıda çalışan demo (`demo/portal_web`) kullanır.
Future<void> seedDemo(PortalApi api, {DateTime? now, Random? random}) async {
  final store = api.store;
  final t = (now ?? DateTime.now()).toUtc();
  final r = random ?? Random(42);
  store
    ..addAccount(
      const Account(
        id: 'dr-demo',
        role: Role.clinician,
        name: 'Dr. Ayşe Demir',
        organization: 'Demo Kardiyoloji Polikliniği',
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

  Future<void> share(String actorToken, String patientToken, List<String> scopes, String purpose) async {
    final invite = await call('POST', '/invites', actorToken, {
      'purpose': purpose,
      'scopes': scopes,
      'days': 90,
    });
    await call('POST', '/invites/${invite['code']}/accept', patientToken, {
      'scopes': scopes,
    });
  }

  await share(DemoTokens.doctor, DemoTokens.patients[0], [
    'heartRate',
    'spo2',
    'ecg',
    'bloodPressure',
    'sleep',
  ], 'Çarpıntı şikâyeti: ritim ve tansiyon takibi');
  await share(DemoTokens.doctor, DemoTokens.patients[1], [
    'heartRate',
    'activity',
    'temperature',
  ], 'Kalp yetmezliği sonrası aktivite takibi');
  await share(DemoTokens.doctor, DemoTokens.patients[2], [
    'sleep',
    'spo2',
  ], 'Uyku apnesi şüphesi');
  await share(DemoTokens.researcher, DemoTokens.patients[0], [
    'sleep',
    'heartRate',
  ], 'Uyku ve gece nabzı araştırması');

  for (var i = 0; i < ids.length; i++) {
    await call(
      'POST',
      '/fhir',
      DemoTokens.patients[i],
      _bundle(ids[i], t, r, restingRate: 62 + i * 6),
    );
  }
}

Map<String, Object?> _obs(
  String patientId,
  String id,
  String code,
  DateTime at, {
  num? value,
  String? unit,
  List<(String, num, String)> components = const [],
}) => {
  'resourceType': 'Observation',
  'identifier': [
    {'system': 'https://bileklik.app/demo', 'value': id},
  ],
  'status': 'final',
  'code': {
    'coding': [
      {'system': 'http://loinc.org', 'code': code},
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
              {'system': 'http://loinc.org', 'code': c},
            ],
          },
          'valueQuantity': {'value': v, 'unit': u},
        },
    ],
};

Map<String, Object?> _bundle(
  String patientId,
  DateTime now,
  Random r, {
  required int restingRate,
}) {
  final list = <Map<String, Object?>>[];
  for (var h = 0; h < 7 * 24; h += 2) {
    final at = now.subtract(Duration(hours: h));
    final night = at.hour < 6;
    list.add(
      _obs(
        patientId,
        'hr-$h',
        '8867-4',
        at,
        value: restingRate + (night ? -6 : 8) + r.nextInt(12),
        unit: 'beats/minute',
      ),
    );
    if (h % 6 == 0) {
      list.add(
        _obs(patientId, 'spo2-$h', '59408-5', at, value: 94 + r.nextInt(5), unit: '%'),
      );
    }
  }
  for (var d = 0; d < 7; d++) {
    // Gelecek zaman olmasın diye tüm kayıtlar şimdiden geriye sayılır.
    DateTime ago(int hours) => now.subtract(Duration(days: d, hours: hours));
    final morning = ago(3);
    list
      ..add(
        _obs(
          patientId,
          'sleep-$d',
          '93832-4',
          morning,
          value: 330 + r.nextInt(120),
          unit: 'min',
        ),
      )
      ..add(_obs(patientId, 'hrv-$d', '80404-7', morning, value: 32 + r.nextInt(25), unit: 'ms'))
      ..add(
        _obs(
          patientId,
          'steps-$d',
          '55423-8',
          ago(1),
          value: 3000 + r.nextInt(7000),
          unit: 'steps',
        ),
      )
      ..add(
        _obs(
          patientId,
          'temp-$d',
          '8310-5',
          morning,
          value: 36.2 + r.nextInt(8) / 10,
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
            ('8480-6', 115 + r.nextInt(20), 'mm[Hg]'),
            ('8462-4', 72 + r.nextInt(12), 'mm[Hg]'),
          ],
        ),
      );
    if (d.isEven) {
      list.add(
        _obs(
          patientId,
          'ecg-$d',
          '11524-6',
          ago(5),
          components: [('8867-4', restingRate + 10 + r.nextInt(10), 'beats/minute')],
        ),
      );
    }
  }
  return {
    'resourceType': 'Bundle',
    'type': 'collection',
    'entry': [
      {
        'resource': {'resourceType': 'Patient', 'id': patientId},
      },
      for (final o in list) {'resource': o},
    ],
  };
}
