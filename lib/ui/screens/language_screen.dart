import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';

/// Dil seçimi. İlk açılışta tam ekran gelir; sonra Profil'den açılır.
///
/// Seçim hemen önizlenir (Arapça seçilince ekran sağdan sola döner) ama
/// "Devam" ile kaydedilir.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.firstRun = false});

  /// İlk açılış mı; değilse ekranın geri düğmesi olur.
  final bool firstRun;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

/// Telefonun dilini izleyen seçeneğin değeri.
const _system = 'system';

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selected != null) return;
    final settings = SettingsScope.of(context);
    if (widget.firstRun) {
      // İlk açılışta telefonun dili (destekleniyorsa) seçili gelir.
      final device = Localizations.localeOf(context).languageCode;
      _selected = supportedLanguages.contains(device) ? device : 'en';
    } else {
      _selected = settings.language ?? _system;
    }
  }

  String? get _code => _selected == _system ? null : _selected;

  Future<void> _done() async {
    await SettingsScope.of(context).setLanguage(_code);
    if (!mounted || widget.firstRun) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _code == null
        ? Localizations.localeOf(context)
        : Locale(_code!);
    return Localizations.override(
      context: context,
      locale: preview,
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    final l = context.l10n;
    final options = [if (!widget.firstRun) _system, ...supportedLanguages];
    return Scaffold(
      appBar: widget.firstRun ? null : AppBar(title: Text(l.languageTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            if (widget.firstRun) ...[
              Icon(Icons.translate, size: 40, color: context.colors.accent),
              const SizedBox(height: 16),
              Text(
                l.languagePickTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l.languagePickHint,
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 24),
            ],
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                children: [
                  for (final code in options)
                    RadioListTile<String>(
                      value: code,
                      title: Text(
                        code == _system ? l.languageSystem : languageName(code),
                      ),
                      // Dil adı kendi yazı yönüyle okunur.
                      subtitle: code == _system || code == 'en'
                          ? null
                          : Text(_englishName(code)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _done,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l.continueButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dilin İngilizce adı; dilini bilmeyen biri de seçeneği tanısın.
String _englishName(String code) => switch (code) {
  'tr' => 'Turkish',
  'en' => 'English',
  'ar' => 'Arabic',
  'de' => 'German',
  _ => code,
};
