import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../device/transport.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';

/// Ayrı sayfa olarak eşleştirme ("Başka bileklik eşleştir").
/// Bağlanınca kendini kapatır.
class PairingScreen extends StatelessWidget {
  const PairingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      top: false,
      child: PairingView(onConnected: () => Navigator.of(context).pop()),
    ),
  );
}

/// Bileklik arama ve adresle (QR kodunun altındaki) eşleştirme.
///
/// Kamerayla QR okuma gerçek bileklik geldiğinde eklenecek (ROADMAP 17);
/// şimdilik QR'ın altında yazan adres elle girilir.
class PairingView extends StatefulWidget {
  const PairingView({super.key, this.onConnected});

  final VoidCallback? onConnected;

  @override
  State<PairingView> createState() => _PairingViewState();
}

class _PairingViewState extends State<PairingView> {
  bool _searched = false;
  bool _connecting = false;

  Future<void> _scan() async {
    HapticFeedback.selectionClick();
    await DeviceScope.of(context).scan();
    if (mounted) setState(() => _searched = true);
  }

  Future<void> _connect(DiscoveredDevice d) async {
    final c = DeviceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _connecting = true);
    await c.connectTo(d);
    if (!mounted) return;
    setState(() => _connecting = false);
    final problem = issueText(c);
    messenger.showSnackBar(SnackBar(content: Text(problem ?? l.pairConnected)));
    if (c.isConnected) {
      HapticFeedback.mediumImpact();
      widget.onConnected?.call();
    }
  }

  Future<void> _pairWithAddress() async {
    final address = await showDialog<String>(
      context: context,
      builder: (_) => const _AddressDialog(),
    );
    if (address == null || !mounted) return;
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final found = c.found.isEmpty ? await c.scan() : c.found;
    if (!mounted) return;
    final match = found.where((d) => d.address == address).firstOrNull;
    if (match == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.pairCodeNotFound)));
      return;
    }
    await _connect(match);
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final busy = c.scanning || _connecting;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(l.pairTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(l.pairSubtitle, style: TextStyle(color: colors.muted)),
        const SizedBox(height: 24),
        Center(child: _Radar(active: c.scanning)),
        const SizedBox(height: 24),
        if (_searched && !c.scanning) ...[
          if (c.found.isEmpty)
            Text(l.pairNoneFound, style: TextStyle(color: colors.danger))
          else ...[
            Text(l.pairFound, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final d in c.found)
              Card(
                child: ListTile(
                  minTileHeight: 64,
                  leading: Icon(Icons.watch, color: colors.accent),
                  title: Text(d.name),
                  subtitle: Text(
                    '${ltr(d.address)} · ${l.pairSignal(d.rssi)}',
                    style: TextStyle(color: colors.muted),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: busy ? null : () => _connect(d),
                    child: Text(l.pairConnect),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: colors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l.pairNote, style: TextStyle(color: colors.muted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : _scan,
          icon: c.scanning
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bluetooth_searching),
          label: Text(c.scanning ? l.pairScanning : l.pairScan),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy ? null : _pairWithAddress,
          icon: const Icon(Icons.qr_code_2),
          label: Text(l.pairCode),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

/// Bileklik simgesi ve çevresinde halkalar; arama sürerken halkalar
/// dışa doğru yayılır. "Hareketi azalt" açıksa durağan kalır.
class _Radar extends StatefulWidget {
  const _Radar({required this.active});
  final bool active;

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Radar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.disableAnimationsOf(context);
    if (widget.active && !still) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      _anim
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 180,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => CustomPaint(
            painter: _RingsPainter(_anim.value, colors.accent),
            child: child,
          ),
          child: Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.glow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.watch, size: 40, color: colors.accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final max = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      // Her halka bir öncekinin üçte bir adım gerisinden gelir.
      final p = (i / 3 + t) % 1.0;
      final r = 40 + (max - 40) * p;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.45 * (1 - p) + 0.05);
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t || old.color != color;
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog();

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final a = normalizeAddress(_ctrl.text);
    if (a == null) {
      setState(() => _error = context.l10n.pairCodeInvalid);
      return;
    }
    Navigator.of(context).pop(a);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.pairCode),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pairCodeHint),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            // Adres her dilde soldan sağa yazılır.
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l.pairCodeLabel,
              hintText: 'A1:B2:C3:D4:E5:F6',
              errorText: _error,
              errorMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l.pairConnect)),
      ],
    );
  }
}
