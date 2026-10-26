import 'model.dart';

/// Portalın deposu: bellekte ([MemoryPortalStore], demo ve testler) ya da
/// şifreli dosyada (`EncryptedPortalStore`).
abstract class PortalStore {
  /// Hesap ve oturum anahtarı ekler.
  void addAccount(Account a, String token);

  Account? accountByToken(String token);
  Account? account(String id);

  /// E-postası verilen hesap (küçük harfle karşılaştırılır).
  Account? accountByEmail(String email);

  /// Hekim ve araştırma kurumu hesapları.
  List<Account> clinicians();

  /// Hesabın bilgilerini değiştirir (ör. doğrulama); oturum anahtarları kalır.
  void updateAccount(Account a);

  /// Şifre özetini ([passwordHash] biçimi) hesaba bağlar.
  void setPassword(String accountId, String passwordHash);
  String? passwordOf(String accountId);

  /// Hesabın tüm eski oturum anahtarlarını geçersiz kılar, [token]'ı ekler.
  void replaceToken(String accountId, String token);

  /// Kurtarma kodunun özetini ([recoveryHash]) hesaba bağlar; eskisi geçersiz
  /// olur.
  void setRecovery(String accountId, String recoveryHash);

  /// Özeti verilen kurtarma kodunun hesabı.
  Account? accountByRecovery(String recoveryHash);

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

  void addGroup(CareGroupRecord g);
  CareGroupRecord? group(String id);
  CareGroupRecord? groupByCode(String code);

  /// Grubu ve tüm üyeliklerini siler.
  void deleteGroup(String id);

  /// Üyeliği ekler ya da aynı kimlikliyi değiştirir.
  void putMember(GroupMember m);
  void removeMember(String memberId);
  List<GroupMember> members(String groupId);
  GroupMember? memberByInvite(String code);

  /// Hesabın katıldığı (ya da sahibi olduğu) grupların üyelikleri.
  List<GroupMember> membershipsOf(String accountId);

  void addFeedback(FeedbackEntry f);
  List<FeedbackEntry> feedback();

  /// Sitedeki iş birliği formundan gelen başvurular.
  void addInquiry(Inquiry i);
  List<Inquiry> inquiries();

  /// Hasta kaydını ekler ya da aynı kimlikliyi değiştirir.
  void putRecord(PatientRecord r);
  PatientRecord? record(String id);

  /// Hekimin kayıtları, yeniden eskiye.
  List<PatientRecord> recordsOf(String ownerId);

  /// Kaydı siler (bileklik verisine dokunmaz).
  void deleteRecord(String id);

  /// Uyarıyı ekler ya da aynı kimlikliyi değiştirir.
  void putAlert(Alert a);
  Alert? alert(String id);

  /// Hekimin uyarıları, yeniden eskiye.
  List<Alert> alertsOf(String ownerId);

  /// Hastanın uyarılarını siler (unutulma hakkı).
  void deleteAlertsFor(String patientId);

  /// Yeni kayıtlar için benzersiz kimlik.
  String nextId(String prefix);
}

class MemoryPortalStore implements PortalStore {
  MemoryPortalStore({Map<String, Account> tokens = const {}})
    : _tokens = {...tokens} {
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
  final _feedback = <FeedbackEntry>[];
  final _inquiries = <Inquiry>[];
  final _recovery = <String, String>{}; // özet -> hesap
  final _groups = <String, CareGroupRecord>{};
  final _members = <String, GroupMember>{};
  final _passwords = <String, String>{};
  final _records = <String, PatientRecord>{};
  final _alerts = <String, Alert>{};
  var _seq = 0;

  @override
  void putAlert(Alert a) => _alerts[a.id] = a;

  @override
  Alert? alert(String id) => _alerts[id];

  @override
  List<Alert> alertsOf(String ownerId) => [
    for (final a in _alerts.values)
      if (a.ownerId == ownerId) a,
  ]..sort((a, b) => b.created.compareTo(a.created));

  @override
  void deleteAlertsFor(String patientId) =>
      _alerts.removeWhere((_, a) => a.patientId == patientId);

  @override
  Account? accountByEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return null;
    return _accounts.values.where((a) => a.email == e).firstOrNull;
  }

  @override
  List<Account> clinicians() => [
    for (final a in _accounts.values)
      if (a.role == Role.clinician || a.role == Role.researcher) a,
  ];

  @override
  void updateAccount(Account a) {
    if (!_accounts.containsKey(a.id)) return;
    _accounts[a.id] = a;
    for (final e in _tokens.entries.toList()) {
      if (e.value.id == a.id) _tokens[e.key] = a;
    }
  }

  @override
  void setPassword(String accountId, String passwordHash) =>
      _passwords[accountId] = passwordHash;

  @override
  String? passwordOf(String accountId) => _passwords[accountId];

  @override
  void putRecord(PatientRecord r) => _records[r.id] = r;

  @override
  PatientRecord? record(String id) => _records[id];

  @override
  List<PatientRecord> recordsOf(String ownerId) => [
    for (final r in _records.values)
      if (r.ownerId == ownerId) r,
  ]..sort((a, b) => b.created.compareTo(a.created));

  @override
  void deleteRecord(String id) => _records.remove(id);

  @override
  void addAccount(Account a, String token) {
    _accounts[a.id] = a;
    _tokens[token] = a;
  }

  @override
  Account? accountByToken(String token) => _tokens[token];

  @override
  void replaceToken(String accountId, String token) {
    final a = _accounts[accountId];
    if (a == null) return;
    _tokens
      ..removeWhere((_, v) => v.id == accountId)
      ..[token] = a;
  }

  @override
  void setRecovery(String accountId, String recoveryHash) {
    _recovery
      ..removeWhere((_, id) => id == accountId)
      ..[recoveryHash] = accountId;
  }

  @override
  Account? accountByRecovery(String recoveryHash) =>
      switch (_recovery[recoveryHash]) {
        null => null,
        final id => _accounts[id],
      };

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
  void addGroup(CareGroupRecord g) => _groups[g.id] = g;

  @override
  CareGroupRecord? group(String id) => _groups[id];

  @override
  CareGroupRecord? groupByCode(String code) =>
      _groups.values.where((g) => g.code == code).firstOrNull;

  @override
  void deleteGroup(String id) {
    _groups.remove(id);
    _members.removeWhere((_, m) => m.groupId == id);
  }

  @override
  void putMember(GroupMember m) => _members[m.id] = m;

  @override
  void removeMember(String memberId) => _members.remove(memberId);

  @override
  List<GroupMember> members(String groupId) => [
    for (final m in _members.values)
      if (m.groupId == groupId) m,
  ];

  @override
  GroupMember? memberByInvite(String code) =>
      _members.values.where((m) => m.inviteCode == code).firstOrNull;

  @override
  List<GroupMember> membershipsOf(String accountId) => [
    for (final m in _members.values)
      if (m.accountId == accountId) m,
  ];

  @override
  void addFeedback(FeedbackEntry f) => _feedback.add(f);

  @override
  List<FeedbackEntry> feedback() => List.unmodifiable(_feedback);

  @override
  void addInquiry(Inquiry i) => _inquiries.add(i);

  @override
  List<Inquiry> inquiries() => List.unmodifiable(_inquiries);

  @override
  String nextId(String prefix) => '$prefix-${++_seq}';
}
