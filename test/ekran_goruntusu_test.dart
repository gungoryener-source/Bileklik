import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/portal.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/community_dialogs.dart';
import 'package:bileklik/ui/screens/feedback_screen.dart';
import 'package:bileklik/ui/screens/group_screen.dart';
import 'package:bileklik/ui/screens/portal_account_screen.dart';
import 'package:bileklik/ui/screens/privacy_screen.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:bileklik_portal/portal.dart' as portal;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Ekran görüntüleri: yalnızca `EKRAN=1` ile çalışır.
///
/// ```sh
/// EKRAN=1 flutter test --update-goldens test/ekran_goruntusu_test.dart
/// ```
///
/// Görüntüler `test/ekran/` altına yazılır (390 x 844 dp, 3x). Gerçek yazı
/// tipi (Manrope) ve Material ikonları yüklenir; Arapça için
/// `build/NotoSansArabic.ttf` varsa o da. Hekim paneli ve gizlilik sayfasının
/// HTML'i de aynı klasöre yazılır.
final _enabled = Platform.environment['EKRAN'] == '1';

Future<ByteData> _bytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

Future<void> _loadFonts() async {
  final manrope = FontLoader('Manrope');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    manrope.addFont(_bytes('assets/fonts/Manrope-$w.ttf'));
  }
  await manrope.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(_bytes(icons.path))).load();
    }
  }
  final arabic = File('build/NotoSansArabic.ttf');
  if (arabic.existsSync()) {
    await (FontLoader('Noto Sans Arabic')..addFont(_bytes(arabic.path)))
        .load();
  }
}

/// Bellekteki gerçek portal.
class _Backend {
  _Backend() {
    store.addAccount(
      const portal.Account(
        id: 'dr-1',
        role: portal.Role.clinician,
        name: 'Dr. Ayşe Kaya',
        organization: 'Kardiyoloji Polikliniği',
      ),
      'doctor',
    );
    api = portal.PortalApi(store, random: Random(9));
  }

  final store = portal.MemoryPortalStore();
  late final portal.PortalApi api;

  http.Client get client => MockClient((r) async {
    final res = await api.handler(
      shelf.Request(r.method, r.url, headers: r.headers, body: r.bodyBytes),
    );
    return http.Response.bytes(
      await res.read().expand((b) => b).toList(),
      res.statusCode,
      headers: res.headers,
    );
  });
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('ekran/$name.png'));
}

Future<DeviceController> _app(
  WidgetTester tester, {
  String language = 'tr',
  PortalAccountService? account,
  CommunityService? community,
  bool connect = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final device = FakeDevice(
    random: Random(7),
    realtimeInterval: const Duration(minutes: 30),
  );
  final controller = DeviceController(device, store: MemoryHealthStore());
  if (connect) await tester.runAsync(controller.connect);
  await tester.pumpWidget(
    BileklikApp(
      controller: controller,
      settings: AppSettings.memory(language: language),
      account: account,
      community: community,
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.runAsync(controller.disconnect);
    device.dispose();
  });
  return controller;
}

void _push(WidgetTester tester, Widget screen) => unawaited(
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => screen)),
);

Future<void> _tab(WidgetTester tester, int i) async {
  await tester.tap(
    find.descendant(
      of: find.byType(GlassNavBar),
      matching: find.byType(Pressable),
    ).at(i),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (_enabled) await _loadFonts();
  });

  testWidgets('ana sayfa', skip: !_enabled, (tester) async {
    await _app(tester, connect: true);
    await _shot(tester, '01-ana-sayfa');
  });

  testWidgets('profil', skip: !_enabled, (tester) async {
    final b = _Backend();
    final settings = AppSettings.memory();
    await _app(
      tester,
      account: PortalAccountService(
        PortalClient(
          baseUrl: Uri.parse('http://portal.test/'),
          httpClient: b.client,
          credentials: settings,
        ),
      ),
    );
    await _tab(tester, 3);
    await _shot(tester, '02-profil');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
    await _shot(tester, '03-profil-alt');
  });

  for (final lang in ['tr', 'ar']) {
    testWidgets('geri bildirim $lang', skip: !_enabled, (tester) async {
      await _app(tester, language: lang);
      _push(tester, const FeedbackScreen());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        lang == 'tr'
            ? 'Haftalık raporun e-postayla gelmesi güzel olurdu.'
            : 'سيكون من الجيد إرسال التقرير الأسبوعي بالبريد.',
      );
      await _shot(tester, '04-geri-bildirim-$lang');
    });
  }

  testWidgets('portal hesabı', skip: !_enabled, (tester) async {
    final b = _Backend();
    final settings = AppSettings.memory();
    final account = PortalAccountService(
      PortalClient(
        baseUrl: Uri.parse('http://portal.test/'),
        httpClient: b.client,
        credentials: settings,
      ),
    );
    await _app(tester, account: account);
    await tester.runAsync(() async {
      await account.recoveryCode();
      _push(tester, const PortalAccountScreen());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await _shot(tester, '05-portal-hesabi');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -700));
    await _shot(tester, '06-portal-hesabi-alt');
  });

  for (final lang in ['tr', 'de', 'ar']) {
    testWidgets('gizlilik $lang', skip: !_enabled, (tester) async {
      await _app(tester, language: lang);
      _push(tester, const PrivacyScreen());
      await _shot(tester, '07-gizlilik-$lang');
    });
  }

  testWidgets('aile grubu ve davet kodu', skip: !_enabled, (tester) async {
    final community = FakeCommunityServer(
      latency: Duration.zero,
      acceptDelay: null,
      seed: false,
    );
    final g = await community.createGroup('Kaya ailesi');
    await community.invite(g.id, 'Annem');
    await community.setConsent(g.id, {ShareScope.heartRate, ShareScope.sleep});
    await _app(tester, community: community);
    _push(tester, GroupScreen(groupId: g.id));
    await _shot(tester, '08-aile-grubu');
    final context = tester.element(find.byType(GroupScreen));
    unawaited(
      showCamDialog<void>(
        context: context,
        builder: (_) => InviteCodeDialog(code: g.inviteCode, name: 'Annem'),
      ),
    );
    await _shot(tester, '09-davet-kodu');
  });

  test('hekim paneli ve gizlilik sayfası HTML', skip: !_enabled, () async {
    final b = _Backend();
    const patient = '6f1c2a3e-1111-4222-8333-944455556666';
    b.store.addAccount(
      const portal.Account(id: patient, role: portal.Role.patient, name: '-'),
      'patient',
    );
    Future<shelf.Response> send(
      String method,
      String path, {
      String? cookie,
      String? body,
      String? bearer,
    }) async => await b.api.handler(
      shelf.Request(
        method,
        Uri.parse('http://portal.test$path'),
        headers: {
          'cookie': ?cookie,
          if (bearer != null) 'authorization': 'Bearer $bearer',
          if (body != null && bearer == null)
            'content-type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ),
    );
    final login = await send('POST', '/panel/login', body: 'token=doctor');
    final cookie = login.headers['set-cookie']!.split(';').first;
    final home = await (await send('GET', '/panel', cookie: cookie))
        .readAsString();
    final csrf = RegExp(r'name="csrf" value="([0-9a-f]+)"')
        .firstMatch(home)!
        .group(1)!;
    final created = await (await send(
      'POST',
      '/panel/invites',
      cookie: cookie,
      body: 'csrf=$csrf&purpose=Ritim+takibi&scope=heartRate&scope=spo2&days=90',
    )).readAsString();
    final code = RegExp(r'class="code">([A-Z2-9]{7})<')
        .firstMatch(created)!
        .group(1)!;
    await send(
      'POST',
      '/invites/$code/accept',
      bearer: 'patient',
      body: '{"scopes":["heartRate","spo2"]}',
    );
    final now = DateTime.now().toUtc();
    await send(
      'POST',
      '/fhir',
      bearer: 'patient',
      body: '{"resourceType":"Bundle","type":"collection","entry":['
          '{"resource":{"resourceType":"Patient","id":"$patient"}}'
          '${[
            for (var i = 0; i < 14; i++)
              ',{"resource":{"resourceType":"Observation","identifier":[{"system":"x","value":"hr$i"}],'
                  '"status":"final","code":{"coding":[{"system":"http://loinc.org","code":"8867-4"}]},'
                  '"subject":{"reference":"urn:uuid:$patient"},'
                  '"effectiveDateTime":"${now.subtract(Duration(hours: i * 12)).toIso8601String()}",'
                  '"valueQuantity":{"value":${68 + (i * 7) % 15},"unit":"beats/minute"}}}',
            ',{"resource":{"resourceType":"Observation","identifier":[{"system":"x","value":"o1"}],'
                '"status":"final","code":{"coding":[{"system":"http://loinc.org","code":"59408-5"}]},'
                '"subject":{"reference":"urn:uuid:$patient"},'
                '"effectiveDateTime":"${now.toIso8601String()}",'
                '"valueQuantity":{"value":97,"unit":"%"}}}',
          ].join()}]}',
    );
    final dir = Directory('test/ekran')..createSync(recursive: true);
    Future<void> save(String name, String path) async {
      final html = await (await send('GET', path, cookie: cookie))
          .readAsString();
      File('${dir.path}/$name.html').writeAsStringSync(html);
    }

    await save('10-panel-hastalarim', '/panel?lang=tr');
    await save('11-panel-hasta', '/panel/patients/$patient');
    await save('12-panel-hasta-ar', '/panel/patients/$patient?lang=ar');
    File('${dir.path}/13-panel-davet.html').writeAsStringSync(created);
    await save('14-gizlilik-sayfasi', '/gizlilik');
  });
}
