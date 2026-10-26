import 'dart:convert';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _patientId = '6f1c2a3e-1111-4222-8333-944455556666';
final _now = DateTime.utc(2026, 10, 20, 12);

StoredObservation _obs(
  String code,
  DateTime t,
  double? v, {
  Map<String, double>? components,
  DateTime? end,
}) => StoredObservation(
  patientId: _patientId,
  identifier: 'test|$code-${t.toIso8601String()}',
  code: code,
  effective: t,
  resource: {
    'resourceType': 'Observation',
    if (v != null) 'valueQuantity': {'value': v},
    if (end != null)
      'effectivePeriod': {
        'start': t.toIso8601String(),
        'end': end.toIso8601String(),
      },
    if (components != null)
      'component': [
        for (final e in components.entries)
          {
            'code': {
              'coding': [
                {'code': e.key},
              ],
            },
            'valueQuantity': {'value': e.value},
          },
      ],
  },
);

/// [minutes] dakika önceden başlayıp her [step] dakikada bir ölçüm.
List<StoredObservation> _series(
  String code,
  List<double> values, {
  int minutesAgo = 60,
  int step = 5,
}) => [
  for (var i = 0; i < values.length; i++)
    _obs(
      code,
      _now.subtract(Duration(minutes: minutesAgo - i * step)),
      values[i],
    ),
];

MemoryPortalStore _store({
  Set<ShareScope> scopes = const {
    ShareScope.heartRate,
    ShareScope.spo2,
    ShareScope.bloodPressure,
    ShareScope.temperature,
    ShareScope.activity,
  },
  DateTime? consentStart,
}) => MemoryPortalStore()
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
  )
  ..addConsent(
    Consent(
      id: 'c-1',
      patientId: _patientId,
      actorId: 'dr-1',
      scopes: scopes,
      start: consentStart ?? _now.subtract(const Duration(days: 3)),
      end: _now.add(const Duration(days: 30)),
    ),
  );

void main() {
  group('uyarı kuralları', () {
    test('SpO2 10 dk %90 altında: kritik uyarı, en düşük değerle', () {
      final store = _store();
      // 90, 88, 86, 87 (15 dk süren düşüş), sonra 95.
      _series('59408-5', [92, 88, 86, 87, 95]).forEach(store.addObservation);
      final engine = AlertEngine(store);
      final created = engine.scan(_now);
      expect(created, hasLength(1));
      final a = created.single;
      expect(a.kind, AlertKind.spo2Low);
      expect(a.kind.severity, AlertSeverity.critical);
      expect(a.value, 86);
      expect(a.start, _now.subtract(const Duration(minutes: 55)));
      expect(a.lastSeen, _now.subtract(const Duration(minutes: 45)));
      expect(a.created, _now);
      // İkinci tarama aynı uyarıyı yeniden açmaz.
      expect(engine.scan(_now), isEmpty);
      expect(store.alertsOf('dr-1'), hasLength(1));
      // Başka hekim, rızası olmadığı için uyarı almaz.
      expect(store.alertsOf('dr-2'), isEmpty);
    });

    test('kısa düşüş (10 dk altı) uyarı değil', () {
      final store = _store();
      _series('59408-5', [95, 88, 95, 89, 96]).forEach(store.addObservation);
      expect(AlertEngine(store).scan(_now), isEmpty);
    });

    test('yüksek nabız egzersizde sayılmaz, egzersiz dışında sayılır', () {
      final store = _store();
      // 60–40 dk önce egzersiz, nabız 150.
      store
        ..addObservation(
          _obs(
            'workout',
            _now.subtract(const Duration(minutes: 60)),
            null,
            end: _now.subtract(const Duration(minutes: 40)),
          ),
        )
        ..addObservation(
          _obs('8867-4', _now.subtract(const Duration(minutes: 55)), 150),
        )
        ..addObservation(
          _obs('8867-4', _now.subtract(const Duration(minutes: 45)), 155),
        );
      expect(AlertEngine(store).scan(_now), isEmpty);
      // Dinlenirken 25 dk boyunca 130+.
      _series('8867-4', [
        130,
        132,
        135,
        131,
      ], minutesAgo: 20).forEach(store.addObservation);
      final a = AlertEngine(store).scan(_now).single;
      expect(a.kind, AlertKind.heartRateHigh);
      expect(a.value, 135);
    });

    test('düşük nabız, tansiyon krizi ve ateş', () {
      final store = _store();
      _series('8867-4', [
        38,
        36,
        39,
      ], minutesAgo: 120).forEach(store.addObservation);
      store
        ..addObservation(
          _obs(
            '85354-9',
            _now.subtract(const Duration(hours: 1)),
            null,
            components: {'8480-6': 185, '8462-4': 110},
          ),
        )
        ..addObservation(
          _obs(
            '85354-9',
            _now.subtract(const Duration(hours: 2)),
            null,
            components: {'8480-6': 150, '8462-4': 95},
          ),
        )
        ..addObservation(
          _obs('8310-5', _now.subtract(const Duration(hours: 3)), 38.4),
        );
      final kinds = {for (final a in AlertEngine(store).scan(_now)) a.kind: a};
      expect(kinds.keys, {
        AlertKind.heartRateLow,
        AlertKind.bloodPressureCrisis,
        AlertKind.fever,
      });
      expect(kinds[AlertKind.heartRateLow]!.value, 36);
      expect(kinds[AlertKind.bloodPressureCrisis]!.value, 185);
      expect(kinds[AlertKind.bloodPressureCrisis]!.value2, 110);
      expect(kinds[AlertKind.fever]!.kind.severity, AlertSeverity.warning);
    });

    test('rızada olmayan tür uyarı üretmez', () {
      final store = _store(scopes: {ShareScope.heartRate});
      _series('59408-5', [85, 85, 85, 85]).forEach(store.addObservation);
      store.addObservation(
        _obs('8867-4', _now.subtract(const Duration(minutes: 5)), 70),
      );
      expect(AlertEngine(store).scan(_now), isEmpty);
    });

    test('24 saat veri yoksa uyarı; veri gelince kendiliğinden kapanır', () {
      final store = _store();
      store.addObservation(
        _obs('8867-4', _now.subtract(const Duration(hours: 30)), 70),
      );
      final engine = AlertEngine(store);
      final a = engine.scan(_now).single;
      expect(a.kind, AlertKind.noData);
      expect(a.start, _now.subtract(const Duration(hours: 30)));
      expect(engine.scan(_now.add(const Duration(hours: 1))), isEmpty);

      store.addObservation(
        _obs('8867-4', _now.add(const Duration(hours: 2)), 72),
      );
      engine.scan(_now.add(const Duration(hours: 2, minutes: 1)));
      final closed = store.alert(a.id)!;
      expect(closed.open, isFalse);
      expect(closed.resolvedAt, _now.add(const Duration(hours: 2, minutes: 1)));
      expect(closed.ackAt, isNull);
    });

    test('yeni rıza ilk 24 saatte veri gelmedi uyarısı vermez', () {
      final store = _store(
        consentStart: _now.subtract(const Duration(hours: 5)),
      );
      expect(AlertEngine(store).scan(_now), isEmpty);
    });

    test('Gördüm: yalnızca sahibi kapatır; not ve zaman kalır', () {
      final store = _store();
      _series('59408-5', [85, 85, 85, 85]).forEach(store.addObservation);
      final engine = AlertEngine(store);
      final a = engine.scan(_now).single;
      final later = _now.add(const Duration(minutes: 7));
      expect(engine.acknowledge(a.id, 'dr-2', 'x', later), isNull);
      final acked = engine.acknowledge(
        a.id,
        'dr-1',
        '  Hasta arandı  ',
        later,
      )!;
      expect(acked.open, isFalse);
      expect(acked.ackBy, 'dr-1');
      expect(acked.ackAt, later);
      expect(acked.note, 'Hasta arandı');
      // İkinci kez kapatılamaz; aynı olay yeni uyarı açmaz.
      expect(engine.acknowledge(a.id, 'dr-1', null, later), isNull);
      expect(engine.scan(later), isEmpty);
    });

    test('şifreli depoya giden olay geri okunur', () {
      final a = Alert(
        id: 'al-1',
        ownerId: 'dr-1',
        patientId: _patientId,
        kind: AlertKind.bloodPressureCrisis,
        start: _now,
        lastSeen: _now,
        created: _now,
        value: 185,
        value2: 110,
        ackAt: _now.add(const Duration(minutes: 3)),
        ackBy: 'dr-1',
        note: 'Not',
      );
      final b = Alert.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, Object?>,
      );
      expect(b.toJson(), a.toJson());
    });
  });

  group('panel', () {
    Future<Response> send(
      PortalApi api,
      String method,
      String path, {
      String? cookie,
      Map<String, String>? form,
      String? bearer,
      Object? json,
      String? referer,
    }) async => await api.handler(
      Request(
        method,
        Uri.parse('http://portal.test$path'),
        headers: {
          'cookie': ?cookie,
          'referer': ?referer,
          if (bearer != null) 'authorization': 'Bearer $bearer',
          if (form != null) 'content-type': 'application/x-www-form-urlencoded',
        },
        body: form != null
            ? [
                for (final e in form.entries)
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
              ].join('&')
            : json == null
            ? null
            : jsonEncode(json),
      ),
    );

    Map<String, Object?> spo2Bundle(List<int> values) => {
      'resourceType': 'Bundle',
      'type': 'collection',
      'entry': [
        {
          'resource': {'resourceType': 'Patient', 'id': _patientId},
        },
        for (var i = 0; i < values.length; i++)
          {
            'resource': {
              'resourceType': 'Observation',
              'identifier': [
                {
                  'system': 'https://bileklik.app/fhir/observation',
                  'value': 'spo2-$i',
                },
              ],
              'status': 'final',
              'code': {
                'coding': [
                  {'system': 'http://loinc.org', 'code': '59408-5'},
                ],
              },
              'subject': {'reference': 'urn:uuid:$_patientId'},
              'effectiveDateTime': _now
                  .subtract(Duration(minutes: 30 - i * 5))
                  .toIso8601String(),
              'valueQuantity': {'value': values[i], 'unit': '%'},
            },
          },
      ],
    };

    test(
      'veri gelince uyarı açılır, panoda görünür, Gördüm ile kayda geçer',
      () async {
        var clock = _now;
        final store = _store();
        final api = PortalApi(store, clock: () => clock, random: Random(3));
        final up = await send(
          api,
          'POST',
          '/fhir',
          bearer: 'patient',
          json: spo2Bundle([96, 87, 86, 88, 95]),
        );
        expect(up.statusCode, 200);
        // Uyarı veri geldiği anda açıldı.
        expect(store.alertsOf('dr-1').single.created, _now);

        final login = await send(
          api,
          'POST',
          '/panel/login',
          form: {'token': 'doctor'},
        );
        final cookie = login.headers['set-cookie']!.split(';').first;
        clock = _now.add(const Duration(minutes: 20));
        final home = await (await send(
          api,
          'GET',
          '/panel',
          cookie: cookie,
        )).readAsString();
        expect(home, contains('Açık uyarılar'));
        expect(home, contains('SpO2 düşük'));
        expect(home, contains('En düşük %86'));
        // 15 dakikayı geçti: gecikti.
        expect(home, contains('Gecikti'));
        expect(home, contains('href="/panel/alerts"'));

        final id = store.alertsOf('dr-1').single.id;
        final csrf = RegExp(
          r'name="csrf" value="([0-9a-f]+)"',
        ).firstMatch(home)!.group(1)!;
        // Yanlış CSRF reddedilir.
        final bad = await send(
          api,
          'POST',
          '/panel/alerts/$id/ack',
          cookie: cookie,
          form: {'csrf': 'x', 'note': 'n'},
        );
        expect(bad.statusCode, 403);
        final ack = await send(
          api,
          'POST',
          '/panel/alerts/$id/ack',
          cookie: cookie,
          form: {'csrf': csrf, 'note': 'Hasta arandı, iyi'},
        );
        expect(ack.statusCode, 303);
        expect(ack.headers['location'], '/panel');

        final after = await (await send(
          api,
          'GET',
          '/panel',
          cookie: cookie,
        )).readAsString();
        expect(after, contains('Açık uyarı yok.'));

        final log = await (await send(
          api,
          'GET',
          '/panel/alerts',
          cookie: cookie,
        )).readAsString();
        expect(log, contains('Uyarı kaydı'));
        expect(log, contains('Dr. Ayşe Kaya'));
        expect(log, contains('20 dk sonra yanıtlandı'));
        expect(log, contains('Hasta arandı, iyi'));

        // Başka hekim bu uyarıyı kapatamaz ve kayıtta görmez.
        final other = await send(
          api,
          'POST',
          '/panel/login',
          form: {'token': 'stranger'},
        );
        final otherCookie = other.headers['set-cookie']!.split(';').first;
        final otherLog = await (await send(
          api,
          'GET',
          '/panel/alerts',
          cookie: otherCookie,
        )).readAsString();
        expect(otherLog, isNot(contains('SpO2 düşük')));
      },
    );

    test('hasta verisini silince uyarıları da silinir', () async {
      final store = _store();
      final api = PortalApi(store, clock: () => _now, random: Random(3));
      await send(
        api,
        'POST',
        '/fhir',
        bearer: 'patient',
        json: spo2Bundle([85, 85, 85, 85]),
      );
      expect(store.alertsOf('dr-1'), isNotEmpty);
      final del = await send(
        api,
        'DELETE',
        '/patients/$_patientId/data',
        bearer: 'patient',
      );
      expect(del.statusCode, 200);
      expect(store.alertsOf('dr-1'), isEmpty);
    });

    test('uyarı kaydı dört dilde açılır', () async {
      final api = PortalApi(_store(), clock: () => _now, random: Random(3));
      final login = await send(
        api,
        'POST',
        '/panel/login',
        form: {'token': 'doctor'},
      );
      final cookie = login.headers['set-cookie']!.split(';').first;
      for (final (lang, title) in [
        ('en', 'Alert log'),
        ('ar', 'سجل التنبيهات'),
        ('de', 'Warnprotokoll'),
      ]) {
        final html = await (await send(
          api,
          'GET',
          '/panel/alerts?lang=$lang',
          cookie: cookie,
        )).readAsString();
        expect(html, contains(title));
      }
    });
  });
}
