part of 'panel.dart';

/// Genel bakış (`/panel`) ve etkinlik (`/panel/activity`).
///
/// Genel bakış şu soruları sırayla yanıtlar: kaç hasta izleniyor, kaçı
/// stabil, kaçına bakılmalı; önce kime bakılmalı ve neden; son günlerde ne
/// değişti; hangi örüntüler var. Her sayı [MonitorBoard]'dan gelir ve
/// hasta listesine ya da hasta sayfasına götürür.
extension _PanelOverview on PanelApi {
  static String _h(String s) => PanelApi._h(s);

  Response _home(Request r) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final m = PanelApi._m(r);
    final auth = _auth(r);
    if (auth == null) return _html(200, _loginPage(t));
    final (s, me) = auth;
    // Eski arama adresi: hasta listesine taşındı.
    final q = r.url.queryParameters['q'];
    if (q != null) {
      return Response(
        303,
        headers: {
          'location': '/panel/patients?q=${Uri.encodeQueryComponent(q)}',
        },
      );
    }
    final now = _now();
    _engine.scan(now, ownerId: me.id);
    final board = MonitorBoard.build(store, me.id, now);
    final open = _openAlerts(me.id, now);
    final counts = board.counts;
    final monitored = board.monitored.length;
    final total = board.patients.length;
    final needNow =
        counts[MonitorStatus.critical]! + counts[MonitorStatus.attention]!;
    final critAlerts = open
        .where((a) => a.kind.severity == AlertSeverity.critical)
        .toList();
    final overdueAlerts = critAlerts.where((a) => _overdue(a, now)).length;
    final tasks = store.openTasksOf(me.id);
    final overdueTasks = tasks.where((e) => e.overdueAt(now)).length;
    final adh = board.meanAdherence;

    String kpi(
      String label,
      String value,
      String foot, {
      String cls = '',
      String? href,
      String? title,
    }) {
      final tag = href == null ? 'div' : 'a';
      return '<$tag class="kpi $cls"${href == null ? '' : ' href="$href"'}${title == null ? '' : ' title="${_h(title)}"'}>'
          '<span class="label">${_h(label)}</span><span class="value">$value</span>'
          '<span class="foot">${_h(foot)}</span></$tag>';
    }

    final kpis =
        '''
<section class="panel" aria-label="${_h(m['kpiAria'])}"><div class="kpis">
${kpi(m['kpiMonitored'], '$monitored<small>/ $total</small>', m.f('kpiMonitoredFoot', {'n': total - monitored}), href: '/panel/patients')}
${kpi(m['kpiNeed'], '$needNow', m.f('kpiNeedFoot', {'c': counts[MonitorStatus.critical]!, 'a': counts[MonitorStatus.attention]!}), cls: needNow > 0 ? 'attn' : 'stable', href: '/panel/patients?status=need')}
${kpi(m['kpiCritAlerts'], '${critAlerts.length}', overdueAlerts > 0 ? m.f('kpiOverdueFoot', {'n': overdueAlerts}) : m['kpiCritFootNone'], cls: critAlerts.isEmpty ? 'stable' : 'crit', href: '/panel/alerts')}
${kpi(m['kpiFresh'], monitored == 0 ? '—' : _h(_PanelUi.pct(m, board.fresh / monitored * 100)), m.f('kpiFreshFoot', {'n': board.fresh, 'total': monitored}), href: '/panel/patients?sort=last')}
${kpi(m['kpiAdherence'], adh == null ? '—' : _h(_PanelUi.pct(m, adh * 100)), m.f('kpiAdherenceFoot', {'days': MonitorBoard.window}), title: m['kpiAdherenceTitle'], href: '/panel/patients?sort=adherence')}
${kpi(m['kpiTasks'], '${tasks.length}', overdueTasks > 0 ? m.f('kpiTasksFoot', {'n': overdueTasks}) : m['kpiTasksFootNone'], cls: overdueTasks > 0 ? 'attn' : '')}
</div></section>''';

    final hour = now.toLocal().hour;
    final greet =
        m[hour < 12
            ? 'greetMorning'
            : hour < 18
            ? 'greetDay'
            : 'greetEvening'];
    final head =
        '''
<div class="page-head">
<div class="titles">
<div class="eyebrow">${_h(m['navOverview'])}${demoData ? ' <span class="demo-tag" title="${_h(m['demoTitle'])}">${_h(m['demoTag'])}</span>' : ''}</div>
<h1>${_h(m.f('greeting', {'greet': greet, 'name': me.name}))}</h1>
<p class="sub">${_h(m.f('overviewSub', {'date': _longDate(t, m, now), 'time': '${PanelApi._two(now.toLocal().hour)}:${PanelApi._two(now.toLocal().minute)}'}))}</p>
</div>
<div class="actions">
${_inviteModal(t, c, m, s)}
<a class="button" href="/panel/records/new">${_PanelUi.icon('plus')} ${_h(c['newPatient'])}</a>
</div>
</div>''';

    final body = StringBuffer()
      ..write(head)
      ..write(
        me.verified
            ? ''
            : '<p class="warn" role="status">${_h(c['unverified'])}</p>',
      )
      ..write(kpis)
      ..write('<div class="grid cols-main mt">')
      ..write(_priorityQueue(t, c, m, board, now))
      ..write('<div class="stack">')
      ..write(_distribution(m, board))
      ..write(_openAlertsHtml(t, c, s, me, open, now))
      ..write('</div></div>')
      ..write('<div class="grid cols-main mt">')
      ..write(_trendsPanel(t, m, board, now))
      ..write(_insightsPanel(t, c, m, board, now))
      ..write('</div>')
      ..write('<div class="grid cols-2 mt">')
      ..write(_activityPanel(t, c, m, me, now, limit: 8))
      ..write(_myTasksHtml(t, c, s, me, now))
      ..write('</div>');
    return _html(
      200,
      _page(
        t,
        me,
        s,
        m['navOverview'],
        active: '/panel',
        body.toString(),
        bare: true,
      ),
    );
  }

  /// "Cumartesi, 28 Kasım" gibi uzun tarih.
  static String _longDate(PanelText t, MonitorText m, DateTime d) {
    final l = d.toLocal();
    return m.f('longDate', {
      'wd': m['wd${l.weekday}'],
      'd': l.day,
      'mo': m['mo${l.month}'],
      'y': l.year,
    });
  }

  /// Önce bakılacak hastalar: kritik, bakılmalı, izlenecek; en çok 8.
  String _priorityQueue(
    PanelText t,
    ClinicText c,
    MonitorText m,
    MonitorBoard board,
    DateTime now,
  ) {
    final list = [
      for (final p in board.patients)
        if (p.status.index <= MonitorStatus.watch.index) p,
    ];
    final rows = StringBuffer();
    for (final p in list.take(8)) {
      rows.write(_queueRow(t, c, m, p, now));
    }
    final more = list.length > 8
        ? '<div class="panel-foot"><a href="/panel/patients?status=need">${_h(m.f('queueMore', {'n': list.length - 8}))}</a></div>'
        : '';
    return '''
<section class="panel" aria-labelledby="queue-h">
<div class="panel-head"><h2 id="queue-h">${_h(m['queueTitle'])}</h2><a class="more" href="/panel/patients">${_h(m['allPatients'])} ›</a>
<p class="hint">${_h(m['queueHint'])}</p></div>
${list.isEmpty ? _PanelUi.empty('check', m['queueEmpty'], m['queueEmptyBody']) : '''
<div class="table-wrap"><table class="cards">
<thead><tr><th>${_h(m['colPatient'])}</th><th>${_h(m['colReason'])}</th><th>${_h(m['colLatest'])}</th><th>${_h(m['colLastData'])}</th><th class="cell-go"><span class="sr">${_h(m['open'])}</span></th></tr></thead>
<tbody>$rows</tbody></table></div>$more'''}
</section>''';
  }

  String _queueRow(
    PanelText t,
    ClinicText c,
    MonitorText m,
    PatientSnapshot p,
    DateTime now,
  ) {
    final sig = p.signals.firstOrNull;
    final (title, why) = sig == null ? ('—', '') : signalText(t, c, m, sig);
    final vital =
        sig?.vital ??
        (p.vitals.containsKey(Vital.heartRate) ? Vital.heartRate : null);
    final v = vital == null ? null : p.vitals[vital];
    final latestBlock = v == null
        ? '<span class="faint">—</span>'
        : '<div><div class="vals"><span class="${const ['', 'out', 'crit'][flagOf(v.vital, v.latest, v.latest2)]}"><b>${_h(_PanelUi.vitalValue(t, c, m, v.vital, v.latest, v.latest2))}</b></span></div>'
              '<span class="faint tiny">${_h(_PanelUi.vitalLabel(t, v.vital))} · ${_PanelUi.ago(m, t, v.latestAt, now)}</span></div>';
    final sparkHtml = v == null
        ? ''
        : _PanelUi.spark(
            v.daily,
            cls: 'm-${v.vital.name}',
            label: m.f('sparkAria', {
              'metric': _PanelUi.vitalLabel(t, v.vital),
            }),
            w: 90,
          );
    final more = p.signals.length > 1
        ? ' <span class="tag" title="${_h([for (final x in p.signals.skip(1)) signalText(t, c, m, x).$1].join(' · '))}">+${p.signals.length - 1}</span>'
        : '';
    final rowCls = p.status == MonitorStatus.critical
        ? ' class="row-alert"'
        : p.status == MonitorStatus.attention
        ? ' class="row-attn"'
        : '';
    return '<tr$rowCls>'
        '<td>${ident(m, c, p, now)}<div style="margin:6px 0 0 46px">${_PanelUi.statusBadge(m, p.status)}</div></td>'
        '<td class="c-wide" data-l="${_h(m['colReason'])}" style="min-width:220px"><span class="reason">${_h(title)}$more</span><span class="faint">${_h(why)}</span></td>'
        '<td data-l="${_h(m['colLatest'])}"><div style="display:flex;align-items:center;gap:12px;justify-content:space-between">$latestBlock$sparkHtml</div></td>'
        '<td data-l="${_h(m['colLastData'])}" class="nowrap small">${p.lastData == null ? '—' : _PanelUi.ago(m, t, p.lastData!, now)}</td>'
        '<td class="cell-go"><a class="go" href="${_PanelUi.patientHref(p)}" aria-label="${_h(m.f('openPatient', {'name': p.displayName}))}">${_PanelUi.icon('chevron', size: 16)}</a></td>'
        '</tr>';
  }

  /// Durum dağılımı: tek yığılmış çubuk ve listeye götüren açıklama.
  String _distribution(MonitorText m, MonitorBoard board) {
    final counts = board.counts;
    final total = board.patients.length;
    final bar = [
      for (final st in MonitorStatus.values)
        if (counts[st]! > 0)
          '<span class="${st.name}" style="flex:${counts[st]}" title="${_h('${m['st.${st.name}']}: ${counts[st]}')}"></span>',
    ].join();
    final legend = [
      for (final st in MonitorStatus.values)
        '<li><a href="/panel/patients?status=${st.name}"><span class="dot c-${st.name}"></span>'
            '<span class="lbl">${_h(m['st.${st.name}'])}<small>${_h(m['stHint.${st.name}'])}</small></span>'
            '<b>${counts[st]}</b><span class="pct">${total == 0 ? '' : _h(_PanelUi.pct(m, counts[st]! / total * 100))}</span></a></li>',
    ].join();
    return '''
<section class="panel" aria-labelledby="dist-h">
<div class="panel-head"><h2 id="dist-h">${_h(m['distTitle'])}</h2></div>
<div class="panel-body">
${total == 0 ? _PanelUi.empty('patients', m['noPatientsYet'], m['noPatientsYetBody'], action: '<a class="button small" href="/panel/records/new">${_h(m['addFirst'])}</a>') : '<div class="dist" role="img" aria-label="${_h(m['distTitle'])}">$bar</div><ul class="legend">$legend</ul>'}
</div>
</section>''';
  }

  /// Son 14 günün kapsaması (verisi gelen hasta oranı) ve günlük uyarılar.
  String _trendsPanel(
    PanelText t,
    MonitorText m,
    MonitorBoard board,
    DateTime now,
  ) {
    if (board.monitored.isEmpty) return '';
    const n = MonitorBoard.window;
    final today = DateTime(
      now.toLocal().year,
      now.toLocal().month,
      now.toLocal().day,
    );
    final first = today.subtract(const Duration(days: n - 1));
    DateTime day(int i) => first.add(Duration(days: i));
    final cov = [
      for (var i = 0; i < n; i++)
        if (board.monitoredDaily[i] > 0)
          (
            day(i).add(const Duration(hours: 12)),
            board.coverageDaily[i] / board.monitoredDaily[i] * 100,
            null,
            null,
          ),
    ];
    String dm(DateTime d) =>
        '${PanelApi._two(d.day)}.${PanelApi._two(d.month)}';
    final ticks = [
      for (var i = 0; i < n; i += 2) day(i).add(const Duration(hours: 12)),
    ];
    final covChart = timeChart(
      series: [cov.cast<(DateTime, double, double?, double?)>()],
      classes: ['m-hrv'],
      from: first,
      to: today.add(const Duration(days: 1)),
      fmt: (v) => _PanelUi.pct(m, v),
      when: (d) => PanelApi._date(t, d),
      tick: dm,
      ticks: ticks,
      label: m['covTitle'],
      floor: 0,
      w: 440,
      h: 220,
      gap: const Duration(days: 2),
    );
    final alertPts = [
      for (var i = 0; i < n; i++)
        (day(i), board.alertsDaily[i].toDouble(), null, null),
    ];
    final alertsChart = timeChart(
      series: [alertPts.cast<(DateTime, double, double?, double?)>()],
      classes: ['m-heartRate'],
      from: first,
      to: today.add(const Duration(days: 1)),
      fmt: (v) => t.number(v),
      when: (d) => PanelApi._date(t, d),
      tick: dm,
      ticks: ticks,
      label: m['alertsTrendTitle'],
      bars: true,
      w: 440,
      h: 220,
    );
    final covToday = board.monitoredDaily.last == 0
        ? null
        : board.coverageDaily.last / board.monitoredDaily.last * 100;
    final alertsTotal = board.alertsDaily.reduce((a, b) => a + b);
    final half = n ~/ 2;
    final a1 = board.alertsDaily.take(half).reduce((a, b) => a + b);
    final a2 = board.alertsDaily.skip(half).reduce((a, b) => a + b);
    return '''
<section class="panel" aria-labelledby="trend-h">
<div class="panel-head"><h2 id="trend-h">${_h(m['trendsTitle'])}</h2><span class="faint small">${_h(m.f('lastNDays', {'n': n}))}</span></div>
<div class="grid cols-2" style="gap:0">
<div class="panel-body" style="border-inline-end:1px solid var(--line)">
<h3 style="margin-top:0">${_h(m['covTitle'])}</h3>
<p class="faint small" style="margin-top:0">${_h(m['covHint'])}</p>
$covChart
<dl class="facts-inline"><div><dt>${_h(m['today'])}</dt><dd>${covToday == null ? '—' : _h(_PanelUi.pct(m, covToday))}</dd></div><div><dt>${_h(m['covMean'])}</dt><dd>${_h(_PanelUi.pct(m, (board.meanAdherence ?? 0) * 100))}</dd></div></dl>
</div>
<div class="panel-body">
<h3 style="margin-top:0">${_h(m['alertsTrendTitle'])}</h3>
<p class="faint small" style="margin-top:0">${_h(m['alertsTrendHint'])}</p>
$alertsChart
<dl class="facts-inline"><div><dt>${_h(m.f('lastNDays', {'n': n}))}</dt><dd>$alertsTotal</dd></div><div><dt>${_h(m['prevVsLast'])}</dt><dd>$a1 → $a2</dd></div></dl>
</div>
</div>
</section>''';
  }

  /// İçgörüler: aynı türdeki sinyaller gruplanır; her grup açılınca
  /// hastaları ve dayanaklarını listeler.
  String _insightsPanel(
    PanelText t,
    ClinicText c,
    MonitorText m,
    MonitorBoard board,
    DateTime now,
  ) {
    // Uyarı sinyalleri uyarı panosunda; burada örüntüler.
    const groups = [
      (
        'worsening',
        'trend',
        [
          SignalKind.restingHrRise,
          SignalKind.activityDrop,
          SignalKind.weightChange,
        ],
        MonitorStatus.attention,
      ),
      (
        'repeated',
        'repeat',
        [
          SignalKind.highHeartRate,
          SignalKind.lowHeartRate,
          SignalKind.lowSpo2,
          SignalKind.highBloodPressure,
          SignalKind.fever,
        ],
        MonitorStatus.attention,
      ),
      ('missing', 'gap', [SignalKind.noData], MonitorStatus.attention),
      ('adherence', 'calendar', [SignalKind.lowAdherence], MonitorStatus.watch),
      ('followup', 'note', [SignalKind.overdueTask], MonitorStatus.attention),
    ];
    final items = StringBuffer();
    var shown = 0;
    for (final (key, ico, kinds, level) in groups) {
      final hits = <(PatientSnapshot, Signal)>[
        for (final p in board.monitored)
          for (final sg in p.signals)
            if (kinds.contains(sg.kind)) (p, sg),
      ];
      if (hits.isEmpty) continue;
      shown++;
      final patients = {for (final h in hits) h.$1.key}.length;
      final list = [
        for (final (p, sg) in hits.take(8))
          '<li><a href="${_PanelUi.patientHref(p)}${sg.vital == null || p.patientId == null || p.consent == null ? '' : '?m=${sg.vital!.name}'}">${_h(p.displayName)}</a>'
              '<span class="faint">${_h(signalText(t, c, m, sg).$2)}</span></li>',
      ].join();
      items.write('''
<li><details>
<summary><span class="ico c-${level.name}">${_PanelUi.icon(ico, size: 15)}</span><span class="ttl">${_h(m['ins.$key'])}<small>${_h(m['insWhy.$key'])}</small></span><span class="cnt">$patients</span></summary>
<div class="body">${_h(m['insBasis.$key'])}<ul>$list</ul></div>
</details></li>''');
    }
    return '''
<section class="panel" aria-labelledby="ins-h">
<div class="panel-head"><h2 id="ins-h">${_h(m['insightsTitle'])}</h2>
<p class="hint">${_h(m['insightsHint'])}</p></div>
${shown == 0 ? _PanelUi.empty('check', m['insightsNone'], board.monitored.isEmpty ? m['insightsNoData'] : m['insightsNoneBody']) : '<ul class="insights">$items</ul>'}
</section>''';
  }

  /// Etkinlik akışının bir olayı: simge sınıfı, simge, metin, ayrıntı.
  (String, String, String, String?) _activityLine(
    PanelText t,
    ClinicText c,
    MonitorText m,
    String ownerId,
    ActivityEvent e,
  ) {
    String who() {
      final rec = e.recordId != null
          ? store.record(e.recordId!)
          : e.patientId == null
          ? null
          : _recordFor(ownerId, e.patientId!);
      if (rec != null) {
        return '<a href="/panel/records/${_h(Uri.encodeComponent(rec.id))}">${_h(rec.name)}</a>';
      }
      final pid = e.patientId ?? '';
      return '<a href="/panel/patients/${_h(Uri.encodeComponent(pid))}" dir="ltr">${_h(PanelApi._shortId(pid))}</a>';
    }

    String fill(String key, [Map<String, Object> extra = const {}]) {
      // Ad bağlantısı HTML'dir; metnin geri kalanı kaçışlanır.
      final parts = m.f(key, {...extra}).split('{who}');
      return parts.map(_h).join(who());
    }

    return switch (e.kind) {
      ActivityKind.alertRaised => (
        e.alert!.kind.severity == AlertSeverity.critical
            ? 'critical'
            : 'attention',
        'alerts',
        fill('act.alertRaised', {'alert': c['alert_${e.alert!.kind.name}']}),
        _alertValue(t, c, e.alert!),
      ),
      ActivityKind.alertAcked => (
        'stable',
        'check',
        fill('act.alertAcked', {'alert': c['alert_${e.alert!.kind.name}']}),
        e.text,
      ),
      ActivityKind.alertResolved => (
        'stable',
        'check',
        fill('act.alertResolved', {'alert': c['alert_${e.alert!.kind.name}']}),
        null,
      ),
      ActivityKind.note => ('', 'note', fill('act.note'), e.text),
      ActivityKind.taskAdded => (
        'watch',
        'calendar',
        fill('act.taskAdded'),
        e.text,
      ),
      ActivityKind.taskDone => (
        'stable',
        'check',
        fill('act.taskDone'),
        e.text,
      ),
      ActivityKind.consentStarted => (
        'watch',
        'link',
        fill('act.consent'),
        null,
      ),
      ActivityKind.recordCreated => (
        '',
        'newPatient',
        fill('act.record'),
        null,
      ),
      ActivityKind.dataReceived => (
        '',
        'data',
        fill('act.data'),
        m.f('act.dataN', {'n': e.n ?? 0}),
      ),
    };
  }

  String _activityList(
    PanelText t,
    ClinicText c,
    MonitorText m,
    String ownerId,
    List<ActivityEvent> events,
    DateTime now, {
    bool daySeparators = false,
  }) {
    final b = StringBuffer('<ol class="timeline">');
    String? lastDay;
    for (final e in events) {
      if (daySeparators) {
        final d = PanelApi._date(t, e.time);
        if (d != lastDay) {
          b.write('<li class="day-sep" style="display:block">${_h(d)}</li>');
          lastDay = d;
        }
      }
      final (cls, ico, text, detail) = _activityLine(t, c, m, ownerId, e);
      b.write(
        '<li><span class="ti $cls">${_PanelUi.icon(ico, size: 15)}</span>'
        '<div class="tx">$text${detail == null || detail.isEmpty ? '' : '<p>${_h(detail)}</p>'}</div>'
        '${_PanelUi.ago(m, t, e.time, now)}</li>',
      );
    }
    b.write('</ol>');
    return b.toString();
  }

  String _activityPanel(
    PanelText t,
    ClinicText c,
    MonitorText m,
    Account me,
    DateTime now, {
    int limit = 8,
  }) {
    final events = activityFeed(store, me.id, now, days: 7);
    return '''
<section class="panel" aria-labelledby="act-h">
<div class="panel-head"><h2 id="act-h">${_h(m['activityTitle'])}</h2><a class="more" href="/panel/activity">${_h(m['activityAll'])} ›</a></div>
${events.isEmpty ? _PanelUi.empty('activity', m['activityNone'], m['activityNoneBody']) : _activityList(t, c, m, me.id, events.take(limit).toList(), now)}
</section>''';
  }

  /// `/panel/activity`: son 30 günün olayları, türe göre süzülür.
  Response _activityPage(Request r) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final m = PanelApi._m(r);
    final auth = _auth(r);
    if (auth == null) return _html(200, _loginPage(t));
    final (s, me) = auth;
    final now = _now();
    _engine.scan(now, ownerId: me.id);
    final q = r.url.queryParameters;
    const filters = {
      'all': <ActivityKind>{},
      'alerts': {
        ActivityKind.alertRaised,
        ActivityKind.alertAcked,
        ActivityKind.alertResolved,
      },
      'care': {
        ActivityKind.note,
        ActivityKind.taskAdded,
        ActivityKind.taskDone,
      },
      'data': {
        ActivityKind.dataReceived,
        ActivityKind.consentStarted,
        ActivityKind.recordCreated,
      },
    };
    final type = filters.containsKey(q['type']) ? q['type']! : 'all';
    final all = activityFeed(store, me.id, now, days: 30);
    final events = [
      for (final e in all)
        if (type == 'all' || filters[type]!.contains(e.kind)) e,
    ];
    const per = 30;
    final pages = max(1, (events.length / per).ceil());
    final page = (int.tryParse(q['p'] ?? '') ?? 1).clamp(1, pages);
    String href({String? ty, int? p}) =>
        '/panel/activity?${Uri(queryParameters: {if ((ty ?? type) != 'all') 'type': ty ?? type, if ((p ?? 1) > 1) 'p': '${p ?? 1}'}).query}';
    final seg = [
      for (final k in filters.keys)
        k == type
            ? '<span aria-current="true">${_h(m['actType.$k'])} <span class="n">${k == 'all' ? all.length : all.where((e) => filters[k]!.contains(e.kind)).length}</span></span>'
            : '<a href="${_h(href(ty: k))}">${_h(m['actType.$k'])} <span class="n">${k == 'all' ? all.length : all.where((e) => filters[k]!.contains(e.kind)).length}</span></a>',
    ].join();
    final slice = events.skip((page - 1) * per).take(per).toList();
    return _html(
      200,
      _page(
        t,
        me,
        s,
        m['activityTitle'],
        active: '/panel/activity',
        bare: true,
        '''
<div class="page-head"><div class="titles"><div class="eyebrow">${_h(m['navActivity'])}</div><h1>${_h(m['activityTitle'])}</h1><p class="sub">${_h(m['activityIntro'])}</p></div></div>
<section class="panel">
<div class="toolbar"><nav class="seg" aria-label="${_h(m['filter'])}">$seg</nav></div>
${slice.isEmpty ? _PanelUi.empty('activity', m['activityNone'], m['activityNoneBody']) : _activityList(t, c, m, me.id, slice, now, daySeparators: true)}
${_PanelUi.pager(m, page, pages, events.length, per, (p) => _h(href(p: p)))}
</section>''',
      ),
    );
  }

  /// Davet kodu oluşturma penceresi (betiksiz: `details`).
  String _inviteModal(PanelText t, ClinicText c, MonitorText m, _Session s) =>
      '''
<details class="modal">
<summary class="button secondary" role="button">${_PanelUi.icon('key', size: 16)} ${_h(t.createInvite)}</summary>
<div class="dialog" role="dialog" aria-labelledby="inv-h">
<h2 id="inv-h">${_h(t.createInvite)}</h2>
<p class="muted small">${_h(m['inviteIntro'])}</p>
<form method="post" action="/panel/invites">
<input type="hidden" name="csrf" value="${_h(s.csrf)}">
<label>${_h(t.purpose)}<textarea name="purpose" required maxlength="500" rows="3"></textarea></label>
<fieldset><legend>${_h(t.requestedData)}</legend>${PanelApi._scopeBoxes(t, ShareScope.values, checked: const {})}</fieldset>
<label>${_h(t.durationDays)}<input type="number" name="days" value="90" min="1" max="730" required></label>
<button type="submit">${_h(t.createCode)}</button>
</form>
</div>
</details>''';
}
