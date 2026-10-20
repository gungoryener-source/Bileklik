import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/connections.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/connection_detail_screen.dart';
import 'package:bileklik/ui/screens/connections_screen.dart';
import 'package:bileklik/ui/screens/consent_screen.dart';
import 'package:bileklik/ui/screens/profile_screen.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kurum ve hekim adları kendi yönünde yalıtılarak yazılır.
const _dr = '\u2068Dr. Ayşe Kaya\u2069';

/// Uygulamayı açar ve Profil > Hekim ve araştırma kurumu sayfasına gider.
Future<void> _openConnections(
  WidgetTester tester,
  ConnectionService server, {
  String language = 'tr',
  Size size = const Size(1080, 2340),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = DeviceController(
    FakeDevice(
      random: Random(5),
      realtimeInterval: const Duration(seconds: 30),
    ),
    store: MemoryHealthStore(),
  );
  await tester.pumpWidget(
    BileklikApp(
      controller: controller,
      settings: AppSettings.memory(language: language),
      community: FakeCommunityServer(latency: Duration.zero, acceptDelay: null),
      connections: server,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(
          of: find.byType(GlassNavBar),
          matching: find.byType(Pressable),
        )
        .at(3),
  );
  await tester.pumpAndSettle();
  final tile = find.byIcon(Icons.biotech);
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await _tap(tester, tile);
  await tester.pumpAndSettle();
  expect(find.byType(ConnectionsScreen), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Devam'));
  await tester.pumpAndSettle();
}

Finder _inConsent(Finder f) =>
    find.descendant(of: find.byType(ConsentScreen), matching: f);

void main() {
  group('sahte bağlantı sunucusu', () {
    test('kod çözülür, yalnızca seçilenler ve istenenler paylaşılır', () async {
      var now = DateTime(2026, 10, 20, 9);
      final s = FakeConnectionServer(latency: Duration.zero, clock: () => now);
      expect(await s.lookup('XXXXXX'), isNull);
      final offer = await s.lookup(' drk482 ');
      expect(offer!.kind, ConnectionKind.clinician);

      final c = await s.connect(offer, {ShareScope.heartRate});
      expect(c.scopes, {ShareScope.heartRate});
      expect(c.until, DateTime(2027, 10, 20, 9));
      expect(s.connections, hasLength(1));

      // Aynı davet yeniden onaylanırsa eski rıza yenisiyle değişir.
      await s.connect(offer, {ShareScope.heartRate, ShareScope.ecg});
      expect(s.connections.single.scopes, hasLength(2));

      // Süre bitince bağlantı listeden düşer.
      now = now.add(const Duration(days: 366));
      expect(s.connections, isEmpty);
    });

    test('bağlantı kaldırılır', () async {
      final s = FakeConnectionServer(latency: Duration.zero);
      final offer = await s.lookup(FakeConnectionServer.researchCode);
      final c = await s.connect(offer!, {ShareScope.sleep});
      await s.disconnect(c.id);
      expect(s.connections, isEmpty);
    });
  });

  testWidgets('kodla bağlan: açık rıza, ayrıntı ve kaldırma', (tester) async {
    final server = FakeConnectionServer(latency: Duration.zero);
    await _openConnections(tester, server);
    expect(find.text('Henüz bir bağlantınız yok.'), findsOneWidget);

    await _tap(tester, find.text('Davet kodu gir').last);
    await tester.pumpAndSettle();
    await _enterCode(tester, 'abc123');
    expect(find.text('Bu kod geçersiz ya da süresi dolmuş.'), findsOneWidget);
    await _enterCode(tester, 'drk482');
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(_inConsent(find.text(_dr)), findsOneWidget);

    // Hiçbir veri önceden seçili değil; onay düğmesi kapalı.
    GlowButton confirm() =>
        tester.widget(find.widgetWithText(GlowButton, 'Onayla ve bağlan'));
    expect(confirm().onTap, isNull);
    await _tap(tester, _inConsent(find.text('Nabız')));
    await _tap(tester, _inConsent(find.text('EKG kayıtları')));
    await tester.pumpAndSettle();
    // Rıza kutusu işaretlenmeden bağlanılamaz.
    expect(confirm().onTap, isNull);
    await _tap(tester, _inConsent(find.textContaining('açıkça rıza')));
    await tester.pumpAndSettle();
    expect(confirm().onTap, isNotNull);
    await tester.tap(find.text('Onayla ve bağlan'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsentScreen), findsNothing);
    expect(find.text('$_dr ile bağlantı kuruldu.'), findsOneWidget);
    expect(server.connections.single.scopes, {
      ShareScope.heartRate,
      ShareScope.ecg,
    });
    expect(find.textContaining('Hekim · 2 veri türü'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_dr));
    await tester.pumpAndSettle();
    final detail = find.byType(ConnectionDetailScreen);
    expect(
      find.descendant(of: detail, matching: find.text('Nabız')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detail, matching: find.text('Kan oksijeni (SpO2)')),
      findsNothing,
    );
    final remove = find.descendant(
      of: detail,
      matching: find.text('Bağlantıyı kaldır'),
    );
    await tester.scrollUntilVisible(
      remove,
      200,
      scrollable: find
          .descendant(of: detail, matching: find.byType(Scrollable))
          .first,
    );
    await _tap(tester, remove);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Bağlantıyı kaldır'));
    await tester.pumpAndSettle();
    expect(detail, findsNothing);
    expect(server.connections, isEmpty);
    expect(find.text('Henüz bir bağlantınız yok.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QR tara şimdilik kod girişine yönlendirir', (tester) async {
    await _openConnections(
      tester,
      FakeConnectionServer(latency: Duration.zero),
    );
    await _tap(tester, find.text('QR kodu tara'));
    await tester.pumpAndSettle();
    expect(find.textContaining('QR kodun altındaki kodu'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: açık rıza ekranı 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final server = FakeConnectionServer(latency: Duration.zero);
      await _openConnections(
        tester,
        server,
        language: lang,
        size: const Size(960, 1920),
      );
      await _tap(tester, find.byIcon(Icons.pin_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        FakeConnectionServer.researchCode,
      );
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ConsentScreen), findsOneWidget);
      await tester.drag(
        _inConsent(find.byType(Scrollable)).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
