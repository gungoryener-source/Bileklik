import 'dart:convert';
import 'dart:io';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 10, 20, 12);

void main() {
  late MemoryPortalStore store;
  late PortalApi api;
  late String cookie;
  late String csrf;
  var clock = _now;

  Future<Response> send(
    String method,
    String path, {
    Map<String, String>? form,
    String? referer,
    bool auth = true,
  }) async => await api.handler(
    Request(
      method,
      Uri.parse('http://portal.test$path'),
      headers: {
        if (auth) 'cookie': cookie,
        'referer': ?referer,
        if (form != null) 'content-type': 'application/x-www-form-urlencoded',
      },
      body: form == null ? null : Uri(queryParameters: form).query,
    ),
  );

  Future<String> page(String path) async =>
      (await send('GET', path)).readAsString();

  setUp(() async {
    clock = _now;
    store = MemoryPortalStore()
      ..addAccount(
        const Account(id: 'dr-1', role: Role.clinician, name: 'Dr. Ayşe'),
        'doctor',
      )
      ..addAccount(
        const Account(id: 'dr-2', role: Role.clinician, name: 'Dr. Başka'),
        'stranger',
      )
      ..putRecord(
        PatientRecord(
          id: 'rec-1',
          ownerId: 'dr-1',
          name: 'Mehmet Yılmaz',
          created: _now,
        ),
      );
    api = PortalApi(store, clock: () => clock);
    cookie = '';
    final login = await send(
      'POST',
      '/panel/login',
      form: {'token': 'doctor'},
      auth: false,
    );
    cookie = login.headers['set-cookie']!.split(';').first;
    csrf = RegExp(
      r'name="csrf" value="([0-9a-f]+)"',
    ).firstMatch(await page('/panel/records/rec-1'))!.group(1)!;
  });

  test('not ve görev eklenir, görev ana sayfada görünür ve kapanır', () async {
    final note = await send(
      'POST',
      '/panel/records/rec-1/care',
      form: {
        'csrf': csrf,
        'kind': 'note',
        'text': 'Beta bloker başlandı.\nKontrol 2 hafta sonra.',
      },
    );
    expect(note.statusCode, 303);
    expect(note.headers['location'], '/panel/records/rec-1');
    await send(
      'POST',
      '/panel/records/rec-1/care',
      form: {
        'csrf': csrf,
        'kind': 'task',
        'text': 'Hastayı ara',
        'due': '2026-10-19',
      },
    );
    await send(
      'POST',
      '/panel/records/rec-1/care',
      form: {
        'csrf': csrf,
        'kind': 'task',
        'text': 'EKG sonucunu incele',
        'due': '',
      },
    );
    final rec = await page('/panel/records/rec-1');
    expect(rec, contains('İzlem notları ve görevler'));
    expect(rec, contains('Beta bloker başlandı.'));
    expect(rec, contains('Gecikti (19.10.2026)'));
    // Gecikmiş görev son günsüz görevden önce.
    expect(
      rec.indexOf('Hastayı ara'),
      lessThan(rec.indexOf('EKG sonucunu incele')),
    );

    final home = await page('/panel');
    expect(home, contains('Görevlerim'));
    expect(home, contains('Hastayı ara'));
    expect(home, contains('href="/panel/records/rec-1"'));

    final task = store
        .openTasksOf('dr-1')
        .firstWhere((e) => e.text == 'Hastayı ara');
    clock = _now.add(const Duration(hours: 1));
    final done = await send(
      'POST',
      '/panel/records/rec-1/care/${task.id}/done',
      form: {'csrf': csrf},
      referer: 'http://portal.test/panel',
    );
    expect(done.statusCode, 303);
    expect(done.headers['location'], '/panel');
    expect(store.care(task.id)!.doneAt, clock);
    final after = await page('/panel/records/rec-1');
    expect(after, contains('Görev tamamlandı'));
    expect(store.openTasksOf('dr-1').single.text, 'EKG sonucunu incele');
  });

  test('geçersiz girdi, yanlış CSRF ve başka hekim reddedilir', () async {
    for (final f in [
      {'csrf': csrf, 'kind': 'note', 'text': '  '},
      {'csrf': csrf, 'kind': 'task', 'text': 'x', 'due': '2026-02-30'},
      {'csrf': csrf, 'kind': 'task', 'text': 'x' * 301},
      {'csrf': csrf, 'kind': 'memo', 'text': 'x'},
    ]) {
      expect(
        (await send('POST', '/panel/records/rec-1/care', form: f)).statusCode,
        400,
      );
    }
    expect(
      (await send(
        'POST',
        '/panel/records/rec-1/care',
        form: {'csrf': 'x', 'kind': 'note', 'text': 'a'},
      )).statusCode,
      403,
    );
    expect(store.careOf('rec-1'), isEmpty);

    // Başka hekim kaydı ve görevi göremez, kapatamaz.
    await send(
      'POST',
      '/panel/records/rec-1/care',
      form: {'csrf': csrf, 'kind': 'task', 'text': 'Gizli'},
    );
    final id = store.careOf('rec-1').single.id;
    cookie = (await send(
      'POST',
      '/panel/login',
      form: {'token': 'stranger'},
      auth: false,
    )).headers['set-cookie']!.split(';').first;
    expect(await page('/panel'), isNot(contains('Gizli')));
    final other = RegExp(
      r'name="csrf" value="([0-9a-f]+)"',
    ).firstMatch(await page('/panel/records/new'))!.group(1)!;
    final r = await send(
      'POST',
      '/panel/records/rec-1/care/$id/done',
      form: {'csrf': other},
    );
    expect(r.statusCode, 403);
    expect(store.care(id)!.open, isTrue);
  });

  test('kayıt silinince notlar da silinir; şifreli depoda kalıcı', () async {
    final dir = await Directory.systemTemp.createTemp('care');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/p.log');
    final key = base64.decode(EncryptedPortalStore.newKey());
    final s = await EncryptedPortalStore.open(file, key);
    s.putRecord(
      PatientRecord(id: 'r', ownerId: 'dr', name: 'A', created: _now),
    );
    final e = CareEntry(
      id: 'c1',
      recordId: 'r',
      ownerId: 'dr',
      kind: CareKind.task,
      text: 'Ara',
      created: _now,
      due: DateTime.utc(2026, 10, 21),
    );
    s.putCare(e);
    s.putCare(e.done(_now));
    await s.flush();
    var again = await EncryptedPortalStore.open(file, key);
    expect(again.care('c1')!.doneAt, _now);
    expect(again.care('c1')!.due, DateTime.utc(2026, 10, 21));
    again.deleteRecord('r');
    await again.flush();
    again = await EncryptedPortalStore.open(file, key);
    expect(again.careOf('r'), isEmpty);
  });

  test('bölüm dört dilde açılır', () async {
    for (final lang in ['en', 'ar', 'de']) {
      final r = await api.handler(
        Request(
          'GET',
          Uri.parse('http://portal.test/panel/records/rec-1?lang=$lang'),
          headers: {'cookie': cookie, 'accept-language': lang},
        ),
      );
      expect(r.statusCode, 200);
      final html = await r.readAsString();
      expect(html, contains(ClinicText.of(lang)['careTitle']));
    }
  });
}
