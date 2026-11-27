import 'package:flutter/material.dart';

import '../../data/insights.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/insights.dart';
import 'personal_info_screen.dart';

/// Biyolojik yaş. 21 gün kesintisiz veri toplanana kadar ilerlemeyi, her
/// gün gereken verileri, yaş uyarısını ve ipuçlarını gösterir; sonra rapor.
class BiologicalAgeScreen extends StatelessWidget {
  const BiologicalAgeScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scope = DeviceScope.of(context);
    final store = scope.store;
    return CamScaffold(
      appBar: AppBar(title: Text(l.bioAgeTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final age = scope.profile?.age;
            final c = BioAgeCollection.of(store, day);
            const gap = SizedBox(height: CamSpace.gap);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (c.ready)
                  BiologicalAgeCard(store: store, day: day, age: age)
                else ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.bioAgeCollectingTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        BioAgeProgress(collection: c),
                      ],
                    ),
                  ),
                  gap,
                  BioAgeDailyData(today: c.today),
                ],
                if (!c.ready || age == null) ...[
                  gap,
                  _AgeCheck(missing: age == null),
                ],
                if (!c.ready) ...[gap, const _Tips()],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Yaşın doğru girilmesi uyarısı; dokununca Kişisel bilgiler açılır.
class _AgeCheck extends StatelessWidget {
  const _AgeCheck({required this.missing});

  final bool missing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final title = missing ? l.bioAgeNeedsAge : l.bioAgeAgeCheckTitle;
    return Pressable(
      semanticLabel: '$title ${l.bioAgeAgeCheckBody}',
      pressedScale: 0.98,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PersonalInfoScreen()),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.bioAgeAgeCheckBody,
                    style: TextStyle(
                      color: colors.danger.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.danger),
          ],
        ),
      ),
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.bioAgeTipsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final tip in [
            l.bioAgeTipSleep,
            l.bioAgeTipHeart,
            l.bioAgeTipActivity,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 5, color: colors.muted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(tip, style: TextStyle(color: colors.muted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
