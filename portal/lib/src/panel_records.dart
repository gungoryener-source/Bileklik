part of 'panel.dart';

/// Hekimin hasta kayıtları: tanımlama, düzenleme, silme ve bilekliğe bağlama.
///
/// Kayıt yalnızca açan hekime görünür; başka hekimin kaydı "bulunamadı"
/// döner. Bağlama iki yolla olur: kayda özel davet kodunu hasta uygulamada
/// kabul eder (portal, kabulde kaydı bağlar) ya da hekim kendisine rıza
/// vermiş bir bağlantıyı seçer. Veri her durumda yalnızca süren rızadaki
/// türlerle görünür.
extension _PanelRecords on PanelApi {
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${PanelApi._two(d.month)}-${PanelApi._two(d.day)}';

  /// `yyyy-aa-gg`; geçersizse null.
  static DateTime? _parseDay(String? v) {
    if (v == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v.trim());
    if (m == null) return null;
    final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
    final date = DateTime.utc(y, mo, d);
    if (date.month != mo || date.day != d) return null;
    return date;
  }

  String _sexLabel(ClinicText c, Sex? s) => switch (s) {
    Sex.female => c['sexFemale'],
    Sex.male => c['sexMale'],
    Sex.other => c['sexOther'],
    null => c['sexUnset'],
  };

  /// Listede ve kayıt sayfasında görünen bağlantı durumu ve rozet sınıfı.
  (String, String) _recordStatus(ClinicText c, PatientRecord rec) {
    final pid = rec.patientId;
    if (pid != null) {
      return _activeConsent(rec.ownerId, pid) == null
          ? (c['statusEnded'], 'wait')
          : (c['statusLinked'], 'on');
    }
    final code = rec.inviteCode;
    final invite = code == null ? null : store.invite(code);
    if (invite != null && _now().isBefore(invite.expires)) {
      return (c['statusPending'], 'wait');
    }
    return (c['statusNone'], '');
  }

  /// Oturum ve hekimin kendi kaydı; yoksa hata sayfası.
  (_Session, Account, PatientRecord)? _ownRecord(Request r, String id) {
    final auth = _auth(r);
    if (auth == null) return null;
    final rec = store.record(id);
    if (rec == null || rec.ownerId != auth.$2.id) return null;
    return (auth.$1, auth.$2, rec);
  }

  Response _recordMissing(Request r) {
    final t = PanelApi._t(r);
    final auth = _auth(r);
    if (auth == null) return _html(401, _loginPage(t));
    // 404 değil: API'nin Cascade'i 404'ü "panel yolu değil" sayar.
    return _html(
      403,
      _page(
        t,
        auth.$2,
        auth.$1,
        PanelApi._c(r)['recordNotFound'],
        '<p>${PanelApi._h(PanelApi._c(r)['recordNotFound'])}</p>'
        '<p><a href="/panel">${PanelApi._h(t.myPatients)}</a></p>',
      ),
    );
  }

  String _recordForm(
    PanelText t,
    _Session s, {
    required String action,
    PatientRecord? rec,
    Map<String, List<String>>? form,
  }) {
    final c = ClinicText.of(t.lang);
    String v(String k, String? fallback) =>
        PanelApi._h(form?[k]?.firstOrNull ?? fallback ?? '');
    final sex = form?['sex']?.firstOrNull ?? rec?.sex?.name ?? '';
    String option(String value, String label) =>
        '<option value="$value"${sex == value ? ' selected' : ''}>${PanelApi._h(label)}</option>';
    return '''
<form method="post" action="${PanelApi._h(action)}" class="card">
<input type="hidden" name="csrf" value="${PanelApi._h(s.csrf)}">
<label>${PanelApi._h(c['patientName'])}<input name="name" value="${v('name', rec?.name)}" required maxlength="80" autocomplete="off"></label>
<div class="grid2">
<label>${PanelApi._h(c['birthDate'])}<input type="date" name="birth" value="${v('birth', rec?.birthDate == null ? null : _ymd(rec!.birthDate!))}" min="1900-01-01" dir="ltr"></label>
<label>${PanelApi._h(c['sex'])}<select name="sex">${option('', c['sexUnset'])}${option('female', c['sexFemale'])}${option('male', c['sexMale'])}${option('other', c['sexOther'])}</select></label>
<label>${PanelApi._h(c['fileNo'])}<input name="fileNo" value="${v('fileNo', rec?.fileNo)}" maxlength="40" autocomplete="off" dir="ltr"></label>
<label>${PanelApi._h(c['phone'])}<input type="tel" name="phone" value="${v('phone', rec?.phone)}" maxlength="30" autocomplete="off" dir="ltr"></label>
</div>
<label>${PanelApi._h(c['notes'])}<textarea name="notes" maxlength="2000" rows="3">${v('notes', rec?.notes)}</textarea></label>
<button type="submit">${PanelApi._h(c['save'])}</button>
</form>''';
  }

  Response _newRecordPage(Request r) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final auth = _auth(r);
    if (auth == null) return _html(401, _loginPage(t));
    final (s, me) = auth;
    return _html(
      200,
      _page(
        t,
        me,
        s,
        c['newPatient'],
        active: '/panel/records/new',
        '<h1>${PanelApi._h(c['newPatient'])}</h1>'
        '<p class="muted">${PanelApi._h(c['newPatientIntro'])}</p>'
        '${_recordForm(t, s, action: '/panel/records')}',
      ),
    );
  }

  /// Formu doğrular; hata metni ya da kayıt alanları.
  ({
    String? error,
    String? name,
    DateTime? birth,
    Sex? sex,
    String? fileNo,
    String? phone,
    String? notes,
  })
  _readRecord(ClinicText c, Map<String, List<String>> form) {
    String? field(String k, int max) {
      final v = form[k]?.firstOrNull?.trim() ?? '';
      if (v.isEmpty) return null;
      return v.length > max ? v.substring(0, max) : v;
    }

    final name = field('name', 80);
    final birthRaw = field('birth', 10);
    final birth = _parseDay(birthRaw);
    final now = _now();
    String? error;
    if (name == null) {
      error = c['errName'];
    } else if (birthRaw != null &&
        (birth == null || birth.isAfter(now) || birth.year < 1900)) {
      error = c['errBirthDate'];
    }
    return (
      error: error,
      name: name,
      birth: birth,
      sex: Sex.values.asNameMap()[form['sex']?.firstOrNull ?? ''],
      fileNo: field('fileNo', 40),
      phone: field('phone', 30),
      notes: field('notes', 2000),
    );
  }

  Future<Response> _createRecord(Request r) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final auth = _auth(r);
    if (auth == null) return _html(401, _loginPage(t));
    final (s, me) = auth;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${PanelApi._h(t.formExpired)}</p>'),
      );
    }
    final f = _readRecord(c, form);
    if (f.error != null) {
      return _html(
        400,
        _page(
          t,
          me,
          s,
          c['newPatient'],
          '<h1>${PanelApi._h(c['newPatient'])}</h1>'
          '<p class="error" role="alert">${PanelApi._h(f.error!)}</p>'
          '${_recordForm(t, s, action: '/panel/records', form: form)}',
        ),
      );
    }
    final rec = PatientRecord(
      id: store.nextId('rec'),
      ownerId: me.id,
      name: f.name!,
      created: _now(),
      birthDate: f.birth,
      sex: f.sex,
      fileNo: f.fileNo,
      phone: f.phone,
      notes: f.notes,
    );
    store.putRecord(rec);
    return Response(
      303,
      headers: {'location': '/panel/records/${Uri.encodeComponent(rec.id)}'},
    );
  }

  Future<Response> _updateRecord(Request r, String id) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${PanelApi._h(t.formExpired)}</p>'),
      );
    }
    final f = _readRecord(c, form);
    if (f.error != null) {
      return _recordPage(r, id, error: f.error, form: form, status: 400);
    }
    store.putRecord(
      PatientRecord(
        id: rec.id,
        ownerId: rec.ownerId,
        created: rec.created,
        name: f.name!,
        birthDate: f.birth,
        sex: f.sex,
        fileNo: f.fileNo,
        phone: f.phone,
        notes: f.notes,
        patientId: rec.patientId,
        inviteCode: rec.inviteCode,
      ),
    );
    return _recordPage(r, id, notice: c['saved']);
  }

  Response _recordPage(
    Request r,
    String id, {
    String? notice,
    String? error,
    Map<String, List<String>>? form,
    String? newCode,
    int status = 200,
  }) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final now = _now();
    final esc = PanelApi._h;
    final enc = esc(Uri.encodeComponent(rec.id));
    final age = rec.ageAt(now);
    String fact(String key, String? value, {bool ltr = false}) =>
        value == null || value.isEmpty
        ? ''
        : '<dt>${esc(c[key])}</dt><dd dir="${ltr ? 'ltr' : 'auto'}">${esc(value)}</dd>';
    final (label, cls) = _recordStatus(c, rec);
    final consent = rec.patientId == null
        ? null
        : _activeConsent(me.id, rec.patientId!);
    final csrf = '<input type="hidden" name="csrf" value="${esc(s.csrf)}">';

    final inviteForm =
        '''
<form method="post" action="/panel/records/$enc/invite">
$csrf
<label>${esc(c['invitePurpose'])}<input name="purpose" value="${esc(c['consentPurposeDefault'])}" required maxlength="500"></label>
<fieldset><legend>${esc(t.requestedData)}</legend>${PanelApi._scopeBoxes(t, ShareScope.values, checked: ShareScope.values.toSet())}</fieldset>
<label>${esc(t.durationDays)}<input type="number" name="days" value="365" min="1" max="730" required></label>
<button type="submit">${esc(t.createCode)}</button>
</form>''';

    final linkedElsewhere = {
      for (final x in store.recordsOf(me.id))
        if (x.patientId != null && x.id != rec.id) x.patientId!,
    };
    final candidates = [
      for (final k in store.consentsForActor(me.id))
        if (k.activeAt(now) && !linkedElsewhere.contains(k.patientId)) k,
    ];
    final linkExisting = candidates.isEmpty || rec.patientId != null
        ? ''
        : '''
<h3>${esc(c['linkExisting'])}</h3>
<form method="post" action="/panel/records/$enc/link" class="row">
$csrf
<label>${esc(t.colPatient)}<select name="patient" dir="ltr">${[for (final k in candidates) '<option value="${esc(k.patientId)}">${esc(PanelApi._shortId(k.patientId))} · ${esc(PanelApi._scopes(t, k.scopes))}</option>'].join()}</select></label>
<button type="submit" class="secondary">${esc(c['linkButton'])}</button>
</form>''';

    final pendingCode =
        newCode ??
        (cls == 'wait' && rec.patientId == null ? rec.inviteCode : null);
    final String wristband;
    if (rec.patientId != null && consent != null) {
      final pid = esc(Uri.encodeComponent(rec.patientId!));
      wristband =
          '''
<dl class="facts">
<dt>${esc(c['linkedTo'])}</dt><dd dir="ltr">${esc(PanelApi._shortId(rec.patientId!))}</dd>
<dt>${esc(t.colShared)}</dt><dd>${esc(PanelApi._scopes(t, consent.scopes))}</dd>
<dt>${esc(t.colConsentEnd)}</dt><dd>${esc(PanelApi._date(t, consent.end))}</dd>
</dl>
<p class="row"><a class="button" href="/panel/patients/$pid">${esc(c['viewData'])}</a> <a class="button" href="/panel/patients/$pid/report">${esc(c['createReport'])}</a></p>
<form method="post" action="/panel/records/$enc/unlink">$csrf<button type="submit" class="link">${esc(c['unlink'])}</button> <span class="muted small">${esc(c['unlinkNote'])}</span></form>''';
    } else if (rec.patientId != null) {
      wristband =
          '''
<p>${esc(c['consentEnded'])}</p>
$inviteForm
<form method="post" action="/panel/records/$enc/unlink">$csrf<button type="submit" class="link">${esc(c['unlink'])}</button></form>''';
    } else {
      wristband =
          '''
${pendingCode == null ? '' : '<p>${esc(c['pendingCode'])}</p><p dir="ltr" class="code">${esc(pendingCode)}</p><p class="muted small">${esc(t.inviteCodeBody)}</p>'}
<p class="muted">${esc(c['linkIntro'])}</p>
${pendingCode == null ? inviteForm : '<details><summary>${esc(t.createInvite)}</summary>$inviteForm</details>'}
$linkExisting''';
    }

    return _html(
      status,
      _page(t, me, s, rec.name, '''
<p><a href="/panel">${t.rtl ? '→' : '←'} ${esc(t.myPatients)}</a></p>
<h1>${esc(rec.name)} <span class="badge $cls">${esc(label)}</span></h1>
${notice == null ? '' : '<p class="ok" role="status">${esc(notice)}</p>'}
${error == null ? '' : '<p class="error" role="alert">${esc(error)}</p>'}
<section class="card">
<dl class="facts">
${fact('fileNo', rec.fileNo, ltr: true)}
${fact('birthDate', rec.birthDate == null ? null : '${PanelApi._date(t, rec.birthDate!)}${age == null ? '' : ' (${c.f('ageYears', {'n': age})})'}')}
${fact('sex', rec.sex == null ? null : _sexLabel(c, rec.sex))}
${fact('phone', rec.phone, ltr: true)}
${fact('notes', rec.notes)}
${fact('createdAt', PanelApi._date(t, rec.created))}
</dl>
</section>
<section class="card">
<h2>${esc(c['linkTitle'])}</h2>
$wristband
</section>
<details class="card"${form == null ? '' : ' open'}>
<summary><strong>${esc(c['editRecord'])}</strong></summary>
${_recordForm(t, s, action: '/panel/records/${rec.id}', rec: rec, form: form)}
</details>
<details class="card">
<summary><strong>${esc(c['deleteRecord'])}</strong></summary>
<p class="muted">${esc(c['deleteNote'])}</p>
<form method="post" action="/panel/records/$enc/delete" class="row">
$csrf
<label>${esc(c['deleteConfirm'])}<input name="confirm" required autocomplete="off"></label>
<button type="submit" class="danger">${esc(c['deleteRecord'])}</button>
</form>
</details>
'''),
    );
  }

  /// Kayda özel davet kodu; hasta kabul edince kayıt bilekliğe bağlanır.
  Future<Response> _recordInvite(Request r, String id) async {
    final t = PanelApi._t(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${PanelApi._h(t.formExpired)}</p>'),
      );
    }
    final purpose = form['purpose']?.firstOrNull?.trim() ?? '';
    final scopes = {
      for (final v in form['scope'] ?? const <String>[]) ?ShareScope.byName(v),
    };
    final days = int.tryParse(form['days']?.firstOrNull ?? '') ?? 0;
    if (purpose.isEmpty ||
        purpose.length > 500 ||
        scopes.isEmpty ||
        days < 1 ||
        days > 730) {
      return _recordPage(r, id, error: t.missingInfoBody, status: 400);
    }
    final code = _newInviteCode();
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
    // Eski bekleyen kod artık bu kayda bağlamaz.
    final old = rec.inviteCode;
    if (old != null) store.removeInvite(old);
    store.putRecord(rec.copyWith(inviteCode: code));
    return _recordPage(r, id, newCode: code, status: 201);
  }

  String _newInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    while (true) {
      final code = List.generate(
        7,
        (_) => alphabet[_random.nextInt(alphabet.length)],
      ).join();
      if (store.invite(code) == null) return code;
    }
  }

  Future<Response> _linkRecord(Request r, String id) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${PanelApi._h(t.formExpired)}</p>'),
      );
    }
    final pid = form['patient']?.firstOrNull ?? '';
    if (_activeConsent(me.id, pid) == null) {
      _audit(
        me.id,
        pid,
        false,
        'Panel: rızasız bağlantı kayda bağlanmak istendi',
      );
      return _recordPage(r, id, error: t.noAccessBody, status: 403);
    }
    final other = _recordFor(me.id, pid);
    if (other != null && other.id != rec.id) {
      return _recordPage(r, id, error: c['alreadyLinked'], status: 409);
    }
    store.putRecord(rec.copyWith(patientId: pid));
    return _recordPage(r, id, notice: c['saved']);
  }

  Future<Response> _unlinkRecord(Request r, String id) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${PanelApi._h(t.formExpired)}</p>'),
      );
    }
    store.putRecord(rec.copyWith(clearPatient: true, clearInvite: true));
    return _recordPage(r, id, notice: c['saved']);
  }

  Future<Response> _deleteRecord(Request r, String id) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final own = _ownRecord(r, id);
    if (own == null) return _recordMissing(r);
    final (s, me, rec) = own;
    final form = await PanelApi._form(r);
    if (form['csrf']?.firstOrNull != s.csrf) {
      return _html(
        403,
        _page(t, me, s, t.error, '<p>${PanelApi._h(t.formExpired)}</p>'),
      );
    }
    final word = (form['confirm']?.firstOrNull ?? '').trim();
    if (word.toUpperCase() != c['deleteWord'].toUpperCase() &&
        word != c['deleteWord']) {
      return _recordPage(r, id, error: c['deleteConfirm'], status: 400);
    }
    final code = rec.inviteCode;
    if (code != null && rec.patientId == null) store.removeInvite(code);
    store.deleteRecord(rec.id);
    return _html(
      200,
      _page(
        t,
        me,
        s,
        c['deleted'],
        '<p class="ok" role="status">${PanelApi._h(c['deleted'])}</p>'
        '<p><a href="/panel">${PanelApi._h(t.myPatients)}</a></p>',
      ),
    );
  }
}
