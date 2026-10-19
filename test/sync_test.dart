import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/sync_service.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/device/wristband_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 19, 15, 0);
  late FakeDevice device;
  late WristbandClient client;

  setUp(() async {
    device = FakeDevice(random: Random(1), clock: () => now);
    client = WristbandClient(device);
    await device.connect();
  });

  tearDown(() async {
    await device.disconnect();
    await client.dispose();
    device.dispose();
  });

  test('tüm sayfalar çekilir', () async {
    final rows = await client.fetchHistory(HistoryKind.heartRateDetail);
    expect(rows.length,
        device.history.records(HistoryKind.heartRateDetail, now).length);
  });

  test('senkron depoyu doldurur, ikinci senkron tekrar eklemez', () async {
    final store = MemoryHealthStore();
    final sync = SyncService(client, store);
    await sync.syncAll();

    final week = now.subtract(const Duration(days: 7));
    int count(MetricType t) => store.measurements(t, week, now).length;
    for (final t in MetricType.values) {
      expect(count(t), greaterThan(0), reason: t.name);
    }
    expect(store.sleepBetween(week, now), isNotEmpty);
    expect(store.latest(MetricType.spo2)!.time, DateTime(2026, 10, 19, 14));

    final before = {for (final t in MetricType.values) t: count(t)};
    final sleepBefore = store.sleepBetween(week, now).length;
    await sync.syncAll();
    for (final t in MetricType.values) {
      expect(count(t), before[t], reason: t.name);
    }
    expect(store.sleepBetween(week, now).length, sleepBefore);
  });
}
