import 'dart:math';

import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('EKG ölçülür ve kayıt ekranı açılır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(
      random: Random(6),
      realtimeInterval: const Duration(seconds: 30),
      ecgPacketInterval: const Duration(microseconds: 500),
    );
    final controller = DeviceController(device);
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.runAsync(() => controller.connect());

    await tester.tap(find.text('Sağlık'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EKG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 saniyelik ölçüm başlat'));
    await tester.pumpAndSettle();
    // Hazırlık: el seçimi ve talimatlar.
    expect(find.text('Bileklik hangi bileğinizde?'), findsOneWidget);
    expect(find.text('Sol el'), findsOneWidget);
    await tester.tap(find.text('Sağ el'));
    await tester.pump();
    await tester.tap(find.text('Ölçümü başlat'));
    for (var i = 0; i < 40; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Ortalama nabız'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('tıbbi tanı yerine geçmez'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('tıbbi tanı yerine geçmez'), findsOneWidget);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.textContaining('bpm ortalama'), findsOneWidget);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });
}
