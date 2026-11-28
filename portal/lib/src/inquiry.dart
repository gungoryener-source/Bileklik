import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'locale.dart';
import 'model.dart';
import 'store.dart';

/// `POST /inquiry`: tanıtım sitesindeki iş birliği (B2B) formu.
///
/// - Anahtar istenmez; site başka adreste olduğu için yanıt herkese açık
///   CORS başlığı taşır. Form `application/x-www-form-urlencoded` gelir,
///   böylece tarayıcı ön istek (OPTIONS) göndermez.
/// - `Accept: application/json` ise JSON döner (sitenin betiği), yoksa
///   betiksiz gönderim için kısa bir HTML sayfası.
/// - Dakikada en çok [perMinute] başvuru. Gizli `website` alanı doluysa
///   (bot) başarılı görünür ama kaydedilmez.
/// - Aydınlatma onayı (`consent=on`) zorunludur.
/// - `kind=waitlist` ön kayıttır: yalnızca e-posta ve onay; aynı e-posta
///   ikinci kez kaydedilmez.
class InquiryEndpoint {
  InquiryEndpoint(this.store, this._now);

  final PortalStore store;
  final DateTime Function() _now;

  static const perMinute = 10;
  static const messageMax = 2000;
  static const fieldMax = 120;
  final _times = <DateTime>[];

  Future<Response> handle(Request r) async {
    final json = r.headers['accept']?.contains('application/json') ?? false;
    final form = parseForm(await r.readAsString());
    // Yanıt sayfası formu gönderen sitenin dilinde (gizli `lang` alanı).
    final lang = PortalLocale.of(r, formLang: form['lang']);
    final now = _now();
    _times.removeWhere((t) => now.difference(t) >= const Duration(minutes: 1));
    if (_times.length >= perMinute) {
      return _reply(lang, r, json, 429, 'throttled', const []);
    }
    String? field(String k, int max) {
      final v = form[k]?.trim();
      return v == null || v.isEmpty || v.length > max ? null : v;
    }

    if ((form['website'] ?? '').isNotEmpty) {
      return _reply(lang, r, json, 201, 'received', const []);
    }
    final kind = InquiryKind.values.asNameMap()[form['kind']];
    final name = field('name', fieldMax);
    final company = field('company', fieldMax);
    final email = field('email', 200)?.toLowerCase();
    final message = field('message', messageMax);
    final emailOk =
        email != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    // Ön kayıtta yalnızca e-posta ve onay istenir.
    final waitlist = kind == InquiryKind.waitlist;
    final bad = [
      if (kind == null) 'kind',
      if (name == null && !waitlist) 'name',
      if (company == null && !waitlist) 'company',
      if (!emailOk) 'email',
      if (message == null && !waitlist) 'message',
      if (form['consent'] != 'on') 'consent',
    ];
    if (bad.isNotEmpty) return _reply(lang, r, json, 400, 'invalid', bad);
    _times.add(now);
    if (waitlist &&
        store.inquiries().any(
          (i) => i.kind == InquiryKind.waitlist && i.email == email,
        )) {
      return _reply(lang, r, json, 201, 'received', const []);
    }
    store.addInquiry(
      Inquiry(
        id: store.nextId('inq'),
        time: now,
        kind: kind!,
        name: name ?? '',
        company: company ?? '',
        email: email!,
        message: message ?? '',
        country: field('country', fieldMax),
        phone: field('phone', 40),
        lang: PortalLocale.isSupported(form['lang']) ? form['lang'] : null,
      ),
    );
    return _reply(lang, r, json, 201, 'received', const []);
  }

  /// Form gövdesi; aynı anahtar birden çok gelirse ilki.
  static Map<String, String> parseForm(String body) {
    final out = <String, String>{};
    for (final pair in body.split('&')) {
      if (pair.isEmpty) continue;
      final i = pair.indexOf('=');
      try {
        final k = Uri.decodeQueryComponent(i < 0 ? pair : pair.substring(0, i));
        final v = i < 0 ? '' : Uri.decodeQueryComponent(pair.substring(i + 1));
        out.putIfAbsent(k, () => v);
      } on ArgumentError {
        continue;
      }
    }
    return out;
  }

  static const _cors = {
    'access-control-allow-origin': '*',
    'x-content-type-options': 'nosniff',
  };

  Response _reply(
    String lang,
    Request r,
    bool json,
    int status,
    String code,
    List<String> fields,
  ) {
    if (json) {
      return Response(
        status,
        body: jsonEncode({
          'status': code,
          if (fields.isNotEmpty) 'fields': fields,
        }),
        headers: {..._cors, 'content-type': 'application/json'},
      );
    }
    final ok = status == 201;
    final t = _texts[lang] ?? _texts['en']!;
    final title = ok ? t['ok']! : t['fail']!;
    final text = switch (code) {
      'received' => t['received']!,
      'throttled' => t['throttled']!,
      _ => t['invalid']!,
    };
    // Geri bağlantı: sitenin adresi (tarayıcı yalnızca kökeni gönderir).
    final ref = Uri.tryParse(r.headers['referer'] ?? '');
    final back = ref != null && (ref.scheme == 'https' || ref.scheme == 'http')
        ? ref.replace(fragment: 'is-birligi').toString()
        : null;
    return Response(
      status,
      body:
          '''<!doctype html>
<html lang="$lang" dir="${lang == 'ar' ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_h(title)} · Bileklik</title>
<style>
:root { color-scheme: dark; }
body { margin: 0; font: 17px/1.6 Manrope, "Segoe UI", system-ui, sans-serif; background: radial-gradient(55vmax 55vmax at 14% 10%, rgba(76,141,255,.28), transparent 70%), radial-gradient(55vmax 55vmax at 10% 88%, rgba(69,214,184,.16), transparent 70%), linear-gradient(180deg, #1F2E4D 0%, #34507A 45%, #0C1016 100%) fixed, #0C1016; color: #fff; min-height: 100vh; }
a { color: #45D6B8; }
main { max-width: 560px; margin: 0 auto; padding: 48px 16px; }
[lang="ar"] body { font-family: Manrope, "Noto Sans Arabic", "Segoe UI", Tahoma, "Geeza Pro", sans-serif; }
</style>
</head>
<body><main>
<h1>${_h(title)}</h1>
<p>${_h(text)}</p>
${back == null ? '' : '<p><a href="${const HtmlEscape(HtmlEscapeMode.attribute).convert(back)}">${_h(t['back']!)}</a></p>'}
</main></body>
</html>
''',
      headers: {
        ..._cors,
        'content-type': 'text/html; charset=utf-8',
        'content-security-policy':
            "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; "
            "form-action 'none'; frame-ancestors 'none'",
        'referrer-policy': 'no-referrer',
      },
    );
  }

  static String _h(String s) => const HtmlEscape().convert(s);

  /// Betiksiz gönderimde gösterilen kısa sayfanın metinleri.
  static const _texts = {
    'tr': {
      'ok': 'Başvurunuz alındı',
      'fail': 'Başvuru gönderilemedi',
      'received': 'Teşekkürler. En kısa sürede e-postayla size döneceğiz.',
      'throttled':
          'Şu an çok fazla başvuru geliyor. Birkaç dakika sonra yeniden deneyin.',
      'invalid':
          'Lütfen zorunlu alanları doldurun, e-posta adresinizi kontrol edin ve aydınlatma metnini onaylayın.',
      'back': 'Siteye dön',
    },
    'en': {
      'ok': 'We have received your enquiry',
      'fail': 'Your enquiry could not be sent',
      'received': 'Thank you. We will reply by email as soon as possible.',
      'throttled':
          'We are receiving too many enquiries right now. Please try again in a few minutes.',
      'invalid':
          'Please fill in the required fields, check your email address and confirm the privacy notice.',
      'back': 'Back to the website',
    },
    'ar': {
      'ok': 'تلقّينا طلبك',
      'fail': 'تعذّر إرسال الطلب',
      'received': 'شكرًا. سنرد عليك بالبريد الإلكتروني في أقرب وقت.',
      'throttled': 'تصل طلبات كثيرة جدًا الآن. أعد المحاولة بعد بضع دقائق.',
      'invalid':
          'يرجى ملء الحقول المطلوبة، والتحقق من بريدك الإلكتروني، والموافقة على إشعار الخصوصية.',
      'back': 'العودة إلى الموقع',
    },
    'de': {
      'ok': 'Ihre Anfrage ist eingegangen',
      'fail': 'Die Anfrage konnte nicht gesendet werden',
      'received': 'Danke. Wir melden uns so bald wie möglich per E-Mail.',
      'throttled':
          'Gerade kommen zu viele Anfragen. Bitte versuchen Sie es in ein paar Minuten erneut.',
      'invalid':
          'Bitte füllen Sie die Pflichtfelder aus, prüfen Sie Ihre E-Mail-Adresse und bestätigen Sie den Datenschutzhinweis.',
      'back': 'Zurück zur Website',
    },
  };
}
