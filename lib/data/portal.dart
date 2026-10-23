import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'community.dart';
import 'connections.dart';
import 'fhir.dart';
import 'health_store.dart';

/// Portal oturum anahtarının ve son yüklemenin saklandığı yer
/// (`AppSettings` uygular).
abstract class PortalCredentials {
  String get patientId;
  Future<void> setPatientId(String id);
  String? get portalToken;
  Future<void> setPortalToken(String? token);
  String? get recoveryCode;
  Future<void> setRecoveryCode(String? code);
  DateTime? get lastPortalUpload;
  Future<void> setLastPortalUpload(DateTime t);

  /// Topluluk bildirimlerinin okunduğu son an (rozet sayısı için).
  DateTime? get communityReadUntil;
  Future<void> setCommunityReadUntil(DateTime t);
}

/// Portal API'sinin HTTP istemcisi (`portal/` paketi).
///
/// İlk istekte uygulamanın takma kimliğiyle hesap açar (`POST /patients`) ve
/// verilen anahtarı saklar. Ağ hatası ve beklenmeyen yanıtlar
/// [ConnectionUnavailable] olarak gelir.
class PortalClient {
  PortalClient({
    required this.baseUrl,
    required this.httpClient,
    required this.credentials,
    this.timeout = const Duration(seconds: 15),
  });

  /// Sondaki `/` önemli: yollar buna göre çözülür.
  final Uri baseUrl;
  final http.Client httpClient;
  final PortalCredentials credentials;
  final Duration timeout;

  Future<String>? _registering;

  Future<String> _token() async {
    final saved = credentials.portalToken;
    if (saved != null) return saved;
    return _registering ??= _register().whenComplete(() => _registering = null);
  }

  Future<String> _register() async {
    final r = await _send(
      'POST',
      '/patients',
      body: {'patientId': credentials.patientId},
      auth: false,
    );
    if (r.statusCode != 201) {
      // 409: bu kimlikle hesap var ama anahtar telefonda yok. Kullanıcı
      // kurtarma koduyla hesabını geri alır (PortalAccountService.recover).
      throw ConnectionUnavailable('kayıt ${r.statusCode}');
    }
    final json = jsonDecode(r.body) as Map;
    final token = json['token'] as String;
    await credentials.setPortalToken(token);
    await credentials.setRecoveryCode(json['recoveryCode'] as String?);
    return token;
  }

  /// İlk istekte hesap açılmadıysa açar.
  Future<void> ensureAccount() => _token();

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final headers = {
      'content-type': 'application/json',
      if (auth) 'authorization': 'Bearer ${await _token()}',
    };
    final request = http.Request(method, baseUrl.resolve(path.substring(1)))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    try {
      final streamed = await httpClient.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ConnectionUnavailable('zaman aşımı');
    } catch (e) {
      if (e is ConnectionUnavailable) rethrow;
      throw ConnectionUnavailable(e.toString());
    }
  }

  /// Yanıt [ok] değilse [ConnectionUnavailable] fırlatır. [auth] false ise
  /// oturum anahtarı gönderilmez (ör. kimliksiz geri bildirim).
  Future<http.Response> request(
    String method,
    String path, {
    Object? body,
    Set<int> ok = const {200, 201},
    bool auth = true,
  }) async {
    final r = await _send(method, path, body: body, auth: auth);
    if (!ok.contains(r.statusCode)) {
      throw ConnectionUnavailable('$method $path → ${r.statusCode}');
    }
    return r;
  }
}

/// Portal hesabı: kurtarma kodunu gösterme, yenileme ve başka telefondaki
/// hesabı kodla geri alma.
class PortalAccountService {
  PortalAccountService(this.client, {this.onRecovered});

  final PortalClient client;

  /// Hesap değişince (ör. bağlantıları yenilemek için) çağrılır.
  final Future<void> Function()? onRecovered;

  PortalCredentials get _c => client.credentials;

  /// Kurtarma kodu; hesap henüz açılmadıysa açılır, eski bir hesapta kod
  /// yoksa yenisi istenir.
  Future<String> recoveryCode() async {
    await client.ensureAccount();
    return _c.recoveryCode ?? await renewRecoveryCode();
  }

  /// Yeni kod üretir; eskisi geçersiz olur.
  Future<String> renewRecoveryCode() async {
    final r = await client.request('POST', '/patients/recovery');
    final code = (jsonDecode(r.body) as Map)['recoveryCode'] as String;
    await _c.setRecoveryCode(code);
    return code;
  }

  /// Kodla eski hesabı bu telefona alır. Kod geçersizse false.
  ///
  /// Bu telefonda açılmış (boş) hesap varsa önce verisi silinir; sonra
  /// takma kimlik, oturum anahtarı ve yeni kurtarma kodu bu telefona geçer.
  Future<bool> recover(String code) async {
    final r = await client.request(
      'POST',
      '/recover',
      auth: false,
      body: {'recoveryCode': code.trim()},
      ok: const {200, 404},
    );
    if (r.statusCode == 404) return false;
    final json = jsonDecode(r.body) as Map;
    final id = json['patientId'] as String;
    if (_c.portalToken != null && _c.patientId != id) {
      try {
        await client.request(
          'DELETE',
          '/patients/${Uri.encodeComponent(_c.patientId)}/data',
        );
      } on ConnectionUnavailable {
        // Boş hesabın silinememesi kurtarmayı durdurmaz.
      }
    }
    await _c.setPatientId(id);
    await _c.setPortalToken(json['token'] as String);
    await _c.setRecoveryCode(json['recoveryCode'] as String);
    await onRecovered?.call();
    return true;
  }
}

/// Hekim ve araştırma bağlantıları, portal üzerinden.
class PortalConnectionService extends ConnectionService {
  PortalConnectionService(this.client);

  final PortalClient client;
  var _list = const <DataConnection>[];

  @override
  List<DataConnection> get connections => _list;

  /// Süren bağlantılardaki türlerin birleşimi; portala yalnızca bunlar
  /// yüklenir.
  Set<ShareScope> get sharedScopes => {for (final c in _list) ...c.scopes};

  static ConnectionKind _kind(Object? k) =>
      k == 'researcher' ? ConnectionKind.research : ConnectionKind.clinician;

  static Set<ShareScope> _scopes(Object? raw) => {
    for (final s in raw as List? ?? const [])
      ?ShareScope.values.asNameMap()[s],
  };

  static ConnectionOffer _offer(Map j, {required String code}) =>
      ConnectionOffer(
        code: code,
        kind: _kind(j['kind']),
        name: j['name'] as String? ?? '',
        organization: j['organization'] as String? ?? '',
        purpose: j['purpose'] as String? ?? '',
        requested: _scopes(j['requested']),
        duration: Duration(days: j['durationDays'] as int? ?? 0),
      );

  @override
  Future<void> refresh() async {
    final r = await client.request('GET', '/connections');
    _list = List.unmodifiable([
      for (final j in jsonDecode(r.body) as List)
        if (j is Map) _connection(j),
    ]);
    notifyListeners();
  }

  static DataConnection _connection(Map j) {
    final since = DateTime.parse(j['since'] as String).toLocal();
    final until = DateTime.parse(j['until'] as String).toLocal();
    return DataConnection(
      id: j['id'] as String,
      offer: _offer({
        ...j,
        'durationDays': until.difference(since).inDays,
      }, code: j['code'] as String? ?? ''),
      scopes: _scopes(j['scopes']),
      since: since,
      until: until,
    );
  }

  @override
  Future<ConnectionOffer?> lookup(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    final r = await client.request(
      'GET',
      '/invites/${Uri.encodeComponent(c)}',
      ok: const {200, 404},
    );
    if (r.statusCode == 404) return null;
    return _offer(jsonDecode(r.body) as Map, code: c);
  }

  @override
  Future<DataConnection> connect(
    ConnectionOffer offer,
    Set<ShareScope> scopes,
  ) async {
    final r = await client.request(
      'POST',
      '/invites/${Uri.encodeComponent(offer.code)}/accept',
      body: {'scopes': [for (final s in scopes) s.name]},
    );
    final id = (jsonDecode(r.body) as Map)['id'] as String;
    await refresh();
    return _list.firstWhere(
      (c) => c.id == id,
      orElse: () => throw const ConnectionUnavailable('bağlantı listede yok'),
    );
  }

  @override
  Future<void> disconnect(String id) async {
    await client.request('DELETE', '/consents/${Uri.encodeComponent(id)}');
    await refresh();
  }
}

/// Aile grupları, portal üzerinden (`/groups`).
///
/// Davet kişiye özel kodla yapılır: sahip davet edilenin adını yazar, portal
/// bir kod verir; davet edilen bu kodla katılınca o adla görünür. Grup
/// koduyla katılanın adı boştur. Portal kişiler arası rehber tutmadığı için
/// "biri sizi davet etti" bildirimi yoktur; yalnızca "katıldı" bildirimleri
/// gelir.
class PortalCommunityService extends CommunityService {
  PortalCommunityService(this.client);

  final PortalClient client;
  var _groups = const <CareGroup>[];
  var _messages = const <CommunityMessage>[];

  @override
  List<CareGroup> get myGroups => [
    for (final g in _groups)
      if (g.ownedByMe) g,
  ];

  @override
  List<CareGroup> get joinedGroups => [
    for (final g in _groups)
      if (!g.ownedByMe) g,
  ];

  @override
  List<CommunityMessage> get messages => _messages;

  @override
  int get unreadCount {
    final since = client.credentials.communityReadUntil;
    return since == null
        ? _messages.length
        : _messages.where((m) => m.time.isAfter(since)).length;
  }

  /// Gruplarla paylaşılan türlerin birleşimi; portala bunlar da yüklenir.
  Set<ShareScope> get sharedScopes => {
    for (final g in _groups) ...g.myConsent.scopes,
  };

  @override
  CareGroup? group(String id) =>
      _groups.where((g) => g.id == id).firstOrNull;

  static Set<ShareScope> _scopes(Object? raw) => {
    for (final s in raw as List? ?? const [])
      ?ShareScope.values.asNameMap()[s],
  };

  static CareGroup _group(Map j) {
    final consent = j['myConsent'] as Map? ?? const {};
    final scopes = _scopes(consent['scopes']);
    final granted = consent['grantedAt'] as String?;
    return CareGroup(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      ownedByMe: j['ownedByMe'] == true,
      inviteCode: j['inviteCode'] as String? ?? '',
      members: [
        for (final m in j['members'] as List? ?? const [])
          if (m is Map)
            GroupMember(
              id: m['id'] as String,
              name: m['name'] as String? ?? '',
              isMe: m['isMe'] == true,
              isOwner: m['isOwner'] == true,
              pending: m['pending'] == true,
              shares: _scopes(m['shares']),
            ),
      ],
      myConsent: ShareConsent(
        scopes: scopes,
        grantedAt: scopes.isEmpty || granted == null
            ? null
            : DateTime.parse(granted).toLocal(),
      ),
    );
  }

  /// Grupları ve bildirimleri portaldan yeniden okur.
  @override
  Future<void> refresh() async {
    final r = await client.request('GET', '/groups');
    final j = jsonDecode(r.body) as Map;
    _groups = List.unmodifiable([
      for (final g in j['groups'] as List? ?? const [])
        if (g is Map) _group(g),
    ]);
    _messages = List.unmodifiable(
      [
        for (final m in j['messages'] as List? ?? const [])
          if (m is Map)
            CommunityMessage(
              id: m['id'] as String,
              kind: CommunityMessageKind.memberJoined,
              from: m['from'] as String? ?? '',
              groupName: m['groupName'] as String? ?? '',
              groupId: m['groupId'] as String?,
              time: DateTime.parse(m['time'] as String).toLocal(),
            ),
      ]..sort((a, b) => b.time.compareTo(a.time)),
    );
    notifyListeners();
  }

  String _path(String groupId, [String rest = '']) =>
      '/groups/${Uri.encodeComponent(groupId)}$rest';

  @override
  Future<CareGroup> createGroup(String name) async {
    final r = await client.request(
      'POST',
      '/groups',
      body: {'name': name.trim()},
    );
    final id = (jsonDecode(r.body) as Map)['id'] as String;
    await refresh();
    return group(id) ?? _group(jsonDecode(r.body) as Map);
  }

  @override
  Future<String> invite(String groupId, String name) async {
    final r = await client.request(
      'POST',
      _path(groupId, '/members'),
      body: {'name': name.trim()},
    );
    await refresh();
    return (jsonDecode(r.body) as Map)['code'] as String;
  }

  @override
  Future<void> removeMember(String groupId, String memberId) async {
    await client.request(
      'DELETE',
      _path(groupId, '/members/${Uri.encodeComponent(memberId)}'),
    );
    await refresh();
  }

  @override
  Future<void> setConsent(String groupId, Set<ShareScope> scopes) async {
    await client.request(
      'PUT',
      _path(groupId, '/consent'),
      body: {'scopes': [for (final s in scopes) s.name]},
    );
    await refresh();
  }

  @override
  Future<CareGroup?> joinWithCode(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    final r = await client.request(
      'POST',
      '/groups/join',
      body: {'code': c},
      ok: const {200, 404},
    );
    if (r.statusCode == 404) return null;
    final id = (jsonDecode(r.body) as Map)['id'] as String;
    await refresh();
    return group(id);
  }

  /// Portalda davet bildirimi yok; çağrılmaz.
  @override
  Future<void> answerInvite(String messageId, {required bool accept}) async {}

  @override
  Future<void> leave(String groupId) async {
    await client.request('DELETE', _path(groupId));
    await refresh();
  }

  @override
  void markAllRead() {
    if (_messages.isEmpty || unreadCount == 0) return;
    unawaited(client.credentials.setCommunityReadUntil(_messages.first.time));
    notifyListeners();
  }
}

/// Paylaşılan türlerdeki ölçümleri portala FHIR Bundle olarak yükler.
///
/// - Hiç bağlantı ya da grup paylaşımı yoksa hiçbir şey yüklenmez (veri en
///   aza indirme).
/// - Yalnızca süren rızalardaki ve gruplarla paylaşılan türler gider.
/// - Senkron eski kayıtları sonradan getirebildiği için son yüklemeden 7 gün
///   öncesinden başlanır; portal aynı kaydı kimliğinden tanır, tekrar yazmaz.
///   İlk yüklemede son 30 gün gider.
class PortalUploader extends ChangeNotifier {
  PortalUploader({
    required this.client,
    required this.connections,
    required this.store,
    this.community,
    this.debounce = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    store.addListener(_schedule);
    connections.addListener(_schedule);
    community?.addListener(_schedule);
  }

  final PortalClient client;
  final PortalConnectionService connections;

  /// Aile gruplarıyla paylaşılan türler de yüklenir.
  final PortalCommunityService? community;

  Set<ShareScope> get _scopes => {
    ...connections.sharedScopes,
    ...?community?.sharedScopes,
  };
  final HealthStore store;
  final Duration debounce;
  final DateTime Function() _now;
  Timer? _timer;
  bool _busy = false;
  Object? lastError;

  void _schedule() {
    if (_scopes.isEmpty) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(uploadNow()));
  }

  /// Yüklenen kayıt sayısını döndürür (hasta kaydı hariç).
  Future<int> uploadNow() async {
    final scopes = _scopes;
    if (scopes.isEmpty || _busy) return 0;
    _busy = true;
    try {
      final to = _now();
      final last = client.credentials.lastPortalUpload;
      final from = last == null
          ? to.subtract(const Duration(days: 30))
          : last.subtract(const Duration(days: 7));
      final bundle = filterBundle(
        FhirExporter(
          patientId: client.credentials.patientId,
          clock: _now,
        ).bundle(
          store,
          from: from,
          to: to,
          includeEcg: scopes.contains(ShareScope.ecg),
        ),
        {for (final s in scopes) ...fhirCodesFor(s)},
      );
      final count = (bundle['entry']! as List).length - 1;
      if (count > 0) await client.request('POST', '/fhir', body: bundle);
      await client.credentials.setLastPortalUpload(to);
      lastError = null;
      return count;
    } catch (e) {
      lastError = e;
      return 0;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    store.removeListener(_schedule);
    connections.removeListener(_schedule);
    community?.removeListener(_schedule);
    super.dispose();
  }
}
