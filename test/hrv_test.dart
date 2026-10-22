import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/hrv_analysis.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/fake_history.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/metric_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [start]'tan itibaren art arda atımlar; her atım bir öncekinin bittiği an.
List<Measurement> _beats(DateTime start, List<int> intervals) {
  var t = start;
  return [
    for (final ms in intervals)
      Measurement(
        MetricType.ppi,
        t = t.add(Duration(milliseconds: ms)),
        ms.toDouble(),
      ),
  ];
}

void main() {
  test('0x63 PPI kaydı çözülür (varsayılan biçim)', () {
    final r = [
      0x63, 0x01, 0x00, // komut, sıra
      0x26, 0x10, 0x20, 0x02, 0x15, 0x30, // 2026-10-20 02:15:30 (BCD)
      0x03, // 3 aralık
      0xE8, 0x03, 0xD4, 0x03, 0x00, 0x04, // 1000, 980, 1024 ms
      ...List.filled(10, 0),
    ];
    expect(r, hasLength(HistoryKind.ppi.recordLength));
    final p = PpiRecord.parse(r);
    expect(p.time, DateTime(2026, 10, 20, 2, 15, 30));
    expect(p.intervalsMs, [1000, 980, 1024]);
  });

  test('RMSSD, SDNN ve pNN50', () {
    // 1000 ve 1040 ms dönüşümlü: ardışık farklar hep 40 ms.
    final beats = _beats(DateTime(2026, 10, 20, 2), [
      for (var i = 0; i < 40; i++) i.isEven ? 1000 : 1040,
    ]);
    final s = analyzePpi(beats)!;
    expect(s.beats, 40);
    expect(s.meanRr, closeTo(1020, 0.01));
    expect(s.rmssd, closeTo(40, 0.01));
    expect(s.sdnn, closeTo(20, 0.01));
    expect(s.pnn50, 0);
    expect(s.meanHeartRate, closeTo(58.8, 0.1));
  });

  test('aykırı aralıklar ayıklanır, pencere arası ardışık sayılmaz', () {
    final night = DateTime(2026, 10, 20, 2);
    final a = _beats(night, List.filled(15, 1000));
    // 10 dakika sonraki pencere; aradaki boşluk fark olarak sayılmaz.
    final b = _beats(night.add(const Duration(minutes: 10)), [
      ...List.filled(7, 1100),
      2500, // geçersiz
      1100,
      400, // %20'den fazla sıçrama
      ...List.filled(5, 1100),
    ]);
    final s = analyzePpi([...a, ...b])!;
    expect(s.beats, 15 + 7 + 1 + 5);
    // Pencere içinde değişkenlik yok; pencereler arası 100 ms fark ise
    // ardışık sayılmadığı için RMSSD sıfır kalır.
    expect(s.rmssd, 0);
    expect(analyzePpi(a.take(10).toList()), isNull, reason: 'çok az atım');
  });

  test('gece penceresi, dinlenik nabız ve VO2 Max', () {
    final store = MemoryHealthStore()
      ..addMeasurements([
        // 19 Ekim 23:30 → 20 Ekim gecesi; ~60 atım/dk.
        ..._beats(DateTime(2026, 10, 19, 23, 30), [
          for (var i = 0; i < 30; i++) i.isEven ? 990 : 1010,
        ]),
      ]);
    final now = DateTime(2026, 10, 20, 9);
    final latest = latestNightHrv(store, now)!;
    expect(latest.day, DateTime(2026, 10, 20));
    expect(restingHeartRate(store, now), 60);
    expect(estimateVo2Max(age: 40, restingHeartRate: 60), 45.9);
    expect(estimateVo2Max(age: 8, restingHeartRate: 60), isNull);
    expect(estimateVo2Max(age: 40, restingHeartRate: 20), isNull);

    // PPI yoksa nabız ölçümlerinin alt %10'u.
    final hrOnly = MemoryHealthStore()
      ..addMeasurements([
        for (var i = 0; i < 20; i++)
          Measurement(
            MetricType.heartRate,
            now.subtract(Duration(hours: i)),
            (55 + i).toDouble(),
          ),
      ]);
    expect(restingHeartRate(hrOnly, now), 57);
    expect(restingHeartRate(MemoryHealthStore(), now), isNull);
  });

  test('sahte bileklik gece PPI kayıtları üretir', () {
    final now = DateTime(2026, 10, 20, 9);
    final records = FakeHistory().records(HistoryKind.ppi, now);
    expect(records, isNotEmpty);
    for (final r in records) {
      final hour = r.time.hour;
      expect(hour < 7 || hour >= 23, isTrue, reason: '${r.time}');
      expect(PpiRecord.parse(r.bytes).intervalsMs, hasLength(8));
    }
  });

  testWidgets('HRV ekranı gece ayrıntısını ve VO2 Max notunu gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final today = DateTime.now();
    final store = MemoryHealthStore()
      ..addMeasurements(
        _beats(DateTime(today.year, today.month, today.day, 1), [
          for (var i = 0; i < 40; i++) i.isEven ? 1000 : 1040,
        ]),
      );
    final controller = DeviceController(
      FakeDevice(random: Random(5)),
      store: store,
    );
    await tester.pumpWidget(
      BileklikApp(controller: controller, settings: AppSettings.memory()),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const MetricDetailScreen(type: MetricType.hrv),
          ),
        );
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('RMSSD'), 200, scrollable: list);
    expect(find.text('40 ms'), findsOneWidget);
    expect(find.text('20 ms'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('yaşınız gerekiyor'),
      200,
      scrollable: list,
    );
    expect(find.textContaining('laboratuvar ölçümü değildir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
