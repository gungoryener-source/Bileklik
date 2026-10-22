import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Kamera önizlemesi; okunan her kodun ham metnini [onCode] ile bildirir.
typedef QrScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

/// Tarama ekranının sonucu: okunan değer ya da "elle gir" seçimi.
@immutable
class QrScanResult<T> {
  const QrScanResult.scanned(T this.value) : manual = false;
  const QrScanResult.manual() : value = null, manual = true;

  final T? value;

  /// Kullanıcı kamerayı bırakıp kodu elle girmek istedi.
  final bool manual;
}

/// Kamerayla QR kodu okur. Okunan metin [parse] ile çözülemezse ekran
/// kapanmaz, [invalidText] gösterilir ve okumaya devam edilir. Kamera izni
/// yoksa ya da kamera açılmazsa kullanıcı elle girişe geçer.
class QrScanScreen<T> extends StatefulWidget {
  const QrScanScreen({
    super.key,
    required this.title,
    required this.hint,
    required this.parse,
    required this.invalidText,
  });

  final String title;
  final String hint;
  final T? Function(String raw) parse;
  final String invalidText;

  /// Testlerde kamera yerine kullanılan okuyucu.
  @visibleForTesting
  static QrScannerBuilder? scannerOverride;

  @override
  State<QrScanScreen<T>> createState() => _QrScanScreenState<T>();
}

class _QrScanScreenState<T> extends State<QrScanScreen<T>> {
  bool _done = false;
  String? _lastInvalid;

  void _onCode(String raw) {
    if (_done) return;
    final value = widget.parse(raw);
    if (value == null) {
      // Aynı yanlış kod kamerada durdukça uyarı tekrar tekrar çıkmasın.
      if (raw == _lastInvalid) return;
      _lastInvalid = raw;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(widget.invalidText)));
      return;
    }
    _done = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(QrScanResult<T>.scanned(value));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final QrScannerBuilder scanner =
        QrScanScreen.scannerOverride ??
        ((_, onCode) => _CameraScanner(onCode: onCode));
    return CamScaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: colors.background,
                        child: scanner(context, _onCode),
                      ),
                      IgnorePointer(child: _Frame(color: colors.accent)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.muted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(QrScanResult<T>.manual()),
                    icon: const Icon(Icons.keyboard_outlined),
                    label: Text(l.qrManual),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: colors.outline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Telefon kamerası (mobile_scanner). İzin ilk açılışta sistem tarafından
/// sorulur; reddedilirse ya da kamera yoksa açıklama gösterilir.
class _CameraScanner extends StatelessWidget {
  const _CameraScanner({required this.onCode});

  final ValueChanged<String> onCode;

  @override
  Widget build(BuildContext context) => MobileScanner(
    onDetect: (capture) {
      for (final b in capture.barcodes) {
        final v = b.rawValue;
        if (v != null && v.isNotEmpty) {
          onCode(v);
          return;
        }
      }
    },
    errorBuilder: (context, e) => _CameraError(
      denied: e.errorCode == MobileScannerErrorCode.permissionDenied,
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.denied});

  final bool denied;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              denied ? Icons.no_photography_outlined : Icons.videocam_off,
              size: 40,
              color: colors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              denied ? l.qrCameraDenied : l.qrCameraUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortadaki kare çerçeve; kodun nereye getirileceğini gösterir.
class _Frame extends StatelessWidget {
  const _Frame({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: 0.65,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),
  );
}
