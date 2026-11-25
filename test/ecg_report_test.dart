import 'dart:math';

import 'package:bileklik/data/ecg_analysis.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/fake_ecg.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [heartRate] bpm'lik sahte kayıt; [jitter] atım aralığını rastgele oynatır.
EcgRecording recording(
  DateTime start, {
  double heartRate = 72,
  double jitter = 0,
  int seconds = 30,
}) {
  const rate = 250;
  final random = Random(3);
  final samples = <int>[];
  var synth = EcgSynth(sampleRate: rate, heartRate: heartRate, random: random);
  if (jitter == 0) {
    samples.addAll([for (var i = 0; i < seconds * rate; i++) synth.next()]);
  } else {
    // Her atımda nabız ±jitter oranında değişir (AF benzeri düzensizlik).
    while (samples.length < seconds * rate) {
      final bpm = heartRate * (1 + (random.nextDouble() * 2 - 1) * jitter);
      synth = EcgSynth(sampleRate: rate, heartRate: bpm, random: random);
      final beat = (60 / bpm * rate).round();
      samples.addAll([for (var i = 0; i < beat; i++) synth.next()]);
    }
  }
  final s = EcgSummary.analyze(samples, rate);
  return EcgRecording(
    start: start,
    sampleRate: rate,
    samples: samples,
    averageHeartRate: s.averageHeartRate,
    minHeartRate: s.minHeartRate,
    maxHeartRate: s.maxHeartRate,
    sdnn: s.sdnn,
    beats: s.peaks.length,
  );
}

EcgFindings findingsOf(EcgRecording r) =>
    EcgFindings.of(EcgSummary.analyze(r.samples, r.sampleRate));

void main() {
  final t = DateTime(2026, 11, 25, 18, 43);

  test('düzenli 72 bpm: dört bulgu da olumlu', () {
    final f = findingsOf(recording(t));
    expect(f.normalRhythm, FindingState.ok);
    expect(f.highRate, FindingState.ok);
    expect(f.lowRate, FindingState.ok);
    expect(f.afib, FindingState.ok);
  });

  test('120 bpm yüksek, 42 bpm düşük kalp hızı', () {
    final high = findingsOf(recording(t, heartRate: 120));
    expect(high.highRate, FindingState.flagged);
    expect(high.normalRhythm, FindingState.flagged);
    final low = findingsOf(recording(t, heartRate: 42));
    expect(low.lowRate, FindingState.flagged);
    expect(low.highRate, FindingState.ok);
  });

  test('düzensiz aralıklar AF belirtisi sayılır', () {
    final f = findingsOf(recording(t, heartRate: 85, jitter: 0.3));
    expect(f.afib, FindingState.flagged);
    expect(f.normalRhythm, FindingState.flagged);
  });

  test('tek erken atım AF sayılmaz, kısa kayıt değerlendirilmez', () {
    final rr = List<double>.filled(20, 830)..[10] = 500;
    expect(EcgFindings.isIrregular(rr), isFalse);
    final short = findingsOf(recording(t, seconds: 3));
    expect(short.assessable, isFalse);
  });

  testWidgets('EKG raporu ay seçer, kayıt bulgularını gösterir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final device = FakeDevice(random: Random(6));
    final controller = DeviceController(device);
    controller.store
      ..addEcg(recording(DateTime(2026, 10, 3, 9, 15), heartRate: 120))
      ..addEcg(recording(DateTime(2026, 11, 25, 18, 41)))
      ..addEcg(recording(DateTime(2026, 11, 25, 18, 43)));
    await tester.pumpWidget(BileklikApp(controller: controller));

    await tester.tap(find.text('Sağlık'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EKG'));
    await tester.pumpAndSettle();

    expect(find.text('EKG raporu'), findsOneWidget);
    expect(find.text('Kasım 2026'), findsOneWidget);
    expect(find.text('Normal kalp ritmi görüldü'), findsWidgets);
    expect(find.text('Yüksek kalp hızı görüldü (100 bpm üstü)'), findsNothing);

    await tester.tap(find.text('Kasım 2026'));
    await tester.pumpAndSettle();
    expect(find.text('2 kayıt'), findsOneWidget);
    await tester.tap(find.text('Ekim 2026'));
    await tester.pumpAndSettle();
    expect(
      find.text('Yüksek kalp hızı görüldü (100 bpm üstü)'),
      findsOneWidget,
    );

    device.dispose();
  });
}
