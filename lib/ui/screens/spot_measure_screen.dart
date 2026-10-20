import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/device_controller.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'ecg_screen.dart';

/// Ana Sayfa'daki "Şimdi ölç": nabız, SpO2 ya da EKG seçimi.
Future<void> showMeasureSheet(BuildContext context) {
  final l = context.l10n;
  return showCamSheet<void>(
    context: context,
    builder: (sheet) {
      Widget tile(
        IconData icon,
        Color color,
        String title,
        String sub,
        VoidCallback onTap,
      ) => ListTile(
        minTileHeight: 64,
        contentPadding: const EdgeInsetsDirectional.only(start: 20, end: 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub),
        trailing: Icon(Icons.chevron_right, color: context.colors.muted),
        onTap: () {
          Navigator.of(sheet).pop();
          onTap();
        },
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              child: Text(
                l.measureSheetTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            tile(
              Icons.favorite,
              DataColors.heart,
              l.measureHeartRate,
              l.measureTakes(30),
              () => startSpotMeasurement(context, MetricType.heartRate),
            ),
            tile(
              Icons.water_drop,
              DataColors.oxygen,
              l.measureSpo2,
              l.measureTakes(30),
              () => startSpotMeasurement(context, MetricType.spo2),
            ),
            tile(
              Icons.monitor_heart,
              DataColors.heart,
              l.measureEcg,
              l.measureEcgHint,
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EcgScreen()),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Bilekliğe ölçümü başlatır ve ölçüm ekranını açar. Bağlı değilse ya da
/// bileklik meşgulse nedenini kısa bir mesajla söyler.
Future<void> startSpotMeasurement(BuildContext context, MetricType type) async {
  final c = DeviceScope.of(context);
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  if (!c.isConnected) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.ecgConnectFirst)));
    return;
  }
  if (await c.startSpot(type)) {
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => SpotMeasureScreen(type: type)),
    );
  } else if (issueText(c) case final message?) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Süren elle ölçüm ve sonucu. Ölçüm bitince aynı ekranda sonuç gösterilir;
/// değer alınamazsa ekran kapanır ve neden söylenir.
class SpotMeasureScreen extends StatefulWidget {
  const SpotMeasureScreen({super.key, required this.type});

  final MetricType type;

  @override
  State<SpotMeasureScreen> createState() => _SpotMeasureScreenState();
}

class _SpotMeasureScreenState extends State<SpotMeasureScreen> {
  DeviceController? _controller;
  Measurement? _result;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = DeviceScope.of(context);
    if (c != _controller) {
      _controller?.removeListener(_onChange);
      _controller = c..addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final c = _controller!;
    if (c.spot != null || _closing || _result != null) return;
    final r = c.lastSpot;
    if (r != null && r.type == widget.type) {
      HapticFeedback.mediumImpact();
      setState(() => _result = r);
      return;
    }
    _closing = true;
    Navigator.of(context).pop();
    if (issueText(c) case final message?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _again() async {
    final c = _controller!;
    setState(() => _result = null);
    if (!await c.startSpot(widget.type) && mounted) {
      _closing = true;
      Navigator.of(context).pop();
      if (issueText(c) case final message?) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  String _value(int v) =>
      widget.type == MetricType.spo2 ? context.l10n.statPercent(v) : '$v';

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final type = widget.type;
    final s = c.spot;
    final result = _result;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && c.spot != null) c.cancelSpot();
      },
      child: CamScaffold(
        appBar: AppBar(title: Text(type.label)),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    Center(
                      child: _Dial(
                        color: type.color,
                        progress: result != null ? 1 : s?.progress ?? 0,
                        icon: type.icon,
                        value: result != null
                            ? _value(result.value.round())
                            : s?.latest == null
                            ? null
                            : _value(s!.latest!),
                        unit: type == MetricType.spo2 ? null : type.unit,
                        lines: [
                          if (result != null)
                            l.spotSaved(hhmm(result.time))
                          else if (s != null) ...[
                            l.spotMeasuring,
                            l.ecgSecondsLeft(s.remaining.inSeconds),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (result != null &&
                        type == MetricType.spo2 &&
                        result.value < 90) ...[
                      Text(
                        l.spotLowSpo2,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.danger),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      result == null ? l.spotKeepStill : l.spotNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: result == null
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: context.colors.outline),
                        ),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          _closing = true;
                          await c.cancelSpot();
                          navigator.pop();
                        },
                        child: Text(l.ecgCancel),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                side: BorderSide(color: context.colors.outline),
                              ),
                              onPressed: _again,
                              child: Text(
                                l.spotAgain,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlowButton(
                              onTap: () => Navigator.of(context).pop(),
                              label: l.spotDone,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İlerleme halkası ve ortasında canlı değer.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.color,
    required this.progress,
    required this.icon,
    required this.value,
    required this.unit,
    required this.lines,
  });

  final Color color;
  final double progress;
  final IconData icon;
  final String? value;
  final String? unit;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      children: [
        SizedBox.square(
          dimension: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: progress),
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, v, _) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: colors.surfaceHigh,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value ?? context.l10n.noValue,
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (unit != null)
                      Text(unit!, style: TextStyle(color: colors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted),
            ),
          ),
      ],
    );
  }
}
