import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:crypto/crypto.dart' as crypto;

import 'clinic_text.dart';
import 'model.dart';
import 'panel_text.dart';
import 'passwords.dart';
import 'report.dart';
import 'store.dart';

part 'panel_account.dart';
part 'panel_records.dart';
part 'panel_report.dart';

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
  final Random _random;

  /// HTTPS arkasında çalışırken true: çerez yalnızca şifreli bağlantıda gider.
  final bool secureCookie;

  static const cookieName = 'bk_panel';
  static const langCookie = 'bk_lang';
  static const sessionLength = Duration(hours: 8);

  final _sessions = <String, _Session>{};

  /// E-posta başına son hatalı giriş zamanları.
  final _loginFailures = <String, List<DateTime>>{};

  /// `?lang=` verilirse seçim çerezde saklanır.
  Handler get handler => (r) async {
    final res = await _router.call(r);
    final lang = r.url.queryParameters['lang'];
    if (lang == null || !PanelText.supported.contains(lang)) return res;
    return res.change(
      headers: {
        'set-cookie': [
          ...?res.headersAll['set-cookie'],
          '$langCookie=$lang; Path=/panel; SameSite=Strict; Max-Age=31536000',
        ],
      },
    );
  };

  /// Sayfanın dili: `?lang=`, sonra çerez, sonra `Accept-Language`.
  static PanelText _t(Request r) {
    final q = r.url.queryParameters['lang'];
    if (q != null && PanelText.supported.contains(q)) return PanelText.of(q);
    final c = _cookies(r)[langCookie];
    if (c != null && PanelText.supported.contains(c)) return PanelText.of(c);
    return PanelText.of(
      PanelText.fromAcceptLanguage(r.headers['accept-language']),
    );
  }

  static ClinicText _c(Request r) => ClinicText.of(_t(r).lang);

  late final Router _router = Router()
    ..get('/panel', _home)
    ..post('/panel/login', _login)
    ..post('/panel/logout', _logout)
    ..get('/panel/register', (Request r) => _registerPage(r))
    ..post('/panel/register', (Request r) => _register(r))
    ..get('/panel/account', (Request r) => _accountPage(r))
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
    ..get('/panel/patients/<id>', _patient)
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

  Response _home(Request r) {
    final t = _t(r);
    final c = _c(r);
    final auth = _auth(r);
    if (auth == null) return _html(200, _loginPage(t));
    final (s, me) = auth;
    final now = _now();
    final records = store.recordsOf(me.id);
    final linked = {for (final rec in records) ?rec.patientId};
    final consents = [
      for (final k in store.consentsForActor(me.id))
        if (k.activeAt(now) && !linked.contains(k.patientId)) k,
    ]..sort((a, b) => b.start.compareTo(a.start));

    DateTime? lastData(String patientId, Consent k) => store
        .observations(patientId, codes: k.codes)
        .map((o) => o.effective)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    // Ad ya da dosya numarasında arama (büyük/küçük harf fark etmez).
    final q = (r.url.queryParameters['q'] ?? '').trim();
    final needle = q.toLowerCase();
    final shown = [
      for (final rec in records)
        if (needle.isEmpty ||
            rec.name.toLowerCase().contains(needle) ||
            (rec.fileNo ?? '').toLowerCase().contains(needle))
          rec,
    ];
    final recordRows = StringBuffer();
    for (final rec in shown) {
      final (label, cls) = _recordStatus(c, rec);
      final k = rec.patientId == null
          ? null
          : _activeConsent(me.id, rec.patientId!);
      final last = k == null ? null : lastData(rec.patientId!, k);
      final age = rec.ageAt(now);
      recordRows.write(
        '<tr><td><a href="/panel/records/${_h(Uri.encodeComponent(rec.id))}">'
        '${_h(rec.name)}</a></td>'
        '<td dir="ltr" class="nowrap">${_h(rec.fileNo ?? '—')}</td>'
        '<td>${age == null ? '—' : _h('$age')}</td>'
        '<td><span class="badge $cls">${_h(label)}</span></td>'
        '<td>${k == null ? '—' : _h(_scopes(t, k.scopes))}</td>'
        '<td>${last == null ? '—' : _h(_dateTime(t, last))}</td></tr>',
      );
    }
    final rows = StringBuffer();
    for (final k in consents) {
      final last = lastData(k.patientId, k);
      rows.write(
        '<tr><td><a href="/panel/patients/${_h(Uri.encodeComponent(k.patientId))}">'
        '${_h(_shortId(k.patientId))}</a></td>'
        '<td>${_h(_scopes(t, k.scopes))}</td>'
        '<td>${_h(_date(t, k.end))}</td>'
        '<td>${last == null ? '—' : _h(_dateTime(t, last))}</td></tr>',
      );
    }
    final scopeBoxes = _scopeBoxes(t, ShareScope.values, checked: const {});
    final recordsHtml = records.isEmpty
        ? '<p class="muted">${_h(c['noRecords'])}</p>'
        : '''
<form method="get" action="/panel" class="row" role="search">
<label>${_h(c['search'])}<input type="search" name="q" value="${_h(q)}" placeholder="${_h(c['searchHint'])}" maxlength="80"></label>
<button type="submit" class="secondary">${_h(c['search'])}</button>
</form>
${shown.isEmpty ? '<p class="muted">${_h(c['noMatch'])}</p>' : '''
<div class="table-wrap"><table>
<thead><tr><th>${_h(c['colName'])}</th><th>${_h(c['colFileNo'])}</th><th>${_h(c['colAge'])}</th><th>${_h(c['colStatus'])}</th><th>${_h(t.colShared)}</th><th>${_h(t.colLastData)}</th></tr></thead>
<tbody>$recordRows</tbody>
</table></div>'''}''';
    return _html(
      200,
      _page(t, me, s, t.myPatients, active: '/panel', '''
<div class="row"><h1 style="flex:1">${_h(t.myPatients)}</h1><a class="button" href="/panel/records/new">+ ${_h(c['newPatient'])}</a></div>
<h2>${_h(c['recordsTitle'])}</h2>
$recordsHtml
<h2>${_h(c['unlinkedTitle'])}</h2>
${consents.isEmpty ? '<p class="muted">${_h(t.noPatients)}</p>' : '''
<p class="muted small">${_h(c['unlinkedIntro'])}</p>
<div class="table-wrap"><table>
<thead><tr><th>${_h(t.colPatient)}</th><th>${_h(t.colShared)}</th><th>${_h(t.colConsentEnd)}</th><th>${_h(t.colLastData)}</th></tr></thead>
<tbody>$rows</tbody>
</table></div>'''}
<details class="card">
<summary><strong>${_h(t.createInvite)}</strong></summary>
<form method="post" action="/panel/invites">
<input type="hidden" name="csrf" value="${_h(s.csrf)}">
<label>${_h(t.purpose)}<textarea name="purpose" required maxlength="500" rows="3"></textarea></label>
<fieldset><legend>${_h(t.requestedData)}</legend>$scopeBoxes</fieldset>
<label>${_h(t.durationDays)}<input type="number" name="days" value="90" min="1" max="730" required></label>
<button type="submit">${_h(t.createCode)}</button>
</form>
</details>
'''),
    );
  }

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
        expires: _now().add(const Duration(days: 30)),
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

  Response _patient(Request r, String id) {
    final t = _t(r);
    final s = _session(r);
    final me = s == null ? null : store.account(s.accountId);
    if (s == null || me == null) return _html(401, _loginPage(t));
    final now = _now();
    final consent = store
        .consentsForPatient(id)
        .where((c) => c.actorId == me.id && c.activeAt(now))
        .firstOrNull;
    if (consent == null) {
      _audit(me.id, id, false, 'Panel: rıza olmadan erişim denemesi');
      return _html(
        403,
        _page(t, me, s, t.noAccess, '<p>${_h(t.noAccessBody)}</p>'),
      );
    }
    final c = _c(r);
    final days = switch (r.url.queryParameters['days']) {
      '30' => 30,
      '90' => 90,
      _ => 7,
    };
    final from = now.subtract(Duration(days: days));
    final items = store.observations(id, codes: consent.codes, from: from);
    _audit(
      me.id,
      id,
      true,
      'Panel: ${items.length} ölçüm görüntülendi ($days gün)',
    );
    final record = _recordFor(me.id, id);

    final byCode = <String, List<StoredObservation>>{};
    for (final o in items) {
      byCode.putIfAbsent(o.code, () => []).add(o);
    }
    final sections = StringBuffer();
    for (final code in _codeOrder.where(byCode.containsKey)) {
      final list = byCode[code]!;
      final latest = list.last;
      final values = [for (final o in list) ?_number(o.resource)];
      final avg = values.isEmpty
          ? null
          : values.reduce((a, b) => a + b) / values.length;
      final unit = _unit(t, latest.resource);
      sections.write(
        '<section class="card"><h2>${_h(t.codeLabels[code] ?? code)}</h2>',
      );
      sections.write(
        '<p class="big">${_h(_summary(t, latest.resource))}</p>'
        '<p class="muted">${_h(t.last)}: ${_h(_dateTime(t, latest.effective))} · '
        '${_h(days == 7 ? t.recordsIn7Days.replaceAll('{n}', '${list.length}') : c.f('recordsInPeriod', {'n': list.length}))}'
        '${avg == null ? '' : ' · ${_h(t.average)} ${_h(t.number(avg))} ${_h(unit)}'}</p>',
      );
      if (code == '8867-4' && days == 7) {
        sections.write(_sparkline(t, list, from, now));
      }
      sections.write(
        '<table><thead><tr><th>${_h(t.colTime)}</th><th>${_h(t.colValue)}</th></tr></thead><tbody>',
      );
      for (final o in list.reversed.take(20)) {
        sections.write(
          '<tr><td>${_h(_dateTime(t, o.effective))}</td>'
          '<td>${_h(_summary(t, o.resource))}</td></tr>',
        );
      }
      sections.write('</tbody></table></section>');
    }
    return _html(
      200,
      _page(t, me, s, '${t.patient} ${_shortId(id)}', '''
<p><a href="${record == null ? '/panel' : '/panel/records/${_h(Uri.encodeComponent(record.id))}'}">${t.rtl ? '→' : '←'} ${_h(record?.name ?? t.myPatients)}</a></p>
<h1>${record == null ? '${_h(t.patient)} <span dir="ltr">${_h(_shortId(id))}</span>' : '${_h(record.name)} <span class="muted small" dir="ltr">${_h(_shortId(id))}</span>'}</h1>
<p class="muted">${_h(t.shared)}: ${_h(_scopes(t, consent.scopes))} · ${_h(t.consentEnd)} ${_h(_date(t, consent.end))}</p>
<nav class="row noprint" aria-label="${_h(c['period'])}">
${[
        for (final d in const [7, 30, 90]) d == days ? '<strong>${_h(c['last$d'])}</strong>' : '<a href="/panel/patients/${_h(Uri.encodeComponent(id))}?days=$d">${_h(c['last$d'])}</a>',
      ].join(' · ')}
<span style="flex:1"></span>
<a class="button" href="/panel/patients/${_h(Uri.encodeComponent(id))}/report">${_h(c['createReport'])}</a>
</nav>
${sections.isEmpty ? '<p class="muted">${_h(days == 7 ? t.noRecentData : c['noData'])}</p>' : sections}
<p class="muted small">${_h(t.disclaimer)}</p>
'''),
    );
  }

  /// Son 7 günün günlük nabız ortalamaları, satır içi SVG.
  static String _sparkline(
    PanelText t,
    List<StoredObservation> list,
    DateTime from,
    DateTime to,
  ) {
    final days = <int, List<double>>{};
    for (final o in list) {
      final v = _number(o.resource);
      if (v == null) continue;
      final d = o.effective.difference(from).inDays.clamp(0, 6);
      days.putIfAbsent(d, () => []).add(v);
    }
    if (days.length < 2) return '';
    final avgs = {
      for (final e in days.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };
    final lo = avgs.values.reduce(min) - 5;
    final hi = avgs.values.reduce(max) + 5;
    final keys = avgs.keys.toList()..sort();
    final pts = [
      for (final k in keys)
        '${(k * 50).toStringAsFixed(0)},'
            '${(60 - (avgs[k]! - lo) / (hi - lo) * 60).toStringAsFixed(1)}',
    ].join(' ');
    return '<svg class="spark" viewBox="-4 -4 308 68" role="img" '
        'aria-label="${_h(t.sparkLabel)}">'
        '<polyline fill="none" stroke="currentColor" stroke-width="2" '
        'points="$pts"/></svg>';
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

  static const _codeOrder = [
    '8867-4',
    '80404-7',
    '59408-5',
    '85354-9',
    '11524-6',
    '93832-4',
    '55423-8',
    '55430-3',
    '41981-2',
    'workout',
    '8310-5',
    '9279-1',
    'stress',
    '29463-7',
    '39156-5',
    '41982-0',
    'muscle-mass',
  ];

  static Map? _quantity(Map<String, Object?> r) => r['valueQuantity'] as Map?;

  static double? _number(Map<String, Object?> r) =>
      (_quantity(r)?['value'] as num?)?.toDouble();

  static String _unit(PanelText t, Map<String, Object?> r) =>
      switch (_quantity(r)?['unit']) {
        final String u => t.units[u] ?? u,
        _ => '',
      };

  /// Bir kaydın tek satırlık özeti.
  static String _summary(PanelText t, Map<String, Object?> r) {
    final components = (r['component'] as List?)?.cast<Map>() ?? const [];
    double? component(String code) {
      for (final c in components) {
        final coding = ((c['code'] as Map)['coding'] as List).first as Map;
        if (coding['code'] == code) {
          return ((c['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();
        }
      }
      return null;
    }

    final code =
        (((r['code'] as Map)['coding'] as List).first as Map)['code'] as String;
    switch (code) {
      case '85354-9':
        final sys = component('8480-6'), dia = component('8462-4');
        return '${t.number(sys ?? 0)}/${t.number(dia ?? 0)} mmHg';
      case '11524-6':
        final hr = component('8867-4');
        return hr == null
            ? t.ecgRecording
            : '${t.ecgRecording} · ${t.average} ${t.number(hr)} '
                  '${t.units['beats/minute']}';
      case 'workout':
        final minutes = component('workout-duration');
        return minutes == null
            ? t.workout
            : '${t.workout} · ${t.number(minutes)} ${t.units['min']}';
    }
    final v = _number(r);
    if (v == null) return '—';
    if (code == '93832-4') return t.duration(v.round());
    final unit = _unit(t, r);
    return unit.isEmpty ? t.number(v) : '${t.number(v)} $unit';
  }

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

  /// Dil seçici: aynı sayfayı başka dilde açar.
  static String _languages(PanelText t) => [
    for (final l in PanelText.supported)
      l == t.lang
          ? '<strong lang="$l">${_h(PanelText.of(l).language)}</strong>'
          : '<a href="?lang=$l" lang="$l" hreflang="$l">'
                '${_h(PanelText.of(l).language)}</a>',
  ].join(' · ');

  String _loginPage(PanelText t, {String? error, String email = ''}) {
    final c = ClinicText.of(t.lang);
    return _document(t, t.signIn, '''
<main class="narrow">
<nav class="langs small">${_languages(t)}</nav>
<h1>${_h(t.signInTitle)}</h1>
${error == null ? '' : '<p class="error" role="alert">${_h(error)}</p>'}
<form method="post" action="/panel/login" class="card">
<label>${_h(c['email'])}<input type="email" name="email" value="${_h(email)}" autocomplete="username" required maxlength="120"></label>
<label>${_h(c['password'])}<input type="password" name="password" autocomplete="current-password" required></label>
<button type="submit">${_h(t.signIn)}</button>
</form>
<p>${_h(c['noAccount'])} <a href="/panel/register">${_h(c['register'])}</a></p>
<details class="card">
<summary>${_h(c['signInWithKey'])}</summary>
<p class="muted">${_h(t.signInIntro)}</p>
<form method="post" action="/panel/login">
<label>${_h(t.tokenLabel)}<input type="password" name="token" autocomplete="off" required></label>
<button type="submit">${_h(t.signIn)}</button>
</form>
</details>
</main>
''');
  }

  String _page(
    PanelText t,
    Account me,
    _Session s,
    String title,
    String body, {
    String? active,
  }) {
    final c = ClinicText.of(t.lang);
    String nav(String href, String key) => href == active
        ? '<a href="$href" aria-current="page">${_h(c[key])}</a>'
        : '<a href="$href">${_h(c[key])}</a>';
    return _document(t, title, '''
<header class="noprint">
<span><strong>Bileklik</strong> · ${_h(me.name)}${me.organization == null ? '' : ' · ${_h(me.organization!)}'}</span>
<nav class="nav">${nav('/panel', 'navPatients')}${nav('/panel/records/new', 'navNewPatient')}${nav('/panel/account', 'navAccount')}</nav>
<span class="small">${_languages(t)}</span>
<form method="post" action="/panel/logout"><input type="hidden" name="csrf" value="${_h(s.csrf)}"><button class="link" type="submit">${_h(t.signOut)}</button></form>
</header>
<main>
${me.verified ? '' : '<p class="warn noprint" role="status">${_h(c['unverified'])}</p>'}
$body
</main>
''');
  }

  static String _document(PanelText t, String title, String body) =>
      '''<!doctype html>
<html lang="${t.lang}" dir="${t.rtl ? 'rtl' : 'ltr'}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_h(title)} · Bileklik</title>
<style>
:root { color-scheme: light dark; --bg: #f6f7fb; --fg: #16181d; --muted: #5d6472; --card: #fff; --line: #dfe3ea; --accent: #2457d6; --danger: #b42318; }
@media (prefers-color-scheme: dark) { :root { --bg: #111318; --fg: #e9ebf0; --muted: #9aa3b2; --card: #1b1e25; --line: #2c313b; --accent: #7aa2ff; --danger: #ff8a80; } }
* { box-sizing: border-box; }
body { margin: 0; font: 16px/1.5 system-ui, sans-serif; background: var(--bg); color: var(--fg); }
header { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 12px; padding: 12px 16px; border-bottom: 1px solid var(--line); background: var(--card); }
header form { margin: 0; }
main { max-width: 960px; margin: 0 auto; padding: 16px; }
main.narrow { max-width: 420px; }
h1 { font-size: 1.6rem; margin: 8px 0 12px; }
h2 { font-size: 1.15rem; margin: 24px 0 8px; }
a { color: var(--accent); }
.card { background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 16px; margin: 12px 0; }
.muted { color: var(--muted); }
.small { font-size: .875rem; }
.error { color: var(--danger); }
.big { font-size: 1.6rem; font-weight: 700; margin: 4px 0; }
.code { font: 700 2.4rem/1.2 ui-monospace, monospace; letter-spacing: .2em; }
table { width: 100%; border-collapse: collapse; background: var(--card); }
th, td { text-align: start; padding: 8px; border-bottom: 1px solid var(--line); }
label { display: block; margin: 8px 0; }
label.check { display: inline-flex; align-items: center; gap: 6px; margin-inline-end: 16px; min-height: 32px; }
input, textarea { display: block; min-height: 44px; width: 100%; margin-top: 4px; padding: 10px; font: inherit; border: 1px solid var(--line); border-radius: 8px; background: var(--bg); color: var(--fg); }
label.check input { display: inline; width: auto; margin: 0; }
fieldset { border: 1px solid var(--line); border-radius: 8px; margin: 12px 0; }
button { min-height: 44px; padding: 8px 18px; font: inherit; font-weight: 600; border: 0; border-radius: 8px; background: var(--accent); color: #fff; cursor: pointer; }
button.link { background: none; color: var(--accent); padding: 8px; }
.langs { margin-bottom: 8px; }
.spark { width: 100%; max-width: 320px; height: 72px; color: var(--accent); }
.nav { display: flex; flex-wrap: wrap; gap: 4px 16px; }
.nav a { text-decoration: none; padding: 10px 2px; }
.nav a[aria-current] { font-weight: 700; border-bottom: 2px solid var(--accent); }
.warn { background: #fff4d6; color: #5c4200; border: 1px solid #f0c64a; border-radius: 8px; padding: 10px 12px; }
@media (prefers-color-scheme: dark) { .warn { background: #3a2f10; color: #ffe08a; border-color: #7a5d14; } }
.ok { color: #1a7f37; }
.nowrap { white-space: nowrap; }
.row { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: flex-end; }
.row > label { flex: 1 1 180px; }
.row > button, .row > a.button { flex: 0 0 auto; }
a.button { display: inline-flex; align-items: center; min-height: 44px; padding: 8px 18px; border-radius: 8px; background: var(--accent); color: #fff; font-weight: 600; text-decoration: none; }
a.button.secondary, button.secondary { background: transparent; color: var(--accent); border: 1px solid var(--accent); }
button.danger { background: var(--danger); }
select { display: block; width: 100%; margin-top: 4px; padding: 10px; font: inherit; border: 1px solid var(--line); border-radius: 8px; background: var(--bg); color: var(--fg); min-height: 44px; }
.badge { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: .8rem; border: 1px solid var(--line); white-space: nowrap; }
.badge.on { border-color: #1a7f37; color: #1a7f37; }
.badge.wait { border-color: #b7791f; color: #b7791f; }
.table-wrap { overflow-x: auto; }
dl.facts { display: grid; grid-template-columns: max-content 1fr; gap: 4px 16px; margin: 0; }
dl.facts dt { color: var(--muted); }
dl.facts dd { margin: 0; overflow-wrap: anywhere; }
details summary { cursor: pointer; padding: 10px 0; }
.grid2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 0 16px; }
td.num, th.num { text-align: end; font-variant-numeric: tabular-nums; white-space: nowrap; }
th[scope=row] { font-weight: 500; }
table.compact th, table.compact td { padding: 4px 8px; font-size: .9rem; }
.chart { width: 100%; height: auto; max-height: 220px; margin: 8px 0; color: var(--accent); }
.chart text { font: 11px system-ui, sans-serif; fill: var(--muted); }
.chart .grid { stroke: var(--line); stroke-width: 1; }
.chart .band { fill: currentColor; opacity: .14; }
.chart .line { fill: none; stroke: currentColor; stroke-width: 2; }
.chart circle.line { fill: currentColor; stroke: none; }
.chart .line2 { fill: none; stroke: #c2410c; stroke-width: 2; }
.chart circle.line2 { fill: #c2410c; stroke: none; }
.chart .bar { fill: currentColor; opacity: .8; }
.report-head h1 { margin-top: 0; }
ul.findings { padding-inline-start: 20px; }
ul.findings li { margin: 4px 0; }
.sign { margin-top: 32px; display: flex; justify-content: flex-end; }
.sign span { border-top: 1px solid var(--fg); padding-top: 4px; min-width: 240px; text-align: center; }
details.daily > summary { font-weight: 600; }
@page { size: A4; margin: 14mm 12mm; }
@media print {
  :root { --bg: #fff; --fg: #000; --muted: #444; --card: #fff; --line: #bbb; --accent: #1d4ed8; }
  body { font-size: 11pt; background: #fff; color: #000; }
  .noprint, header.noprint, .warn { display: none !important; }
  main { max-width: none; padding: 0; }
  .card { border: 0; border-top: 1px solid #bbb; border-radius: 0; padding: 8px 0; margin: 8px 0; }
  .avoid, tr, .chart { break-inside: avoid; }
  h2 { break-after: avoid; }
  details.daily > summary { display: none; }
  details.daily:not([open]) { display: none; }
  .table-wrap { overflow: visible; }
  a { color: inherit; text-decoration: none; }
}
@media (max-width: 600px) { table { font-size: .9rem; } th, td { padding: 6px 4px; } dl.facts { grid-template-columns: 1fr; gap: 0; } dl.facts dd { margin-bottom: 8px; } }
</style>
</head>
<body>
$body
</body>
</html>
''';
}

class _Session {
  _Session(this.accountId, this.csrf, this.expires);
  final String accountId;
  final String csrf;
  final DateTime expires;
}
