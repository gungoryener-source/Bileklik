import 'package:flutter/material.dart';

import '../../data/health_platform.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/menu_group.dart';
import '../widgets/cam/cam.dart';

/// Health Connect (Android) ve Apple Health (iOS) aktarımı: tür seçimi,
/// platformun izin penceresi, son aktarım ve durdurma.
class HealthPlatformScreen extends StatefulWidget {
  const HealthPlatformScreen({super.key});

  @override
  State<HealthPlatformScreen> createState() => _HealthPlatformScreenState();
}

/// Platformun adı; marka adı, çevrilmez.
String platformName(HealthPlatformKind k) => switch (k) {
  HealthPlatformKind.healthConnect => 'Health Connect',
  HealthPlatformKind.appleHealth => 'Apple Health',
};

extension ExportTypeLook on ExportType {
  String get label {
    final l = currentL10n;
    return switch (this) {
      ExportType.activity => l.hpActivity,
      ExportType.heartRate => l.shareHeartRate,
      ExportType.spo2 => l.shareSpo2,
      ExportType.hrv => l.hpHrv,
      ExportType.temperature => l.shareTemperature,
      ExportType.respiratoryRate => l.metricRespiratoryRate,
      ExportType.sleep => l.shareSleep,
      ExportType.workouts => l.hpWorkouts,
    };
  }

  IconData get icon => switch (this) {
    ExportType.activity => Icons.directions_walk,
    ExportType.heartRate => Icons.favorite,
    ExportType.spo2 => Icons.water_drop,
    ExportType.hrv => Icons.monitor_heart,
    ExportType.temperature => Icons.thermostat,
    ExportType.respiratoryRate => Icons.air,
    ExportType.sleep => Icons.bedtime,
    ExportType.workouts => Icons.fitness_center,
  };

  Color get color => switch (this) {
    ExportType.activity => DataColors.steps,
    ExportType.heartRate => DataColors.heart,
    ExportType.spo2 => DataColors.oxygen,
    ExportType.hrv => DataColors.hrv,
    ExportType.temperature => DataColors.temperature,
    ExportType.respiratoryRate => DataColors.respiration,
    ExportType.sleep => DataColors.sleepLight,
    ExportType.workouts => DataColors.stress,
  };
}

class _HealthPlatformScreenState extends State<HealthPlatformScreen> {
  // Bağlanmadan önce seçilenler; kullanıcı kendi telefonuna yazdığı için
  // hepsi açık başlar, istemediğini kapatır.
  final _chosen = ExportType.values.toSet();

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  String _exported(int n) => n == 0
      ? context.l10n.hpNothingNew
      : context.l10n.hpExported(context.l10n.hpRecords(n));

  Future<void> _connect(HealthExportService s, String name) async {
    final l = context.l10n;
    if (!await s.platform.isAvailable()) {
      _snack(l.hpUnavailable(name));
      return;
    }
    final ok = await s.connect({..._chosen});
    if (!mounted) return;
    if (ok.isEmpty) {
      _snack(l.hpDenied(name));
    } else {
      _snack(_exported(s.lastCount));
    }
  }

  Future<void> _disconnect(HealthExportService s, String name) async {
    final l = context.l10n;
    final colors = context.colors;
    final ok = await showCamDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.hpDisconnect),
        content: Text(l.hpDisconnectNote(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: colors.onAccent,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.hpDisconnect),
          ),
        ],
      ),
    );
    if (ok == true) s.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final s = HealthExportScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final name = ltr(platformName(s.platform.kind));
    final connected = s.connected;

    return CamScaffold(
      appBar: AppBar(title: Text(l.hpTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _PlatformCard(
                    name: name,
                    connected: connected,
                    status: !connected
                        ? null
                        : s.lastExport == null
                        ? l.hpNever
                        : l.hpLastExport(
                            whenText(s.lastExport!, DateTime.now()),
                            l.hpRecords(s.lastCount),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 4,
                    ),
                    child: Text(
                      connected ? l.hpAuto : l.hpIntro(name),
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                  MenuHeader(l.hpChooseTypes),
                  MenuGroup(
                    children: [
                      for (final t in ExportType.values)
                        if (!connected || s.granted.contains(t))
                          SwitchListTile(
                            contentPadding: const EdgeInsetsDirectional.only(
                              start: 16,
                              end: 12,
                            ),
                            secondary: Icon(t.icon, color: t.color),
                            title: Text(t.label),
                            value: connected || _chosen.contains(t),
                            onChanged: s.busy
                                ? null
                                : (on) {
                                    if (connected) {
                                      s.remove(t);
                                    } else {
                                      setState(
                                        () => on
                                            ? _chosen.add(t)
                                            : _chosen.remove(t),
                                      );
                                    }
                                  },
                          ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
                    child: Text(
                      connected
                          ? l.hpNotExported
                          : '${l.hpNotExported}\n${l.hpPermissionNote(name)}',
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                  if (connected) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.danger,
                        side: BorderSide(color: colors.outline),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => _disconnect(s, name),
                      icon: const Icon(Icons.sync_disabled),
                      label: Text(l.hpDisconnect),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GlowButton(
                onTap: s.busy || (!connected && _chosen.isEmpty)
                    ? null
                    : connected
                    ? () async {
                        _snack(_exported(await s.exportNow()));
                      }
                    : () => _connect(s, name),
                loading: s.busy,
                icon: connected ? Icons.sync : Icons.link,
                label: connected ? l.hpExportNow : l.hpConnect(name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.name,
    required this.connected,
    this.status,
  });

  final String name;
  final bool connected;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.glow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.health_and_safety, color: colors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 2),
                  Text(status!, style: TextStyle(color: colors.muted)),
                ],
              ],
            ),
          ),
          if (connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.glow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l.hpConnected,
                style: TextStyle(color: colors.accent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
