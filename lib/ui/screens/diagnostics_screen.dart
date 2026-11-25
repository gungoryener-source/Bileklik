import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../device/device_log.dart';
import '../../device/protocol/commands.dart';
import '../../device/protocol/packet.dart';
import '../../device/transport.dart';
import '../../l10n/l10n.dart';
import '../../state/device_controller.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/menu_group.dart';

/// Kaydı telefonun paylaşım menüsüyle gönderir (e-posta, WhatsApp…).
typedef ShareLog = Future<void> Function(String text);

Future<void> _shareWithSystem(String text) async {
  await SharePlus.instance.share(
    ShareParams(text: text, subject: 'Bileklik BLE kaydı'),
  );
}

/// Bağlantı tanılama: gerçek bileklikle ilk denemelerde ne olduğunu gösterir.
///
/// Bağlantı durumu, test komutları (yanıtları kayıtta görünür), ad süzgeci
/// olmadan arama, demo kipi anahtarı ve paylaşılabilir ham paket kaydı.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.share = _shareWithSystem});

  final ShareLog share;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final _raw = TextEditingController();
  String? _rawError;
  bool? _demo;
  bool _scanned = false;

  /// Kayıt ekranda en çok bu kadar satır gösterir; paylaşılan metin tamdır.
  static const _visibleLines = 300;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDemo());
  }

  Future<void> _loadDemo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () => _demo = prefs.getBool(DeviceController.demoModeKey) ?? false,
    );
  }

  Future<void> _setDemo(bool v) async {
    setState(() => _demo = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DeviceController.demoModeKey, v);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.diagRestartNeeded)));
  }

  @override
  void dispose() {
    _raw.dispose();
    super.dispose();
  }

  Future<void> _send(Packet p) async {
    final c = DeviceScope.of(context);
    if (!c.isConnected) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.diagNotConnected)));
      return;
    }
    try {
      await c.sendRaw(p.bytes);
    } catch (_) {
      // Hata kayıtta görünür (LoggingTransport).
    }
  }

  Future<void> _sendRaw() async {
    final bytes = parseHex(_raw.text);
    if (bytes == null || bytes.length > 15 || bytes.first > 0x7F) {
      setState(() => _rawError = context.l10n.diagRawInvalid);
      return;
    }
    setState(() => _rawError = null);
    await _send(Packet.build(bytes.first, bytes.sublist(1)));
  }

  Future<void> _share(DeviceController c) async {
    final header = [
      'Bileklik BLE kaydı ${DateTime.now().toIso8601String()}',
      'kip: ${c.isDemo ? 'demo' : 'gerçek'}',
      'bileklik: ${c.deviceName} ${c.pairedId ?? '-'}',
      'durum: ${c.connection.name}, paket boyu: ${c.maxWriteLength}',
      if (c.firmware case final fw?) 'yazılım: ${fw.version}',
      if (c.error case final e?) 'son hata: $e',
      '',
    ].join('\n');
    await widget.share(c.log.export(header: header));
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(
        title: Text(l.diagTitle),
        actions: [
          IconButton(
            tooltip: l.diagShare,
            icon: const Icon(Icons.ios_share),
            onPressed: () => _share(c),
          ),
          IconButton(
            tooltip: l.diagClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: c.log.clear,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: c.log,
          builder: (context, _) => ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
            children: [
              Text(
                l.diagIntro,
                style: TextStyle(color: context.colors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              _status(context, c),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          c.connection == DeviceConnectionState.connecting ||
                              c.isConnected ||
                              !c.hasPairedDevice
                          ? null
                          : c.connect,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: Text(l.diagReconnect),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: c.hasPairedDevice ? c.forgetDevice : null,
                      icon: const Icon(Icons.link_off),
                      label: Text(l.diagForget),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
              MenuHeader(l.diagSectionTests),
              Text(
                l.diagTestsHint,
                style: TextStyle(color: context.colors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(l.diagTestBattery, Commands.batteryLevel()),
                  _chip(l.diagTestTime, Commands.getTime()),
                  _chip(l.diagTestFirmware, Commands.firmwareVersion()),
                  _chip(l.diagTestProfile, Commands.getPersonalInfo()),
                  _chip(l.diagTestRealtime, Commands.realtime(true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextField(
                        controller: _raw,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: l.diagRawLabel,
                          hintText: l.diagRawHint,
                          errorText: _rawError,
                          errorMaxLines: 2,
                        ),
                        onSubmitted: (_) => _sendRaw(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4),
                    child: FilledButton.tonal(
                      onPressed: _sendRaw,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 48),
                      ),
                      child: Text(l.diagRawSend),
                    ),
                  ),
                ],
              ),
              MenuHeader(l.diagSectionScan),
              Text(
                l.diagScanHint,
                style: TextStyle(color: context.colors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: c.scanning
                    ? null
                    : () async {
                        await c.scan(all: true);
                        if (mounted) setState(() => _scanned = true);
                      },
                icon: c.scanning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar),
                label: Text(c.scanning ? l.diagScanning : l.diagScan),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (_scanned && !c.scanning) ..._scanResults(context, c),
              MenuHeader(l.diagSectionDeveloper),
              MenuGroup(
                children: [
                  SwitchListTile(
                    value: _demo ?? c.isDemo,
                    onChanged: _demo == null ? null : _setDemo,
                    title: Text(l.diagDemoSwitch),
                    subtitle: Text(l.diagDemoHint),
                  ),
                ],
              ),
              MenuHeader(l.diagSectionLog),
              ..._logLines(context, c.log),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(BuildContext context, DeviceController c) {
    final l = context.l10n;
    final retry = c.nextReconnect;
    final state = switch (c.connection) {
      DeviceConnectionState.connected => l.deviceConnected,
      DeviceConnectionState.connecting => l.diagConnecting,
      DeviceConnectionState.disconnected => l.deviceDisconnected,
    };
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _Row(l.diagMode, c.isDemo ? l.diagModeDemo : l.diagModeReal),
          _Row(l.deviceStatus, state),
          _Row(
            l.diagPaired,
            c.hasPairedDevice
                ? ltr('${c.deviceName} ${c.pairedId ?? ''}'.trim())
                : l.diagNone,
          ),
          if (c.isConnected)
            _Row(l.diagWriteLength, l.diagWriteLengthValue(c.maxWriteLength)),
          if (c.firmware case final fw?)
            _Row(l.deviceFirmware, ltr(fw.version)),
          if (retry != null && !c.isConnected)
            _Row(
              l.diagNextRetry,
              l.diagNextRetryValue(
                retry.difference(DateTime.now()).inSeconds.clamp(0, 999),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Packet p) => ActionChip(
    label: Text(label),
    avatar: const Icon(Icons.send, size: 16),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    onPressed: () => _send(p),
  );

  List<Widget> _scanResults(BuildContext context, DeviceController c) {
    final l = context.l10n;
    if (c.found.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(l.diagScanEmpty, textAlign: TextAlign.center),
        ),
      ];
    }
    return [
      const SizedBox(height: 8),
      MenuGroup(
        children: [
          for (final d in c.found)
            ListTile(
              minTileHeight: 56,
              title: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                ltr(
                  '${d.connectId}  ${d.rssi} dBm'
                  '${d.details == null ? '' : '\n${d.details}'}',
                ),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: context.colors.muted,
                ),
              ),
              trailing: TextButton(
                onPressed: () => c.connectTo(d),
                style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
                child: Text(l.diagConnectTo),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _logLines(BuildContext context, DeviceLog log) {
    final l = context.l10n;
    final entries = log.entries;
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            l.diagLogEmpty,
            style: TextStyle(color: context.colors.muted),
          ),
        ),
      ];
    }
    final colors = context.colors;
    final shown = entries.reversed.take(_visibleLines);
    return [
      Text(
        l.diagLogCount(entries.length),
        style: TextStyle(color: colors.muted, fontSize: 12),
      ),
      const SizedBox(height: 8),
      GlassCard(
        padding: const EdgeInsets.all(12),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      e.format(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.35,
                        color: switch (e.kind) {
                          LogKind.tx => colors.accent,
                          LogKind.rx => colors.text,
                          LogKind.event => colors.muted,
                          LogKind.error => colors.danger,
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 48,
    title: Text(label, style: TextStyle(color: context.colors.muted)),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(
        value,
        textAlign: TextAlign.end,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
