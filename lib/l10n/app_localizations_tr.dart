// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Bileklik';

  @override
  String get bandAnxious => 'Kaygılı';

  @override
  String get bandCalm => 'Sakin';

  @override
  String get bandGood => 'İyi';

  @override
  String get bandGreat => 'Harika';

  @override
  String get bandLow => 'Düşük';

  @override
  String get bandMild => 'Hafif';

  @override
  String get bandNormal => 'Normal';

  @override
  String get bandTense => 'Gergin';

  @override
  String get continueButton => 'Devam';

  @override
  String durationHours(Object h) {
    return '$h sa';
  }

  @override
  String durationHoursMinutes(Object h, Object m) {
    return '$h sa $m dk';
  }

  @override
  String durationMinutes(Object m) {
    return '$m dk';
  }

  @override
  String get issueBusy => 'Bileklik şu an başka bir egzersizde ya da ölçümde.';

  @override
  String get issueFailed =>
      'Bileklikle iletişim kurulamadı. Yakında ve açık olduğundan emin olun.';

  @override
  String get issueNoEcgSignal =>
      'EKG verisi alınamadı. Bilekliği takıp parmağınızı elektroda dokundurun.';

  @override
  String get languagePickHint =>
      'Daha sonra Profil ekranından değiştirebilirsiniz.';

  @override
  String get languagePickTitle => 'Dilinizi seçin';

  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get languageTitle => 'Dil';

  @override
  String get metricCalories => 'Kalori';

  @override
  String get metricDiastolic => 'Tansiyon (küçük)';

  @override
  String get metricDistance => 'Mesafe';

  @override
  String get metricHeartRate => 'Kalp Atış Hızı';

  @override
  String get metricHrv => 'Kalp Atış Hızı Değişkenliği';

  @override
  String get metricRespiratoryRate => 'Solunum Hızı';

  @override
  String get metricSpo2 => 'Kan Oksijen Doygunluğu';

  @override
  String get metricSteps => 'Adım';

  @override
  String get metricStress => 'Stres';

  @override
  String get metricSystolic => 'Tansiyon (büyük)';

  @override
  String get metricTemperature => 'Vücut Isısı';

  @override
  String get navExercise => 'Egzersiz';

  @override
  String get navHealth => 'Sağlık';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navProfile => 'Profil';

  @override
  String get noValue => '--';

  @override
  String get periodDay => 'Gün';

  @override
  String get periodMonth => 'Ay';

  @override
  String get periodWeek => 'Hafta';

  @override
  String get sleepAwake => 'Uyanık';

  @override
  String get sleepDeep => 'Derin';

  @override
  String get sleepLight => 'Hafif';

  @override
  String get sleepRem => 'REM';

  @override
  String get sportAerobics => 'Aerobik';

  @override
  String get sportBadminton => 'Badminton';

  @override
  String get sportBasketball => 'Basketbol';

  @override
  String get sportCricket => 'Kriket';

  @override
  String get sportCycling => 'Bisiklet';

  @override
  String get sportDance => 'Dans';

  @override
  String get sportFootball => 'Futbol';

  @override
  String get sportHiking => 'Doğa yürüyüşü';

  @override
  String get sportMeditation => 'Meditasyon';

  @override
  String get sportPingPong => 'Masa tenisi';

  @override
  String get sportRopeJump => 'İp atlama';

  @override
  String get sportRun => 'Koşu';

  @override
  String get sportSitUps => 'Mekik';

  @override
  String get sportTennis => 'Tenis';

  @override
  String get sportUnknown => 'Egzersiz';

  @override
  String get sportVolleyball => 'Voleybol';

  @override
  String get sportWalk => 'Yürüyüş';

  @override
  String get sportWorkout => 'Antrenman';

  @override
  String get sportYoga => 'Yoga';

  @override
  String get unitPerMinute => '/dk';

  @override
  String get unitSteps => 'adım';
}
