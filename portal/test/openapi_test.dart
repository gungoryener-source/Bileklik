import 'dart:convert';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  final api = PortalApi(
    MemoryPortalStore()..addAccount(
      const Account(id: 'p-1', role: Role.patient, name: '-'),
      'patient',
    ),
  );

  Future<Response> call(String method, String path, {bool auth = true}) async =>
      await api.handler(
        Request(
          method.toUpperCase(),
          Uri.parse('http://portal.test$path'),
          headers: {if (auth) 'authorization': 'Bearer patient'},
          body: '',
        ),
      );

  test('belgedeki her uç yönlendiricide var', () async {
    for (final op in OpenApi.endpoints) {
      final path = op.path.replaceAllMapped(RegExp(r'\{\w+\}'), (_) => 'x');
      final r = await call(op.method, path);
      expect(
        await r.readAsString(),
        isNot('Route not found'),
        reason: '${op.method} ${op.path}',
      );
    }
    // Belgede olmayan bir uç gerçekten "bulunamadı" der.
    expect(await (await call('get', '/yok')).readAsString(), 'Route not found');
  });

  test('openapi.json anahtarsız açılır ve geçerli yapıdadır', () async {
    final r = await call('get', '/openapi.json', auth: false);
    expect(r.statusCode, 200);
    final spec = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
    expect(spec['openapi'], '3.1.0');
    final paths = spec['paths'] as Map<String, dynamic>;
    expect(paths.keys, contains('/fhir/Observation'));
    final search = paths['/fhir/Observation']['get'] as Map<String, dynamic>;
    final params = search['parameters'] as List;
    expect(
      params.firstWhere((p) => p['name'] == 'patient')['required'],
      isTrue,
    );
    expect(paths['/health']['get']['security'], isEmpty);
    expect(
      (paths['/invites/{code}']['get']['parameters'] as List).single['in'],
      'path',
    );
    expect(spec['info']['description'], contains('heartRate (8867-4'));
  });

  test('geliştirici sayfası anahtarsız açılır', () async {
    final r = await call('get', '/developers', auth: false);
    expect(r.statusCode, 200);
    final html = await r.readAsString();
    expect(html, contains('<code>/fhir/Observation</code>'));
    expect(html, contains('href="/openapi.json"'));
    expect(
      r.headers['content-security-policy'],
      contains("default-src 'none'"),
    );
  });
}
