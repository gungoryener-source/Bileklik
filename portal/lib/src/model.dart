/// Portalın alan modeli: hesaplar, rızalar (Consent), davetler ve erişim
/// kayıtları.
library;

/// Portal hesabının FHIR `Identifier`'ı.
Map<String, String> accountIdentifier(String id) => {
  'system': 'https://bileklik.app/portal/account',
  'value': id,
};

/// Hesap türleri. Hasta verinin sahibidir; diğerleri yalnızca rızayla görür.
enum Role { patient, clinician, researcher, family }

/// Paylaşılabilen veri türleri. Uygulamadaki `ShareScope` ile aynı adlar.
enum ShareScope {
  heartRate,
  spo2,
  sleep,
  activity,
  ecg,
  bloodPressure,
  stress,
  temperature,

  /// Solunum hızı (bilekten tahmin).
  respiration,

  /// Elle girilen vücut ölçüleri: kilo, VKİ, yağ oranı, kas kütlesi. Hasta
  /// ayrıca açmadıkça paylaşılmaz.
  body;

  static ShareScope? byName(String name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// Bu türün kapsadığı Observation kodları (uygulamanın `FhirExporter`
  /// ile ürettiği LOINC ve yerel kodlar). Kilo, VKİ gibi elle girilenler
  /// yalnızca [body] türünde; hasta bunu ayrıca seçmedikçe gösterilmez.
  Set<String> get codes => switch (this) {
    // HRV nabız verisiyle birlikte paylaşılır.
    ShareScope.heartRate => const {'8867-4', '80404-7'},
    ShareScope.spo2 => const {'59408-5'},
    ShareScope.sleep => const {'93832-4'},
    ShareScope.activity => const {'55423-8', '55430-3', '41981-2', 'workout'},
    ShareScope.ecg => const {'11524-6'},
    ShareScope.bloodPressure => const {'85354-9'},
    ShareScope.stress => const {'stress'},
    ShareScope.temperature => const {'8310-5'},
    ShareScope.respiration => const {'9279-1'},
    ShareScope.body => const {'29463-7', '39156-5', '41982-0', 'muscle-mass'},
  };
}

class Account {
  const Account({
    required this.id,
    required this.role,
    required this.name,
    this.organization,
    this.email,
    this.specialty,
    this.licenseNo,
    this.verified = true,
  });

  /// Hastada uygulamanın takma kimliği (FHIR Patient id); diğerlerinde
  /// portalın verdiği kimlik.
  final String id;
  final Role role;

  /// Hekimin adı, çalışmanın adı ya da aile üyesinin görünen adı. Hastanın
  /// adı tutulmaz.
  final String name;

  /// Hastane, klinik ya da kurum.
  final String? organization;

  /// Panelde e-posta ve şifreyle giriş yapan hekimin e-postası (küçük harf).
  final String? email;

  /// Uzmanlık ya da unvan (ör. "Kardiyoloji uzmanı").
  final String? specialty;

  /// Diploma tescil ya da sicil numarası; doğrulamada kullanılır.
  final String? licenseNo;

  /// Kendi kaydolan hekim, portal yöneticisi kimliğini doğrulayana kadar
  /// false. Hasta davet ekranında bunu görür. Yöneticinin açtığı hesaplar
  /// doğrulanmış sayılır.
  final bool verified;

  Account copyWith({bool? verified}) => Account(
    id: id,
    role: role,
    name: name,
    organization: organization,
    email: email,
    specialty: specialty,
    licenseNo: licenseNo,
    verified: verified ?? this.verified,
  );
}

enum Sex { female, male, other }

/// Hekimin kendi tuttuğu hasta kaydı (dosya). Gerçek ad ve doğum tarihi
/// gibi kimlik bilgileri yalnızca burada, yalnızca kaydı açan hekime
/// görünür; bileklik verisi ise takma kimlikle gelir.
///
/// Kayıt, hastanın rıza verdiği bir bileklik kullanıcısına [patientId] ile
/// bağlanır. Bağ, hekimin bu kayıt için ürettiği davet kodunun ([inviteCode])
/// hasta tarafından kabul edilmesiyle ya da hekimin rızası süren bir
/// bağlantıyı kayda elle bağlamasıyla kurulur. Kayıt bağlansa da veri
/// yalnızca süren rızadaki türlerle görülür.
class PatientRecord {
  const PatientRecord({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.created,
    this.birthDate,
    this.sex,
    this.fileNo,
    this.phone,
    this.notes,
    this.patientId,
    this.inviteCode,
  });

  final String id;

  /// Kaydı açan hekim.
  final String ownerId;
  final String name;
  final DateTime created;
  final DateTime? birthDate;
  final Sex? sex;

  /// Hastane dosya ya da protokol numarası.
  final String? fileNo;
  final String? phone;
  final String? notes;

  /// Bağlı bileklik kullanıcısının takma kimliği.
  final String? patientId;

  /// Bu kayıt için üretilen son davet kodu.
  final String? inviteCode;

  /// [now] anındaki tam yaş.
  int? ageAt(DateTime now) {
    final b = birthDate;
    if (b == null) return null;
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  PatientRecord copyWith({
    String? name,
    DateTime? birthDate,
    Sex? sex,
    String? fileNo,
    String? phone,
    String? notes,
    String? patientId,
    String? inviteCode,
    bool clearBirthDate = false,
    bool clearSex = false,
    bool clearPatient = false,
    bool clearInvite = false,
  }) => PatientRecord(
    id: id,
    ownerId: ownerId,
    created: created,
    name: name ?? this.name,
    birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
    sex: clearSex ? null : sex ?? this.sex,
    fileNo: fileNo ?? this.fileNo,
    phone: phone ?? this.phone,
    notes: notes ?? this.notes,
    patientId: clearPatient ? null : patientId ?? this.patientId,
    inviteCode: clearInvite ? null : inviteCode ?? this.inviteCode,
  );
}

/// Hastanın bir takipçiye verdiği açık rıza (FHIR R4 Consent).
class Consent {
  Consent({
    required this.id,
    required this.patientId,
    required this.actorId,
    required this.scopes,
    required this.start,
    required this.end,
    this.purpose,
    this.inviteCode,
    Set<ShareScope>? requested,
  }) : requested = requested ?? scopes;

  final String id;
  final String patientId;
  final String actorId;
  final Set<ShareScope> scopes;
  final DateTime start;
  final DateTime end;
  final String? purpose;

  /// Rızanın verildiği davet kodu.
  final String? inviteCode;

  /// Davette istenen türler (hasta bunlardan seçti).
  final Set<ShareScope> requested;
  DateTime? revokedAt;

  bool activeAt(DateTime now) =>
      revokedAt == null && !now.isBefore(start) && now.isBefore(end);

  Set<String> get codes => {for (final s in scopes) ...s.codes};

  Map<String, Object?> toFhir(DateTime now) => {
    'resourceType': 'Consent',
    'id': id,
    'status': activeAt(now) ? 'active' : 'inactive',
    'scope': {
      'coding': [
        {
          'system': 'http://terminology.hl7.org/CodeSystem/consentscope',
          'code': 'patient-privacy',
        },
      ],
    },
    'category': [
      {
        'coding': [
          {'system': 'http://loinc.org', 'code': '59284-0'},
        ],
      },
    ],
    'patient': {'reference': 'Patient/$patientId'},
    'dateTime': start.toUtc().toIso8601String(),
    'provision': {
      'type': 'permit',
      'period': {
        'start': start.toUtc().toIso8601String(),
        'end': (revokedAt ?? end).toUtc().toIso8601String(),
      },
      'actor': [
        {
          'role': {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/v3-ParticipationType',
                'code': 'IRCP',
              },
            ],
          },
          // Takipçi hekim, araştırmacı ya da aile üyesi olabilir; tür
          // yerine portal hesabının kimliği yazılır.
          'reference': {'identifier': accountIdentifier(actorId)},
        },
      ],
      if (purpose != null)
        'purpose': [
          {'display': purpose},
        ],
      'class': [
        for (final s in scopes)
          {
            'system': 'https://bileklik.app/fhir/CodeSystem/share-scope',
            'code': s.name,
          },
      ],
    },
  };
}

/// Hekim ya da araştırma kurumunun oluşturduğu davet. Hasta kodu girince
/// uygulama bunu açık rıza ekranında gösterir.
class Invite {
  const Invite({
    required this.code,
    required this.actorId,
    required this.purpose,
    required this.requested,
    required this.duration,
    required this.expires,
  });

  final String code;
  final String actorId;
  final String purpose;
  final Set<ShareScope> requested;

  /// Kabul edilince rızanın süresi.
  final Duration duration;

  /// Kodun kullanılabileceği son an.
  final DateTime expires;
}

/// Ayrıştırılmış ve saklanan bir Observation.
class StoredObservation {
  const StoredObservation({
    required this.patientId,
    required this.identifier,
    required this.code,
    required this.effective,
    required this.resource,
  });

  final String patientId;

  /// `system|value`; aynı kayıt ikinci kez gelirse tanınır.
  final String identifier;

  /// İlk kodlamanın kodu (LOINC ya da yerel).
  final String code;
  final DateTime effective;
  final Map<String, Object?> resource;
}

/// KVKK için erişim kaydı. Hasta, verisine kimin ne zaman eriştiğini görür.
enum AuditAction {
  /// Veri yüklendi.
  create('C'),

  /// Veri okundu.
  read('R'),

  /// Rıza verildi ya da geri alındı.
  update('U'),

  /// Veri silindi (unutulma hakkı).
  delete('D');

  const AuditAction(this.code);
  final String code;
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.time,
    required this.actorId,
    required this.patientId,
    required this.action,
    required this.success,
    required this.description,
  });

  final String id;
  final DateTime time;
  final String actorId;
  final String patientId;
  final AuditAction action;
  final bool success;
  final String description;

  /// FHIR R4 AuditEvent.
  Map<String, Object?> toFhir() => {
    'resourceType': 'AuditEvent',
    'id': id,
    'type': {
      'system': 'http://terminology.hl7.org/CodeSystem/audit-event-type',
      'code': 'rest',
    },
    'action': action.code,
    'recorded': time.toUtc().toIso8601String(),
    // 0 başarılı, 4 küçük hata (ör. yetkisiz erişim denemesi).
    'outcome': success ? '0' : '4',
    'outcomeDesc': description,
    'agent': [
      {
        'who': {'identifier': accountIdentifier(actorId)},
        'requestor': true,
      },
    ],
    'source': {
      'observer': {'display': 'bileklik-portal'},
    },
    'entity': [
      {
        'what': {'reference': 'Patient/$patientId'},
      },
    ],
  };
}

/// Uygulama içi geri bildirimin türü.
enum FeedbackCategory { bug, idea, other }

/// Uygulamadan gelen geri bildirim. Kimseye bağlanmaz: hasta kimliği ya da
/// sağlık verisi tutulmaz; yalnızca isteğe bağlı sürüm ve platform bilgisi.
class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.time,
    required this.category,
    required this.message,
    this.appVersion,
    this.platform,
    this.locale,
  });

  final String id;
  final DateTime time;
  final FeedbackCategory category;
  final String message;
  final String? appVersion;
  final String? platform;
  final String? locale;

  Map<String, Object?> toJson() => {
    'id': id,
    'time': time.toUtc().toIso8601String(),
    'category': category.name,
    'message': message,
    'appVersion': appVersion,
    'platform': platform,
    'locale': locale,
  };
}

/// Aile ya da bakım grubu. Üyeler hastadır (takma kimlikli hesaplar); her
/// üye grupla neyi paylaşacağını kendisi seçer ([GroupMember.scopes]).
class CareGroupRecord {
  const CareGroupRecord({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.code,
    required this.created,
  });

  final String id;
  final String name;
  final String ownerId;

  /// Herkese açık grup kodu (6 karakter); bununla katılan üyenin adı boştur.
  final String code;
  final DateTime created;
}

/// Grup üyeliği. Davet edilip henüz katılmamış üyede [accountId] yoktur ve
/// kişiye özel [inviteCode] vardır; katılınca kod silinir.
class GroupMember {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.name,
    this.accountId,
    this.inviteCode,
    this.joined,
    this.scopes = const {},
    this.consentAt,
  });

  final String id;
  final String groupId;

  /// Grup sahibinin verdiği görünen ad (ör. "Annem"); boş olabilir.
  final String name;
  final String? accountId;
  final String? inviteCode;
  final DateTime? joined;

  /// Bu üyenin grupla paylaştığı türler (açık rıza). Varsayılan boş.
  final Set<ShareScope> scopes;
  final DateTime? consentAt;

  bool get pending => accountId == null;

  GroupMember copyWith({
    String? accountId,
    DateTime? joined,
    Set<ShareScope>? scopes,
    DateTime? consentAt,
    bool clearInvite = false,
  }) => GroupMember(
    id: id,
    groupId: groupId,
    name: name,
    accountId: accountId ?? this.accountId,
    inviteCode: clearInvite ? null : inviteCode,
    joined: joined ?? this.joined,
    scopes: scopes ?? this.scopes,
    consentAt: consentAt ?? this.consentAt,
  );
}

/// Hekim panelindeki uyarı türleri ([AlertEngine] üretir).
enum AlertKind {
  /// SpO2 en az 10 dakika %90'ın altında.
  spo2Low(AlertSeverity.critical),

  /// Nabız en az 10 dakika 120'nin üstünde (egzersiz dışında).
  heartRateHigh(AlertSeverity.critical),

  /// Nabız en az 10 dakika 40'ın altında.
  heartRateLow(AlertSeverity.critical),

  /// Tansiyon 180/120 ve üstü (tahmini değer).
  bloodPressureCrisis(AlertSeverity.critical),

  /// Vücut ısısı 38 °C ve üstü.
  fever(AlertSeverity.warning),

  /// 24 saattir veri gelmiyor (bileklik takılmamış ya da senkron yok).
  noData(AlertSeverity.warning);

  const AlertKind(this.severity);

  final AlertSeverity severity;
}

enum AlertSeverity { critical, warning }

/// Bir hekime düşen uyarı. Hekim "Gördüm" deyip not yazınca kapanır; veri
/// gelmeme uyarısı veri gelince kendiliğinden kapanır. Kapanan uyarı
/// silinmez: kim, ne zaman, ne yaptı kaydı olarak kalır.
class Alert {
  const Alert({
    required this.id,
    required this.ownerId,
    required this.patientId,
    required this.kind,
    required this.start,
    required this.lastSeen,
    required this.created,
    this.value,
    this.value2,
    this.ackAt,
    this.ackBy,
    this.note,
    this.resolvedAt,
  });

  final String id;

  /// Uyarının gittiği hekim.
  final String ownerId;
  final String patientId;
  final AlertKind kind;

  /// Olayın ilk ölçümü; veri gelmemede son verinin zamanı.
  final DateTime start;

  /// Olayın bilinen son ölçümü.
  final DateTime lastSeen;

  /// Uyarının portala düştüğü an; yanıt süresi buradan ölçülür.
  final DateTime created;

  /// En kötü değer (en düşük SpO2, en yüksek nabız, sistolik…).
  final double? value;

  /// Tansiyonda diyastolik.
  final double? value2;

  final DateTime? ackAt;
  final String? ackBy;
  final String? note;

  /// Kendiliğinden kapandı (veri yeniden gelmeye başladı).
  final DateTime? resolvedAt;

  bool get open => ackAt == null && resolvedAt == null;

  Alert copyWith({
    DateTime? lastSeen,
    double? value,
    double? value2,
    DateTime? ackAt,
    String? ackBy,
    String? note,
    DateTime? resolvedAt,
  }) => Alert(
    id: id,
    ownerId: ownerId,
    patientId: patientId,
    kind: kind,
    start: start,
    lastSeen: lastSeen ?? this.lastSeen,
    created: created,
    value: value ?? this.value,
    value2: value2 ?? this.value2,
    ackAt: ackAt ?? this.ackAt,
    ackBy: ackBy ?? this.ackBy,
    note: note ?? this.note,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'patientId': patientId,
    'kind': kind.name,
    'start': start.toUtc().toIso8601String(),
    'lastSeen': lastSeen.toUtc().toIso8601String(),
    'created': created.toUtc().toIso8601String(),
    'value': value,
    'value2': value2,
    'ackAt': ackAt?.toUtc().toIso8601String(),
    'ackBy': ackBy,
    'note': note,
    'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
  };

  static Alert fromJson(Map<String, Object?> j) {
    DateTime? t(Object? v) => v is String ? DateTime.parse(v) : null;
    return Alert(
      id: j['id']! as String,
      ownerId: j['ownerId']! as String,
      patientId: j['patientId']! as String,
      kind: AlertKind.values.byName(j['kind']! as String),
      start: t(j['start'])!,
      lastSeen: t(j['lastSeen'])!,
      created: t(j['created'])!,
      value: (j['value'] as num?)?.toDouble(),
      value2: (j['value2'] as num?)?.toDouble(),
      ackAt: t(j['ackAt']),
      ackBy: j['ackBy'] as String?,
      note: j['note'] as String?,
      resolvedAt: t(j['resolvedAt']),
    );
  }
}

/// Tanıtım sitesindeki iş birliği formunda başvuranın türü.
enum InquiryKind { distributor, oem, corporate, clinic, other }

/// Siteden gelen iş birliği başvurusu (B2B). Sağlık verisi değildir ve
/// hiçbir hesaba bağlanmaz; yalnızca başvurana dönmek için saklanır.
class Inquiry {
  const Inquiry({
    required this.id,
    required this.time,
    required this.kind,
    required this.name,
    required this.company,
    required this.email,
    required this.message,
    this.country,
    this.phone,
  });

  final String id;
  final DateTime time;
  final InquiryKind kind;
  final String name;
  final String company;
  final String email;
  final String message;
  final String? country;
  final String? phone;

  Map<String, Object?> toJson() => {
    'id': id,
    'time': time.toUtc().toIso8601String(),
    'kind': kind.name,
    'name': name,
    'company': company,
    'email': email,
    'message': message,
    'country': country,
    'phone': phone,
  };

  factory Inquiry.fromJson(Map<String, Object?> j) => Inquiry(
    id: j['id']! as String,
    time: DateTime.parse(j['time']! as String),
    kind: InquiryKind.values.byName(j['kind']! as String),
    name: j['name']! as String,
    company: j['company']! as String,
    email: j['email']! as String,
    message: j['message']! as String,
    country: j['country'] as String?,
    phone: j['phone'] as String?,
  );
}
