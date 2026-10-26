import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'alerts.dart';
import 'ingest.dart';
import 'model.dart';
import 'panel.dart';
import 'passwords.dart';
import 'privacy_page.dart';
import 'store.dart';

/// Portalın HTTP API'si.
///
/// | Yol | Kim | Ne yapar |
/// | --- | --- | --- |
/// | `POST /patients` | herkes | Uygulamanın takma kimliğiyle hasta hesabı açar, oturum anahtarı ve kurtarma kodu döner |
/// | `POST /patients/recovery` | hasta | Yeni kurtarma kodu üretir; eskisi geçersiz olur |
/// | `POST /recover` | herkes | Kurtarma koduyla hesabı yeni telefona alır |
/// | `GET /connections` | hasta | Süren rızaları uygulamanın göstereceği biçimde listeler |
/// | `POST /fhir` | hasta | Uygulamanın FHIR Bundle'ını alır |
/// | `GET /fhir/Observation?patient=&code=&date=` | hasta, rızalı takipçi | Ölçümleri arar |
/// | `GET /fhir/Consent` | hasta, takipçi | Rızaları listeler |
/// | `GET /fhir/AuditEvent` | hasta | Verisine kimin eriştiğini gösterir (KVKK) |
/// | `POST /invites` | hekim, araştırmacı | Davet kodu üretir |
/// | `GET /invites/<code>` | hasta | Davetin içeriğini gösterir |
/// | `POST /invites/<code>/accept` | hasta | Açık rızayla bağlanır |
/// | `DELETE /consents/<id>` | hasta | Rızayı geri alır |
/// | `DELETE /patients/<id>/data` | hasta | Ölçümlerini siler (unutulma hakkı) |
/// | `POST /feedback` | herkes | Uygulama içi geri bildirim (kimliksiz) |
/// | `GET /groups` | hasta | Aile grupları, üyeler, paylaşımlar ve bildirimler |
/// | `POST /groups` | hasta | Grup açar |
/// | `POST /groups/join` | hasta | Grup ya da kişiye özel kodla katılır |
/// | `POST /groups/<id>/members` | grup sahibi | Kişiye özel davet kodu üretir |
/// | `DELETE /groups/<id>/members/<mid>` | grup sahibi | Üyeyi çıkarır |
/// | `PUT /groups/<id>/consent` | üye | Grupla paylaşılan türleri değiştirir |
/// | `DELETE /groups/<id>` | üye | Sahipse grubu siler, değilse ayrılır |
/// | `/panel` | hekim, araştırmacı | Tarayıcı paneli ([PanelApi]) |
/// | `GET /gizlilik`, `GET /privacy` | herkes | Gizlilik politikası ([PrivacyPage]) |
///
/// Kimlik doğrulama iskelette `Authorization: Bearer <anahtar>` ile; gerçek
/// giriş akışı (e-Devlet/OAuth) sonra eklenecek.
class PortalApi {
  PortalApi(
    this.store, {
    DateTime Function()? clock,
    Random? random,
    bool secureCookie = false,
    PasswordHasher passwords = const PasswordHasher(),
  }) : _now = clock ?? DateTime.now,
       _random = random ?? Random.secure(),
       panel = PanelApi(
         store,
         clock: clock,
         random: random,
         secureCookie: secureCookie,
         passwords: passwords,
       );

  final PortalStore store;
  final DateTime Function() _now;
  final Random _random;

  static const fhirJson = 'application/fhir+json';

  /// Davet kodunda karışmayan harf ve rakamlar (0/O, 1/I yok).
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Hekim paneli (`/panel`); tarayıcı oturumuyla çalışır.
  final PanelApi panel;

  /// Önce panel, panel yolu değilse anahtarla korunan API.
  Handler get handler => Cascade()
      .add(panel.handler)
      .add(
        const Pipeline().addMiddleware(_authenticate).addHandler(_router.call),
      )
      .handler;

  late final Router _router = Router()
    ..get('/health', (Request _) => Response.ok('ok'))
    ..get('/gizlilik', PrivacyPage.handle)
    ..get('/privacy', PrivacyPage.handle)
    ..post('/patients', _registerPatient)
    ..post('/patients/recovery', _newRecovery)
    ..post('/recover', _recover)
    ..get('/connections', _connections)
    ..post('/fhir', _ingest)
    ..get('/fhir/Observation', _searchObservations)
    ..get('/fhir/Consent', _searchConsents)
    ..get('/fhir/AuditEvent', _searchAudit)
    ..post('/invites', _createInvite)
    ..get('/invites/<code>', _getInvite)
    ..post('/invites/<code>/accept', _acceptInvite)
    ..delete('/consents/<id>', _revokeConsent)
    ..delete('/patients/<id>/data', _erase)
    ..post('/feedback', _feedback)
    ..get('/groups', _listGroups)
    ..post('/groups', _createGroup)
    ..post('/groups/join', _joinGroup)
    ..post('/groups/<id>/members', _inviteMember)
    ..delete('/groups/<id>/members/<mid>', _removeMember)
    ..put('/groups/<id>/consent', _groupConsent)
    ..delete('/groups/<id>', _leaveGroup);

  Handler _authenticate(Handler inner) => (request) {
    if (request.method == 'GET' &&
        const {'health', 'gizlilik', 'privacy'}.contains(request.url.path)) {
      return inner(request);
    }
    if (request.method == 'POST' &&
        const {'patients', 'feedback', 'recover'}.contains(request.url.path)) {
      return inner(request);
    }
    final header = request.headers['authorization'] ?? '';
    final token = header.startsWith('Bearer ') ? header.substring(7) : '';
    final account = store.accountByToken(token);
    if (account == null) {
      return _outcome(401, 'error', 'login', 'Geçerli bir oturum anahtarı gerekli');
    }
    return inner(request.change(context: {'account': account}));
  };

  static Account _me(Request r) => r.context['account']! as Account;

  // ------------------------------------------------------------------ kayıt

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  /// Uygulama ilk açıldığında kendi takma kimliğiyle hesap açar. Kişisel
  /// bilgi alınmaz. Kimlik zaten varsa 409 döner; anahtar yalnızca bir kez
  /// verilir (uygulama telefonda saklar).
  Future<Response> _registerPatient(Request request) async {
    final id = (await _body(request))?['patientId'];
    if (id is! String || !_uuid.hasMatch(id)) {
      return _outcome(400, 'error', 'invalid', 'patientId UUID (v4) olmalı');
    }
    if (store.account(id) != null) {
      return _outcome(409, 'error', 'duplicate', 'Bu kimlikle hesap var');
    }
    final token = _newToken();
    store.addAccount(Account(id: id, role: Role.patient, name: '-'), token);
    final recovery = _issueRecovery(id);
    _audit(id, id, AuditAction.create, true, 'Hesap açıldı');
    return _json(201, {'token': token, 'recoveryCode': recovery});
  }

  String _newToken() => List.generate(
    32,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  // --------------------------------------------------------------- kurtarma

  /// Kurtarma kodu: karışmayan alfabeden 16 karakter (80 bit), dörderli
  /// gruplar halinde. Yalnızca SHA-256 özeti saklanır.
  String _issueRecovery(String accountId) {
    final raw = List.generate(
      16,
      (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
    ).join();
    store.setRecovery(accountId, _recoveryHash(raw));
    return [
      for (var i = 0; i < 16; i += 4) raw.substring(i, i + 4),
    ].join('-');
  }

  /// Boşluk, tire ve küçük harf fark etmez.
  static String _recoveryHash(String code) => crypto.sha256
      .convert(utf8.encode(code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '')))
      .toString();

  /// Kurtarmada dakikada en çok bu kadar hatalı deneme kabul edilir.
  static const recoveryFailuresPerMinute = 10;
  final _recoveryFailures = <DateTime>[];

  /// Hasta yeni kurtarma kodu ister (ör. eskisini kaybetti ya da kodu
  /// olmayan eski bir hesap).
  Response _newRecovery(Request request) {
    final me = _me(request);
    if (me.role != Role.patient) {
      return _outcome(403, 'error', 'forbidden', 'Yalnızca hasta');
    }
    final code = _issueRecovery(me.id);
    _audit(me.id, me.id, AuditAction.update, true, 'Yeni kurtarma kodu');
    return _json(201, {'recoveryCode': code});
  }

  /// Kurtarma koduyla hesabı yeni telefona alır: eski oturum anahtarları ve
  /// kod geçersiz olur, yenileri verilir.
  Future<Response> _recover(Request request) async {
    final now = _now();
    _recoveryFailures.removeWhere(
      (t) => now.difference(t) >= const Duration(minutes: 1),
    );
    if (_recoveryFailures.length >= recoveryFailuresPerMinute) {
      return _outcome(429, 'error', 'throttled', 'Çok fazla deneme; sonra deneyin');
    }
    final code = (await _body(request))?['recoveryCode'];
    final account = code is String && code.length <= 64
        ? store.accountByRecovery(_recoveryHash(code))
        : null;
    if (account == null || account.role != Role.patient) {
      _recoveryFailures.add(now);
      return _outcome(404, 'error', 'not-found', 'Kurtarma kodu geçersiz');
    }
    final token = _newToken();
    store.replaceToken(account.id, token);
    final next = _issueRecovery(account.id);
    _audit(account.id, account.id, AuditAction.update, true, 'Hesap kurtarma koduyla yeni telefona alındı');
    return _json(200, {
      'patientId': account.id,
      'token': token,
      'recoveryCode': next,
    });
  }

  /// Uygulamanın "Bağlantılarım" listesi: süren rızalar ve karşı taraf.
  Response _connections(Request request) {
    final me = _me(request);
    if (me.role != Role.patient) {
      return _outcome(403, 'error', 'forbidden', 'Yalnızca hasta');
    }
    final now = _now();
    final list = [
      for (final c in store.consentsForPatient(me.id))
        if (c.activeAt(now)) c,
    ]..sort((a, b) => b.start.compareTo(a.start));
    return _json(200, [
      for (final c in list)
        if (store.account(c.actorId) case final actor?)
          {
            'id': c.id,
            'code': c.inviteCode,
            'kind': actor.role.name,
            'name': actor.name,
            'organization': actor.organization,
            'verified': actor.verified,
            'purpose': c.purpose,
            'requested': [for (final s in c.requested) s.name],
            'scopes': [for (final s in c.scopes) s.name],
            'since': c.start.toUtc().toIso8601String(),
            'until': c.end.toUtc().toIso8601String(),
          },
    ]);
  }

  // ---------------------------------------------------------- geri bildirim

  /// Geri bildirimde en çok bu kadar karakter.
  static const feedbackMaxLength = 2000;

  /// Anahtarsız uç olduğu için dakikada en çok bu kadar geri bildirim alınır.
  static const feedbackPerMinute = 30;
  final _feedbackTimes = <DateTime>[];

  /// Geri bildirim hesaba bağlanmaz; anahtar istenmez, kimlik saklanmaz.
  Future<Response> _feedback(Request request) async {
    final now = _now();
    _feedbackTimes.removeWhere(
      (t) => now.difference(t) >= const Duration(minutes: 1),
    );
    if (_feedbackTimes.length >= feedbackPerMinute) {
      return _outcome(429, 'error', 'throttled', 'Çok fazla istek; sonra deneyin');
    }
    final body = await _body(request);
    final category = switch (body?['category']) {
      final String c => FeedbackCategory.values.asNameMap()[c],
      _ => null,
    };
    final message = body?['message'];
    if (category == null ||
        message is! String ||
        message.trim().isEmpty ||
        message.length > feedbackMaxLength) {
      return _outcome(
        400,
        'error',
        'invalid',
        'category (bug, idea, other) ve message (1-$feedbackMaxLength) gerekli',
      );
    }
    String? short(Object? v) =>
        v is String && v.isNotEmpty ? (v.length > 40 ? v.substring(0, 40) : v) : null;
    _feedbackTimes.add(now);
    store.addFeedback(
      FeedbackEntry(
        id: store.nextId('feedback'),
        time: now,
        category: category,
        message: message.trim(),
        appVersion: short(body?['appVersion']),
        platform: short(body?['platform']),
        locale: short(body?['locale']),
      ),
    );
    return _outcome(201, 'information', 'informational', 'received');
  }

  // ------------------------------------------------------------ aile grupları

  /// [patientId]'nin, [viewerId] ile ortak gruplarda paylaştığı türler.
  Set<ShareScope> _groupScopes(String patientId, String viewerId) {
    final viewerGroups = {
      for (final m in store.membershipsOf(viewerId)) m.groupId,
    };
    return {
      for (final m in store.membershipsOf(patientId))
        if (viewerGroups.contains(m.groupId)) ...m.scopes,
    };
  }

  String _shortCode() => List.generate(
    6,
    (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
  ).join();

  /// Grup ya da kişiye özel davetle çakışmayan yeni kod.
  String _freeCode() {
    while (true) {
      final c = _shortCode();
      if (store.groupByCode(c) == null && store.memberByInvite(c) == null) {
        return c;
      }
    }
  }

  Response? _patientOnly(Account me) => me.role == Role.patient
      ? null
      : _outcome(403, 'error', 'forbidden', 'Yalnızca hasta');

  /// Hesabın bu gruptaki üyeliği; yoksa null.
  GroupMember? _membership(String groupId, String accountId) => store
      .members(groupId)
      .where((m) => m.accountId == accountId)
      .firstOrNull;

  Map<String, Object?> _groupJson(CareGroupRecord g, String meId) {
    final owner = g.ownerId == meId;
    final members = store.members(g.id)
      ..sort((a, b) {
        if (a.accountId == g.ownerId) return -1;
        if (b.accountId == g.ownerId) return 1;
        return (a.joined ?? g.created).compareTo(b.joined ?? g.created);
      });
    final mine = _membership(g.id, meId);
    return {
      'id': g.id,
      'name': g.name,
      'ownedByMe': owner,
      // Grup kodu yalnızca sahibine gösterilir.
      'inviteCode': owner ? g.code : '',
      'members': [
        for (final m in members)
          {
            'id': m.id,
            'name': m.name,
            'isMe': m.accountId == meId,
            'isOwner': m.accountId == g.ownerId,
            'pending': m.pending,
            // Bekleyen üyenin kişiye özel kodu yalnızca sahibine gider.
            if (owner) 'inviteCode': ?m.inviteCode,
            'shares': [for (final s in m.scopes) s.name],
          },
      ],
      'myConsent': {
        'scopes': [for (final s in mine?.scopes ?? const <ShareScope>{}) s.name],
        'grantedAt': mine?.consentAt?.toUtc().toIso8601String(),
      },
    };
  }

  Response _listGroups(Request request) {
    final me = _me(request);
    if (_patientOnly(me) case final r?) return r;
    final groups = [
      for (final m in store.membershipsOf(me.id)) ?store.group(m.groupId),
    ]..sort((a, b) => a.created.compareTo(b.created));
    // Sahibi olunan gruplara katılanlar bildirim olarak gelir.
    final messages = [
      for (final g in groups)
        if (g.ownerId == me.id)
          for (final m in store.members(g.id))
            if (m.joined != null && m.accountId != me.id)
              {
                'id': 'joined-${m.id}',
                'kind': 'memberJoined',
                'from': m.name,
                'groupId': g.id,
                'groupName': g.name,
                'time': m.joined!.toUtc().toIso8601String(),
              },
    ];
    return _json(200, {
      'groups': [for (final g in groups) _groupJson(g, me.id)],
      'messages': messages,
    });
  }

  Future<Response> _createGroup(Request request) async {
    final me = _me(request);
    if (_patientOnly(me) case final r?) return r;
    final name = (await _body(request))?['name'];
    if (name is! String || name.trim().isEmpty || name.trim().length > 40) {
      return _outcome(400, 'error', 'invalid', 'name (1-40) gerekli');
    }
    final now = _now();
    final g = CareGroupRecord(
      id: store.nextId('group'),
      name: name.trim(),
      ownerId: me.id,
      code: _freeCode(),
      created: now,
    );
    store
      ..addGroup(g)
      ..putMember(
        GroupMember(
          id: store.nextId('member'),
          groupId: g.id,
          name: '',
          accountId: me.id,
          joined: now,
        ),
      );
    return _json(201, _groupJson(g, me.id));
  }

  Future<Response> _inviteMember(Request request, String id) async {
    final me = _me(request);
    final g = store.group(id);
    if (g == null || g.ownerId != me.id) {
      return _outcome(404, 'error', 'not-found', 'Grup bulunamadı');
    }
    final name = (await _body(request))?['name'];
    if (name is! String || name.trim().isEmpty || name.trim().length > 40) {
      return _outcome(400, 'error', 'invalid', 'name (1-40) gerekli');
    }
    final code = _freeCode();
    store.putMember(
      GroupMember(
        id: store.nextId('member'),
        groupId: g.id,
        name: name.trim(),
        inviteCode: code,
      ),
    );
    return _json(201, {'code': code});
  }

  Future<Response> _joinGroup(Request request) async {
    final me = _me(request);
    if (_patientOnly(me) case final r?) return r;
    final raw = (await _body(request))?['code'];
    final code = raw is String ? raw.trim().toUpperCase() : '';
    final invited = code.isEmpty ? null : store.memberByInvite(code);
    final g = invited != null
        ? store.group(invited.groupId)
        : code.isEmpty
        ? null
        : store.groupByCode(code);
    if (g == null) {
      return _outcome(404, 'error', 'not-found', 'Kod geçersiz');
    }
    if (_membership(g.id, me.id) == null) {
      final now = _now();
      store.putMember(
        invited?.copyWith(accountId: me.id, joined: now, clearInvite: true) ??
            GroupMember(
              id: store.nextId('member'),
              groupId: g.id,
              name: '',
              accountId: me.id,
              joined: now,
            ),
      );
    }
    return _json(200, _groupJson(g, me.id));
  }

  Response _removeMember(Request request, String id, String mid) {
    final me = _me(request);
    final g = store.group(id);
    final member = store.members(id).where((m) => m.id == mid).firstOrNull;
    if (g == null || g.ownerId != me.id || member == null) {
      return _outcome(404, 'error', 'not-found', 'Üye bulunamadı');
    }
    if (member.accountId == me.id) {
      return _outcome(400, 'error', 'invalid', 'Sahip kendini çıkaramaz; grubu siler');
    }
    store.removeMember(member.id);
    if (member.accountId case final a? when member.scopes.isNotEmpty) {
      _audit(me.id, a, AuditAction.update, true, 'Gruptan çıkarıldı, paylaşım bitti: ${g.id}');
    }
    return _json(200, _groupJson(g, me.id));
  }

  Future<Response> _groupConsent(Request request, String id) async {
    final me = _me(request);
    final g = store.group(id);
    final mine = g == null ? null : _membership(g.id, me.id);
    if (g == null || mine == null) {
      return _outcome(404, 'error', 'not-found', 'Grup bulunamadı');
    }
    final scopes = _scopes((await _body(request))?['scopes']);
    if (scopes == null) {
      return _outcome(400, 'error', 'invalid', 'scopes listesi gerekli');
    }
    store.putMember(mine.copyWith(scopes: scopes, consentAt: _now()));
    _audit(
      me.id,
      me.id,
      AuditAction.update,
      true,
      scopes.isEmpty
          ? 'Grup paylaşımı kapatıldı: ${g.id}'
          : 'Grup paylaşımı: ${g.id} (${scopes.map((s) => s.name).join(', ')})',
    );
    return _json(200, _groupJson(g, me.id));
  }

  Response _leaveGroup(Request request, String id) {
    final me = _me(request);
    final g = store.group(id);
    final mine = g == null ? null : _membership(g.id, me.id);
    if (g == null || mine == null) {
      return _outcome(404, 'error', 'not-found', 'Grup bulunamadı');
    }
    if (g.ownerId == me.id) {
      for (final m in store.members(g.id)) {
        if (m.accountId case final a? when m.scopes.isNotEmpty) {
          _audit(me.id, a, AuditAction.update, true, 'Grup silindi, paylaşım bitti: ${g.id}');
        }
      }
      store.deleteGroup(g.id);
    } else {
      store.removeMember(mine.id);
      if (mine.scopes.isNotEmpty) {
        _audit(me.id, me.id, AuditAction.update, true, 'Gruptan ayrıldı, paylaşım bitti: ${g.id}');
      }
    }
    return _json(200, {'left': g.id});
  }

  // ---------------------------------------------------------------- yükleme

  Future<Response> _ingest(Request request) async {
    final me = _me(request);
    if (me.role != Role.patient) {
      return _outcome(403, 'error', 'forbidden', 'Yalnızca hasta veri yükler');
    }
    final IngestResult result;
    try {
      result = parseBundle(jsonDecode(await request.readAsString()), me.id);
    } on FormatException catch (e) {
      _audit(me.id, me.id, AuditAction.create, false, 'Bundle reddedildi: ${e.message}');
      return _outcome(400, 'error', 'invalid', e.message);
    }
    var created = 0;
    for (final o in result.observations) {
      if (store.addObservation(o)) created++;
    }
    // Yeni veri hekimlerin uyarı kurallarından geçer; uyarı veri geldiği
    // anda açılır, yanıt süresi buradan ölçülür.
    if (created > 0) AlertEngine(store).scan(_now(), patientId: me.id);
    final duplicates = result.observations.length - created;
    final summary =
        'created=$created duplicates=$duplicates rejected=${result.rejected.length}';
    _audit(me.id, me.id, AuditAction.create, true, summary);
    return _json(200, {
      'resourceType': 'OperationOutcome',
      'issue': [
        {'severity': 'information', 'code': 'informational', 'diagnostics': summary},
        for (final r in result.rejected)
          {
            'severity': 'warning',
            'code': 'invalid',
            'diagnostics': r.reason,
            'expression': ['Bundle.entry[${r.index}]'],
          },
      ],
    });
  }

  // ------------------------------------------------------------------ arama

  Response _searchObservations(Request request) {
    final me = _me(request);
    final q = request.url.queryParametersAll;
    final patientId = q['patient']?.firstOrNull;
    if (patientId == null || patientId.isEmpty) {
      return _outcome(400, 'error', 'required', 'patient parametresi gerekli');
    }
    // Hasta kendi verisinin tamamını görür; takipçi yalnızca süren
    // rızalarındaki türleri.
    Set<String>? allowed;
    if (!(me.role == Role.patient && me.id == patientId)) {
      final now = _now();
      allowed = {
        for (final c in store.consentsForPatient(patientId))
          if (c.actorId == me.id && c.activeAt(now)) ...c.codes,
        // Aynı aile grubundaki üye, hastanın o grupla paylaştığı türleri görür.
        for (final s in _groupScopes(patientId, me.id)) ...s.codes,
      };
      if (allowed.isEmpty) {
        _audit(me.id, patientId, AuditAction.read, false, 'Rıza olmadan erişim denemesi');
        return _outcome(403, 'error', 'forbidden', 'Bu hastanın rızası yok');
      }
    }
    final requested = q['code']
        ?.expand((v) => v.split(','))
        .where((v) => v.isNotEmpty)
        .toSet();
    final codes = switch ((allowed, requested)) {
      (null, null) => null,
      (null, final r?) => r,
      (final a?, null) => a,
      (final a?, final r?) => a.intersection(r),
    };
    DateTime? from;
    DateTime? to;
    for (final d in q['date'] ?? const <String>[]) {
      final at = d.length > 2 ? DateTime.tryParse(d.substring(2)) : null;
      if (at == null) {
        return _outcome(400, 'error', 'invalid', 'date: ge<zaman> ya da le<zaman>');
      }
      switch (d.substring(0, 2)) {
        case 'ge' || 'gt':
          from = at;
        case 'le' || 'lt':
          to = at;
        default:
          return _outcome(400, 'error', 'invalid', 'date: ge<zaman> ya da le<zaman>');
      }
    }
    final found = store.observations(patientId, codes: codes, from: from, to: to);
    if (me.id != patientId) {
      _audit(me.id, patientId, AuditAction.read, true, '${found.length} ölçüm okundu');
    }
    return _json(200, _searchset([for (final o in found) o.resource]));
  }

  Response _searchConsents(Request request) {
    final me = _me(request);
    final now = _now();
    final list = me.role == Role.patient
        ? store.consentsForPatient(me.id)
        : store.consentsForActor(me.id);
    return _json(200, _searchset([for (final c in list) c.toFhir(now)]));
  }

  Response _searchAudit(Request request) {
    final me = _me(request);
    if (me.role != Role.patient) {
      return _outcome(403, 'error', 'forbidden', 'Erişim kayıtlarını yalnızca hasta görür');
    }
    return _json(200, _searchset([for (final e in store.auditForPatient(me.id)) e.toFhir()]));
  }

  // ----------------------------------------------------------- davet, rıza

  Future<Response> _createInvite(Request request) async {
    final me = _me(request);
    if (me.role != Role.clinician && me.role != Role.researcher) {
      return _outcome(403, 'error', 'forbidden', 'Davet yalnızca hekim ya da araştırmacı oluşturur');
    }
    final body = await _body(request);
    final purpose = body?['purpose'];
    final scopes = _scopes(body?['scopes']);
    final days = body?['days'];
    if (purpose is! String || purpose.trim().isEmpty || scopes == null || scopes.isEmpty || days is! int || days < 1 || days > 730) {
      return _outcome(400, 'error', 'invalid', 'purpose, scopes ve days (1-730) gerekli');
    }
    final code = List.generate(
      7,
      (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
    ).join();
    final invite = Invite(
      code: code,
      actorId: me.id,
      purpose: purpose.trim(),
      requested: scopes,
      duration: Duration(days: days),
      // Kod 30 gün kullanılabilir.
      expires: _now().add(const Duration(days: 30)),
    );
    store.addInvite(invite);
    return _json(201, _inviteJson(invite, me));
  }

  Invite? _liveInvite(String code) {
    final invite = store.invite(code.trim().toUpperCase());
    if (invite == null || !_now().isBefore(invite.expires)) return null;
    return invite;
  }

  Response _getInvite(Request request, String code) {
    if (_me(request).role != Role.patient) {
      return _outcome(403, 'error', 'forbidden', 'Daveti hasta açar');
    }
    final invite = _liveInvite(code);
    final actor = invite == null ? null : store.account(invite.actorId);
    if (invite == null || actor == null) {
      return _outcome(404, 'error', 'not-found', 'Kod geçersiz ya da süresi dolmuş');
    }
    return _json(200, _inviteJson(invite, actor));
  }

  Future<Response> _acceptInvite(Request request, String code) async {
    final me = _me(request);
    if (me.role != Role.patient) {
      return _outcome(403, 'error', 'forbidden', 'Daveti hasta kabul eder');
    }
    final invite = _liveInvite(code);
    if (invite == null) {
      return _outcome(404, 'error', 'not-found', 'Kod geçersiz ya da süresi dolmuş');
    }
    final scopes = _scopes((await _body(request))?['scopes']);
    if (scopes == null || scopes.isEmpty || !invite.requested.containsAll(scopes)) {
      return _outcome(400, 'error', 'invalid', 'scopes istenen türlerden en az biri olmalı');
    }
    final now = _now();
    // Aynı takipçiye verilmiş eski rıza yenisiyle değişir.
    for (final old in store.consentsForPatient(me.id)) {
      if (old.actorId == invite.actorId && old.activeAt(now)) {
        store.revokeConsent(old.id, now);
      }
    }
    final consent = Consent(
      id: store.nextId('consent'),
      patientId: me.id,
      actorId: invite.actorId,
      scopes: scopes,
      start: now,
      end: now.add(invite.duration),
      purpose: invite.purpose,
      inviteCode: invite.code,
      requested: invite.requested,
    );
    store.addConsent(consent);
    // Hekim bu daveti bir hasta kaydı için ürettiyse kayıt bilekliğe bağlanır.
    final owned = store.recordsOf(invite.actorId);
    if (owned.where((r) => r.inviteCode == invite.code).firstOrNull
        case final rec?) {
      for (final other in owned) {
        if (other.id != rec.id && other.patientId == me.id) {
          store.putRecord(other.copyWith(clearPatient: true));
        }
      }
      store.putRecord(rec.copyWith(patientId: me.id, clearInvite: true));
    }
    _audit(
      me.id,
      me.id,
      AuditAction.update,
      true,
      'Rıza verildi: ${invite.actorId} (${scopes.map((s) => s.name).join(', ')})',
    );
    return _json(201, consent.toFhir(now));
  }

  Response _revokeConsent(Request request, String id) {
    final me = _me(request);
    final consent = store.consent(id);
    if (consent == null || consent.patientId != me.id) {
      return _outcome(404, 'error', 'not-found', 'Rıza bulunamadı');
    }
    final now = _now();
    store.revokeConsent(consent.id, now);
    _audit(me.id, me.id, AuditAction.update, true, 'Rıza geri alındı: ${consent.actorId}');
    return _json(200, consent.toFhir(now));
  }

  /// Unutulma hakkı: ölçümler silinir, rızalar sona erer. Erişim kayıtları
  /// yasal saklama yükümlülüğü nedeniyle silinmez.
  Response _erase(Request request, String id) {
    final me = _me(request);
    if (me.role != Role.patient || me.id != id) {
      return _outcome(403, 'error', 'forbidden', 'Yalnızca hasta kendi verisini siler');
    }
    final now = _now();
    final count = store.deleteObservations(id);
    store.deleteAlertsFor(id);
    for (final c in store.consentsForPatient(id)) {
      store.revokeConsent(c.id, now);
    }
    for (final m in store.membershipsOf(id)) {
      if (m.scopes.isNotEmpty) {
        store.putMember(m.copyWith(scopes: const {}, consentAt: now));
      }
    }
    _audit(me.id, id, AuditAction.delete, true, '$count ölçüm silindi');
    return _outcome(200, 'information', 'informational', 'deleted=$count');
  }

  // -------------------------------------------------------------- yardımcı

  Map<String, Object?> _inviteJson(Invite i, Account actor) => {
    'code': i.code,
    'kind': actor.role.name,
    'name': actor.name,
    'organization': actor.organization,
    'specialty': actor.specialty,
    // Kendi kaydolan ve henüz doğrulanmamış hesapta false; uygulama uyarır.
    'verified': actor.verified,
    'purpose': i.purpose,
    'requested': [for (final s in i.requested) s.name],
    'durationDays': i.duration.inDays,
    'expires': i.expires.toUtc().toIso8601String(),
  };

  static Set<ShareScope>? _scopes(Object? raw) {
    if (raw is! List) return null;
    final out = <ShareScope>{};
    for (final v in raw) {
      final s = v is String ? ShareScope.byName(v) : null;
      if (s == null) return null;
      out.add(s);
    }
    return out;
  }

  static Future<Map<String, Object?>?> _body(Request request) async {
    try {
      final json = jsonDecode(await request.readAsString());
      return json is Map<String, Object?> ? json : null;
    } on FormatException {
      return null;
    }
  }

  void _audit(
    String actorId,
    String patientId,
    AuditAction action,
    bool success,
    String description,
  ) => store.addAudit(
    AuditEntry(
      id: store.nextId('audit'),
      time: _now(),
      actorId: actorId,
      patientId: patientId,
      action: action,
      success: success,
      description: description,
    ),
  );

  static Map<String, Object?> _searchset(List<Map<String, Object?>> resources) => {
    'resourceType': 'Bundle',
    'type': 'searchset',
    'total': resources.length,
    'entry': [
      for (final r in resources)
        {
          'resource': r,
          'search': {'mode': 'match'},
        },
    ],
  };

  static Response _json(int status, Object body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': fhirJson},
  );

  static Response _outcome(
    int status,
    String severity,
    String code,
    String diagnostics,
  ) => _json(status, {
    'resourceType': 'OperationOutcome',
    'issue': [
      {'severity': severity, 'code': code, 'diagnostics': diagnostics},
    ],
  });
}
