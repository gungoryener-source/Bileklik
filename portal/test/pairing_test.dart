import 'dart:convert';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Portalda üretilen kodla telefonun bağlanması: tek kullanım, süre,
/// deneme sınırı, QR ve panelin kendiliğinden yenilenmesi.
const _patient = '6f1c2a3e-1111-4222-8333-944455556666';
const _patient2 = '7a2d3b4f-2222-4333-8444-a55566667777';

class _Portal {
  _Portal() {
    store
      ..addAccount(
        const Account(id: _patient, role: Role.patient, name: '-'),
        'patient',
      )
      ..addAccount(
        const Account(id: _patient2, role: Role.patient, name: '-'),
        'patient2',
      )
      ..addAccount(
        const Account(
          id: 'dr-1',
          role: Role.clinician,
          name: 'Dr. Ayşe Kaya',
          verified: true,
        ),
        'doctor',
      )
      ..addAccount(
        const Account(id: 'rs-1', role: Role.researcher, name: 'Çalışma'),
        'research',
      );
    api = PortalApi(store, clock: () => now, random: Random(7));
  }

  final store = MemoryPortalStore();
  late final PortalApi api;
  var now = DateTime.utc(2026, 11, 28, 9);

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
        'accept-language': 'tr',
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

  Future<String> login() async => (await send(
    'POST',
    '/panel/login',
    form: {'token': 'doctor'},
  )).headers['set-cookie']!.split(';').first;

  /// Hekim kayıt açar ve kod üretir; (kayıt adresi, kod sayfası).
  Future<(String, String)> recordWithCode(String cookie) async {
    var html = await page('/panel/records/new', cookie);
    final path = (await send(
      'POST',
      '/panel/records',
      cookie: cookie,
      form: {'csrf': csrfOf(html), 'name': 'Zeynep Deneme'},
    )).headers['location']!;
    html = await page(path, cookie);
    final res = await send(
      'POST',
      '$path/invite',
      cookie: cookie,
      form: {
        'csrf': csrfOf(html),
        'purpose': 'Ritim takibi',
        'scope': ['heartRate', 'ecg'],
        'days': '90',
      },
    );
    expect(res.statusCode, 201);
    return (path, await res.readAsString());
  }

  Future<int> accept(String code, String token) async => (await send(
    'POST',
    '/invites/$code/accept',
    bearer: token,
    json: {
      'scopes': ['heartRate'],
    },
  )).statusCode;
}

String _codeOf(String html) =>
    RegExp(r'class="code">([A-Z2-9]{7})<').firstMatch(html)!.group(1)!;

void main() {
  test(
    'panel kodu QR ile gösterir, telefon bağlanınca sayfa haber verir',
    () async {
      final p = _Portal();
      final cookie = await p.login();
      final (path, html) = await p.recordWithCode(cookie);
      final code = _codeOf(html);

      // QR karesi, geçerlilik süresi ve bekleme sırasında kendiliğinden yenileme.
      expect(html, contains('<svg class="qr"'));
      expect(html, contains('aria-label="Davet kodunun QR karesi"'));
      expect(html, contains('29.11.2026'), reason: '24 saat geçerli');
      expect(html, contains('tek kullanımlık'));
      expect(html, contains('http-equiv="refresh"'));
      expect(html, contains('$path?w=1'));

      // Hasta kodu açar: hekim adı ve istenen türler.
      final offer = await p.send('GET', '/invites/$code', bearer: 'patient');
      expect(offer.statusCode, 200);
      final body = jsonDecode(await offer.readAsString()) as Map;
      expect(body['name'], 'Dr. Ayşe Kaya');
      expect(body['requested'], ['heartRate', 'ecg']);

      expect(await p.accept(code, 'patient'), 201);
      final linked = await p.page('$path?w=1', cookie);
      expect(linked, contains('Telefon bağlandı'));
      expect(linked, isNot(contains('http-equiv="refresh"')));

      // Tek kullanımlık: ikinci telefon aynı kodla bağlanamaz.
      expect(await p.accept(code, 'patient2'), 404);
      expect(
        (await p.send('GET', '/invites/$code', bearer: 'patient2')).statusCode,
        404,
      );
    },
  );

  test('hekim kodu 24 saat sonra geçersiz', () async {
    final p = _Portal();
    final cookie = await p.login();
    final (path, html) = await p.recordWithCode(cookie);
    final code = _codeOf(html);
    p.now = p.now.add(const Duration(hours: 23));
    expect(
      (await p.send('GET', '/invites/$code', bearer: 'patient')).statusCode,
      200,
    );
    p.now = p.now.add(const Duration(hours: 2));
    expect(
      (await p.send('GET', '/invites/$code', bearer: 'patient')).statusCode,
      404,
    );
    expect(await p.accept(code, 'patient'), 404);
    // Süresi dolan kod sayfada gösterilmez, yenileme durur.
    final page = await p.page(path, cookie);
    expect(page, isNot(contains('class="code"')));
    expect(page, isNot(contains('http-equiv="refresh"')));
  });

  test('hatalı kod denemesi hesap başına dakikada 10', () async {
    final p = _Portal();
    final cookie = await p.login();
    final (_, html) = await p.recordWithCode(cookie);
    final code = _codeOf(html);
    for (var i = 0; i < 10; i++) {
      expect(
        (await p.send(
          'GET',
          '/invites/YANLIS$i',
          bearer: 'patient',
        )).statusCode,
        404,
      );
    }
    // Sınırda doğru kod da beklemeli; başka hesap etkilenmez.
    expect(
      (await p.send('GET', '/invites/$code', bearer: 'patient')).statusCode,
      429,
    );
    expect(await p.accept(code, 'patient'), 429);
    expect(
      (await p.send('GET', '/invites/$code', bearer: 'patient2')).statusCode,
      200,
    );
    p.now = p.now.add(const Duration(minutes: 1));
    expect(await p.accept(code, 'patient'), 201);
  });

  test(
    'hasta bağlantıyı geri alınca panel rızanın bittiğini gösterir',
    () async {
      final p = _Portal();
      final cookie = await p.login();
      final (path, html) = await p.recordWithCode(cookie);
      expect(await p.accept(_codeOf(html), 'patient'), 201);
      final consents = await p.send('GET', '/connections', bearer: 'patient');
      final id =
          ((jsonDecode(await consents.readAsString()) as List).single
              as Map)['id'];
      expect(
        (await p.send('DELETE', '/consents/$id', bearer: 'patient')).statusCode,
        200,
      );
      expect(await p.page(path, cookie), contains('Rıza bitti'));
    },
  );

  test('araştırma kodu çalışmaya katılan herkes için 30 gün', () async {
    final p = _Portal();
    final res = await p.send(
      'POST',
      '/invites',
      bearer: 'research',
      json: {
        'purpose': 'Uyku çalışması',
        'scopes': ['heartRate'],
        'days': 30,
      },
    );
    final code = (jsonDecode(await res.readAsString()) as Map)['code'];
    expect(await p.accept('$code', 'patient'), 201);
    p.now = p.now.add(const Duration(days: 29));
    expect(await p.accept('$code', 'patient2'), 201);
  });
}
