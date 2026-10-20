import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/app_shell.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DeviceController _controller() => DeviceController(
  FakeDevice(random: Random(3), realtimeInterval: const Duration(seconds: 30)),
  store: MemoryHealthStore(),
);

void main() {
  testWidgets('ilk açılışta dil seçilir, seçim önizlenir', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Test ortamında telefonun dili İngilizce.
    final settings = AppSettings.memory(language: null, languageChosen: false);
    await tester.pumpWidget(
      BileklikApp(controller: _controller(), settings: settings),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache wählen'), findsOneWidget);
    expect(settings.languageChosen, isFalse);

    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(settings.language, 'de');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Arapça seçilince ekran sağdan sola döner', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BileklikApp(
        controller: _controller(),
        settings: AppSettings.memory(language: 'ar'),
      ),
    );
    await tester.pumpAndSettle();
    final shell = tester.element(find.byType(AppShell));
    expect(Directionality.of(shell), TextDirection.rtl);
    expect(find.text('الرئيسية'), findsWidgets);
  });

  // Uzun Almanca sözcükler ve Arapça yazı, küçük ekranda ve büyük yazıda
  // taşmamalı. Taşma testte hata olarak yakalanır.
  for (final lang in ['ar', 'de', 'en']) {
    testWidgets('$lang: dört sekme 320 dp ve büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920); // 320 x 640 dp
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final controller = _controller();
      await tester.pumpWidget(
        BileklikApp(
          controller: controller,
          settings: AppSettings.memory(language: lang),
        ),
      );
      await tester.runAsync(() => controller.connect());
      await tester.pumpAndSettle();

      final tabs = find.descendant(
        of: find.byType(GlassNavBar),
        matching: find.byType(Pressable),
      );
      expect(tabs, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        await tester.tap(tabs.at(i));
        await tester.pumpAndSettle();
        // Sayfanın sonuna kadar kaydırıp her kartı çizdir.
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -4000));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
