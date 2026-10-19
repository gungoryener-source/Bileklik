// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Bileklik';

  @override
  String get bandAnxious => 'قلق';

  @override
  String get bandCalm => 'هادئ';

  @override
  String get bandGood => 'جيد';

  @override
  String get bandGreat => 'ممتاز';

  @override
  String get bandLow => 'منخفض';

  @override
  String get bandMild => 'خفيف';

  @override
  String get bandNormal => 'طبيعي';

  @override
  String get bandTense => 'متوتر';

  @override
  String get continueButton => 'متابعة';

  @override
  String durationHours(Object h) {
    return '$h س';
  }

  @override
  String durationHoursMinutes(Object h, Object m) {
    return '$h س $m د';
  }

  @override
  String durationMinutes(Object m) {
    return '$m د';
  }

  @override
  String get issueBusy => 'السوار مشغول بتمرين أو قياس آخر.';

  @override
  String get issueFailed =>
      'تعذر الاتصال بالسوار. تأكد من أنه قريب وقيد التشغيل.';

  @override
  String get issueNoEcgSignal =>
      'لم يتم استلام بيانات تخطيط القلب. ارتدِ السوار والمس القطب بإصبعك.';

  @override
  String get languagePickHint => 'يمكنك تغييرها لاحقًا من شاشة الملف الشخصي.';

  @override
  String get languagePickTitle => 'اختر لغتك';

  @override
  String get languageSystem => 'لغة الهاتف';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get metricCalories => 'السعرات';

  @override
  String get metricDiastolic => 'ضغط الدم (الانبساطي)';

  @override
  String get metricDistance => 'المسافة';

  @override
  String get metricHeartRate => 'معدل ضربات القلب';

  @override
  String get metricHrv => 'تقلب معدل ضربات القلب';

  @override
  String get metricRespiratoryRate => 'معدل التنفس';

  @override
  String get metricSpo2 => 'تشبع الأكسجين في الدم';

  @override
  String get metricSteps => 'الخطوات';

  @override
  String get metricStress => 'التوتر';

  @override
  String get metricSystolic => 'ضغط الدم (الانقباضي)';

  @override
  String get metricTemperature => 'حرارة الجسم';

  @override
  String get navExercise => 'التمارين';

  @override
  String get navHealth => 'الصحة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get noValue => '--';

  @override
  String get periodDay => 'يوم';

  @override
  String get periodMonth => 'شهر';

  @override
  String get periodWeek => 'أسبوع';

  @override
  String get sleepAwake => 'مستيقظ';

  @override
  String get sleepDeep => 'عميق';

  @override
  String get sleepLight => 'خفيف';

  @override
  String get sleepRem => 'حركة العين السريعة';

  @override
  String get sportAerobics => 'أيروبيك';

  @override
  String get sportBadminton => 'تنس الريشة';

  @override
  String get sportBasketball => 'كرة السلة';

  @override
  String get sportCricket => 'كريكيت';

  @override
  String get sportCycling => 'ركوب الدراجة';

  @override
  String get sportDance => 'رقص';

  @override
  String get sportFootball => 'كرة القدم';

  @override
  String get sportHiking => 'تنزه';

  @override
  String get sportMeditation => 'تأمل';

  @override
  String get sportPingPong => 'تنس الطاولة';

  @override
  String get sportRopeJump => 'نط الحبل';

  @override
  String get sportRun => 'جري';

  @override
  String get sportSitUps => 'تمارين البطن';

  @override
  String get sportTennis => 'تنس';

  @override
  String get sportUnknown => 'تمرين';

  @override
  String get sportVolleyball => 'كرة الطائرة';

  @override
  String get sportWalk => 'مشي';

  @override
  String get sportWorkout => 'تمرين';

  @override
  String get sportYoga => 'يوغا';

  @override
  String get unitPerMinute => '/د';

  @override
  String get unitSteps => 'خطوة';
}
