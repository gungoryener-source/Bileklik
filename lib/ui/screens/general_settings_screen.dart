import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import 'language_screen.dart';

/// Genel ayarlar: görünüm (tema) ve dil.
class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.profileMenuGeneral)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l.profileAppearance,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const _ThemePicker(),
            const SizedBox(height: 24),
            const _LanguageRow(),
          ],
        ),
      ),
    );
  }
}

/// Tema seçimi: telefonun ayarına uy, her zaman açık ya da koyu.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final l = context.l10n;
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto),
          label: Text(l.profileThemeSystem),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode),
          label: Text(l.profileThemeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode),
          label: Text(l.profileThemeDark),
        ),
      ],
      selected: {settings.themeMode},
      onSelectionChanged: (s) => settings.setThemeMode(s.first),
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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
