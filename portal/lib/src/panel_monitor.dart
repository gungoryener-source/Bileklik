part of 'panel.dart';

/// Hasta listesi (`/panel/patients`) ve hasta izlem sayfası
/// (`/panel/patients/<takma kimlik>`).
///
/// - Liste: arama, durum süzgeci, sütuna göre sıralama ve sayfalama;
///   hepsi adres parametresiyle (betik yok), paylaşılabilir ve geri tuşuyla
///   çalışır.
/// - İzlem: hastanın başlığı ve sekmeleri, durumun dayanağı, ölçüm
///   kartları, seçilen ölçümün grafiği (24 saat / 7 / 30 / 90 gün, tarama
///   bandı, eşik dışı noktalar), ölçüm geçmişi, uyarılar, uyku evreleri,
///   uyum takvimi, EKG kayıtları ve bakım özeti.
/// Yalnızca süren rızadaki türler okunur; her görüntüleme erişim kaydına
/// geçer.
extension _PanelMonitor on PanelApi {
  static String _h(String s) => PanelApi._h(s);

  static const _sorts = ['priority', 'name', 'last', 'adherence'];
  static const _perPage = [10, 25, 50];

  Response _patientsPage(Request r) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final m = PanelApi._m(r);
    final auth = _auth(r);
    if (auth == null) return _html(200, _loginPage(t));
    final (s, me) = auth;
    final now = _now();
    _engine.scan(now, ownerId: me.id);
    final board = MonitorBoard.build(store, me.id, now);
    final qp = r.url.queryParameters;
    final q = (qp['q'] ?? '').trim();
    final needle = q.toLowerCase();
    final status = switch (qp['status']) {
      final v? when v == 'need' => 'need',
      final v? when MonitorStatus.values.any((x) => x.name == v) => v,
      _ => 'all',
    };
    final sort = _sorts.contains(qp['sort']) ? qp['sort']! : 'priority';
    final per = _perPage.contains(int.tryParse(qp['n'] ?? ''))
        ? int.parse(qp['n']!)
        : 10;

    bool matchesStatus(PatientSnapshot p) => switch (status) {
      'all' => true,
      'need' =>
        p.status == MonitorStatus.critical ||
            p.status == MonitorStatus.attention,
      _ => p.status.name == status,
    };
    bool matchesQuery(PatientSnapshot p) =>
        needle.isEmpty ||
        p.displayName.toLowerCase().contains(needle) ||
        (p.record?.fileNo ?? '').toLowerCase().contains(needle) ||
        (p.patientId ?? '').toLowerCase().startsWith(needle);
    final searched = board.patients.where(matchesQuery).toList();
    final list = searched.where(matchesStatus).toList();
    switch (sort) {
      case 'name':
        list.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
      case 'last':
        list.sort((a, b) {
          final x = a.lastData, y = b.lastData;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return y.compareTo(x);
        });
      case 'adherence':
        list.sort((a, b) {
          final x = a.adherence, y = b.adherence;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return x.compareTo(y);
        });
    }
    final pages = max(1, (list.length / per).ceil());
    final page = (int.tryParse(qp['p'] ?? '') ?? 1).clamp(1, pages);

    String href({String? st, String? so, int? p, int? n, bool keepQ = true}) {
      final params = {
        if (keepQ && q.isNotEmpty) 'q': q,
        if ((st ?? status) != 'all') 'status': st ?? status,
        if ((so ?? sort) != 'priority') 'sort': so ?? sort,
        if ((n ?? per) != 10) 'n': '${n ?? per}',
        if ((p ?? 1) > 1) 'p': '${p ?? 1}',
      };
      return params.isEmpty
          ? '/panel/patients'
          : '/panel/patients?${Uri(queryParameters: params).query}';
    }

    int countOf(String st) => searched
        .where(
          (p) => switch (st) {
            'all' => true,
            'need' =>
              p.status == MonitorStatus.critical ||
                  p.status == MonitorStatus.attention,
            _ => p.status.name == st,
          },
        )
        .length;
    final seg = [
      for (final st in [
        'all',
        'need',
        ...MonitorStatus.values.map((x) => x.name),
      ])
        '${st == status ? '<span aria-current="true">' : '<a href="${_h(href(st: st))}">'}'
            '${st == 'all' || st == 'need' ? '' : '<span class="dot c-$st"></span>'}'
            '${_h(st == 'all'
                ? m['filterAll']
                : st == 'need'
                ? m['filterNeed']
                : m['st.$st'])} <span class="n">${countOf(st)}</span>'
            '${st == status ? '</span>' : '</a>'}',
    ].join();

    String th(String label, String? key, {String cls = ''}) {
      if (key == null) {
        return '<th${cls.isEmpty ? '' : ' class="$cls"'}>${_h(label)}</th>';
      }
      final on = key == sort;
      return '<th${cls.isEmpty ? '' : ' class="$cls"'}${on ? ' aria-sort="${key == 'adherence' || key == 'name' ? 'ascending' : 'descending'}"' : ''}>'
          '<a href="${_h(href(so: key))}"${on ? ' aria-sort="true"' : ''}>${_h(label)}${on ? ' ▾' : ''}</a></th>';
    }

    final rows = StringBuffer();
    for (final p in list.skip((page - 1) * per).take(per)) {
      rows.write(_listRow(t, c, m, p, now));
    }
    final perLinks = [
      for (final n in _perPage)
        n == per
            ? '<span aria-current="true">$n</span>'
            : '<a href="${_h(href(n: n))}">$n</a>',
    ].join();
    final table = list.isEmpty
        ? (board.patients.isEmpty
              ? _PanelUi.empty(
                  'patients',
                  m['noPatientsYet'],
                  '${t.noPatients} ${m['noPatientsYetBody']}',
                  action:
                      '<a class="button small" href="/panel/records/new">${_h(m['addFirst'])}</a>',
                )
              : _PanelUi.empty(
                  'search',
                  c['noMatch'],
                  m['noMatchBody'],
                  action:
                      '<a class="button small secondary" href="/panel/patients">${_h(m['clearFilters'])}</a>',
                ))
        : '''
<div class="table-wrap"><table class="cards">
<thead><tr>${th(m['colPatient'], 'name')}${th(m['colStatus'], 'priority')}${th(m['colReason'], null)}${th(m['colVitals'], null)}${th(m['colAdherence'], 'adherence')}${th(m['colLastData'], 'last')}<th class="cell-go"><span class="sr">${_h(m['open'])}</span></th></tr></thead>
<tbody>$rows</tbody></table></div>''';
    return _html(
      200,
      _page(
        t,
        me,
        s,
        m['navPatients'],
        active: '/panel/patients',
        bare: true,
        query: {...qp}..remove('lang'),
        search: q,
        '''
<div class="page-head">
<div class="titles"><div class="eyebrow">${_h(m['navPatients'])}${demoData ? ' <span class="demo-tag" title="${_h(m['demoTitle'])}">${_h(m['demoTag'])}</span>' : ''}</div>
<h1>${_h(t.myPatients)} <span class="faint" style="font-weight:600">${board.patients.length}</span></h1>
<p class="sub">${_h(m['patientsIntro'])}</p></div>
<div class="actions">${_inviteModal(t, c, m, s)}<a class="button" href="/panel/records/new">${_PanelUi.icon('plus')} ${_h(c['newPatient'])}</a></div>
</div>
<section class="panel">
<div class="toolbar">
<form method="get" action="/panel/patients" role="search">
${status == 'all' ? '' : '<input type="hidden" name="status" value="${_h(status)}">'}
${sort == 'priority' ? '' : '<input type="hidden" name="sort" value="${_h(sort)}">'}
<label class="sr" for="pq">${_h(c['search'])}</label>
<input id="pq" type="search" name="q" value="${_h(q)}" placeholder="${_h(c['searchHint'])}" maxlength="80">
<button type="submit" class="secondary">${_h(c['search'])}</button>
</form>
<nav class="seg" aria-label="${_h(m['filter'])}">$seg</nav>
</div>
$table
${list.isEmpty ? '' : '<div class="pager" style="border-top:0;padding-top:0"><span></span><span class="seg" aria-label="${_h(m['perPage'])}"><span class="n" style="padding:0 6px">${_h(m['perPage'])}</span>$perLinks</span></div>'}
${_PanelUi.pager(m, page, pages, list.length, per, (p) => _h(href(p: p)))}
</section>
<p class="faint small mt">${_h(m['statusRulesNote'])}</p>
''',
      ),
    );
  }

  String _listRow(
    PanelText t,
    ClinicText c,
    MonitorText m,
    PatientSnapshot p,
    DateTime now,
  ) {
    final String reason;
    if (p.status == MonitorStatus.inactive) {
      reason =
          '<span class="reason">${_h(switch (p.inactive) {
            InactiveReason.pendingInvite => c['statusPending'],
            InactiveReason.consentEnded => c['statusEnded'],
            _ => c['statusNone'],
          })}</span><span class="faint">${_h(m['inactive.${p.inactive?.name ?? 'notLinked'}'])}</span>';
    } else if (p.signals.isEmpty) {
      reason = '<span class="reason faint">${_h(m['noSignals'])}</span>';
    } else {
      final (title, why) = signalText(t, c, m, p.signals.first);
      final more = p.signals.length > 1
          ? ' <span class="tag" title="${_h([for (final x in p.signals.skip(1)) signalText(t, c, m, x).$1].join(' · '))}">+${p.signals.length - 1}</span>'
          : '';
      reason =
          '<span class="reason">${_h(title)}$more</span><span class="faint">${_h(why)}</span>';
    }
    String val(Vital v) {
      final x = p.vitals[v];
      if (x == null) return '';
      final (num, unit) = _PanelUi.vitalParts(t, c, m, v, x.latest, x.latest2);
      final fl = flagOf(v, x.latest, x.latest2);
      return '<span class="${const ['', 'out', 'crit'][fl]}" title="${_h('${_PanelUi.vitalLabel(t, v)} · ${PanelApi._dateTime(t, x.latestAt)}')}"><span class="dot m-${v.name}"></span> <b>${_h(num)}</b>${unit.isEmpty ? '' : '<i>${_h(unit)}</i>'}</span>';
    }

    final vitals = [
      val(Vital.heartRate),
      val(Vital.spo2),
      val(Vital.bloodPressure),
    ].where((x) => x.isNotEmpty).join();
    final rowCls = p.status == MonitorStatus.critical
        ? ' class="row-alert"'
        : p.status == MonitorStatus.attention
        ? ' class="row-attn"'
        : '';
    return '<tr$rowCls>'
        '<td>${ident(m, c, p, now)}</td>'
        '<td data-l="${_h(m['colStatus'])}">${_PanelUi.statusBadge(m, p.status)}</td>'
        '<td class="c-wide" data-l="${_h(m['colReason'])}">$reason</td>'
        '<td class="c-wide" data-l="${_h(m['colVitals'])}">${vitals.isEmpty ? '<span class="faint">—</span>' : '<div class="vals">$vitals</div>'}</td>'
        '<td data-l="${_h(m['colAdherence'])}">${_PanelUi.adherence(m, p)}</td>'
        '<td data-l="${_h(m['colLastData'])}" class="nowrap small">${p.lastData == null ? '<span class="faint">—</span>' : _PanelUi.ago(m, t, p.lastData!, now)}</td>'
        '<td class="cell-go"><a class="go" href="${_PanelUi.patientHref(p)}" aria-label="${_h(m.f('openPatient', {'name': p.displayName}))}">${_PanelUi.icon('chevron', size: 16)}</a></td>'
        '</tr>';
  }

  /// Hekimin hastalarından biri; kayıt ya da takma kimlikle.
  PatientSnapshot? _snapshotFor(
    Account me,
    DateTime now, {
    String? recordId,
    String? patientId,
  }) {
    final board = MonitorBoard.build(store, me.id, now);
    for (final p in board.patients) {
      if (recordId != null && p.record?.id == recordId) return p;
      if (patientId != null && p.patientId == patientId && p.consent != null) {
        return p;
      }
    }
    return null;
  }

  /// Hasta sayfalarının ortak başlığı ve sekmeleri: izlem, bakım ve kayıt,
  /// rapor.
  String _patientHeader(
    PanelText t,
    ClinicText c,
    MonitorText m,
    PatientSnapshot p,
    DateTime now,
    String tab,
  ) {
    final rec = p.record;
    final k = p.consent;
    final pid = p.patientId;
    final age = rec?.ageAt(now);
    String meta(String label, String value, {bool ltr = false}) =>
        '<span><b>${_h(label)}</b><span${ltr ? ' dir="ltr"' : ''}>${_h(value)}</span></span>';
    final metas = [
      if (rec?.fileNo != null) meta(c['fileNo'], rec!.fileNo!, ltr: true),
      if (age != null) meta(c['colAge'], c.f('ageYears', {'n': age})),
      if (rec?.sex != null) meta(c['sex'], _sexLabel(c, rec!.sex)),
      if (pid != null) meta(m['pseudonym'], PanelApi._shortId(pid), ltr: true),
      if (k != null) meta(m['monitoringSince'], PanelApi._date(t, k.start)),
      if (k != null) meta(t.colConsentEnd, PanelApi._date(t, k.end)),
    ].join();
    final enc = pid == null ? '' : _h(Uri.encodeComponent(pid));
    final live = pid != null && k != null;
    String tabLink(String key, String label, String? href) => href == null
        ? '<span class="off" title="${_h(m['tabOff'])}">${_h(label)}</span>'
        : key == tab
        ? '<a href="$href" aria-current="page">${_h(label)}</a>'
        : '<a href="$href">${_h(label)}</a>';
    final tabs = [
      tabLink('monitor', m['tabMonitor'], live ? '/panel/patients/$enc' : null),
      tabLink(
        'care',
        m['tabCare'],
        rec == null
            ? null
            : '/panel/records/${_h(Uri.encodeComponent(rec.id))}',
      ),
      tabLink(
        'report',
        m['tabReport'],
        live ? '/panel/patients/$enc/report' : null,
      ),
    ].join();
    final name = rec == null
        ? '<span dir="ltr">${_h(p.displayName)}</span>'
        : _h(rec.name);
    final sharing = k == null
        ? ''
        : '<p class="faint small" style="margin:8px 0 0">${_h(t.shared)}: ${_h(PanelApi._scopes(t, k.scopes))}</p>';
    final actions = live
        ? '<div class="actions noprint">'
              '${p.lastData == null ? '' : '<span class="faint small">${_h(m['lastData'])} ${_PanelUi.ago(m, t, p.lastData!, now)}</span>'}'
              '${tab == 'report' ? '' : '<a class="button" href="/panel/patients/$enc/report">${_PanelUi.icon('report', size: 16)} ${_h(c['createReport'])}</a>'}</div>'
        : rec != null && pid == null
        ? '<div class="actions noprint"><span class="faint small">${_h(m['notLinkedYet'])}</span></div>'
        : '';
    return '''
<section class="panel noprint" aria-label="${_h(m['patientHeader'])}">
<div class="phead">
${_PanelUi.avatar(p, large: true)}
<div style="min-width:0">
<h1>$name ${_PanelUi.statusBadge(m, p.status)}${rec == null ? ' <span class="tag">${_h(m['unlinkedSub'])}</span>' : ''}</h1>
<div class="meta">$metas</div>
$sharing
</div>
$actions
</div>
<nav class="tabs" aria-label="${_h(m['patientTabs'])}">$tabs</nav>
</section>''';
  }

  Response _patient(Request r, String id) {
    final t = PanelApi._t(r);
    final s = _session(r);
    final me = s == null ? null : store.account(s.accountId);
    if (s == null || me == null) return _html(401, _loginPage(t));
    final now = _now();
    final consent = _activeConsent(me.id, id);
    if (consent == null) {
      _audit(me.id, id, false, 'Panel: rıza olmadan erişim denemesi');
      return _html(
        403,
        _page(t, me, s, t.noAccess, '<p>${_h(t.noAccessBody)}</p>'),
      );
    }
    final c = PanelApi._c(r);
    final m = PanelApi._m(r);
    final qp = r.url.queryParameters;
    final days = switch (qp['days']) {
      '1' => 1,
      '30' => 30,
      '90' => 90,
      _ => 7,
    };
    _engine.scan(now, patientId: id, ownerId: me.id);
    final snap = _snapshotFor(me, now, patientId: id)!;
    final from = now.subtract(Duration(days: days));
    final wide = now.subtract(Duration(days: max(days, 30)));
    final all = store.observations(id, codes: consent.codes, from: wide);
    final items = [
      for (final o in all)
        if (!o.effective.isBefore(from)) o,
    ];
    _audit(
      me.id,
      id,
      true,
      'Panel: ${items.length} ölçüm görüntülendi ($days gün)',
    );
    final record = snap.record;
    final enc = _h(Uri.encodeComponent(id));

    // Paylaşılan ve verisi olan türler, uygulamadaki sırayla.
    final shared = [
      for (final v in Vital.values)
        if (consent.codes.contains(v.code)) v,
    ];
    final withData = [
      for (final v in shared)
        if (all.any((o) => o.code == v.code)) v,
    ];
    final focus =
        withData.where((v) => v.name == qp['m']).firstOrNull ??
        snap.signals
            .map((x) => x.vital)
            .nonNulls
            .where(withData.contains)
            .firstOrNull ??
        withData.firstOrNull;
    String link({String? metric, int? d, int? hp}) {
      final p = {
        'm': metric ?? focus?.name ?? '',
        if ((d ?? days) != 7) 'days': '${d ?? days}',
        if ((hp ?? 1) > 1) 'hp': '${hp ?? 1}',
      }..removeWhere((_, v) => v.isEmpty);
      return '/panel/patients/$enc${p.isEmpty ? '' : '?${Uri(queryParameters: p).query}'}';
    }

    final body = StringBuffer()
      ..write(_patientHeader(t, c, m, snap, now, 'monitor'))
      ..write('<div class="grid cols-main mt"><div class="stack">');

    // Durumun dayanağı.
    if (snap.signals.isNotEmpty) {
      final list = [
        for (final sg in snap.signals)
          () {
            final (title, why) = signalText(t, c, m, sg);
            final go = sg.vital != null && withData.contains(sg.vital)
                ? '<a class="button small ghost" href="${_h(link(metric: sg.vital!.name))}">${_h(m['showChart'])}</a>'
                : sg.kind == SignalKind.overdueTask && record != null
                ? '<a class="button small ghost" href="/panel/records/${_h(Uri.encodeComponent(record.id))}">${_h(m['tabCare'])}</a>'
                : '';
            return '<li class="c-${sg.level.name}"><span><span class="what">${_h(title)}</span><span class="why">${_h(why)}</span></span>$go</li>';
          }(),
      ].join();
      body.write('''
<section class="panel" aria-labelledby="why-h">
<div class="panel-head"><h2 id="why-h">${_h(m['whyTitle'])}</h2><p class="hint">${_h(m['whyHint'])}</p></div>
<ul class="signals">$list</ul>
</section>''');
    }

    // Ölçüm kartları.
    if (withData.isEmpty) {
      body.write(
        '<section class="panel">${_PanelUi.empty('data', m['noDataYet'], days == 7 ? t.noRecentData : c['noData'])}</section>',
      );
    } else {
      final cards = StringBuffer();
      for (final v in withData) {
        final x = snap.vitals[v];
        if (x == null) continue;
        final (num, unit) = _PanelUi.vitalParts(
          t,
          c,
          m,
          v,
          x.latest,
          x.latest2,
        );
        final fl = flagOf(v, x.latest, x.latest2);
        final delta = x.change;
        String deltaHtml = '';
        if (delta != null && x.lastWeek != null) {
          final rel = x.lastWeek == 0 ? 0 : delta / x.lastWeek!.abs();
          final flat = rel.abs() < .03;
          final txt = v == Vital.sleep
              ? '${delta >= 0 ? '+' : '−'}${t.duration(delta.abs().round())}'
              : v == Vital.steps || v == Vital.spo2
              ? '${delta >= 0 ? '+' : '−'}${_PanelUi.pct(m, (rel * 100).abs())}'
              : '${delta >= 0 ? '+' : '−'}${t.number(((delta.abs()) * 10).round() / 10)}';
          deltaHtml =
              '<span class="delta ${flat
                  ? 'flat'
                  : delta > 0
                  ? 'up'
                  : 'down'}" title="${_h(m.f('deltaTitle', {'a': _PanelUi.vitalValue(t, c, m, v, x.thisWeek!), 'b': _PanelUi.vitalValue(t, c, m, v, x.lastWeek!)}))}">${flat ? '≈' : _h(txt)}</span>';
        }
        cards.write(
          '<a class="vital m-${v.name}" href="${_h(link(metric: v.name))}"${v == focus ? ' aria-current="true"' : ''}>'
          '<span class="vh"><span class="dot"></span><span class="lbl">${_h(_PanelUi.vitalLabel(t, v))}</span>'
          '${fl == 0 ? '' : '<span class="status ${fl == 2 ? 'st-critical' : 'st-attention'}">${_h(m[fl == 2 ? 'flagCrit' : 'flagOut'])}</span>'}</span>'
          '<span class="vv">${_h(num)}${unit.isEmpty ? '' : '<small>${_h(unit)}</small>'}</span>'
          '<span class="vf"><span>${_PanelUi.ago(m, t, x.latestAt, now)}${deltaHtml.isEmpty ? '' : ' · $deltaHtml'}</span>${_PanelUi.spark(x.daily, label: m.f('sparkAria', {'metric': _PanelUi.vitalLabel(t, v)}))}</span>'
          '</a>',
        );
      }
      body.write('''
<section class="panel" aria-labelledby="vit-h">
<div class="panel-head"><h2 id="vit-h">${_h(m['vitalsTitle'])}</h2><p class="hint">${_h(m['vitalsHint'])}</p></div>
<div class="panel-body"><div class="vitals">$cards</div></div>
</section>''');
    }

    // Seçilen ölçümün grafiği ve geçmişi.
    if (focus != null) {
      body.write(_focusChart(t, c, m, focus, items, from, now, days, link));
      body.write(_historyTable(t, c, m, focus, items, qp, link));
    }
    body.write('</div><div class="stack">');
    body.write(_patientAlerts(t, c, s, me, id, now));
    if (consent.scopes.contains(ShareScope.sleep)) {
      body.write(_sleepNights(t, c, m, all, now, enc));
    }
    body.write(_calendar(t, m, all, now, consent.start));
    if (record != null) body.write(_careSummary(t, c, m, s, record, now));
    if (consent.scopes.contains(ShareScope.ecg)) {
      body.write(_ecgList(t, c, m, all, enc));
    }
    body.write('</div></div>');
    body.write('<p class="faint small mt">${_h(t.disclaimer)}</p>');

    return _html(
      200,
      _page(
        t,
        me,
        s,
        record?.name ?? '${t.patient} ${PanelApi._shortId(id)}',
        body.toString(),
        bare: true,
        query: {...qp}..remove('lang'),
        crumbs: [
          ('/panel/patients', m['navPatients']),
          (null, record?.name ?? PanelApi._shortId(id)),
        ],
        active: '/panel/patients',
      ),
    );
  }

  /// Ölçüm değeri (tansiyonda sistolik, diyastolik).
  static (double?, double?) _read(Vital v, StoredObservation o) {
    final res = o.resource;
    if (v == Vital.bloodPressure) {
      return (_comp(res, '8480-6'), _comp(res, '8462-4'));
    }
    return (
      ((res['valueQuantity'] as Map?)?['value'] as num?)?.toDouble(),
      null,
    );
  }

  static double? _comp(Map<String, Object?> r, String code) {
    for (final c in (r['component'] as List?)?.cast<Map>() ?? const <Map>[]) {
      final coding = ((c['code'] as Map?)?['coding'] as List?)?.firstOrNull;
      if (coding is Map && coding['code'] == code) {
        return ((c['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();
      }
    }
    return null;
  }

  String _focusChart(
    PanelText t,
    ClinicText c,
    MonitorText m,
    Vital v,
    List<StoredObservation> items,
    DateTime from,
    DateTime now,
    int days,
    String Function({String? metric, int? d, int? hp}) link,
  ) {
    final obs = [
      for (final o in items)
        if (o.code == v.code) o,
    ]..sort((a, b) => a.effective.compareTo(b.effective));
    final summed = v == Vital.steps || v == Vital.sleep;
    final daily = days > 7 || summed;
    final s1 = <(DateTime, double, double?, double?)>[];
    final s2 = <(DateTime, double, double?, double?)>[];
    final values = <double>[];
    var outCount = 0;
    if (!daily) {
      for (final o in obs) {
        final (a, b) = _read(v, o);
        if (a == null) continue;
        s1.add((o.effective, a, null, null));
        if (b != null) s2.add((o.effective, b, null, null));
        values.add(a);
        if (flagOf(v, a, b) > 0) outCount++;
      }
    } else {
      final byDay = <DateTime, List<(double, double?)>>{};
      for (final o in obs) {
        final (a, b) = _read(v, o);
        if (a == null) continue;
        final l = o.effective.toLocal();
        byDay.putIfAbsent(DateTime(l.year, l.month, l.day), () => []).add((
          a,
          b,
        ));
        values.add(a);
        if (flagOf(v, a, b) > 0) outCount++;
      }
      final keys = byDay.keys.toList()..sort();
      for (final d in keys) {
        final l = byDay[d]!;
        final at = d.add(const Duration(hours: 12));
        final xs = [for (final e in l) e.$1];
        if (summed) {
          s1.add((at, xs.reduce((a, b) => a + b), null, null));
          continue;
        }
        s1.add((
          at,
          xs.reduce((a, b) => a + b) / xs.length,
          xs.reduce(min),
          xs.reduce(max),
        ));
        final ys = [for (final e in l) ?e.$2];
        if (ys.isNotEmpty) {
          s2.add((
            at,
            ys.reduce((a, b) => a + b) / ys.length,
            ys.reduce(min),
            ys.reduce(max),
          ));
        }
      }
    }
    final l = now.toLocal();
    final start = days == 1
        ? from
        : DateTime(l.year, l.month, l.day).subtract(Duration(days: days - 1));
    final end = days == 1 ? now : DateTime(l.year, l.month, l.day + 1);
    final ticks = <DateTime>[];
    if (days == 1) {
      var tk = DateTime(
        from.toLocal().year,
        from.toLocal().month,
        from.toLocal().day,
        from.toLocal().hour - from.toLocal().hour % 3 + 3,
      );
      while (tk.isBefore(now)) {
        ticks.add(tk);
        tk = tk.add(const Duration(hours: 3));
      }
    } else {
      final stepDays = switch (days) {
        7 => 1,
        30 => 5,
        _ => 15,
      };
      for (
        var d = start;
        d.isBefore(end);
        d = d.add(Duration(days: stepDays))
      ) {
        ticks.add(daily ? d.add(const Duration(hours: 12)) : d);
      }
    }
    String fmt(double x) => switch (v) {
      Vital.temperature || Vital.weight => t.number((x * 10).round() / 10),
      Vital.sleep => t.duration(x.round()),
      Vital.spo2 => _PanelUi.pct(m, x),
      _ => t.number(x.roundToDouble()),
    };
    final label = _PanelUi.vitalLabel(t, v);
    final chart = s1.isEmpty
        ? _PanelUi.empty('data', m['noDataRange'], m['noDataRangeBody'])
        : '<div class="chart-scroll">${timeChart(
            series: [s1, if (s2.isNotEmpty) s2],
            classes: ['m-${v.name}', 'm-${v.name} second'],
            from: start,
            to: end,
            fmt: fmt,
            when: (d) => daily ? PanelApi._date(t, d) : PanelApi._dateTime(t, d),
            tick: (d) => days == 1 ? '${PanelApi._two(d.hour)}:00' : '${PanelApi._two(d.day)}.${PanelApi._two(d.month)}',
            ticks: ticks,
            label: m.f('chartAria', {'metric': label}),
            flag: (si, x) => v == Vital.bloodPressure ? (si == 0 ? flagOf(v, x, 0) : flagOf(v, 0, x)) : flagOf(v, x),
            ref: _PanelUi.refRange(v),
            refLines: v == Vital.bloodPressure ? [MonitorBoard.systolicHigh, MonitorBoard.diastolicHigh] : const [],
            bars: summed,
            gap: daily ? const Duration(days: 2) : Duration(hours: v == Vital.heartRate ? 6 : 13),
            floor: v == Vital.spo2 ? 80 : null,
          )}</div>';
    final metricSeg = [
      for (final x in Vital.values)
        if (items.any((o) => o.code == x.code) || x == v)
          x == v
              ? '<span aria-current="true"><span class="dot m-${x.name}"></span>${_h(_PanelUi.vitalLabel(t, x))}</span>'
              : '<a href="${_h(link(metric: x.name))}"><span class="dot m-${x.name}"></span>${_h(_PanelUi.vitalLabel(t, x))}</a>',
    ].join();
    final rangeSeg = [
      for (final d in const [1, 7, 30, 90])
        d == days
            ? '<span aria-current="true">${_h(m['range$d'])}</span>'
            : '<a href="${_h(link(d: d))}">${_h(m['range$d'])}</a>',
    ].join();
    final ref = _PanelUi.refRange(v);
    final legend = [
      '<li class="m-${v.name}"><span class="sw"></span>${_h(daily && !summed ? m['legendMean'] : label)}</li>',
      if (daily && !summed)
        '<li class="m-${v.name}"><span class="sw box"></span>${_h(m['legendRange'])}</li>',
      if (v == Vital.bloodPressure)
        '<li style="color:var(--pressure)"><span class="sw" style="opacity:.6"></span>${_h(m['legendDia'])}</li>',
      if (ref != null || v == Vital.bloodPressure)
        '<li><span class="sw ref"></span>${_h(m['legendRef'])}</li>',
      if (outCount > 0)
        '<li><span class="sw out"></span>${_h(m['legendOut'])}</li>',
    ].join();
    String stat(String k, String v) =>
        '<div><dt>${_h(k)}</dt><dd>${_h(v)}</dd></div>';
    final stats = values.isEmpty
        ? ''
        : '<dl class="chart-stats">'
              '${stat(m['statMin'], fmt(values.reduce(min)))}'
              '${stat(m['statMean'], fmt(values.reduce((a, b) => a + b) / values.length))}'
              '${stat(m['statMax'], fmt(values.reduce(max)))}'
              '${stat(m['statCount'], '${values.length}')}'
              '${stat(m['statOut'], '$outCount')}'
              '</dl>';
    return '''
<section class="panel" aria-labelledby="chart-h">
<div class="panel-head"><h2 id="chart-h"><span class="dot m-${v.name}"></span>${_h(label)}</h2><nav class="seg" aria-label="${_h(m['rangeLabel'])}">$rangeSeg</nav></div>
<div class="toolbar" style="padding-block:8px"><nav class="seg" aria-label="${_h(m['metricLabel'])}" style="max-width:100%;overflow-x:auto;flex-wrap:nowrap">$metricSeg</nav></div>
<div class="panel-body m-${v.name}">
$chart
<ul class="chart-legend">$legend</ul>
${v == Vital.bloodPressure ? '<p class="faint small" style="margin-bottom:0">${_h(m['bpEstimateNote'])}</p>' : ''}
</div>
$stats
</section>''';
  }

  String _historyTable(
    PanelText t,
    ClinicText c,
    MonitorText m,
    Vital v,
    List<StoredObservation> items,
    Map<String, String> qp,
    String Function({String? metric, int? d, int? hp}) link,
  ) {
    final obs = [
      for (final o in items)
        if (o.code == v.code) o,
    ]..sort((a, b) => b.effective.compareTo(a.effective));
    if (obs.isEmpty) return '';
    const per = 12;
    final pages = max(1, (obs.length / per).ceil());
    final page = (int.tryParse(qp['hp'] ?? '') ?? 1).clamp(1, pages);
    final rows = StringBuffer();
    for (final o in obs.skip((page - 1) * per).take(per)) {
      final (a, b) = _read(v, o);
      final fl = a == null ? 0 : flagOf(v, a, b);
      rows.write(
        '<tr><td class="nowrap">${_h(PanelApi._dateTime(t, o.effective))}</td>'
        '<td class="num">${a == null ? '—' : _h(_PanelUi.vitalValue(t, c, m, v, a, b))}</td>'
        '<td>${fl == 0 ? '<span class="faint small">${_h(m['inRange'])}</span>' : '<span class="status ${fl == 2 ? 'st-critical' : 'st-attention'}">${_h(m[fl == 2 ? 'flagCrit' : 'flagOut'])}</span>'}</td></tr>',
      );
    }
    return '''
<section class="panel" aria-labelledby="hist-h">
<details${qp.containsKey('hp') ? ' open' : ''}>
<summary class="panel-head" style="border-bottom:0"><h2 id="hist-h">${_h(m['historyTitle'])}</h2><span class="faint small">${_h(m.f('historyCount', {'n': obs.length}))}</span></summary>
<div class="table-wrap"><table class="compact">
<thead><tr><th>${_h(t.colTime)}</th><th class="num">${_h(t.colValue)}</th><th>${_h(m['colFlag'])}</th></tr></thead>
<tbody>$rows</tbody></table></div>
${_PanelUi.pager(m, page, pages, obs.length, per, (p) => _h(link(hp: p)))}
</details>
</section>''';
  }

  /// Bu hastanın açık uyarıları ("Gördüm" ile) ve son kapanan uyarıları.
  String _patientAlerts(
    PanelText t,
    ClinicText c,
    _Session s,
    Account me,
    String patientId,
    DateTime now,
  ) {
    final m = MonitorText.of(t.lang);
    final mine = [
      for (final a in store.alertsOf(me.id))
        if (a.patientId == patientId) a,
    ]..sort((a, b) => b.created.compareTo(a.created));
    final open = mine.where((a) => a.open).toList();
    final closed = mine.where((a) => !a.open).take(4).toList();
    final b = StringBuffer();
    for (final a in open) {
      b.write('''
<li class="c-${a.kind.severity == AlertSeverity.critical ? 'critical' : 'attention'}" style="grid-template-columns:4px 1fr">
<div><span class="what">${_h(_alertTitle(c, a.kind))}</span> ${_severityBadge(c, a, now)}<span class="why">${_h(_alertValue(t, c, a))} · ${_h(_alertWhen(t, a))}</span>
<form method="post" action="/panel/alerts/${_h(Uri.encodeComponent(a.id))}/ack" class="ack" style="margin-top:8px">
<input type="hidden" name="csrf" value="${_h(s.csrf)}">
<input type="text" name="note" maxlength="500" aria-label="${_h(c['alertNote'])}" placeholder="${_h(c['alertNote'])}">
<button type="submit">${_h(c['alertAck'])}</button>
</form></div></li>''');
    }
    for (final a in closed) {
      b.write(
        '<li class="c-inactive"><span><span class="what" style="font-weight:600">${_h(_alertTitle(c, a.kind))}</span>'
        '<span class="why">${_h(_alertValue(t, c, a))} · ${_h(PanelApi._dateTime(t, a.created))} · ${_h(a.ackAt != null ? c['alertAck'] : m['resolved'])}</span></span></li>',
      );
    }
    return '''
<section class="panel${open.isEmpty ? '' : ' alert-edge'}" aria-labelledby="alerts-p" id="alerts-p">
<div class="panel-head"><h2>${_h(m['patientAlerts'])}</h2>${open.isEmpty ? '' : '<span class="status st-critical">${open.length}</span>'}<a class="more" href="/panel/alerts">${_h(c['alertLogLink'])} ›</a></div>
${mine.isEmpty ? _PanelUi.empty('check', m['noAlerts'], m['noAlertsBody']) : '<ul class="signals">$b</ul>'}
</section>''';
  }

  /// Son 7 gecenin uyku evreleri (uygulamadaki uyku kartının renkleri).
  String _sleepNights(
    PanelText t,
    ClinicText c,
    MonitorText m,
    List<StoredObservation> all,
    DateTime now,
    String enc,
  ) {
    final nights = [
      for (final o in all)
        if (o.code == Vital.sleep.code) o,
    ]..sort((a, b) => b.effective.compareTo(a.effective));
    final last = nights.take(7).toList();
    if (last.isEmpty) {
      return '<section class="panel"><div class="panel-head"><h2>${_h(m['sleepTitle'])}</h2></div>${_PanelUi.empty('data', m['noDataYet'], m['noSleep'])}</section>';
    }
    const stages = ['sleep-deep', 'sleep-light', 'sleep-rem', 'sleep-awake'];
    const cls = ['s-deep', 's-light', 's-rem', 's-awake'];
    double total(StoredObservation o) =>
        stages.map((k) => _comp(o.resource, k) ?? 0).fold(0.0, (a, b) => a + b);
    final longest = last.map(total).fold(1.0, max);
    final rows = StringBuffer();
    for (final o in last) {
      final asleep =
          ((o.resource['valueQuantity'] as Map?)?['value'] as num?)
              ?.toDouble() ??
          0;
      final spans = StringBuffer();
      for (var i = 0; i < stages.length; i++) {
        final v = _comp(o.resource, stages[i]) ?? 0;
        if (v <= 0) continue;
        spans.write(
          '<span class="${cls[i]}" style="width:${(v / longest * 100).toStringAsFixed(1)}%" title="${_h('${m['stage.${stages[i]}']}: ${t.duration(v.round())}')}"></span>',
        );
      }
      final day = o.effective.toLocal();
      rows.write(
        '<div class="night"><span class="faint">${_h(m.lang == 'ar' ? m['wd${day.weekday}'] : m['wd${day.weekday}'].substring(0, min(3, m['wd${day.weekday}'].length)))} ${PanelApi._two(day.day)}.${PanelApi._two(day.month)}</span>'
        '<span class="bar">$spans</span><b>${_h(t.duration(asleep.round()))}</b></div>',
      );
    }
    final legend = [
      for (var i = 0; i < stages.length; i++)
        '<li><span class="sw box ${cls[i]}" style="opacity:1"></span>${_h(m['stage.${stages[i]}'])}</li>',
    ].join();
    return '''
<section class="panel" aria-labelledby="sleep-h">
<div class="panel-head"><h2 id="sleep-h"><span class="dot m-sleep"></span>${_h(m['sleepTitle'])}</h2><a class="more" href="/panel/patients/$enc?m=sleep">${_h(m['showChart'])}</a></div>
<div class="panel-body"><div class="nights">$rows</div><ul class="chart-legend" style="margin-top:12px">$legend</ul></div>
</section>''';
  }

  /// Son 30 günün takvimi: günde kaç ölçüm geldi.
  String _calendar(
    PanelText t,
    MonitorText m,
    List<StoredObservation> all,
    DateTime now,
    DateTime since,
  ) {
    final l = now.toLocal();
    final today = DateTime(l.year, l.month, l.day);
    final counts = <DateTime, int>{};
    for (final o in all) {
      final e = o.effective.toLocal();
      final d = DateTime(e.year, e.month, e.day);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final start = since.toLocal();
    final startDay = DateTime(start.year, start.month, start.day);
    var have = 0, possible = 0;
    final cells = StringBuffer();
    for (var i = 29; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final n = counts[d] ?? 0;
      final before = d.isBefore(startDay);
      if (!before) {
        possible++;
        if (n > 0) have++;
      }
      final lv = n == 0
          ? ''
          : n < 8
          ? 'l1'
          : n < 16
          ? 'l2'
          : 'l3';
      cells.write(
        '<span class="$lv${i == 0 ? ' today' : ''}" title="${_h(m.f('calTitle', {'date': PanelApi._date(t, d), 'n': n}))}"${before ? ' style="opacity:.35"' : ''}>${d.day}</span>',
      );
    }
    return '''
<section class="panel" aria-labelledby="cal-h">
<div class="panel-head"><h2 id="cal-h">${_h(m['calTitleHead'])}</h2><span class="faint small">${possible == 0 ? '' : _h(m.f('calSummary', {'n': have, 'total': possible}))}</span><p class="hint">${_h(m['calHint'])}</p></div>
<div class="panel-body"><div class="cal" role="img" aria-label="${_h(m['calTitleHead'])}">$cells</div></div>
</section>''';
  }

  /// Bakım özeti: açık görevler ve son not; tamamı "Bakım ve kayıt"ta.
  String _careSummary(
    PanelText t,
    ClinicText c,
    MonitorText m,
    _Session s,
    PatientRecord rec,
    DateTime now,
  ) {
    final entries = store.careOf(rec.id);
    final tasks = _PanelCare._sortTasks(entries.where((e) => e.open));
    final note = entries
        .where((e) => e.kind == CareKind.note)
        .fold<CareEntry?>(
          null,
          (a, e) => a == null || e.created.isAfter(a.created) ? e : a,
        );
    final href = '/panel/records/${_h(Uri.encodeComponent(rec.id))}';
    final list = [
      for (final e in tasks.take(3))
        '<li><span><span class="what" style="font-weight:650">${_h(e.text)}</span> ${_dueBadge(t, c, e, now)}</span>${_doneForm(s, c, e)}</li>',
    ].join();
    return '''
<section class="panel" aria-labelledby="care-s">
<div class="panel-head"><h2 id="care-s">${_h(c['careTitle'])}</h2><a class="more" href="$href">${_h(m['tabCare'])} ›</a></div>
${tasks.isEmpty ? '<p class="panel-body faint small" style="margin:0">${_h(c['tasksNone'])}</p>' : '<ul class="signals">${list.replaceAll('<li>', '<li class="c-watch">')}</ul>'}
${note == null ? '' : '<div class="panel-foot"><b style="color:var(--fg-2)">${_h(c['noteLabel'])}</b> · ${_h(PanelApi._date(t, note.created))}<p class="pre" style="margin:4px 0 0;color:var(--fg-2)">${_h(note.text)}</p></div>'}
</section>''';
  }

  String _ecgList(
    PanelText t,
    ClinicText c,
    MonitorText m,
    List<StoredObservation> all,
    String enc,
  ) {
    final ecgs = [
      for (final o in all)
        if (o.code == '11524-6') o,
    ]..sort((a, b) => b.effective.compareTo(a.effective));
    if (ecgs.isEmpty) return '';
    final rows = [
      for (final o in ecgs.take(5))
        '<tr><td class="nowrap">${_h(PanelApi._dateTime(t, o.effective))}</td>'
            '<td class="num">${_comp(o.resource, '8867-4') == null ? '—' : _h('${_comp(o.resource, '8867-4')!.round()} ${c['u.bpm']}')}</td>'
            '<td class="num">${_comp(o.resource, '80404-7') == null ? '—' : _h('${_comp(o.resource, '80404-7')!.round()} ${c['u.ms']}')}</td></tr>',
    ].join();
    return '''
<section class="panel" aria-labelledby="ecg-h">
<div class="panel-head"><h2 id="ecg-h">${_h(m['ecgTitle'])}</h2><a class="more" href="/panel/patients/$enc/report">${_h(m['tabReport'])} ›</a></div>
<div class="table-wrap"><table class="compact"><thead><tr><th>${_h(t.colTime)}</th><th class="num">${_h(m['ecgHr'])}</th><th class="num">HRV</th></tr></thead><tbody>$rows</tbody></table></div>
</section>''';
  }
}
