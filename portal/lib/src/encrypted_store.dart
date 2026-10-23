import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import 'model.dart';
import 'store.dart';

/// Oturum anahtarının saklanan özeti (SHA-256). Anahtarın kendisi diske
/// yazılmaz; dosya çalınsa bile anahtarla giriş yapılamaz.
String tokenHash(String token) =>
    crypto.sha256.convert(utf8.encode(token)).toString();

/// Kalıcı ve şifreli depo.
///
/// Her değişiklik bir olay olarak dosyaya eklenir; her satır AES-256-GCM ile
/// ayrı şifrelenir (rastgele 12 baytlık nonce + şifreli metin + 16 baytlık
/// doğrulama etiketi, base64). Açılışta tüm satırlar çözülüp durum bellekte
/// yeniden kurulur; okumalar bellekten yapılır.
///
/// - Anahtar dosyada değil, ortam değişkeninde durur (`PORTAL_KEY`).
/// - Oturum anahtarlarının yalnızca SHA-256 özeti saklanır.
/// - Hasta verisini silince (unutulma hakkı) dosya, o hastanın ölçümleri
///   olmadan baştan yazılır; silinen veri şifreli halde bile diskte kalmaz.
/// - Yanlış anahtar ya da bozuk satır açılışta hata verir; sessizce veri
///   kaybedilmez.
///
/// Pilot için tek dosya yeterli; çok kullanıcılı üretimde aynı arayüzün
/// arkasına PostgreSQL gelebilir.
class EncryptedPortalStore implements PortalStore {
  EncryptedPortalStore._(this._file, this._key, {Random? random})
    : _random = random ?? Random.secure();

  final File _file;
  final SecretKey _key;
  final Random _random;
  final _mem = MemoryPortalStore();

  /// Dosyadaki olaylar (çözülmüş). Yeniden yazmada kullanılır.
  final _events = <Map<String, Object?>>[];

  Future<void> _pending = Future.value();

  static final _cipher = AesGcm.with256bits();
  static const _aad = [0x62, 0x6B, 0x2D, 0x70, 0x31]; // "bk-p1"

  /// Yeni 32 baytlık anahtar, base64 (`dart run bin/server.dart --new-key`).
  static String newKey() {
    final r = Random.secure();
    return base64.encode(List.generate(32, (_) => r.nextInt(256)));
  }

  /// [file] yoksa boş depo açılır. [key] 32 bayt olmalı.
  static Future<EncryptedPortalStore> open(
    File file,
    List<int> key, {
    Random? random,
  }) async {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', '32 bayt olmalı');
    }
    final store = EncryptedPortalStore._(file, SecretKey(key), random: random);
    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().isEmpty) continue;
        final Map<String, Object?> event;
        try {
          event = await store._decrypt(lines[i]);
        } catch (e) {
          throw StateError(
            'Portal deposu çözülemedi (satır ${i + 1}): anahtar yanlış ya da '
            'dosya bozuk',
          );
        }
        store._apply(event);
        store._events.add(event);
      }
    }
    return store;
  }

  /// Bekleyen yazımlar bitince tamamlanır.
  Future<void> flush() => _pending;

  /// Dosyadaki olay sayısı (yeniden yazmadan sonra azalır).
  int get eventCount => _events.length;

  Future<String> _encrypt(Map<String, Object?> event) async {
    final nonce = List.generate(12, (_) => _random.nextInt(256));
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(event)),
      secretKey: _key,
      nonce: nonce,
      aad: _aad,
    );
    return base64.encode(box.concatenation());
  }

  Future<Map<String, Object?>> _decrypt(String line) async {
    final box = SecretBox.fromConcatenation(
      base64.decode(line.trim()),
      nonceLength: 12,
      macLength: 16,
    );
    final clear = await _cipher.decrypt(box, secretKey: _key, aad: _aad);
    return (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>();
  }

  /// Olayı belleğe uygular ve dosyaya ekler.
  void _record(Map<String, Object?> event) {
    _apply(event);
    _events.add(event);
    _pending = _pending.then((_) async {
      final line = await _encrypt(event);
      await _file.parent.create(recursive: true);
      await _file.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    });
  }

  /// Dosyayı bellekteki olaylardan baştan yazar (geçici dosya + yeniden ad).
  void _rewrite() {
    final snapshot = [..._events];
    _pending = _pending.then((_) async {
      final buffer = StringBuffer();
      for (final e in snapshot) {
        buffer.writeln(await _encrypt(e));
      }
      await _file.parent.create(recursive: true);
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(buffer.toString(), flush: true);
      await tmp.rename(_file.path);
    });
  }

  // ------------------------------------------------------------- olaylar

  static String _time(DateTime t) => t.toUtc().toIso8601String();
  static DateTime _parse(Object? t) => DateTime.parse(t! as String);
  static Set<ShareScope> _scopes(Object? raw) => {
    for (final s in raw! as List) ?ShareScope.byName(s as String),
  };

  void _apply(Map<String, Object?> e) {
    switch (e['t']) {
      case 'account':
        _mem.addAccount(
          Account(
            id: e['id']! as String,
            role: Role.values.byName(e['role']! as String),
            name: e['name']! as String,
            organization: e['org'] as String?,
          ),
          e['tokenHash']! as String,
        );
      case 'obs':
        _mem.addObservation(
          StoredObservation(
            patientId: e['patientId']! as String,
            identifier: e['identifier']! as String,
            code: e['code']! as String,
            effective: _parse(e['effective']),
            resource: (e['resource']! as Map).cast<String, Object?>(),
          ),
        );
      case 'consent':
        _mem.addConsent(
          Consent(
            id: e['id']! as String,
            patientId: e['patientId']! as String,
            actorId: e['actorId']! as String,
            scopes: _scopes(e['scopes']),
            requested: _scopes(e['requested']),
            start: _parse(e['start']),
            end: _parse(e['end']),
            purpose: e['purpose'] as String?,
            inviteCode: e['inviteCode'] as String?,
          ),
        );
      case 'revoke':
        _mem.revokeConsent(e['id']! as String, _parse(e['at']));
      case 'invite':
        _mem.addInvite(
          Invite(
            code: e['code']! as String,
            actorId: e['actorId']! as String,
            purpose: e['purpose']! as String,
            requested: _scopes(e['requested']),
            duration: Duration(seconds: e['seconds']! as int),
            expires: _parse(e['expires']),
          ),
        );
      case 'inviteDel':
        _mem.removeInvite(e['code']! as String);
      case 'audit':
        _mem.addAudit(
          AuditEntry(
            id: e['id']! as String,
            time: _parse(e['time']),
            actorId: e['actorId']! as String,
            patientId: e['patientId']! as String,
            action: AuditAction.values.byName(e['action']! as String),
            success: e['success']! as bool,
            description: e['description']! as String,
          ),
        );
      default:
        throw FormatException('Bilinmeyen olay: ${e['t']}');
    }
  }

  // ---------------------------------------------------------- PortalStore

  @override
  void addAccount(Account a, String token) => _record({
    't': 'account',
    'id': a.id,
    'role': a.role.name,
    'name': a.name,
    'org': a.organization,
    'tokenHash': tokenHash(token),
  });

  @override
  Account? accountByToken(String token) =>
      token.isEmpty ? null : _mem.accountByToken(tokenHash(token));

  @override
  Account? account(String id) => _mem.account(id);

  @override
  bool addObservation(StoredObservation o) {
    final exists = _mem
        .observations(o.patientId)
        .any((x) => x.identifier == o.identifier);
    if (exists) return false;
    _record({
      't': 'obs',
      'patientId': o.patientId,
      'identifier': o.identifier,
      'code': o.code,
      'effective': _time(o.effective),
      'resource': o.resource,
    });
    return true;
  }

  @override
  List<StoredObservation> observations(
    String patientId, {
    Set<String>? codes,
    DateTime? from,
    DateTime? to,
  }) => _mem.observations(patientId, codes: codes, from: from, to: to);

  /// Ölçümler bellekten ve dosyadan silinir: dosya, bu hastanın ölçüm
  /// olayları olmadan baştan yazılır.
  @override
  int deleteObservations(String patientId) {
    final count = _mem.deleteObservations(patientId);
    _events.removeWhere((e) => e['t'] == 'obs' && e['patientId'] == patientId);
    _rewrite();
    return count;
  }

  @override
  void addConsent(Consent c) => _record({
    't': 'consent',
    'id': c.id,
    'patientId': c.patientId,
    'actorId': c.actorId,
    'scopes': [for (final s in c.scopes) s.name],
    'requested': [for (final s in c.requested) s.name],
    'start': _time(c.start),
    'end': _time(c.end),
    'purpose': c.purpose,
    'inviteCode': c.inviteCode,
  });

  @override
  void revokeConsent(String id, DateTime at) {
    final c = _mem.consent(id);
    if (c == null || c.revokedAt != null) return;
    _record({'t': 'revoke', 'id': id, 'at': _time(at)});
  }

  @override
  Consent? consent(String id) => _mem.consent(id);

  @override
  List<Consent> consentsForPatient(String patientId) =>
      _mem.consentsForPatient(patientId);

  @override
  List<Consent> consentsForActor(String actorId) =>
      _mem.consentsForActor(actorId);

  @override
  void addInvite(Invite i) => _record({
    't': 'invite',
    'code': i.code,
    'actorId': i.actorId,
    'purpose': i.purpose,
    'requested': [for (final s in i.requested) s.name],
    'seconds': i.duration.inSeconds,
    'expires': _time(i.expires),
  });

  @override
  Invite? invite(String code) => _mem.invite(code);

  @override
  void removeInvite(String code) {
    if (_mem.invite(code) == null) return;
    _record({'t': 'inviteDel', 'code': code});
  }

  @override
  void addAudit(AuditEntry e) => _record({
    't': 'audit',
    'id': e.id,
    'time': _time(e.time),
    'actorId': e.actorId,
    'patientId': e.patientId,
    'action': e.action.name,
    'success': e.success,
    'description': e.description,
  });

  @override
  List<AuditEntry> auditForPatient(String patientId) =>
      _mem.auditForPatient(patientId);

  /// Yeniden başlatmada çakışmasın diye sıra numarası yerine rastgele.
  @override
  String nextId(String prefix) {
    final hex = List.generate(
      8,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '$prefix-$hex';
  }
}
