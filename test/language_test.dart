import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dil Profil sekmesinden değiştirilir', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final settings = AppSettings.memory(language: 'tr');
    final device = FakeDevice(random: Random(1));
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(
      BileklikApp(controller: controller, settings: settings),
    );

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genel ayarlar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dil'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Türkçe'), findsOneWidget);
    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    // Seçim önizlendiği için düğme artık İngilizce.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(settings.language, 'en');
    // Genel ayarlar sayfası da artık İngilizce; geri dönülür.
    expect(find.text('General settings'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final nav = find.byType(GlassNavBar);
    expect(
      find.descendant(of: nav, matching: find.text('Profile')),
      findsOneWidget,
    );
    expect(find.text('Profil'), findsNothing);
    expect(tester.takeException(), isNull);
    device.dispose();
  });
}
