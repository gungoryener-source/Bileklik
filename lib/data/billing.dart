import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Abonelik (Premium)
//
// Uygulama içindeki dijital hizmetler App Store ve Google Play'in kendi ödeme
// sistemlerinden satılmak zorunda. Gerçek uygulama `in_app_purchase` (ya da
// RevenueCat) ile mağazaya bağlanacak ve satın alma makbuzu portalda
// doğrulanacak. Şimdilik [FakeBillingService] mağazayı taklit eder: para
// alınmaz, fiyatlar örnektir.
// ---------------------------------------------------------------------------

/// Premium paketin dönemi.
enum PremiumPlan { monthly, yearly }

/// Mağazada satılan bir ürün. Gerçek mağaza fiyatı kullanıcının ülkesine göre
/// biçimlendirilmiş verir; demoda tutar ve para birimi tutulur.
class BillingProduct {
  const BillingProduct(this.plan, this.price, this.currency);

  final PremiumPlan plan;

  /// Dönem başına fiyat.
  final double price;

  /// ISO 4217 kodu (TRY, EUR…).
  final String currency;

  /// Bir dönemin ay sayısı.
  int get months => plan == PremiumPlan.yearly ? 12 : 1;
}

/// Kullanıcının aboneliği.
class Subscription {
  const Subscription({
    required this.plan,
    required this.since,
    required this.renewsAt,
    this.cancelled = false,
  });

  final PremiumPlan plan;
  final DateTime since;

  /// Dönemin bittiği an; iptal edilmediyse o an yenilenir.
  final DateTime renewsAt;

  /// Kullanıcı iptal etti: dönem sonunda yenilenmez, o zamana kadar sürer.
  final bool cancelled;

  bool activeAt(DateTime now) => now.isBefore(renewsAt);

  Subscription copyWith({bool? cancelled}) => Subscription(
    plan: plan,
    since: since,
    renewsAt: renewsAt,
    cancelled: cancelled ?? this.cancelled,
  );
}

/// Ödeme servisi; ekranlar yalnızca bunu bilir.
abstract class BillingService extends ChangeNotifier {
  /// Satıştaki ürünler, sabit sırayla (aylık, yıllık).
  List<BillingProduct> get products;

  /// Bilinen abonelik; hiç alınmadıysa null. Süresi geçmiş olabilir.
  Subscription? get subscription;

  /// Premium şu an açık mı.
  bool isPremium(DateTime now) => subscription?.activeAt(now) ?? false;

  /// Mağazanın onay ekranından sonra çağrılır.
  Future<Subscription> purchase(PremiumPlan plan);

  /// Mağaza hesabındaki eski satın alımı bu telefona getirir; yoksa null.
  Future<Subscription?> restore();

  /// Yenilemeyi kapatır; dönem sonuna kadar Premium sürer.
  Future<void> cancel();
}

/// Mağazayı taklit eder; para alınmaz.
class FakeBillingService extends BillingService {
  FakeBillingService({
    this.delay = const Duration(milliseconds: 600),
    DateTime Function()? now,
    this._storeAccount,
  }) : _now = now ?? DateTime.now;

  /// Mağazaya gidip gelmeyi taklit eden bekleme.
  final Duration delay;
  final DateTime Function() _now;

  /// Mağaza hesabında duran satın alım ("geri yükle" bunu getirir).
  Subscription? _storeAccount;
  Subscription? _subscription;

  /// Örnek fiyatlar; yıllık, aylığın on iki katından ucuzdur.
  static const demoProducts = [
    BillingProduct(PremiumPlan.monthly, 149.99, 'TRY'),
    BillingProduct(PremiumPlan.yearly, 1199.99, 'TRY'),
  ];

  @override
  List<BillingProduct> get products => demoProducts;

  @override
  Subscription? get subscription => _subscription;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<Subscription> purchase(PremiumPlan plan) async {
    await _wait();
    final now = _now();
    final s = Subscription(
      plan: plan,
      since: now,
      renewsAt: plan == PremiumPlan.yearly
          ? DateTime(now.year + 1, now.month, now.day, now.hour, now.minute)
          : DateTime(now.year, now.month + 1, now.day, now.hour, now.minute),
    );
    _subscription = s;
    _storeAccount = s;
    notifyListeners();
    return s;
  }

  @override
  Future<Subscription?> restore() async {
    await _wait();
    final s = _storeAccount;
    if (s == null || !s.activeAt(_now())) return null;
    _subscription = s;
    notifyListeners();
    return s;
  }

  @override
  Future<void> cancel() async {
    await _wait();
    final s = _subscription;
    if (s == null) return;
    _subscription = s.copyWith(cancelled: true);
    _storeAccount = _subscription;
    notifyListeners();
  }
}

/// Yıllık paketin aylığa göre yüzde kaç ucuz olduğu.
int yearlySavingPercent(List<BillingProduct> products) {
  BillingProduct? of(PremiumPlan p) {
    for (final x in products) {
      if (x.plan == p) return x;
    }
    return null;
  }

  final m = of(PremiumPlan.monthly);
  final y = of(PremiumPlan.yearly);
  if (m == null || y == null || m.price <= 0) return 0;
  return ((1 - y.price / (m.price * 12)) * 100).floor().clamp(0, 100);
}
