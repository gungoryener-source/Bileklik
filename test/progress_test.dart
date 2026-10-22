import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/progress.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pazartesi.
final _monday = DateTime(2026, 10, 19);

DateTime _day(int offset) =>
    DateTime(_monday.year, _monday.month, _monday.day + offset);

/// [day] sabahına biten 8 saatlik gece: 300 dk hafif, 100 derin, 80 REM.
SleepSession _night(DateTime day) => SleepSession(
  DateTime(day.year, day.month, day.day - 1, 23),
  [
    ...List.filled(300, SleepStage.light),
    ...List.filled(100, SleepStage.deep),
    ...List.filled(80, SleepStage.rem),
  ],
);

void main() {
  test('enerji: uyku ve toparlanma doldurur, adım harcar', () {
    final day = _day(2);
    final store = MemoryHealthStore()
      ..addSleep([_night(day)])
      ..addMeasurements([
        // Son iki haftanın HRV ortancası 50 ms.
        for (var i = 1; i <= 14; i++)
          Measurement(
            MetricType.hrv,
            DateTime(day.year, day.month, day.day - i, 12),
            50,
          ),
        // Gece HRV'si 60 ms: ortancadan %20 yüksek.
        Measurement(MetricType.hrv, DateTime(day.year, day.month, day.day, 2), 60),
        Measurement(MetricType.steps, DateTime(day.year, day.month, day.day, 10), 7500),
      ]);
    final e = EnergyScore.of(store, day)!;
    // Süre 8 saat → 70; derin+REM 180/480 → 28,1 ⇒ 98.
    expect(e.sleepScore, 98);
    // 50 + 0,2 × 150.
    expect(e.recoveryScore, 80);
    // 7500 / 15000 × 25.
    expect(e.drain, 13);
    // 0,6 × 98 + 0,4 × 80 − 13.
    expect(e.score, 78);
    expect(e.level, EnergyLevel.high);

    expect(EnergyScore.of(MemoryHealthStore(), day), isNull);
  });

  test('haftalık rapor ve önceki haftayla karşılaştırma', () {
    final store = MemoryHealthStore()
      ..addMeasurements([
        for (var d = 0; d < 7; d++) ...[
          Measurement(MetricType.steps, _day(d).add(const Duration(hours: 12)), 12000),
          Measurement(MetricType.steps, _day(d - 7).add(const Duration(hours: 12)), 6000),
          Measurement(MetricType.stress, _day(d).add(const Duration(hours: 9)), 30),
        ],
      ])
      ..addSleep([_night(_day(1)), _night(_day(2))]);
    final r = WeeklyReport.of(store, _day(3));
    expect(r.current.range.start, _monday);
    expect(r.current.steps, 84000);
    expect(r.current.averageSteps, 12000);
    expect(r.current.goalDays, 7);
    expect(r.previous.goalDays, 0);
    expect(r.current.averageSleepMinutes, 480);
    expect(r.current.averageStress, 30);
    expect(WeeklyReport.change(r.current.steps, r.previous.steps), 100);
    expect(WeeklyReport.change(5, 0), isNull);
    expect(WeeklyReport.change(null, 3), isNull);
  });

  test('rozetler geçmişten hesaplanır', () {
    final store = MemoryHealthStore()
      ..addMeasurements([
        for (var d = 0; d < 8; d++)
          Measurement(MetricType.steps, _day(d).add(const Duration(hours: 12)), 12000),
      ]);
    final list = achievements(store, _day(9));
    Achievement of(AchievementKind k) => list.firstWhere((a) => a.kind == k);

    expect(list, hasLength(AchievementKind.values.length));
    expect(of(AchievementKind.firstSync).earnedOn, _day(0));
    expect(of(AchievementKind.steps10k).earnedOn, _day(0));
    expect(of(AchievementKind.goalStreak7).earnedOn, _day(6));
    final twenty = of(AchievementKind.steps20k);
    expect(twenty.earned, isFalse);
    expect(twenty.progress, closeTo(0.6, 0.001));
    expect(of(AchievementKind.wear30).progress, closeTo(8 / 30, 0.001));
    expect(of(AchievementKind.firstEcg).progress, 0);
    expect(of(AchievementKind.workouts10).earned, isFalse);
  });

  testWidgets('İlerleme ekranı enerjiyi, raporu ve rozetleri gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final day = _day(2);
    final store = MemoryHealthStore()
      ..addSleep([_night(day)])
      ..addMeasurements([
        for (var d = 0; d < 3; d++)
          Measurement(MetricType.steps, _day(d).add(const Duration(hours: 12)), 11000),
      ]);
    final controller = DeviceController(FakeDevice(random: Random(5)), store: store);
    await tester.pumpWidget(
      BileklikApp(controller: controller, settings: AppSettings.memory()),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ProgressScreen(day: day, now: _day(3)),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('İlerleme'), findsOneWidget);
    expect(find.text('Haftalık rapor'), findsOneWidget);
    // Uyku 98, HRV yok: enerji 98 − 18 (11.000 adım).
    expect(find.text('80'), findsOneWidget);

    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('10.000 adım'), 200, scrollable: list);
    expect(find.textContaining('tarihinde kazanıldı'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Sadık bileklik'), 200, scrollable: list);
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: İlerleme ekranı 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final day = _day(2);
      final store = MemoryHealthStore()..addSleep([_night(day)]);
      final controller = DeviceController(FakeDevice(random: Random(5)), store: store);
      await tester.pumpWidget(
        BileklikApp(
          controller: controller,
          settings: AppSettings.memory(language: lang),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ProgressScreen(day: day, now: _day(3)),
            ),
          );
      await tester.pumpAndSettle();
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
