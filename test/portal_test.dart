import 'dart:math';

import 'package:bileklik/data/community.dart';
import 'package:bileklik/data/connections.dart';
import 'package:bileklik/data/fhir.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/data/portal.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/connections_screen.dart';
import 'package:bileklik_portal/portal.dart' as portal;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;

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
    final c = PortalClientForDoctor(this);
    return c.invite(scopes);
  }
}

/// Testte hekim tarafını oynayan küçük istemci.
class PortalClientForDoctor {
  PortalClientForDoctor(this.backend);
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
}
