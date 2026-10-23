import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _patientId = '6f1c2a3e-1111-4222-8333-944455556666';
const _patient2 = '7a2d3b4f-2222-4333-8444-a55566667777';
final _now = DateTime.utc(2026, 10, 20, 12);
const _fast = PasswordHasher(iterations: 500);

/// Hekim panelinin hesap, hasta kaydı ve rapor akışları için küçük portal.
class _Portal {
  _Portal([PortalStore? store]) : store = store ?? MemoryPortalStore() {
    this.store
      ..addAccount(
        const Account(id: _patientId, role: Role.patient, name: '-'),
        'patient',
      )
      ..addAccount(
        const Account(id: _patient2, role: Role.patient, name: '-'),
        'patient2',
      )
      ..addAccount(
        const Account(id: 'dr-x', role: Role.clinician, name: 'Dr. Başka'),
        'stranger',
      );
    api = PortalApi(
      this.store,
      clock: () => _now,
      random: Random(5),
      passwords: _fast,
    );
  }

  final PortalStore store;
  late final PortalApi api;

  Future<Response> send(
    String method,
    String path, {
    String? cookie,
    Map<String, Object>? form,
    String? bearer,
    Object? json,
  }) async => await api.handler(
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
                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('$v')}',
            ].join('&')
          : json == null
          ? null
          : jsonEncode(json),
    ),
  );

  Future<String> page(String path, String cookie) async =>
      (await send('GET', path, cookie: cookie)).readAsString();

  static String csrfOf(String html) =>
      RegExp(r'name="csrf" value="([0-9a-f]+)"').firstMatch(html)!.group(1)!;

  static String cookieOf(Response r) =>
      r.headers['set-cookie']!.split(';').first;

  /// Hekim kaydı açar; oturum çerezini döner.
  Future<String> register({
    String email = 'ayse@klinik.test',
    String password = 'cok-gizli-sifre',
  }) async {
    final r = await send(
      'POST',
      '/panel/register',
      form: {
        'type': 'clinician',
        'name': 'Dr. Ayşe Kaya',
        'specialty': 'Kardiyoloji',
        'organization': 'Klinik',
        'license': 'TR-123',
        'email': email,
        'password': password,
        'password2': password,
        'terms': '1',
      },
    );
    expect(r.statusCode, 303, reason: await r.readAsString());
    return cookieOf(r);
  }

  /// Hasta ölçümlerini yükler.
  Future<void> upload(
    String token,
    String patientId,
    List<Map<String, Object?>> observations,
  ) async {
    final r = await send(
      'POST',
      '/fhir',
      bearer: token,
      json: {
        'resourceType': 'Bundle',
        'type': 'collection',
        'entry': [
          {
            'resource': {'resourceType': 'Patient', 'id': patientId},
          },
          for (final o in observations) {'resource': o},
        ],
      },
    );
    expect(r.statusCode, 200);
  }
}

var _seq = 0;
Map<String, Object?> _obs(
  String patientId,
  String code,
  DateTime at, {
  num? value,
  List<(String, num)> components = const [],
  DateTime? end,
}) => {
  'resourceType': 'Observation',
  'identifier': [
    {'system': 'https://bileklik.app/test', 'value': 'o-${_seq++}'},
  ],
  'status': 'final',
  'code': {
    'coding': [
      {'system': 'http://loinc.org', 'code': code},
    ],
  },
  'subject': {'reference': 'urn:uuid:$patientId'},
  if (end == null)
    'effectiveDateTime': at.toIso8601String()
  else
    'effectivePeriod': {
      'start': at.toIso8601String(),
      'end': end.toIso8601String(),
    },
  if (value != null) 'valueQuantity': {'value': value},
  if (components.isNotEmpty)
    'component': [
      for (final (c, v) in components)
        {
          'code': {
            'coding': [
              {'code': c},
            ],
          },
          'valueQuantity': {'value': v},
        },
    ],
};

StoredObservation _stored(Map<String, Object?> r) => StoredObservation(
  patientId: _patientId,
  identifier: '${(r['identifier'] as List).first}',
  code: (((r['code'] as Map)['coding'] as List).first as Map)['code'] as String,
  effective: DateTime.parse(
    (r['effectiveDateTime'] ?? (r['effectivePeriod'] as Map)['start'])
        as String,
  ),
  resource: r,
);

void main() {
  group('şifre', () {
    test('özet doğrular, yanlış şifre ve bozuk biçim reddedilir', () async {
      final h = await _fast.hash('dogru-sifre-123', random: Random(1));
      expect(h, startsWith(r'pbkdf2-sha256$500$'));
      expect(h, isNot(contains('dogru-sifre')));
      expect(await _fast.verify('dogru-sifre-123', h), isTrue);
      expect(await _fast.verify('yanlis-sifre-123', h), isFalse);
      expect(await _fast.verify('dogru-sifre-123', 'bozuk'), isFalse);
      // Tur sayısı özetin içinde: farklı ayarlı doğrulayıcı da okur.
      expect(
        await const PasswordHasher(iterations: 9).verify('dogru-sifre-123', h),
        isTrue,
      );
    });
  });

  group('hekim hesabı', () {
    test(
      'kayıt doğrular; hesap doğrulanmadı başlar ve uyarı görünür',
      () async {
        final p = _Portal();
        final form = (await p.send('GET', '/panel/register')).readAsString();
        expect(await form, contains('name="license"'));

        Future<String> bad(Map<String, Object> f) async {
          final r = await p.send('POST', '/panel/register', form: f);
          expect(r.statusCode, 400);
          return r.readAsString();
        }

        final base = <String, Object>{
          'name': 'Dr. <b>X</b>',
          'email': 'x@klinik.test',
          'password': 'cok-gizli-sifre',
          'password2': 'cok-gizli-sifre',
          'terms': '1',
        };
        expect(
          await bad({...base, 'password': 'kisa', 'password2': 'kisa'}),
          contains('en az 10'),
        );
        expect(
          await bad({...base, 'password2': 'baska-sifre-xx'}),
          contains('aynı değil'),
        );
        expect(
          await bad({...base, 'email': 'gecersiz'}),
          contains('Geçerli bir e-posta'),
        );
        final noTerms = await bad({...base}..remove('terms'));
        expect(noTerms, contains('beyanı onaylayın'));
        expect(
          noTerms,
          contains('Dr. &lt;b&gt;X&lt;/b&gt;'),
          reason: 'form değerleri kaçışlanır',
        );

        final cookie = await p.register();
        final me = p.store.accountByEmail('AYSE@klinik.test')!;
        expect(me.role, Role.clinician);
        expect(me.verified, isFalse);
        expect(me.licenseNo, 'TR-123');
        expect(p.store.passwordOf(me.id), startsWith('pbkdf2-sha256'));
        final home = await p.page('/panel', cookie);
        expect(home, contains('Hesabınız henüz doğrulanmadı'));
        expect(home, contains('Hasta kayıtları'));

        expect(
          await bad({...base, 'email': 'ayse@klinik.test'}),
          contains('Bu e-postayla bir hesap var'),
        );

        // Davet bilgisi uygulamaya doğrulanmadığını söyler.
        final invite = await p.send(
          'POST',
          '/invites',
          bearer: 'patient',
          json: {},
        );
        expect(invite.statusCode, 403);
        final html = await p.page('/panel', cookie);
        final r = await p.send(
          'POST',
          '/panel/invites',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'purpose': 'Takip',
            'scope': 'heartRate',
            'days': '30',
          },
        );
        final code = RegExp(
          r'class="code">([A-Z0-9]{7})<',
        ).firstMatch(await r.readAsString())!.group(1)!;
        final info =
            jsonDecode(
                  await (await p.send(
                    'GET',
                    '/invites/$code',
                    bearer: 'patient',
                  )).readAsString(),
                )
                as Map;
        expect(info['verified'], isFalse);
        expect(info['specialty'], 'Kardiyoloji');
      },
    );

    test(
      'e-posta ve şifreyle giriş; 5 hatalı denemeden sonra geçici kilit',
      () async {
        final p = _Portal();
        await p.register();
        Future<Response> login(
          String pw, {
          String email = 'ayse@klinik.test',
        }) => p.send(
          'POST',
          '/panel/login',
          form: {'email': email, 'password': pw},
        );

        final ok = await login('cok-gizli-sifre');
        expect(ok.statusCode, 303);
        expect(ok.headers['set-cookie'], contains('HttpOnly'));
        expect((await login('yanlis')).statusCode, 401);
        expect(
          (await login('cok-gizli-sifre', email: 'yok@klinik.test')).statusCode,
          401,
        );
        for (var i = 0; i < 4; i++) {
          await login('yanlis');
        }
        final locked = await login('cok-gizli-sifre');
        expect(locked.statusCode, 429);
        expect(await locked.readAsString(), contains('15 dakika'));
      },
    );

    test(
      'şifre değiştirme ve anahtarla açılan hesaba şifre belirleme',
      () async {
        final p = _Portal();
        var cookie = await p.register();
        var html = await p.page('/panel/account', cookie);
        expect(html, contains('TR-123'));
        expect(html, contains('Doğrulanmadı'));
        final wrong = await p.send(
          'POST',
          '/panel/account/password',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'current': 'yanlis',
            'password': 'yeni-sifre-12345',
            'password2': 'yeni-sifre-12345',
          },
        );
        expect(wrong.statusCode, 400);
        final ok = await p.send(
          'POST',
          '/panel/account/password',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'current': 'cok-gizli-sifre',
            'password': 'yeni-sifre-12345',
            'password2': 'yeni-sifre-12345',
          },
        );
        expect(await ok.readAsString(), contains('Şifre değiştirildi'));
        expect(
          (await p.send(
            'POST',
            '/panel/login',
            form: {'email': 'ayse@klinik.test', 'password': 'yeni-sifre-12345'},
          )).statusCode,
          303,
        );

        // Anahtarla açılan hekim e-posta ve şifre belirler.
        final r = await p.send(
          'POST',
          '/panel/login',
          form: {'token': 'stranger'},
        );
        cookie = _Portal.cookieOf(r);
        html = await p.page('/panel/account', cookie);
        expect(html, contains('Şifre belirle'));
        await p.send(
          'POST',
          '/panel/account/password',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'email': 'baska@klinik.test',
            'password': 'baska-sifre-123',
            'password2': 'baska-sifre-123',
          },
        );
        expect(p.store.accountByEmail('baska@klinik.test')?.id, 'dr-x');
        expect(p.store.accountByToken('stranger')?.email, 'baska@klinik.test');
      },
    );
  });

  group('hasta kayıtları', () {
    test(
      'kayıt oluşturulur, aranır, düzenlenir; başka hekim göremez',
      () async {
        final p = _Portal();
        final cookie = await p.register();
        var html = await p.page('/panel/records/new', cookie);
        final noCsrf = await p.send(
          'POST',
          '/panel/records',
          cookie: cookie,
          form: {'name': 'Ali'},
        );
        expect(noCsrf.statusCode, 403);
        final badBirth = await p.send(
          'POST',
          '/panel/records',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'name': 'Ali',
            'birth': '2030-01-01',
          },
        );
        expect(badBirth.statusCode, 400);
        final r = await p.send(
          'POST',
          '/panel/records',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'name': 'Ali <Veli>',
            'birth': '1970-05-20',
            'sex': 'male',
            'fileNo': 'P-77',
            'notes': 'Not',
          },
        );
        expect(r.statusCode, 303);
        final path = r.headers['location']!;
        final id = Uri.decodeComponent(path.split('/').last);
        final rec = p.store.record(id)!;
        expect(rec.ageAt(_now), 56);
        expect(rec.sex, Sex.male);

        html = await p.page(path, cookie);
        expect(html, contains('Ali &lt;Veli&gt;'));
        expect(html, contains('56 yaş'));
        expect(html, contains('Bağlı değil'));

        expect(
          await p.page('/panel?q=p-77', cookie),
          contains('Ali &lt;Veli&gt;'),
        );
        expect(
          await p.page('/panel?q=zzz', cookie),
          contains('Aramaya uyan kayıt yok'),
        );

        final edit = await p.send(
          'POST',
          path,
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'name': 'Ali Veli',
            'fileNo': 'P-78',
          },
        );
        expect(await edit.readAsString(), contains('Kaydedildi'));
        expect(p.store.record(id)!.fileNo, 'P-78');
        expect(p.store.record(id)!.birthDate, isNull);

        final other = _Portal.cookieOf(
          await p.send('POST', '/panel/login', form: {'token': 'stranger'}),
        );
        final foreign = await p.send('GET', path, cookie: other);
        expect(foreign.statusCode, 403);
        expect(await foreign.readAsString(), contains('Kayıt bulunamadı'));
        expect(await p.page('/panel', other), isNot(contains('Ali Veli')));
      },
    );

    test(
      'kayda özel davet kabul edilince kayıt bağlanır; bağ kaldırılır ve kayıt silinir',
      () async {
        final p = _Portal();
        final cookie = await p.register();
        var html = await p.page('/panel/records/new', cookie);
        final path = (await p.send(
          'POST',
          '/panel/records',
          cookie: cookie,
          form: {'csrf': _Portal.csrfOf(html), 'name': 'Zeynep Deneme'},
        )).headers['location']!;
        final id = Uri.decodeComponent(path.split('/').last);
        html = await p.page(path, cookie);
        final inv = await p.send(
          'POST',
          '$path/invite',
          cookie: cookie,
          form: {
            'csrf': _Portal.csrfOf(html),
            'purpose': 'Takip',
            'scope': ['heartRate', 'body'],
            'days': '180',
          },
        );
        expect(inv.statusCode, 201);
        final code = p.store.record(id)!.inviteCode!;
        expect(await inv.readAsString(), contains(code));
        expect(await p.page('/panel', cookie), contains('Davet bekliyor'));

        final accept = await p.send(
          'POST',
          '/invites/$code/accept',
          bearer: 'patient',
          json: {
            'scopes': ['heartRate'],
          },
        );
        expect(accept.statusCode, 201);
        expect(p.store.record(id)!.patientId, _patientId);
        expect(p.store.record(id)!.inviteCode, isNull);
        final home = await p.page('/panel', cookie);
        expect(home, contains('>Bağlı<'));
        expect(
          home,
          isNot(contains('>6f1c2a3e</a>')),
          reason: 'kayda bağlı olan ayrıca listelenmez',
        );
        html = await p.page(path, cookie);
        expect(html, contains('/panel/patients/$_patientId/report'));

        // Bağı kaldır: rıza sürer, bağlantı "kayda bağlanmamış" listesine düşer.
        await p.send(
          'POST',
          '$path/unlink',
          cookie: cookie,
          form: {'csrf': _Portal.csrfOf(html)},
        );
        expect(p.store.record(id)!.patientId, isNull);
        expect(await p.page('/panel', cookie), contains('>6f1c2a3e</a>'));

        // Elle yeniden bağla; rızası olmayanı bağlayamaz.
        html = await p.page(path, cookie);
        expect(html, contains('value="$_patientId"'));
        final denied = await p.send(
          'POST',
          '$path/link',
          cookie: cookie,
          form: {'csrf': _Portal.csrfOf(html), 'patient': _patient2},
        );
        expect(denied.statusCode, 403);
        await p.send(
          'POST',
          '$path/link',
          cookie: cookie,
          form: {'csrf': _Portal.csrfOf(html), 'patient': _patientId},
        );
        expect(p.store.record(id)!.patientId, _patientId);

        final noWord = await p.send(
          'POST',
          '$path/delete',
          cookie: cookie,
          form: {'csrf': _Portal.csrfOf(html), 'confirm': 'hayır'},
        );
        expect(noWord.statusCode, 400);
        final del = await p.send(
          'POST',
          '$path/delete',
          cookie: cookie,
          form: {'csrf': _Portal.csrfOf(html), 'confirm': 'SİL'},
        );
        expect(await del.readAsString(), contains('Kayıt silindi'));
        expect(p.store.record(id), isNull);
        expect(
          p.store.consentsForPatient(_patientId).single.activeAt(_now),
          isTrue,
        );
      },
    );
  });

  group('rapor', () {
    Future<(_Portal, String)> setup({
      List<String> scopes = const [
        'heartRate',
        'bloodPressure',
        'activity',
        'sleep',
      ],
    }) async {
      final p = _Portal();
      final cookie = await p.register();
      final html = await p.page('/panel', cookie);
      final r = await p.send(
        'POST',
        '/panel/invites',
        cookie: cookie,
        form: {
          'csrf': _Portal.csrfOf(html),
          'purpose': 'Takip',
          'scope': ShareScope.values.map((s) => s.name).toList(),
          'days': '90',
        },
      );
      final code = RegExp(
        r'class="code">([A-Z0-9]{7})<',
      ).firstMatch(await r.readAsString())!.group(1)!;
      await p.send(
        'POST',
        '/invites/$code/accept',
        bearer: 'patient',
        json: {'scopes': scopes},
      );
      final day = DateTime.utc(2026, 10, 18, 10);
      await p.upload('patient', _patientId, [
        for (var i = 0; i < 12; i++)
          _obs(
            _patientId,
            '8867-4',
            day.add(Duration(hours: i)),
            value: i == 3 ? 125 : 70 + i,
          ),
        _obs(
          _patientId,
          '85354-9',
          day,
          components: [('8480-6', 150), ('8462-4', 95)],
        ),
        _obs(
          _patientId,
          '85354-9',
          day.add(const Duration(days: 1)),
          components: [('8480-6', 118), ('8462-4', 76)],
        ),
        _obs(_patientId, '55423-8', day, value: 4000),
        _obs(
          _patientId,
          '55423-8',
          day.add(const Duration(hours: 2)),
          value: 2000,
        ),
        _obs(
          _patientId,
          '93832-4',
          day.subtract(const Duration(hours: 8)),
          value: 320,
          end: day.subtract(const Duration(hours: 2)),
          components: [
            ('sleep-deep', 60),
            ('sleep-light', 200),
            ('sleep-rem', 60),
            ('sleep-awake', 20),
          ],
        ),
        _obs(_patientId, '59408-5', day, value: 88),
        _obs(_patientId, '29463-7', day, value: 80),
      ]);
      return (p, cookie);
    }

    test(
      'rapor tüm paylaşılan türleri, bulguları ve yazdırma düğmesini içerir',
      () async {
        final (p, cookie) = await setup();
        final r = await p.send(
          'GET',
          '/panel/patients/$_patientId/report?from=2026-10-01&to=2026-10-20',
          cookie: cookie,
        );
        expect(r.statusCode, 200);
        final csp = r.headers['content-security-policy']!;
        expect(csp, contains("script-src 'sha256-"));
        final html = await r.readAsString();
        expect(html, contains('Sağlık verisi raporu'));
        expect(html, contains('01.10.2026 – 20.10.2026 (20 gün)'));
        expect(html, contains('Nabız'));
        expect(html, contains('100 atım/dk üzerinde; en yüksek 125'));
        expect(html, contains('Tansiyon tahminlerinin 1/2 tanesi (%50)'));
        expect(html, contains('1. derece (140-159/90-99)'));
        expect(html, contains('6000 adım'), reason: 'adımlar günlük toplanır');
        expect(html, contains('5 sa 20 dk'));
        expect(html, contains('<svg class="chart"'));
        expect(html, contains('id="print"'));
        expect(html, contains('report.csv?from=2026-10-01&amp;to=2026-10-20'));
        // Paylaşılmayan türler raporda yok.
        expect(html, isNot(contains('SpO2 ölçümlerinin')));
        expect(html, isNot(contains('>Kilo<')));
        expect(
          p.store.auditForPatient(_patientId).first.description,
          contains('rapor oluşturuldu 2026-10-01–2026-10-20 (17 ölçüm)'),
        );

        // Bölüm seçimi: yalnızca tansiyon.
        final only = await p.page(
          '/panel/patients/$_patientId/report?from=2026-10-01&to=2026-10-20&s=bloodPressure',
          cookie,
        );
        expect(only, isNot(contains('100 atım/dk üzerinde')));
        expect(only, contains('Tansiyon tahminlerinin'));

        // Arapça sağdan sola, sayılar Batı rakamıyla.
        final ar = await p.page(
          '/panel/patients/$_patientId/report?from=2026-10-01&to=2026-10-20&lang=ar',
          cookie,
        );
        expect(ar, contains('dir="rtl"'));
        expect(ar, contains('تقرير البيانات الصحية'));
      },
    );

    test(
      'tarih aralığı denetlenir; rızası olmayan hekim rapor alamaz',
      () async {
        final (p, cookie) = await setup();
        expect(
          (await p.send(
            'GET',
            '/panel/patients/$_patientId/report?from=2026-10-20&to=2026-10-01',
            cookie: cookie,
          )).statusCode,
          400,
        );
        expect(
          (await p.send(
            'GET',
            '/panel/patients/$_patientId/report?from=2020-01-01&to=2026-10-01',
            cookie: cookie,
          )).statusCode,
          400,
        );
        final other = _Portal.cookieOf(
          await p.send('POST', '/panel/login', form: {'token': 'stranger'}),
        );
        expect(
          (await p.send(
            'GET',
            '/panel/patients/$_patientId/report',
            cookie: other,
          )).statusCode,
          403,
        );
        expect(
          (await p.send(
            'GET',
            '/panel/patients/$_patientId/report.csv',
            cookie: other,
          )).statusCode,
          403,
        );
        expect(p.store.auditForPatient(_patientId).first.success, isFalse);
      },
    );

    test(
      'CSV ve FHIR dışa aktarma yalnızca rızadaki türleri içerir ve kayda geçer',
      () async {
        final (p, cookie) = await setup();
        final csv = await p.send(
          'GET',
          '/panel/patients/$_patientId/report.csv?from=2026-10-01&to=2026-10-20',
          cookie: cookie,
        );
        expect(csv.statusCode, 200);
        expect(
          csv.headers['content-disposition'],
          'attachment; filename="bileklik-6f1c2a3e-2026-10-01-2026-10-20.csv"',
        );
        final bytes = await csv.read().expand((b) => b).toList();
        expect(bytes.take(3), [
          0xEF,
          0xBB,
          0xBF,
        ], reason: 'Excel için UTF-8 BOM');
        final text = utf8.decode(bytes.skip(3).toList());
        expect(text, startsWith('time,code,metric,value,unit,detail'));
        expect(
          text,
          contains(',85354-9,Tansiyon (tahmini),,,8480-6=150 8462-4=95'),
        );
        expect(text, contains('sleep-deep=60'));
        expect(text, isNot(contains('59408-5')), reason: 'SpO2 paylaşılmadı');
        expect(text, isNot(contains('29463-7')), reason: 'kilo paylaşılmadı');

        final json = await p.send(
          'GET',
          '/panel/patients/$_patientId/report.json?from=2026-10-01&to=2026-10-20&s=heartRate',
          cookie: cookie,
        );
        final bundle = jsonDecode(await json.readAsString()) as Map;
        expect(bundle['resourceType'], 'Bundle');
        final codes = {
          for (final e in (bundle['entry'] as List).skip(1))
            ((((e as Map)['resource'] as Map)['code'] as Map)['coding'] as List)
                .first['code'],
        };
        expect(codes, {'8867-4'});
        final audit = p.store
            .auditForPatient(_patientId)
            .map((e) => e.description)
            .toList();
        expect(audit.first, contains('FHIR dışa aktarıldı (12 ölçüm)'));
        expect(audit[1], contains('CSV dışa aktarıldı'));
      },
    );

    test('vücut ölçüleri ve solunum yalnızca hasta seçerse görünür', () async {
      final (p, cookie) = await setup(scopes: ['body', 'spo2']);
      final html = await p.page(
        '/panel/patients/$_patientId/report?from=2026-10-01&to=2026-10-20',
        cookie,
      );
      expect(html, contains('>Kilo<'));
      expect(
        html,
        contains('SpO2 ölçümlerinin 1/1 tanesi %90 altında; en düşük %88.'),
      );
      expect(html, isNot(contains('Nabız ölçümlerinin')));
    });
  });

  group('rapor hesapları', () {
    test(
      'tansiyon sınıfları, günlük toplamlar, uyku evreleri, bulgular ve VO2',
      () {
        final d = DateTime(2026, 10, 1, 10);
        final obs = [
          for (var day = 0; day < 10; day++) ...[
            for (var h = 0; h < 3; h++)
              _stored(
                _obs(
                  _patientId,
                  '8867-4',
                  d.add(Duration(days: day, hours: h)),
                  value: 60 + h * 5,
                ),
              ),
            _stored(
              _obs(
                _patientId,
                '55423-8',
                d.add(Duration(days: day)),
                value: 1000,
              ),
            ),
            _stored(
              _obs(
                _patientId,
                '55423-8',
                d.add(Duration(days: day, hours: 3)),
                value: 2000,
              ),
            ),
            _stored(
              _obs(
                _patientId,
                '55430-3',
                d.add(Duration(days: day)),
                value: 2500,
              ),
            ),
          ],
          _stored(
            _obs(
              _patientId,
              '85354-9',
              d,
              components: [('8480-6', 182), ('8462-4', 90)],
            ),
          ),
          _stored(
            _obs(
              _patientId,
              '85354-9',
              d,
              components: [('8480-6', 125), ('8462-4', 82)],
            ),
          ),
          _stored(
            _obs(
              _patientId,
              '85354-9',
              d,
              components: [('8480-6', 110), ('8462-4', 70)],
            ),
          ),
          _stored(
            _obs(
              _patientId,
              '93832-4',
              d,
              value: 300,
              components: [('sleep-deep', 50), ('sleep-awake', 30)],
            ),
          ),
          _stored(
            _obs(
              _patientId,
              '93832-4',
              d.add(const Duration(days: 1)),
              value: 420,
              components: [('sleep-deep', 70), ('sleep-awake', 10)],
            ),
          ),
          _stored(_obs(_patientId, '8310-5', d, value: 38.4)),
          _stored(_obs(_patientId, '9279-1', d, value: 24)),
          _stored(_obs(_patientId, '29463-7', d, value: 80)),
          _stored(
            _obs(
              _patientId,
              '29463-7',
              d.add(const Duration(days: 9)),
              value: 82.5,
            ),
          ),
          _stored(
            _obs(
              _patientId,
              '11524-6',
              d,
              end: d.add(const Duration(seconds: 30)),
              components: [('8867-4', 72), ('80404-7', 41.5)],
            ),
          ),
        ];
        final r = PatientReport.build(
          obs,
          from: DateTime(2026, 10, 1),
          to: DateTime(2026, 10, 30, 23, 59),
          age: 50,
        );
        expect(r.periodDays, 30);
        expect(r.daysWithData, 10);
        expect(r.bp!.categories[BpCategory.grade3], 1);
        expect(r.bp!.categories[BpCategory.normal], 1);
        expect(r.bp!.categories[BpCategory.optimal], 1);
        final steps = r.series[ReportMetric.steps]!;
        expect(steps.mean, 3000);
        expect(steps.days, hasLength(10));
        expect(
          r.series[ReportMetric.distance]!.mean,
          2.5,
          reason: 'metre km olur',
        );
        expect(r.sleep!.stageMeans['deep'], 60);
        expect(r.sleep!.duration.mean, 360);
        expect(r.ecgs.single.seconds, 30);
        expect(r.ecgs.single.sdnn, 41.5);
        expect(r.restingHeartRate, 60);
        expect(r.vo2max, estimateVo2Max(age: 50, restingHeartRate: 60));
        final kinds = {for (final f in r.findings) f.kind};
        expect(
          kinds,
          containsAll([
            FindingKind.hypertension,
            FindingKind.fever,
            FindingKind.tachypnea,
            FindingKind.shortSleep,
            FindingKind.lowActivity,
            FindingKind.weightChange,
            FindingKind.dataGaps,
          ]),
        );
        expect(kinds, isNot(contains(FindingKind.tachycardia)));
        expect(
          r.findings
              .firstWhere((f) => f.kind == FindingKind.weightChange)
              .value,
          2.5,
        );
        expect(BpCategory.of(139, 89), BpCategory.highNormal);
        expect(BpCategory.of(119, 79), BpCategory.optimal);
      },
    );

    test('boş dönem', () {
      final r = PatientReport.build(
        const [],
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 7),
      );
      expect(r.isEmpty, isTrue);
      expect(r.findings, isEmpty);
    });
  });

  test('metinler dört dilde aynı anahtarlara sahip', () {
    final keys = ClinicText.tr.strings.keys.toSet();
    for (final t in [ClinicText.en, ClinicText.ar, ClinicText.de]) {
      expect(t.strings.keys.toSet(), keys, reason: t.lang);
    }
    for (final k in FindingKind.values) {
      expect(keys, contains('f.${k.name}'));
    }
    for (final m in ReportMetric.values) {
      expect(keys, contains('u.${m.unit}'));
      for (final lang in PanelText.supported) {
        expect(
          PanelText.of(lang).codeLabels,
          contains(m.code),
          reason: '$lang ${m.code}',
        );
      }
    }
  });

  test(
    'hesap, şifre ve hasta kayıtları şifreli depoda kalıcıdır; silinen kayıt dosyadan çıkar',
    () async {
      final dir = await Directory.systemTemp.createTemp('portal-clinic');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/portal.log');
      final key = List<int>.generate(32, (i) => i);
      var store = await EncryptedPortalStore.open(file, key);
      store.addAccount(
        const Account(
          id: 'dr-1',
          role: Role.clinician,
          name: 'Dr. A',
          email: 'a@k.test',
          licenseNo: 'L1',
          verified: false,
        ),
        'tok',
      );
      store.setPassword('dr-1', await _fast.hash('sifre-sifre-1'));
      store.updateAccount(store.account('dr-1')!.copyWith(verified: true));
      final rec = PatientRecord(
        id: 'rec-1',
        ownerId: 'dr-1',
        name: 'Gizli Ad Soyad',
        created: _now,
        birthDate: DateTime.utc(1980, 1, 2),
        sex: Sex.female,
      );
      store.putRecord(rec);
      store.putRecord(rec.copyWith(name: 'Düzeltilmiş Ad'));
      store.putRecord(
        PatientRecord(
          id: 'rec-2',
          ownerId: 'dr-1',
          name: 'Silinecek Kişi',
          created: _now,
        ),
      );
      await store.flush();

      store = await EncryptedPortalStore.open(file, key);
      final a = store.accountByEmail('a@k.test')!;
      expect(a.verified, isTrue);
      expect(a.licenseNo, 'L1');
      expect(store.accountByToken('tok')?.verified, isTrue);
      expect(
        await _fast.verify('sifre-sifre-1', store.passwordOf('dr-1')!),
        isTrue,
      );
      expect(store.record('rec-1')!.name, 'Düzeltilmiş Ad');
      expect(store.record('rec-1')!.sex, Sex.female);
      expect(store.recordsOf('dr-1'), hasLength(2));
      store.deleteRecord('rec-2');
      await store.flush();
      store = await EncryptedPortalStore.open(file, key);
      expect(store.record('rec-2'), isNull);
      expect(store.recordsOf('dr-1').single.id, 'rec-1');
      // Düzeltilen eski ad ve silinen kayıt dosyada şifreli halde bile yok:
      // hesap, şifre, hesap güncellemesi ve tek kayıt olayı.
      expect(store.eventCount, 4);
    },
  );

  test(
    'deneme verisi: hekim e-postayla girer, kayıtlar bağlı ve rapor dolu',
    () async {
      final store = MemoryPortalStore();
      final api = PortalApi(
        store,
        random: Random(1),
        clock: () => _now,
        passwords: _fast,
      );
      await seedDemo(api, now: _now);
      final dr = store.accountByEmail(DemoTokens.doctorEmail)!;
      expect(
        await _fast.verify(DemoTokens.doctorPassword, store.passwordOf(dr.id)!),
        isTrue,
      );
      final records = store.recordsOf(dr.id);
      expect(records, hasLength(3));
      expect(records.where((r) => r.patientId != null), hasLength(2));
      expect(
        records.where((r) => r.inviteCode != null && r.patientId == null),
        hasLength(1),
      );
      final first = records.firstWhere((r) => r.name == 'Elif Örnek');
      final report = PatientReport.build(
        store.observations(first.patientId!),
        from: _now.subtract(const Duration(days: 29)),
        to: _now,
        age: first.ageAt(_now),
      );
      expect(
        report.series.keys,
        containsAll(
          ReportMetric.values.where(
            (m) => m.kind == MetricKind.average || m.kind == MetricKind.total,
          ),
        ),
      );
      expect(report.bp, isNotNull);
      expect(
        report.sleep!.stageMeans.keys,
        containsAll(PatientReport.sleepStages),
      );
      expect(report.workouts, isNotEmpty);
      expect(report.ecgs, isNotEmpty);
      expect(report.vo2max, isNotNull);
      final hf = records.firstWhere((r) => r.name == 'Murat Örnek');
      final hfReport = PatientReport.build(
        store.observations(hf.patientId!),
        from: _now.subtract(const Duration(days: 29)),
        to: _now,
      );
      expect(
        hfReport.findings.map((f) => f.kind),
        contains(FindingKind.weightChange),
      );
    },
  );
}
