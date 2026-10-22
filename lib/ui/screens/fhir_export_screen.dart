import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/fhir.dart';
import '../../data/health_store.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Dosyayı telefonun paylaşım menüsüyle gönderir.
typedef ShareFile = Future<void> Function(Uint8List bytes, String fileName);

Future<void> _shareWithSystem(Uint8List bytes, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(bytes, mimeType: 'application/fhir+json', name: fileName),
      ],
      fileNameOverrides: [fileName],
    ),
  );
}

/// Ölçümleri FHIR R4 JSON dosyası olarak dışa aktarır. Kullanıcı dönemi ve
/// EKG kayıtlarının eklenip eklenmeyeceğini seçer; dosya paylaşım menüsüyle
/// gider (hekime e-posta, başka bir uygulama…).
class FhirExportScreen extends StatefulWidget {
  const FhirExportScreen({super.key, this.share = _shareWithSystem, this.clock});

  final ShareFile share;
  final DateTime Function()? clock;

  @override
  State<FhirExportScreen> createState() => _FhirExportScreenState();
}

/// Dışa aktarılacak dönem.
enum ExportPeriod {
  week(7),
  month(30),
  quarter(90);

  const ExportPeriod(this.days);
  final int days;
}

class _FhirExportScreenState extends State<FhirExportScreen> {
  ExportPeriod _period = ExportPeriod.month;
  bool _ecg = true;
  bool _busy = false;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  (DateTime, DateTime) get _range {
    final to = _now();
    return (to.subtract(Duration(days: _period.days)), to);
  }

  /// Dosyaya girecek kayıt sayısı (hasta kaydı hariç). Dosyanın kendisinden
  /// sayılır; eşi olmayan tansiyon değeri gibi atlananlar sayılmaz.
  int _count(HealthStore store) {
    final (from, to) = _range;
    final b = FhirExporter(
      patientId: 'count',
      random: Random(0),
      clock: _now,
    ).bundle(store, from: from, to: to, includeEcg: _ecg);
    return (b['entry']! as List).length - 1;
  }

  Future<void> _export() async {
    final store = DeviceScope.of(context).store;
    final settings = SettingsScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final (from, to) = _range;
    setState(() => _busy = true);
    try {
      final bundle = FhirExporter(
        patientId: settings.patientId,
        clock: _now,
      ).bundle(store, from: from, to: to, includeEcg: _ecg);
      final bytes = Uint8List.fromList(utf8.encode(FhirExporter.encode(bundle)));
      final day = to.toIso8601String().substring(0, 10).replaceAll('-', '');
      await widget.share(bytes, 'bileklik-fhir-$day.json');
      HapticFeedback.lightImpact();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.exportFailed)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final store = DeviceScope.of(context).store;
    return CamScaffold(
      appBar: AppBar(title: Text(l.exportTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final count = _count(store);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(l.exportIntro, style: TextStyle(color: colors.muted)),
                const SizedBox(height: 20),
                Text(
                  l.exportPeriod,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ExportPeriod>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ExportPeriod.week,
                      label: Text(l.periodWeek),
                    ),
                    ButtonSegment(
                      value: ExportPeriod.month,
                      label: Text(l.periodMonth),
                    ),
                    ButtonSegment(
                      value: ExportPeriod.quarter,
                      label: Text(l.bodyRange3Months),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    value: _ecg,
                    onChanged: (v) => setState(() => _ecg = v),
                    title: Text(l.exportIncludeEcg),
                    subtitle: Text(
                      l.exportIncludeEcgNote,
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: colors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          count == 0 ? l.exportEmpty : l.exportRecordCount(count),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: colors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.exportPrivacy,
                        style: TextStyle(color: colors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlowButton(
                  label: l.exportShare,
                  icon: Icons.ios_share,
                  loading: _busy,
                  onTap: count == 0 || _busy ? null : _export,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
