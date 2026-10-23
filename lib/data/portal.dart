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
  String? get portalToken;
  Future<void> setPortalToken(String? token);
  DateTime? get lastPortalUpload;
  Future<void> setLastPortalUpload(DateTime t);
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
      // 409: bu kimlikle hesap var ama anahtar telefonda yok (ör. uygulama
      // verisi silindi). Yeni kimlik gerekir; şimdilik bağlantı kurulamaz.
      throw ConnectionUnavailable('kayıt ${r.statusCode}');
    }
    final token = (jsonDecode(r.body) as Map)['token'] as String;
    await credentials.setPortalToken(token);
    return token;
  }

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

  /// Yanıt [ok] değilse [ConnectionUnavailable] fırlatır.
  Future<http.Response> request(
    String method,
    String path, {
    Object? body,
    Set<int> ok = const {200, 201},
  }) async {
    final r = await _send(method, path, body: body);
    if (!ok.contains(r.statusCode)) {
      throw ConnectionUnavailable('$method $path → ${r.statusCode}');
    }
    return r;
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

/// Paylaşılan türlerdeki ölçümleri portala FHIR Bundle olarak yükler.
///
/// - Hiç bağlantı yoksa hiçbir şey yüklenmez (veri en aza indirme).
/// - Yalnızca süren rızalardaki türler gider.
/// - Senkron eski kayıtları sonradan getirebildiği için son yüklemeden 7 gün
///   öncesinden başlanır; portal aynı kaydı kimliğinden tanır, tekrar yazmaz.
///   İlk yüklemede son 30 gün gider.
class PortalUploader extends ChangeNotifier {
  PortalUploader({
    required this.client,
    required this.connections,
    required this.store,
    this.debounce = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    store.addListener(_schedule);
    connections.addListener(_schedule);
  }

  final PortalClient client;
  final PortalConnectionService connections;
  final HealthStore store;
  final Duration debounce;
  final DateTime Function() _now;
  Timer? _timer;
  bool _busy = false;
  Object? lastError;

  void _schedule() {
    if (connections.sharedScopes.isEmpty) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(uploadNow()));
  }

  /// Yüklenen kayıt sayısını döndürür (hasta kaydı hariç).
  Future<int> uploadNow() async {
    final scopes = connections.sharedScopes;
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
    super.dispose();
  }
}
