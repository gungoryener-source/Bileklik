import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Portal sunucusu.
///
/// ```sh
/// dart run bin/server.dart --demo            # bellekte, deneme hesaplarıyla
/// dart run bin/server.dart --new-key         # PORTAL_KEY için anahtar üretir
/// PORTAL_KEY=… PORTAL_DATA=data/portal.log dart run bin/server.dart
/// PORTAL_KEY=… PORTAL_DATA=… dart run bin/server.dart \
///   --add-clinician="Dr. Ayşe Kaya" --org="Kardiyoloji Polikliniği"
/// ```
///
/// `--demo` deneme verisiyle açılır ([seedDemo]): `demo-doctor` (hekim),
/// `demo-research` (araştırma), `demo-patient` (hasta) anahtarları; veriler
/// sunucu kapanınca silinir.
/// `--feedback` uygulamadan gelen geri bildirimleri yazar.
/// `--add-clinician` (araştırma kurumu için ayrıca `--researcher`) hesabı
/// açar, oturum anahtarını bir kez yazar ve çıkar.
Future<void> main(List<String> args) async {
  if (args.contains('--new-key')) {
    stdout.writeln(EncryptedPortalStore.newKey());
    return;
  }
  final PortalStore store;
  if (args.contains('--demo')) {
    store = MemoryPortalStore();
  } else {
    final key = Platform.environment['PORTAL_KEY'];
    final path = Platform.environment['PORTAL_DATA'];
    if (key == null || path == null) {
      stderr.writeln(
        'PORTAL_KEY ve PORTAL_DATA gerekli (ya da --demo). Anahtar için: '
        'dart run bin/server.dart --new-key',
      );
      exitCode = 64;
      return;
    }
    store = await EncryptedPortalStore.open(File(path), base64.decode(key));
  }

  // Geri bildirimleri JSON satırları olarak yazar ve çıkar.
  if (args.contains('--feedback')) {
    for (final f in store.feedback()) {
      stdout.writeln(jsonEncode(f.toJson()));
    }
    return;
  }

  final name = _arg(args, '--add-clinician');
  if (name != null) {
    final r = Random.secure();
    final token = List.generate(
      32,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    store.addAccount(
      Account(
        id: store.nextId('dr'),
        role: args.contains('--researcher') ? Role.researcher : Role.clinician,
        name: name,
        organization: _arg(args, '--org'),
      ),
      token,
    );
    if (store is EncryptedPortalStore) await store.flush();
    stdout.writeln(token);
    return;
  }

  final api = PortalApi(
    store,
    // HTTPS arkasında: panel çerezi yalnızca şifreli bağlantıda gider.
    secureCookie: Platform.environment['PORTAL_HTTPS'] == '1',
  );
  if (args.contains('--demo')) await seedDemo(api);
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(api.handler);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Portal http://${server.address.host}:${server.port}');
  stdout.writeln('Hekim paneli http://${server.address.host}:${server.port}/panel');
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return null;
}
