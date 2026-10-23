import 'model.dart';

/// Portalın deposu: bellekte ([MemoryPortalStore], demo ve testler) ya da
/// şifreli dosyada (`EncryptedPortalStore`).
abstract class PortalStore {
  /// Hesap ve oturum anahtarı ekler.
  void addAccount(Account a, String token);

  Account? accountByToken(String token);
  Account? account(String id);

  /// Kayıt yeniyse ekler ve true döner; aynı kimlikle daha önce geldiyse false.
  bool addObservation(StoredObservation o);

  List<StoredObservation> observations(
    String patientId, {
    Set<String>? codes,
    DateTime? from,
    DateTime? to,
  });

  /// Hastanın tüm ölçümlerini siler; silinen sayısını döner.
  int deleteObservations(String patientId);

  void addConsent(Consent c);

  /// Rızayı [at] anında sona erdirir; zaten bittiyse değiştirmez.
  void revokeConsent(String id, DateTime at);
  Consent? consent(String id);
  List<Consent> consentsForPatient(String patientId);
  List<Consent> consentsForActor(String actorId);

  void addInvite(Invite i);
  Invite? invite(String code);
  void removeInvite(String code);

  void addAudit(AuditEntry e);
  List<AuditEntry> auditForPatient(String patientId);

  /// Yeni kayıtlar için benzersiz kimlik.
  String nextId(String prefix);
}

class MemoryPortalStore implements PortalStore {
  MemoryPortalStore({
    Map<String, Account> tokens = const {},
  }) : _tokens = {...tokens} {
    for (final a in tokens.values) {
      _accounts[a.id] = a;
    }
  }

  final Map<String, Account> _tokens;
  final _accounts = <String, Account>{};
  final _observations = <String, Map<String, StoredObservation>>{};
  final _consents = <String, Consent>{};
  final _invites = <String, Invite>{};
  final _audit = <AuditEntry>[];
  var _seq = 0;

  @override
  void addAccount(Account a, String token) {
    _accounts[a.id] = a;
    _tokens[token] = a;
  }

  @override
  Account? accountByToken(String token) => _tokens[token];

  @override
  Account? account(String id) => _accounts[id];

  @override
  bool addObservation(StoredObservation o) {
    final byId = _observations.putIfAbsent(o.patientId, () => {});
    if (byId.containsKey(o.identifier)) return false;
    byId[o.identifier] = o;
    return true;
  }

  @override
  List<StoredObservation> observations(
    String patientId, {
    Set<String>? codes,
    DateTime? from,
    DateTime? to,
  }) {
    final list = [
      for (final o in (_observations[patientId] ?? const {}).values)
        if ((codes == null || codes.contains(o.code)) &&
            (from == null || !o.effective.isBefore(from)) &&
            (to == null || !o.effective.isAfter(to)))
          o,
    ]..sort((a, b) => a.effective.compareTo(b.effective));
    return list;
  }

  @override
  int deleteObservations(String patientId) =>
      _observations.remove(patientId)?.length ?? 0;

  @override
  void addConsent(Consent c) => _consents[c.id] = c;

  @override
  void revokeConsent(String id, DateTime at) => _consents[id]?.revokedAt ??= at;

  @override
  Consent? consent(String id) => _consents[id];

  @override
  List<Consent> consentsForPatient(String patientId) => [
    for (final c in _consents.values)
      if (c.patientId == patientId) c,
  ];

  @override
  List<Consent> consentsForActor(String actorId) => [
    for (final c in _consents.values)
      if (c.actorId == actorId) c,
  ];

  @override
  void addInvite(Invite i) => _invites[i.code] = i;

  @override
  Invite? invite(String code) => _invites[code];

  @override
  void removeInvite(String code) => _invites.remove(code);

  @override
  void addAudit(AuditEntry e) => _audit.add(e);

  @override
  List<AuditEntry> auditForPatient(String patientId) => [
    for (final e in _audit.reversed)
      if (e.patientId == patientId) e,
  ];

  @override
  String nextId(String prefix) => '$prefix-${++_seq}';
}
