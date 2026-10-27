import 'dart:math';

import 'package:bileklik/data/billing.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/l10n/app_localizations.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/ai_report_screen.dart';
import 'package:bileklik/ui/screens/premium_screen.dart';
import 'package:bileklik/ui/screens/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 27, 9);
final _tr = lookupAppLocalizations(const Locale('tr'));

FakeBillingService _billing({Subscription? account}) => FakeBillingService(
  delay: Duration.zero,
  now: () => _now,
  storeAccount: account,
);

void main() {
  test('aylık ve yıllık satın alma dönemi', () async {
    final b = _billing();
    expect(b.isPremium(_now), isFalse);
    final m = await b.purchase(PremiumPlan.monthly);
    expect(m.renewsAt, DateTime(2026, 11, 27, 9));
    expect(b.isPremium(_now), isTrue);
    final y = await b.purchase(PremiumPlan.yearly);
    expect(y.renewsAt, DateTime(2027, 10, 27, 9));
  });

  test('iptal dönem sonuna kadar Premium bırakır', () async {
    final b = _billing();
    await b.purchase(PremiumPlan.monthly);
    await b.cancel();
    expect(b.subscription!.cancelled, isTrue);
    expect(b.isPremium(_now), isTrue);
    expect(b.isPremium(DateTime(2026, 11, 28)), isFalse);
  });

  test('geri yükleme mağaza hesabındaki süren aboneliği getirir', () async {
    expect(await _billing().restore(), isNull);
    final old = Subscription(
      plan: PremiumPlan.yearly,
      since: DateTime(2026, 3, 1),
      renewsAt: DateTime(2027, 3, 1),
    );
    final b = _billing(account: old);
    expect(b.isPremium(_now), isFalse);
    expect(await b.restore(), same(old));
    expect(b.isPremium(_now), isTrue);
    final expired = Subscription(
      plan: PremiumPlan.monthly,
      since: DateTime(2026, 8, 1),
      renewsAt: DateTime(2026, 9, 1),
    );
    expect(await _billing(account: expired).restore(), isNull);
  });

  test('yıllık paketin tasarrufu', () {
    expect(yearlySavingPercent(FakeBillingService.demoProducts), 33);
    expect(yearlySavingPercent(const []), 0);
  });

  Future<void> pump(
    WidgetTester tester,
    FakeBillingService billing, {
    String lang = 'tr',
  }) async {
    await tester.pumpWidget(
      BileklikApp(
        controller: DeviceController(
          FakeDevice(random: Random(5)),
          store: MemoryHealthStore(),
        ),
        settings: AppSettings.memory(language: lang),
        billing: billing,
      ),
    );
    await tester.pumpAndSettle();
  }

  void push(WidgetTester tester, Widget screen) => tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  testWidgets('yapay zeka raporu Premium ister; satın alınca açılır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final billing = _billing();
    await pump(tester, billing);
    push(tester, ProgressScreen(day: _now, now: _now));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(AiReportCard),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProgressScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byType(AiReportCard));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumScreen), findsOneWidget);
    expect(find.text(_tr.premiumSave(33)), findsOneWidget);

    // Vazgeçilirse satın alınmaz.
    await tester.tap(find.text(_tr.premiumSubscribe));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr.storeCancel));
    await tester.pumpAndSettle();
    expect(billing.subscription, isNull);

    await tester.tap(find.text(_tr.premiumMonthly));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr.premiumSubscribe));
    await tester.pumpAndSettle();
    expect(find.text(_tr.storeSheetItem(_tr.premiumMonthly)), findsOneWidget);
    await tester.tap(find.text(_tr.storeConfirm));
    await tester.pumpAndSettle();

    expect(billing.subscription!.plan, PremiumPlan.monthly);
    expect(find.byType(AiReportScreen), findsOneWidget);
    expect(find.text(_tr.premiumActive), findsOneWidget);
  });

  testWidgets('abonelik ekranı: ücretsiz, Premium ve iptal', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final billing = _billing();
    await pump(tester, billing);
    push(tester, SubscriptionScreen(now: () => _now));
    await tester.pumpAndSettle();
    expect(find.text(_tr.subscriptionFree), findsOneWidget);
    expect(find.text(_tr.subscriptionUpgrade), findsOneWidget);

    await billing.purchase(PremiumPlan.yearly);
    await tester.pumpAndSettle();
    expect(
      find.text(_tr.subscriptionPremium(_tr.premiumYearly)),
      findsOneWidget,
    );
    expect(find.text(_tr.subscriptionUpgrade), findsNothing);

    await tester.tap(find.text(_tr.subscriptionCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, _tr.subscriptionCancel));
    await tester.pumpAndSettle();
    expect(billing.subscription!.cancelled, isTrue);
    expect(find.text(_tr.subscriptionCancelled), findsOneWidget);
    expect(find.text(_tr.subscriptionCancel), findsNothing);
  });

  for (final lang in ['tr', 'en', 'ar', 'de']) {
    testWidgets('$lang: Premium ve abonelik 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final l = lookupAppLocalizations(Locale(lang));
      final billing = _billing();
      await pump(tester, billing, lang: lang);
      push(tester, const PremiumScreen());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.premiumSubscribe));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(l.storeConfirm));
      await tester.pumpAndSettle();

      push(tester, SubscriptionScreen(now: () => _now));
      await tester.pumpAndSettle();
      expect(find.text(l.subscriptionPremium(l.premiumYearly)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
