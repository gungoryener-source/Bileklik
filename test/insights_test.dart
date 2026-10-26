import 'dart:math';

import 'package:bileklik/data/aggregate.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/insights.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/commands.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/metric_detail_screen.dart';
import 'package:bileklik/ui/screens/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 10, 26);

DateTime _day(int ago) => DateTime(_today.year, _today.month, _today.day - ago);

/// [day] sabahına biten 7,5 saatlik gece (23:00 – 06:30).
SleepSession _night(DateTime day) =>
    SleepSession(DateTime(day.year, day.month, day.day - 1, 23), [
      ...List.filled(300, SleepStage.light),
      ...List.filled(90, SleepStage.deep),
      ...List.filled(60, SleepStage.rem),
    ]);

/// [day] gecesinde (01:00–05:00) saatlik ölçümler.
List<Measurement> _nightReadings(
  DateTime day, {
  double hr = 58,
  double hrv = 50,
  double temp = 36.0,
  double spo2 = 97,
}) => [
  for (var h = 1; h <= 5; h++) ...[
    Measurement(
      MetricType.heartRate,
      DateTime(day.year, day.month, day.day, h),
      hr,
    ),
    Measurement(MetricType.hrv, DateTime(day.year, day.month, day.day, h), hrv),
    Measurement(
      MetricType.temperature,
      DateTime(day.year, day.month, day.day, h),
      temp,
    ),
    Measurement(
      MetricType.spo2,
      DateTime(day.year, day.month, day.day, h),
      spo2,
    ),
  ],
];

/// Son [days] günün her biri için gece verisi ve gündüz adımları.
MemoryHealthStore _history({int days = 21, int steps = 11000}) {
  final store = MemoryHealthStore();
  for (var i = 0; i < days; i++) {
    final d = _day(i);
    store
      ..addSleep([_night(d)])
      ..addMeasurements([
        ..._nightReadings(d),
        Measurement(
          MetricType.steps,
          DateTime(d.year, d.month, d.day, 12),
          steps.toDouble(),
        ),
      ]);
  }
  return store;
}

void main() {
  group('nabız bölgeleri', () {
    test('azami nabız ve sınırlar', () {
      // 208 − 0,7 × 40 = 180.
      expect(maxHeartRate(40), 180);
      expect(HeartRateZone.of(80, 180), isNull); // %44, dinlenme
      expect(HeartRateZone.of(90, 180), HeartRateZone.warmUp);
      expect(HeartRateZone.of(126, 180), HeartRateZone.aerobic);
      expect(HeartRateZone.of(170, 180), HeartRateZone.maximum);
      expect(HeartRateZone.aerobic.bpmRange(180), (126, 143));
      expect(HeartRateZone.maximum.bpmRange(180), (162, null));
    });

    test('süreler: sonraki ölçüme kadar, boşluk en çok 10 dk', () {
      final t = DateTime(2026, 10, 26, 18);
      final hr = [
        Measurement(MetricType.heartRate, t, 100), // ısınma, 1 dk
        Measurement(
          MetricType.heartRate,
          t.add(const Duration(minutes: 1)),
          130,
        ), // aerobik, 1 dk
        Measurement(
          MetricType.heartRate,
          t.add(const Duration(minutes: 2)),
          150,
        ), // anaerobik, 10 dk (boşluk)
        Measurement(
          MetricType.heartRate,
          t.add(const Duration(minutes: 60)),
          60,
        ), // dinlenme
      ];
      final z = zoneDurations(hr, 180);
      expect(z[HeartRateZone.warmUp], const Duration(minutes: 1));
      expect(z[HeartRateZone.aerobic], const Duration(minutes: 1));
      expect(z[HeartRateZone.anaerobic], const Duration(minutes: 10));
      expect(z[HeartRateZone.fatBurn], Duration.zero);
      expect(
        zoneDurations(const [], 180).values.every((d) => d == Duration.zero),
        isTrue,
      );
    });
  });

  group('ısı sapması', () {
    test('ilk 7 günün ortalaması temel olur', () {
      final store = MemoryHealthStore()
        ..addMeasurements([
          for (var i = 0; i < 10; i++)
            Measurement(
              MetricType.temperature,
              DateTime(2026, 10, 1 + i, 3),
              // İlk 7 gün 36,0; sonra 36,8.
              i < 7 ? 36.0 : 36.8,
            ),
          // Takılı değilken gelen değer atılır.
          Measurement(MetricType.temperature, DateTime(2026, 10, 2, 4), 0),
        ]);
      final base = TemperatureBaseline.of(store, DateTime(2026, 10, 20))!;
      expect(base.value, closeTo(36.0, 1e-9));
      expect(base.days, 7);
      expect(base.from, DateTime(2026, 10, 1));
      expect(base.to, DateTime(2026, 10, 7));

      final week = PeriodRange.of(Period.week, DateTime(2026, 10, 8));
      final dev = temperatureDeviation(store, week, base);
      // 5 Ekim pazartesi: 5, 6, 7 → 0; 8, 9, 10 → +0,8; 11 → veri yok.
      expect(dev[0], closeTo(0, 1e-9));
      expect(dev[3], closeTo(0.8, 1e-9));
      expect(dev[6], isNull);
    });

    test('3 günden az veri: temel yok', () {
      final store = MemoryHealthStore()
        ..addMeasurements([
          Measurement(MetricType.temperature, DateTime(2026, 10, 1, 3), 36),
          Measurement(MetricType.temperature, DateTime(2026, 10, 2, 3), 36),
        ]);
      expect(TemperatureBaseline.of(store, DateTime(2026, 10, 20)), isNull);
    });
  });

  group('biyolojik yaş', () {
    test('iyi değerler gençleştirir', () {
      final store = _history();
      final b = BiologicalAge.of(store, _today, 40)!;
      final byFactor = {for (final c in b.contributions) c.factor: c};
      // Dinlenik nabız: PPI yok, nabızların alt %10'u = 58 → (58 − 62)/4 = −1.
      expect(byFactor[AgeFactor.restingHeartRate]!.years, -1);
      // 11.000 adım → (7000 − 11000)/2000 = −2.
      expect(byFactor[AgeFactor.steps]!.years, -2);
      // 7,5 saat uyku → −1.
      expect(byFactor[AgeFactor.sleep]!.years, -1);
      expect(byFactor.containsKey(AgeFactor.bmi), isFalse);
      expect(b.age, 36);
      expect(b.difference, -4);
    });

    test('VKİ ve az adım yaşlandırır; sınır ±10', () {
      final store = _history(steps: 1000)
        ..addMeasurements([Measurement(MetricType.bmi, _day(3), 32.5)]);
      final b = BiologicalAge.of(store, _today, 50)!;
      final byFactor = {for (final c in b.contributions) c.factor: c};
      expect(byFactor[AgeFactor.steps]!.years, 3);
      expect(byFactor[AgeFactor.bmi]!.years, 3);
      // −1 + 3 − 1 + 3.
      expect(b.age, 54);
    });

    test('yetersiz veri ya da yaş: hesap yok', () {
      expect(BiologicalAge.of(_history(days: 5), _today, 40), isNull);
      expect(BiologicalAge.of(_history(), _today, 15), isNull);
      final trend = BiologicalAge.trend(_history(), _today, 40);
      expect(trend, hasLength(8));
      // 21 günlük geçmiş: son üç hafta hesaplanır, öncesi boş.
      expect(trend.last, isNotNull);
      expect(trend.first, isNull);
    });
  });

  group('Sağlık Radarı', () {
    test('olağan gece: bulgu yok', () {
      final r = HealthRadar.of(_history(), _today);
      expect(r.ready, isTrue);
      expect(r.findings, isEmpty);
      expect(r.baselineNights, 14);
    });

    test('nabız, HRV, ısı ve oksijen sapmaları', () {
      final store = MemoryHealthStore();
      for (var i = 1; i <= 14; i++) {
        final d = _day(i);
        store
          ..addSleep([_night(d)])
          ..addMeasurements(_nightReadings(d));
      }
      store
        ..addSleep([_night(_today)])
        ..addMeasurements(
          _nightReadings(_today, hr: 67, hrv: 35, temp: 36.6, spo2: 93),
        );
      final r = HealthRadar.of(store, _today);
      expect(r.findings.map((f) => f.signal), [
        RadarSignal.heartRateUp,
        RadarSignal.hrvDown,
        RadarSignal.temperatureUp,
        RadarSignal.spo2Down,
      ]);
      expect(r.findings.first.baseline, 58);
      expect(r.strong, isTrue);
    });

    test('küçük değişim bulgu sayılmaz', () {
      final store = MemoryHealthStore();
      for (var i = 1; i <= 14; i++) {
        store.addMeasurements(_nightReadings(_day(i)));
      }
      store.addMeasurements(
        _nightReadings(_today, hr: 63, hrv: 40, temp: 36.4, spo2: 95),
      );
      expect(HealthRadar.of(store, _today).findings, isEmpty);
    });

    test('temel oluşmadan hazır değil', () {
      final store = MemoryHealthStore();
      for (var i = 0; i <= 3; i++) {
        store.addMeasurements(_nightReadings(_day(i)));
      }
      final r = HealthRadar.of(store, _today);
      expect(r.baselineNights, 3);
      expect(r.ready, isFalse);
      expect(HealthRadar.of(MemoryHealthStore(), _today).hasTonight, isFalse);
    });
  });

  Future<DeviceController> pumpApp(
    WidgetTester tester,
    MemoryHealthStore store, {
    String lang = 'tr',
  }) async {
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
    controller.profile = const PersonalInfo(
      isMale: true,
      age: 40,
      heightCm: 178,
      weightKg: 75,
    );
    return controller;
  }

  Future<void> push(WidgetTester tester, Widget screen) async {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    await tester.pumpAndSettle();
  }

  testWidgets('İlerleme: Sağlık Radarı ve biyolojik yaş', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, _history());
    await push(tester, ProgressScreen(day: _today, now: _today));
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Sağlık Radarı'),
      200,
      scrollable: list,
    );
    expect(find.text('Son gece olağan aralığınızdaydı.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Biyolojik yaş'),
      200,
      scrollable: list,
    );
    await tester.scrollUntilVisible(
      find.text('4 yaş daha genç'),
      200,
      scrollable: list,
    );
    expect(find.text('36'), findsWidgets);
    expect(find.text('Takvim yaşınız 40'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nabız ayrıntısında bölgeler, ısı ayrıntısında sapma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final store = MemoryHealthStore()
      ..addMeasurements([
        for (var m = 0; m < 30; m++)
          Measurement(MetricType.heartRate, day.add(Duration(minutes: m)), 140),
        for (var i = 0; i < 8; i++)
          Measurement(
            MetricType.temperature,
            DateTime(day.year, day.month, day.day - i, 3),
            i == 0 ? 36.5 : 36.0,
          ),
      ]);
    await pumpApp(tester, store);
    await push(tester, const MetricDetailScreen(type: MetricType.heartRate));
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Nabız bölgeleri'),
      200,
      scrollable: list,
    );
    // 140 / 180 = %78: aerobik, 30 dk.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            RegExp('^Aerobik.*: 30 dk\$').hasMatch(w.properties.label ?? ''),
      ),
      findsOneWidget,
    );
    Navigator.of(tester.element(list)).pop();
    await tester.pumpAndSettle();

    await push(tester, const MetricDetailScreen(type: MetricType.temperature));
    final list2 = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Olağan ısınıza göre'),
      200,
      scrollable: list2,
    );
    expect(find.textContaining('+0.5'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['ar', 'de']) {
    testWidgets('$lang: yeni kartlar 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = _history()
        ..addMeasurements(
          _nightReadings(_today, hr: 70, hrv: 30, temp: 36.7, spo2: 92),
        );
      await pumpApp(tester, store, lang: lang);
      await push(tester, ProgressScreen(day: _today, now: _today));
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(list)).pop();
      await tester.pumpAndSettle();
      await push(tester, const MetricDetailScreen(type: MetricType.heartRate));
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
