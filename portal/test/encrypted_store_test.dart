import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _patientId = '6f1c2a3e-1111-4222-8333-944455556666';
final _key = List<int>.generate(32, (i) => i * 7 % 256);
final _t0 = DateTime.utc(2026, 10, 20, 9);

Map<String, Object?> _bundle() => {
  'resourceType': 'Bundle',
  'type': 'collection',
  'entry': [
    {
      'resource': {'resourceType': 'Patient', 'id': _patientId},
    },
    for (final (i, v) in [(0, 72), (1, 80)])
      {
        'resource': {
          'resourceType': 'Observation',
          'identifier': [
            {
              'system': 'https://bileklik.app/fhir/observation',
              'value': 'heartRate-$i',
            },
          ],
          'status': 'final',
          'code': {
            'coding': [
              {'system': 'http://loinc.org', 'code': '8867-4'},
            ],
          },
          'subject': {'reference': 'urn:uuid:$_patientId'},
          'effectiveDateTime': _t0.add(Duration(hours: i)).toIso8601String(),
          'valueQuantity': {'value': v},
        },
      },
  ],
};

Future<(int, Object?)> _call(
  PortalApi api,
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final r = await api.handler(
    Request(
      method,
      Uri.parse('http://portal.test$path'),
      headers: {if (token != null) 'authorization': 'Bearer $token'},
      body: body == null ? null : jsonEncode(body),
    ),
  );
  final text = await r.readAsString();
  return (r.statusCode, text.isEmpty ? null : jsonDecode(text));
}

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('portal-store-');
    file = File('${dir.path}/portal.log');
  });
  tearDown(() => dir.delete(recursive: true));

  /// Hasta hesabı, hekim, davet, rıza ve iki ölçüm.
  Future<(EncryptedPortalStore, String)> seeded() async {
    final store = await EncryptedPortalStore.open(file, _key, random: Random(1));
    store.addAccount(
      const Account(
        id: 'dr-1',
        role: Role.clinician,
        name: 'Dr. Ayşe Kaya',
        organization: 'Kardiyoloji Polikliniği',
      ),
      'doctor-token',
    );
    final api = PortalApi(store, clock: () => _t0, random: Random(2));
    final (s1, reg) = await _call(
      api,
      'POST',
      '/patients',
      body: {'patientId': _patientId},
    );
    expect(s1, 201);
    final token = (reg! as Map)['token'] as String;
    expect((await _call(api, 'POST', '/fhir', token: token, body: _bundle())).$1, 200);
    final (_, invite) = await _call(
      api,
      'POST',
      '/invites',
      token: 'doctor-token',
      body: {
        'purpose': 'Ritim takibi',
        'scopes': ['heartRate'],
        'days': 30,
      },
    );
    final code = (invite! as Map)['code'] as String;
    expect(
      (await _call(
        api,
        'POST',
        '/invites/$code/accept',
        token: token,
        body: {
          'scopes': ['heartRate'],
        },
      )).$1,
      201,
    );
    store.addFeedback(
      FeedbackEntry(
        id: 'feedback-1',
        time: _t0,
        category: FeedbackCategory.idea,
        message: 'Grafik güzel',
      ),
    );
    await store.flush();
    return (store, token);
  }

  test('yeniden açılınca tüm durum geri gelir', () async {
    final (_, token) = await seeded();
    final again = await EncryptedPortalStore.open(file, _key);
    expect(again.accountByToken(token)!.id, _patientId);
    expect(again.accountByToken('doctor-token')!.organization, 'Kardiyoloji Polikliniği');
    expect(again.observations(_patientId), hasLength(2));
    final consent = again.consentsForPatient(_patientId).single;
    expect(consent.scopes, {ShareScope.heartRate});
    expect(consent.activeAt(_t0), isTrue);
    expect(again.auditForPatient(_patientId), isNotEmpty);
    expect(again.feedback().single.message, 'Grafik güzel');

    // Yeniden açılan depo üzerinden hekim okuyabilir; aynı kayıt tekrar
    // yazılmaz.
    final api = PortalApi(again, clock: () => _t0);
    final (s, seen) = await _call(
      api,
      'GET',
      '/fhir/Observation?patient=$_patientId',
      token: 'doctor-token',
    );
    expect(s, 200);
    expect((seen! as Map)['total'], 2);
    final (_, outcome) = await _call(
      api,
      'POST',
      '/fhir',
      token: token,
      body: _bundle(),
    );
    expect(jsonEncode(outcome), contains('created=0 duplicates=2'));
    // Erişim kayıtları yazılmadan test klasörü silinmesin.
    await again.flush();
  });

  test('dosyada açık metin ve oturum anahtarı yok', () async {
    final (store, token) = await seeded();
    final raw = await file.readAsString();
    for (final secret in [_patientId, '8867-4', 'Ayşe', 'Ritim', token, 'doctor-token', 'Grafik']) {
      expect(raw, isNot(contains(secret)), reason: secret);
    }
    // Çözülmüş olaylarda bile anahtarın kendisi değil özeti var.
    expect(store.eventCount, greaterThan(5));
    final again = await EncryptedPortalStore.open(file, _key);
    expect(again.accountByToken(tokenHash(token)), isNull);
  });

  test('yanlış anahtarla açılmaz', () async {
    await seeded();
    final wrong = List<int>.filled(32, 1);
    await expectLater(
      EncryptedPortalStore.open(file, wrong),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      EncryptedPortalStore.open(file, [1, 2, 3]),
      throwsArgumentError,
    );
  });

  test('rıza geri alınması kalıcıdır', () async {
    final (store, token) = await seeded();
    final api = PortalApi(store, clock: () => _t0.add(const Duration(hours: 1)));
    final id = store.consentsForPatient(_patientId).single.id;
    expect((await _call(api, 'DELETE', '/consents/$id', token: token)).$1, 200);
    await store.flush();
    final again = await EncryptedPortalStore.open(file, _key);
    expect(again.consent(id)!.activeAt(_t0.add(const Duration(hours: 2))), isFalse);
  });

  test('unutulma hakkı: ölçümler dosyadan da silinir, kayıtlar kalır', () async {
    final (store, token) = await seeded();
    final before = store.eventCount;
    final api = PortalApi(store, clock: () => _t0);
    expect(
      (await _call(api, 'DELETE', '/patients/$_patientId/data', token: token)).$1,
      200,
    );
    await store.flush();
    // İki ölçüm olayı çıktı; rıza bitişi ve erişim kaydı eklendi.
    expect(store.eventCount, before - 2 + 2);
    expect(await file.exists(), isTrue);
    expect(File('${file.path}.tmp').existsSync(), isFalse);

    final again = await EncryptedPortalStore.open(file, _key);
    expect(again.observations(_patientId), isEmpty);
    expect(again.consentsForPatient(_patientId).single.activeAt(_t0), isFalse);
    expect(
      again.auditForPatient(_patientId).map((e) => e.action),
      contains(AuditAction.delete),
    );
    expect(again.eventCount, store.eventCount);
  });

  test('kimlikler yeniden başlatmada çakışmaz', () async {
    final a = await EncryptedPortalStore.open(file, _key);
    final b = await EncryptedPortalStore.open(file, _key);
    expect(a.nextId('consent'), isNot(b.nextId('consent')));
    expect(EncryptedPortalStore.newKey(), hasLength(44));
  });
}
