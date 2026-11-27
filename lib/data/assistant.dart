import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'day_summary.dart';
import 'ecg_analysis.dart';
import 'health_store.dart';
import 'insights.dart';
import 'portal.dart';
import 'recovery.dart';
import 'sleep_analysis.dart';
import 'strain.dart';

// ---------------------------------------------------------------------------
// Sağlık asistanı (Vita)
//
// Telefonda çevrimdışı çalışan kurallı yanıtlar her zaman vardır. Portal
// adresi verilmiş, sunucuda ANTHROPIC_API_KEY tanımlı ve kullanıcı yapay
// zeka rızası vermişse soru portalın `/assistant` ucuna gider; anahtar
// uygulamada değil, sunucudadır. Sunucuya ulaşılamazsa yine kurallı yanıt.
// ---------------------------------------------------------------------------

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage(this.role, this.text, {this.offline = false});

  final ChatRole role;
  final String text;

  /// Yanıt sunucuya ulaşılamadığı için telefonda hazırlandı.
  final bool offline;
}

/// Asistanın bağlam olarak kullandığı özet sayılar. Ad, kimlik, cihaz adresi
/// ya da tek tek ölçüm yoktur.
@immutable
class AssistantFacts {
  const AssistantFacts({
    required this.day,
    this.sleepMinutes,
    this.sleepStart,
    this.sleepEnd,
    this.sleepScore,
    this.sleepEfficiency,
    this.sleepDebtMinutes,
    this.recovery,
    this.hrv,
    this.hrvBaseline,
    this.restingHeartRate,
    this.restingBaseline,
    this.stress,
    this.strain,
    this.strainOptimal,
    this.steps = 0,
    this.averageHeartRate,
    this.minHeartRate,
    this.maxHeartRate,
    this.ecgTime,
    this.ecgState,
    this.age,
    this.biologicalAge,
    this.bioAgeDays = 0,
    this.workouts7 = 0,
    this.workoutMinutes7 = 0,
  });

  final DateTime day;
  final int? sleepMinutes;
  final DateTime? sleepStart;
  final DateTime? sleepEnd;
  final int? sleepScore;
  final int? sleepEfficiency;
  final int? sleepDebtMinutes;
  final int? recovery;
  final int? hrv;
  final int? hrvBaseline;
  final int? restingHeartRate;
  final int? restingBaseline;
  final int? stress;
  final double? strain;
  final (double, double)? strainOptimal;
  final int steps;
  final int? averageHeartRate;
  final int? minHeartRate;
  final int? maxHeartRate;

  /// Son EKG kaydı ve ön değerlendirmesi.
  final DateTime? ecgTime;
  final FindingState? ecgState;

  final int? age;
  final int? biologicalAge;

  /// Biyolojik yaş için toplanan kesintisiz gün.
  final int bioAgeDays;
  final int workouts7;
  final int workoutMinutes7;

  RecoveryLevel? get recoveryLevel =>
      recovery == null ? null : RecoveryLevel.of(recovery!);

  static AssistantFacts of(HealthStore store, DateTime day, {int? age}) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DaySummary.of(store, d);
    final night = s.night;
    final sleep = night == null ? null : SleepAnalysis.of(store, night);
    final rec = DayRecovery.of(store, d);
    final strain = DayStrain.of(store, d, age: age);
    final ecgs = store.ecgRecordings()
      ..sort((a, b) => b.start.compareTo(a.start));
    final ecg = ecgs.firstOrNull;
    FindingState? ecgState;
    if (ecg != null) {
      final f = EcgFindings.of(EcgSummary.analyze(ecg.samples, ecg.sampleRate));
      ecgState = !f.assessable
          ? FindingState.unknown
          : [
              f.highRate,
              f.lowRate,
              f.afib,
              f.normalRhythm,
            ].contains(FindingState.flagged)
          ? FindingState.flagged
          : FindingState.ok;
    }
    final bio = age == null ? null : BiologicalAge.of(store, d, age);
    final collection = BioAgeCollection.of(store, d);
    final end = DateTime(d.year, d.month, d.day + 1);
    final workouts = store.workoutsBetween(
      end.subtract(const Duration(days: 7)),
      end,
    );
    final hr = s.heartRateStats;
    return AssistantFacts(
      day: d,
      sleepMinutes: night?.asleepMinutes,
      sleepStart: night?.start,
      sleepEnd: night?.end,
      sleepScore: sleep?.score,
      sleepEfficiency: sleep?.efficiency,
      sleepDebtMinutes: sleep?.debtMinutes,
      recovery: rec?.score,
      hrv: rec?.hrv?.round(),
      hrvBaseline: rec?.hrvBaseline?.round(),
      restingHeartRate: rec?.restingHeartRate,
      restingBaseline: rec?.restingBaseline,
      stress: rec?.stress?.round(),
      strain: strain?.score,
      strainOptimal: strain?.optimal,
      steps: s.steps,
      averageHeartRate: hr?.average.round(),
      minHeartRate: hr?.min.round(),
      maxHeartRate: hr?.max.round(),
      ecgTime: ecg?.start,
      ecgState: ecgState,
      age: age,
      biologicalAge: collection.ready ? bio?.age : null,
      bioAgeDays: collection.days,
      workouts7: workouts.length,
      workoutMinutes7: workouts.fold(0, (a, w) => a + w.duration.inMinutes),
    );
  }

  /// Sunucuya gidecek JSON; saatler yalnızca saat:dakika.
  Map<String, Object?> toJson() {
    String? t(DateTime? x) => x == null
        ? null
        : '${x.hour.toString().padLeft(2, '0')}:'
              '${x.minute.toString().padLeft(2, '0')}';
    return {
      'sleep_minutes': sleepMinutes,
      'sleep_start': t(sleepStart),
      'sleep_end': t(sleepEnd),
      'sleep_score': sleepScore,
      'sleep_efficiency_percent': sleepEfficiency,
      'sleep_debt_minutes': sleepDebtMinutes,
      'recovery_score': recovery,
      'hrv_ms': hrv,
      'hrv_baseline_ms': hrvBaseline,
      'resting_hr': restingHeartRate,
      'resting_hr_baseline': restingBaseline,
      'stress': stress,
      'strain_0_21': strain,
      'strain_optimal': strainOptimal == null
          ? null
          : [strainOptimal!.$1, strainOptimal!.$2],
      'steps': steps,
      'avg_hr': averageHeartRate,
      'min_hr': minHeartRate,
      'max_hr': maxHeartRate,
      'last_ecg_days_ago': ecgTime == null
          ? null
          : day.difference(ecgTime!).inDays.clamp(0, 9999),
      'last_ecg_assessment': ecgState?.name,
      'age': age,
      'biological_age': biologicalAge,
      'bio_age_days_collected': bioAgeDays,
      'workouts_last_7_days': workouts7,
      'workout_minutes_last_7_days': workoutMinutes7,
    };
  }
}

/// Sorunun konuları; bir soru birden çok konu taşıyabilir.
enum AssistantTopic {
  emergency,
  medication,
  greeting,
  thanks,
  report,
  training,
  sleep,
  heart,
  recovery,
  strain,
  stress,
  ecg,
  bioAge,
  steps,
  workouts,
}

/// Dört dilde anahtar sözcüklerle konu bulma. Türkçe ve Almanca harfler
/// sadeleştirilir ("uykum" → "uykum", "Schlaf" → "schlaf").
abstract final class AssistantIntents {
  static String normalize(String s) {
    const map = {
      'İ': 'i', 'I': 'ı', 'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', //
      'ş': 's', 'ü': 'u', 'ä': 'a', 'ß': 'ss', 'â': 'a', 'î': 'i',
    };
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final m = map[ch] ?? map[ch.toLowerCase()];
      b.write(m ?? ch.toLowerCase());
    }
    // "I" → "ı" → "i" sonucunu tekrar sadeleştir.
    return b.toString().replaceAll('ı', 'i');
  }

  static const _words = <AssistantTopic, List<String>>{
    AssistantTopic.emergency: [
      'gogus agri',
      'gogsum agri',
      'gogsumde agri',
      'nefes alamiyorum',
      'nefes darligi',
      'bayil',
      'felc',
      'inme gec',
      'kendime zarar',
      'intihar',
      'chest pain',
      "can't breathe",
      'cant breathe',
      'shortness of breath',
      'fainted',
      'fainting',
      'stroke',
      'suicid',
      'hurt myself',
      'brustschmerz',
      'atemnot',
      'ohnmacht',
      'schlaganfall',
      'bewusstlos',
      'ألم في الصدر',
      'ألم صدر',
      'ضيق في التنفس',
      'لا أستطيع التنفس',
      'إغماء',
      'أغمي',
      'سكتة',
      'انتحار',
    ],
    AssistantTopic.medication: [
      'ilac',
      'hap ',
      'doz',
      'teshis',
      'hastalig',
      'kanser',
      'antibiyotik',
      'medication',
      'medicine',
      'pill',
      'dose',
      'diagnos',
      'disease',
      'medikament',
      'tablette',
      'dosis',
      'krankheit',
      'دواء',
      'أدوية',
      'جرعة',
      'تشخيص',
      'مرض',
    ],
    AssistantTopic.greeting: [
      'merhaba',
      'selam',
      'hello',
      'hi ',
      'hey',
      'hallo',
      'guten tag',
      'guten morgen',
      'مرحبا',
      'السلام',
      'أهلا',
      'اهلا',
    ],
    AssistantTopic.thanks: [
      'tesekkur',
      'sagol',
      'thank',
      'danke',
      'شكرا',
      'شكراً',
    ],
    AssistantTopic.report: [
      'rapor',
      'bugun nasil',
      'ozet',
      'genel durum',
      'report',
      'summary',
      'overview',
      'how am i',
      'bericht',
      'zusammenfassung',
      'wie geht es mir',
      'تقرير',
      'ملخص',
      'حالتي',
    ],
    AssistantTopic.training: [
      'antrenman',
      'egzersiz',
      'spor',
      'program',
      'kosu',
      'kosmal',
      'calis',
      'training',
      'workout plan',
      'exercise',
      'train',
      'run ',
      'trainingsplan',
      'trainieren',
      'sport',
      'laufen',
      'تمرين',
      'رياضة',
      'برنامج',
      'تدريب',
    ],
    AssistantTopic.sleep: [
      'uyku',
      'uyu',
      'gece',
      'sleep',
      'slept',
      'night',
      'schlaf',
      'nacht',
      'نوم',
      'نمت',
      'الليلة',
    ],
    AssistantTopic.heart: [
      'nabiz',
      'nabz',
      'kalp',
      'heart',
      'pulse',
      'bpm',
      'herz',
      'puls',
      'نبض',
      'قلب',
    ],
    AssistantTopic.recovery: [
      'toparlan',
      'hrv',
      'dinlen',
      'yorgun',
      'recover',
      'tired',
      'rested',
      'erhol',
      'mude',
      'تعافي',
      'متعب',
      'إرهاق',
    ],
    AssistantTopic.strain: [
      'yuk',
      'strain',
      'load',
      'belastung',
      'الحمل',
      'حملي',
    ],
    AssistantTopic.stress: [
      'stres',
      'stress',
      'gergin',
      'kaygi',
      'anxious',
      'anxiety',
      'angst',
      'gestresst',
      'توتر',
      'ضغط نفسي',
      'قلق',
    ],
    AssistantTopic.ecg: [
      'ekg',
      'ecg',
      'ritim',
      'rhythm',
      'rhythmus',
      'تخطيط',
      'نظم القلب',
    ],
    AssistantTopic.bioAge: [
      'biyolojik',
      'vitalage',
      'yasim',
      'biological',
      'biologisch',
      'alter',
      'my age',
      'العمر البيولوجي',
      'عمري',
    ],
    AssistantTopic.steps: [
      'adim',
      'aktivite',
      'yuru',
      'hareket',
      'step',
      'walk',
      'activity',
      'schritt',
      'aktivit',
      'gehen',
      'خطوات',
      'خطوة',
      'نشاط',
      'مشي',
    ],
    AssistantTopic.workouts: [
      'egzersizlerim',
      'antrenmanlarim',
      'my workouts',
      'meine trainings',
      'تماريني',
    ],
  };

  /// Sorudaki konular, sözlük sırasıyla (acil durum ilk).
  static List<AssistantTopic> of(String text) {
    final t = ' ${normalize(text)} ';
    return [
      for (final e in _words.entries)
        if (e.value.any((w) => t.contains(normalize(w)))) e.key,
    ];
  }
}

/// Yanıt üreten hizmet.
abstract interface class AssistantService {
  /// [history]'nin son mesajı kullanıcınındır. null: bu hizmet yanıt veremedi
  /// (sunucu yok, bağlantı yok); çağıran çevrimdışı yanıta düşer.
  Future<String?> reply(
    List<ChatMessage> history,
    AssistantFacts facts,
    String language,
  );
}

/// Portalın `/assistant` ucu (Claude API sunucuda).
class PortalAssistantService implements AssistantService {
  PortalAssistantService(this.client);

  final PortalClient client;

  /// Telefonda portal varsa `main` koyar; yoksa null ve yalnızca kurallı
  /// yanıt.
  static AssistantService? instance;

  /// Sunucu "anahtar yok" dedi; bu oturumda bir daha denenmez.
  bool _notConfigured = false;

  @override
  Future<String?> reply(
    List<ChatMessage> history,
    AssistantFacts facts,
    String language,
  ) async {
    if (_notConfigured) return null;
    try {
      final r = await client.request(
        'POST',
        '/assistant',
        body: {
          'lang': language,
          'messages': [
            for (final m in history) {'role': m.role.name, 'content': m.text},
          ],
          'facts': facts.toJson(),
        },
        ok: const {200, 503},
      );
      if (r.statusCode == 503) {
        _notConfigured = true;
        return null;
      }
      final json = jsonDecode(r.body) as Map;
      return json['reply'] as String?;
    } catch (_) {
      return null;
    }
  }
}
