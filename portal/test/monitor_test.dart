import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 28, 10);

/// Deneme verisiyle kurulan portal ve hekimin oturumu.
class _Demo {
  final store = MemoryPortalStore();
  late final PortalApi api = PortalApi(
    store,
    random: Random(1),
    clock: () => _now,
  );
  late String cookie;
  late String doctorId;

  Future<void> open() async {
    await seedDemo(api, now: _now);
    doctorId = store.accountByToken(DemoTokens.doctor)!.id;
    final r = await api.handler(
      Request(
        'POST',
        Uri.parse('http://portal.test/panel/login'),
        headers: {'content-type': 'application/x-www-form-urlencoded'},
        body: 'token=${Uri.encodeQueryComponent(DemoTokens.doctor)}',
      ),
    );
    expect(r.statusCode, 303);
    cookie = r.headers['set-cookie']!.split(';').first;
  }

  Future<String> page(String path) async {
    final r = await api.handler(
      Request(
        'GET',
        Uri.parse('http://portal.test$path'),
        headers: {'accept-language': 'tr', 'cookie': cookie},
      ),
    );
    expect(r.statusCode, 200, reason: path);
    return r.readAsString();
  }

  MonitorBoard board() => MonitorBoard.build(store, doctorId, _now);
}

/// Sayfadaki hasta adları, görünüş sırasıyla.
List<String> _names(String html) => [
  for (final m in RegExp(
    r'<div class="names"><a href="[^"]*"[^>]*>([^<]+)</a>',
  ).allMatches(html))
    m.group(1)!,
];

void main() {
  group('izlem durumu', () {
    late _Demo d;
    setUp(() async {
      d = _Demo();
      await d.open();
    });

    test('her hastanın durumu dayanağı olan sinyalden gelir', () {
      final board = d.board();
      MonitorStatus of(String name) =>
          board.patients.firstWhere((p) => p.displayName == name).status;
      Set<SignalKind> kinds(String name) => {
        for (final s
            in board.patients.firstWhere((p) => p.displayName == name).signals)
          s.kind,
      };

      expect(of('Elif Örnek'), MonitorStatus.critical);
      expect(kinds('Elif Örnek'), contains(SignalKind.criticalAlert));
      expect(of('Leyla Örnek'), MonitorStatus.attention);
      expect(kinds('Leyla Örnek'), contains(SignalKind.noData));
      expect(of('Selin Örnek'), MonitorStatus.attention);
      expect(kinds('Selin Örnek'), contains(SignalKind.highBloodPressure));
      expect(of('Murat Örnek'), MonitorStatus.attention);
      expect(kinds('Murat Örnek'), contains(SignalKind.overdueTask));
      expect(of('Hasan Örnek'), MonitorStatus.watch);
      expect(kinds('Hasan Örnek'), contains(SignalKind.lowAdherence));
      expect(of('Nermin Örnek'), MonitorStatus.watch);
      expect(kinds('Nermin Örnek'), contains(SignalKind.restingHrRise));
      expect(of('Zeynep Örnek'), MonitorStatus.stable);
      expect(kinds('Zeynep Örnek'), isEmpty, reason: 'stabil: sinyal yok');
      final kemal = board.patients.firstWhere(
        (p) => p.displayName == 'Kemal Örnek',
      );
      expect(kemal.status, MonitorStatus.inactive);
      expect(kemal.inactive, InactiveReason.pendingInvite);
      expect(kemal.adherence, isNull);
    });

    test('sıra: en ağır durum önce; sayılar toplamı tutar', () {
      final board = d.board();
      final ranks = [for (final p in board.patients) p.status.index];
      expect(ranks, orderedEquals([...ranks]..sort()));
      final counts = board.counts;
      expect(counts.values.reduce((a, b) => a + b), board.patients.length);
      expect(board.monitored, hasLength(board.patients.length - 1));
      expect(board.fresh, lessThanOrEqualTo(board.monitored.length));
      // Ortalama uyum yalnızca izlenen hastalardan.
      final list = [for (final p in board.monitored) p.adherence!];
      expect(
        board.meanAdherence,
        closeTo(list.reduce((a, b) => a + b) / list.length, 1e-9),
      );
    });

    test('sinyal kanıt taşır: sayı, değer ve eşik', () {
      final board = d.board();
      final selin = board.patients.firstWhere(
        (p) => p.displayName == 'Selin Örnek',
      );
      final bp = selin.signals.firstWhere(
        (s) => s.kind == SignalKind.highBloodPressure,
      );
      expect(bp.n, greaterThanOrEqualTo(MonitorBoard.repeated));
      expect(bp.value, greaterThanOrEqualTo(MonitorBoard.systolicHigh));
      final hasan = board.patients.firstWhere(
        (p) => p.displayName == 'Hasan Örnek',
      );
      expect(hasan.adherence, lessThan(MonitorBoard.adherenceMin));
      expect(hasan.coverage, hasLength(MonitorBoard.window));
    });

    test('etkinlik akışı en yeni önce ve süre içinde', () {
      final feed = activityFeed(d.store, d.doctorId, _now, days: 14);
      expect(feed, isNotEmpty);
      for (var i = 1; i < feed.length; i++) {
        expect(feed[i - 1].time.isBefore(feed[i].time), isFalse);
      }
      expect(
        feed.every(
          (e) =>
              !e.time.isAfter(_now) &&
              !e.time.isBefore(_now.subtract(const Duration(days: 14))),
        ),
        isTrue,
      );
      final kinds = {for (final e in feed) e.kind};
      expect(
        kinds,
        containsAll([ActivityKind.alertRaised, ActivityKind.dataReceived]),
      );
      // Veri alımı hasta başına tek olay.
      final data = [
        for (final e in feed)
          if (e.kind == ActivityKind.dataReceived) e.patientId,
      ];
      expect(data.toSet(), hasLength(data.length));
    });
  });

  group('panel sayfaları', () {
    late _Demo d;
    setUp(() async {
      d = _Demo();
      await d.open();
    });

    test(
      'genel bakış KPI, öncelik sırası ve deneme etiketi gösterir',
      () async {
        final html = await d.page('/panel');
        expect(html, contains('Deneme verisi'));
        expect(html, contains('İzlenen hasta'));
        expect(html, contains('Öncelikli hastalar'));
        final queue = _names(html);
        expect(queue.first, anyOf('Elif Örnek', 'a8c41d7e'));
        expect(
          queue,
          isNot(contains('Zeynep Örnek')),
          reason: 'stabil sırada yok',
        );
      },
    );

    test(
      'hasta listesi: durum süzgeci, arama, sıralama ve sayfalama',
      () async {
        final crit = _names(await d.page('/panel/patients?status=critical'));
        expect(crit.toSet(), {'Elif Örnek', 'a8c41d7e'});

        final need = _names(await d.page('/panel/patients?status=need'));
        expect(need, containsAll(['Elif Örnek', 'Selin Örnek', 'Leyla Örnek']));
        expect(need, isNot(contains('Hasan Örnek')));

        final found = _names(await d.page('/panel/patients?q=demo-1008'));
        expect(found, ['Selin Örnek'], reason: 'dosya numarasıyla arama');
        expect(
          await d.page('/panel/patients?q=zzzz'),
          contains('Aramaya uyan kayıt yok'),
        );

        final byName = _names(await d.page('/panel/patients?sort=name&n=25'));
        expect(byName, hasLength(12));
        final named = [
          for (final n in byName)
            if (n.contains(' ')) n,
        ];
        expect(named, orderedEquals([...named]..sort()));

        final p1 = _names(await d.page('/panel/patients'));
        final p2 = _names(await d.page('/panel/patients?p=2'));
        expect(p1, hasLength(10));
        expect(p2, hasLength(2));
        expect(p1.toSet().intersection(p2.toSet()), isEmpty);
        // Geçersiz sayfa son sayfaya sıkışır.
        expect(_names(await d.page('/panel/patients?p=99')), p2);
      },
    );

    test('eski ?q adresi hasta listesine yönlenir', () async {
      final r = await d.api.handler(
        Request(
          'GET',
          Uri.parse('http://portal.test/panel?q=elif'),
          headers: {'cookie': d.cookie},
        ),
      );
      expect(r.statusCode, 303);
      expect(r.headers['location'], '/panel/patients?q=elif');
    });

    test('hasta sayfası: dayanak, ölçüm kartı ve aralık seçimi', () async {
      const id = '00000000-0000-4000-8000-000000000001';
      final html = await d.page('/panel/patients/$id');
      expect(html, contains('Durumun dayanağı'));
      expect(html, contains('class="chart'));
      final month = await d.page('/panel/patients/$id?days=30&m=spo2');
      expect(month, contains('aria-current="true">30 gün'));
      final reads = d.store
          .auditForPatient(id)
          .where(
            (e) => e.action == AuditAction.read && e.actorId == d.doctorId,
          );
      expect(reads.map((e) => e.description), contains(contains('(30 gün)')));
    });

    test('etkinlik sayfası türe göre süzer', () async {
      final all = await d.page('/panel/activity');
      expect(all, contains('Etkinlik'));
      final alerts = await d.page('/panel/activity?type=alerts');
      final care = await d.page('/panel/activity?type=care');
      expect(alerts, isNot(contains('için yeni veri')));
      expect(care, isNot(contains('için yeni veri')));
      expect(all, contains('için yeni veri'));
    });
  });

  test('izlem metinleri dört dilde aynı anahtar ve yer tutucularla', () {
    final ph = RegExp(r'\{(\w+)\}');
    final tr = MonitorText.tr.strings;
    for (final t in MonitorText.all) {
      expect(t.strings.keys.toSet(), tr.keys.toSet(), reason: t.lang);
      for (final k in tr.keys) {
        expect(
          {for (final m in ph.allMatches(t.strings[k]!)) m.group(1)},
          {for (final m in ph.allMatches(tr[k]!)) m.group(1)},
          reason: '${t.lang}.$k',
        );
        expect(t.strings[k]!.trim(), isNotEmpty, reason: '${t.lang}.$k');
      }
    }
  });
}
