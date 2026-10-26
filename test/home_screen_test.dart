import 'dart:math';

import 'package:bileklik/data/day_summary.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ana Sayfa listesini öğe kurulana dek aşağı kaydırır, sonra görünür
/// alana getirir. Alt menü içeriğin üstünde yüzdüğü için isabet testi
/// yerine bu yol kullanılır.
Future<void> _reveal(WidgetTester tester, Finder f) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
}

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

    expect(find.text('Bağlı değil'), findsOneWidget);
    for (final title in [
      'Nabız',
      'Nabız ölç',
      'Uyku',
      'Adım',
      'Kalori',
      'Aktif süre',
      'Dün gece uyku ölçülmedi',
      'Denge',
      'Kalp Atış Hızı',
      'Kan Oksijen Doygunluğu',
      'Zaman çizelgesi',
    ]) {
      await _reveal(tester, find.text(title, skipOffstage: false));
      expect(find.text(title), findsWidgets);
      expect(tester.takeException(), isNull, reason: title);
    }
    expect(
      find.textContaining('bilekliği gün boyu takın', skipOffstage: false),
      findsNWidgets(2),
    );
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

    expect(find.text('Bugün'), findsOneWidget);
    expect(find.textContaining('Bağlı ·'), findsOneWidget);
    expect(find.text('Canlı'), findsOneWidget);
    // Bileklik takılı olmadığı için ölçemediği gün yerine dün tam bir gündür.
    await tester.tap(find.byTooltip('Önceki gün'));
    await tester.pumpAndSettle();
    expect(find.text('Dün'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Günün özeti'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dün gece uyku ölçülmedi'), findsNothing);
    expect(find.textContaining('uyudunuz'), findsOneWidget);

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
    expect(find.text('Bugün'), findsOneWidget);

    await tester.tap(find.text('Egzersize başla'));
    await tester.pumpAndSettle();
    expect(find.text('Koşu'), findsWidgets);

    await tester.runAsync(() => controller.disconnect());
    device.dispose();
  });

  testWidgets('bileklik bağlı değilken nabız kartı yönlendirir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(random: Random(3));
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(BileklikApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Bağlı değil'), findsOneWidget);
    expect(find.text('Canlı'), findsNothing);
    expect(
      find.text('Nabzınızı görmek için bilekliği bağlayın.'),
      findsOneWidget,
    );
    final measure = tester.widget<GlowButton>(
      find.widgetWithText(GlowButton, 'Şimdi ölç'),
    );
    expect(measure.onTap, isNull);

    // Çipe dokununca bağlanır; düğme etkinleşir. Sahte bilekliğin
    // zamanlayıcıları test saatinde ilerler.
    await tester.tap(find.text('Bağlı değil'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(controller.isConnected, isTrue);
    expect(
      tester
          .widget<GlowButton>(find.widgetWithText(GlowButton, 'Şimdi ölç'))
          .onTap,
      isNotNull,
    );
    await controller.disconnect();
    await tester.pumpAndSettle();
    device.dispose();
  });

  for (final lang in ['tr', 'ar', 'de']) {
    testWidgets('$lang: veri yokken ızgara boş durum gösterir, taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920); // 320 x 640 dp
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final device = FakeDevice(random: Random(3));
      final controller = DeviceController(device, store: MemoryHealthStore());
      await tester.pumpWidget(
        BileklikApp(
          controller: controller,
          settings: AppSettings.memory(language: lang),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).first;
      await _reveal(tester, find.byType(Flame3D, skipOffstage: false));
      // Nabız, uyku, adım, kalori ve aktif süre değeri yok: "--".
      expect(find.text('--', skipOffstage: false), findsAtLeastNWidgets(4));
      if (lang == 'tr') {
        expect(find.text('Kayıt yok', skipOffstage: false), findsWidgets);
        expect(
          find.text('Hedef 10000 adım', skipOffstage: false),
          findsOneWidget,
        );
      }
      await tester.drag(scrollable, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      device.dispose();
    });
  }
}
