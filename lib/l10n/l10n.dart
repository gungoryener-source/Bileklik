import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Uygulamanın desteklediği diller; ilki kaynak dildir.
const supportedLanguages = ['tr', 'en', 'ar', 'de'];

/// Dil adı, o dilin kendi yazısıyla (seçicide her dil kendi adıyla görünür).
String languageName(String code) => switch (code) {
  'tr' => 'Türkçe',
  'en' => 'English',
  'ar' => 'العربية',
  'de' => 'Deutsch',
  _ => code,
};

extension L10nOf on BuildContext {
  /// Etkin dilin metinleri.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// BuildContext olmayan biçimlendiriciler (süre, tarih) için etkin dil.
///
/// [LocaleSync] her dil değişiminde günceller; testlerde Türkçe başlar.
AppLocalizations get currentL10n => _current;
AppLocalizations _current = lookupAppLocalizations(const Locale('tr'));

/// MaterialApp altında etkin dili [currentL10n]'e yazar.
class LocaleSync extends StatelessWidget {
  const LocaleSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    _current = AppLocalizations.of(context);
    return child;
  }
}
