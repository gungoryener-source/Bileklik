import 'dart:convert';
import 'dart:io';

import 'package:bileklik_portal/portal.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Request _get(String path, [Map<String, String> headers = const {}]) =>
    Request('GET', Uri.parse('http://portal.test$path'), headers: headers);

void main() {
  group('dil seçimi sırası', () {
    String lang(String path, [Map<String, String> h = const {}]) =>
        PortalLocale.of(_get(path, h));

    test('?lang her şeyin önünde', () {
      expect(
        lang('/panel?lang=ar', {
          'cookie': 'bk_lang=de',
          'cf-ipcountry': 'TR',
          'accept-language': 'en',
        }),
        'ar',
      );
    });

    test('elle seçim (çerez) ülkenin ve tarayıcının önünde', () {
      expect(
        lang('/panel', {
          'cookie': 'bk_lang=de; bk_geo=SA',
          'cf-ipcountry': 'TR',
          'accept-language': 'en',
        }),
        'de',
      );
    });

    test('bağlanılan ülke tarayıcı dilinin önünde', () {
      expect(
        lang('/panel', {'cf-ipcountry': 'SA', 'accept-language': 'en'}),
        'ar',
      );
      expect(lang('/panel', {'cloudfront-viewer-country': 'tr'}), 'tr');
      expect(lang('/panel', {'x-vercel-ip-country': 'AT'}), 'de');
      expect(lang('/panel', {'x-country-code': 'EG'}), 'ar');
    });

    test('tabloda olmayan ülkede tarayıcı dili, o da yoksa İngilizce', () {
      expect(
        lang('/panel', {'cf-ipcountry': 'FR', 'accept-language': 'de-DE'}),
        'de',
      );
      expect(
        lang('/panel', {'cf-ipcountry': 'US', 'accept-language': 'ja'}),
        'en',
      );
      // Ülke başlığı varken saat dilimi çerezi kullanılmaz.
      expect(
        lang('/panel', {'cf-ipcountry': 'US', 'cookie': 'bk_geo=TR'}),
        'en',
      );
    });

    test('ülke başlığı yoksa saat diliminden bulunan ülke', () {
      expect(
        lang('/panel', {'cookie': 'bk_geo=DE', 'accept-language': 'en'}),
        'de',
      );
      expect(
        lang('/panel', {'cookie': 'bk_geo=ZZ', 'accept-language': 'tr'}),
        'tr',
      );
    });

    test('hiçbir bilgi yoksa İngilizce', () {
      expect(lang('/panel'), 'en');
      expect(lang('/panel', {'accept-language': 'ja, ar;q=0'}), 'en');
      expect(lang('/panel', {'cf-ipcountry': 'XX'}), 'en');
    });
  });

  test(
    '?lang bütün portal için çereze yazılır ve gizlilik sayfası da izler',
    () async {
      final api = PortalApi(MemoryPortalStore());
      final r = await api.handler(_get('/panel?lang=ar'));
      final cookie = r.headers['set-cookie']!;
      expect(cookie, startsWith('bk_lang=ar;'));
      expect(cookie, contains('Path=/;'));
      final privacy = await api.handler(
        _get('/gizlilik', {
          'cookie': cookie.split(';').first,
          'cf-ipcountry': 'DE',
        }),
      );
      final html = await privacy.readAsString();
      expect(html, contains('<html lang="ar" dir="rtl">'));
      expect(html, contains('class="langswitch"'));
    },
  );

  test(
    'ülke bilinmiyorsa sayfa saat dilimi betiğini taşır; CSP özeti tutar',
    () async {
      final api = PortalApi(MemoryPortalStore());
      for (final path in ['/panel', '/gizlilik', '/developers']) {
        final r = await api.handler(_get(path, {'accept-language': 'en'}));
        final html = await r.readAsString();
        final m = RegExp(
          r'<script>(.*?)</script>',
          dotAll: true,
        ).firstMatch(html);
        expect(m, isNotNull, reason: path);
        final hash = base64.encode(
          crypto.sha256.convert(utf8.encode(m!.group(1)!)).bytes,
        );
        expect(
          r.headers['content-security-policy'],
          contains("script-src 'sha256-$hash'"),
          reason: path,
        );
        expect(r.headers['content-length'], '${utf8.encode(html).length}');
      }
      // Ülke başlığı, saat dilimi çerezi ya da elle seçim varsa betik yok.
      for (final h in [
        {'cf-ipcountry': 'US'},
        {'cookie': 'bk_geo=ZZ'},
        {'cookie': 'bk_lang=tr'},
      ]) {
        final r = await api.handler(_get('/panel', h));
        expect(
          await r.readAsString(),
          isNot(contains('<script>')),
          reason: '$h',
        );
        expect(r.headers['content-security-policy'], isNot(contains('sha256')));
      }
      // Raporun yazdırma betiği varken iki özet birlikte durur.
      expect(PortalLocale.detectScript, contains('bk_geo'));
    },
  );

  test('başvuru yanıtı formu gönderen sitenin dilinde', () async {
    final api = PortalApi(MemoryPortalStore());
    final r = await api.handler(
      Request(
        'POST',
        Uri.parse('http://portal.test/inquiry'),
        headers: {'content-type': 'application/x-www-form-urlencoded'},
        body: 'kind=waitlist&email=a%40b.co&consent=on&lang=ar',
      ),
    );
    expect(r.statusCode, 201);
    final html = await r.readAsString();
    expect(html, contains('<html lang="ar" dir="rtl">'));
    expect(html, contains('تلقّينا طلبك'));
    expect(api.store.inquiries().single.lang, 'ar');
  });

  test('geliştirici sayfasının çerçevesi dört dilde', () async {
    final api = PortalApi(MemoryPortalStore());
    final de = await (await api.handler(
      _get('/developers?lang=de'),
    )).readAsString();
    expect(de, contains('<html lang="de" dir="ltr">'));
    expect(de, contains('Authentifizierung'));
    final ar = await (await api.handler(
      _get('/developers?lang=ar'),
    )).readAsString();
    expect(ar, contains('dir="rtl"'));
    expect(ar, contains('المصادقة'));
    // Uç açıklamaları İngilizce ve soldan sağa kalır.
    expect(ar, contains('<section class="op" lang="en" dir="ltr">'));
  });

  test('ülke ve saat dilimi tabloları tanıtım sitesiyle aynı', () {
    final js = File('../website/i18n.js').readAsStringSync();
    Map<String, String> table(String name) {
      final m = RegExp(
        'var $name = (\\{.*?\\});',
        dotAll: true,
      ).firstMatch(js)!;
      final body = m
          .group(1)!
          .replaceAll(RegExp(r'//[^\n]*'), '')
          .replaceAllMapped(RegExp(r'(\b[A-Z]{2}\b)\s*:'), (x) => '"${x[1]}":');
      return (jsonDecode(body) as Map).cast<String, String>();
    }

    expect(table('COUNTRY_LANG'), PortalLocale.countryLanguage);
    expect(table('TZ_COUNTRY'), PortalLocale.timeZoneCountry);
    for (final c in PortalLocale.timeZoneCountry.values) {
      expect(PortalLocale.countryLanguage, contains(c));
    }
  });
}
