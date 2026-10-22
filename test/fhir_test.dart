import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bileklik/data/fhir.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/exercise.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/fhir_export_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _patient = '11111111-2222-4333-8444-555555555555';
final _t = DateTime.utc(2026, 10, 20, 8, 30);

MemoryHealthStore _store() => MemoryHealthStore()
  ..addMeasurements([
    Measurement(MetricType.heartRate, _t, 72),
    Measurement(MetricType.spo2, _t, 97),
    Measurement(MetricType.steps, _t, 840),
    Measurement(MetricType.distance, _t, 0.62),
    Measurement(MetricType.temperature, _t, 36.4),
    Measurement(MetricType.systolic, _t, 121),
    Measurement(MetricType.diastolic, _t, 79),
    // Eşi olmayan sistolik değer panele girmez.
    Measurement(MetricType.systolic, _t.add(const Duration(hours: 1)), 130),
  ])
  ..addSleep([
    SleepSession(_t.subtract(const Duration(hours: 8)), const [
      SleepStage.light,
      SleepStage.light,
      SleepStage.deep,
      SleepStage.rem,
      SleepStage.awake,
    ]),
  ])
  ..addWorkouts([
    Workout(
      type: SportType.run,
      start: _t,
      duration: const Duration(minutes: 30),
      steps: 4200,
      distanceKm: 5.1,
      calories: 310,
      averageHeartRate: 148,
    ),
  ])
  ..addEcg(
    EcgRecording(
      start: _t,
      sampleRate: 250,
      samples: List.generate(500, (i) => i % 7 - 3),
      averageHeartRate: 70,
      minHeartRate: 66,
      maxHeartRate: 75,
      sdnn: 42.5,
      beats: 2,
    ),
  );

Map<String, Object?> _bundle({bool includeEcg = true}) =>
    FhirExporter(
      patientId: _patient,
      random: Random(1),
      clock: () => _t,
    ).bundle(
      _store(),
      from: _t.subtract(const Duration(days: 1)),
      to: _t.add(const Duration(days: 1)),
      includeEcg: includeEcg,
    );

List<Map<String, Object?>> _resources(Map<String, Object?> b) => [
  for (final e in b['entry']! as List)
    (e as Map<String, Object?>)['resource']! as Map<String, Object?>,
];

Map<String, Object?> _byCode(Map<String, Object?> b, String code) =>
    _resources(b).firstWhere((r) {
      final coding = ((r['code'] as Map?)?['coding'] as List?) ?? const [];
      return coding.any((c) => (c as Map)['code'] == code);
    });

void main() {
  test('FHIR dateTime saat dilimiyle', () {
    expect(fhirDateTime(DateTime.utc(2026, 1, 2, 3, 4, 5)), '2026-01-02T03:04:05Z');
    final local = DateTime(2026, 10, 22, 9, 30);
    expect(
      fhirDateTime(local),
      matches(RegExp(r'^2026-10-22T09:30:00[+-]\d\d:\d\d$')),
    );
  });

  test('Bundle hasta ve tüm kayıtları içerir, JSON olarak okunur', () {
    final b = _bundle();
    expect(b['resourceType'], 'Bundle');
    expect(b['type'], 'collection');
    final rs = _resources(b);
    expect(rs.first['resourceType'], 'Patient');
    expect(rs.first['id'], _patient);
    // 5 ölçüm + 1 tansiyon paneli + uyku + egzersiz + EKG.
    expect(rs.where((r) => r['resourceType'] == 'Observation'), hasLength(9));
    for (final r in rs.skip(1)) {
      expect((r['subject']! as Map)['reference'], 'urn:uuid:$_patient');
      expect(r['status'], 'final');
    }
    final ids = rs.map((r) => r['id']).toSet();
    expect(ids, hasLength(rs.length), reason: 'kimlikler benzersiz');
    final decoded = jsonDecode(FhirExporter.encode(b)) as Map;
    expect(decoded['entry'] as List, hasLength(rs.length));
  });

  test('LOINC kodları, UCUM birimleri ve dönüşümler', () {
    final b = _bundle();
    final hr = _byCode(b, '8867-4');
    expect(hr['valueQuantity'], {
      'value': 72,
      'unit': 'beats/minute',
      'system': FhirExporter.ucum,
      'code': '/min',
    });
    expect(hr['effectiveDateTime'], '2026-10-20T08:30:00Z');
    expect((_byCode(b, '59408-5')['valueQuantity']! as Map)['value'], 97);
    // Mesafe metreye çevrilir; adım 10 dakikalık dönemdir.
    final distance = _byCode(b, '55430-3');
    expect((distance['valueQuantity']! as Map)['value'], 620);
    expect((distance['valueQuantity']! as Map)['code'], 'm');
    expect(_byCode(b, '55423-8')['effectivePeriod'], {
      'start': '2026-10-20T08:30:00Z',
      'end': '2026-10-20T08:40:00Z',
    });
    expect((_byCode(b, '8310-5')['valueQuantity']! as Map)['value'], 36.4);
    // Aynı kayıt tekrar aktarılırsa portal tanısın diye kalıcı kimlik.
    expect(hr['identifier'], [
      {
        'system': FhirExporter.identifierSystem,
        'value': 'heartRate-${_t.millisecondsSinceEpoch}',
      },
    ]);
  });

  test('tansiyon tek panelde, tahmini olduğu not edilir', () {
    final b = _bundle();
    final panels = _resources(b).where((r) {
      final coding = ((r['code'] as Map?)?['coding'] as List?) ?? const [];
      return coding.any((c) => (c as Map)['code'] == '85354-9');
    }).toList();
    expect(panels, hasLength(1));
    final components = panels.single['component']! as List;
    expect(
      components.map((c) => ((c as Map)['valueQuantity'] as Map)['value']),
      [121, 79],
    );
    expect(panels.single['note']! as List, isNotEmpty);
  });

  test('uyku, egzersiz ve EKG', () {
    final b = _bundle();
    final sleep = _byCode(b, '93832-4');
    // Uyanık dakika toplam uykuya sayılmaz.
    expect((sleep['valueQuantity']! as Map)['value'], 4);
    expect(sleep['component'], hasLength(SleepStage.values.length));

    final workout = _byCode(b, 'workout');
    final parts = (workout['component']! as List).cast<Map>();
    expect(parts.map((p) => (p['valueQuantity'] as Map)['value']), [
      30,
      4200,
      5100,
      310,
      148,
    ]);

    final ecg = _byCode(b, '11524-6');
    final sampled =
        ((ecg['component']! as List).first as Map)['valueSampledData'] as Map;
    expect(sampled['period'], 4.0);
    expect(sampled['dimensions'], 1);
    expect((sampled['data'] as String).split(' '), hasLength(500));
    expect(ecg['effectivePeriod'], {
      'start': '2026-10-20T08:30:00Z',
      'end': '2026-10-20T08:30:02Z',
    });

    expect(
      _resources(_bundle(includeEcg: false)).where((r) {
        final coding = ((r['code'] as Map?)?['coding'] as List?) ?? const [];
        return coding.any((c) => (c as Map)['code'] == '11524-6');
      }),
      isEmpty,
    );
  });

  testWidgets('dışa aktarma ekranı dosyayı paylaşır', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final store = _store();
    final controller = DeviceController(
      FakeDevice(random: Random(5)),
      store: store,
    );
    Uint8List? shared;
    String? name;
    await tester.pumpWidget(
      BileklikApp(
        controller: controller,
        settings: AppSettings.memory(),
      ),
    );
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => FhirExportScreen(
          clock: () => _t.add(const Duration(hours: 1)),
          share: (bytes, fileName) async {
            shared = bytes;
            name = fileName;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Verilerimi dışa aktar'), findsOneWidget);
    // 5 ölçüm + tansiyon paneli + uyku + egzersiz + EKG.
    expect(find.text('9 kayıt'), findsOneWidget);

    await tester.tap(find.text('EKG kayıtlarını ekle'));
    await tester.pumpAndSettle();
    expect(find.text('8 kayıt'), findsOneWidget);

    await tester.tap(find.text('Dosyayı paylaş'));
    await tester.pumpAndSettle();
    expect(name, 'bileklik-fhir-20261020.json');
    final bundle = jsonDecode(utf8.decode(shared!)) as Map;
    expect(bundle['resourceType'], 'Bundle');
    expect(tester.takeException(), isNull);
  });
}
