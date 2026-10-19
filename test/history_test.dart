import 'package:bileklik/data/aggregate.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_history.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

void main() {
  group('geçmiş çözücüleri', () {
    test('PDF örneği: 0x52 adım kaydı', () {
      final r = hex('52 09 00 24 08 27 09 10 19 12 00 28 00 00 00 0E 04 '
          '00 00 00 00 00 00 00 00');
      final rec = StepDetailRecord.parse(r);
      expect(rec.time, DateTime(2024, 8, 27, 9, 10, 19));
      expect(rec.steps, 18);
      expect(rec.calories, closeTo(0.40, 1e-9));
      expect(rec.distanceKm, 0);
      expect(rec.perMinute.take(2), [14, 4]);
    });

    test('istek: zaman BCD olarak gönderilir', () {
      final p = historyRequest(HistoryKind.heartRateDetail, HistoryMode.read,
          since: DateTime(2024, 8, 27, 9, 10, 19));
      expect(p.bytes.sublist(0, 10),
          hex('54 00 00 00 24 08 27 09 10 19'));
      expect(p.bytes.last, Packet.crc(p.bytes.sublist(0, 15)));
    });

    test('kayıtlar ayrılır ve bitiş işareti tanınır', () {
      final a = List<int>.filled(10, 0)..[0] = 0x66;
      final b = List<int>.filled(10, 0)..[0] = 0x66;
      final chunk = splitHistory(HistoryKind.spo2, [...a, ...b, 0x66, 0xFF]);
      expect(chunk.records, hasLength(2));
      expect(chunk.ended, isTrue);
      expect(splitHistory(HistoryKind.spo2, a).ended, isFalse);
    });

    test('ısı küçük sonlu, 0,1 derece', () {
      final r = List<int>.filled(11, 0)
        ..setAll(0, hex('62 01 00 24 08 27 09 10 19 5A 01'));
      expect(TemperatureRecord.parse(r).celsius, closeTo(34.6, 1e-9));
    });

    test('uyku evreleri dakika dakika okunur', () {
      final r = List<int>.filled(130, 0)
        ..setAll(0, hex('53 00 00 24 08 27 23 00 00 04 01 02 03 00'));
      final rec = SleepRecord.parse(r);
      expect(rec.start, DateTime(2024, 8, 27, 23));
      expect(rec.minutes, [
        SleepStage.deep,
        SleepStage.light,
        SleepStage.rem,
        SleepStage.awake,
      ]);
    });
  });

  group('sahte geçmiş', () {
    final now = DateTime(2026, 10, 19, 15, 0);
    final h = FakeHistory();

    test('yanıtlar 50 kayıtlık sayfalara bölünür', () {
      final all = h.records(HistoryKind.heartRateDetail, now);
      expect(all.length, greaterThan(100));
      final first = h.respond(
          historyRequest(HistoryKind.heartRateDetail, HistoryMode.read), now);
      expect(first, hasLength(51));
      expect(first.last, [0x54, 0xFF]);
      final next = h.respond(
          historyRequest(HistoryKind.heartRateDetail, HistoryMode.next), now);
      expect(next.first, all[50].bytes);
    });

    test('verilen zamandan sonraki kayıtlar döner', () {
      final since = DateTime(2026, 10, 19, 12);
      final page = h.respond(
          historyRequest(HistoryKind.spo2, HistoryMode.read, since: since),
          now);
      final times = page
          .where((r) => r.length == 10)
          .map((r) => SingleValueRecord.parse(r).time);
      expect(times, [DateTime(2026, 10, 19, 13), DateTime(2026, 10, 19, 14)]);
    });

    test('her gece bir uyku oturumu üretilir', () {
      final sessions = [
        for (final r in h.records(HistoryKind.sleep, now))
          () {
            final s = SleepRecord.parse(r.bytes);
            return SleepSession(s.start, s.minutes);
          }(),
      ];
      final nights = NightSleep.group(sessions);
      expect(nights, hasLength(7));
      for (final n in nights) {
        expect(n.asleepMinutes, inInclusiveRange(300, 500));
        expect(n.minutesIn(SleepStage.deep), greaterThan(0));
        expect(n.minutesIn(SleepStage.rem), greaterThan(0));
      }
      expect(nights.last.day, DateTime(2026, 10, 19));
    });
  });

  group('özetleme', () {
    test('hafta pazartesi başlar', () {
      final r = PeriodRange.of(Period.week, DateTime(2026, 10, 22));
      expect(r.start, DateTime(2026, 10, 19));
      expect(r.end, DateTime(2026, 10, 26));
      expect(r.buckets, hasLength(7));
      expect(r.shift(-1).start, DateTime(2026, 10, 12));
    });

    test('adım toplanır, nabız ortalaması alınır', () {
      final day = PeriodRange.of(Period.day, DateTime(2026, 10, 19));
      final steps = [
        Measurement(MetricType.steps, DateTime(2026, 10, 19, 8, 0), 100),
        Measurement(MetricType.steps, DateTime(2026, 10, 19, 8, 10), 50),
      ];
      expect(aggregate(steps, day, MetricType.steps)[8], 150);
      final hr = [
        Measurement(MetricType.heartRate, DateTime(2026, 10, 19, 8, 0), 60),
        Measurement(MetricType.heartRate, DateTime(2026, 10, 19, 8, 10), 80),
      ];
      final v = aggregate(hr, day, MetricType.heartRate);
      expect(v[8], 70);
      expect(v[9], isNull);
    });

    test('stres ve HRV aralıkları', () {
      expect(bandOf(MetricType.stress, 20)?.label, 'Sakin');
      expect(bandOf(MetricType.stress, 60)?.label, 'Gergin');
      expect(bandOf(MetricType.hrv, 80)?.label, 'Harika');
      expect(bandOf(MetricType.heartRate, 80), isNull);
    });

    test('gece yarısından sonra başlayan uyku aynı güne yazılır', () {
      expect(NightSleep.dayOf(DateTime(2026, 10, 18, 23, 30)),
          DateTime(2026, 10, 19));
      expect(NightSleep.dayOf(DateTime(2026, 10, 19, 1)),
          DateTime(2026, 10, 19));
    });
  });
}
