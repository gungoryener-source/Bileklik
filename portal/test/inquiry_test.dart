import 'dart:convert';
import 'dart:io';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late MemoryPortalStore store;
  late PortalApi api;
  var now = DateTime.utc(2026, 10, 26, 12);

  setUp(() {
    store = MemoryPortalStore();
    now = DateTime.utc(2026, 10, 26, 12);
    api = PortalApi(store, clock: () => now);
  });

  const valid = {
    'kind': 'distributor',
    'name': 'Ayşe Demir',
    'company': 'Medikal Dağıtım A.Ş.',
    'email': 'Ayse@Ornek.com.tr',
    'country': 'Türkiye',
    'message': 'Bölgesel distribütörlük için görüşmek istiyoruz.',
    'consent': 'on',
    'website': '',
  };

  Future<Response> post(
    Map<String, String> form, {
    bool json = true,
    String? referer,
  }) async => api.handler(
    Request(
      'POST',
      Uri.parse('http://localhost/inquiry'),
      body: Uri(queryParameters: form).query,
      headers: {
        'content-type': 'application/x-www-form-urlencoded',
        if (json) 'accept': 'application/json',
        'referer': ?referer,
      },
    ),
  );

  test('geçerli başvuru anahtarsız kaydedilir, CORS başlığı taşır', () async {
    final r = await post(valid);
    expect(r.statusCode, 201);
    expect(r.headers['access-control-allow-origin'], '*');
    expect(jsonDecode(await r.readAsString()), {'status': 'received'});
    final i = store.inquiries().single;
    expect(i.kind, InquiryKind.distributor);
    expect(i.email, 'ayse@ornek.com.tr');
    expect(i.company, 'Medikal Dağıtım A.Ş.');
    expect(i.country, 'Türkiye');
    expect(i.phone, isNull);
    expect(Inquiry.fromJson(i.toJson()).toJson(), i.toJson());
  });

  test('eksik ya da hatalı alanlar 400 ve alan adları', () async {
    final r = await post({
      ...valid,
      'kind': 'reseller',
      'email': 'ornek.com',
      'name': '  ',
      'consent': '',
    });
    expect(r.statusCode, 400);
    final body = jsonDecode(await r.readAsString()) as Map;
    expect(body['fields'], ['kind', 'name', 'email', 'consent']);
    final long = await post({...valid, 'message': 'x' * 2001});
    expect(long.statusCode, 400);
    expect(store.inquiries(), isEmpty);
  });

  test(
    'ön kayıt yalnızca e-posta ve onay ister, aynı e-posta bir kez',
    () async {
      final form = {
        'kind': 'waitlist',
        'email': 'ali@ornek.com',
        'consent': 'on',
      };
      expect((await post(form)).statusCode, 201);
      expect((await post({...form, 'email': 'ALI@ornek.com'})).statusCode, 201);
      final i = store.inquiries().single;
      expect(i.kind, InquiryKind.waitlist);
      expect(i.name, '');
      expect((await post({'kind': 'waitlist', 'email': 'x'})).statusCode, 400);
    },
  );

  test('gizli alan doluysa başarılı görünür ama kaydedilmez', () async {
    final r = await post({...valid, 'website': 'http://spam.example'});
    expect(r.statusCode, 201);
    expect(store.inquiries(), isEmpty);
  });

  test('dakikada en çok 10 başvuru', () async {
    for (var i = 0; i < InquiryEndpoint.perMinute; i++) {
      expect((await post(valid)).statusCode, 201);
    }
    expect((await post(valid)).statusCode, 429);
    now = now.add(const Duration(minutes: 1));
    expect((await post(valid)).statusCode, 201);
  });

  test('betiksiz gönderimde HTML yanıt ve siteye dönüş bağlantısı', () async {
    final r = await post(valid, json: false, referer: 'https://site.example/');
    expect(r.statusCode, 201);
    expect(r.headers['content-type'], startsWith('text/html'));
    final html = await r.readAsString();
    expect(html, contains('Başvurunuz alındı'));
    expect(html, contains('href="https://site.example/#is-birligi"'));
    final bad = await post(
      {...valid, 'email': ''},
      json: false,
      referer: 'javascript:alert(1)',
    );
    final badHtml = await bad.readAsString();
    expect(bad.statusCode, 400);
    expect(badHtml, contains('gönderilemedi'));
    expect(badHtml, isNot(contains('javascript:')));
  });

  test('başvurular şifreli depoda kalıcıdır', () async {
    final dir = await Directory.systemTemp.createTemp('inq');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/portal.log');
    final key = base64.decode(EncryptedPortalStore.newKey());
    final s = await EncryptedPortalStore.open(file, key);
    final a = PortalApi(s, clock: () => now);
    await a.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/inquiry'),
        body: Uri(queryParameters: {...valid, 'kind': 'oem'}).query,
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      ),
    );
    await s.flush();
    expect(await file.readAsString(), isNot(contains('Medikal')));
    final again = await EncryptedPortalStore.open(file, key);
    expect(again.inquiries().single.kind, InquiryKind.oem);
  });
}
