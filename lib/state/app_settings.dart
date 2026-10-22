import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saat gösterimi: telefonun/dilin alışkanlığı, 24 saat ya da 12 saat (ÖÖ/ÖS).
enum ClockFormat { system, h24, h12 }

/// Ölçü birimleri: metrik (km, °C) ya da ABD (mil, °F).
enum UnitSystem { metric, imperial }

/// Kullanıcının uygulama tercihleri (dil, saat biçimi, birimler, takma
/// algılaması). Telefonda saklanır.
///
/// Uygulama yalnızca koyu Cam temasında çalışır. Eski sürümlerin kaydettiği
/// `theme_mode` değeri okunmaz; olduğu yerde kalması bir şeyi bozmaz.
class AppSettings extends ChangeNotifier {
  AppSettings._(
    this._prefs,
    this._language,
    this._chosen, {
    this._clock = ClockFormat.system,
    this._units = UnitSystem.metric,
    this._wearDetection = true,
    this._heightCm,
    this._patientId,
  });

  /// Kaydedilmiş tercihleri okur; yoksa telefonun dili.
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      prefs,
      prefs.getString(_languageKey),
      prefs.getBool(_chosenKey) ?? false,
      clock:
          _byName(ClockFormat.values, prefs.getString(_clockKey)) ??
          ClockFormat.system,
      units:
          _byName(UnitSystem.values, prefs.getString(_unitsKey)) ??
          UnitSystem.metric,
      wearDetection: prefs.getBool(_wearKey) ?? true,
      heightCm: prefs.getInt(_heightKey),
      patientId: prefs.getString(_patientIdKey),
    );
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  /// Testler ve önizleme için saklamasız tercihler: Türkçe, dil seçilmiş.
  AppSettings.memory({
    String? language = 'tr',
    bool languageChosen = true,
    ClockFormat clock = ClockFormat.system,
    UnitSystem units = UnitSystem.metric,
    int? heightCm,
  }) : this._(
         null,
         language,
         languageChosen,
         clock: clock,
         units: units,
         heightCm: heightCm,
       );

  static const _languageKey = 'language';
  static const _chosenKey = 'language_chosen';
  static const _clockKey = 'clock_format';
  static const _unitsKey = 'unit_system';
  static const _wearKey = 'wear_detection';
  static const _heightKey = 'height_cm';
  static const _patientIdKey = 'fhir_patient_id';

  final SharedPreferences? _prefs;
  String? _language;
  bool _chosen;
  ClockFormat _clock;
  UnitSystem _units;
  bool _wearDetection;
  int? _heightCm;
  String? _patientId;

  /// FHIR dışa aktarımındaki takma hasta kimliği (UUID). Kişisel bilgi
  /// taşımaz; ilk istendiğinde üretilir ve telefonda saklanır, böylece aynı
  /// kişinin dosyaları portalda birleşebilir.
  String get patientId {
    final existing = _patientId;
    if (existing != null) return existing;
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0F) | 0x40;
    b[8] = (b[8] & 0x3F) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
    _patientId = id;
    _prefs?.setString(_patientIdKey, id);
    return id;
  }

  /// Boy (cm); VKİ hesabı için. Bileklik bağlı değilken de bilinsin diye
  /// telefonda saklanır.
  int? get heightCm => _heightCm;

  Future<void> setHeight(int cm) async {
    if (cm == _heightCm) return;
    _heightCm = cm;
    notifyListeners();
    await _prefs?.setInt(_heightKey, cm);
  }

  ClockFormat get clock => _clock;
  UnitSystem get units => _units;

  /// Takma algılaması açık mı; bileklik her bağlantıda bu değeri alır.
  bool get wearDetection => _wearDetection;

  Future<void> setClock(ClockFormat v) async {
    if (v == _clock) return;
    _clock = v;
    notifyListeners();
    await _prefs?.setString(_clockKey, v.name);
  }

  Future<void> setUnits(UnitSystem v) async {
    if (v == _units) return;
    _units = v;
    notifyListeners();
    await _prefs?.setString(_unitsKey, v.name);
  }

  Future<void> setWearDetection(bool v) async {
    if (v == _wearDetection) return;
    _wearDetection = v;
    notifyListeners();
    await _prefs?.setBool(_wearKey, v);
  }

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
