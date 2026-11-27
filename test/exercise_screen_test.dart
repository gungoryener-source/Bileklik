import 'dart:math';

import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/ui/screens/live_exercise_screen.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('egzersiz başlatılır, bitirilir ve özet görünür', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(
      random: Random(5),
      realtimeInterval: const Duration(seconds: 30),
      exerciseInterval: const Duration(milliseconds: 5),
    );
    final controller = DeviceController(device);
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.runAsync(() => controller.connect());

    await tester.tap(find.text('Egzersiz'));
    await tester.pumpAndSettle();
    expect(find.text('Toplam süre'), findsOneWidget);
    expect(find.text('Toplam sayı'), findsOneWidget);
    expect(find.text('Egzersiz kayıtlarını görüntüle'), findsOneWidget);

    // Kayıtlar ekranı geçmiş egzersizleri listeler.
    await tester.tap(find.text('Egzersiz kayıtlarını görüntüle'));
    await tester.pumpAndSettle();
    expect(find.text('Egzersiz kayıtları'), findsOneWidget);
    expect(find.textContaining('kcal'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Hedef seçilir, canlı ekranda ilerlemesi görünür.
    await tester.tap(find.byIcon(Icons.track_changes));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 dk'));
    await tester.pumpAndSettle();
    expect(find.text('30 dk'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.bySemanticsLabel('Koşu egzersizini başlat'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('Duraklat'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Hedef: 30 dk'), findsOneWidget);

    await tester.tap(find.text('Bitir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Bitir').last);
    for (var i = 0; i < 5; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Tebrikler, egzersiz kaydedildi'), findsOneWidget);
    expect(find.text('Ortalama nabız'), findsOneWidget);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });

  testWidgets('bağlı değilken spora dokununca bağlanır ve egzersiz açılır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(
      random: Random(5),
      realtimeInterval: const Duration(seconds: 30),
      exerciseInterval: const Duration(milliseconds: 5),
    );
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.pumpAndSettle();
    expect(controller.isConnected, isFalse);

    await tester.tap(find.text('Egzersiz'));
    await tester.pumpAndSettle();

    // "Daha fazla" ile başka spor seçilir; sekme onun adını alır.
    await tester.tap(find.text('Daha fazla'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tenis').last);
    await tester.pumpAndSettle();
    expect(find.text('Daha fazla'), findsNothing);
    await tester.tap(find.text('Koşu').first);
    await tester.pumpAndSettle();

    // Bağlı değilken başlat düğmesi önce bağlanır.
    await tester.tap(find.bySemanticsLabel('Koşu egzersizini başlat'));
    // Canlı egzersiz ekranı sayaç çalıştırdığı için durulmaz; adım adım ilerlet.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(controller.isConnected, isTrue);
    expect(find.byType(LiveExerciseScreen), findsOneWidget);

    await controller.disconnect();
    await tester.pump(const Duration(seconds: 1));
    device.dispose();
  });
}
