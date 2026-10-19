import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının uygulama tercihleri (tema ve dil). Telefonda saklanır.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._themeMode, this._language, this._chosen);

  /// Kaydedilmiş tercihleri okur; yoksa sistem teması ve telefonun dili.
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    return AppSettings._(
      prefs,
      mode,
      prefs.getString(_languageKey),
      prefs.getBool(_chosenKey) ?? false,
    );
  }

  /// Testler ve önizleme için saklamasız tercihler: Türkçe, dil seçilmiş.
  AppSettings.memory({
    ThemeMode themeMode = ThemeMode.system,
    String? language = 'tr',
    bool languageChosen = true,
  }) : this._(null, themeMode, language, languageChosen);

  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _chosenKey = 'language_chosen';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;
  String? _language;
  bool _chosen;

  ThemeMode get themeMode => _themeMode;

  /// Seçilen dil kodu (tr, en, ar, de); null ise telefonun dili.
  String? get language => _language;

  /// MaterialApp'e verilecek dil; null ise sistem dili kullanılır.
  Locale? get locale => _language == null ? null : Locale(_language!);

  /// İlk açılışta dil seçildi mi.
  bool get languageChosen => _chosen;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_themeKey, mode.name);
  }

  /// Dili değiştirir; null telefonun diline döner. Seçim yapılmış sayılır.
  Future<void> setLanguage(String? code) async {
    if (code == _language && _chosen) return;
    _language = code;
    _chosen = true;
    notifyListeners();
    final p = _prefs;
    if (p == null) return;
    if (code == null) {
      await p.remove(_languageKey);
    } else {
      await p.setString(_languageKey, code);
    }
    await p.setBool(_chosenKey, true);
  }
}
