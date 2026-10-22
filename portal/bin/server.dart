import 'dart:io';

import 'package:bileklik_portal/portal.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Geliştirme sunucusu: `dart run bin/server.dart [--demo]`.
///
/// `--demo` iki deneme hesabı açar: `demo-patient` (hasta) ve `demo-doctor`
/// (hekim) oturum anahtarlarıyla. Veriler bellekte tutulur; sunucu kapanınca
/// silinir.
Future<void> main(List<String> args) async {
  final store = MemoryPortalStore();
  if (args.contains('--demo')) {
    store
      ..addAccount(
        const Account(
          id: '00000000-0000-4000-8000-000000000001',
          role: Role.patient,
          name: 'Demo hasta',
        ),
        'demo-patient',
      )
      ..addAccount(
        const Account(id: 'dr-demo', role: Role.clinician, name: 'Dr. Demo'),
        'demo-doctor',
      );
  }
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(PortalApi(store).handler);
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Portal http://${server.address.host}:${server.port}');
}
