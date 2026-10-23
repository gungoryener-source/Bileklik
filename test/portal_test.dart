import 'dart:async';
import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/connections.dart';
import 'package:bileklik/data/feedback.dart';
import 'package:bileklik/data/fhir.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/portal.dart';
import 'package:bileklik/data/secrets.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/connections_screen.dart';
import 'package:bileklik/ui/screens/portal_account_screen.dart';
import 'package:bileklik_portal/portal.dart' as portal;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shared_preferences/shared_preferences.dart';

/// Bellekte çalışan gerçek portal ve ona bağlı HTTP istemcisi.
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
  bool offline = false;

  http.Client get client => MockClient((r) async {
    if (offline) throw http.ClientException('bağlantı yok');
    final response = await api.handler(
      shelf.Request(
        r.method,
        r.url,
        headers: r.headers,
        body: r.bodyBytes,
      ),
    );
    return http.Response.bytes(
      await response.read().expand((b) => b).toList(),
      response.statusCode,
      headers: response.headers,
    );
  });

  /// Hekim davet kodu üretir (portalın kendi API'siyle).
  Future<String> invite(List<String> scopes) async {
    final c = _DoctorClient(this);
    return c.invite(scopes);
  }
}

/// Testte hekim tarafını oynayan küçük istemci.
class _DoctorClient {
  _DoctorClient(this.backend);
  final _Backend backend;

  Future<String> invite(List<String> scopes) async {
    final r = await backend.client.post(
      Uri.parse('http://portal.test/invites'),
      headers: {
        'authorization': 'Bearer doctor',
        'content-type': 'application/json',
      },
      body: '{"purpose":"Ritim takibi","scopes":[${scopes.map((s) => '"$s"').join(',')}],"days":90}',
    );
    expect(r.statusCode, 201);
    return RegExp(r'"code":"([A-Z0-9]+)"').firstMatch(r.body)!.group(1)!;
  }
}

PortalClient _client(_Backend b, AppSettings settings) => PortalClient(
  baseUrl: Uri.parse('http://portal.test/'),
  httpClient: b.client,
  credentials: settings,
);

void main() {
  test('paylaşım türlerinin kodları portalla aynı', () {
    for (final s in ShareScope.values) {
      expect(
        fhirCodesFor(s),
        portal.ShareScope.byName(s.name)!.codes,
        reason: s.name,
      );
    }
    expect(portal.ShareScope.values, hasLength(ShareScope.values.length));
  });

  test('hesap açılır, davet çözülür, bağlanılır ve kaldırılır', () async {
    final b = _Backend();
    final settings = AppSettings.memory();
    final service = PortalConnectionService(_client(b, settings));

    expect(await service.lookup('YOKBOYLE'), isNull);
    expect(settings.portalToken, hasLength(64), reason: 'ilk istekte kayıt');
    expect(b.store.account(settings.patientId)!.role, portal.Role.patient);

    final code = await b.invite(['heartRate', 'ecg']);
    final offer = (await service.lookup(code.toLowerCase()))!;
    expect(offer.name, 'Dr. Ayşe Kaya');
    expect(offer.organization, 'Kardiyoloji Polikliniği');
    expect(offer.kind, ConnectionKind.clinician);
    expect(offer.requested, {ShareScope.heartRate, ShareScope.ecg});
    expect(offer.duration, const Duration(days: 90));

    final c = await service.connect(offer, {ShareScope.heartRate});
    expect(c.scopes, {ShareScope.heartRate});
    expect(service.connections, hasLength(1));
    expect(service.sharedScopes, {ShareScope.heartRate});

    await service.disconnect(c.id);
    expect(service.connections, isEmpty);
  });

  test('oturum anahtarı güvenli depoda; eski sürümünkü taşınır', () async {
    SharedPreferences.setMockInitialValues({'portal_token': 'eski'});
    final secrets = MemorySecretStore();
    final settings = await AppSettings.load(secrets: secrets);
    expect(settings.portalToken, 'eski');
    expect(secrets.values['portal_token'], 'eski');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('portal_token'), isNull);

    await settings.setPortalToken('yeni');
    expect(secrets.values['portal_token'], 'yeni');
    expect((await AppSettings.load(secrets: secrets)).portalToken, 'yeni');
  });

  test('geri bildirim anahtarsız gider; hesap açılmaz', () async {
    final b = _Backend();
    final settings = AppSettings.memory();
    await PortalFeedbackService(_client(b, settings)).send(
      FeedbackTopic.bug,
      ' Senkron takılıyor ',
      context: const FeedbackContext(
        appVersion: '0.1.0',
        platform: 'android',
        locale: 'tr',
      ),
    );
    final saved = b.store.feedback().single;
    expect(saved.category, portal.FeedbackCategory.bug);
    expect(saved.message, 'Senkron takılıyor');
    expect(saved.platform, 'android');
    expect(settings.portalToken, isNull, reason: 'kimliğe bağlanmadı');
  });

  test('yalnızca paylaşılan türler yüklenir; bağlantı yoksa hiçbiri', () async {
    final b = _Backend();
    final settings = AppSettings.memory();
    final client = _client(b, settings);
    final service = PortalConnectionService(client);
    final now = DateTime(2026, 10, 20, 12);
    final store = MemoryHealthStore()
      ..addMeasurements([
        Measurement(MetricType.heartRate, now.subtract(const Duration(hours: 1)), 70),
        Measurement(MetricType.spo2, now.subtract(const Duration(hours: 1)), 97),
        Measurement(MetricType.weight, now.subtract(const Duration(hours: 1)), 80),
      ]);
    final uploader = PortalUploader(
      client: client,
      connections: service,
      store: store,
      clock: () => now,
    );
    addTearDown(uploader.dispose);

    expect(await uploader.uploadNow(), 0);
    expect(settings.portalToken, isNull, reason: 'bağlantı yokken hesap bile açılmaz');

    final code = await b.invite(['heartRate', 'spo2']);
    await service.connect((await service.lookup(code))!, {ShareScope.heartRate});
    expect(await uploader.uploadNow(), 1);
    final saved = b.store.observations(settings.patientId);
    expect(saved.map((o) => o.code), ['8867-4']);
    expect(settings.lastPortalUpload, now);

    // İkinci yükleme aynı kaydı tekrar yazmaz.
    expect(await uploader.uploadNow(), 1);
    expect(b.store.observations(settings.patientId), hasLength(1));
  });

  test('sunucuya ulaşılamazsa ConnectionUnavailable', () async {
    final b = _Backend()..offline = true;
    final service = PortalConnectionService(_client(b, AppSettings.memory()));
    await expectLater(
      service.lookup('ABC1234'),
      throwsA(isA<ConnectionUnavailable>()),
    );
  });

  testWidgets('kod girilince sunucu hatası ayrı mesajla gösterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final b = _Backend()..offline = true;
    final settings = AppSettings.memory();
    final controller = DeviceController(
      FakeDevice(random: Random(5)),
      store: MemoryHealthStore(),
    );
    await tester.pumpWidget(
      BileklikApp(
        controller: controller,
        settings: settings,
        connections: PortalConnectionService(_client(b, settings)),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const ConnectionsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.pin_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ABC1234');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Devam'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Sunucuya ulaşılamadı'), findsOneWidget);
    expect(find.text('Bu kod geçersiz ya da süresi dolmuş.'), findsNothing);
  });

  test('kurtarma koduyla hesap yeni telefona geçer', () async {
    final b = _Backend();
    final oldPhone = AppSettings.memory();
    final oldService = PortalConnectionService(_client(b, oldPhone));
    final code = await PortalAccountService(_client(b, oldPhone)).recoveryCode();
    expect(code, oldPhone.recoveryCode);
    final offer = (await oldService.lookup(await b.invite(['heartRate'])))!;
    await oldService.connect(offer, {ShareScope.heartRate});

    // Yeni telefon önce kendi (boş) hesabını açmış olsun.
    final newPhone = AppSettings.memory();
    final newService = PortalConnectionService(_client(b, newPhone));
    await newService.refresh();
    final emptyId = newPhone.patientId;
    var refreshed = false;
    final account = PortalAccountService(
      _client(b, newPhone),
      onRecovered: () async {
        refreshed = true;
        await newService.refresh();
      },
    );

    expect(await account.recover('AAAA-BBBB-CCCC-DDDD'), isFalse);
    expect(newPhone.patientId, emptyId);

    expect(await account.recover(code.toLowerCase()), isTrue);
    expect(newPhone.patientId, oldPhone.patientId);
    expect(newPhone.portalToken, isNot(oldPhone.portalToken));
    expect(newPhone.recoveryCode, isNot(code));
    expect(refreshed, isTrue);
    expect(newService.connections.single.offer.name, 'Dr. Ayşe Kaya');

    // Eski telefonun anahtarı artık geçmez.
    await expectLater(oldService.refresh(), throwsA(isA<ConnectionUnavailable>()));
  });

  test('kodu olmayan eski hesap ilk istekte yeni kod alır', () async {
    final b = _Backend();
    final settings = AppSettings.memory();
    final client = _client(b, settings);
    await PortalConnectionService(client).refresh();
    await settings.setRecoveryCode(null);
    final code = await PortalAccountService(client).recoveryCode();
    expect(code, matches(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$')));
    expect(settings.recoveryCode, code);
  });

  testWidgets('portal hesabı ekranı kodu gösterir, geçersiz kodu bildirir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final b = _Backend();
    final settings = AppSettings.memory();
    final client = _client(b, settings);
    await tester.pumpWidget(
      BileklikApp(
        controller: DeviceController(
          FakeDevice(random: Random(5)),
          store: MemoryHealthStore(),
        ),
        settings: settings,
        connections: PortalConnectionService(client),
        account: PortalAccountService(client),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => const PortalAccountScreen(),
              ),
            ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final code = settings.recoveryCode!;
    expect(find.text(code), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'AAAA-BBBB-CCCC-DDDD');
    await tester.pump();
    final restore = find.text('Geri yükle').last;
    await tester.ensureVisible(restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();
    // Onay penceresi.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Geri yükle'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('Kod geçersiz ya da daha önce kullanılmış.'), findsOneWidget);
    expect(settings.recoveryCode, code);
  });

  test('aile grubu portal üzerinden: kişiye özel kod, rıza ve yükleme', () async {
    final b = _Backend();
    final mePhone = AppSettings.memory();
    final sisterPhone = AppSettings.memory();
    final mine = PortalCommunityService(_client(b, mePhone));
    final hers = PortalCommunityService(_client(b, sisterPhone));

    final g = await mine.createGroup('  Kaya ailesi ');
    expect(g.name, 'Kaya ailesi');
    expect(g.ownedByMe, isTrue);
    expect(g.inviteCode, hasLength(6));
    expect(mine.myGroups, hasLength(1));

    final code = await mine.invite(g.id, 'Ablam');
    expect(code, isNot(g.inviteCode));
    expect(mine.group(g.id)!.members.last.pending, isTrue);

    expect(await hers.joinWithCode('YOKKOD'), isNull);
    final joined = (await hers.joinWithCode(code.toLowerCase()))!;
    expect(joined.ownedByMe, isFalse);
    expect(hers.joinedGroups.single.id, g.id);
    expect(joined.members.firstWhere((m) => m.isMe).name, 'Ablam');

    // Sahibe katılım bildirimi gelir; okununca rozet söner.
    await mine.refresh();
    expect(mine.messages.single.from, 'Ablam');
    expect(mine.messages.single.kind, CommunityMessageKind.memberJoined);
    expect(mine.unreadCount, 1);
    mine.markAllRead();
    await Future<void>.delayed(Duration.zero);
    expect(mine.unreadCount, 0);

    // Paylaşım rızası: abla nabzını paylaşır, yükleyici yalnızca onu gönderir.
    await hers.setConsent(g.id, {ShareScope.heartRate});
    expect(hers.sharedScopes, {ShareScope.heartRate});
    expect(hers.group(g.id)!.myConsent.grantedAt, isNotNull);
    await mine.refresh();
    expect(
      mine.group(g.id)!.members.firstWhere((m) => m.name == 'Ablam').shares,
      {ShareScope.heartRate},
    );

    final now = DateTime(2026, 10, 20, 12);
    final uploader = PortalUploader(
      client: _client(b, sisterPhone),
      connections: PortalConnectionService(_client(b, sisterPhone)),
      community: hers,
      store: MemoryHealthStore()
        ..addMeasurements([
          Measurement(MetricType.heartRate, now.subtract(const Duration(hours: 1)), 70),
          Measurement(MetricType.spo2, now.subtract(const Duration(hours: 1)), 97),
        ]),
      clock: () => now,
    );
    addTearDown(uploader.dispose);
    expect(await uploader.uploadNow(), 1);
    expect(
      b.store.observations(sisterPhone.patientId).map((o) => o.code),
      ['8867-4'],
    );

    // Sahip üyeyi çıkarır; abla için grup kalmaz.
    final sisterMember = mine.group(g.id)!.members.firstWhere((m) => m.name == 'Ablam');
    await mine.removeMember(g.id, sisterMember.id);
    await hers.refresh();
    expect(hers.joinedGroups, isEmpty);
    expect(hers.sharedScopes, isEmpty);

    await mine.leave(g.id);
    expect(mine.myGroups, isEmpty);
  });

  test('portaldaki veriler silinir; rızalar ve grup paylaşımları biter', () async {
    final b = _Backend();
    final settings = AppSettings.memory();
    final client = _client(b, settings);
    final service = PortalConnectionService(client);
    final community = PortalCommunityService(client);
    final now = DateTime(2026, 10, 20, 12);
    final uploader = PortalUploader(
      client: client,
      connections: service,
      store: MemoryHealthStore()
        ..addMeasurements([
          Measurement(MetricType.heartRate, now.subtract(const Duration(hours: 1)), 70),
          Measurement(MetricType.heartRate, now.subtract(const Duration(hours: 2)), 72),
        ]),
      clock: () => now,
    );
    addTearDown(uploader.dispose);
    await service.connect(
      (await service.lookup(await b.invite(['heartRate'])))!,
      {ShareScope.heartRate},
    );
    final g = await community.createGroup('Ev');
    await community.setConsent(g.id, {ShareScope.sleep});
    expect(await uploader.uploadNow(), 2);

    var refreshed = 0;
    final account = PortalAccountService(
      client,
      onRecovered: () async {
        refreshed++;
        await service.refresh();
        await community.refresh();
      },
    );
    expect(await account.eraseData(), 2);
    expect(b.store.observations(settings.patientId), isEmpty);
    expect(refreshed, 1);
    expect(service.connections, isEmpty);
    expect(community.sharedScopes, isEmpty);
  });
}
