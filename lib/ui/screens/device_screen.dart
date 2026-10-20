import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'pairing_screen.dart';

/// Cihaz: bağlıysa bilekliğin durumu, değilse eşleştirme.
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.profileMenuDevice)),
      body: SafeArea(
        top: false,
        child: c.isConnected ? const _Connected() : const PairingView(),
      ),
    );
  }
}

class _Connected extends StatelessWidget {
  const _Connected();

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final battery = c.battery;
    final sync = c.lastSync;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colors.glow,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.watch, size: 48, color: colors.accent),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          c.deviceName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _Row(l.deviceStatus, l.deviceConnected),
              if (battery != null)
                _Row(l.deviceBattery, l.deviceBatteryValue(battery.percent)),
              if (c.profile?.mac != null)
                _Row(l.deviceAddress, ltr(c.profile!.mac!)),
              _Row(
                l.deviceLastSync,
                sync == null ? l.noValue : whenText(sync, DateTime.now()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l.deviceSettingsNote, style: TextStyle(color: colors.muted)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: c.disconnect,
          icon: const Icon(Icons.link_off),
          label: Text(l.deviceDisconnect),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PairingScreen()),
          ),
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(l.devicePairNew),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 52,
    title: Text(label, style: TextStyle(color: context.colors.muted)),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Text(
        value,
        textAlign: TextAlign.end,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
