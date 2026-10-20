import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/health_platform.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/health_platform_screen.dart';
import 'package:bileklik/ui/screens/profile_screen.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 20, 9);

MemoryHealthStore _store() => MemoryHealthStore()
  ..addMeasurements([
    Measurement(
      MetricType.heartRate,
      _now.subtract(const Duration(hours: 2)),
      72,
    ),
    Measurement(
      MetricType.heartRate,
      _now.subtract(const Duration(hours: 1)),
      75,
    ),
    Measurement(
      MetricType.steps,
      _now.subtract(const Duration(hours: 1)),
      1200,
    ),
    // 30 günden eski: aktarılmaz.
    Measurement(
      MetricType.heartRate,
      _now.subtract(const Duration(days: 40)),
      70,
    ),
  ])
  ..addSleep([
    SleepSession(
      _now.subtract(const Duration(hours: 9)),
      List.filled(420, SleepStage.light),
    ),
  ]);

HealthExportService _service(
  MemoryHealthStore store, {
  Set<ExportType> deny = const {},
  Duration debounce = const Duration(seconds: 2),
}) => HealthExportService(
  FakeHealthPlatform(latency: Duration.zero, deny: deny),
  store,
  debounce: debounce,
  clock: () => _now,
);

void main() {
  group('sağlık platformu aktarımı', () {
    test('izin verilen türlerin son 30 günü bir kez yazılır', () async {
      final store = _store();
      final s = _service(store);
      final platform = s.platform as FakeHealthPlatform;
      await s.connect({
        ExportType.heartRate,
        ExportType.activity,
        ExportType.sleep,
      });
      expect(s.connected, isTrue);
      expect(platform.written, {
        ExportType.heartRate: 2,
        ExportType.activity: 1,
        ExportType.sleep: 1,
      });
      expect(s.lastCount, 4);

      // Yeni bir şey yoksa tekrar yazılmaz.
      expect(await s.exportNow(), 0);

      // Geçmiş senkronla sonradan gelen eski bir kayıt da gider.
      store.addMeasurements([
        Measurement(
          MetricType.heartRate,
          _now.subtract(const Duration(days: 2)),
          68,
        ),
      ]);
      expect(await s.exportNow(), 1);
      expect(platform.written[ExportType.heartRate], 3);
      s.dispose();
    });

    test('kullanıcının izin vermediği tür aktarılmaz', () async {
      final s = _service(_store(), deny: {ExportType.heartRate});
      final ok = await s.connect({ExportType.heartRate, ExportType.sleep});
      expect(ok, {ExportType.sleep});
      expect((s.platform as FakeHealthPlatform).written.keys, [
        ExportType.sleep,
      ]);
      s.dispose();
    });

    test('hiç izin yoksa bağlanmaz; durdurunca sıfırlanır', () async {
      final s = _service(_store(), deny: ExportType.values.toSet());
      expect(await s.connect({ExportType.spo2}), isEmpty);
      expect(s.connected, isFalse);

      final t = _service(_store());
      await t.connect({ExportType.heartRate});
      t.disconnect();
      expect(t.connected, isFalse);
      expect(t.lastExport, isNull);
      s.dispose();
      t.dispose();
    });

    test(
      'depo değişince kısa bir beklemeden sonra kendiliğinden aktarır',
      () async {
        final store = _store();
        final s = _service(store, debounce: const Duration(milliseconds: 10));
        await s.connect({ExportType.spo2});
        store.addMeasurements([
          Measurement(
            MetricType.spo2,
            _now.subtract(const Duration(minutes: 5)),
            97,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect((s.platform as FakeHealthPlatform).written[ExportType.spo2], 1);
        s.dispose();
      },
    );
  });

  Future<HealthExportService> open(
    WidgetTester tester, {
    String language = 'tr',
    Size size = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = _store();
    final controller = DeviceController(
      FakeDevice(
        random: Random(5),
        realtimeInterval: const Duration(seconds: 30),
      ),
      store: store,
    );
    final service = _service(store);
    await tester.pumpWidget(
      BileklikApp(
        controller: controller,
        settings: AppSettings.memory(language: language),
        community: FakeCommunityServer(
          latency: Duration.zero,
          acceptDelay: null,
        ),
        healthExport: service,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(GlassNavBar),
            matching: find.byType(Pressable),
          )
          .at(3),
    );
    await tester.pumpAndSettle();
    final tile = find.byIcon(Icons.sync_alt);
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ProfileScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(HealthPlatformScreen), findsOneWidget);
    return service;
  }

  Finder inScreen(Finder f) =>
      find.descendant(of: find.byType(HealthPlatformScreen), matching: f);

  testWidgets('türleri seç, bağlan, aktar ve durdur', (tester) async {
    final service = await open(tester);
    // Marka adı soldan sağa yalıtılır.
    const name = '\u2066Health Connect\u2069';
    expect(find.text('$name ile bağlan'), findsOneWidget);

    // Uykuyu kapat; bağlanınca listede yalnızca seçilenler kalır.
    await tester.scrollUntilVisible(
      inScreen(find.text('Uyku')),
      200,
      scrollable: inScreen(find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(inScreen(find.text('Uyku')));
    await tester.pumpAndSettle();
    await tester.tap(inScreen(find.text('Uyku')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$name ile bağlan'));
    await tester.pumpAndSettle();

    expect(service.granted, isNot(contains(ExportType.sleep)));
    expect(service.granted, contains(ExportType.heartRate));
    await tester.drag(
      inScreen(find.byType(Scrollable)).first,
      const Offset(0, 3000),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bağlı'), findsOneWidget);
    expect(find.text('3 kayıt aktarıldı'), findsOneWidget);
    expect(inScreen(find.text('Uyku')), findsNothing);
    expect(find.textContaining('Son aktarım:'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Şimdi aktar'));
    await tester.pumpAndSettle();
    expect(find.text('Aktarılacak yeni kayıt yok'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final stop = inScreen(find.text('Aktarımı durdur'));
    await tester.scrollUntilVisible(
      stop,
      200,
      scrollable: inScreen(find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(stop);
    await tester.pumpAndSettle();
    await tester.tap(stop);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Aktarımı durdur'));
    await tester.pumpAndSettle();
    expect(service.connected, isFalse);
    expect(find.text('$name ile bağlan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: aktarım ekranı 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final service = await open(
        tester,
        language: lang,
        size: const Size(960, 1920),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();
      expect(service.connected, isTrue);
      await tester.drag(
        inScreen(find.byType(Scrollable)).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
