import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının uygulama tercihleri (dil). Telefonda saklanır.
///
/// Uygulama yalnızca koyu Cam temasında çalışır. Eski sürümlerin kaydettiği
/// `theme_mode` değeri okunmaz; olduğu yerde kalması bir şeyi bozmaz.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._language, this._chosen);

  /// Kaydedilmiş tercihleri okur; yoksa telefonun dili.
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      prefs,
      prefs.getString(_languageKey),
      prefs.getBool(_chosenKey) ?? false,
    );
  }

  /// Testler ve önizleme için saklamasız tercihler: Türkçe, dil seçilmiş.
  AppSettings.memory({String? language = 'tr', bool languageChosen = true})
    : this._(null, language, languageChosen);

  static const _languageKey = 'language';
  static const _chosenKey = 'language_chosen';

  final SharedPreferences? _prefs;
  String? _language;
  bool _chosen;

  /// Seçilen dil kodu (tr, en, ar, de); null ise telefonun dili.
  String? get language => _language;

  /// MaterialApp'e verilecek dil; null ise sistem dili kullanılır.
  Locale? get locale => _language == null ? null : Locale(_language!);

  /// İlk açılışta dil seçildi mi.
  bool get languageChosen => _chosen;

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
