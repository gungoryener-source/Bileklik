import 'package:qr/qr.dart';

/// Davet kodunun QR karesi, satır içi SVG olarak.
///
/// QR'da yalnızca kodun kendisi yazar ("K7MP2QX"); uygulamanın QR okuyucusu
/// (`inviteCodeFromQr`) bunu doğrudan kod olarak alır. Kare koyu zeminde de
/// okunsun diye beyaz kutu ve dört modüllük sessiz kenarla çizilir.
String qrSvg(String data, {required String label, int size = 200}) {
  final image = QrImage(QrCode(payload: QrPayload.fromString(data)));
  final n = image.moduleCount;
  const quiet = 4;
  final total = n + quiet * 2;
  final path = StringBuffer();
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (image.isDark(y, x)) path.write('M${x + quiet} ${y + quiet}h1v1h-1z');
    }
  }
  final safeLabel = label
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');
  return '<svg class="qr" xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 $total $total" width="$size" height="$size" '
      'role="img" aria-label="$safeLabel" shape-rendering="crispEdges">'
      '<rect width="$total" height="$total" fill="#fff"/>'
      '<path d="$path" fill="#000"/></svg>';
}
