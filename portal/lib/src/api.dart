import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ingest.dart';
import 'model.dart';
import 'store.dart';

/// Portalın HTTP API'si.
///
/// | Yol | Kim | Ne yapar |
/// | --- | --- | --- |
/// | `POST /fhir` | hasta | Uygulamanın FHIR Bundle'ını alır |
/// | `GET /fhir/Observation?patient=&code=&date=` | hasta, rızalı takipçi | Ölçümleri arar |
/// | `GET /fhir/Consent` | hasta, takipçi | Rızaları listeler |
/// | `GET /fhir/AuditEvent` | hasta | Verisine kimin eriştiğini gösterir (KVKK) |
/// | `POST /invites` | hekim, araştırmacı | Davet kodu üretir |
/// | `GET /invites/<code>` | hasta | Davetin içeriğini gösterir |
/// | `POST /invites/<code>/accept` | hasta | Açık rızayla bağlanır |
/// | `DELETE /consents/<id>` | hasta | Rızayı geri alır |
/// | `DELETE /patients/<id>/data` | hasta | Ölçümlerini siler (unutulma hakkı) |
///
/// Kimlik doğrulama iskelette `Authorization: Bearer <anahtar>` ile; gerçek
/// giriş akışı (e-Devlet/OAuth) sonra eklenecek.
class PortalApi {
  PortalApi(this.store, {DateTime Function()? clock, Random? random})
    : _now = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final PortalStore store;
  final DateTime Function() _now;
  final Random _random;

  static const fhirJson = 'application/fhir+json';

  /// Davet kodunda karışmayan harf ve rakamlar (0/O, 1/I yok).
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Handler get handler =>
      const Pipeline().addMiddleware(_authenticate).addHandler(_router.call);

  late final Router _router = Router()
    ..get('/health', (Request _) => Response.ok('ok'))
    ..post('/fhir', _ingest)
    ..get('/fhir/Observation', _searchObservations)
    ..get('/fhir/Consent', _searchConsents)
    ..get('/fhir/AuditEvent', _searchAudit)
    ..post('/invites', _createInvite)
    ..get('/invites/<code>', _getInvite)
    ..post('/invites/<code>/accept', _acceptInvite)
    ..delete('/consents/<id>', _revokeConsent)
    ..delete('/patients/<id>/data', _erase);

  Handler _authenticate(Handler inner) => (request) {
    if (request.url.path == 'health') return inner(request);
    final header = request.headers['authorization'] ?? '';
    final token = header.startsWith('Bearer ') ? header.substring(7) : '';
    final account = store.accountByToken(token);
    if (account == null) {
      return _outcome(401, 'error', 'login', 'Geçerli bir oturum anahtarı gerekli');
    }
    return inner(request.change(context: {'account': account}));
  };

  static Account _me(Request r) => r.context['account']! as Account;

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
      if (old.actorId == invite.actorId && old.activeAt(now)) old.revokedAt = now;
    }
    final consent = Consent(
      id: store.nextId('consent'),
      patientId: me.id,
      actorId: invite.actorId,
      scopes: scopes,
      start: now,
      end: now.add(invite.duration),
      purpose: invite.purpose,
    );
    store.addConsent(consent);
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
    consent.revokedAt ??= now;
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
    for (final c in store.consentsForPatient(id)) {
      c.revokedAt ??= now;
    }
    _audit(me.id, id, AuditAction.delete, true, '$count ölçüm silindi');
    return _outcome(200, 'information', 'informational', 'deleted=$count');
  }

  // -------------------------------------------------------------- yardımcı

  Map<String, Object?> _inviteJson(Invite i, Account actor) => {
    'code': i.code,
    'kind': actor.role.name,
    'name': actor.name,
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
