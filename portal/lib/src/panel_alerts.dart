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

  /// Ana sayfanın başındaki açık uyarılar bölümü.
  String _openAlertsHtml(
    PanelText t,
    ClinicText c,
    _Session s,
    Account me,
    List<Alert> open,
    DateTime now,
  ) {
    final rows = StringBuffer();
    for (final a in open) {
      rows.write('''
<tr class="${a.kind.severity == AlertSeverity.critical ? 'row-alert' : ''}">
<td>${_severityBadge(c, a, now)}</td>
<td>${_alertPatient(t, me.id, a.patientId)}</td>
<td><strong>${_h(_alertTitle(c, a.kind))}</strong><br><span class="small muted">${_h(_alertValue(t, c, a))}</span></td>
<td class="nowrap small">${_h(_alertWhen(t, a))}</td>
<td><form method="post" action="/panel/alerts/${_h(Uri.encodeComponent(a.id))}/ack" class="ack">
<input type="hidden" name="csrf" value="${_h(s.csrf)}">
<input type="text" name="note" maxlength="500" aria-label="${_h(c['alertNote'])}" placeholder="${_h(c['alertNote'])}">
<button type="submit">${_h(c['alertAck'])}</button>
</form></td>
</tr>''');
    }
    return '''
<section aria-labelledby="alerts-h">
<div class="row"><h2 id="alerts-h" style="flex:1">${_h(c['alertsTitle'])}</h2><a href="/panel/alerts">${_h(c['alertLogLink'])}</a></div>
${open.isEmpty ? '<p class="muted">${_h(c['alertsNone'])}</p>' : '''
<div class="table-wrap"><table>
<thead><tr><th>${_h(c['alertColLevel'])}</th><th>${_h(t.colPatient)}</th><th>${_h(c['alertColAlert'])}</th><th>${_h(c['alertColWhen'])}</th><th>${_h(c['alertColAction'])}</th></tr></thead>
<tbody>$rows</tbody>
</table></div>'''}
</section>''';
  }

  /// `/panel/alerts`: son 30 günün uyarı kaydı.
  Response _alertsPage(Request r) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final auth = _auth(r);
    if (auth == null) return _html(200, _loginPage(t));
    final (s, me) = auth;
    final now = _now();
    _engine.scan(now, ownerId: me.id);
    final since = now.subtract(const Duration(days: 30));
    final all = [
      for (final a in store.alertsOf(me.id))
        if (!a.created.isBefore(since)) a,
    ];
    final acked = all.where((a) => a.ackAt != null).toList();
    final minutes = [
      for (final a in acked) a.ackAt!.difference(a.created).inMinutes,
    ]..sort();
    final median = minutes.isEmpty ? null : minutes[minutes.length ~/ 2];
    final rows = StringBuffer();
    for (final a in all) {
      final String outcome;
      if (a.ackAt != null) {
        final who = a.ackBy == null ? null : store.account(a.ackBy!);
        outcome =
            '${_h(c.f('alertAckedBy', {'name': who?.name ?? '—', 'time': PanelApi._dateTime(t, a.ackAt!)}))}'
            '<br><span class="small muted">${_h(c.f('alertResponse', {'n': a.ackAt!.difference(a.created).inMinutes}))}</span>'
            '${a.note == null ? '' : '<br><span class="small">${_h(a.note!)}</span>'}';
      } else if (a.resolvedAt != null) {
        outcome =
            '<span class="small muted">${_h(c.f('alertResolved', {'time': PanelApi._dateTime(t, a.resolvedAt!)}))}</span>';
      } else {
        outcome = '<span class="badge alert">${_h(c['alertOpen'])}</span>';
      }
      rows.write('''
<tr>
<td class="nowrap small">${_h(PanelApi._dateTime(t, a.created))}</td>
<td>${_alertPatient(t, me.id, a.patientId)}</td>
<td>${_severityBadge(c, a, now)} ${_h(_alertTitle(c, a.kind))}<br><span class="small muted">${_h(_alertValue(t, c, a))} · ${_h(_alertWhen(t, a))}</span></td>
<td>$outcome</td>
</tr>''');
    }
    final rules = _engine.rules;
    return _html(
      200,
      _page(t, me, s, c['alertLogTitle'], active: '/panel/alerts', '''
<h1>${_h(c['alertLogTitle'])}</h1>
<div class="stats">
<div class="stat heart"><b>${all.where((a) => a.open).length}</b><span>${_h(c['statAlerts'])}</span></div>
<div class="stat accent"><b>${all.length}</b><span>${_h(c['alertStat30'])}</span></div>
<div class="stat ok"><b>${median == null ? '—' : _h(c.f('alertMinutes', {'n': median}))}</b><span>${_h(c['alertStatMedian'])}</span></div>
</div>
${all.isEmpty ? '<p class="muted">${_h(c['alertLogEmpty'])}</p>' : '''
<div class="table-wrap"><table>
<thead><tr><th>${_h(c['alertColCreated'])}</th><th>${_h(t.colPatient)}</th><th>${_h(c['alertColAlert'])}</th><th>${_h(c['alertColOutcome'])}</th></tr></thead>
<tbody>$rows</tbody>
</table></div>'''}
<p class="small muted">${_h(c.f('alertRulesNote', {'spo2': rules.spo2Below.round(), 'hrHigh': rules.heartRateAbove.round(), 'hrLow': rules.heartRateBelow.round(), 'sys': rules.systolicCrisis.round(), 'dia': rules.diastolicCrisis.round(), 'temp': rules.feverFrom.round(), 'hours': rules.noDataAfter.inHours, 'overdue': rules.overdueAfter.inMinutes}))}</p>
'''),
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
