part of 'panel.dart';

/// Hasta kaydında izlem notları ve görevler (bakım takibi).
///
/// - Not: tarihli serbest metin (görüşme, ilaç değişikliği, telefonla arama).
/// - Görev: kısa metin ve isteğe bağlı son gün; "Tamamlandı" ile kapanır.
/// - Ana sayfada hekimin açık görevleri, gecikenler önce.
/// - Yalnızca kaydı açan hekim görür; kayıt silinince notlar da silinir.
extension _PanelCare on PanelApi {
  static String _h(String s) => PanelApi._h(s);

  static const noteMax = 2000;
  static const taskMax = 300;

  /// Son gün UTC gece yarısı saklanır; yerel saate çevirmeden yazılır.
  static String _day(PanelText t, DateTime d) => t.dateOrder == 'ymd'
      ? '${d.year}-${PanelApi._two(d.month)}-${PanelApi._two(d.day)}'
      : '${PanelApi._two(d.day)}.${PanelApi._two(d.month)}.${d.year}';

  String _dueBadge(PanelText t, ClinicText c, CareEntry e, DateTime now) {
    final d = e.due;
    if (d == null) return '';
    final today = DateTime.utc(now.year, now.month, now.day);
    final cls = e.overdueAt(now)
        ? 'alert'
        : d == today
        ? 'wait'
        : '';
    final label = e.overdueAt(now)
        ? c.f('taskOverdue', {'date': _day(t, d)})
        : d == today
        ? c['taskToday']
        : c.f('taskDue', {'date': _day(t, d)});
    return '<span class="badge $cls">${_h(label)}</span>';
  }

  /// Açık görevler: gecikenler ve son günü yakın olanlar önce, son günsüzler
  /// en sonda.
  static List<CareEntry> _sortTasks(Iterable<CareEntry> tasks) {
    final list = tasks.toList();
    list.sort((a, b) {
      final da = a.due, db = b.due;
      if (da == null && db == null) return b.created.compareTo(a.created);
      if (da == null) return 1;
      if (db == null) return -1;
      final r = da.compareTo(db);
      return r != 0 ? r : a.created.compareTo(b.created);
    });
    return list;
  }

  String _doneForm(_Session s, ClinicText c, CareEntry e) {
    final rid = _h(Uri.encodeComponent(e.recordId));
    final id = _h(Uri.encodeComponent(e.id));
    return '<form method="post" action="/panel/records/$rid/care/$id/done" class="ack">'
        '<input type="hidden" name="csrf" value="${_h(s.csrf)}">'
        '<button type="submit" class="secondary">${_h(c['taskDone'])}</button></form>';
  }

  /// Kayıt sayfasındaki bölüm.
  String _careSection(
    PanelText t,
    ClinicText c,
    _Session s,
    PatientRecord rec,
    DateTime now,
  ) {
    final entries = store.careOf(rec.id);
    final tasks = _sortTasks(entries.where((e) => e.open));
    final history = [
      for (final e in entries)
        if (!e.open) e,
    ];
    final enc = _h(Uri.encodeComponent(rec.id));
    final csrf = '<input type="hidden" name="csrf" value="${_h(s.csrf)}">';
    final taskList = tasks.isEmpty
        ? '<p class="muted">${_h(c['tasksNone'])}</p>'
        : '<ul class="care">${[for (final e in tasks) '<li><div><strong>${_h(e.text)}</strong> ${_dueBadge(t, c, e, now)}</div>${_doneForm(s, c, e)}</li>'].join()}</ul>';
    final timeline = history.isEmpty
        ? '<p class="muted">${_h(c['notesNone'])}</p>'
        : '<ol class="care">${[for (final e in history) e.kind == CareKind.note ? '<li><div><span class="small muted">${_h(PanelApi._dateTime(t, e.created))} · ${_h(c['noteLabel'])}</span><p class="pre">${_h(e.text)}</p></div></li>' : '<li><div><span class="small muted">${_h(PanelApi._dateTime(t, e.doneAt!))} · ${_h(c['taskDoneLabel'])}</span><p>${_h(e.text)}</p></div></li>'].join()}</ol>';
    return '''
<section class="card" aria-labelledby="care-h">
<h2 id="care-h">${_h(c['careTitle'])}</h2>
<h3>${_h(c['tasksTitle'])}</h3>
$taskList
<form method="post" action="/panel/records/$enc/care" class="row">
$csrf
<input type="hidden" name="kind" value="task">
<label style="flex:1 1 240px">${_h(c['taskText'])}<input name="text" required maxlength="$taskMax"></label>
<label>${_h(c['taskDueLabel'])}<input type="date" name="due" dir="ltr"></label>
<button type="submit">${_h(c['taskAdd'])}</button>
</form>
<h3>${_h(c['notesTitle'])}</h3>
<form method="post" action="/panel/records/$enc/care">
$csrf
<input type="hidden" name="kind" value="note">
<label>${_h(c['noteText'])}<textarea name="text" rows="3" required maxlength="$noteMax"></textarea></label>
<button type="submit">${_h(c['noteAdd'])}</button>
</form>
$timeline
</section>''';
  }

  /// Ana sayfadaki "Görevlerim" bölümü; açık görev yoksa boş.
  String _myTasksHtml(
    PanelText t,
    ClinicText c,
    _Session s,
    Account me,
    DateTime now,
  ) {
    final tasks = _sortTasks(store.openTasksOf(me.id));
    if (tasks.isEmpty) return '';
    final rows = StringBuffer();
    for (final e in tasks.take(20)) {
      final rec = store.record(e.recordId);
      if (rec == null) continue;
      rows.write(
        '<tr${e.overdueAt(now) ? ' class="row-alert"' : ''}>'
        '<td><a href="/panel/records/${_h(Uri.encodeComponent(rec.id))}">${_h(rec.name)}</a></td>'
        '<td>${_h(e.text)}</td>'
        '<td>${_dueBadge(t, c, e, now)}</td>'
        '<td>${_doneForm(s, c, e)}</td></tr>',
      );
    }
    return '''
<section aria-labelledby="tasks-h">
<h2 id="tasks-h">${_h(c['myTasks'])}</h2>
<div class="table-wrap"><table>
<thead><tr><th>${_h(c['colName'])}</th><th>${_h(c['taskText'])}</th><th>${_h(c['taskDueLabel'])}</th><th>${_h(c['alertColAction'])}</th></tr></thead>
<tbody>$rows</tbody>
</table></div>
${tasks.length > 20 ? '<p class="small muted">${_h(c.f('tasksMore', {'n': tasks.length - 20}))}</p>' : ''}
</section>''';
  }

  /// Not ya da görev ekler.
  Future<Response> _addCare(Request r, String id) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${_h(t.formExpired)}</p>'),
      );
    }
    final kind = CareKind.values.asNameMap()[form['kind']?.firstOrNull];
    final text = (form['text']?.firstOrNull ?? '').trim();
    final max = kind == CareKind.task ? taskMax : noteMax;
    final dueRaw = (form['due']?.firstOrNull ?? '').trim();
    final due = dueRaw.isEmpty ? null : _PanelRecords._parseDay(dueRaw);
    if (kind == null ||
        text.isEmpty ||
        text.length > max ||
        (dueRaw.isNotEmpty && due == null)) {
      return _recordPage(r, id, error: c['careInvalid'], status: 400);
    }
    store.putCare(
      CareEntry(
        id: store.nextId('care'),
        recordId: rec.id,
        ownerId: me.id,
        kind: kind,
        text: text,
        created: _now(),
        due: kind == CareKind.task ? due : null,
      ),
    );
    return Response(
      303,
      headers: {'location': '/panel/records/${Uri.encodeComponent(rec.id)}'},
    );
  }

  /// Görevi tamamlar; ana sayfadan geldiyse ana sayfaya döner.
  Future<Response> _careDone(Request r, String id, String entryId) async {
    final t = PanelApi._t(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${_h(t.formExpired)}</p>'),
      );
    }
    final e = store.care(entryId);
    if (e == null || e.recordId != rec.id || e.ownerId != me.id) {
      return _recordMissing(r);
    }
    if (e.open) store.putCare(e.done(_now()));
    final fromRecord =
        r.headers['referer']?.contains('/panel/records/') ?? false;
    return Response(
      303,
      headers: {
        'location': fromRecord
            ? '/panel/records/${Uri.encodeComponent(rec.id)}'
            : '/panel',
      },
    );
  }
}
