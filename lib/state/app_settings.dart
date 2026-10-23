import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/portal.dart';
import '../data/secrets.dart';

/// Saat gösterimi: telefonun/dilin alışkanlığı, 24 saat ya da 12 saat (ÖÖ/ÖS).
enum ClockFormat { system, h24, h12 }

/// Ölçü birimleri: metrik (km, °C) ya da ABD (mil, °F).
enum UnitSystem { metric, imperial }

/// Kullanıcının uygulama tercihleri (dil, saat biçimi, birimler, takma
/// algılaması). Telefonda saklanır.
///
/// Uygulama yalnızca koyu Cam temasında çalışır. Eski sürümlerin kaydettiği
/// `theme_mode` değeri okunmaz; olduğu yerde kalması bir şeyi bozmaz.
class AppSettings extends ChangeNotifier implements PortalCredentials {
  AppSettings._(
    this._prefs,
    this._secrets,
    this._language,
    this._chosen, {
    this._clock = ClockFormat.system,
    this._units = UnitSystem.metric,
    this._wearDetection = true,
    this._heightCm,
    this._patientId,
    this._portalToken,
    this._lastPortalUpload,
    String? recoveryCode,
  }) : _recoveryCode = recoveryCode;

  /// Kaydedilmiş tercihleri okur; yoksa telefonun dili.
  ///
  /// Portal oturum anahtarı [secrets] içinde durur. Eski sürümlerin düz
  /// tercihlere yazdığı anahtar oraya taşınır ve tercihlerden silinir.
  static Future<AppSettings> load({SecretStore? secrets}) async {
    final prefs = await SharedPreferences.getInstance();
    final s = secrets ?? MemorySecretStore();
    var token = await s.read(_portalTokenKey);
    final recovery = await s.read(_recoveryKey);
    final legacyToken = prefs.getString(_portalTokenKey);
    if (legacyToken != null) {
      token ??= legacyToken;
      await s.write(_portalTokenKey, token);
      await prefs.remove(_portalTokenKey);
    }
    return AppSettings._(
      prefs,
      s,
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
      portalToken: token,
      recoveryCode: recovery,
      lastPortalUpload: switch (prefs.getInt(_portalUploadKey)) {
        null => null,
        final ms => DateTime.fromMillisecondsSinceEpoch(ms),
      },
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
  static const _portalTokenKey = 'portal_token';
  static const _recoveryKey = 'portal_recovery_code';
  static const _portalUploadKey = 'portal_last_upload';
  static const _communityReadKey = 'community_read_until';

  final SharedPreferences? _prefs;
  final SecretStore? _secrets;
  String? _recoveryCode;
  String? _language;
  bool _chosen;
  ClockFormat _clock;
  UnitSystem _units;
  bool _wearDetection;
  int? _heightCm;
  String? _patientId;
  String? _portalToken;
  DateTime? _lastPortalUpload;

  /// Portalın verdiği oturum anahtarı; hesap açılınca saklanır.
  @override
  String? get portalToken => _portalToken;

  @override
  Future<void> setPortalToken(String? token) async {
    _portalToken = token;
    await _secrets?.write(_portalTokenKey, token);
  }

  /// Portal hesabının kurtarma kodu; kullanıcı görsün ve yazsın diye
  /// güvenli depoda tutulur.
  @override
  String? get recoveryCode => _recoveryCode;

  @override
  Future<void> setRecoveryCode(String? code) async {
    _recoveryCode = code;
    await _secrets?.write(_recoveryKey, code);
    notifyListeners();
  }

  /// Kurtarılan hesabın kimliği bu telefona geçer.
  @override
  Future<void> setPatientId(String id) async {
    _patientId = id;
    await _prefs?.setString(_patientIdKey, id);
    notifyListeners();
  }

  @override
  DateTime? get communityReadUntil {
    final ms = _prefs?.getInt(_communityReadKey) ?? _communityRead;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  int? _communityRead;

  @override
  Future<void> setCommunityReadUntil(DateTime t) async {
    _communityRead = t.millisecondsSinceEpoch;
    await _prefs?.setInt(_communityReadKey, t.millisecondsSinceEpoch);
  }

  /// Portala son başarılı yüklemenin anı.
  @override
  DateTime? get lastPortalUpload => _lastPortalUpload;

  @override
  Future<void> setLastPortalUpload(DateTime t) async {
    _lastPortalUpload = t;
    await _prefs?.setInt(_portalUploadKey, t.millisecondsSinceEpoch);
  }

  /// FHIR dışa aktarımındaki takma hasta kimliği (UUID). Kişisel bilgi
  /// taşımaz; ilk istendiğinde üretilir ve telefonda saklanır, böylece aynı
  /// kişinin dosyaları portalda birleşebilir.
  @override
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
