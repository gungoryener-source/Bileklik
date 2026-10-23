// Portalın tarayıcıda çalışan denemesi.
//
// Gerçek portal kodu (PortalApi, hekim paneli, gizlilik sayfası) sunucu
// olmadan, sayfanın içinde çalışır. İstekler ağa gitmez: bağlantı ve formlar
// yakalanıp doğrudan PortalApi'ye verilir, dönen HTML sayfaya yazılır.
// Çerezler bellekte tutulur. Veriler deneme verisidir ([seedDemo]) ve sayfa
// yenilenince baştan kurulur.
// Portalın dosya deposu (dart:io) tarayıcıda yok; yalnızca gereken
// kütüphaneler alınır.
// ignore_for_file: implementation_imports
import 'dart:js_interop';

import 'package:bileklik_portal/src/api.dart';
import 'package:bileklik_portal/src/demo.dart';
import 'package:bileklik_portal/src/passwords.dart';
import 'package:bileklik_portal/src/store.dart';
import 'package:shelf/shelf.dart';
import 'package:web/web.dart' as web;

late final PortalApi _api;
final _cookies = <String, String>{};
var _path = '/panel';

Future<void> main() async {
  // Şifre özeti tarayıcıda yavaş olmasın diye az turla (deneme verisi).
  _api = PortalApi(
    MemoryPortalStore(),
    passwords: const PasswordHasher(iterations: 2000),
  );
  await seedDemo(_api);
  web.document.addEventListener('click', _onClick.toJS);
  web.document.addEventListener('submit', _onSubmit.toJS);
  web.window.addEventListener(
    'hashchange',
    ((web.Event _) {
      _fromHash();
    }).toJS,
  );
  await _fromHash();
}

/// Adres çubuğundaki `#/panel` gibi yol; yoksa panel.
Future<void> _fromHash() async {
  final hash = web.window.location.hash;
  final path = hash.length > 1 ? hash.substring(1) : '/panel';
  if (path != _path || web.document.querySelector('[data-demo]') == null) {
    await _go('GET', path);
  }
}

Future<void> _go(String method, String path, {String? form}) async {
  final headers = <String, String>{
    'accept-language': web.window.navigator.language,
    if (_cookies.isNotEmpty)
      'cookie': [for (final e in _cookies.entries) '${e.key}=${e.value}'].join('; '),
    if (form != null) 'content-type': 'application/x-www-form-urlencoded',
  };
  final res = await _api.handler(
    Request(method, Uri.parse('http://demo$path'), headers: headers, body: form),
  );
  for (final c in res.headersAll['set-cookie'] ?? const <String>[]) {
    final pair = c.split(';').first;
    final i = pair.indexOf('=');
    if (i <= 0) continue;
    final name = pair.substring(0, i);
    final value = pair.substring(i + 1);
    if (value.isEmpty || c.contains('Max-Age=0')) {
      _cookies.remove(name);
    } else {
      _cookies[name] = value;
    }
  }
  final location = res.headers['location'];
  if (res.statusCode == 303 && location != null) {
    return _go('GET', location);
  }
  // CSV ve FHIR dışa aktarma: sayfaya yazılmaz, dosya olarak indirilir.
  final disposition = res.headers['content-disposition'];
  if (disposition != null && disposition.startsWith('attachment')) {
    final name = RegExp('filename="([^"]+)"').firstMatch(disposition)?.group(1) ?? 'bileklik';
    final blob = web.Blob(
      [(await res.readAsString()).toJS].toJS,
      web.BlobPropertyBag(type: res.headers['content-type'] ?? 'text/plain'),
    );
    final url = web.URL.createObjectURL(blob);
    (web.document.createElement('a') as web.HTMLAnchorElement)
      ..href = url
      ..download = name
      ..click();
    web.URL.revokeObjectURL(url);
    return;
  }
  _path = path;
  if (web.window.location.hash != '#$path') {
    web.window.history.pushState(null, '', '#$path');
  }
  _render(await res.readAsString());
}

void _render(String html) {
  final doc = web.DOMParser().parseFromString(html.toJS, 'text/html');
  final root = doc.documentElement;
  final body = doc.body;
  if (root == null || body == null) return;
  body.prepend(_banner(doc));
  final adopted = web.document.adoptNode(root);
  final current = web.document.documentElement;
  if (current == null) return;
  web.document.replaceChild(adopted, current);
  web.window.scrollTo(0.toJS, 0);
}

/// Sayfanın üstündeki deneme bandı.
web.Element _banner(web.Document doc) {
  final b = doc.createElement('div')
    ..setAttribute('data-demo', '')
    ..setAttribute(
      'style',
      'background:#2b2140;color:#e9e3ff;padding:10px 16px;font:14px/1.5 '
          'system-ui,sans-serif;display:flex;flex-wrap:wrap;gap:6px 16px;'
          'align-items:center',
    );
  b.innerHTML =
      ('<strong>Deneme</strong>'
              '<span>Tarayıcıda çalışır, veriler örnektir ve yenileyince '
              'sıfırlanır.</span>'
              '<span>Hekim girişi: <code style="background:#ffffff1a;'
              'padding:1px 6px;border-radius:4px">demo@bileklik.app</code> / '
              '<code style="background:#ffffff1a;padding:1px 6px;'
              'border-radius:4px">demo-sifre-2026</code> (ya da anahtar '
              '<code style="background:#ffffff1a;padding:1px 6px;'
              'border-radius:4px">demo-doctor</code>) · '
              'Araştırma: <code style="background:#ffffff1a;padding:1px 6px;'
              'border-radius:4px">demo-research</code></span>'
              '<span><a style="color:#b9a7ff" href="/panel">Panel</a> · '
              '<a style="color:#b9a7ff" href="/gizlilik">Gizlilik '
              'politikası</a></span>')
          .toJS;
  return b;
}

void _onClick(web.Event e) {
  final target = e.target;
  if (target == null) return;
  // Rapordaki "Yazdır / PDF" düğmesi (DOMParser ile gelen betik çalışmaz).
  if ((target as web.Element).closest('#print') != null) {
    e.preventDefault();
    web.window.print();
    return;
  }
  final link = target.closest('a');
  final href = link?.getAttribute('href');
  if (link == null || href == null || href.startsWith('http')) return;
  e.preventDefault();
  _go('GET', Uri.parse('http://demo$_path').resolve(href).toString().substring('http://demo'.length));
}

void _onSubmit(web.Event e) {
  final form = e.target as web.HTMLFormElement;
  e.preventDefault();
  final action = form.getAttribute('action') ?? _path;
  final body = web.URLSearchParams(web.FormData(form)).toString();
  final method = (form.getAttribute('method') ?? 'get').toUpperCase();
  if (method == 'GET') {
    _go('GET', '$action?$body');
  } else {
    _go(method, action, form: body);
  }
}
