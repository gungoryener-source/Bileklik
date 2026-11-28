import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:shelf/shelf.dart';

/// Kullanıcının dili nereden geldi.
enum LangSource {
  /// Adresteki `?lang=` (bağlantıdan ya da dil seçiciden).
  query,

  /// Daha önce elle seçilen dil (`bk_lang` çerezi).
  cookie,

  /// Sunucunun önündeki CDN'in bildirdiği ülke (ör. `CF-IPCountry`).
  country,

  /// Tarayıcının saat diliminden çıkarılan ülke (`bk_geo` çerezi).
  timeZone,

  /// Tarayıcının `Accept-Language` başlığı.
  browser,

  /// Hiçbir bilgi yok: İngilizce.
  fallback,
}

/// Portal sayfalarının (hekim paneli, gizlilik, geliştirici sayfası, başvuru
/// yanıtı) dili.
///
/// Sıra: `?lang=` > elle seçilen dil (çerez) > bağlanılan ülke > tarayıcı dili >
/// İngilizce. Ülke önce CDN başlığından okunur (Cloudflare `CF-IPCountry`,
/// CloudFront, Vercel, App Engine ya da ters vekilin `X-Country-Code`'u).
/// Render gibi ülke başlığı vermeyen bir barındırmada sayfa, tarayıcının saat
/// diliminden ülkeyi bulan küçük bir betik taşır ([detectScript]); betik
/// ülkeyi `bk_geo` çerezine yazar ve dil değişiyorsa sayfayı bir kez yeniden
/// yükler. Elle seçim her zaman otomatik seçimin önüne geçer.
///
/// Ülke ve saat dilimi tabloları tanıtım sitesindeki `website/i18n.js` ile
/// aynıdır; `test/locale_test.dart` ikisini karşılaştırır.
abstract final class PortalLocale {
  static const supported = ['tr', 'en', 'ar', 'de'];
  static const fallback = 'en';

  /// Elle seçilen dil. Bütün portal (`Path=/`) için geçerli.
  static const cookie = 'bk_lang';

  /// Tarayıcının saat diliminden bulunan ülke kodu; tabloda yoksa `ZZ`.
  static const geoCookie = 'bk_geo';

  /// Ülke kodu veren yaygın CDN/vekil başlıkları.
  static const countryHeaders = [
    'cf-ipcountry',
    'cloudfront-viewer-country',
    'x-vercel-ip-country',
    'x-appengine-country',
    'x-country-code',
  ];

  /// Ülke -> dil. Burada olmayan ülkede tarayıcı dili, o da yoksa İngilizce.
  static const countryLanguage = {
    'TR': 'tr',
    'DE': 'de', 'AT': 'de', 'CH': 'de', 'LI': 'de',
    // Arap Birliği ülkeleri.
    'SA': 'ar', 'AE': 'ar', 'QA': 'ar', 'BH': 'ar', 'KW': 'ar', 'OM': 'ar',
    'YE': 'ar', 'IQ': 'ar', 'JO': 'ar', 'SY': 'ar', 'LB': 'ar', 'PS': 'ar',
    'EG': 'ar', 'LY': 'ar', 'TN': 'ar', 'DZ': 'ar', 'MA': 'ar', 'EH': 'ar',
    'SD': 'ar', 'MR': 'ar', 'SO': 'ar', 'DJ': 'ar', 'KM': 'ar',
  };

  /// IANA saat dilimi -> ülke (yalnızca [countryLanguage]'daki ülkeler).
  static const timeZoneCountry = {
    'Europe/Istanbul': 'TR',
    'Asia/Istanbul': 'TR',
    'Turkey': 'TR',
    'Europe/Berlin': 'DE',
    'Europe/Busingen': 'DE',
    'Europe/Vienna': 'AT',
    'Europe/Zurich': 'CH',
    'Europe/Vaduz': 'LI',
    'Asia/Riyadh': 'SA',
    'Asia/Dubai': 'AE',
    'Asia/Qatar': 'QA',
    'Asia/Bahrain': 'BH',
    'Asia/Kuwait': 'KW',
    'Asia/Muscat': 'OM',
    'Asia/Aden': 'YE',
    'Asia/Baghdad': 'IQ',
    'Asia/Amman': 'JO',
    'Asia/Damascus': 'SY',
    'Asia/Beirut': 'LB',
    'Asia/Gaza': 'PS',
    'Asia/Hebron': 'PS',
    'Africa/Cairo': 'EG',
    'Egypt': 'EG',
    'Africa/Tripoli': 'LY',
    'Libya': 'LY',
    'Africa/Tunis': 'TN',
    'Africa/Algiers': 'DZ',
    'Africa/Casablanca': 'MA',
    'Africa/El_Aaiun': 'EH',
    'Africa/Khartoum': 'SD',
    'Africa/Nouakchott': 'MR',
    'Africa/Mogadishu': 'SO',
    'Africa/Djibouti': 'DJ',
    'Indian/Comoro': 'KM',
  };

  /// Dil seçicide görünen adlar.
  static const names = {
    'tr': 'Türkçe',
    'en': 'English',
    'ar': 'العربية',
    'de': 'Deutsch',
  };

  static bool isSupported(String? l) => l != null && supported.contains(l);

  /// Ülke koduna göre dil; tabloda yoksa null.
  static String? languageOfCountry(String? country) =>
      country == null ? null : countryLanguage[country.trim().toUpperCase()];

  /// CDN başlığındaki ülke kodu (iki harf), yoksa null.
  static String? countryOf(Request r) {
    for (final h in countryHeaders) {
      final v = r.headers[h]?.trim().toUpperCase();
      if (v != null && RegExp(r'^[A-Z]{2}$').hasMatch(v) && v != 'XX') {
        return v;
      }
    }
    return null;
  }

  /// `Accept-Language` başlığından desteklenen ilk dil; yoksa null.
  static String? fromAcceptLanguage(String? header) {
    final ranked = <(String, double)>[];
    for (final part in (header ?? '').split(',')) {
      final pieces = part.trim().split(';');
      final tag = pieces.first.trim().toLowerCase();
      if (tag.isEmpty) continue;
      var q = 1.0;
      for (final p in pieces.skip(1)) {
        final kv = p.trim().split('=');
        if (kv.length == 2 && kv[0] == 'q') q = double.tryParse(kv[1]) ?? 0;
      }
      ranked.add((tag.split('-').first, q));
    }
    ranked.sort((a, b) => b.$2.compareTo(a.$2));
    for (final (lang, q) in ranked) {
      if (q > 0 && supported.contains(lang)) return lang;
    }
    return null;
  }

  /// İsteğin dili ve nereden geldiği.
  ///
  /// [formLang] form gönderen sayfaların (ör. sitedeki başvuru formu) gizli
  /// `lang` alanıdır; `?lang=` gibi davranır.
  static (String, LangSource) resolve(Request r, {String? formLang}) {
    final q = r.url.queryParameters['lang'] ?? formLang;
    if (isSupported(q)) return (q!, LangSource.query);
    final cookies = _cookies(r);
    final c = cookies[cookie];
    if (isSupported(c)) return (c!, LangSource.cookie);
    final byCountry = languageOfCountry(countryOf(r));
    if (byCountry != null) return (byCountry, LangSource.country);
    final browser = fromAcceptLanguage(r.headers['accept-language']);
    // Ülke biliniyor ama tabloda yok (ör. US): tarayıcı dili, sonra İngilizce.
    if (countryOf(r) != null) {
      return browser != null
          ? (browser, LangSource.browser)
          : (fallback, LangSource.fallback);
    }
    final byZone = languageOfCountry(cookies[geoCookie]);
    if (byZone != null) return (byZone, LangSource.timeZone);
    if (browser != null) return (browser, LangSource.browser);
    return (fallback, LangSource.fallback);
  }

  static String of(Request r, {String? formLang}) =>
      resolve(r, formLang: formLang).$1;

  /// Ülke henüz bilinmiyorsa (CDN başlığı ve `bk_geo` yok, elle seçim yok)
  /// sayfaya saat dilimi betiği eklenir.
  static bool needsDetection(Request r) {
    final (_, source) = resolve(r);
    if (source == LangSource.query || source == LangSource.cookie) {
      return false;
    }
    if (source == LangSource.country || countryOf(r) != null) return false;
    return !_cookies(r).containsKey(geoCookie);
  }

  /// Elle seçimi saklayan çerez (bir yıl, bütün portal).
  static String choiceCookie(String lang, {bool secure = false}) =>
      '$cookie=$lang; Path=/; SameSite=Lax; Max-Age=31536000'
      '${secure ? '; Secure' : ''}';

  /// Saat diliminden ülkeyi bulan betik. Ülke `bk_geo` çerezine yazılır;
  /// o ülkenin dili sayfanınkinden farklıysa sayfa bir kez yeniden yüklenir.
  /// Çerez yazılamıyorsa (tarayıcı engelliyorsa) yeniden yüklemez, döngü
  /// olmaz. CSP'de özetiyle ([detectScriptHash]) izin verilir.
  static final String detectScript = () {
    final zones = jsonEncode(timeZoneCountry);
    final langs = jsonEncode(countryLanguage);
    return '(function(){try{var z=$zones,l=$langs,'
        'tz=Intl.DateTimeFormat().resolvedOptions().timeZone||"",'
        'c=z[tz]||"ZZ";'
        'document.cookie="$geoCookie="+c+"; Path=/; SameSite=Lax; Max-Age=31536000";'
        'if(document.cookie.indexOf("$geoCookie="+c)<0)return;'
        'var w=l[c];'
        'if(w&&w!==document.documentElement.lang)location.reload();'
        '}catch(e){}})();';
  }();

  /// CSP `script-src` için betiğin özeti.
  static final String detectScriptHash =
      "'sha256-${base64.encode(crypto.sha256.convert(utf8.encode(detectScript)).bytes)}'";

  /// `<head>` içine konacak betik etiketi; gerekmiyorsa boş.
  static String detectTag(Request r) =>
      needsDetection(r) ? '<script>$detectScript</script>' : '';

  /// CSP'ye eklenecek `script-src` kaynağı; betik yoksa null.
  static String? detectCsp(Request r) =>
      needsDetection(r) ? detectScriptHash : null;

  /// Dil seçici: aynı sayfayı başka dilde açan bağlantılar (betik gerekmez).
  /// [query] sayfanın korunacak diğer parametreleridir.
  static String switcher(
    String current, {
    Map<String, String> query = const {},
    String label = 'Dil · Language · اللغة · Sprache',
  }) {
    String href(String l) =>
        '?${Uri(queryParameters: {...query, 'lang': l}).query}';
    final items = [
      for (final l in supported)
        l == current
            ? '<span class="lang-on" lang="$l" aria-current="true">${names[l]}</span>'
            : '<a href="${_attr(href(l))}" lang="$l" hreflang="$l">${names[l]}</a>',
    ].join();
    return '<nav class="langswitch" aria-label="${_attr(label)}">'
        '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" '
        'stroke="currentColor" stroke-width="2" stroke-linecap="round" '
        'stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" '
        'r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 '
        '18"/></svg>$items</nav>';
  }

  /// Dil seçicinin Cam görünümü (panel, gizlilik ve geliştirici sayfaları).
  static const switcherCss = '''
.langswitch { display: inline-flex; flex-wrap: wrap; align-items: center; gap: 4px; padding: 4px 6px; border-radius: 22px; background: rgba(255,255,255,.08); border: 1px solid rgba(255,255,255,.18); color: rgba(255,255,255,.75); }
.langswitch svg { margin-inline: 4px 2px; flex: 0 0 auto; }
.langswitch a, .langswitch .lang-on { display: inline-flex; align-items: center; min-height: 36px; padding: 0 10px; border-radius: 999px; font-weight: 600; font-size: .92rem; text-decoration: none; color: rgba(255,255,255,.8); }
.langswitch a:hover { background: rgba(255,255,255,.12); color: #fff; }
.langswitch a:focus-visible { outline: 3px solid #45D6B8; outline-offset: 1px; }
.langswitch .lang-on { background: rgba(69,214,184,.2); color: #9DF2D8; }
[lang="ar"] body { font-family: Manrope, "Noto Sans Arabic", "Noto Naskh Arabic", "Segoe UI", Tahoma, "Geeza Pro", sans-serif; }
[lang="ar"] h1, [lang="ar"] h2, [lang="ar"] h3 { letter-spacing: 0; }
@media (max-width: 420px) { .langswitch svg { display: none; } .langswitch a, .langswitch .lang-on { padding: 0 8px; } }
@media print { .langswitch { display: none !important; } }''';

  static String _attr(String s) =>
      const HtmlEscape(HtmlEscapeMode.attribute).convert(s);

  static Map<String, String> _cookies(Request r) {
    final out = <String, String>{};
    for (final part in (r.headers['cookie'] ?? '').split(';')) {
      final i = part.indexOf('=');
      if (i <= 0) continue;
      out[part.substring(0, i).trim()] = part.substring(i + 1).trim();
    }
    return out;
  }
}

/// `?lang=` ile seçilen dili bütün portal için çereze yazar.
Middleware rememberLanguage({bool secure = false}) =>
    (inner) => (r) async {
      final res = await inner(r);
      final lang = r.url.queryParameters['lang'];
      if (!PortalLocale.isSupported(lang) || r.method != 'GET') return res;
      return res.change(
        headers: {
          'set-cookie': [
            ...?res.headersAll['set-cookie'],
            PortalLocale.choiceCookie(lang!, secure: secure),
          ],
        },
      );
    };

/// Ülkesi bilinmeyen ziyaretçinin HTML sayfasına saat dilimi betiğini
/// ([PortalLocale.detectScript]) ekler ve CSP'ye özetini yazar. Sayfalar
/// betiği kendileri taşımaz; böylece her sayfa (panel, gizlilik, geliştirici,
/// başvuru yanıtı) aynı kurala uyar.
Middleware detectCountry() =>
    (inner) => (r) async {
      final res = await inner(r);
      final type = res.headers['content-type'] ?? '';
      if (!type.startsWith('text/html') || !PortalLocale.needsDetection(r)) {
        return res;
      }
      final body = await res.readAsString();
      final i = body.indexOf('<head>');
      if (i < 0) return res.change(body: body);
      final tag = '<script>${PortalLocale.detectScript}</script>';
      final withScript =
          '${body.substring(0, i + 6)}\n$tag${body.substring(i + 6)}';
      final csp = res.headers['content-security-policy'];
      String? newCsp;
      if (csp != null) {
        final hash = PortalLocale.detectScriptHash;
        newCsp = csp.contains('script-src ')
            ? csp.replaceFirst('script-src ', 'script-src $hash ')
            : csp.replaceFirst(
                'default-src ',
                'script-src $hash; default-src ',
              );
      }
      return res.change(
        body: withScript,
        headers: {
          'content-security-policy': ?newCsp,
          // Gövde değişti; eski uzunluk geçersiz.
          'content-length': utf8.encode(withScript).length.toString(),
        },
      );
    };
