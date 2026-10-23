import 'dart:convert';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _patientId = '6f1c2a3e-1111-4222-8333-944455556666';
final _now = DateTime.utc(2026, 10, 20, 12);

class _Portal {
  _Portal() {
    store
      ..addAccount(
        const Account(id: _patientId, role: Role.patient, name: '-'),
        'patient',
      )
      ..addAccount(
        const Account(
          id: 'dr-1',
          role: Role.clinician,
          name: 'Dr. <b>Ayşe</b> Kaya',
          organization: 'Kardiyoloji Polikliniği',
        ),
        'doctor',
      )
      ..addAccount(
        const Account(id: 'dr-2', role: Role.clinician, name: 'Dr. Başka'),
        'stranger',
      );
    api = PortalApi(store, clock: () => _now, random: Random(3));
  }

  final store = MemoryPortalStore();
  late final PortalApi api;

  Future<Response> send(
    String method,
    String path, {
    String? cookie,
    Map<String, Object>? form,
    String? bearer,
    Object? json,
  }) => api.handler(
    Request(
      method,
      Uri.parse('http://portal.test$path'),
      headers: {
        'cookie': ?cookie,
        if (bearer != null) 'authorization': 'Bearer $bearer',
        if (form != null) 'content-type': 'application/x-www-form-urlencoded',
      },
      body: form != null
          ? [
              for (final e in form.entries)
                for (final v in e.value is List ? e.value as List : [e.value])
                  '${Uri.encodeQueryComponent(e.key)}='
                      '${Uri.encodeQueryComponent('$v')}',
            ].join('&')
          : json == null
          ? null
          : jsonEncode(json),
    ),
  );

  /// Giriş yapar; oturum çerezini döndürür.
  Future<String> login(String token) async {
    final r = await send('POST', '/panel/login', form: {'token': token});
    expect(r.statusCode, 303);
    final setCookie = r.headers['set-cookie']!;
    expect(setCookie, contains('HttpOnly'));
    expect(setCookie, contains('SameSite=Strict'));
    return setCookie.split(';').first;
  }

  Future<String> page(String path, String cookie) async {
    final r = await send('GET', path, cookie: cookie);
    return r.readAsString();
  }

  static String csrf(String html) =>
      RegExp(r'name="csrf" value="([0-9a-f]+)"').firstMatch(html)!.group(1)!;
}

Map<String, Object?> _bundle() => {
  'resourceType': 'Bundle',
  'type': 'collection',
  'entry': [
    {
      'resource': {'resourceType': 'Patient', 'id': _patientId},
    },
    for (final (kind, code, i, v, unit) in [
      ('heartRate', '8867-4', 1, 72, 'beats/minute'),
      ('heartRate', '8867-4', 30, 80, 'beats/minute'),
      ('spo2', '59408-5', 1, 97, '%'),
    ])
      {
        'resource': {
          'resourceType': 'Observation',
          'identifier': [
            {'system': 'https://bileklik.app/fhir/observation', 'value': '$kind-$i'},
          ],
          'status': 'final',
          'code': {
            'coding': [
              {'system': 'http://loinc.org', 'code': code},
            ],
          },
          'subject': {'reference': 'urn:uuid:$_patientId'},
          'effectiveDateTime':
              _now.subtract(Duration(hours: i)).toIso8601String(),
          'valueQuantity': {'value': v, 'unit': unit},
        },
      },
  ],
};

void main() {
  test('girişsiz panel giriş formunu gösterir; yanlış anahtar reddedilir', () async {
    final p = _Portal();
    final r = await p.send('GET', '/panel');
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], startsWith('text/html'));
    expect(r.headers['content-security-policy'], contains("default-src 'none'"));
    expect(await r.readAsString(), contains('name="token"'));

    final bad = await p.send('POST', '/panel/login', form: {'token': 'yanlis'});
    expect(bad.statusCode, 401);
    expect(await bad.readAsString(), contains('Anahtar geçersiz'));

    // Hasta paneli kullanamaz.
    final patient = await p.send('POST', '/panel/login', form: {'token': 'patient'});
    expect(patient.statusCode, 401);
  });

  test('hekim davet oluşturur; CSRF olmadan oluşturamaz', () async {
    final p = _Portal();
    final cookie = await p.login('doctor');
    final home = await p.page('/panel', cookie);
    expect(home, contains('Henüz rıza vermiş hasta yok'));
    // Ad HTML olarak değil metin olarak yazılır.
    expect(home, contains('Dr. &lt;b&gt;Ayşe&lt;/b&gt; Kaya'));
    expect(home, isNot(contains('<b>Ayşe</b>')));

    final noCsrf = await p.send(
      'POST',
      '/panel/invites',
      cookie: cookie,
      form: {'purpose': 'Ritim', 'scope': 'heartRate', 'days': '30'},
    );
    expect(noCsrf.statusCode, 403);

    final r = await p.send(
      'POST',
      '/panel/invites',
      cookie: cookie,
      form: {
        'csrf': _Portal.csrf(home),
        'purpose': 'Ritim takibi',
        'scope': ['heartRate', 'ecg'],
        'days': '90',
      },
    );
    expect(r.statusCode, 201);
    final code = RegExp(r'class="code">([A-Z2-9]{7})<')
        .firstMatch(await r.readAsString())!
        .group(1)!;
    final invite = p.store.invite(code)!;
    expect(invite.actorId, 'dr-1');
    expect(invite.requested, {ShareScope.heartRate, ShareScope.ecg});
    expect(invite.duration, const Duration(days: 90));

    final empty = await p.send(
      'POST',
      '/panel/invites',
      cookie: cookie,
      form: {'csrf': _Portal.csrf(home), 'purpose': '', 'days': '90'},
    );
    expect(empty.statusCode, 400);
  });

  test('hasta sayfası yalnızca rızadaki türleri gösterir ve kayda geçer', () async {
    final p = _Portal();
    final cookie = await p.login('doctor');
    final home = await p.page('/panel', cookie);
    final created = await p.send(
      'POST',
      '/panel/invites',
      cookie: cookie,
      form: {
        'csrf': _Portal.csrf(home),
        'purpose': 'Ritim takibi',
        'scope': ['heartRate', 'spo2'],
        'days': '30',
      },
    );
    final code = RegExp(r'class="code">([A-Z2-9]{7})<')
        .firstMatch(await created.readAsString())!
        .group(1)!;

    // Hasta yalnızca nabzı paylaşır ve veri yükler (uygulamanın API'si).
    final accept = await p.send(
      'POST',
      '/invites/$code/accept',
      bearer: 'patient',
      json: {
        'scopes': ['heartRate'],
      },
    );
    expect(accept.statusCode, 201);
    expect(
      (await p.send('POST', '/fhir', bearer: 'patient', json: _bundle())).statusCode,
      200,
    );

    final list = await p.page('/panel', cookie);
    expect(list, contains('>6f1c2a3e</a>'), reason: 'ekranda kısa kimlik');

    final detail = await p.page('/panel/patients/$_patientId', cookie);
    expect(detail, contains('Nabız'));
    expect(detail, contains('72 atım/dk'));
    expect(detail, contains('<svg class="spark"'));
    expect(detail, isNot(contains('SpO2</h2>')), reason: 'SpO2 paylaşılmadı');
    expect(detail, isNot(contains('97 %')));

    final reads = p.store
        .auditForPatient(_patientId)
        .where((e) => e.action == AuditAction.read && e.actorId == 'dr-1');
    expect(reads.single.success, isTrue);
    expect(reads.single.description, contains('2 ölçüm'));

    // Rızası olmayan hekim göremez; deneme kayda geçer.
    final other = await p.login('stranger');
    final denied = await p.send('GET', '/panel/patients/$_patientId', cookie: other);
    expect(denied.statusCode, 403);
    expect(
      p.store
          .auditForPatient(_patientId)
          .where((e) => e.actorId == 'dr-2' && !e.success),
      hasLength(1),
    );
  });

  test('çıkış oturumu kapatır; süresi dolan oturum geçmez', () async {
    var now = _now;
    final store = MemoryPortalStore()
      ..addAccount(
        const Account(id: 'dr-1', role: Role.clinician, name: 'Dr. A'),
        'doctor',
      );
    final api = PortalApi(store, clock: () => now, random: Random(4));
    Future<Response> send(String m, String path, {String? cookie, String? body}) =>
        api.handler(
          Request(
            m,
            Uri.parse('http://portal.test$path'),
            headers: {'cookie': ?cookie},
            body: body,
          ),
        );

    final login = await send('POST', '/panel/login', body: 'token=doctor');
    final cookie = login.headers['set-cookie']!.split(';').first;
    final home = await (await send('GET', '/panel', cookie: cookie)).readAsString();
    expect(home, contains('Çıkış'));

    now = now.add(PanelApi.sessionLength);
    final expired = await (await send('GET', '/panel', cookie: cookie)).readAsString();
    expect(expired, contains('name="token"'));

    now = _now;
    final again = await send('POST', '/panel/login', body: 'token=doctor');
    final c2 = again.headers['set-cookie']!.split(';').first;
    final h2 = await (await send('GET', '/panel', cookie: c2)).readAsString();
    final out = await send(
      'POST',
      '/panel/logout',
      cookie: c2,
      body: 'csrf=${_Portal.csrf(h2)}',
    );
    expect(out.statusCode, 303);
    expect(out.headers['set-cookie'], contains('Max-Age=0'));
    final after = await (await send('GET', '/panel', cookie: c2)).readAsString();
    expect(after, contains('name="token"'));
  });

  test('API yolları panelden etkilenmez', () async {
    final p = _Portal();
    expect((await p.send('GET', '/fhir/Consent')).statusCode, 401);
    expect((await p.send('GET', '/health')).statusCode, 200);
  });
}
