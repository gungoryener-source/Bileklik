import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının uygulama tercihleri (şimdilik tema). Telefonda saklanır.
///
/// Dil seçimi de buraya eklenecek (ROADMAP 7).
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._themeMode);

  /// Kaydedilmiş tercihleri okur; yoksa sistem teması kullanılır.
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    return AppSettings._(prefs, mode);
  }

  /// Testler ve önizleme için saklamasız tercihler.
  AppSettings.memory([this._themeMode = ThemeMode.system]) : _prefs = null;

  static const _themeKey = 'theme_mode';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_themeKey, mode.name);
  }
}
