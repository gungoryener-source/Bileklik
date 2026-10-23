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
/// `--add-clinician` (araştırma kurumu için ayrıca `--researcher`; isteğe
/// bağlı `--email`, `--specialty`) hesabı açar, oturum anahtarını bir kez
/// yazar ve çıkar. Hekim panelde `/panel/register` ile kendisi de kaydolabilir.
/// `--list-clinicians` hekim hesaplarını, `--verify-clinician=<e-posta>`
/// kimliği doğrulanan hekimi onaylar.
Future<void> main(List<String> args) async {
  if (args.contains('--new-key')) {
    stdout.writeln(EncryptedPortalStore.newKey());
    return;
  }
  final demo = args.contains('--demo') ||
      Platform.environment['PORTAL_DEMO'] == '1';
  final key = Platform.environment['PORTAL_KEY'];
  final path = Platform.environment['PORTAL_DATA'];
  final PortalStore store;
  if (key == null || path == null) {
    // Anahtar ve dosya verilmediyse yalnızca deneme kipinde, bellekte açılır.
    if (demo) {
      store = MemoryPortalStore();
    } else {
      stderr.writeln(
        'PORTAL_KEY ve PORTAL_DATA gerekli (ya da --demo). Anahtar için: '
        'dart run bin/server.dart --new-key',
      );
      exitCode = 64;
      return;
    }
  } else {
    store = await EncryptedPortalStore.open(File(path), base64.decode(key));
  }

  // Geri bildirimleri JSON satırları olarak yazar ve çıkar.
  if (args.contains('--feedback')) {
    for (final f in store.feedback()) {
      stdout.writeln(jsonEncode(f.toJson()));
    }
    return;
  }

  // Kendi kaydolan hekimler: listeleme ve kimlik doğrulandıktan sonra onay.
  if (args.contains('--list-clinicians')) {
    for (final a in store.clinicians()) {
      stdout.writeln(
        [a.id, a.role.name, a.email ?? '-', a.name, a.licenseNo ?? '-',
          a.verified ? 'doğrulandı' : 'DOĞRULANMADI'].join('\t'),
      );
    }
    return;
  }
  final verify = _arg(args, '--verify-clinician');
  if (verify != null) {
    final a = store.accountByEmail(verify) ?? store.account(verify);
    if (a == null || (a.role != Role.clinician && a.role != Role.researcher)) {
      stderr.writeln('Hesap bulunamadı: $verify');
      exitCode = 1;
      return;
    }
    store.updateAccount(a.copyWith(verified: true));
    if (store is EncryptedPortalStore) await store.flush();
    stdout.writeln('Doğrulandı: ${a.name} (${a.email ?? a.id})');
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
        email: _arg(args, '--email')?.trim().toLowerCase(),
        specialty: _arg(args, '--specialty'),
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
  // Deneme verisi bir kez kurulur; kalıcı depoda yeniden başlatınca
  // tekrarlanmaz.
  if (demo && store.accountByToken(DemoTokens.doctor) == null) {
    await seedDemo(api);
    if (store is EncryptedPortalStore) await store.flush();
  }
  // `--site=<klasör>`: test portalında uygulamanın web sürümü ve açılış
  // sayfası aynı adresten sunulur (önce panel ve API, sonra dosyalar).
  final site = _arg(args, '--site') ?? Platform.environment['PORTAL_SITE'];
  final Handler app = site == null
      ? api.handler
      : Cascade().add(_static(Directory(site))).add(api.handler).handler;
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app);
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

const _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'mjs': 'text/javascript; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'json': 'application/json',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'webp': 'image/webp',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff2': 'font/woff2',
  'txt': 'text/plain; charset=utf-8',
  'bin': 'application/octet-stream',
  'frag': 'application/octet-stream',
};

/// Klasördeki dosyaları sunar; bulunamazsa 404 (zincirde sıradaki dener).
/// Klasör dışına çıkan yollar (`..`) reddedilir; klasör adresinde
/// `index.html` verilir.
Handler _static(Directory root) {
  final base = root.absolute.path;
  return (Request r) async {
    if (r.method != 'GET' && r.method != 'HEAD') return Response.notFound('');
    final segments = r.url.pathSegments;
    if (segments.any((s) => s == '..' || s.contains('\\'))) {
      return Response.notFound('');
    }
    var file = File([base, ...segments].join(Platform.pathSeparator));
    if (r.url.path.isEmpty || r.url.path.endsWith('/') ||
        await Directory(file.path).exists()) {
      if (r.url.path.isNotEmpty && !r.url.path.endsWith('/')) {
        return Response.movedPermanently('/${r.url.path}/');
      }
      file = File('${file.path}${Platform.pathSeparator}index.html');
    }
    if (!await file.exists()) return Response.notFound('');
    final ext = file.path.split('.').last.toLowerCase();
    return Response.ok(
      r.method == 'HEAD' ? null : file.openRead(),
      headers: {
        'content-type': _types[ext] ?? 'application/octet-stream',
        // Uygulama dosyaları her sürümde değişir; önbellek kısa tutulur.
        'cache-control': ext == 'html' ? 'no-cache' : 'public, max-age=300',
        'x-content-type-options': 'nosniff',
      },
    );
  };
}
