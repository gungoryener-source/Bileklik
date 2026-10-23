import 'dart:convert';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _patientId = '6f1c2a3e-1111-4222-8333-944455556666';
final _t0 = DateTime.utc(2026, 10, 20, 9);

Map<String, Object?> _obs(String kind, String code, DateTime at, num value) => {
  'resourceType': 'Observation',
  'id': '$kind-${at.millisecondsSinceEpoch}',
  'identifier': [
    {
      'system': 'https://bileklik.app/fhir/observation',
      'value': '$kind-${at.millisecondsSinceEpoch}',
    },
  ],
  'status': 'final',
  'code': {
    'coding': [
      {'system': 'http://loinc.org', 'code': code},
    ],
  },
  'subject': {'reference': 'urn:uuid:$_patientId'},
  'effectiveDateTime': at.toIso8601String(),
  'valueQuantity': {'value': value},
};

/// Uygulamanın `FhirExporter` çıktısıyla aynı biçimde bir Bundle.
Map<String, Object?> _bundle({String patientId = _patientId, List<Object?>? extra}) => {
  'resourceType': 'Bundle',
  'type': 'collection',
  'entry': [
    {
      'fullUrl': 'urn:uuid:$patientId',
      'resource': {'resourceType': 'Patient', 'id': patientId},
    },
    for (final r in [
      _obs('heartRate', '8867-4', _t0, 72),
      _obs('heartRate', '8867-4', _t0.add(const Duration(hours: 2)), 80),
      _obs('spo2', '59408-5', _t0, 97),
    ])
      {'fullUrl': 'urn:uuid:${r['id']}', 'resource': r},
    ...?extra,
  ],
};

class _Portal {
  _Portal() {
    store
      ..addAccount(
        const Account(id: _patientId, role: Role.patient, name: '-'),
        'patient',
      )
      ..addAccount(
        const Account(id: 'dr-1', role: Role.clinician, name: 'Dr. Ayşe Kaya'),
        'doctor',
      )
      ..addAccount(
        const Account(id: 'dr-2', role: Role.clinician, name: 'Dr. Başka'),
        'stranger',
      );
    api = PortalApi(store, clock: () => now, random: Random(7));
  }

  final store = MemoryPortalStore();
  late final PortalApi api;
  DateTime now = _t0.add(const Duration(days: 1));

  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    String? token,
    Object? body,
  }) async {
    final response = await api.handler(
      Request(
        method,
        Uri.parse('http://portal.test$path'),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
        body: body == null ? null : jsonEncode(body),
      ),
    );
    final text = await response.readAsString();
    final json = text.startsWith('{') ? jsonDecode(text) as Map<String, Object?> : <String, Object?>{};
    return (response.statusCode, json);
  }

  /// Hekimin davetini hasta seçtiği türlerle kabul eder.
  Future<String> connectDoctor(List<String> scopes) async {
    final (_, invite) = await call(
      'POST',
      '/invites',
      token: 'doctor',
      body: {
        'purpose': 'Ritim takibi',
        'scopes': ['heartRate', 'ecg'],
        'days': 30,
      },
    );
    final (status, consent) = await call(
      'POST',
      '/invites/${invite['code']}/accept',
      token: 'patient',
      body: {'scopes': scopes},
    );
    expect(status, 201);
    return consent['id']! as String;
  }
}

String _diagnostics(Map<String, Object?> outcome) =>
    ((outcome['issue']! as List).first as Map)['diagnostics'] as String;

List<Map> _entries(Map<String, Object?> bundle) => [
  for (final e in bundle['entry']! as List) (e as Map)['resource'] as Map,
];

void main() {
  test('oturum anahtarı olmadan erişilmez; sağlık denetimi açık', () async {
    final p = _Portal();
    expect((await p.call('GET', '/fhir/Observation?patient=$_patientId')).$1, 401);
    expect((await p.call('GET', '/fhir/Observation', token: 'yanlis')).$1, 401);
    final ok = await p.api.handler(Request('GET', Uri.parse('http://portal.test/health')));
    expect(ok.statusCode, 200);
  });

  test('hasta Bundle yükler; aynı kayıtlar ikinci kez yazılmaz', () async {
    final p = _Portal();
    final (s1, o1) = await p.call('POST', '/fhir', token: 'patient', body: _bundle());
    expect(s1, 200);
    expect(_diagnostics(o1), 'created=3 duplicates=0 rejected=0');

    final broken = {
      'resource': {'resourceType': 'Observation', 'status': 'final'},
    };
    final (s2, o2) = await p.call(
      'POST',
      '/fhir',
      token: 'patient',
      body: _bundle(extra: [broken]),
    );
    expect(s2, 200);
    expect(_diagnostics(o2), 'created=0 duplicates=3 rejected=1');
    final warning = (o2['issue']! as List)[1] as Map;
    expect(warning['expression'], ['Bundle.entry[4]']);

    final (s3, own) = await p.call(
      'GET',
      '/fhir/Observation?patient=$_patientId',
      token: 'patient',
    );
    expect(s3, 200);
    expect(own['total'], 3);
  });

  test('başka hastanın Bundle\'ı ve hekimin yüklemesi reddedilir', () async {
    final p = _Portal();
    final (s1, _) = await p.call(
      'POST',
      '/fhir',
      token: 'patient',
      body: _bundle(patientId: '00000000-0000-4000-8000-000000000000'),
    );
    expect(s1, 400);
    final (s2, _) = await p.call('POST', '/fhir', token: 'doctor', body: _bundle());
    expect(s2, 403);
    final (s3, _) = await p.call('POST', '/fhir', token: 'patient', body: 'bozuk');
    expect(s3, 400);
  });

  test('rızası olmayan hekim göremez; deneme kayda geçer', () async {
    final p = _Portal();
    await p.call('POST', '/fhir', token: 'patient', body: _bundle());
    final (status, _) = await p.call(
      'GET',
      '/fhir/Observation?patient=$_patientId',
      token: 'doctor',
    );
    expect(status, 403);
    final (_, audit) = await p.call('GET', '/fhir/AuditEvent', token: 'patient');
    final failed = _entries(audit).where((e) => e['outcome'] == '4');
    expect(failed, hasLength(1));
    expect(failed.single['action'], 'R');
  });

  test('davet: hekim kod üretir, hasta görür ve seçtiği türlerle kabul eder', () async {
    final p = _Portal();
    final (s1, invite) = await p.call(
      'POST',
      '/invites',
      token: 'doctor',
      body: {
        'purpose': 'Ritim takibi',
        'scopes': ['heartRate', 'ecg'],
        'days': 30,
      },
    );
    expect(s1, 201);
    final code = invite['code']! as String;
    expect(code, matches(RegExp(r'^[A-Z2-9]{7}$')));

    final (s2, offer) = await p.call('GET', '/invites/${code.toLowerCase()}', token: 'patient');
    expect(s2, 200);
    expect(offer['name'], 'Dr. Ayşe Kaya');
    expect(offer['kind'], 'clinician');
    expect(offer['requested'], ['heartRate', 'ecg']);

    // İstenmeyen tür seçilemez.
    final (s3, _) = await p.call(
      'POST',
      '/invites/$code/accept',
      token: 'patient',
      body: {
        'scopes': ['spo2'],
      },
    );
    expect(s3, 400);
    // Hasta olmayan daveti açamaz.
    expect((await p.call('GET', '/invites/$code', token: 'stranger')).$1, 403);
    expect((await p.call('GET', '/invites/YOKBOYLE', token: 'patient')).$1, 404);
  });

  test('hekim yalnızca rızadaki türleri ve dönemi görür', () async {
    final p = _Portal();
    await p.call('POST', '/fhir', token: 'patient', body: _bundle());
    await p.connectDoctor(['heartRate']);

    final (s1, seen) = await p.call(
      'GET',
      '/fhir/Observation?patient=$_patientId',
      token: 'doctor',
    );
    expect(s1, 200);
    expect(seen['total'], 2, reason: 'SpO2 paylaşılmadı');

    final (_, filtered) = await p.call(
      'GET',
      '/fhir/Observation?patient=$_patientId&date=ge${_t0.add(const Duration(hours: 1)).toIso8601String()}',
      token: 'doctor',
    );
    expect(filtered['total'], 1);

    // SpO2 açıkça istense bile rızada yoksa gelmez.
    final (_, spo2) = await p.call(
      'GET',
      '/fhir/Observation?patient=$_patientId&code=59408-5',
      token: 'doctor',
    );
    expect(spo2['total'], 0);

    // Başka hekim hâlâ göremez.
    expect(
      (await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'stranger')).$1,
      403,
    );

    final (_, audit) = await p.call('GET', '/fhir/AuditEvent', token: 'patient');
    final reads = _entries(audit).where((e) => e['action'] == 'R' && e['outcome'] == '0');
    expect(reads, hasLength(3));
    // Erişim kayıtlarını yalnızca hasta görür.
    expect((await p.call('GET', '/fhir/AuditEvent', token: 'doctor')).$1, 403);
  });

  test('rızanın süresi dolunca ya da geri alınınca erişim biter', () async {
    final p = _Portal();
    await p.call('POST', '/fhir', token: 'patient', body: _bundle());
    final consentId = await p.connectDoctor(['heartRate']);

    p.now = p.now.add(const Duration(days: 31));
    expect(
      (await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'doctor')).$1,
      403,
    );

    p.now = _t0.add(const Duration(days: 2));
    expect(
      (await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'doctor')).$1,
      200,
    );
    // Başkasının rızasını kimse geri alamaz.
    expect((await p.call('DELETE', '/consents/$consentId', token: 'doctor')).$1, 404);
    final (s, consent) = await p.call('DELETE', '/consents/$consentId', token: 'patient');
    expect(s, 200);
    expect(consent['status'], 'inactive');
    expect(
      (await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'doctor')).$1,
      403,
    );

    final (_, list) = await p.call('GET', '/fhir/Consent', token: 'doctor');
    expect(list['total'], 1);
  });

  test('unutulma hakkı: ölçümler silinir, rızalar biter, kayıt kalır', () async {
    final p = _Portal();
    await p.call('POST', '/fhir', token: 'patient', body: _bundle());
    await p.connectDoctor(['heartRate']);

    expect((await p.call('DELETE', '/patients/$_patientId/data', token: 'doctor')).$1, 403);
    final (s, outcome) = await p.call(
      'DELETE',
      '/patients/$_patientId/data',
      token: 'patient',
    );
    expect(s, 200);
    expect(_diagnostics(outcome), 'deleted=3');

    final (_, own) = await p.call(
      'GET',
      '/fhir/Observation?patient=$_patientId',
      token: 'patient',
    );
    expect(own['total'], 0);
    expect(
      (await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'doctor')).$1,
      403,
    );
    final (_, audit) = await p.call('GET', '/fhir/AuditEvent', token: 'patient');
    expect(_entries(audit).where((e) => e['action'] == 'D'), hasLength(1));
  });

  test('uygulama takma kimlikle hesap açar; anahtar bir kez verilir', () async {
    final p = _Portal();
    const id = '0f0e0d0c-1111-4222-8333-444455556666';
    expect((await p.call('POST', '/patients', body: {'patientId': 'yok'})).$1, 400);
    final (s1, created) = await p.call(
      'POST',
      '/patients',
      body: {'patientId': id},
    );
    expect(s1, 201);
    final token = created['token']! as String;
    expect(token, hasLength(64));
    expect((await p.call('POST', '/patients', body: {'patientId': id})).$1, 409);
    final (s2, own) = await p.call(
      'GET',
      '/fhir/Observation?patient=$id',
      token: token,
    );
    expect(s2, 200);
    expect(own['total'], 0);
  });

  test('bağlantı listesi karşı tarafı ve seçilen türleri gösterir', () async {
    final p = _Portal();
    final response = await p.api.handler(
      Request(
        'GET',
        Uri.parse('http://portal.test/connections'),
        headers: {'authorization': 'Bearer patient'},
      ),
    );
    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), isEmpty);

    final consentId = await p.connectDoctor(['heartRate']);
    final list = jsonDecode(
      await (await p.api.handler(
        Request(
          'GET',
          Uri.parse('http://portal.test/connections'),
          headers: {'authorization': 'Bearer patient'},
        ),
      )).readAsString(),
    ) as List;
    expect(list, hasLength(1));
    final c = list.single as Map;
    expect(c['id'], consentId);
    expect(c['kind'], 'clinician');
    expect(c['name'], 'Dr. Ayşe Kaya');
    expect(c['scopes'], ['heartRate']);
    expect(c['requested'], ['heartRate', 'ecg']);
    expect(c['code'], matches(RegExp(r'^[A-Z2-9]{7}$')));

    // Hekim bu listeyi göremez.
    expect((await p.call('GET', '/connections', token: 'doctor')).$1, 403);
  });

  test('geri bildirim anahtarsız alınır, kimliğe bağlanmaz ve sınırlanır', () async {
    final p = _Portal();
    final (status, _) = await p.call(
      'POST',
      '/feedback',
      body: {
        'category': 'bug',
        'message': '  Senkron takılıyor  ',
        'appVersion': '0.1.0',
        'platform': 'android',
        'locale': 'tr',
      },
    );
    expect(status, 201);
    final saved = p.store.feedback().single;
    expect(saved.category, FeedbackCategory.bug);
    expect(saved.message, 'Senkron takılıyor');
    expect(saved.platform, 'android');
    expect(jsonEncode(saved.toJson()), isNot(contains(_patientId)));

    for (final bad in [
      {'category': 'bug', 'message': ''},
      {'category': 'yanlis', 'message': 'x'},
      {'category': 'idea', 'message': 'x' * (PortalApi.feedbackMaxLength + 1)},
    ]) {
      expect((await p.call('POST', '/feedback', body: bad)).$1, 400);
    }

    for (var i = 1; i < PortalApi.feedbackPerMinute; i++) {
      await p.call('POST', '/feedback', body: {'category': 'idea', 'message': '$i'});
    }
    final (limited, _) = await p.call(
      'POST',
      '/feedback',
      body: {'category': 'idea', 'message': 'fazla'},
    );
    expect(limited, 429);
    p.now = p.now.add(const Duration(minutes: 1));
    expect(
      (await p.call('POST', '/feedback', body: {'category': 'other', 'message': 'tekrar'})).$1,
      201,
    );
  });

  test('kurtarma kodu hesabı yeni telefona alır; eski anahtar ve kod biter', () async {
    final p = _Portal();
    const id = '0f0e0d0c-1111-4222-8333-444455556666';
    final (_, created) = await p.call('POST', '/patients', body: {'patientId': id});
    final oldToken = created['token']! as String;
    final code = created['recoveryCode']! as String;
    expect(code, matches(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$')));

    expect(
      (await p.call('POST', '/recover', body: {'recoveryCode': 'AAAA-BBBB-CCCC-DDDD'})).$1,
      404,
    );
    // Küçük harf ve boşluk fark etmez.
    final typed = code.toLowerCase().replaceAll('-', ' ');
    final (s, recovered) = await p.call(
      'POST',
      '/recover',
      body: {'recoveryCode': typed},
    );
    expect(s, 200);
    expect(recovered['patientId'], id);
    final newToken = recovered['token']! as String;
    expect(newToken, isNot(oldToken));
    expect(recovered['recoveryCode'], isNot(code));

    expect((await p.call('GET', '/connections', token: oldToken)).$1, 401);
    expect((await p.call('GET', '/connections', token: newToken)).$1, 200);
    // Kod bir kez kullanılır.
    expect((await p.call('POST', '/recover', body: {'recoveryCode': code})).$1, 404);

    // Hasta yeni kod isteyebilir; bir öncekisi geçersiz olur.
    final (s3, again) = await p.call('POST', '/patients/recovery', token: newToken);
    expect(s3, 201);
    expect(
      (await p.call('POST', '/recover', body: {'recoveryCode': recovered['recoveryCode']})).$1,
      404,
    );
    expect(
      (await p.call('POST', '/recover', body: {'recoveryCode': again['recoveryCode']})).$1,
      200,
    );
    expect((await p.call('POST', '/patients/recovery', token: 'doctor')).$1, 403);
    expect(
      p.store.auditForPatient(id).where((e) => e.description.contains('yeni telefona')),
      hasLength(2),
    );
  });

  test('kurtarmada hatalı denemeler sınırlanır', () async {
    final p = _Portal();
    for (var i = 0; i < PortalApi.recoveryFailuresPerMinute; i++) {
      expect((await p.call('POST', '/recover', body: {'recoveryCode': 'X$i'})).$1, 404);
    }
    expect((await p.call('POST', '/recover', body: {'recoveryCode': 'X'})).$1, 429);
    p.now = p.now.add(const Duration(minutes: 1));
    expect((await p.call('POST', '/recover', body: {'recoveryCode': 'X'})).$1, 404);
  });

  group('aile grupları', () {
    const sister = '7a7a7a7a-1111-4222-8333-944455556666';
    late _Portal p;
    setUp(() {
      p = _Portal();
      p.store.addAccount(
        const Account(id: sister, role: Role.patient, name: '-'),
        'sister',
      );
    });

    Future<Map<String, Object?>> groupOf(String token, String id) async {
      final (_, list) = await p.call('GET', '/groups', token: token);
      return (list['groups']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((g) => g['id'] == id);
    }

    test('kişiye özel kodla katılan davetteki adı alır; paylaşım rızayla', () async {
      final (s1, g) = await p.call('POST', '/groups', token: 'patient', body: {'name': 'Kaya ailesi'});
      expect(s1, 201);
      final id = g['id']! as String;
      expect(g['ownedByMe'], isTrue);
      expect(g['inviteCode'], matches(RegExp(r'^[A-Z2-9]{6}$')));

      final (s2, inv) = await p.call(
        'POST',
        '/groups/$id/members',
        token: 'patient',
        body: {'name': 'Ablam'},
      );
      expect(s2, 201);
      final code = inv['code']! as String;
      expect(code, isNot(g['inviteCode']));
      // Sahip olmayan davet edemez.
      expect(
        (await p.call('POST', '/groups/$id/members', token: 'sister', body: {'name': 'x'})).$1,
        404,
      );

      expect((await p.call('POST', '/groups/join', token: 'sister', body: {'code': 'YOKKOD'})).$1, 404);
      final (s3, joined) = await p.call(
        'POST',
        '/groups/join',
        token: 'sister',
        body: {'code': code.toLowerCase()},
      );
      expect(s3, 200);
      expect(joined['ownedByMe'], isFalse);
      expect(joined['inviteCode'], '', reason: 'grup kodu yalnızca sahibine');
      final members = (joined['members']! as List).cast<Map>();
      expect(members.first['isOwner'], isTrue);
      expect(members.last['name'], 'Ablam');
      expect(members.last['isMe'], isTrue);
      expect(members.last['pending'], isFalse);
      // Kod bir kez kullanılır.
      expect(p.store.memberByInvite(code), isNull);

      // Paylaşım yokken abla hastanın verisini göremez.
      await p.call('POST', '/fhir', token: 'patient', body: _bundle());
      expect((await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'sister')).$1, 403);

      await p.call('PUT', '/groups/$id/consent', token: 'patient', body: {
        'scopes': ['spo2'],
      });
      final (s4, seen) = await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'sister');
      expect(s4, 200);
      expect(_entries(seen).map((o) => (o['code'] as Map)['coding']).toString(), contains('59408-5'));
      expect(seen['total'], 1, reason: 'yalnızca SpO2');
      final owner = await groupOf('sister', id);
      expect(((owner['members']! as List).first as Map)['shares'], ['spo2']);

      // Sahibe katılım bildirimi gider.
      final (_, list) = await p.call('GET', '/groups', token: 'patient');
      expect((list['messages']! as List).single, containsPair('from', 'Ablam'));

      // Ayrılınca erişim biter.
      expect((await p.call('DELETE', '/groups/$id', token: 'sister')).$1, 200);
      expect((await p.call('GET', '/fhir/Observation?patient=$_patientId', token: 'sister')).$1, 403);
      expect(p.store.group(id), isNotNull);
    });

    test('grup koduyla katılan adsız; sahip çıkarır ve grubu siler', () async {
      final (_, g) = await p.call('POST', '/groups', token: 'patient', body: {'name': 'Ev'});
      final id = g['id']! as String;
      final (_, joined) = await p.call('POST', '/groups/join', token: 'sister', body: {'code': g['inviteCode']});
      final me = (joined['members']! as List).cast<Map>().last;
      expect(me['name'], '');
      await p.call('PUT', '/groups/$id/consent', token: 'sister', body: {
        'scopes': ['heartRate'],
      });
      // Üye başkasını çıkaramaz; sahip çıkarır.
      expect((await p.call('DELETE', '/groups/$id/members/${me['id']}', token: 'sister')).$1, 404);
      expect((await p.call('DELETE', '/groups/$id/members/${me['id']}', token: 'patient')).$1, 200);
      expect((await p.call('GET', '/groups', token: 'sister')).$2['groups'], isEmpty);
      expect(
        p.store.auditForPatient(sister).where((e) => e.description.contains('Gruptan çıkarıldı')),
        hasLength(1),
      );

      expect((await p.call('DELETE', '/groups/$id', token: 'patient')).$1, 200);
      expect(p.store.group(id), isNull);
      expect(p.store.members(id), isEmpty);
      expect((await p.call('GET', '/groups', token: 'doctor')).$1, 403);
    });
  });

  test('gizlilik politikası anahtarsız ve dört dilde', () async {
    final p = _Portal();
    Future<(int, String, Map<String, String>)> get(String path, [String? lang]) async {
      final r = await p.api.handler(
        Request(
          'GET',
          Uri.parse('http://portal.test$path'),
          headers: {'accept-language': ?lang},
        ),
      );
      return (r.statusCode, await r.readAsString(), r.headers);
    }

    final (s, tr, headers) = await get('/gizlilik');
    expect(s, 200);
    expect(headers['content-type'], startsWith('text/html'));
    expect(headers['content-security-policy'], contains("default-src 'none'"));
    expect(tr, contains('<html lang="tr"'));
    expect(tr, contains('KVKK'));
    expect(tr, contains('Hukuki sebep'));

    final (_, en, _) = await get('/privacy', 'en-GB,en;q=0.9');
    expect(en, contains('Privacy policy'));
    final (_, ar, _) = await get('/privacy?lang=ar');
    expect(ar, contains('dir="rtl"'));
    final (_, de, _) = await get('/gizlilik', 'de');
    expect(de, contains('Datenschutzerklärung'));
    for (final lang in PanelText.supported) {
      expect(PrivacyPage.of(lang).sections, hasLength(PrivacyPage.of('tr').sections.length));
    }
  });
}
