import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Gizlilik politikası (KVKK aydınlatma metni taslağı).
///
/// Hakkında ekranından açılır. Android'de Health Connect izin ekranındaki
/// "neden" bağlantısı ve Android 14+ izin kullanımı ekranı uygulamayı bu
/// sayfayla açar ([routeName], `MainActivity.getInitialRoute`). Aynı metin
/// portalda `/gizlilik` adresinde ve `docs/gizlilik-politikasi.md` içinde.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const routeName = '/privacy';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final sections = [
      (l.privacyDataTitle, l.privacyDataBody),
      (l.privacyStorageTitle, l.privacyStorageBody),
      (l.privacyPurposeTitle, l.privacyPurposeBody),
      (l.privacyLegalTitle, l.privacyLegalBody),
      (l.privacySharingTitle, l.privacySharingBody),
      (l.privacyAuditTitle, l.privacyAuditBody),
      (l.privacyRetentionTitle, l.privacyRetentionBody),
      (l.privacyRightsTitle, l.privacyRightsBody),
      (l.privacyContactTitle, l.privacyContactBody),
    ];
    return CamScaffold(
      appBar: AppBar(title: Text(l.privacyTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
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
                    child: Text(
                      l.privacyDraft,
                      style: TextStyle(color: colors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(l.privacyIntro),
            for (final (title, body) in sections) ...[
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(title, style: text.titleMedium),
              ),
              const SizedBox(height: 6),
              Text(body),
            ],
          ],
        ),
      ),
    );
  }
}
