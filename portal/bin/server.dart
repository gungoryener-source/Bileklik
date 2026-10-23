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
/// `--demo` iki deneme hesabı açar: `demo-patient` (hasta) ve `demo-doctor`
/// (hekim) oturum anahtarlarıyla; veriler sunucu kapanınca silinir.
/// `--add-clinician` (araştırma kurumu için ayrıca `--researcher`) hesabı
/// açar, oturum anahtarını bir kez yazar ve çıkar.
Future<void> main(List<String> args) async {
  if (args.contains('--new-key')) {
    stdout.writeln(EncryptedPortalStore.newKey());
    return;
  }
  final PortalStore store;
  if (args.contains('--demo')) {
    store = MemoryPortalStore()
      ..addAccount(
        const Account(
          id: '00000000-0000-4000-8000-000000000001',
          role: Role.patient,
          name: 'Demo hasta',
        ),
        'demo-patient',
      )
      ..addAccount(
        const Account(
          id: 'dr-demo',
          role: Role.clinician,
          name: 'Dr. Demo',
          organization: 'Demo Kliniği',
        ),
        'demo-doctor',
      );
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

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(PortalApi(store).handler);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Portal http://${server.address.host}:${server.port}');
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('$name=')) return a.substring(name.length + 1);
  }
  return null;
}
