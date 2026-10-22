import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../state/app_settings.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/menu_group.dart';
import 'language_screen.dart';

/// Genel ayarlar: dil, saat biçimi, birimler. Uygulama yalnızca koyu Cam temasında çalıştığı
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
          children: const [_LanguageRow(), SizedBox(height: 12), _FormatRows()],
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

/// Saat biçimi ve birim satırları; dokununca seçim sayfası açılır.
class _FormatRows extends StatelessWidget {
  const _FormatRows();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = SettingsScope.of(context);
    final clocks = [
      (ClockFormat.system, l.clockSystem),
      (ClockFormat.h24, l.clock24),
      (ClockFormat.h12, l.clock12),
    ];
    final units = [
      (UnitSystem.metric, l.unitsMetric),
      (UnitSystem.imperial, l.unitsImperial),
    ];
    String label<T>(List<(T, String)> options, T v) =>
        options.firstWhere((o) => o.$1 == v).$2;
    return MenuGroup(
      children: [
        MenuTile(
          icon: Icons.schedule,
          title: l.clockTitle,
          subtitle: label(clocks, s.clock),
          onTap: () async {
            final v = await showChoiceSheet(
              context: context,
              title: l.clockTitle,
              options: clocks,
              current: s.clock,
            );
            if (v != null) await s.setClock(v);
          },
        ),
        MenuTile(
          icon: Icons.straighten,
          title: l.unitsTitle,
          subtitle: label(units, s.units),
          onTap: () async {
            final v = await showChoiceSheet(
              context: context,
              title: l.unitsTitle,
              options: units,
              current: s.units,
            );
            if (v != null) await s.setUnits(v);
          },
        ),
      ],
    );
  }
}
