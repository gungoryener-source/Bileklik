import 'dart:math';

import 'package:bileklik/data/aggregate.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/recovery.dart';
import 'package:bileklik/data/sleep_analysis.dart';
import 'package:bileklik/data/strain.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/recovery_screen.dart';
import 'package:bileklik/ui/screens/sleep_screen.dart';
import 'package:bileklik/ui/screens/strain_screen.dart';
import 'package:bileklik/ui/screens/workout_detail_screen.dart';
import 'package:bileklik/device/protocol/exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 11, 26);

DateTime _day(int ago) => DateTime(_today.year, _today.month, _today.day - ago);

/// [day] sabahına biten gece: 23:00'te yatış, 20 dk uyanık, sonra
/// 300 hafif + 60 derin + 90 REM, sonunda 10 dk uyanık.
SleepSession _night(DateTime day) =>
    SleepSession(DateTime(day.year, day.month, day.day - 1, 23), [
      ...List.filled(20, SleepStage.awake),
      ...List.filled(300, SleepStage.light),
      ...List.filled(60, SleepStage.deep),
      ...List.filled(90, SleepStage.rem),
      ...List.filled(10, SleepStage.awake),
    ]);

MemoryHealthStore _store({int days = 14, double lastHrv = 50}) {
  final store = MemoryHealthStore();
  for (var i = 0; i < days; i++) {
    final d = _day(i);
    store
      ..addSleep([_night(d)])
      ..addMeasurements([
        for (var q = 0; q < 12; q++)
          Measurement(
            MetricType.heartRate,
            DateTime(d.year, d.month, d.day, 1, q * 20),
            56.0 + q % 5,
          ),
        for (var h = 1; h <= 5; h++) ...[
          Measurement(
            MetricType.hrv,
            DateTime(d.year, d.month, d.day, h),
            i == 0 ? lastHrv : 50,
          ),
          Measurement(
            MetricType.spo2,
            DateTime(d.year, d.month, d.day, h),
            96.0 + h % 2,
          ),
        ],
        Measurement(
          MetricType.stress,
          DateTime(d.year, d.month, d.day, 14),
          40,
        ),
      ]);
  }
  return store;
}

final _workout = Workout(
  type: SportType.run,
  start: DateTime(2026, 11, 26, 18, 5),
  duration: const Duration(minutes: 40),
  steps: 5200,
  distanceKm: 6.1,
  calories: 410,
  averageHeartRate: 142,
  pace: const Duration(seconds: 393),
);

void main() {
  group('uyku çözümlemesi', () {
    test('örüntü, evre payları ve şekerleme', () {
      final store = _store(days: 1)
        ..addSleep([
          SleepSession(
            DateTime(_today.year, _today.month, _today.day, 14),
            List.filled(30, SleepStage.light),
          ),
        ]);
      final g = NightSleep.group(
        store.sleepBetween(_day(2), _today.add(const Duration(days: 1))),
      ).single;
      final a = SleepAnalysis.of(store, g)!;
      expect(a.naps, hasLength(1));
      expect(a.asleepMinutes, 450);
      expect(a.inBedMinutes, 480);
      expect(a.efficiency, 93);
      expect(a.latencyMinutes, 20);
      expect(a.debtMinutes, 30);
      expect(a.stagePercent(SleepStage.light), 63);
      expect(a.stageInRange(SleepStage.rem), isFalse); // %19
      expect(a.heartRate!.stats.min, 56);
      expect(a.spo2!.stats.min, 96);
      expect(a.hrv!.stats.average, 50);
    });
  });

  group('günlük toparlanma', () {
    test('olağan HRV ve iyi uyku normal ya da üstü', () {
      final r = DayRecovery.of(_store(), _today)!;
      expect(r.hrv, 50);
      expect(r.hrvBaseline, 50);
      expect(r.sleepScore, isNotNull);
      expect(r.stress, 40);
      expect(r.score, greaterThanOrEqualTo(60));
      expect(r.hrvLow, isFalse);
    });

    test('düşük HRV puanı düşürür ve uyarır', () {
      final low = DayRecovery.of(_store(lastHrv: 30), _today)!;
      final normal = DayRecovery.of(_store(), _today)!;
      expect(low.score, lessThan(normal.score));
      expect(low.hrvLow, isTrue);
    });

    test('düzey sınırları', () {
      expect(RecoveryLevel.of(90), RecoveryLevel.excellent);
      expect(RecoveryLevel.of(75), RecoveryLevel.good);
      expect(RecoveryLevel.of(74), RecoveryLevel.normal);
      expect(RecoveryLevel.of(40), RecoveryLevel.poor);
      expect(RecoveryLevel.of(39), RecoveryLevel.inadequate);
    });

    test('veri yoksa hesap yok; eğilimde gelecek günler boş', () {
      expect(DayRecovery.of(MemoryHealthStore(), _today), isNull);
      final s = DayRecovery.series(
        _store(),
        PeriodRange.of(Period.week, _today),
        now: _today,
      );
      expect(s, hasLength(7));
      expect(s.last.$2, isNull); // pazar, gelecek
      expect(s[3].$2, isNotNull); // perşembe, bugün
    });
  });

  Future<void> pump(
    WidgetTester tester,
    MemoryHealthStore store,
    Widget screen, {
    String lang = 'tr',
    Size size = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final controller = DeviceController(
      FakeDevice(random: Random(5)),
      store: store,
    );
    await tester.pumpWidget(
      BileklikApp(
        controller: controller,
        settings: AppSettings.memory(language: lang),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(
        find.text(text),
        300,
        scrollable: find.byType(Scrollable).last,
      );

  testWidgets('Uyku ayrıntısı bölümleri', (tester) async {
    await pump(tester, _store(), SleepScreen(day: _today));
    expect(find.text('Uyku skoru'), findsOneWidget);
    expect(find.text('Uykuya dalma'), findsOneWidget);
    expect(find.text('Uyanma'), findsOneWidget);
    for (final t in [
      'Uyku dağılımı',
      'Uyku örüntüsü',
      'Uyku verimliliği',
      'Uyku borcu',
      'Uyku sırasında nabız',
      'Uyku sırasında kan oksijeni',
      'Uyku sırasında HRV',
      'Kısa şekerleme yok',
      'Son 7 gece',
    ]) {
      await scrollTo(tester, t);
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Uyku: ölçülmeyen değerin bölümü gizlenir', (tester) async {
    final store = MemoryHealthStore()..addSleep([_night(_today)]);
    await pump(tester, store, SleepScreen(day: _today));
    await scrollTo(tester, 'Son 7 gece');
    expect(find.text('Uyku sırasında nabız'), findsNothing);
    expect(find.text('Uyku sırasında HRV'), findsNothing);
  });

  testWidgets('Toparlanma ekranı ve eğilim', (tester) async {
    await pump(tester, _store(), RecoveryScreen(day: _today, now: _today));
    expect(find.text('Günlük toparlanma'), findsOneWidget);
    expect(find.text('Değerlendirme'), findsOneWidget);
    await scrollTo(tester, 'Uyku skoru');
    expect(find.text('Dinlenik nabız'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
    expect(find.text('Stres'), findsOneWidget);
    await scrollTo(tester, 'Eğilim');
    await tester.tap(find.text('Ay'));
    await tester.pumpAndSettle();
    expect(find.textContaining('30 Kas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('günlük yük', () {
    test('düzey sınırları ve ideal aralık', () {
      expect(StrainLevel.of(0), StrainLevel.veryLow);
      expect(StrainLevel.of(5), StrainLevel.normal);
      expect(StrainLevel.of(12.9), StrainLevel.moderate);
      expect(StrainLevel.of(13), StrainLevel.high);
      expect(StrainLevel.of(21), StrainLevel.overloaded);
      expect(DayStrain.optimalFor(80), (10.0, 14.0));
      expect(DayStrain.optimalFor(30), (0.0, 6.0));
    });

    test('yüksek nabız ve adım yükü artırır, uyku sayılmaz', () {
      final rest = _store();
      final calm = DayStrain.of(rest, _today, age: 40)!;
      // Gecedeki nabız (uyku sırasında) yük katmaz; adım da yok.
      expect(calm.score, 0);
      expect(calm.sleepMinutes, isNotNull);
      expect(calm.optimal, isNotNull);

      final active = _store()
        ..addMeasurements([
          for (var m = 0; m < 60; m += 5)
            Measurement(
              MetricType.heartRate,
              DateTime(_today.year, _today.month, _today.day, 18, m),
              150,
            ),
          Measurement(
            MetricType.steps,
            DateTime(_today.year, _today.month, _today.day, 18),
            9000,
          ),
        ]);
      final s = DayStrain.of(active, _today, age: 40)!;
      expect(s.score, greaterThan(5));
      expect(s.score, lessThan(DayStrain.max));
      expect(s.steps, 9000);
      expect(DayStrain.of(MemoryHealthStore(), _today), isNull);
    });
  });

  testWidgets('Günlük yük: halka, AI yorumu, göstergeler ve eğilim', (
    tester,
  ) async {
    final store = _store()
      ..addMeasurements([
        for (var m = 0; m < 60; m += 5)
          Measurement(
            MetricType.heartRate,
            DateTime(_today.year, _today.month, _today.day, 18, m),
            140,
          ),
        Measurement(
          MetricType.steps,
          DateTime(_today.year, _today.month, _today.day, 18),
          6400,
        ),
      ]);
    await pump(tester, store, StrainScreen(day: _today, now: _today));
    expect(find.text('Günlük yük'), findsWidgets);
    expect(find.text('AI analizi'), findsOneWidget);
    expect(find.text('Çok düşük'), findsWidgets);
    await scrollTo(tester, 'Adım');
    expect(find.text('Yük göstergeleri'), findsOneWidget);
    expect(find.text('Uyku'), findsOneWidget);
    await scrollTo(tester, 'Eğilim');
    await tester.tap(find.text('Ay'));
    await tester.pumpAndSettle();
    expect(find.textContaining('30 Kas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Günlük yük: veri yoksa yönlendirir', (tester) async {
    await pump(tester, MemoryHealthStore(), StrainScreen(day: _today));
    expect(find.textContaining('gün boyu takın'), findsOneWidget);
  });

  testWidgets('Toparlanma: veri yoksa yönlendirir', (tester) async {
    await pump(tester, MemoryHealthStore(), RecoveryScreen(day: _today));
    expect(find.textContaining('Bilekliği bu gece takın'), findsOneWidget);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: uyku ve toparlanma 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final screen in [
        SleepScreen(day: _today),
        RecoveryScreen(day: _today, now: _today),
        StrainScreen(day: _today, now: _today),
        WorkoutDetailScreen(workout: _workout),
      ]) {
        await pump(
          tester,
          _store()
            ..addWorkouts([_workout])
            ..addMeasurements([
              for (var m = 0; m < 40; m += 2)
                Measurement(
                  MetricType.heartRate,
                  _workout.start.add(Duration(minutes: m)),
                  110.0 + m,
                ),
            ]),
          screen,
          lang: lang,
          size: const Size(960, 1920),
        );
        for (var i = 0; i < 8; i++) {
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$lang $i');
        }
      }
    });
  }
}
