import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:crypto/crypto.dart' as crypto;

import 'alerts.dart';
import 'clinic_text.dart';
import 'hl7.dart';
import 'locale.dart';
import 'model.dart';
import 'monitor.dart';
import 'monitor_text.dart';
import 'panel_style.dart';
import 'panel_text.dart';
import 'passwords.dart';
import 'qr_svg.dart';
import 'report.dart';
import 'store.dart';

part 'panel_account.dart';
part 'panel_alerts.dart';
part 'panel_care.dart';
part 'panel_monitor.dart';
part 'panel_overview.dart';
part 'panel_records.dart';
part 'panel_report.dart';
part 'panel_ui.dart';

/// Hekim ve araştırmacı için tarayıcı paneli (`/panel`).
///
/// - Giriş: portalın verdiği oturum anahtarıyla. Sunucu tarafında oturum
///   tutulur; çerez `HttpOnly`, `SameSite=Strict`, `Path=/panel` ve 8 saat
///   geçerli. Formlar oturuma bağlı CSRF jetonu taşır.
/// - Ana sayfa: rıza vermiş hastalar (yalnızca takma kimlik) ve davet formu.
/// - Hasta sayfası: yalnızca süren rızadaki türler; her görüntüleme ve
///   rızasız deneme erişim kaydına (AuditEvent) geçer.
/// - Sayfalar harici kaynak yüklemez; tüm değerler HTML'e kaçışlanarak yazılır.
/// - Dört dil ([PanelText]): `?lang=` ile seçilir, çerezde kalır; yoksa
///   tarayıcının dili.
/// - Hekim hesabı: kendi kaydı (`/panel/register`), e-posta ve şifreyle giriş
///   ([PasswordHasher]), hesap sayfası (`panel_account.dart`).
/// - Hasta kayıtları: hekimin kendi hasta dosyaları ve davet koduyla
///   bilekliğe bağlanmaları (`panel_records.dart`).
/// - Raporlar: tarih aralığıyla tüm türlerin özeti, yazdırma/PDF, CSV ve FHIR
///   dışa aktarma (`panel_report.dart`, [PatientReport]).
class PanelApi {
  PanelApi(
    this.store, {
    DateTime Function()? clock,
    Random? random,
    this.secureCookie = false,
    this.passwords = const PasswordHasher(),
  }) : _now = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  /// Şifre özeti; testler ve tarayıcı demosu daha az tur kullanır.
  final PasswordHasher passwords;

  final PortalStore store;
  final DateTime Function() _now;

  /// Deneme verisiyle açıldı ([seedDemo]); sayfalarda "Deneme verisi"
  /// etiketi görünür.
  bool demoData = false;
  final Random _random;

  /// HTTPS arkasında çalışırken true: çerez yalnızca şifreli bağlantıda gider.
  final bool secureCookie;

  static const cookieName = 'bk_panel';
  static const langCookie = PortalLocale.cookie;
  static const sessionLength = Duration(hours: 8);

  final _sessions = <String, _Session>{};

  /// Uyarı kuralları; panel açıldığında hekimin hastaları taranır.
  late final AlertEngine _engine = AlertEngine(store);

  /// E-posta başına son hatalı giriş zamanları.
  final _loginFailures = <String, List<DateTime>>{};

  /// Panelin yönlendiricisi. `?lang=` seçimini çereze yazan katman
  /// [PortalApi.handler] içindedir ([rememberLanguage]), bütün portal için.
  Handler get handler => _router.call;

  /// Sayfanın dili: `?lang=`, elle seçim (çerez), bağlanılan ülke, tarayıcı
  /// dili, İngilizce ([PortalLocale]).
  static PanelText _t(Request r) => PanelText.of(PortalLocale.of(r));

  static ClinicText _c(Request r) => ClinicText.of(_t(r).lang);

  static MonitorText _m(Request r) => MonitorText.of(_t(r).lang);

  late final Router _router = Router()
    ..get('/panel', (Request r) => _home(r))
    ..post('/panel/login', _login)
    ..post('/panel/logout', _logout)
    ..get('/panel/register', (Request r) => _registerPage(r))
    ..post('/panel/register', (Request r) => _register(r))
    ..get('/panel/account', (Request r) => _accountPage(r))
    ..get('/panel/patients', (Request r) => _patientsPage(r))
    ..get('/panel/activity', (Request r) => _activityPage(r))
    ..get('/panel/alerts', (Request r) => _alertsPage(r))
    ..post('/panel/alerts/<id>/ack', (Request r, String id) => _ackAlert(r, id))
    ..post('/panel/account/password', (Request r) => _changePassword(r))
    ..post('/panel/invites', _createInvite)
    ..get('/panel/records/new', (Request r) => _newRecordPage(r))
    ..post('/panel/records', (Request r) => _createRecord(r))
    ..get('/panel/records/<id>', (Request r, String id) => _recordPage(r, id))
    ..post(
      '/panel/records/<id>',
      (Request r, String id) => _updateRecord(r, id),
    )
    ..post(
      '/panel/records/<id>/invite',
      (Request r, String id) => _recordInvite(r, id),
    )
    ..post(
      '/panel/records/<id>/link',
      (Request r, String id) => _linkRecord(r, id),
    )
    ..post(
      '/panel/records/<id>/unlink',
      (Request r, String id) => _unlinkRecord(r, id),
    )
    ..post(
      '/panel/records/<id>/delete',
      (Request r, String id) => _deleteRecord(r, id),
    )
    ..post(
      '/panel/records/<id>/care',
      (Request r, String id) => _addCare(r, id),
    )
    ..post(
      '/panel/records/<id>/care/<entry>/done',
      (Request r, String id, String entry) => _careDone(r, id, entry),
    )
    ..get('/panel/patients/<id>', (Request r, String id) => _patient(r, id))
    ..get(
      '/panel/patients/<id>/report',
      (Request r, String id) => _report(r, id),
    )
    ..get(
      '/panel/patients/<id>/report.csv',
      (Request r, String id) => _exportCsv(r, id),
    )
    ..get(
      '/panel/patients/<id>/report.json',
      (Request r, String id) => _exportFhir(r, id),
    )
    ..get(
      '/panel/patients/<id>/report.hl7',
      (Request r, String id) => _exportHl7(r, id),
    );

  /// Oturum ve hesabı; giriş yoksa null.
  (_Session, Account)? _auth(Request r) {
    final s = _session(r);
    final me = s == null ? null : store.account(s.accountId);
    return s == null || me == null ? null : (s, me);
  }

  /// Hesabın [patientId] için süren rızası.
  Consent? _activeConsent(String accountId, String patientId) {
    final now = _now();
    return store
        .consentsForPatient(patientId)
        .where((c) => c.actorId == accountId && c.activeAt(now))
        .firstOrNull;
  }

  /// Hekimin, bu takma kimliğe bağlı hasta kaydı.
  PatientRecord? _recordFor(String ownerId, String patientId) => store
      .recordsOf(ownerId)
      .where((r) => r.patientId == patientId)
      .firstOrNull;

  /// Yeni oturum açar; çerez başlığını döner.
  String _startSession(Account a) {
    final id = _randomHex(32);
    _sessions[id] = _Session(a.id, _randomHex(16), _now().add(sessionLength));
    return _cookie(id);
  }

  // ---------------------------------------------------------------- oturum

  String _randomHex(int bytes) => List.generate(
    bytes,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  _Session? _session(Request r) {
    final id = _cookies(r)[cookieName];
    final s = id == null ? null : _sessions[id];
    if (s == null) return null;
    if (!_now().isBefore(s.expires)) {
      _sessions.remove(id);
      return null;
    }
    return s;
  }

  static Map<String, String> _cookies(Request r) {
    final out = <String, String>{};
    for (final part in (r.headers['cookie'] ?? '').split(';')) {
      final i = part.indexOf('=');
      if (i > 0) {
        out[part.substring(0, i).trim()] = part.substring(i + 1).trim();
      }
    }
    return out;
  }

  String _cookie(String value, {Duration? maxAge}) => [
    '$cookieName=$value',
    'Path=/panel',
    'HttpOnly',
    'SameSite=Strict',
    if (secureCookie) 'Secure',
    'Max-Age=${(maxAge ?? sessionLength).inSeconds}',
  ].join('; ');

  static Future<Map<String, List<String>>> _form(Request r) async {
    final out = <String, List<String>>{};
    for (final pair in (await r.readAsString()).split('&')) {
      if (pair.isEmpty) continue;
      final i = pair.indexOf('=');
      final k = Uri.decodeQueryComponent(i < 0 ? pair : pair.substring(0, i));
      final v = i < 0 ? '' : Uri.decodeQueryComponent(pair.substring(i + 1));
      out.putIfAbsent(k, () => []).add(v);
    }
    return out;
  }

  Future<Response> _login(Request r) async {
    final t = _t(r);
    final form = await _form(r);
    // E-posta ve şifreyle giriş (kendi kaydolan hekim).
    if (form.containsKey('email')) return _loginWithPassword(r, form);
    final token = form['token']?.firstOrNull?.trim() ?? '';
    final account = token.isEmpty ? null : store.accountByToken(token);
    if (account == null ||
        (account.role != Role.clinician && account.role != Role.researcher)) {
      return _html(401, _loginPage(t, error: t.badToken));
    }
    return Response(
      303,
      headers: {'location': '/panel', 'set-cookie': _startSession(account)},
    );
  }

  Future<Response> _logout(Request r) async {
    final s = _session(r);
    final form = await _form(r);
    if (s != null && form['csrf']?.firstOrNull == s.csrf) {
      _sessions.removeWhere((_, v) => identical(v, s));
    }
    return Response(
      303,
      headers: {
        'location': '/panel',
        'set-cookie': _cookie('', maxAge: Duration.zero),
      },
    );
  }

  // ------------------------------------------------------------- sayfalar

  static String _scopeBoxes(
    PanelText t,
    Iterable<ShareScope> scopes, {
    required Set<ShareScope> checked,
  }) => [
    for (final sc in scopes)
      '<label class="check"><input type="checkbox" name="scope" '
          'value="${sc.name}"${checked.contains(sc) ? ' checked' : ''}> '
          '${_h(t.scopeLabels[sc]!)}</label>',
  ].join();

  Future<Response> _createInvite(Request r) async {
    final t = _t(r);
    final s = _session(r);
    final me = s == null ? null : store.account(s.accountId);
    if (s == null || me == null) return _html(401, _loginPage(t));
    final form = await _form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${_h(t.formExpired)}</p>'),
      );
    }
    final purpose = form['purpose']?.firstOrNull?.trim() ?? '';
    final scopes = {
      for (final v in form['scope'] ?? const <String>[]) ?ShareScope.byName(v),
    };
    final days = int.tryParse(form['days']?.firstOrNull ?? '') ?? 0;
    if (purpose.isEmpty || scopes.isEmpty || days < 1 || days > 730) {
      return _html(
        400,
        _page(
          t,
          me,
          s,
          t.missingInfo,
          '<p>${_h(t.missingInfoBody)}</p>'
          '<p><a href="/panel">${_h(t.back)}</a></p>',
        ),
      );
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(
      7,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
    store.addInvite(
      Invite(
        code: code,
        actorId: me.id,
        purpose: purpose,
        requested: scopes,
        duration: Duration(days: days),
        expires: _now().add(Invite.lifetimeFor(me.role)),
      ),
    );
    return _html(
      201,
      _page(t, me, s, t.inviteCode, '''
<h1>${_h(t.inviteCode)}</h1>
<p dir="ltr" class="code">${_h(code)}</p>
<p>${_h(t.inviteCodeBody)}</p>
<p class="muted">${_h(t.requested)}: ${_h(_scopes(t, scopes))} · $days ${_h(t.days)}</p>
<p><a href="/panel">${_h(t.myPatients)}</a></p>
'''),
    );
  }

  // ----------------------------------------------------------- yardımcılar

  void _audit(String actorId, String patientId, bool ok, String text) =>
      store.addAudit(
        AuditEntry(
          id: store.nextId('audit'),
          time: _now(),
          actorId: actorId,
          patientId: patientId,
          action: AuditAction.read,
          success: ok,
          description: text,
        ),
      );

  static String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Tarih: gün.ay.yıl ya da yıl-ay-gün; Arapçada da Batı rakamları.
  static String _date(PanelText t, DateTime d) {
    final l = d.toLocal();
    return t.dateOrder == 'ymd'
        ? '${l.year}-${_two(l.month)}-${_two(l.day)}'
        : '${_two(l.day)}.${_two(l.month)}.${l.year}';
  }

  static String _dateTime(PanelText t, DateTime d) {
    final l = d.toLocal();
    return '${_date(t, l)} ${_two(l.hour)}:${_two(l.minute)}';
  }

  static String _scopes(PanelText t, Iterable<ShareScope> scopes) =>
      scopes.map((s) => t.scopeLabels[s]!).join(t.rtl ? '، ' : ', ');

  /// HTML kaçışı: metin ve öznitelik değerleri için.
  static String _h(String s) => const HtmlEscape(
    HtmlEscapeMode(escapeLtGt: true, escapeQuot: true, escapeApos: true),
  ).convert(s);

  Response _html(
    int status,
    String body, {
    bool printScript = false,
  }) => Response(
    status,
    body: body,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      // Harici kaynak yok; satır içi stil dışında hiçbir şey yüklenmez. Rapor
      // sayfasında yalnızca özeti bilinen yazdırma betiği çalışır.
      'content-security-policy':
          "default-src 'none'; style-src 'unsafe-inline'; img-src data:; "
          "${printScript ? "script-src '$_printScriptHash'; " : ''}"
          "form-action 'self'; frame-ancestors 'none'; base-uri 'none'",
      'x-content-type-options': 'nosniff',
      'referrer-policy': 'no-referrer',
      'cache-control': 'no-store',
    },
  );

  /// Dil seçici: aynı sayfayı başka dilde açar; [query] korunur (ör. rapor
  /// tarih aralığı).
  static String _languages(
    PanelText t, [
    Map<String, String> query = const {},
  ]) => PortalLocale.switcher(t.lang, query: query);

  String _loginPage(PanelText t, {String? error, String email = ''}) {
    final c = ClinicText.of(t.lang);
    final m = MonitorText.of(t.lang);
    return _document(t, t.signIn, """
<div class="auth">
<section class="auth-hero">
${_brand(large: true)}
<h1>${_h(t.signInTitle)}</h1>
<p>${_h(c['loginTagline'])}</p>
<ul>
<li>${_h(c['loginPoint1'])}</li>
<li>${_h(c['loginPoint2'])}</li>
<li>${_h(c['loginPoint3'])}</li>
</ul>
<div class="auth-preview" aria-hidden="true">
<div><b class="c-critical">${_PanelUi.icon('alerts', size: 18)}</b><span>${_h(m['loginPrevAlerts'])}</span></div>
<div><b class="c-stable">${_PanelUi.icon('trend', size: 18)}</b><span>${_h(m['loginPrevTrends'])}</span></div>
<div><b class="c-watch">${_PanelUi.icon('report', size: 18)}</b><span>${_h(m['loginPrevReports'])}</span></div>
</div>
<svg class="ecg" viewBox="0 0 440 60" preserveAspectRatio="none" aria-hidden="true"><polyline points="0,30 60,30 70,26 78,30 92,30 98,34 104,4 111,46 118,30 140,30 152,22 164,30 220,30 230,26 238,30 252,30 258,34 264,4 271,46 278,30 300,30 312,22 324,30 440,30"/></svg>
</section>
<main class="narrow">
<div>${_languages(t)}</div>
<h2>${_h(t.signIn)}</h2>
<p class="muted small" style="margin-top:0">${_h(m['loginSub'])}</p>
${error == null ? '' : '<p class="error" role="alert">${_h(error)}</p>'}
<form method="post" action="/panel/login" class="card">
<label>${_h(c['email'])}<input type="email" name="email" value="${_h(email)}" autocomplete="username" required maxlength="120"></label>
<label>${_h(c['password'])}<input type="password" name="password" autocomplete="current-password" required></label>
<button type="submit" class="wide">${_h(t.signIn)}</button>
</form>
<p class="small">${_h(c['noAccount'])} <a href="/panel/register">${_h(c['register'])}</a></p>
<details class="card">
<summary>${_h(c['signInWithKey'])}</summary>
<p class="muted small">${_h(t.signInIntro)}</p>
<form method="post" action="/panel/login">
<label>${_h(t.tokenLabel)}<input type="password" name="token" autocomplete="off" required></label>
<button type="submit" class="secondary">${_h(t.signIn)}</button>
</form>
</details>
<p class="faint tiny" style="margin-top:24px"><a href="/gizlilik" style="color:inherit">${_h(m['privacy'])}</a> · <a href="/developers" style="color:inherit">${_h(m['developers'])}</a></p>
</main>
</div>
""");
  }

  /// Marka işareti: nabız çizgisi.
  static String _brand({bool large = false}) =>
      '<span class="brand${large ? ' large' : ''}"><span class="mark">'
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" '
      'stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" '
      'aria-hidden="true"><path d="M2 12h4l2-5 4 10 2-5h8"/></svg></span>'
      '<span>Bileklik<small>Klinik</small></span></span>';

  /// Avatar için baş harfler; unvan (Dr., Prof., Doç.) atlanır.
  static String _initials(String name) {
    final parts = name
        .replaceAll(
          RegExp(r'^(Dr|Prof|Doç|Uzm)\.?\s+', caseSensitive: false),
          '',
        )
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    String first(String w) => String.fromCharCode(w.runes.first);
    final a = first(parts.first);
    final b = parts.length > 1 ? first(parts.last) : '';
    return (a + b).toUpperCase();
  }

  /// Panel sayfası: yan menü, üst çubuk (yol, hasta arama, dil) ve içerik.
  /// [bare] verilmezse içerik eski sayfalardaki gibi tek sütundur; başlık
  /// ve yol çubuğu yine eklenir.
  String _page(
    PanelText t,
    Account me,
    _Session s,
    String title,
    String body, {
    String? active,
    Map<String, String> query = const {},
    String head = '',
    bool bare = false,
    List<(String?, String)>? crumbs,
    String search = '',
  }) {
    final c = ClinicText.of(t.lang);
    final m = MonitorText.of(t.lang);
    final openAlerts = store.alertsOf(me.id).where((a) => a.open).length;
    String nav(String href, String icon, String label, {String extra = ''}) =>
        '<a href="$href"${href == active ? ' aria-current="page"' : ''}>'
        '${_PanelUi.icon(icon)}<span>${_h(label)}</span>$extra</a>';
    final trail = crumbs ??
        [
          if (active != '/panel') ('/panel', m['navOverview']),
          (null, title),
        ];
    final crumbHtml = [
      for (final (href, label) in trail)
        href == null
            ? '<span aria-current="page">${_h(label)}</span>'
            : '<a href="$href">${_h(label)}</a>',
    ].join('<span class="sep" aria-hidden="true">›</span>');
    final lang = PortalLocale.names[t.lang] ?? t.lang;
    return _document(t, title, """
<input type="checkbox" id="navtoggle" class="navtoggle" aria-hidden="true" tabindex="-1">
<div class="shell">
<label for="navtoggle" class="scrim" aria-hidden="true"></label>
<aside class="side noprint" aria-label="${_h(m['navLabel'])}">
<a href="/panel" style="text-decoration:none">${_brand()}</a>
<nav class="menu" aria-label="${_h(m['navLabel'])}">
${nav('/panel', 'overview', m['navOverview'])}
${nav('/panel/patients', 'patients', m['navPatients'])}
${nav('/panel/alerts', 'alerts', c['navAlerts'], extra: openAlerts == 0 ? '' : '<span class="count">$openAlerts</span>')}
${nav('/panel/activity', 'activity', m['navActivity'])}
<div class="menu-label">${_h(m['navManage'])}</div>
${nav('/panel/records/new', 'newPatient', c['navNewPatient'])}
${nav('/panel/account', 'account', c['navAccount'])}
</nav>
<div class="side-foot">
<div class="who"><span class="avatar" aria-hidden="true">${_h(_initials(me.name))}</span><span><strong>${_h(me.name)}</strong>${me.organization == null ? '' : '<small>${_h(me.organization!)}</small>'}</span></div>
<form method="post" action="/panel/logout"><input type="hidden" name="csrf" value="${_h(s.csrf)}"><button class="link" type="submit">${_h(t.signOut)}</button></form>
<div class="side-links"><a href="/gizlilik">${_h(m['privacy'])}</a><a href="/developers">${_h(m['developers'])}</a></div>
</div>
</aside>
<div class="content">
<header class="topbar noprint">
<label for="navtoggle" class="burger" title="${_h(m['navLabel'])}">${_PanelUi.icon('menu', size: 20)}<span class="sr">${_h(m['navLabel'])}</span></label>
<nav class="crumbs" aria-label="${_h(m['breadcrumbs'])}">$crumbHtml</nav>
<form class="gsearch" method="get" action="/panel/patients" role="search">${_PanelUi.icon('search', size: 16)}<input type="search" name="q" value="${_h(search)}" placeholder="${_h(m['searchPatients'])}" aria-label="${_h(m['searchPatients'])}" maxlength="80"></form>
<details class="pop"><summary title="${_h(m['language'])}">${_PanelUi.icon('globe', size: 16)} ${_h(lang)}</summary><div class="pop-body">${_languages(t, query)}</div></details>
</header>
<main>
${bare || me.verified ? '' : '<p class="warn noprint" role="status">${_h(c['unverified'])}</p>'}
${bare ? body : '<div class="legacy">$body</div>'}
</main>
</div>
</div>
""", head: head);
  }

  static String _document(
    PanelText t,
    String title,
    String body, {
    String head = '',
  }) =>
      """<!doctype html>
<html lang="${t.lang}" dir="${t.rtl ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">$head
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0B0F15">
<title>${_h(title)} · Bileklik</title>
<style>
${panelCss()}
</style>
</head>
<body>
$body
</body>
</html>
""";
}

class _Session {
  _Session(this.accountId, this.csrf, this.expires);
  final String accountId;
  final String csrf;
  final DateTime expires;
}
