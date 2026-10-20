import 'package:flutter/foundation.dart';

import 'community.dart';

/// Veri paylaşılan karşı taraf: araştırma kurumu ya da hekim.
enum ConnectionKind { research, clinician }

/// Davet kodunun arkasındaki istek: kim, hangi amaçla, hangi verileri,
/// ne kadar süre istiyor. Kullanıcı açık rıza ekranında bunu görür.
///
/// Portala aktarımda FHIR R4 Consent: `performer` karşı taraf,
/// `provision.purpose` amaç, `provision.period` süre, `provision.class`
/// veri türleri olacak.
@immutable
class ConnectionOffer {
  const ConnectionOffer({
    required this.code,
    required this.kind,
    required this.name,
    required this.organization,
    required this.purpose,
    required this.requested,
    required this.duration,
  });

  final String code;
  final ConnectionKind kind;

  /// Hekimin adı ya da çalışmanın adı.
  final String name;

  /// Hastane, klinik ya da kurum.
  final String organization;

  /// İsteğin amacı; sunucudan gelir, karşı tarafın yazdığı metindir.
  final String purpose;
  final Set<ShareScope> requested;

  /// Paylaşımın en uzun süresi; bitince kendiliğinden sona erer.
  final Duration duration;
}

/// Kullanıcının onayladığı, süren bir paylaşım.
@immutable
class DataConnection {
  const DataConnection({
    required this.id,
    required this.offer,
    required this.scopes,
    required this.since,
    required this.until,
  });

  final String id;
  final ConnectionOffer offer;

  /// Kullanıcının istenenler arasından seçtikleri.
  final Set<ShareScope> scopes;
  final DateTime since;
  final DateTime until;
}

/// Hekim ve araştırma bağlantıları sunucusu. Şimdilik
/// [FakeConnectionServer]; portal arka ucu (ROADMAP 19) aynı arayüzü
/// uygulayacak.
abstract class ConnectionService extends ChangeNotifier {
  /// Süresi dolmamış bağlantılar, en yeni ilk.
  List<DataConnection> get connections;

  /// Davet kodunu çözer; geçersizse null.
  Future<ConnectionOffer?> lookup(String code);

  /// Açık rızayla bağlanır; yalnızca istenen türlerden seçilenler paylaşılır.
  Future<DataConnection> connect(ConnectionOffer offer, Set<ShareScope> scopes);

  /// Rızayı geri alır; paylaşım hemen durur.
  Future<void> disconnect(String id);
}

/// Bellekte çalışan sahte sunucu. Demoda iki kod çalışır:
/// [doctorCode] (hekim) ve [researchCode] (araştırma çalışması).
class FakeConnectionServer extends ConnectionService {
  FakeConnectionServer({
    this.latency = const Duration(milliseconds: 500),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final Duration latency;
  final DateTime Function() _now;
  final _list = <DataConnection>[];
  var _ids = 0;

  static const doctorCode = 'DRK482';
  static const researchCode = 'RTM2026';

  // Ad ve kurum karşı tarafın kendi yazdığı veridir; çevrilmez.
  static const _offers = {
    doctorCode: ConnectionOffer(
      code: doctorCode,
      kind: ConnectionKind.clinician,
      name: 'Dr. Ayşe Kaya',
      organization: 'Kardiyoloji Polikliniği',
      purpose:
          'Ritim bozukluğu takibi için nabız ve EKG kayıtlarınızı kontrol '
          'muayenelerinden önce görmek istiyorum.',
      requested: {
        ShareScope.heartRate,
        ShareScope.ecg,
        ShareScope.spo2,
        ShareScope.bloodPressure,
      },
      duration: Duration(days: 365),
    ),
    researchCode: ConnectionOffer(
      code: researchCode,
      kind: ConnectionKind.research,
      name: 'Uzaktan ritim izleme çalışması',
      organization: 'Kalp Sağlığı Araştırma Merkezi',
      purpose:
          'Giyilebilir cihaz verisinin atriyal fibrilasyonu erken fark '
          'etmedeki başarısını ölçen gözlemsel bir çalışma. Veriler '
          'kimliksizleştirilerek incelenir.',
      requested: {
        ShareScope.heartRate,
        ShareScope.ecg,
        ShareScope.sleep,
        ShareScope.activity,
        ShareScope.stress,
      },
      duration: Duration(days: 180),
    ),
  };

  Future<void> _wait() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);

  @override
  List<DataConnection> get connections {
    final now = _now();
    return List.unmodifiable(
      _list.where((c) => c.until.isAfter(now)).toList()
        ..sort((a, b) => b.since.compareTo(a.since)),
    );
  }

  @override
  Future<ConnectionOffer?> lookup(String code) async {
    await _wait();
    return _offers[code.trim().toUpperCase()];
  }

  @override
  Future<DataConnection> connect(
    ConnectionOffer offer,
    Set<ShareScope> scopes,
  ) async {
    assert(scopes.isNotEmpty && offer.requested.containsAll(scopes));
    await _wait();
    // Aynı davet ikinci kez onaylanırsa eski rıza yenisiyle değişir.
    _list.removeWhere((c) => c.offer.code == offer.code);
    final now = _now();
    final c = DataConnection(
      id: 'c-${++_ids}',
      offer: offer,
      scopes: Set.unmodifiable(scopes.intersection(offer.requested)),
      since: now,
      until: now.add(offer.duration),
    );
    _list.add(c);
    notifyListeners();
    return c;
  }

  @override
  Future<void> disconnect(String id) async {
    await _wait();
    _list.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
