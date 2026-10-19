import 'dart:math';

import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sağlık sekmesi geçmiş verileri gösterir', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(
        random: Random(3), realtimeInterval: const Duration(seconds: 1));
    final controller = DeviceController(device);
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.runAsync(() => controller.connect());
    expect(controller.lastSync, isNotNull, reason: '${controller.error}');

    await tester.tap(find.text('Sağlık'));
    await tester.pumpAndSettle();
    expect(find.text('Uyku'), findsOneWidget);
    expect(find.textContaining('Son güncelleme'), findsOneWidget);

    await tester.tap(find.text('Uyku'));
    await tester.pumpAndSettle();
    expect(find.text('Derin'), findsOneWidget);
    expect(find.text('Son 7 gece'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kalp Atış Hızı'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalp Atış Hızı'));
    await tester.pumpAndSettle();
    expect(find.text('En yüksek'), findsOneWidget);

    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();
    expect(find.text('Bu dönem için kayıt yok'), findsNothing);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });
}
