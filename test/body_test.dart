import 'dart:io';
import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/sqlite_health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/format.dart';
import 'package:bileklik/ui/screens/body_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

FakeDevice _device() => FakeDevice(
  random: Random(5),
  realtimeInterval: const Duration(seconds: 30),
);

void main() {
  group('hesap', () {
    test('VKİ ve sınıfları', () {
      expect(bodyMassIndex(70, 175), closeTo(22.86, 0.01));
      expect(BmiClass.of(18.4), BmiClass.under);
      expect(BmiClass.of(18.5), BmiClass.normal);
      expect(BmiClass.of(24.99), BmiClass.normal);
      expect(BmiClass.of(25), BmiClass.over);
      expect(BmiClass.of(30), BmiClass.obese);
    });

    test('ondalık virgül ve Arapça rakam', () {
      expect(parseDecimal('72,5'), 72.5);
      expect(parseDecimal(' 72.5 '), 72.5);
      expect(parseDecimal('٧٢٫٥'), 72.5);
      expect(parseDecimal('abc'), isNull);
    });

    test('ABD biriminde libre', () {
      addTearDown(() => DisplayPrefs.imperial = false);
      DisplayPrefs.imperial = true;
      expect(MetricType.weight.format(70), '154.3');
      expect(MetricType.weight.unit, 'lb');
      DisplayPrefs.imperial = false;
      expect(MetricType.weight.format(70), '70.0');
      expect(MetricType.weight.unit, 'kg');
    });
  });

  group('depo', () {
    final t = DateTime(2026, 10, 20, 8);
    test('bellekte silinir', () {
      final s = MemoryHealthStore();
      final w = Measurement(MetricType.weight, t, 72.5);
      s.addMeasurements([w, Measurement(MetricType.bmi, t, 23.7)]);
      s.removeMeasurements([w]);
      expect(s.latest(MetricType.weight), isNull);
      expect(s.latest(MetricType.bmi)!.value, 23.7);
      // Silinen kayıt yeniden eklenebilir.
      s.addMeasurements([w]);
      expect(s.latest(MetricType.weight), w);
    });

    test('SQLite: silinen kayıt açılışta gelmez', () async {
      sqfliteFfiInit();
      final dir = Directory.systemTemp.createTempSync('bileklik_body');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/b.db';
      final a = await SqliteHealthStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final w = Measurement(MetricType.weight, t, 80.2);
      final f = Measurement(MetricType.bodyFat, t, 21.5);
      a.addMeasurements([w, f]);
      a.removeMeasurements([w]);
      await a.close();
      final b = await SqliteHealthStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(b.latest(MetricType.weight), isNull);
      expect(b.latest(MetricType.bodyFat), f);
      await b.close();
    });
  });

  Future<(DeviceController, FakeDevice, AppSettings)> open(
    WidgetTester tester, {
    String language = 'tr',
    Size size = const Size(1080, 2340),
    int? height = 175,
    bool connect = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final device = _device();
    final c = DeviceController(device, store: MemoryHealthStore());
    final settings = AppSettings.memory(language: language, heightCm: height);
    await tester.pumpWidget(BileklikApp(controller: c, settings: settings));
    if (connect) await tester.runAsync(() => c.connect());
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const BodyScreen()));
    await tester.pumpAndSettle();
    return (c, device, settings);
  }

  testWidgets('kilo girilir, VKİ hesaplanır, bilekliğe yazılır', (
    tester,
  ) async {
    final (c, device, _) = await open(tester);
    expect(
      find.text(
        'Tartıldığınızda kilonuzu buraya girin; değişimi grafikte izleyin.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bu dönemde ölçüm yok.'), findsOneWidget);

    await tester.tap(find.text('Ölçüm ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni ölçüm'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '72,5');
    await tester.enterText(fields.at(1), '19');
    await tester.runAsync(() async {
      await tester.tap(find.text('Kaydet'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(c.store.latest(MetricType.weight)!.value, 72.5);
    expect(c.store.latest(MetricType.bodyFat)!.value, 19);
    expect(c.store.latest(MetricType.bmi)!.value, 23.7);
    expect(c.profile!.weightKg, 73);
    expect(find.widgetWithText(BodyScreen, '72.5'), findsWidgets);
    expect(find.text('Önceki ölçüm'), findsNothing);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.byType(WeightChart), findsOneWidget);
    await tester.runAsync(() => c.disconnect());
    device.dispose();
  });

  testWidgets('aralık dışı kilo kaydedilmez', (tester) async {
    final (c, device, _) = await open(tester, connect: false);
    await tester.tap(find.text('Ölçüm ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('20 ile 300 arasında olmalı'), findsOneWidget);
    expect(c.store.latest(MetricType.weight), isNull);

    // Kas kütlesi kilodan büyük olamaz.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '60');
    await tester.enterText(fields.at(2), '61');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Kas kütlesi kilodan büyük olamaz'), findsOneWidget);
    device.dispose();
  });

  testWidgets('boy yoksa VKİ istenir; değişim ve silme', (tester) async {
    final (c, device, settings) = await open(
      tester,
      height: null,
      connect: false,
    );
    expect(find.text('VKİ için boyunuzu girin.'), findsOneWidget);
    final now = DateTime.now();
    c.store.addMeasurements([
      Measurement(MetricType.weight, now.subtract(const Duration(days: 3)), 80),
      Measurement(MetricType.weight, now, 79.2),
    ]);
    await tester.pumpAndSettle();
    expect(find.textContaining('−0.8 kg'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Geçmiş'), 200);

    await tester.scrollUntilVisible(find.byTooltip('Sil').first, 200);
    await tester.tap(find.byTooltip('Sil').first);
    await tester.pumpAndSettle();
    expect(find.text('Ölçüm silinsin mi?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
    await tester.pumpAndSettle();
    expect(c.store.latest(MetricType.weight)!.value, 80);
    expect(settings.heightCm, isNull);
    device.dispose();
  });

  for (final lang in ['ar', 'de', 'en']) {
    testWidgets('$lang: vücut ekranı 320 dp\'de taşmaz', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, device, _) = await open(
        tester,
        language: lang,
        size: const Size(960, 1920),
        connect: false,
      );
      final now = DateTime.now();
      c.store.addMeasurements([
        for (var i = 0; i < 40; i++) ...[
          Measurement(
            MetricType.weight,
            now.subtract(Duration(days: i * 3)),
            118.4 - i * 0.3,
          ),
          Measurement(
            MetricType.bmi,
            now.subtract(Duration(days: i * 3)),
            38.7,
          ),
        ],
        Measurement(MetricType.bodyFat, now, 34.5),
        Measurement(MetricType.muscleMass, now, 48.2),
      ]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final year = find.text(switch (lang) {
        'ar' => 'سنة',
        'de' => '1 Jahr',
        _ => '1 year',
      });
      await tester.scrollUntilVisible(year, 200);
      await tester.tap(year);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      device.dispose();
    });
  }
}
