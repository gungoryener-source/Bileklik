import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'language_screen.dart';

/// Genel ayarlar: dil. Uygulama yalnızca koyu Cam temasında çalıştığı
/// için tema seçimi yok.
class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.profileMenuGeneral)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [_LanguageRow()],
        ),
      ),
    );
  }
}

/// Dil satırı: seçili dili gösterir, dokununca dil seçimini açar.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final code = SettingsScope.of(context).language;
    final current = code == null ? l.languageSystem : languageName(code);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Semantics(
        button: true,
        child: ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.translate),
          title: Text(l.languageTitle),
          subtitle: Text(current),
          // chevron_right yazı yönüne göre kendiliğinden döner.
          trailing: Icon(Icons.chevron_right, color: context.colors.muted),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
          ),
        ),
      ),
    );
  }
}
