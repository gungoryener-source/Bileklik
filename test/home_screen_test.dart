import 'dart:math';

import 'package:bileklik/data/day_summary.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('günün özeti', () {
    test('adım, kalori ve mesafe toplanır; nabız saatlik ortalanır', () {
      final store = MemoryHealthStore();
      final day = DateTime(2026, 10, 19);
      store.addMeasurements([
        Measurement(MetricType.steps, DateTime(2026, 10, 19, 8), 500),
        Measurement(MetricType.steps, DateTime(2026, 10, 19, 9), 700),
        Measurement(MetricType.steps, DateTime(2026, 10, 18, 9), 900),
        Measurement(MetricType.calories, DateTime(2026, 10, 19, 8), 20),
        Measurement(MetricType.distance, DateTime(2026, 10, 19, 8), 0.35),
        Measurement(MetricType.heartRate, DateTime(2026, 10, 19, 8), 60),
        Measurement(MetricType.heartRate, DateTime(2026, 10, 19, 8, 30), 80),
      ]);
      final s = DaySummary.of(store, day);
      expect(s.steps, 1200);
      expect(s.calories, 20);
      expect(s.distanceKm, 0.35);
      expect(s.hourlyHeartRate[8], 70);
      expect(s.hourlyHeartRate[9], isNull);
      expect(s.heartRateStats!.min, 60);
      expect(s.night, isNull);
      expect(s.timeline, isEmpty);
    });

    test('sahte bileklikte dün gecenin uykusu bugüne yazılır', () async {
      final device = FakeDevice(
        random: Random(5),
        realtimeInterval: const Duration(seconds: 30),
      );
      final c = DeviceController(device, store: MemoryHealthStore());
      await c.connect();
      final now = DateTime.now();
      final s = DaySummary.of(c.store, now);
      // Sahte bileklik her gece uyku üretir; sabah 8'den önce uyanış sürmüş olabilir.
      if (now.hour >= 8) {
        expect(s.night, isNotNull);
        expect(s.night!.asleepMinutes, greaterThan(180));
        expect(s.timeline.whereType<SleepEvent>(), hasLength(1));
      }
      expect(s.calories, greaterThanOrEqualTo(0));
      await c.disconnect();
      device.dispose();
    });
  });

  testWidgets('Ana Sayfa veri yokken yönlendirir, küçük ekranda taşmaz', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 1920); // 320 x 640 dp
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final device = FakeDevice(random: Random(3));
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Dün gece uyku ölçülmedi'), findsOneWidget);
    expect(find.text('Bağlan'), findsOneWidget);
    for (final title in [
      'Uyku',
      'Aktivite',
      'Denge',
      'Kalp Atış Hızı',
      'Kan Oksijen Doygunluğu',
      'Zaman çizelgesi',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(find.textContaining('bilekliği gün boyu takın'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    device.dispose();
  });

  testWidgets('Ana Sayfa günün verisini gösterir, günler arasında gezilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(
      random: Random(3),
      realtimeInterval: const Duration(seconds: 30),
    );
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.runAsync(() => controller.connect());
    await tester.pumpAndSettle();

    expect(find.textContaining('Bugün,'), findsOneWidget);
    expect(find.textContaining('Bağlı ·'), findsOneWidget);
    // Bileklik takılı olmadığı için ölçemediği gün yerine dün tam bir gündür.
    await tester.tap(find.byTooltip('Önceki gün'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dün,'), findsOneWidget);
    expect(find.text('Günün özeti'), findsOneWidget);
    expect(find.text('Dün gece uyku ölçülmedi'), findsNothing);
    expect(find.textContaining('uyudunuz'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Kilometre'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('hedef 10000'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Uyandınız'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Uyandınız'), findsOneWidget);

    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sonraki gün'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bugün,'), findsOneWidget);

    await tester.tap(find.text('Egzersize başla'));
    await tester.pumpAndSettle();
    expect(find.text('Koşu'), findsWidgets);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });
}
