import 'dart:io';
import 'dart:math';

import 'package:bileklik/app_info.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/transport.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/pairing_screen.dart';
import 'package:bileklik/ui/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FakeDevice _device() => FakeDevice(
  random: Random(5),
  realtimeInterval: const Duration(seconds: 30),
  scanDelay: const Duration(milliseconds: 200),
);

Future<DeviceController> _openProfile(
  WidgetTester tester, {
  String language = 'tr',
  Size size = const Size(1080, 2340),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = DeviceController(_device(), store: MemoryHealthStore());
  await tester.pumpWidget(
    BileklikApp(
      controller: controller,
      settings: AppSettings.memory(language: language),
    ),
  );
  await tester.pumpAndSettle();
  final tabs = find.byType(NavigationDestination);
  await tester.tap(tabs.at(3));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  test('uygulama sürümü pubspec ile aynı', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  test('adres biçimi', () {
    expect(normalizeAddress('a1b2c3d4e5f6'), 'A1:B2:C3:D4:E5:F6');
    expect(normalizeAddress('A1-B2-C3 D4:E5:F6'), 'A1:B2:C3:D4:E5:F6');
    expect(normalizeAddress('A1:B2:C3'), isNull);
    expect(normalizeAddress('G1:B2:C3:D4:E5:F6'), isNull);
  });

  testWidgets('Profil menüsü bölümleri gösterir, yakında olanlar uyarır', (
    tester,
  ) async {
    await _openProfile(tester);
    for (final t in [
      'Kişisel bilgiler',
      'Cihaz',
      'Bileklik bağlı değil',
      'Genel ayarlar',
      'Aile ve hekimle paylaşım',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.text('Aile ve hekimle paylaşım'));
    await tester.pump();
    expect(find.text('Bu bölüm sonraki bir sürümde gelecek.'), findsOneWidget);
    // Bildirim kapanana kadar bekle; alttaki satırların üstünü örtüyor.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Hakkında'),
      200,
      scrollable: find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(appVersion), findsOneWidget);
    await tester.tap(find.text('Hakkında'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tıbbi cihaz değildir'), findsOneWidget);
  });

  testWidgets('bileklik aranır ve bağlanılır', (tester) async {
    final c = await _openProfile(tester);
    await tester.tap(find.text('Cihaz'));
    await tester.pumpAndSettle();
    expect(find.text('Bileklik eşleştirme'), findsOneWidget);

    await tester.tap(find.text('Aramayı başlat'));
    await tester.pump();
    expect(find.text('Aranıyor…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('JCV8'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Bağlan'));
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pumpAndSettle();
    expect(c.isConnected, isTrue);
    expect(find.text('Bağlantıyı kes'), findsOneWidget);
    expect(find.text('A1:B2:C3:D4:E5:F6', findRichText: true), findsNothing);
  });

  testWidgets('adresle eşleştirmede yanlış adres uyarılır', (tester) async {
    await _openProfile(tester);
    await tester.tap(find.text('Cihaz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adresle eşleştir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A1:B2');
    await tester.tap(find.widgetWithText(FilledButton, 'Bağlan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12 karakterdir'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '00:11:22:33:44:55');
    await tester.tap(find.widgetWithText(FilledButton, 'Bağlan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Bu adreste bir bileklik bulunamadı.'), findsOneWidget);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: menü ve eşleştirme 320 dp, büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openProfile(tester, language: lang, size: const Size(960, 1920));
      final menu = find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      );
      await tester.drag(menu, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(menu, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.watch).first);
      await tester.pumpAndSettle();
      final pairing = find.descendant(
        of: find.byType(PairingView),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byIcon(Icons.bluetooth_searching),
        200,
        scrollable: pairing,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bluetooth_searching));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byIcon(Icons.qr_code_2),
        200,
        scrollable: pairing,
      );
      await tester.pumpAndSettle();
      expect(find.text('JCV8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
