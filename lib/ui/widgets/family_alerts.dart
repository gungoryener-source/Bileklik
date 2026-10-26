import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../screens/group_screen.dart';
import '../theme.dart';
import 'cam/cam.dart';

/// Acil durum satırının metni: "Annem: SpO2 düşük (en düşük %86)".
String familyAlertText(BuildContext context, String name, FamilyAlert a) {
  final l = context.l10n;
  final n = isolate(name.isEmpty ? l.communityUnnamedMember : name);
  String r(double v) => v.round().toString();
  return switch (a.kind) {
    FamilyAlertKind.spo2Low => l.familyAlertSpo2Low(n, r(a.value)),
    FamilyAlertKind.heartRateHigh => l.familyAlertHeartRateHigh(n, r(a.value)),
    FamilyAlertKind.heartRateLow => l.familyAlertHeartRateLow(n, r(a.value)),
    FamilyAlertKind.bloodPressureCrisis => l.familyAlertBloodPressure(
      n,
      r(a.value),
      a.value2 == null ? '—' : r(a.value2!),
    ),
    FamilyAlertKind.fever => l.familyAlertFever(
      n,
      '${MetricType.temperature.format(a.value)} ${MetricType.temperature.unit}',
    ),
  };
}

/// Olayın zamanı: tek ölçümse saat, sürdüyse başlangıç ve bitiş.
String familyAlertTime(BuildContext context, FamilyAlert a) {
  final now = DateTime.now();
  final start = whenText(a.start, now);
  if (!a.end.isAfter(a.start)) return ltr(start);
  return context.l10n.familyAlertTime(ltr(start), ltr(hhmm(a.end)));
}

/// Tek acil durum satırı (ana sayfa kartı ve grup sayfası).
class FamilyAlertLine extends StatelessWidget {
  const FamilyAlertLine({super.key, required this.name, required this.alert});

  final String name;
  final FamilyAlert alert;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: colors.danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                familyAlertText(context, name, alert),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                familyAlertTime(context, alert),
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ana sayfadaki "Aile uyarısı" kartı: gruplarda izin veren üyelerin son
/// 24 saatteki acil durumları. Uyarı yoksa ya da topluluk yoksa görünmez.
class FamilyAlertCard extends StatelessWidget {
  const FamilyAlertCard({super.key});

  /// Kartta en çok bu kadar satır; fazlası grup sayfasında.
  static const maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final service = CommunityScope.maybeOf(context);
    final alerts = service?.familyAlerts ?? const [];
    if (alerts.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final colors = context.colors;
    final first = alerts.first;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Pressable(
        semanticLabel:
            '${l.familyAlertTitle}. ${familyAlertText(context, first.member.name, first.alert)}',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupScreen(groupId: first.group.id),
          ),
        ),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.familyAlertTitle,
                      style: Theme.of(context).textTheme.titleMedium!
                          .copyWith(color: colors.danger),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.muted),
                ],
              ),
              for (final a in alerts.take(maxLines))
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: FamilyAlertLine(name: a.member.name, alert: a.alert),
                ),
              const SizedBox(height: 12),
              Text(
                l.familyAlertNote,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
