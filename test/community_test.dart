import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/community_screen.dart';
import 'package:bileklik/ui/screens/group_screen.dart';
import 'package:bileklik/ui/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FakeCommunityServer _server({Duration? acceptDelay}) => FakeCommunityServer(
  latency: Duration.zero,
  acceptDelay: acceptDelay,
  random: Random(2),
);

/// Uygulamayı açar ve Profil > Sağlık topluluğu sayfasına gider.
Future<void> _openCommunity(
  WidgetTester tester,
  CommunityService server, {
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
      community: server,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(NavigationDestination).at(3));
  await tester.pumpAndSettle();
  final tile = find.byIcon(Icons.family_restroom);
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
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
  expect(find.byType(CommunityScreen), findsOneWidget);
}

Finder _inGroup(Finder f) =>
    find.descendant(of: find.byType(GroupScreen), matching: f);

Future<void> _scrollTo(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(
      f,
      200,
      scrollable: _inGroup(find.byType(Scrollable)).first,
    );

/// Öğeyi görünür alana getirip dokunur (liste alttaki düğmenin arkasında
/// kalabilir).
Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

void main() {
  group('sahte topluluk sunucusu', () {
    test('paylaşım izni varsayılan olarak boş; açınca tarih yazılır', () async {
      final s = _server();
      final g = await s.createGroup('  Ailem ');
      expect(g.name, 'Ailem');
      expect(g.ownedByMe, isTrue);
      expect(g.myConsent.isEmpty, isTrue);
      expect(g.inviteCode, matches(RegExp(r'^[A-Z2-9]{6}$')));

      await s.setConsent(g.id, {ShareScope.heartRate, ShareScope.sleep});
      final after = s.group(g.id)!;
      expect(after.myConsent.scopes, {ShareScope.heartRate, ShareScope.sleep});
      expect(after.myConsent.grantedAt, isNotNull);
      expect(after.members.firstWhere((m) => m.isMe).shares, hasLength(2));

      await s.setConsent(g.id, {});
      expect(s.group(g.id)!.myConsent.grantedAt, isNull);
    });

    test('davet edilen kişi bir süre sonra katılır ve mesaj gelir', () async {
      final s = _server(acceptDelay: const Duration(milliseconds: 10));
      final g = await s.createGroup('Ailem');
      final before = s.unreadCount;
      await s.invite(g.id, 'Ayşe');
      expect(s.group(g.id)!.members.last.pending, isTrue);
      expect(s.group(g.id)!.memberCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final ayse = s.group(g.id)!.members.last;
      expect(ayse.pending, isFalse);
      expect(ayse.shares, isNotEmpty);
      expect(s.unreadCount, before + 1);
      expect(s.messages.first.kind, CommunityMessageKind.memberJoined);
      s.dispose();
    });

    test('kodla katılma, davet kabulü ve ayrılma', () async {
      final s = _server();
      expect(await s.joinWithCode('XXXXXX'), isNull);
      final kaya = await s.joinWithCode(' kaya24 ');
      expect(kaya!.name, 'Kaya ailesi');
      expect(s.joinedGroups, hasLength(1));
      // Aynı kod ikinci kez grubu çoğaltmaz.
      await s.joinWithCode(FakeCommunityServer.demoCode);
      expect(s.joinedGroups, hasLength(1));

      final invite = s.messages.firstWhere(
        (m) => m.kind == CommunityMessageKind.invite,
      );
      await s.answerInvite(invite.id, accept: true);
      expect(s.joinedGroups.map((g) => g.name), contains('Elif'));
      expect(s.messages.firstWhere((m) => m.id == invite.id).answered, isTrue);

      await s.leave(kaya.id);
      expect(s.joinedGroups.map((g) => g.name), ['Elif']);
      expect(s.group(kaya.id), isNull);
    });
  });

  testWidgets('grup oluştur, izin ver, üye davet et', (tester) async {
    final server = _server(acceptDelay: const Duration(seconds: 2));
    await _openCommunity(tester, server);
    expect(
      find.text(
        'Henüz bir grubunuz yok. Bir grup oluşturup ailenizi davet edin.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Yeni grup oluştur'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ailem');
    await tester.pump();
    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupScreen), findsOneWidget);
    await _scrollTo(tester, _inGroup(find.text('Siz · Grup sahibi')));
    expect(_inGroup(find.text('Henüz bir şey paylaşmıyor')), findsNothing);

    // Nabız paylaşımını aç: izin tarihi görünür, üye satırı güncellenir.
    await tester.drag(
      _inGroup(find.byType(Scrollable)).first,
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    await tester.tap(_inGroup(find.text('Nabız')));
    await tester.pumpAndSettle();
    expect(_inGroup(find.textContaining('İzin tarihi:')), findsOneWidget);
    await _scrollTo(tester, _inGroup(find.text('Paylaşıyor: Nabız')));
    expect(_inGroup(find.text('Paylaşıyor: Nabız')), findsOneWidget);

    await _scrollTo(tester, _inGroup(find.text('Üye davet et')));
    await _tap(tester, _inGroup(find.text('Üye davet et')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ayşe');
    await tester.pump();
    await tester.tap(find.text('Davet et'));
    await tester.pumpAndSettle();
    expect(find.text('Davet kodu'), findsOneWidget);
    expect(find.textContaining('Bu kodu Ayşe ile paylaşın.'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(_inGroup(find.text('Ayşe · Davet bekleniyor')), findsOneWidget);

    // Sahte sunucuda davetli kısa süre sonra katılır.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(_inGroup(find.text('Ayşe')), findsOneWidget);
    expect(server.group(server.myGroups.single.id)!.memberCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mesajlardan daveti kabul et, kodla katıl, gruptan ayrıl', (
    tester,
  ) async {
    final server = _server();
    await _openCommunity(tester, server);
    // Okunmamış davet rozeti.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Mesajlar'));
    await tester.pumpAndSettle();
    expect(find.text('Elif sizi "Elif" grubuna davet etti.'), findsOneWidget);
    await tester.tap(find.text('Katıl'));
    await tester.pumpAndSettle();
    expect(find.text('Yanıtlandı'), findsOneWidget);
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(server.unreadCount, 0);
    expect(find.text('Grup sahibi: Elif · 2 üye'), findsOneWidget);

    // Yanlış kod hata verir, doğru kod gruba katar.
    await _tap(tester, find.text('Kodla katıl'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abc123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Katıl'));
    await tester.pumpAndSettle();
    expect(find.text('Bu kodla bir grup bulunamadı.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'kaya24');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Katıl'));
    await tester.pumpAndSettle();
    expect(find.text('Kaya ailesi'), findsOneWidget);
    expect(find.text('"Kaya ailesi" grubuna katıldınız.'), findsOneWidget);
    // Bildirim kapanana kadar bekle; alttaki düğmenin üstünü örtüyor.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Katılınan grupta davet yok, ayrılma var.
    await _tap(tester, find.text('Kaya ailesi'));
    await tester.pumpAndSettle();
    expect(_inGroup(find.text('Üye davet et')), findsNothing);
    await _scrollTo(
      tester,
      _inGroup(find.text('Paylaşıyor: Nabız, Tansiyon (tahmini)')),
    );
    expect(
      _inGroup(find.text('Paylaşıyor: Nabız, Tansiyon (tahmini)')),
      findsOneWidget,
    );
    await _scrollTo(tester, _inGroup(find.text('Gruptan ayrıl')));
    await _tap(tester, _inGroup(find.text('Gruptan ayrıl')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Gruptan ayrıl'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupScreen), findsNothing);
    expect(find.text('Kaya ailesi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: topluluk ve grup sayfası 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final server = _server();
      final kaya = await server.joinWithCode(FakeCommunityServer.demoCode);
      final mine = await server.createGroup('Yener ve ailesi birlikte');
      await server.setConsent(mine.id, ShareScope.values.toSet());
      await _openCommunity(
        tester,
        server,
        language: lang,
        size: const Size(960, 1920),
      );
      expect(tester.takeException(), isNull);

      for (final g in [mine, kaya!]) {
        await _tap(tester, find.text(g.name).first);
        await tester.pumpAndSettle();
        await tester.drag(
          _inGroup(find.byType(Scrollable)).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
    });
  }
}
