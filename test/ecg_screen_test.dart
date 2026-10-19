import 'dart:math';

import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EKG ölçülür ve kayıt ekranı açılır', (tester) async {
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
    expect(find.text('Nasıl ölçülür'), findsOneWidget);

    await tester.tap(find.text('30 saniyelik ölçüm başlat'));
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

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('bpm ortalama'), findsOneWidget);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });
}
