import 'model.dart';

/// Hekim panelinin metinleri: Türkçe (kaynak), İngilizce, Arapça, Almanca.
///
/// Dil `?lang=` ile seçilir ve çerezde kalır; seçilmediyse tarayıcının
/// `Accept-Language` başlığı, o da yoksa Türkçe. Arapçada sayfa sağdan sola.
/// Erişim kayıtlarının açıklamaları dilden bağımsız (Türkçe) kalır.
class PanelText {
  const PanelText._({
    required this.lang,
    required this.decimal,
    required this.dateOrder,
    required this.signInTitle,
    required this.signInIntro,
    required this.tokenLabel,
    required this.signIn,
    required this.signOut,
    required this.badToken,
    required this.myPatients,
    required this.noPatients,
    required this.colPatient,
    required this.colShared,
    required this.colConsentEnd,
    required this.colLastData,
    required this.createInvite,
    required this.purpose,
    required this.requestedData,
    required this.durationDays,
    required this.createCode,
    required this.error,
    required this.formExpired,
    required this.missingInfo,
    required this.missingInfoBody,
    required this.back,
    required this.inviteCode,
    required this.inviteCodeBody,
    required this.requested,
    required this.days,
    required this.noAccess,
    required this.noAccessBody,
    required this.patient,
    required this.shared,
    required this.consentEnd,
    required this.noRecentData,
    required this.disclaimer,
    required this.last,
    required this.recordsIn7Days,
    required this.average,
    required this.colTime,
    required this.colValue,
    required this.sparkLabel,
    required this.ecgRecording,
    required this.workout,
    required this.hoursMinutes,
    required this.codeLabels,
    required this.scopeLabels,
    required this.units,
    required this.language,
  });

  final String lang;
  final String decimal;

  /// `dmy` (gün.ay.yıl) ya da `ymd`.
  final String dateOrder;

  final String signInTitle, signInIntro, tokenLabel, signIn, signOut, badToken;
  final String myPatients, noPatients;
  final String colPatient, colShared, colConsentEnd, colLastData;
  final String createInvite, purpose, requestedData, durationDays, createCode;
  final String error, formExpired, missingInfo, missingInfoBody, back;
  final String inviteCode, inviteCodeBody, requested, days;
  final String noAccess, noAccessBody;
  final String patient, shared, consentEnd, noRecentData, disclaimer;
  final String last, recordsIn7Days, average, colTime, colValue, sparkLabel;
  final String ecgRecording, workout;

  /// `{h}` ve `{m}` yer tutuculu.
  final String hoursMinutes;
  final Map<String, String> codeLabels;
  final Map<ShareScope, String> scopeLabels;
  final Map<String, String> units;

  /// Dil seçicide görünen ad.
  final String language;

  bool get rtl => lang == 'ar';

  static const supported = ['tr', 'en', 'ar', 'de'];

  static PanelText of(String lang) => switch (lang) {
    'en' => en,
    'ar' => ar,
    'de' => de,
    _ => tr,
  };

  /// `Accept-Language` başlığından desteklenen ilk dil; yoksa Türkçe.
  static String fromAcceptLanguage(String? header) {
    final ranked = <(String, double)>[];
    for (final part in (header ?? '').split(',')) {
      final pieces = part.trim().split(';');
      final tag = pieces.first.trim().toLowerCase();
      if (tag.isEmpty) continue;
      var q = 1.0;
      for (final p in pieces.skip(1)) {
        final kv = p.trim().split('=');
        if (kv.length == 2 && kv[0] == 'q') q = double.tryParse(kv[1]) ?? 0;
      }
      ranked.add((tag.split('-').first, q));
    }
    ranked.sort((a, b) => b.$2.compareTo(a.$2));
    for (final (lang, q) in ranked) {
      if (q > 0 && supported.contains(lang)) return lang;
    }
    return 'tr';
  }

  String number(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1).replaceAll('.', decimal);

  String duration(int minutes) => hoursMinutes
      .replaceAll('{h}', '${minutes ~/ 60}')
      .replaceAll('{m}', '${minutes % 60}');

  static const tr = PanelText._(
    lang: 'tr',
    decimal: ',',
    dateOrder: 'dmy',
    language: 'Türkçe',
    signInTitle: 'Bileklik hekim paneli',
    signInIntro: 'Portalın size verdiği oturum anahtarıyla giriş yapın.',
    tokenLabel: 'Oturum anahtarı',
    signIn: 'Giriş',
    signOut: 'Çıkış',
    badToken: 'Anahtar geçersiz.',
    myPatients: 'Hastalarım',
    noPatients:
        'Henüz rıza vermiş hasta yok. Aşağıdan davet kodu oluşturup hastanıza verin.',
    colPatient: 'Hasta (takma kimlik)',
    colShared: 'Paylaşılan',
    colConsentEnd: 'Rıza bitişi',
    colLastData: 'Son veri',
    createInvite: 'Davet oluştur',
    purpose: 'Amaç',
    requestedData: 'İstenen veriler',
    durationDays: 'Süre (gün)',
    createCode: 'Davet kodu oluştur',
    error: 'Hata',
    formExpired: 'Form süresi dolmuş. Sayfayı yenileyin.',
    missingInfo: 'Eksik bilgi',
    missingInfoBody:
        'Amaç, en az bir veri türü ve 1-730 gün arası süre gerekli.',
    back: 'Geri dön',
    inviteCode: 'Davet kodu',
    inviteCodeBody:
        'Bu kodu hastanıza verin. Hasta Bileklik uygulamasında Profil > Hekim ve araştırma kurumu bölümünden kodu girer, istenen verileri görür ve kendisi seçer. Kod 30 gün geçerlidir.',
    requested: 'İstenen',
    days: 'gün',
    noAccess: 'Erişim yok',
    noAccessBody: 'Bu hastanın size verdiği süren bir rıza yok.',
    patient: 'Hasta',
    shared: 'Paylaşılan',
    consentEnd: 'rıza bitişi',
    noRecentData: 'Son 7 günde paylaşılan veri yok.',
    disclaimer:
        'Değerler giyilebilir cihazdan gelir; tıbbi cihaz ölçümü değildir. Tansiyon tahminidir.',
    last: 'Son',
    recordsIn7Days: '7 günde {n} kayıt',
    average: 'ortalama',
    colTime: 'Zaman',
    colValue: 'Değer',
    sparkLabel: 'Son 7 günün günlük ortalama nabzı',
    ecgRecording: 'EKG kaydı',
    workout: 'Egzersiz',
    hoursMinutes: '{h} sa {m} dk',
    codeLabels: {
      '8867-4': 'Nabız',
      '80404-7': 'HRV (SDNN)',
      '59408-5': 'SpO2',
      '85354-9': 'Tansiyon (tahmini)',
      '11524-6': 'EKG kayıtları',
      '93832-4': 'Uyku',
      '55423-8': 'Adım',
      '55430-3': 'Mesafe',
      '41981-2': 'Kalori',
      'workout': 'Egzersiz',
      '8310-5': 'Vücut ısısı',
      'stress': 'Stres',
      '9279-1': 'Solunum hızı',
      '29463-7': 'Kilo',
      '39156-5': 'VKİ',
      '41982-0': 'Vücut yağ oranı',
      'muscle-mass': 'Kas kütlesi',
    },
    scopeLabels: {
      ShareScope.heartRate: 'Nabız ve HRV',
      ShareScope.spo2: 'SpO2',
      ShareScope.sleep: 'Uyku',
      ShareScope.activity: 'Aktivite',
      ShareScope.ecg: 'EKG',
      ShareScope.bloodPressure: 'Tansiyon (tahmini)',
      ShareScope.stress: 'Stres',
      ShareScope.temperature: 'Vücut ısısı',
      ShareScope.respiration: 'Solunum hızı',
      ShareScope.body: 'Vücut ölçüleri (kilo, VKİ)',
    },
    units: {
      'beats/minute': 'atım/dk',
      'breaths/minute': 'nefes/dk',
      'Cel': '°C',
      'min': 'dk',
      'steps': 'adım',
    },
  );

  static const en = PanelText._(
    lang: 'en',
    decimal: '.',
    dateOrder: 'ymd',
    language: 'English',
    signInTitle: 'Bileklik clinician panel',
    signInIntro: 'Sign in with the session key the portal gave you.',
    tokenLabel: 'Session key',
    signIn: 'Sign in',
    signOut: 'Sign out',
    badToken: 'Invalid key.',
    myPatients: 'My patients',
    noPatients:
        'No patient has given consent yet. Create an invitation code below and give it to your patient.',
    colPatient: 'Patient (pseudonym)',
    colShared: 'Shared',
    colConsentEnd: 'Consent ends',
    colLastData: 'Latest data',
    createInvite: 'Create invitation',
    purpose: 'Purpose',
    requestedData: 'Requested data',
    durationDays: 'Duration (days)',
    createCode: 'Create invitation code',
    error: 'Error',
    formExpired: 'The form has expired. Please reload the page.',
    missingInfo: 'Missing information',
    missingInfoBody:
        'A purpose, at least one data type and a duration of 1-730 days are required.',
    back: 'Go back',
    inviteCode: 'Invitation code',
    inviteCodeBody:
        'Give this code to your patient. In the Bileklik app they enter it under Profile > Doctor and research institution, see the requested data and choose what to share. The code is valid for 30 days.',
    requested: 'Requested',
    days: 'days',
    noAccess: 'No access',
    noAccessBody: 'This patient has no active consent for you.',
    patient: 'Patient',
    shared: 'Shared',
    consentEnd: 'consent ends',
    noRecentData: 'No shared data in the last 7 days.',
    disclaimer:
        'Values come from a wearable device and are not medical device measurements. Blood pressure is an estimate.',
    last: 'Latest',
    recordsIn7Days: '{n} records in 7 days',
    average: 'average',
    colTime: 'Time',
    colValue: 'Value',
    sparkLabel: 'Daily average heart rate over the last 7 days',
    ecgRecording: 'ECG recording',
    workout: 'Workout',
    hoursMinutes: '{h} h {m} min',
    codeLabels: {
      '8867-4': 'Heart rate',
      '80404-7': 'HRV (SDNN)',
      '59408-5': 'SpO2',
      '85354-9': 'Blood pressure (estimated)',
      '11524-6': 'ECG recordings',
      '93832-4': 'Sleep',
      '55423-8': 'Steps',
      '55430-3': 'Distance',
      '41981-2': 'Calories',
      'workout': 'Workouts',
      '8310-5': 'Body temperature',
      'stress': 'Stress',
      '9279-1': 'Respiratory rate',
      '29463-7': 'Weight',
      '39156-5': 'BMI',
      '41982-0': 'Body fat',
      'muscle-mass': 'Muscle mass',
    },
    scopeLabels: {
      ShareScope.heartRate: 'Heart rate and HRV',
      ShareScope.spo2: 'SpO2',
      ShareScope.sleep: 'Sleep',
      ShareScope.activity: 'Activity',
      ShareScope.ecg: 'ECG',
      ShareScope.bloodPressure: 'Blood pressure (estimated)',
      ShareScope.stress: 'Stress',
      ShareScope.temperature: 'Body temperature',
      ShareScope.respiration: 'Respiratory rate',
      ShareScope.body: 'Body measurements (weight, BMI)',
    },
    units: {
      'beats/minute': 'bpm',
      'breaths/minute': 'breaths/min',
      'Cel': '°C',
      'min': 'min',
      'steps': 'steps',
    },
  );

  static const ar = PanelText._(
    lang: 'ar',
    decimal: '٫',
    dateOrder: 'dmy',
    language: 'العربية',
    signInTitle: 'لوحة الأطباء في Bileklik',
    signInIntro: 'سجّل الدخول بمفتاح الجلسة الذي منحتك إياه البوابة.',
    tokenLabel: 'مفتاح الجلسة',
    signIn: 'تسجيل الدخول',
    signOut: 'تسجيل الخروج',
    badToken: 'المفتاح غير صالح.',
    myPatients: 'مرضاي',
    noPatients:
        'لم يمنح أي مريض موافقته بعد. أنشئ رمز دعوة أدناه وأعطه لمريضك.',
    colPatient: 'المريض (اسم مستعار)',
    colShared: 'المُشارَك',
    colConsentEnd: 'انتهاء الموافقة',
    colLastData: 'آخر بيانات',
    createInvite: 'إنشاء دعوة',
    purpose: 'الغرض',
    requestedData: 'البيانات المطلوبة',
    durationDays: 'المدة (أيام)',
    createCode: 'إنشاء رمز الدعوة',
    error: 'خطأ',
    formExpired: 'انتهت صلاحية النموذج. أعد تحميل الصفحة.',
    missingInfo: 'معلومات ناقصة',
    missingInfoBody:
        'يلزم غرض ونوع بيانات واحد على الأقل ومدة من 1 إلى 730 يومًا.',
    back: 'رجوع',
    inviteCode: 'رمز الدعوة',
    inviteCodeBody:
        'أعطِ هذا الرمز لمريضك. يدخله المريض في تطبيق Bileklik من الملف الشخصي > الطبيب ومؤسسة البحث، ويرى البيانات المطلوبة ويختار ما يشاركه. الرمز صالح لمدة 30 يومًا.',
    requested: 'المطلوب',
    days: 'يومًا',
    noAccess: 'لا يوجد وصول',
    noAccessBody: 'لا توجد موافقة سارية من هذا المريض لك.',
    patient: 'المريض',
    shared: 'المُشارَك',
    consentEnd: 'انتهاء الموافقة',
    noRecentData: 'لا توجد بيانات مُشارَكة في آخر 7 أيام.',
    disclaimer:
        'القيم مصدرها جهاز قابل للارتداء وليست قياسات جهاز طبي. ضغط الدم تقديري.',
    last: 'الأخير',
    recordsIn7Days: '{n} سجلًا في 7 أيام',
    average: 'المتوسط',
    colTime: 'الوقت',
    colValue: 'القيمة',
    sparkLabel: 'متوسط نبض القلب اليومي في آخر 7 أيام',
    ecgRecording: 'تسجيل تخطيط القلب',
    workout: 'تمرين',
    hoursMinutes: '{h} س {m} د',
    codeLabels: {
      '8867-4': 'نبض القلب',
      '80404-7': 'تقلب نبض القلب (SDNN)',
      '59408-5': 'SpO2',
      '85354-9': 'ضغط الدم (تقديري)',
      '11524-6': 'تسجيلات تخطيط القلب',
      '93832-4': 'النوم',
      '55423-8': 'الخطوات',
      '55430-3': 'المسافة',
      '41981-2': 'السعرات',
      'workout': 'التمارين',
      '8310-5': 'حرارة الجسم',
      'stress': 'التوتر',
      '9279-1': 'معدل التنفس',
      '29463-7': 'الوزن',
      '39156-5': 'مؤشر كتلة الجسم',
      '41982-0': 'نسبة الدهون',
      'muscle-mass': 'الكتلة العضلية',
    },
    scopeLabels: {
      ShareScope.heartRate: 'نبض القلب وتقلبه',
      ShareScope.spo2: 'SpO2',
      ShareScope.sleep: 'النوم',
      ShareScope.activity: 'النشاط',
      ShareScope.ecg: 'تخطيط القلب',
      ShareScope.bloodPressure: 'ضغط الدم (تقديري)',
      ShareScope.stress: 'التوتر',
      ShareScope.temperature: 'حرارة الجسم',
      ShareScope.respiration: 'معدل التنفس',
      ShareScope.body: 'قياسات الجسم (الوزن، مؤشر الكتلة)',
    },
    units: {
      'beats/minute': 'نبضة/د',
      'breaths/minute': 'نفس/د',
      'Cel': '°C',
      'min': 'د',
      'steps': 'خطوة',
    },
  );

  static const de = PanelText._(
    lang: 'de',
    decimal: ',',
    dateOrder: 'dmy',
    language: 'Deutsch',
    signInTitle: 'Bileklik-Ärztepanel',
    signInIntro:
        'Melden Sie sich mit dem Sitzungsschlüssel an, den Ihnen das Portal gegeben hat.',
    tokenLabel: 'Sitzungsschlüssel',
    signIn: 'Anmelden',
    signOut: 'Abmelden',
    badToken: 'Ungültiger Schlüssel.',
    myPatients: 'Meine Patienten',
    noPatients:
        'Noch keine Einwilligung. Erstellen Sie unten einen Einladungscode und geben Sie ihn Ihrem Patienten.',
    colPatient: 'Patient (Pseudonym)',
    colShared: 'Geteilt',
    colConsentEnd: 'Einwilligung bis',
    colLastData: 'Letzte Daten',
    createInvite: 'Einladung erstellen',
    purpose: 'Zweck',
    requestedData: 'Angefragte Daten',
    durationDays: 'Dauer (Tage)',
    createCode: 'Einladungscode erstellen',
    error: 'Fehler',
    formExpired: 'Das Formular ist abgelaufen. Bitte laden Sie die Seite neu.',
    missingInfo: 'Fehlende Angaben',
    missingInfoBody:
        'Erforderlich sind ein Zweck, mindestens ein Datentyp und eine Dauer von 1-730 Tagen.',
    back: 'Zurück',
    inviteCode: 'Einladungscode',
    inviteCodeBody:
        'Geben Sie diesen Code Ihrem Patienten. In der Bileklik-App gibt er ihn unter Profil > Arzt und Forschungseinrichtung ein, sieht die angefragten Daten und wählt selbst aus. Der Code ist 30 Tage gültig.',
    requested: 'Angefragt',
    days: 'Tage',
    noAccess: 'Kein Zugriff',
    noAccessBody:
        'Dieser Patient hat Ihnen keine laufende Einwilligung erteilt.',
    patient: 'Patient',
    shared: 'Geteilt',
    consentEnd: 'Einwilligung bis',
    noRecentData: 'Keine geteilten Daten in den letzten 7 Tagen.',
    disclaimer:
        'Die Werte stammen von einem Wearable und sind keine Messungen eines Medizinprodukts. Der Blutdruck ist geschätzt.',
    last: 'Zuletzt',
    recordsIn7Days: '{n} Einträge in 7 Tagen',
    average: 'Durchschnitt',
    colTime: 'Zeit',
    colValue: 'Wert',
    sparkLabel: 'Tägliche durchschnittliche Herzfrequenz der letzten 7 Tage',
    ecgRecording: 'EKG-Aufzeichnung',
    workout: 'Training',
    hoursMinutes: '{h} Std. {m} Min.',
    codeLabels: {
      '8867-4': 'Herzfrequenz',
      '80404-7': 'HRV (SDNN)',
      '59408-5': 'SpO2',
      '85354-9': 'Blutdruck (geschätzt)',
      '11524-6': 'EKG-Aufzeichnungen',
      '93832-4': 'Schlaf',
      '55423-8': 'Schritte',
      '55430-3': 'Strecke',
      '41981-2': 'Kalorien',
      'workout': 'Training',
      '8310-5': 'Körpertemperatur',
      'stress': 'Stress',
      '9279-1': 'Atemfrequenz',
      '29463-7': 'Gewicht',
      '39156-5': 'BMI',
      '41982-0': 'Körperfett',
      'muscle-mass': 'Muskelmasse',
    },
    scopeLabels: {
      ShareScope.heartRate: 'Herzfrequenz und HRV',
      ShareScope.spo2: 'SpO2',
      ShareScope.sleep: 'Schlaf',
      ShareScope.activity: 'Aktivität',
      ShareScope.ecg: 'EKG',
      ShareScope.bloodPressure: 'Blutdruck (geschätzt)',
      ShareScope.stress: 'Stress',
      ShareScope.temperature: 'Körpertemperatur',
      ShareScope.respiration: 'Atemfrequenz',
      ShareScope.body: 'Körpermaße (Gewicht, BMI)',
    },
    units: {
      'beats/minute': 'Schläge/min',
      'breaths/minute': 'Atemzüge/min',
      'Cel': '°C',
      'min': 'min',
      'steps': 'Schritte',
    },
  );
}
