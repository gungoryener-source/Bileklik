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
  temperature;

  static ShareScope? byName(String name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// Bu türün kapsadığı Observation kodları (uygulamanın `FhirExporter`
  /// ile ürettiği LOINC ve yerel kodlar). Kilo, VKİ gibi elle girilenler
  /// hiçbir türde yok; takipçilere hiç gösterilmez.
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
  };
}

class Account {
  const Account({
    required this.id,
    required this.role,
    required this.name,
    this.organization,
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
