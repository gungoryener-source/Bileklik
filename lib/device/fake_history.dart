import 'dart:math';

import 'protocol/history.dart';
import 'protocol/packet.dart';

/// Sahte cihazın son günlere ait geçmiş kayıtları.
///
/// Değerler zaman dilimine göre tohumlanmış rastgele sayılarla üretilir; aynı
/// dilim her istekte aynı değeri verir, böylece artan senkron tutarlı kalır.
class FakeHistory {
  FakeHistory({this.days = 7, this.stepLengthCm = 70});

  /// Kaç günlük geçmiş tutulduğu (bugün dahil).
  final int days;
  final int stepLengthCm;

  static const pageSize = 50;
  final _cursor = <HistoryKind, ({List<List<int>> records, int offset})>{};

  /// Bir geçmiş isteğine verilecek bildirimler: kayıtlar ve bitiş işareti.
  List<List<int>> respond(Packet request, DateTime now) {
    final kind = HistoryKind.byCommand(request.command)!;
    final d = request.payload;
    final mode = d[0];
    final end = [kind.command, 0xFF];

    if (mode == HistoryMode.delete) {
      _cursor.remove(kind);
      return [end];
    }
    if (mode != HistoryMode.next || !_cursor.containsKey(kind)) {
      final since = _since(d);
      final all = records(kind, now)
          .where((r) => since == null || r.time.isAfter(since))
          .map((r) => r.bytes)
          .toList();
      _cursor[kind] = (records: all, offset: 0);
    }
    final c = _cursor[kind]!;
    final page = c.records.skip(c.offset).take(pageSize).toList();
    _cursor[kind] = (records: c.records, offset: c.offset + page.length);
    return [...page, end];
  }

  static DateTime? _since(List<int> d) {
    // Ay veya gün yoksa zaman verilmemiştir.
    if (d[4] == 0 || d[5] == 0) return null;
    return DateTime(
      2000 + fromBcd(d[3]),
      fromBcd(d[4]),
      fromBcd(d[5]),
      fromBcd(d[6]),
      fromBcd(d[7]),
      fromBcd(d[8]),
    );
  }

  DateTime _firstDay(DateTime now) =>
      DateTime(now.year, now.month, now.day - (days - 1));

  /// Bir türün [now] anına kadar tamamlanmış tüm kayıtları, eskiden yeniye.
  List<({DateTime time, List<int> bytes})> records(
    HistoryKind kind,
    DateTime now,
  ) {
    final out = <({DateTime time, List<int> bytes})>[];
    void each(
      Duration step,
      List<int> Function(DateTime t, int id) build, {
      bool Function(DateTime t)? when,
    }) {
      var t = _firstDay(now);
      var id = 0;
      while (!t.add(step).isAfter(now)) {
        if (when == null || when(t)) out.add((time: t, bytes: build(t, id++)));
        t = t.add(step);
      }
    }

    switch (kind) {
      case HistoryKind.dailyTotals:
        for (var ago = 0; ago < days; ago++) {
          final day = DateTime(now.year, now.month, now.day - ago);
          out.add((time: day, bytes: _dailyTotal(day, ago, now)));
        }
        out.sort((a, b) => a.time.compareTo(b.time));
      case HistoryKind.stepDetail:
        each(
          const Duration(minutes: 10),
          _stepRecord,
          when: (t) => t.hour >= 7 && t.hour < 23,
        );
      case HistoryKind.sleep:
        _sleepRecords(now, out);
      case HistoryKind.heartRateDetail:
        each(const Duration(minutes: 10), _hrDetailRecord);
      case HistoryKind.heartRateSingle:
        each(
          const Duration(hours: 2),
          (t, id) => _single(kind, t, id, _baseHeartRate(t, _rng(t, 0x55))),
        );
      case HistoryKind.hrv:
        each(const Duration(hours: 1), _hrvRecord);
      case HistoryKind.temperature:
        each(const Duration(minutes: 30), _temperatureRecord);
      case HistoryKind.spo2:
        each(
          const Duration(hours: 1),
          (t, id) => _single(kind, t, id, 95 + _rng(t, 0x66).nextInt(5)),
        );
    }
    return out;
  }

  static Random _rng(DateTime t, int salt) =>
      Random(t.millisecondsSinceEpoch ~/ 60000 * 131 + salt);

  static List<int> _header(int cmd, int id, DateTime t, int length) {
    final r = List<int>.filled(length, 0);
    r[0] = cmd;
    r[1] = id & 0xFF;
    r[2] = (id >> 8) & 0xFF;
    r.setAll(3, [
      toBcd(t.year % 100),
      toBcd(t.month),
      toBcd(t.day),
      toBcd(t.hour),
      toBcd(t.minute),
      toBcd(t.second),
    ]);
    return r;
  }

  static void _le(List<int> r, int offset, int value, int count) {
    for (var i = 0; i < count; i++) {
      r[offset + i] = (value >> (8 * i)) & 0xFF;
    }
  }

  /// 10 dakikalık adım sayısı: sabah, öğle ve akşam yürüyüşleri daha yoğun.
  static int stepsAt(DateTime t) {
    if (t.hour < 7 || t.hour >= 23) return 0;
    final rng = _rng(t, 0x52);
    final busy = const {8, 12, 18}.contains(t.hour);
    return busy ? 400 + rng.nextInt(800) : rng.nextInt(180);
  }

  List<int> _stepRecord(DateTime t, int id) {
    final steps = stepsAt(t);
    final r = _header(HistoryKind.stepDetail.command, id, t, 25);
    _le(r, 9, steps, 2);
    _le(r, 11, steps * 4, 2); // kcal x 100
    _le(r, 13, steps * stepLengthCm ~/ 1000, 2); // km x 100
    var left = steps;
    for (var m = 0; m < 10; m++) {
      final v = m == 9 ? left : min(left, steps ~/ 10);
      r[15 + m] = v.clamp(0, 255);
      left -= v;
    }
    return r;
  }

  List<int> _dailyTotal(DateTime day, int ago, DateTime now) {
    var steps = 0;
    for (
      var t = day;
      t.day == day.day && !t.add(const Duration(minutes: 10)).isAfter(now);
      t = t.add(const Duration(minutes: 10))
    ) {
      steps += stepsAt(t);
    }
    final r = List<int>.filled(27, 0);
    r[0] = HistoryKind.dailyTotals.command;
    r[1] = ago;
    r.setAll(2, [toBcd(day.year % 100), toBcd(day.month), toBcd(day.day)]);
    _le(r, 5, steps, 4);
    _le(r, 9, steps ~/ 2, 4); // egzersiz süresi, saniye
    _le(r, 13, steps * stepLengthCm ~/ 1000, 4);
    _le(r, 17, steps * 4, 4);
    return r;
  }

  static int _baseHeartRate(DateTime t, Random rng) {
    final asleep = t.hour < 7 || t.hour >= 23;
    if (asleep) return 54 + rng.nextInt(8);
    if (stepsAt(t) > 400) return 95 + rng.nextInt(20);
    return 66 + rng.nextInt(14);
  }

  List<int> _hrDetailRecord(DateTime t, int id) {
    final rng = _rng(t, 0x54);
    final base = _baseHeartRate(t, rng);
    final r = _header(HistoryKind.heartRateDetail.command, id, t, 24);
    for (var i = 0; i < 15; i++) {
      r[9 + i] = base + rng.nextInt(5) - 2;
    }
    return r;
  }

  List<int> _single(HistoryKind kind, DateTime t, int id, int value) =>
      _header(kind.command, id, t, kind.recordLength)..[9] = value;

  List<int> _hrvRecord(DateTime t, int id) {
    final rng = _rng(t, 0x56);
    final asleep = t.hour < 7 || t.hour >= 23;
    final hrv = asleep ? 55 + rng.nextInt(30) : 25 + rng.nextInt(40);
    final stress = asleep ? 5 + rng.nextInt(15) : 15 + rng.nextInt(70);
    return _header(HistoryKind.hrv.command, id, t, 15)..setAll(9, [
      hrv,
      14 + rng.nextInt(5),
      _baseHeartRate(t, rng),
      stress,
      112 + rng.nextInt(18),
      72 + rng.nextInt(12),
    ]);
  }

  List<int> _temperatureRecord(DateTime t, int id) {
    final rng = _rng(t, 0x62);
    final asleep = t.hour < 7 || t.hour >= 23;
    final tenths = (asleep ? 352 : 340) + rng.nextInt(12);
    return _header(HistoryKind.temperature.command, id, t, 11)
      ..[9] = tenths & 0xFF
      ..[10] = tenths >> 8;
  }

  /// Her gece 23:00 civarı başlayan, 120 dakikalık parçalara bölünmüş uyku.
  void _sleepRecords(
    DateTime now,
    List<({DateTime time, List<int> bytes})> out,
  ) {
    var id = 0;
    final first = _firstDay(now);
    for (var n = 0; n < days; n++) {
      final night = DateTime(first.year, first.month, first.day + n - 1, 23);
      final rng = _rng(night, 0x53);
      final start = night.add(Duration(minutes: rng.nextInt(50)));
      final total = 400 + rng.nextInt(90);
      final stages = _stages(total, rng);
      for (var o = 0; o < total; o += 120) {
        final t = start.add(Duration(minutes: o));
        final len = min(120, total - o);
        if (t.add(Duration(minutes: len)).isAfter(now)) return;
        final r = _header(HistoryKind.sleep.command, id++, t, 130);
        r[9] = len;
        r.setAll(10, stages.sublist(o, o + len));
        out.add((time: t, bytes: r));
      }
    }
  }

  /// 90 dakikalık döngüler: başta derin uyku, sabaha doğru daha çok REM.
  static List<int> _stages(int total, Random rng) {
    final out = <int>[];
    var cycle = 0;
    while (out.length < total) {
      final deep = max(5, 35 - cycle * 8 + rng.nextInt(10));
      final rem = 10 + cycle * 6 + rng.nextInt(8);
      final light = 90 - deep - rem;
      out
        ..addAll(List.filled(light ~/ 2, 2))
        ..addAll(List.filled(deep, 1))
        ..addAll(List.filled(light - light ~/ 2, 2))
        ..addAll(List.filled(rem, 3));
      if (rng.nextInt(3) == 0) out.addAll(List.filled(2 + rng.nextInt(6), 0));
      cycle++;
    }
    return out.sublist(0, total);
  }
}
