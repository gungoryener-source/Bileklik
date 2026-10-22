import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../../device/protocol/settings.dart';
import '../widgets/menu_group.dart';
import 'auto_measure_screen.dart';
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
        MenuHeader(l.deviceSectionSettings),
        MenuGroup(
          children: [
            MenuTile(
              icon: Icons.schedule,
              title: l.autoMeasureTitle,
              subtitle: autoMeasureSummary(context),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AutoMeasureScreen(),
                ),
              ),
            ),
            const _WearDetectionTile(),
          ],
        ),
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

/// Açık otomatik ölçümlerin adları ("Nabız, HRV") ya da "Kapalı".
String? autoMeasureSummary(BuildContext context) {
  final c = DeviceScope.of(context);
  final l = context.l10n;
  if (c.autoMeasure.isEmpty) {
    return c.settingsFailed ? l.autoMeasureLoadFailed : null;
  }
  final on = [
    for (final t in AutoMeasureType.values)
      if (c.autoMeasure[t]?.enabled ?? false)
        switch (t) {
          AutoMeasureType.heartRate => l.measureHeartRate,
          AutoMeasureType.spo2 => 'SpO2',
          AutoMeasureType.hrv => 'HRV',
        },
  ];
  return on.isEmpty ? l.autoMeasureOff : on.join(', ');
}

/// Takma algılaması anahtarı. Tercih telefonda saklanır, bilekliğe her
/// bağlantıda yeniden yazılır.
class _WearDetectionTile extends StatelessWidget {
  const _WearDetectionTile();

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final settings = SettingsScope.of(context);
    final l = context.l10n;
    return SwitchListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.back_hand_outlined,
          size: 22,
          color: context.colors.text,
        ),
      ),
      title: Text(
        l.wearDetectionTitle,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        l.wearDetectionSubtitle,
        style: TextStyle(color: context.colors.muted),
      ),
      value: c.wearDetection,
      onChanged: (v) async {
        final messenger = ScaffoldMessenger.of(context);
        if (await c.setWearDetection(v)) {
          await settings.setWearDetection(v);
        } else {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.wearDetectionFailed)));
        }
      },
    );
  }
}
