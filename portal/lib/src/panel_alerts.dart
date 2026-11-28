part of 'panel.dart';

/// Uyarı panosu: hekimin rızalı hastalarından gelen uyarılar ([AlertEngine]).
///
/// - Ana sayfanın başında açık uyarılar: önce kritikler, sonra gecikenler,
///   sonra en yeni. Her satırda "Gördüm" ve isteğe bağlı not.
/// - `/panel/alerts`: son 30 günün uyarı kaydı; kim, ne zaman, kaç dakikada
///   yanıtladı ve notu. Kayıt silinmez (hasta verisini silerse onunla gider).
/// - Uyarılar yalnızca hekimin süren rızasındaki türlerden üretilir.
extension _PanelAlerts on PanelApi {
  static String _h(String s) => PanelApi._h(s);

  /// Hekimin açık uyarıları, sıralı.
  List<Alert> _openAlerts(String ownerId, DateTime now) {
    final open = [
      for (final a in store.alertsOf(ownerId))
        if (a.open) a,
    ];
    int rank(Alert a) => a.kind.severity == AlertSeverity.critical ? 0 : 1;
    open.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : b.created.compareTo(a.created);
    });
    return open;
  }

  bool _overdue(Alert a, DateTime now) =>
      a.open &&
      a.kind.severity == AlertSeverity.critical &&
      now.difference(a.created) >= _engine.rules.overdueAfter;

  /// Hastanın adı (hekimin kaydı varsa) ya da takma kimliğin başı; kayda
  /// ya da hasta sayfasına bağlantı.
  String _alertPatient(PanelText t, String ownerId, String patientId) {
    final rec = _recordFor(ownerId, patientId);
    return rec == null
        ? '<a href="/panel/patients/${_h(Uri.encodeComponent(patientId))}" dir="ltr">'
              '${_h(PanelApi._shortId(patientId))}</a>'
        : '<a href="/panel/records/${_h(Uri.encodeComponent(rec.id))}">'
              '${_h(rec.name)}</a>';
  }

  String _alertTitle(ClinicText c, AlertKind k) => c['alert_${k.name}'];

  String _alertValue(PanelText t, ClinicText c, Alert a) {
    String n(double? v) => v == null ? '—' : v.round().toString();
    return switch (a.kind) {
      AlertKind.spo2Low => c.f('alertValueSpo2', {'v': n(a.value)}),
      AlertKind.heartRateHigh => c.f('alertValueHrMax', {'v': n(a.value)}),
      AlertKind.heartRateLow => c.f('alertValueHrMin', {'v': n(a.value)}),
      AlertKind.bloodPressureCrisis => c.f('alertValueBp', {
        's': n(a.value),
        'd': n(a.value2),
      }),
      AlertKind.fever => c.f('alertValueTemp', {
        'v': (a.value ?? 0).toStringAsFixed(1),
      }),
      AlertKind.noData => c.f('alertValueNoData', {
        't': PanelApi._dateTime(t, a.start),
      }),
    };
  }

  /// Olayın zamanı: tek ölçümse saat, sürdüyse başlangıç–bitiş.
  String _alertWhen(PanelText t, Alert a) {
    final start = PanelApi._dateTime(t, a.start);
    if (a.kind == AlertKind.noData || !a.lastSeen.isAfter(a.start)) {
      return start;
    }
    final end = a.lastSeen.toLocal();
    return '$start – ${PanelApi._two(end.hour)}:${PanelApi._two(end.minute)}';
  }

  String _severityBadge(ClinicText c, Alert a, DateTime now) {
    final critical = a.kind.severity == AlertSeverity.critical;
    final label = critical ? c['severityCritical'] : c['severityWarning'];
    return '<span class="badge ${critical ? 'alert' : 'wait'}">${_h(label)}</span>'
        '${_overdue(a, now) ? ' <span class="badge alert strong">${_h(c['alertOverdue'])}</span>' : ''}';
  }

  /// Genel bakıştaki açık uyarılar: önce kritikler; her satırda hasta,
  /// değer, zaman ve "Gördüm" (isteğe bağlı notla).
  String _openAlertsHtml(
    PanelText t,
    ClinicText c,
    _Session s,
    Account me,
    List<Alert> open,
    DateTime now,
  ) {
    final m = MonitorText.of(t.lang);
    final rows = StringBuffer();
    for (final a in open) {
      final crit = a.kind.severity == AlertSeverity.critical;
      rows.write("""
<li class="c-${crit ? 'critical' : 'attention'}" style="grid-template-columns:4px 1fr">
<div><div class="row" style="align-items:center;gap:6px 10px"><span class="what">${_alertPatient(t, me.id, a.patientId)}</span>${_severityBadge(c, a, now)}<span class="faint tiny" style="margin-inline-start:auto">${_PanelUi.ago(m, t, a.created, now)}</span></div>
<span class="why"><b style="color:var(--fg-2)">${_h(_alertTitle(c, a.kind))}</b> · ${_h(_alertValue(t, c, a))} · ${_h(_alertWhen(t, a))}</span>
<form method="post" action="/panel/alerts/${_h(Uri.encodeComponent(a.id))}/ack" class="ack" style="margin-top:8px">
<input type="hidden" name="csrf" value="${_h(s.csrf)}">
<input type="text" name="note" maxlength="500" aria-label="${_h(c['alertNote'])}" placeholder="${_h(c['alertNote'])}">
<button type="submit">${_h(c['alertAck'])}</button>
</form></div>
</li>""");
    }
    return """
<section class="panel${open.any((a) => a.kind.severity == AlertSeverity.critical) ? ' alert-edge' : ''}" aria-labelledby="alerts-h">
<div class="panel-head"><h2 id="alerts-h">${_h(c['alertsTitle'])}${open.isEmpty ? '' : ' <span class="status st-critical">${open.length}</span>'}</h2><a class="more" href="/panel/alerts">${_h(c['alertLogLink'])} ›</a></div>
${open.isEmpty ? _PanelUi.empty('check', c['alertsNone'], m['noAlertsBody']) : '<ul class="signals">$rows</ul>'}
</section>""";
  }

  /// `/panel/alerts`: son 30 günün uyarı kaydı; duruma ve düzeye göre
  /// süzülür.
  Response _alertsPage(Request r) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final m = PanelApi._m(r);
    final auth = _auth(r);
    if (auth == null) return _html(200, _loginPage(t));
    final (s, me) = auth;
    final now = _now();
    _engine.scan(now, ownerId: me.id);
    final since = now.subtract(const Duration(days: 30));
    final all = [
      for (final a in store.alertsOf(me.id))
        if (!a.created.isBefore(since)) a,
    ]..sort((a, b) => b.created.compareTo(a.created));
    final acked = all.where((a) => a.ackAt != null).toList();
    final minutes = [
      for (final a in acked) a.ackAt!.difference(a.created).inMinutes,
    ]..sort();
    final median = minutes.isEmpty ? null : minutes[minutes.length ~/ 2];
    final q = r.url.queryParameters;
    const states = ['all', 'open', 'acked', 'resolved'];
    final state = states.contains(q['state']) ? q['state']! : 'all';
    final level = const ['critical', 'warning'].contains(q['level'])
        ? q['level']!
        : 'any';
    bool inState(Alert a, String st) => switch (st) {
      'open' => a.open,
      'acked' => a.ackAt != null,
      'resolved' => a.ackAt == null && a.resolvedAt != null,
      _ => true,
    };
    bool inLevel(Alert a, String lv) =>
        lv == 'any' || a.kind.severity.name == lv;
    final shown = [
      for (final a in all)
        if (inState(a, state) && inLevel(a, level)) a,
    ];
    String href({String? st, String? lv}) {
      final p = {
        if ((st ?? state) != 'all') 'state': st ?? state,
        if ((lv ?? level) != 'any') 'level': lv ?? level,
      };
      return p.isEmpty
          ? '/panel/alerts'
          : '/panel/alerts?${Uri(queryParameters: p).query}';
    }

    String segItem(bool on, String href, String label, int n) => on
        ? '<span aria-current="true">${_h(label)} <span class="n">$n</span></span>'
        : '<a href="${_h(href)}">${_h(label)} <span class="n">$n</span></a>';
    final stateSeg = [
      for (final st in states)
        segItem(
          st == state,
          href(st: st),
          m['alertState.$st'],
          all.where((a) => inState(a, st) && inLevel(a, level)).length,
        ),
    ].join();
    final levelSeg = [
      for (final lv in const ['any', 'critical', 'warning'])
        segItem(
          lv == level,
          href(lv: lv),
          lv == 'any'
              ? m['filterAll']
              : c[lv == 'critical' ? 'severityCritical' : 'severityWarning'],
          all.where((a) => inState(a, state) && inLevel(a, lv)).length,
        ),
    ].join();
    final rows = StringBuffer();
    for (final a in shown) {
      final String outcome;
      if (a.ackAt != null) {
        final who = a.ackBy == null ? null : store.account(a.ackBy!);
        outcome =
            '<span class="status st-stable">${_h(c['alertAck'])}</span><br><span class="small">${_h(c.f('alertAckedBy', {'name': who?.name ?? '—', 'time': PanelApi._dateTime(t, a.ackAt!)}))}</span>'
            '<br><span class="faint tiny">${_h(c.f('alertResponse', {'n': a.ackAt!.difference(a.created).inMinutes}))}</span>'
            '${a.note == null ? '' : '<br><span class="small pre">${_h(a.note!)}</span>'}';
      } else if (a.resolvedAt != null) {
        outcome =
            '<span class="status st-inactive">${_h(m['resolved'])}</span><br><span class="faint tiny">${_h(c.f('alertResolved', {'time': PanelApi._dateTime(t, a.resolvedAt!)}))}</span>';
      } else {
        outcome =
            '<form method="post" action="/panel/alerts/${_h(Uri.encodeComponent(a.id))}/ack" class="ack">'
            '<input type="hidden" name="csrf" value="${_h(s.csrf)}">'
            '<input type="text" name="note" maxlength="500" aria-label="${_h(c['alertNote'])}" placeholder="${_h(c['alertNote'])}">'
            '<button type="submit">${_h(c['alertAck'])}</button></form>';
      }
      final crit = a.kind.severity == AlertSeverity.critical;
      rows.write("""
<tr${a.open ? ' class="${crit ? 'row-alert' : 'row-attn'}"' : ''}>
<td class="nowrap small" data-l="${_h(c['alertColCreated'])}">${_h(PanelApi._dateTime(t, a.created))}<br>${_PanelUi.ago(m, t, a.created, now)}</td>
<td data-l="${_h(t.colPatient)}"><span class="what" style="font-weight:700">${_alertPatient(t, me.id, a.patientId)}</span></td>
<td class="c-wide" data-l="${_h(c['alertColAlert'])}">${_severityBadge(c, a, now)} <b>${_h(_alertTitle(c, a.kind))}</b><br><span class="small faint">${_h(_alertValue(t, c, a))} · ${_h(_alertWhen(t, a))}</span></td>
<td class="c-wide" data-l="${_h(c['alertColOutcome'])}">$outcome</td>
</tr>""");
    }
    final rules = _engine.rules;
    final openN = all.where((a) => a.open).length;
    final openCrit = all
        .where((a) => a.open && a.kind.severity == AlertSeverity.critical)
        .length;
    return _html(
      200,
      _page(
        t,
        me,
        s,
        c['alertLogTitle'],
        active: '/panel/alerts',
        bare: true,
        query: {...q}..remove('lang'),
        """
<div class="page-head"><div class="titles"><div class="eyebrow">${_h(c['navAlerts'])}</div><h1>${_h(c['alertLogTitle'])}</h1><p class="sub">${_h(m['alertsIntro'])}</p></div></div>
<section class="panel"><div class="kpis">
<div class="kpi ${openCrit > 0 ? 'crit' : 'stable'}"><span class="label">${_h(c['statAlerts'])}</span><span class="value">$openN</span><span class="foot">${_h(m.f('alertsOpenFoot', {'n': openCrit}))}</span></div>
<div class="kpi"><span class="label">${_h(c['alertStat30'])}</span><span class="value">${all.length}</span><span class="foot">${_h(m.f('alertsAckedFoot', {'n': acked.length}))}</span></div>
<div class="kpi stable"><span class="label">${_h(c['alertStatMedian'])}</span><span class="value">${median == null ? '—' : _h(c.f('alertMinutes', {'n': median}))}</span><span class="foot">${_h(m.f('alertsTarget', {'n': rules.overdueAfter.inMinutes}))}</span></div>
</div></section>
<section class="panel mt">
<div class="toolbar"><nav class="seg" aria-label="${_h(m['filter'])}">$stateSeg</nav><nav class="seg" aria-label="${_h(m['filter'])}">$levelSeg</nav></div>
${shown.isEmpty ? _PanelUi.empty('alerts', all.isEmpty ? c['alertLogEmpty'] : m['alertsNoMatch'], all.isEmpty ? m['noAlertsBody'] : m['noMatchBody']) : """
<div class="table-wrap"><table class="cards">
<thead><tr><th>${_h(c['alertColCreated'])}</th><th>${_h(t.colPatient)}</th><th>${_h(c['alertColAlert'])}</th><th>${_h(c['alertColOutcome'])}</th></tr></thead>
<tbody>$rows</tbody>
</table></div>"""}
</section>
<p class="small faint mt">${_h(c.f('alertRulesNote', {'spo2': rules.spo2Below.round(), 'hrHigh': rules.heartRateAbove.round(), 'hrLow': rules.heartRateBelow.round(), 'sys': rules.systolicCrisis.round(), 'dia': rules.diastolicCrisis.round(), 'temp': rules.feverFrom.round(), 'hours': rules.noDataAfter.inHours, 'overdue': rules.overdueAfter.inMinutes}))}</p>
""",
      ),
    );
  }

  /// "Gördüm": uyarıyı kapatır, not ve zaman kayda geçer.
  Future<Response> _ackAlert(Request r, String id) async {
    final t = PanelApi._t(r);
    final auth = _auth(r);
    if (auth == null) return _html(401, _loginPage(t));
    final (s, me) = auth;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${_h(t.formExpired)}</p>'),
      );
    }
    final a = _engine.acknowledge(id, me.id, form['note']?.firstOrNull, _now());
    if (a == null) {
      return _html(
        404,
        _page(
          t,
          me,
          s,
          t.error,
          '<p>${_h(PanelApi._c(r)['alertNotFound'])}</p>'
          '<p><a href="/panel">${_h(t.back)}</a></p>',
        ),
      );
    }
    final back = r.headers['referer']?.contains('/panel/alerts') ?? false
        ? '/panel/alerts'
        : '/panel';
    return Response(303, headers: {'location': back});
  }
}
