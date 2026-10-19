import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  for (final (name, c) in [
    ('koyu', AppColors.dark),
    ('açık', AppColors.light),
  ]) {
    test('$name tema metin karşıtlığı WCAG AA', () {
      for (final bg in [c.background, c.surface, c.surfaceHigh]) {
        expect(_contrast(c.text, bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(c.muted, bg), greaterThanOrEqualTo(4.5));
      }
      expect(_contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
    });
  }

  testWidgets('tema Profil sekmesinden değiştirilir', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final settings = AppSettings.memory(themeMode: ThemeMode.light);
    final device = FakeDevice(random: Random(1));
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(
      BileklikApp(controller: controller, settings: settings),
    );
    Color bg() =>
        Theme.of(tester.element(find.text('Ana Sayfa')))
            .scaffoldBackgroundColor;
    expect(bg(), AppColors.light.background);

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genel ayarlar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Koyu'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Sayfa'));
    await tester.pumpAndSettle();
    expect(bg(), AppColors.dark.background);
    expect(tester.takeException(), isNull);
    device.dispose();
  });
}
