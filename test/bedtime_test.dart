import 'dart:async';
import 'dart:math';

import 'package:bileklik/data/bedtime.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/bedtime_screen.dart';
import 'package:bileklik/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SleepSession _sleep(DateTime start, {int minutes = 420}) =>
    SleepSession(start, List.filled(minutes, SleepStage.light));

/// Yatma Düzeni listesini öğe kurulana dek aşağı kaydırır.
Future<void> _reveal(WidgetTester tester, Finder f) async {
  for (var i = 0; i < 20 && f.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
}

void main() {
  group('yatma düzeni', () {
    test('her akşamın ilk yatışı bulunur, şekerleme sayılmaz', () {
      final store = MemoryHealthStore();
      // 23 Kasım 2026 pazartesi.
      store.addSleep([
        _sleep(DateTime(2026, 11, 23, 22, 10)), // pzt, 50 dk erken
        _sleep(DateTime(2026, 11, 24, 23, 20)), // sal, uygun
        _sleep(DateTime(2026, 11, 26, 0, 40)), // çar akşamı, geç
        _sleep(DateTime(2026, 11, 26, 14), minutes: 40), // per şekerleme
        _sleep(DateTime(2026, 11, 29, 22, 45)), // paz, uygun
        _sleep(DateTime(2026, 11, 30, 23)), // gelecek hafta
      ]);
      final w = BedtimeWeek.of(store, DateTime(2026, 11, 27));
      expect(w.range.start, DateTime(2026, 11, 23));
      expect(w.bedtimes, [
        DateTime(2026, 11, 23, 22, 10),
        DateTime(2026, 11, 24, 23, 20),
        DateTime(2026, 11, 26, 0, 40),
        null,
        null,
        null,
        DateTime(2026, 11, 29, 22, 45),
      ]);
      expect(
        [for (final t in w.recorded) BedtimeWeek.deviation(t)],
        [-50, 20, 100, -15],
      );
      expect(w.onTrackCount, 2);
    });

    test('ilk oturum kullanılır; gece bölünse de tek yatış', () {
      final store = MemoryHealthStore()
        ..addSleep([
          _sleep(DateTime(2026, 11, 24, 23, 5), minutes: 120),
          _sleep(DateTime(2026, 11, 25, 1, 5), minutes: 120),
        ]);
      final w = BedtimeWeek.of(store, DateTime(2026, 11, 24));
      expect(w.bedtimes[1], DateTime(2026, 11, 24, 23, 5));
      expect(w.recorded, hasLength(1));
    });

    test('gece görünümü 22:00-05:00 arası', () {
      expect(isWindDownTime(DateTime(2026, 11, 27, 21, 59)), isFalse);
      expect(isWindDownTime(DateTime(2026, 11, 27, 22)), isTrue);
      expect(isWindDownTime(DateTime(2026, 11, 28, 4, 59)), isTrue);
      expect(isWindDownTime(DateTime(2026, 11, 28, 5)), isFalse);
      expect(
        nextWindDownChange(DateTime(2026, 11, 27, 13)),
        DateTime(2026, 11, 27, 22),
      );
      expect(
        nextWindDownChange(DateTime(2026, 11, 27, 23)),
        DateTime(2026, 11, 28, 5),
      );
      expect(
        nextWindDownChange(DateTime(2026, 11, 28, 2)),
        DateTime(2026, 11, 28, 5),
      );
    });
  });

  group('gece ana sayfası', () {
    tearDown(() => HomeScreen.clock = DateTime.now);

    testWidgets('gece sakinleşme görünümü, Daha fazla bilgi yatma düzenini '
        'açar; küçük ekranda taşmaz', (tester) async {
      tester.view.physicalSize = const Size(960, 1920); // 320 x 640 dp
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final n = DateTime.now();
      HomeScreen.clock = () => DateTime(n.year, n.month, n.day, 23, 30);

      final device = FakeDevice(random: Random(3));
      final controller = DeviceController(device, store: MemoryHealthStore());
      await tester.pumpWidget(BileklikApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('Gece geç oldu, rahatlamayı deneyin'), findsOneWidget);
      expect(find.text('Enerji'), findsNothing);
      // Göstergeler ve düğmeler gece de yerinde.
      expect(find.text('Günlük toparlanma'), findsOneWidget);
      expect(find.text('Antrenman planı'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Daha fazla bilgi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daha fazla bilgi'));
      await tester.pumpAndSettle();
      expect(find.text('Yatma düzeni'), findsOneWidget);
      expect(find.text('Sakinleşme zamanı'), findsOneWidget);
      final empty = find.textContaining('Bu hafta yatış kaydı yok');
      await _reveal(tester, empty);
      expect(empty, findsOneWidget);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(
        find.text('İstikrarlı bir yatma saati nasıl bulunur'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      device.dispose();
    });

    testWidgets('gündüz enerji kristali görünür', (tester) async {
      final n = DateTime.now();
      HomeScreen.clock = () => DateTime(n.year, n.month, n.day, 12);
      final device = FakeDevice(random: Random(3));
      final controller = DeviceController(device, store: MemoryHealthStore());
      await tester.pumpWidget(BileklikApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Enerji'), findsOneWidget);
      expect(find.text('Daha fazla bilgi'), findsNothing);
      device.dispose();
    });
  });

  for (final lang in ['tr', 'en', 'ar', 'de']) {
    testWidgets('$lang: yatma düzeni verili hafta, dar ekran ve büyük yazı', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final store = MemoryHealthStore()
        ..addSleep([
          _sleep(DateTime(2026, 11, 23, 23, 5)),
          _sleep(DateTime(2026, 11, 26, 21, 27)),
          _sleep(DateTime(2026, 11, 27, 21, 37)),
          _sleep(DateTime(2026, 11, 28, 20, 28)),
          // Grafik aralığının dışı: eksen 03:00'e genişler.
          _sleep(DateTime(2026, 11, 30, 2, 15)),
        ]);
      final device = FakeDevice(random: Random(3));
      final controller = DeviceController(device, store: store);
      await tester.pumpWidget(
        BileklikApp(
          controller: controller,
          settings: AppSettings.memory(language: lang),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => BedtimeScreen(
                  day: DateTime(2026, 11, 27),
                  now: DateTime(2026, 11, 28, 23),
                ),
              ),
            ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (lang == 'tr') {
        final summary = find.text('İdeal aralıkta yatılan gece: 1/5');
        await _reveal(tester, summary);
        expect(summary, findsOneWidget);
        // Gelecek hafta yok; önceki haftaya geçilir, orası boş.
        final next = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.chevron_right),
        );
        expect(next.onPressed, isNull);
        await tester.ensureVisible(find.byTooltip('Önceki'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Önceki'));
        await tester.pumpAndSettle();
        final empty = find.textContaining('Bu hafta yatış kaydı yok');
        await _reveal(tester, empty);
        expect(empty, findsOneWidget);
      }
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      device.dispose();
    });
  }
}
