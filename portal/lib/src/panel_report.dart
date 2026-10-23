part of 'panel.dart';

/// Rapor sayfasındaki "Yazdır / PDF" düğmesinin betiği. CSP yalnızca bu
/// betiğin özetine izin verir; başka hiçbir betik çalışmaz.
const _printScript =
    "document.getElementById('print').addEventListener('click',"
    "function(){window.print()})";

final String _printScriptHash =
    "sha256-${base64.encode(crypto.sha256.convert(utf8.encode(_printScript)).bytes)}";

/// Hekim raporu: tarih aralığıyla rızadaki tüm türlerin özeti, günlük
/// değerler, grafikler ve eşiğe dayalı bulgular; yazdırılabilir (tarayıcının
/// "PDF olarak kaydet"i), CSV ve FHIR olarak indirilebilir.
///
/// Her rapor ve dışa aktarma erişim kaydına geçer. Yalnızca süren rızadaki
/// türler okunur.
extension _PanelReport on PanelApi {
  /// En uzun rapor dönemi.
  static const maxDays = 731;

  /// `from` ve `to` (yyyy-aa-gg, yerel gün); verilmezse son 30 gün.
  (DateTime, DateTime)? _range(Request r) {
    final q = r.url.queryParameters;
    final today = _now().toLocal();
    DateTime? day(String? v) {
      final d = _PanelRecords._parseDay(v);
      return d == null ? null : DateTime(d.year, d.month, d.day);
    }

    final toDay = q['to'] == null
        ? DateTime(today.year, today.month, today.day)
        : day(q['to']);
    final fromDay = q['from'] == null
        ? toDay?.subtract(const Duration(days: 29))
        : day(q['from']);
    if (fromDay == null || toDay == null || fromDay.isAfter(toDay)) return null;
    if (toDay.difference(fromDay).inDays >= maxDays) return null;
    final end = DateTime(toDay.year, toDay.month, toDay.day, 23, 59, 59, 999);
    return (fromDay, end);
  }

  /// Oturum, hesap ve süren rıza; yoksa hata yanıtı.
  Object _reportAccess(Request r, String id) {
    final t = PanelApi._t(r);
    final auth = _auth(r);
    if (auth == null) return _html(401, _loginPage(t));
    final (s, me) = auth;
    final consent = _activeConsent(me.id, id);
    if (consent == null) {
      _audit(me.id, id, false, 'Panel: rıza olmadan rapor denemesi');
      return _html(
        403,
        _page(t, me, s, t.noAccess, '<p>${PanelApi._h(t.noAccessBody)}</p>'),
      );
    }
    return (s, me, consent);
  }

  Response _report(Request r, String id) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final access = _reportAccess(r, id);
    if (access is Response) return access;
    final (s, me, consent) = access as (_Session, Account, Consent);
    final esc = PanelApi._h;
    final range = _range(r);
    if (range == null) {
      return _html(
        400,
        _page(
          t,
          me,
          s,
          c['errRange'],
          '<p class="error">${esc(c['errRange'])}</p><p><a href="/panel/patients/${esc(Uri.encodeComponent(id))}/report">${esc(c['createReport'])}</a></p>',
        ),
      );
    }
    final (from, to) = range;
    final requested = {
      for (final v in r.url.queryParametersAll['s'] ?? const <String>[])
        ?ShareScope.byName(v),
    };
    final sections = requested.isEmpty
        ? consent.scopes
        : requested.intersection(consent.scopes);
    final codes = {for (final sc in sections) ...sc.codes};
    final items = store.observations(id, codes: codes, from: from, to: to);
    final record = _recordFor(me.id, id);
    final now = _now();
    final report = PatientReport.build(
      items,
      from: from,
      to: to,
      age: record?.ageAt(now),
    );
    _audit(
      me.id,
      id,
      true,
      'Panel: rapor oluşturuldu ${_PanelRecords._ymd(from)}–${_PanelRecords._ymd(to)} (${items.length} ölçüm)',
    );

    final query = [
      'from=${_PanelRecords._ymd(from)}',
      'to=${_PanelRecords._ymd(to)}',
      for (final sc in sections) 's=${sc.name}',
    ].join('&');
    final base = '/panel/patients/${esc(Uri.encodeComponent(id))}';
    final html = StringBuffer()
      ..write('''
<p class="noprint"><a href="${record == null ? base : '/panel/records/${esc(Uri.encodeComponent(record.id))}'}">${t.rtl ? '→' : '←'} ${esc(record?.name ?? '${t.patient} ${PanelApi._shortId(id)}')}</a></p>
<form method="get" action="$base/report" class="card noprint">
<div class="row">
<label>${esc(c['fromDate'])}<input type="date" name="from" value="${_PanelRecords._ymd(from)}" dir="ltr"></label>
<label>${esc(c['toDate'])}<input type="date" name="to" value="${_PanelRecords._ymd(to)}" dir="ltr"></label>
</div>
<fieldset><legend>${esc(c['sections'])}</legend>${PanelApi._scopeBoxes(t, ShareScope.values.where(consent.scopes.contains), checked: sections).replaceAll('name="scope"', 'name="s"')}</fieldset>
<div class="row">
<button type="submit">${esc(c['apply'])}</button>
<span class="small">${[
        for (final d in const [7, 30, 90]) '<a href="$base/report?from=${_PanelRecords._ymd(to.subtract(Duration(days: d - 1)))}&amp;to=${_PanelRecords._ymd(to)}">${esc(c['last$d'])}</a>',
      ].join(' · ')}</span>
<span style="flex:1"></span>
<button type="button" id="print">${esc(c['print'])}</button>
<a class="button secondary" href="$base/report.csv?${esc(query)}" download>${esc(c['downloadCsv'])}</a>
<a class="button secondary" href="$base/report.json?${esc(query)}" download>${esc(c['downloadFhir'])}</a>
</div>
<p class="muted small">${esc(c['printHint'])}</p>
</form>
<article class="report">
''')
      ..write(_reportHeader(t, c, me, id, record, consent, report, sections))
      ..write(_reportBody(t, c, report, sections))
      ..write('''
<section class="card avoid">
<h2>${esc(c['thresholds'])}</h2>
<p class="small">${esc(c['thresholdsBody'])}</p>
<p class="small muted">${esc(c['reportFooter'])}</p>
<div class="sign"><span>${esc(c['signature'])}</span></div>
</section>
</article>
<script>$_printScript</script>
''');
    return _html(
      200,
      _page(
        t,
        me,
        s,
        '${c['reportTitle']} · ${record?.name ?? PanelApi._shortId(id)}',
        html.toString(),
      ),
      printScript: true,
    );
  }

  String _reportHeader(
    PanelText t,
    ClinicText c,
    Account me,
    String id,
    PatientRecord? record,
    Consent consent,
    PatientReport report,
    Set<ShareScope> sections,
  ) {
    final esc = PanelApi._h;
    final now = _now();
    final age = record?.ageAt(now);
    String fact(String key, String? value, {bool ltr = false}) =>
        value == null || value.isEmpty
        ? ''
        : '<dt>${esc(c[key])}</dt><dd dir="${ltr ? 'ltr' : 'auto'}">${esc(value)}</dd>';
    final doctor = [me.name, ?me.specialty, ?me.organization].join(' · ');
    return '''
<div class="report-head card">
<h1>${esc(c['reportTitle'])}</h1>
<div class="grid2">
<dl class="facts">
${fact('reportPatient', record?.name ?? '${t.patient} ${PanelApi._shortId(id)}')}
${record == null ? '' : fact('birthDate', record.birthDate == null ? null : '${PanelApi._date(t, record.birthDate!)}${age == null ? '' : ' (${c.f('ageYears', {'n': age})})'}')}
${record == null ? '' : fact('sex', record.sex == null ? null : _sexLabel(c, record.sex))}
${record == null ? '' : fact('fileNo', record.fileNo, ltr: true)}
${fact('linkedTo', PanelApi._shortId(id), ltr: true)}
</dl>
<dl class="facts">
${fact('period', '${PanelApi._date(t, report.from)} – ${PanelApi._date(t, report.to)} (${report.periodDays} ${t.days})')}
${fact('generated', PanelApi._dateTime(t, now))}
${fact('preparedBy', doctor)}
${fact('sharedScopes', PanelApi._scopes(t, sections))}
${fact('source', c['sourceValue'])}
</dl>
</div>
</div>
''';
  }

  String _label(PanelText t, ReportMetric m) => t.codeLabels[m.code] ?? m.code;

  String _unit(ClinicText c, String key) => c['u.$key'];

  /// Değeri birimine uygun hassasiyetle yazar.
  String _fmt(PanelText t, ReportMetric m, double v) {
    final whole = const {
      'bpm',
      'steps',
      'kcal',
      'mmHg',
      'min',
    }.contains(m.unit);
    return whole
        ? t.number(v.roundToDouble())
        : t.number((v * 10).round() / 10);
  }

  String _withUnit(PanelText t, ClinicText c, ReportMetric m, double v) {
    if (m == ReportMetric.sleep) return t.duration(v.round());
    final u = _unit(c, m.unit);
    return m.unit == 'pct' ? '${_fmt(t, m, v)} %' : '${_fmt(t, m, v)} $u';
  }

  String _signed(PanelText t, ReportMetric m, double v) {
    if (v.abs() < 0.05) return '0';
    final sign = v > 0 ? '+' : '−';
    if (m == ReportMetric.sleep) return '$sign${t.duration(v.abs().round())}';
    return '$sign${_fmt(t, m, v.abs())}';
  }

  String _summaryRow(
    PanelText t,
    ClinicText c,
    ReportMetric m,
    SeriesStats st, {
    String? label,
  }) {
    final esc = PanelApi._h;
    final kindNote = m.kind == MetricKind.total
        ? ' <span class="muted small">(${esc(c['dailyTotal'])})</span>'
        : '';
    return '<tr><th scope="row">${esc(label ?? _label(t, m))}$kindNote</th>'
        '<td class="num">${st.count}</td>'
        '<td class="num">${esc(_withUnit(t, c, m, st.min))}</td>'
        '<td class="num">${esc(_withUnit(t, c, m, st.max))}</td>'
        '<td class="num">${esc(_withUnit(t, c, m, st.mean))}</td>'
        '<td class="num">${esc(_withUnit(t, c, m, st.latest))}</td>'
        '<td class="num">${st.change == null ? '—' : esc(_signed(t, m, st.change!))}</td></tr>';
  }

  String _reportBody(
    PanelText t,
    ClinicText c,
    PatientReport report,
    Set<ShareScope> sections,
  ) {
    final esc = PanelApi._h;
    if (report.isEmpty) {
      return '<section class="card"><p class="muted">${esc(c['noData'])}</p></section>';
    }
    final out = StringBuffer();

    // Özet tablosu.
    final rows = StringBuffer();
    for (final m in ReportMetric.values) {
      if (!sections.contains(m.scope)) continue;
      switch (m) {
        case ReportMetric.bloodPressure:
          if (report.bp case final bp?) {
            rows
              ..write(
                _summaryRow(
                  t,
                  c,
                  m,
                  bp.systolic,
                  label: '${_label(t, m)} · ${c['systolic']}',
                ),
              )
              ..write(
                _summaryRow(
                  t,
                  c,
                  m,
                  bp.diastolic,
                  label: '${_label(t, m)} · ${c['diastolic']}',
                ),
              );
          }
        case ReportMetric.sleep:
          if (report.sleep case final sl?) {
            rows.write(_summaryRow(t, c, m, sl.duration));
          }
        case ReportMetric.workouts:
          if (report.workouts.isNotEmpty) {
            rows.write(
              '<tr><th scope="row">${esc(_label(t, m))}</th><td class="num">${report.workouts.length}</td><td colspan="5"></td></tr>',
            );
          }
        case ReportMetric.ecg:
          if (report.ecgs.isNotEmpty) {
            rows.write(
              '<tr><th scope="row">${esc(_label(t, m))}</th><td class="num">${report.ecgs.length}</td><td colspan="5"></td></tr>',
            );
          }
        default:
          if (report.series[m] case final st?) {
            rows.write(_summaryRow(t, c, m, st));
          }
      }
    }
    out.write('''
<section class="card">
<h2>${esc(c['summary'])}</h2>
<p class="muted small">${esc(c.f('completeness', {'n': report.daysWithData, 'total': report.periodDays}))} · ${esc(c.f('recordsInPeriod', {'n': report.observationCount}))}</p>
<div class="table-wrap"><table>
<thead><tr><th>${esc(c['colMetric'])}</th><th class="num">${esc(c['colCount'])}</th><th class="num">${esc(c['colMin'])}</th><th class="num">${esc(c['colMax'])}</th><th class="num">${esc(c['colMean'])}</th><th class="num">${esc(c['colLatest'])}</th><th class="num">${esc(c['colChange'])}</th></tr></thead>
<tbody>$rows</tbody>
</table></div>
</section>
''');

    // Bulgular.
    out.write('<section class="card avoid"><h2>${esc(c['findings'])}</h2>');
    if (report.findings.isEmpty) {
      out.write('<p>${esc(c['noFindings'])}</p>');
    } else {
      out.write('<ul class="findings">');
      for (final f in report.findings) {
        final v = switch (f.kind) {
          FindingKind.lowActivity => t.number(f.value!.roundToDouble()),
          FindingKind.weightChange => _signed(t, ReportMetric.weight, f.value!),
          _ => f.value == null ? '' : t.number((f.value! * 10).round() / 10),
        };
        out.write(
          '<li>${esc(c.f('f.${f.kind.name}', {'n': f.n ?? 0, 'total': f.total ?? 0, 'pct': f.percent, 'v': v}))}</li>',
        );
      }
      out.write('</ul>');
    }
    out.write('<p class="muted small">${esc(c['findingsNote'])}</p></section>');

    // Türlere göre bölümler.
    if (sections.contains(ShareScope.heartRate)) {
      final extra = StringBuffer();
      if (report.restingHeartRate case final rhr?) {
        extra.write(
          '<dt>${esc(c['restingHr'])}</dt><dd>${esc('$rhr ${c['u.bpm']}')}</dd>',
        );
      }
      extra.write(
        report.vo2max == null
            ? '<dt>${esc(c['vo2max'])}</dt><dd class="muted">${esc(report.restingHeartRate == null ? '—' : c['vo2NeedsAge'])}</dd>'
            : '<dt>${esc(c['vo2max'])}</dt><dd>${esc(t.number(report.vo2max!))} ml/kg/min <span class="muted small">${esc(c['vo2Note'])}</span></dd>',
      );
      out.write(
        _metricSection(
          t,
          c,
          report,
          ReportMetric.heartRate,
          extra: '<dl class="facts">$extra</dl>',
        ),
      );
      out.write(_metricSection(t, c, report, ReportMetric.hrv));
    }
    for (final (scope, metric) in const [
      (ShareScope.spo2, ReportMetric.spo2),
      (ShareScope.respiration, ReportMetric.respiration),
      (ShareScope.temperature, ReportMetric.temperature),
      (ShareScope.stress, ReportMetric.stress),
    ]) {
      if (sections.contains(scope)) {
        out.write(_metricSection(t, c, report, metric));
      }
    }
    if (sections.contains(ShareScope.bloodPressure)) {
      out.write(_bpSection(t, c, report));
    }
    if (sections.contains(ShareScope.sleep)) {
      out.write(_sleepSection(t, c, report));
    }
    if (sections.contains(ShareScope.activity)) {
      for (final m in const [
        ReportMetric.steps,
        ReportMetric.distance,
        ReportMetric.calories,
      ]) {
        out.write(_metricSection(t, c, report, m, bars: true));
      }
      out.write(_workoutSection(t, c, report));
    }
    if (sections.contains(ShareScope.ecg)) out.write(_ecgSection(t, c, report));
    if (sections.contains(ShareScope.body)) {
      final bmi = report.series[ReportMetric.bmi];
      final extra = bmi == null
          ? ''
          : '<dl class="facts"><dt>${esc(c['bmiClass'])}</dt><dd>${esc(c['bmi.${_bmiClass(bmi.latest)}'])} (${esc(t.number((bmi.latest * 10).round() / 10))} ${esc(c['u.kgm2'])})</dd></dl>';
      out.write(
        _metricSection(t, c, report, ReportMetric.weight, extra: extra),
      );
      for (final m in const [
        ReportMetric.bmi,
        ReportMetric.bodyFat,
        ReportMetric.muscleMass,
      ]) {
        out.write(_metricSection(t, c, report, m, table: false));
      }
    }
    return out.toString();
  }

  static String _bmiClass(double v) => v < 18.5
      ? 'under'
      : v < 25
      ? 'normal'
      : v < 30
      ? 'over'
      : 'obese';

  /// Tek bir türün bölümü: özet, günlük grafik ve günlük tablo.
  String _metricSection(
    PanelText t,
    ClinicText c,
    PatientReport report,
    ReportMetric m, {
    String extra = '',
    bool bars = false,
    bool table = true,
  }) {
    final esc = PanelApi._h;
    final st = report.series[m];
    if (st == null) {
      return extra.isEmpty
          ? ''
          : '<section class="card avoid"><h2>${esc(_label(t, m))}</h2>$extra</section>';
    }
    final total = m.kind == MetricKind.total;
    final rows = StringBuffer();
    for (final d in st.days.reversed) {
      rows.write(
        total
            ? '<tr><td>${esc(PanelApi._date(t, d.day))}</td><td class="num">${esc(_withUnit(t, c, m, d.total))}</td></tr>'
            : '<tr><td>${esc(PanelApi._date(t, d.day))}</td><td class="num">${esc(_withUnit(t, c, m, d.min))}</td><td class="num">${esc(_withUnit(t, c, m, d.mean))}</td><td class="num">${esc(_withUnit(t, c, m, d.max))}</td><td class="num">${d.count}</td></tr>',
      );
    }
    final head = total
        ? '<tr><th>${esc(c['colDate'])}</th><th class="num">${esc(c['dailyTotal'])}</th></tr>'
        : '<tr><th>${esc(c['colDate'])}</th><th class="num">${esc(c['colMin'])}</th><th class="num">${esc(c['colMean'])}</th><th class="num">${esc(c['colMax'])}</th><th class="num">${esc(c['colCount'])}</th></tr>';
    return '''
<section class="card">
<h2>${esc(_label(t, m))}</h2>
<p class="big">${esc(_withUnit(t, c, m, st.mean))} <span class="muted small">${esc(total ? c['dailyMean'] : c['colMean'])}</span></p>
<p class="muted small">${esc(c['colMin'])} ${esc(_withUnit(t, c, m, st.min))} · ${esc(c['colMax'])} ${esc(_withUnit(t, c, m, st.max))} · ${esc(c['colLatest'])} ${esc(_withUnit(t, c, m, st.latest))} (${esc(PanelApi._dateTime(t, st.latestAt))})</p>
$extra
${_chart(t, c, report, st.days, m, bars: bars)}
${table ? '<details class="daily"><summary>${esc(c['daily'])}</summary><div class="table-wrap"><table class="compact"><thead>$head</thead><tbody>$rows</tbody></table></div></details>' : ''}
</section>''';
  }

  String _bpSection(PanelText t, ClinicText c, PatientReport report) {
    final bp = report.bp;
    if (bp == null) return '';
    final esc = PanelApi._h;
    const m = ReportMetric.bloodPressure;
    final cats = StringBuffer();
    final n = bp.systolic.count;
    for (final cat in BpCategory.values) {
      final k = bp.categories[cat] ?? 0;
      cats.write(
        '<tr><td>${esc(c['bp.${cat.name}'])}</td><td class="num">$k</td><td class="num">${n == 0 ? 0 : (k * 100 / n).round()} %</td></tr>',
      );
    }
    final dia = {for (final d in bp.diastolic.days) d.day: d};
    final rows = StringBuffer();
    for (final d in bp.systolic.days.reversed) {
      final dd = dia[d.day];
      rows.write(
        '<tr><td>${esc(PanelApi._date(t, d.day))}</td>'
        '<td class="num">${esc(_fmt(t, m, d.mean))}/${dd == null ? '—' : esc(_fmt(t, m, dd.mean))}</td>'
        '<td class="num">${esc(_fmt(t, m, d.max))}/${dd == null ? '—' : esc(_fmt(t, m, dd.max))}</td>'
        '<td class="num">${d.count}</td></tr>',
      );
    }
    return '''
<section class="card">
<h2>${esc(_label(t, m))}</h2>
<p class="big">${esc(_fmt(t, m, bp.systolic.mean))}/${esc(_fmt(t, m, bp.diastolic.mean))} mmHg <span class="muted small">${esc(c['colMean'])}</span></p>
<p class="muted small">${esc(c['colLatest'])} ${esc(_fmt(t, m, bp.systolic.latest))}/${esc(_fmt(t, m, bp.diastolic.latest))} mmHg (${esc(PanelApi._dateTime(t, bp.systolic.latestAt))})</p>
${_chart(t, c, report, bp.systolic.days, m, second: bp.diastolic.days)}
<h3>${esc(c['bpCategories'])}</h3>
<table class="compact"><tbody>$cats</tbody></table>
<details class="daily"><summary>${esc(c['daily'])}</summary><div class="table-wrap"><table class="compact">
<thead><tr><th>${esc(c['colDate'])}</th><th class="num">${esc(c['colMean'])}</th><th class="num">${esc(c['colMax'])}</th><th class="num">${esc(c['colCount'])}</th></tr></thead>
<tbody>$rows</tbody></table></div></details>
</section>''';
  }

  String _sleepSection(PanelText t, ClinicText c, PatientReport report) {
    final sl = report.sleep;
    if (sl == null) return '';
    final esc = PanelApi._h;
    const m = ReportMetric.sleep;
    final stages = [
      for (final s in PatientReport.sleepStages)
        if (sl.stageMeans[s] case final v?)
          '<dt>${esc(c['sleep.$s'])}</dt><dd>${esc(t.duration(v.round()))}</dd>',
    ].join();
    final rows = StringBuffer();
    for (final n in sl.nights.reversed) {
      String stage(String s) =>
          n.stages[s] == null ? '—' : esc(t.duration(n.stages[s]!.round()));
      rows.write(
        '<tr><td>${esc(PanelApi._date(t, n.start))}</td><td class="num">${esc(t.duration(n.asleep.round()))}</td>'
        '${[for (final s in PatientReport.sleepStages) '<td class="num">${stage(s)}</td>'].join()}</tr>',
      );
    }
    return '''
<section class="card">
<h2>${esc(_label(t, m))}</h2>
<p class="big">${esc(t.duration(sl.duration.mean.round()))} <span class="muted small">${esc(c['colMean'])}</span></p>
<p class="muted small">${esc(c['colMin'])} ${esc(t.duration(sl.duration.min.round()))} · ${esc(c['colMax'])} ${esc(t.duration(sl.duration.max.round()))} · ${sl.nights.length} ${esc(c['nights'])}</p>
${stages.isEmpty ? '' : '<h3>${esc(c['sleepStages'])}</h3><dl class="facts">$stages</dl>'}
${_chart(t, c, report, sl.duration.days, m, bars: true)}
<details class="daily"><summary>${esc(c['daily'])}</summary><div class="table-wrap"><table class="compact">
<thead><tr><th>${esc(c['nights'])}</th><th class="num">${esc(c['sleepTotal'])}</th>${[for (final s in PatientReport.sleepStages) '<th class="num">${esc(c['sleep.$s'])}</th>'].join()}</tr></thead>
<tbody>$rows</tbody></table></div></details>
</section>''';
  }

  String _workoutSection(PanelText t, ClinicText c, PatientReport report) {
    if (report.workouts.isEmpty) return '';
    final esc = PanelApi._h;
    String num(double? v, ReportMetric m) =>
        v == null || v == 0 ? '—' : esc(_withUnit(t, c, m, v));
    final rows = StringBuffer();
    for (final w in report.workouts.reversed) {
      rows.write(
        '<tr><td>${esc(PanelApi._dateTime(t, w.start))}</td>'
        '<td>${esc(w.type ?? c['workoutType.unknown'])}</td>'
        '<td class="num">${w.minutes == null ? '—' : esc(t.duration(w.minutes!.round()))}</td>'
        '<td class="num">${num(w.averageHeartRate, ReportMetric.heartRate)}</td>'
        '<td class="num">${num(w.steps, ReportMetric.steps)}</td>'
        '<td class="num">${num(w.distanceKm, ReportMetric.distance)}</td>'
        '<td class="num">${num(w.calories, ReportMetric.calories)}</td></tr>',
      );
    }
    return '''
<section class="card">
<h2>${esc(c['workoutsTitle'])} (${report.workouts.length})</h2>
<div class="table-wrap"><table class="compact">
<thead><tr><th>${esc(t.colTime)}</th><th>${esc(c['colType'])}</th><th class="num">${esc(c['colDuration'])}</th><th class="num">${esc(c['colAvgHr'])}</th><th class="num">${esc(c['colSteps'])}</th><th class="num">${esc(c['colDistance'])}</th><th class="num">${esc(c['colCalories'])}</th></tr></thead>
<tbody>$rows</tbody></table></div>
</section>''';
  }

  String _ecgSection(PanelText t, ClinicText c, PatientReport report) {
    if (report.ecgs.isEmpty) return '';
    final esc = PanelApi._h;
    final rows = StringBuffer();
    for (final e in report.ecgs.reversed) {
      rows.write(
        '<tr><td>${esc(PanelApi._dateTime(t, e.start))}</td>'
        '<td class="num">${e.seconds == null ? '—' : esc('${t.number(e.seconds!.roundToDouble())} ${c['u.s']}')}</td>'
        '<td class="num">${e.averageHeartRate == null ? '—' : esc(_withUnit(t, c, ReportMetric.heartRate, e.averageHeartRate!))}</td>'
        '<td class="num">${e.sdnn == null ? '—' : esc(_withUnit(t, c, ReportMetric.hrv, e.sdnn!))}</td></tr>',
      );
    }
    return '''
<section class="card">
<h2>${esc(c['ecgTitle'])} (${report.ecgs.length})</h2>
<div class="table-wrap"><table class="compact">
<thead><tr><th>${esc(t.colTime)}</th><th class="num">${esc(c['colDuration'])}</th><th class="num">${esc(c['colAvgHr'])}</th><th class="num">${esc(c['colSdnn'])}</th></tr></thead>
<tbody>$rows</tbody></table></div>
<p class="muted small">${esc(c['ecgNote'])}</p>
</section>''';
  }

  /// Günlük değerlerin satır içi SVG grafiği. Ortalama türlerde çizgi ve en
  /// düşük–en yüksek bandı, toplanan türlerde ve uykuda sütun; [second]
  /// verilirse (diastolik) ikinci çizgi. Zaman her dilde soldan sağa akar.
  String _chart(
    PanelText t,
    ClinicText c,
    PatientReport report,
    List<DayValue> days,
    ReportMetric m, {
    bool bars = false,
    List<DayValue>? second,
  }) {
    if (days.isEmpty) return '';
    const w = 640.0,
        h = 170.0,
        left = 52.0,
        right = 8.0,
        top = 10.0,
        bottom = 24.0;
    final start = DateTime(
      report.from.year,
      report.from.month,
      report.from.day,
    );
    final span = max(1, report.periodDays - 1);
    final total = m.kind == MetricKind.total || bars;
    double val(DayValue d) => m.kind == MetricKind.total ? d.total : d.mean;
    final all = <double>[
      for (final d in days) ...(total ? [val(d)] : [d.min, d.max]),
      for (final d in second ?? const <DayValue>[]) ...[d.min, d.max],
    ];
    var lo = total ? 0.0 : all.reduce(min);
    var hi = all.reduce(max);
    if (hi - lo < 1e-6) {
      hi += 1;
      if (!total) lo -= 1;
    }
    final pad = total ? 0 : (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;
    double x(DateTime day) =>
        left +
        (w - left - right) *
            (day.difference(start).inHours / 24).round() /
            span;
    double y(double v) => top + (h - top - bottom) * (1 - (v - lo) / (hi - lo));
    String f(double v) => v.toStringAsFixed(1);
    final svg = StringBuffer(
      '<svg class="chart" viewBox="0 0 ${w.toInt()} ${h.toInt()}" role="img" '
      'aria-label="${PanelApi._h(c.f('chartDaily', {'metric': _label(t, m)}))}" dir="ltr">',
    );
    for (var i = 0; i <= 2; i++) {
      final v = lo + (hi - lo) * i / 2;
      final yy = y(v);
      final label = m == ReportMetric.sleep
          ? t.duration(v.round())
          : _fmt(t, m, v);
      svg.write(
        '<line x1="$left" x2="${w - right}" y1="${f(yy)}" y2="${f(yy)}" class="grid"/>'
        '<text x="${left - 4}" y="${f(yy + 4)}" text-anchor="end">${PanelApi._h(label)}</text>',
      );
    }
    final end = start.add(Duration(days: span));
    svg.write(
      '<text x="$left" y="${h - 6}">${PanelApi._h(PanelApi._date(t, start))}</text>'
      '<text x="${w - right}" y="${h - 6}" text-anchor="end">${PanelApi._h(PanelApi._date(t, end))}</text>',
    );
    if (total) {
      final bw = max(2.0, (w - left - right) / (span + 1) * 0.7);
      for (final d in days) {
        final yy = y(val(d));
        svg.write(
          '<rect x="${f(x(d.day) - bw / 2)}" y="${f(yy)}" width="${f(bw)}" height="${f(max(0, h - bottom - yy))}" class="bar"/>',
        );
      }
    } else {
      if (days.length > 1) {
        final band = [
          for (final d in days) '${f(x(d.day))},${f(y(d.max))}',
          for (final d in days.reversed) '${f(x(d.day))},${f(y(d.min))}',
        ].join(' ');
        svg.write('<polygon points="$band" class="band"/>');
      }
      for (final (list, cls) in [
        (days, 'line'),
        if (second != null) (second, 'line2'),
      ]) {
        final pts = [
          for (final d in list) '${f(x(d.day))},${f(y(d.mean))}',
        ].join(' ');
        if (list.length > 1) {
          svg.write('<polyline points="$pts" class="$cls"/>');
        }
        for (final d in list) {
          svg.write(
            '<circle cx="${f(x(d.day))}" cy="${f(y(d.mean))}" r="2.5" class="$cls"/>',
          );
        }
      }
    }
    svg.write('</svg>');
    return svg.toString();
  }

  // ------------------------------------------------------------ dışa aktarma

  Response _exportCsv(Request r, String id) {
    final t = PanelApi._t(r);
    final access = _reportAccess(r, id);
    if (access is Response) return access;
    final (_, me, consent) = access as (_Session, Account, Consent);
    final range = _range(r);
    if (range == null) return Response(400, body: 'from/to');
    final (from, to) = range;
    final items = store.observations(
      id,
      codes: _exportCodes(r, consent),
      from: from,
      to: to,
    );
    _audit(
      me.id,
      id,
      true,
      'Panel: CSV dışa aktarıldı (${items.length} ölçüm)',
    );

    String cell(Object? v) {
      var s = v?.toString() ?? '';
      // Hesap tablosunda formül sayılmasın.
      if (s.isNotEmpty && '=+-@'.contains(s[0]) && double.tryParse(s) == null) {
        s = "'$s";
      }
      return s.contains(RegExp('[",\n;]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final out = StringBuffer(
      '﻿',
    )..writeln(['time', 'code', 'metric', 'value', 'unit', 'detail'].join(','));
    for (final o in items) {
      final q = o.resource['valueQuantity'] as Map?;
      final parts = <String>[];
      for (final comp in (o.resource['component'] as List?) ?? const []) {
        if (comp is! Map) continue;
        final code =
            (((comp['code'] as Map?)?['coding'] as List?)?.firstOrNull
                as Map?)?['code'];
        final v = (comp['valueQuantity'] as Map?)?['value'];
        if (code != null && v != null) parts.add('$code=$v');
      }
      out.writeln(
        [
          o.effective.toUtc().toIso8601String(),
          o.code,
          t.codeLabels[o.code] ?? o.code,
          q?['value'],
          q?['unit'],
          parts.join(' '),
        ].map(cell).join(','),
      );
    }
    return Response.ok(
      out.toString(),
      headers: {
        'content-type': 'text/csv; charset=utf-8',
        'content-disposition':
            'attachment; filename="${_fileName(id, from, to)}.csv"',
        'cache-control': 'no-store',
        'x-content-type-options': 'nosniff',
      },
    );
  }

  Response _exportFhir(Request r, String id) {
    final access = _reportAccess(r, id);
    if (access is Response) return access;
    final (_, me, consent) = access as (_Session, Account, Consent);
    final range = _range(r);
    if (range == null) return Response(400, body: 'from/to');
    final (from, to) = range;
    final items = store.observations(
      id,
      codes: _exportCodes(r, consent),
      from: from,
      to: to,
    );
    _audit(
      me.id,
      id,
      true,
      'Panel: FHIR dışa aktarıldı (${items.length} ölçüm)',
    );
    final bundle = {
      'resourceType': 'Bundle',
      'type': 'collection',
      'timestamp': _now().toUtc().toIso8601String(),
      'entry': [
        {
          'resource': {'resourceType': 'Patient', 'id': id},
        },
        for (final o in items) {'resource': o.resource},
      ],
    };
    return Response.ok(
      const JsonEncoder.withIndent(' ').convert(bundle),
      headers: {
        'content-type': 'application/fhir+json; charset=utf-8',
        'content-disposition':
            'attachment; filename="${_fileName(id, from, to)}.json"',
        'cache-control': 'no-store',
        'x-content-type-options': 'nosniff',
      },
    );
  }

  /// `?s=` ile seçilen türler (yoksa rızadaki tümü), yalnızca rızadakiler.
  Set<String> _exportCodes(Request r, Consent consent) {
    final requested = {
      for (final v in r.url.queryParametersAll['s'] ?? const <String>[])
        ?ShareScope.byName(v),
    };
    final scopes = requested.isEmpty
        ? consent.scopes
        : requested.intersection(consent.scopes);
    return {for (final s in scopes) ...s.codes};
  }

  static String _fileName(String id, DateTime from, DateTime to) =>
      'bileklik-${PanelApi._shortId(id).replaceAll(RegExp('[^A-Za-z0-9-]'), '')}-'
      '${_PanelRecords._ymd(from)}-${_PanelRecords._ymd(to)}';
}
