part of 'panel.dart';

/// Hekimin kendi hesabı: kayıt, e-posta ve şifreyle giriş, şifre değiştirme.
///
/// - Kendi kaydolan hesap "doğrulanmadı" olarak başlar ([Account.verified]);
///   portal yöneticisi `--verify-clinician` ile doğrular. Hasta davet
///   ekranında bunu görür.
/// - Şifrenin yalnızca tuzlu PBKDF2 özeti saklanır ([PasswordHasher]).
/// - Aynı e-postaya 15 dakikada en çok [_PanelAccount.maxFailures] hatalı
///   deneme; sonra o e-posta için giriş geçici olarak kapanır.
extension _PanelAccount on PanelApi {
  static const maxFailures = 5;
  static const failureWindow = Duration(minutes: 15);
  static final _emailPattern = RegExp(
    r'^[^@\s<>"]{1,64}@[^@\s<>"]{1,190}\.[^@\s<>"]{2,}$',
  );

  static String? _field(Map<String, List<String>> form, String key, int max) {
    final v = form[key]?.firstOrNull?.trim() ?? '';
    if (v.isEmpty) return null;
    return v.length > max ? v.substring(0, max) : v;
  }

  bool _throttled(String email) {
    final now = _now();
    final list = _loginFailures[email];
    if (list == null) return false;
    list.removeWhere((t) => now.difference(t) >= failureWindow);
    return list.length >= maxFailures;
  }

  Future<Response> _loginWithPassword(
    Request r,
    Map<String, List<String>> form,
  ) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final email = (form['email']?.firstOrNull ?? '').trim().toLowerCase();
    final password = form['password']?.firstOrNull ?? '';
    if (_throttled(email)) {
      return _html(
        429,
        _loginPage(t, error: c['tooManyAttempts'], email: email),
      );
    }
    final account = store.accountByEmail(email);
    final hash = account == null ? null : store.passwordOf(account.id);
    final ok =
        hash != null &&
        (account!.role == Role.clinician || account.role == Role.researcher) &&
        await passwords.verify(password, hash);
    if (!ok) {
      _loginFailures.putIfAbsent(email, () => []).add(_now());
      return _html(401, _loginPage(t, error: c['badLogin'], email: email));
    }
    _loginFailures.remove(email);
    return Response(
      303,
      headers: {'location': '/panel', 'set-cookie': _startSession(account)},
    );
  }

  Response _registerPage(Request r) =>
      _html(200, _registerForm(PanelApi._t(r), const {}));

  String _registerForm(
    PanelText t,
    Map<String, List<String>> form, {
    String? error,
  }) {
    final c = ClinicText.of(t.lang);
    String v(String k) => PanelApi._h(form[k]?.firstOrNull ?? '');
    final researcher = form['type']?.firstOrNull == 'researcher';
    return PanelApi._document(t, c['registerTitle'], '''
<main class="narrow">
<nav class="langs small">${PanelApi._languages(t)}</nav>
<h1>${PanelApi._h(c['registerTitle'])}</h1>
<p class="muted">${PanelApi._h(c['registerIntro'])}</p>
${error == null ? '' : '<p class="error" role="alert">${PanelApi._h(error)}</p>'}
<form method="post" action="/panel/register" class="card">
<label>${PanelApi._h(c['accountType'])}<select name="type">
<option value="clinician"${researcher ? '' : ' selected'}>${PanelApi._h(c['typeClinician'])}</option>
<option value="researcher"${researcher ? ' selected' : ''}>${PanelApi._h(c['typeResearcher'])}</option>
</select></label>
<label>${PanelApi._h(c['fullName'])}<input name="name" value="${v('name')}" required maxlength="80" autocomplete="name"></label>
<label>${PanelApi._h(c['specialty'])}<input name="specialty" value="${v('specialty')}" maxlength="80"></label>
<label>${PanelApi._h(c['organization'])}<input name="organization" value="${v('organization')}" maxlength="120" autocomplete="organization"></label>
<label>${PanelApi._h(c['licenseNo'])}<input name="license" value="${v('license')}" maxlength="40" dir="ltr"></label>
<label>${PanelApi._h(c['email'])}<input type="email" name="email" value="${v('email')}" required maxlength="120" autocomplete="username" dir="ltr"></label>
<label>${PanelApi._h(c['password'])}<input type="password" name="password" required minlength="${PasswordHasher.minLength}" autocomplete="new-password"><span class="muted small">${PanelApi._h(c['passwordHint'])}</span></label>
<label>${PanelApi._h(c['password2'])}<input type="password" name="password2" required minlength="${PasswordHasher.minLength}" autocomplete="new-password"></label>
<label class="check"><input type="checkbox" name="terms" value="1" required> ${PanelApi._h(c['terms'])}</label>
<p><button type="submit">${PanelApi._h(c['createAccount'])}</button></p>
</form>
<p><a href="/panel">${PanelApi._h(c['haveAccount'])}</a></p>
</main>
''');
  }

  Future<Response> _register(Request r) async {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final form = await PanelApi._form(r);
    final name = _field(form, 'name', 80);
    final email = (form['email']?.firstOrNull ?? '').trim().toLowerCase();
    final password = form['password']?.firstOrNull ?? '';
    final error = name == null
        ? c['errName']
        : !_emailPattern.hasMatch(email) || email.length > 120
        ? c['errEmail']
        : password.length < PasswordHasher.minLength || password.length > 200
        ? c['errPassword']
        : password != form['password2']?.firstOrNull
        ? c['errPasswordMatch']
        : form['terms']?.firstOrNull != '1'
        ? c['errTerms']
        : store.accountByEmail(email) != null
        ? c['errEmailTaken']
        : null;
    if (error != null) {
      return _html(400, _registerForm(t, form, error: error));
    }
    final account = Account(
      id: store.nextId('dr'),
      role: form['type']?.firstOrNull == 'researcher'
          ? Role.researcher
          : Role.clinician,
      name: name!,
      organization: _field(form, 'organization', 120),
      email: email,
      specialty: _field(form, 'specialty', 80),
      licenseNo: _field(form, 'license', 40),
      verified: false,
    );
    // Oturum anahtarıyla giriş kullanılmaz; rastgele ve kimseye verilmeyen
    // bir anahtar yazılır.
    store.addAccount(account, _randomHex(32));
    store.setPassword(
      account.id,
      await passwords.hash(password, random: _random),
    );
    return Response(
      303,
      headers: {'location': '/panel', 'set-cookie': _startSession(account)},
    );
  }

  Response _accountPage(
    Request r, {
    String? notice,
    String? error,
    int status = 200,
  }) {
    final t = PanelApi._t(r);
    final c = PanelApi._c(r);
    final auth = _auth(r);
    if (auth == null) return _html(401, _loginPage(t));
    final (s, me) = auth;
    final hasPassword = store.passwordOf(me.id) != null;
    String fact(String key, String? value) => value == null || value.isEmpty
        ? ''
        : '<dt>${PanelApi._h(c[key])}</dt><dd>${PanelApi._h(value)}</dd>';
    return _html(
      status,
      _page(t, me, s, c['myAccount'], active: '/panel/account', '''
<h1>${PanelApi._h(c['myAccount'])}</h1>
${notice == null ? '' : '<p class="ok" role="status">${PanelApi._h(notice)}</p>'}
${error == null ? '' : '<p class="error" role="alert">${PanelApi._h(error)}</p>'}
<section class="card">
<dl class="facts">
${fact('fullName', me.name)}
${fact('accountType', me.role == Role.researcher ? c['typeResearcher'] : c['typeClinician'])}
${fact('specialty', me.specialty)}
${fact('organization', me.organization)}
${fact('licenseNo', me.licenseNo)}
${fact('email', me.email)}
<dt></dt><dd>${me.verified ? '<span class="badge on">${PanelApi._h(c['verified'])}</span>' : '<span class="badge wait">${PanelApi._h(c['notVerified'])}</span>'}</dd>
</dl>
</section>
<h2>${PanelApi._h(hasPassword ? c['changePassword'] : c['setPassword'])}</h2>
${hasPassword || me.email != null ? '' : '<p class="muted">${PanelApi._h(c['noPasswordYet'])}</p>'}
<form method="post" action="/panel/account/password" class="card">
<input type="hidden" name="csrf" value="${PanelApi._h(s.csrf)}">
${me.email == null ? '<label>${PanelApi._h(c['email'])}<input type="email" name="email" required maxlength="120" autocomplete="username" dir="ltr"></label>' : ''}
${hasPassword ? '<label>${PanelApi._h(c['currentPassword'])}<input type="password" name="current" required autocomplete="current-password"></label>' : ''}
<label>${PanelApi._h(c['newPassword'])}<input type="password" name="password" required minlength="${PasswordHasher.minLength}" autocomplete="new-password"><span class="muted small">${PanelApi._h(c['passwordHint'])}</span></label>
<label>${PanelApi._h(c['password2'])}<input type="password" name="password2" required minlength="${PasswordHasher.minLength}" autocomplete="new-password"></label>
<button type="submit">${PanelApi._h(c['save'])}</button>
</form>
'''),
    );
  }

  /// Şifre değiştirir. Anahtarla açılmış hesap ilk kez şifre (ve e-posta)
  /// belirleyebilir.
  Future<Response> _changePassword(Request r) async {
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
    final old = store.passwordOf(me.id);
    final password = form['password']?.firstOrNull ?? '';
    final email = (form['email']?.firstOrNull ?? '').trim().toLowerCase();
    String? error;
    if (old != null &&
        !await passwords.verify(form['current']?.firstOrNull ?? '', old)) {
      error = c['errCurrentPassword'];
    } else if (password.length < PasswordHasher.minLength ||
        password.length > 200) {
      error = c['errPassword'];
    } else if (password != form['password2']?.firstOrNull) {
      error = c['errPasswordMatch'];
    } else if (me.email == null && !_emailPattern.hasMatch(email)) {
      error = c['errEmail'];
    } else if (me.email == null && store.accountByEmail(email) != null) {
      error = c['errEmailTaken'];
    }
    if (error != null) return _accountPage(r, error: error, status: 400);
    if (me.email == null) {
      store.updateAccount(
        Account(
          id: me.id,
          role: me.role,
          name: me.name,
          organization: me.organization,
          email: email,
          specialty: me.specialty,
          licenseNo: me.licenseNo,
          verified: me.verified,
        ),
      );
    }
    store.setPassword(me.id, await passwords.hash(password, random: _random));
    return _accountPage(r, notice: c['passwordChanged']);
  }
}
