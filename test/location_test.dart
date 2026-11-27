import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/location_share.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/location_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FakeCommunityServer _server() =>
    FakeCommunityServer(latency: Duration.zero, acceptDelay: null);

void main() {
  test('konum paylaşımı varsayılan kapalı, seçilen kişiyle açılır', () async {
    final s = _server();
    expect(s.sharingLocation, isFalse);
    expect(s.sharedWithMe, isEmpty);

    final g = (await s.joinWithCode(FakeCommunityServer.demoCode))!;
    // Ahmet konumunu paylaşıyor, Zeynep paylaşmıyor.
    expect(s.sharedWithMe.map((e) => e.member.name), ['Ahmet']);
    expect(s.sharingLocation, isFalse);

    await s.setLocationShare(g.id, {'m-zeynep'});
    expect(s.sharingLocation, isTrue);
    expect(s.locationViewers, {'Zeynep'});

    final reporter = LocationReporter(
      s,
      source: FakeLocationSource(random: Random(1)),
    );
    await reporter.report();
    expect(s.myLocation, isNotNull);

    await s.stopLocationSharing();
    expect(s.sharingLocation, isFalse);
    expect(s.myLocation, isNull);
    reporter.dispose();
  });

  test('gruptan ayrılınca o gruptaki paylaşım biter', () async {
    final s = _server();
    final g = (await s.joinWithCode(FakeCommunityServer.demoCode))!;
    await s.setLocationShare(g.id, {'m-ahmet'});
    expect(s.sharingLocation, isTrue);
    await s.leave(g.id);
    expect(s.sharingLocation, isFalse);
  });

  test('konum alınamazsa neden saklanır', () async {
    final s = _server();
    final g = (await s.joinWithCode(FakeCommunityServer.demoCode))!;
    await s.setLocationShare(g.id, {'m-ahmet'});
    final reporter = LocationReporter(s, source: _Denied());
    await reporter.report();
    expect(s.locationProblem, LocationProblem.denied);
    reporter.dispose();
  });

  testWidgets('konum ekranı: kişi seçilir, şerit görünür, durdurulur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final s = _server();
    await s.joinWithCode(FakeCommunityServer.demoCode);
    final device = FakeDevice(random: Random(5));
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller, community: s));
    await tester.pumpAndSettle();
    expect(find.text('Konumunuz paylaşılıyor'), findsNothing);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const LocationScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Konumunuz kimseyle paylaşılmıyor.'), findsOneWidget);
    expect(find.text('Ahmet'), findsWidgets);

    await tester.tap(find.text('Paylaşımı aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ahmet').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(s.locationViewers, {'Ahmet'});
    expect(find.text('Konumunuzu görenler: Ahmet'), findsOneWidget);
    expect(find.textContaining('Son gönderim'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // Paylaşım açıkken her sekmenin üstünde şerit var.
    expect(find.text('Konumunuz paylaşılıyor'), findsOneWidget);

    await tester.tap(find.text('Konumunuz paylaşılıyor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paylaşımı durdur'));
    await tester.pumpAndSettle();
    expect(s.sharingLocation, isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Konumunuz paylaşılıyor'), findsNothing);
    device.dispose();
  });
}

class _Denied implements LocationSource {
  @override
  Future<SharedLocation> current() async =>
      throw const LocationException(LocationProblem.denied);
}
