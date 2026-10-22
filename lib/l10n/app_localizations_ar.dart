// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get aboutDescription =>
      'يعرض تطبيق Bileklik قياسات سوار تخطيط القلب JCV8 على هاتفك.';

  @override
  String get aboutLicenses => 'تراخيص المصادر المفتوحة';

  @override
  String get aboutMedical =>
      'هذا التطبيق ليس جهازًا طبيًا؛ استشر طبيبك للتشخيص والعلاج. قيم ضغط الدم تقديرية.';

  @override
  String get aboutPrivacy =>
      'تبقى قياساتك على هذا الهاتف. عند إضافة المشاركة، ستقرر أنت من يرى ماذا.';

  @override
  String aboutVersion(Object version) {
    return 'الإصدار $version';
  }

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get appTitle => 'Bileklik';

  @override
  String get autoMeasureAllDay => 'طوال اليوم';

  @override
  String get autoMeasureConnect => 'اتصال';

  @override
  String get autoMeasureDays => 'الأيام';

  @override
  String get autoMeasureEnd => 'النهاية';

  @override
  String get autoMeasureEveryDay => 'كل يوم';

  @override
  String autoMeasureEveryHours(int hours) {
    return 'كل $hours ساعة';
  }

  @override
  String autoMeasureEveryMinutes(int minutes) {
    return 'كل $minutes دقيقة';
  }

  @override
  String get autoMeasureHours => 'ساعات القياس';

  @override
  String get autoMeasureInterval => 'الفاصل الزمني';

  @override
  String get autoMeasureIntro =>
      'يقيس السوار تلقائيًا في الساعات التي تختارها. يستغرق كل قياس دقيقة واحدة؛ وكلما قصرت الفترة نفدت البطارية أسرع.';

  @override
  String get autoMeasureLoadFailed => 'تعذّرت قراءة إعدادات السوار.';

  @override
  String autoMeasureNextDay(String time) {
    return '$time (اليوم التالي)';
  }

  @override
  String get autoMeasureNoDays => 'يجب أن يبقى يوم واحد على الأقل محددًا.';

  @override
  String get autoMeasureNotConnected => 'وصّل السوار لعرض إعداداته وتغييرها.';

  @override
  String get autoMeasureOff => 'متوقف';

  @override
  String get autoMeasureRetry => 'حاول مرة أخرى';

  @override
  String get autoMeasureSameTime => 'لا يمكن أن تتطابق البداية والنهاية.';

  @override
  String get autoMeasureSaveFailed =>
      'تعذّر حفظ الإعداد في السوار. حاول مرة أخرى.';

  @override
  String get autoMeasureSleepNote =>
      'أثناء النوم يقيس السوار النبض كل 5 دقائق.';

  @override
  String get autoMeasureStart => 'البداية';

  @override
  String get autoMeasureTitle => 'القياس التلقائي';

  @override
  String autoMeasureTurnOn(String name) {
    return 'القياس التلقائي: $name';
  }

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
  String get bmiNormal => 'وزن طبيعي';

  @override
  String get bmiObese => 'سمنة';

  @override
  String get bmiOver => 'زيادة الوزن';

  @override
  String get bmiUnder => 'نقص الوزن';

  @override
  String get bodyAdd => 'إضافة قياس';

  @override
  String get bodyBmiNeedsHeight => 'أدخل طولك لمعرفة مؤشر كتلة الجسم.';

  @override
  String get bodyBmiNote =>
      'مؤشر كتلة الجسم دليل عام للبالغين؛ وقد يكون مضللًا لذوي الكتلة العضلية العالية وأثناء الحمل وللأطفال.';

  @override
  String bodyChange(String change) {
    return '$change منذ القياس السابق';
  }

  @override
  String get bodyChartEmpty => 'لا قياسات في هذه الفترة.';

  @override
  String get bodyDate => 'التاريخ';

  @override
  String get bodyDelete => 'حذف';

  @override
  String bodyDeleteBody(String date) {
    return 'سيُحذف قياس $date من هذا الهاتف.';
  }

  @override
  String get bodyDeleteTitle => 'حذف القياس؟';

  @override
  String get bodyEmpty =>
      'أدخل وزنك كلما وزنت نفسك وتابع التغيّر في الرسم البياني.';

  @override
  String get bodyHeight => 'الطول';

  @override
  String get bodyHistory => 'السجل';

  @override
  String get bodyMuscleTooHigh => 'لا يمكن أن تتجاوز الكتلة العضلية الوزن';

  @override
  String get bodyNoChange => 'مثل القياس السابق';

  @override
  String get bodyNote =>
      'تُحفظ القياسات على هذا الهاتف فقط. إذا كان السوار متصلًا يُرسل وزنك إليه أيضًا لحساب السعرات.';

  @override
  String bodyOptional(String name) {
    return '$name (اختياري)';
  }

  @override
  String get bodyRange3Months => '3 أشهر';

  @override
  String bodyRangeError(String min, String max) {
    return 'يجب أن يكون بين $min و$max';
  }

  @override
  String get bodyRangeMonth => 'شهر';

  @override
  String get bodyRangeYear => 'سنة';

  @override
  String get bodySave => 'حفظ';

  @override
  String get bodySheetTitle => 'قياس جديد';

  @override
  String get bodyTitle => 'الوزن والجسم';

  @override
  String get bodyToday => 'اليوم';

  @override
  String get clock12 => '12 ساعة (ص/م)';

  @override
  String get clock24 => '24 ساعة';

  @override
  String get clockSystem => 'حسب اللغة';

  @override
  String get clockTitle => 'تنسيق الوقت';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get comingSoonMessage => 'سيتوفر هذا القسم في إصدار قادم.';

  @override
  String get communityAccept => 'انضمام';

  @override
  String get communityAnswered => 'تم الرد';

  @override
  String get communityCodeCopied => 'تم نسخ الرمز';

  @override
  String get communityCodeInvalid => 'لم يتم العثور على مجموعة بهذا الرمز.';

  @override
  String get communityCodeLabel => 'رمز المجموعة';

  @override
  String communityConsentSince(Object date) {
    return 'تاريخ الإذن: $date';
  }

  @override
  String get communityCopyCode => 'نسخ الرمز';

  @override
  String get communityCreate => 'إنشاء';

  @override
  String get communityCreateGroup => 'إنشاء مجموعة جديدة';

  @override
  String get communityDecline => 'رفض';

  @override
  String get communityDelete => 'حذف المجموعة';

  @override
  String communityDeleteConfirm(Object group) {
    return 'سيتم حذف «$group» وتنتهي كل المشاركات فيها.';
  }

  @override
  String get communityGroupName => 'اسم المجموعة';

  @override
  String get communityGroupNameHint => 'مثلًا: عائلتي';

  @override
  String get communityInvite => 'دعوة عضو';

  @override
  String communityInviteCodeBody(Object name) {
    return 'شارك هذا الرمز مع $name. يمكنه الانضمام من مجتمع الصحة > الانضمام برمز.';
  }

  @override
  String get communityInviteCodeTitle => 'رمز الدعوة';

  @override
  String get communityInviteName => 'اسم الشخص المدعو';

  @override
  String get communityInviteSend => 'دعوة';

  @override
  String get communityJoinWithCode => 'الانضمام برمز';

  @override
  String get communityJoinedEmpty => 'يمكنك الانضمام بدعوة أو برمز مجموعة.';

  @override
  String get communityJoinedGroups => 'المجموعات التي انضممت إليها';

  @override
  String communityJoinedMessage(Object group) {
    return 'انضممت إلى «$group».';
  }

  @override
  String get communityLeave => 'مغادرة المجموعة';

  @override
  String communityLeaveConfirm(Object group) {
    return 'عند مغادرة «$group» لن يرى أعضاؤها بياناتك المشتركة بعد الآن.';
  }

  @override
  String communityMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضو',
      many: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
      zero: 'لا أعضاء',
    );
    return '$_temp0';
  }

  @override
  String get communityMembers => 'الأعضاء';

  @override
  String get communityMessages => 'الرسائل';

  @override
  String get communityMessagesEmpty => 'لا توجد رسائل بعد.';

  @override
  String communityMsgInvite(Object name, Object group) {
    return 'دعاك $name إلى مجموعة «$group».';
  }

  @override
  String communityMsgJoined(Object name, Object group) {
    return 'انضم $name إلى مجموعة «$group».';
  }

  @override
  String get communityMyGroups => 'مجموعاتي';

  @override
  String get communityMyGroupsEmpty =>
      'ليست لديك مجموعة بعد. أنشئ مجموعة وادعُ عائلتك.';

  @override
  String get communityMyShareNote =>
      'يراها أعضاء هذه المجموعة فقط. لا تتم مشاركة أي شيء حتى تقوم بتفعيله.';

  @override
  String get communityMyShareTitle => 'ما تشاركه مع هذه المجموعة';

  @override
  String get communityOwner => 'المالك';

  @override
  String communityOwnerName(Object name) {
    return 'المالك: $name';
  }

  @override
  String get communityPending => 'الدعوة قيد الانتظار';

  @override
  String get communityPrivacyNote =>
      'تُشارَك بياناتك الصحية فقط مع المجموعات التي تختارها وبالأنواع التي تحددها. يمكنك سحب الإذن في أي وقت.';

  @override
  String get communityRemoveMember => 'إزالة من المجموعة';

  @override
  String communityShares(Object types) {
    return 'يشارك: $types';
  }

  @override
  String get communitySharesNothing => 'لا يشارك أي شيء بعد';

  @override
  String get communityYou => 'أنت';

  @override
  String get connActive => 'اتصالاتي';

  @override
  String connAgree(Object name) {
    return 'قرأت هذه المعلومات وأوافق صراحةً على مشاركة البيانات التي اخترتها مع $name للغرض المذكور أعلاه.';
  }

  @override
  String get connCodeInvalid => 'هذا الرمز غير صالح أو منتهي الصلاحية.';

  @override
  String get connConfirm => 'الموافقة والاتصال';

  @override
  String connConnected(Object name) {
    return 'تم الاتصال بـ $name.';
  }

  @override
  String get connConsentTitle => 'الموافقة الصريحة';

  @override
  String get connDisconnect => 'إزالة الاتصال';

  @override
  String connDisconnectConfirm(Object name) {
    return 'لن يتمكن $name من رؤية بياناتك الجديدة. يمكنك أن تطلب منهم حذف البيانات التي تمت مشاركتها سابقًا.';
  }

  @override
  String get connDuration => 'المدة';

  @override
  String connDurationText(Object date, Object days) {
    return 'حتى $date ($days يومًا). تتوقف المشاركة تلقائيًا عند انتهاء المدة، ويمكنك إيقافها قبل ذلك.';
  }

  @override
  String get connEmpty => 'ليست لديك اتصالات بعد.';

  @override
  String get connEnterCode => 'إدخال رمز الدعوة';

  @override
  String get connIntro =>
      'يعطيك طبيبك أو دراسة تشارك فيها رمز دعوة. عند إدخاله ترى من يطلب، وأي بيانات، ولأي مدة، ثم تقرر أنت.';

  @override
  String get connKindClinician => 'طبيب';

  @override
  String get connKindResearch => 'مؤسسة بحثية';

  @override
  String get connPurpose => 'الغرض';

  @override
  String get connQrInvalid => 'لا يحتوي رمز QR هذا على رمز دعوة.';

  @override
  String get connRequested => 'البيانات المطلوبة';

  @override
  String get connRequestedNote =>
      'اختر ما تريد مشاركته. ما لا تختاره لا تتم مشاركته.';

  @override
  String get connRights =>
      'تُعالَج بياناتك وفق قانون حماية البيانات الشخصية (KVKK). يحق لك الاطلاع على بياناتك وطلب تصحيحها أو حذفها.';

  @override
  String get connScan => 'مسح رمز QR';

  @override
  String get connScanHint => 'ضع رمز QR الذي حصلت عليه من طبيبك أو من مؤسسة البحث داخل الإطار.';

  @override
  String get connSelectAll => 'تحديد الكل';

  @override
  String get connShared => 'البيانات المشتركة';

  @override
  String connSharedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نوع بيانات',
      many: '$count نوعًا من البيانات',
      few: '$count أنواع بيانات',
      two: 'نوعا بيانات',
      one: 'نوع بيانات واحد',
    );
    return '$_temp0';
  }

  @override
  String connSince(Object date) {
    return 'منذ $date';
  }

  @override
  String connUntil(Object date) {
    return 'حتى $date';
  }

  @override
  String get continueButton => 'متابعة';

  @override
  String get deviceAddress => 'العنوان';

  @override
  String get deviceBattery => 'البطارية';

  @override
  String deviceBatteryValue(Object value) {
    return '$value٪';
  }

  @override
  String get deviceConnected => 'متصل';

  @override
  String get deviceDisconnect => 'قطع الاتصال';

  @override
  String get deviceDisconnected => 'غير متصل';

  @override
  String get deviceLastSync => 'آخر مزامنة';

  @override
  String get devicePairNew => 'إقران سوار آخر';

  @override
  String get deviceSectionSettings => 'إعدادات السوار';

  @override
  String get deviceStatus => 'الحالة';

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
  String ecgAverageBpm(Object bpm) {
    return 'متوسط $bpm نبضة/دقيقة';
  }

  @override
  String get ecgAverageHeartRate => 'متوسط النبض';

  @override
  String get ecgBeats => 'عدد النبضات';

  @override
  String get ecgBpm => 'نبضة/د';

  @override
  String get ecgCancel => 'إلغاء القياس';

  @override
  String get ecgConnectFirst => 'صِل السوار أولًا من الصفحة الرئيسية.';

  @override
  String ecgDetailTitle(Object date, Object time) {
    return 'تخطيط القلب · $date $time';
  }

  @override
  String get ecgDisclaimer =>
      'هذا القياس لا يغني عن التشخيص الطبي. إذا شعرت بألم في الصدر أو ضيق في التنفس أو بأنك على وشك الإغماء، فاتصل برقم الطوارئ المحلي فورًا.';

  @override
  String get ecgHowToSteps =>
      '1. ارتدِ السوار بإحكام على معصمك.\n2. اجلس وضع ذراعك على الطاولة.\n3. المس برفق القطب الموجود أعلى السوار بإصبع من يدك الأخرى.\n4. لا تتحرك ولا تتكلم لمدة 30 ثانية.';

  @override
  String get ecgHowToTitle => 'طريقة القياس';

  @override
  String get ecgKeepStill => 'أبقِ إصبعك على القطب ولا تتحرك.';

  @override
  String get ecgMeasuringTitle => 'جارٍ تسجيل تخطيط القلب';

  @override
  String get ecgMs => 'مللي ث';

  @override
  String get ecgNoHeartRate => 'تعذّر حساب النبض';

  @override
  String get ecgNoRecords => 'لا توجد تسجيلات لتخطيط القلب بعد.';

  @override
  String get ecgRange => 'النطاق';

  @override
  String ecgRangeValue(Object min, Object max) {
    return '$min-$max';
  }

  @override
  String ecgRecordHeader(Object seconds, Object perRow) {
    return 'التسجيل ($seconds ث، $perRow ث لكل سطر)';
  }

  @override
  String ecgRecordSubtitle(Object when, Object seconds) {
    return '$when · $seconds ث';
  }

  @override
  String get ecgRecordsTitle => 'التسجيلات';

  @override
  String get ecgSdnn => 'التباين (SDNN)';

  @override
  String ecgSecondsLeft(Object seconds) {
    return '$seconds ث';
  }

  @override
  String get ecgStartButton => 'ابدأ قياسًا لمدة 30 ثانية';

  @override
  String get ecgTitle => 'تخطيط القلب';

  @override
  String get exerciseConnectFirst => 'صِل السوار من الصفحة الرئيسية أولًا.';

  @override
  String get exerciseConnectHint => 'صِل السوار لعرض التمارين السابقة.';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تمرين',
      many: '$count تمرينًا',
      few: '$count تمارين',
      two: 'تمرينان',
      one: 'تمرين واحد',
      zero: 'لا تمارين',
    );
    return '$_temp0';
  }

  @override
  String get exerciseEmpty => 'لا توجد تمارين بعد.';

  @override
  String exerciseInProgress(Object sport) {
    return '$sport قيد التقدم';
  }

  @override
  String get exerciseLast30Days => 'آخر 30 يومًا';

  @override
  String exercisePausedAt(Object time) {
    return 'متوقف مؤقتًا · $time';
  }

  @override
  String get exerciseStart => 'ابدأ تمرينًا';

  @override
  String get exerciseThisWeek => 'هذا الأسبوع';

  @override
  String get exportEmpty => 'لا توجد سجلات للتصدير في هذه الفترة.';

  @override
  String get exportFailed => 'تعذر تجهيز الملف. حاول مرة أخرى.';

  @override
  String get exportIncludeEcg => 'تضمين تسجيلات تخطيط القلب';

  @override
  String get exportIncludeEcgNote => 'بيانات تخطيط القلب الخام تزيد حجم الملف.';

  @override
  String get exportIntro => 'تُجهَّز قياساتك في ملف بصيغة FHIR R4، وهي الصيغة المشتركة للأنظمة الصحية. يمكنك إرساله إلى طبيبك أو فتحه في تطبيق يقرأ هذه الصيغة.';

  @override
  String get exportPeriod => 'الفترة';

  @override
  String get exportPrivacy => 'يحتوي الملف على بيانات صحية. شاركه فقط مع أشخاص ومؤسسات تثق بها. لا يتضمن الملف اسمك، بل معرّفًا مستعارًا خاصًا بهذا الهاتف فقط.';

  @override
  String exportRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجل',
      many: '$count سجلًا',
      few: '$count سجلات',
      two: 'سجلان',
      one: 'سجل واحد',
    );
    return '$_temp0';
  }

  @override
  String get exportShare => 'مشاركة الملف';

  @override
  String get exportTitle => 'تصدير بياناتي';

  @override
  String get healthBloodPressure => 'ضغط الدم';

  @override
  String healthBloodPressureSubtitle(Object details) {
    return 'تقديري · $details';
  }

  @override
  String get healthConnectHint => 'صِل السوار من الصفحة الرئيسية لعرض بياناتك.';

  @override
  String get healthEcg => 'تخطيط القلب';

  @override
  String healthEcgLast(Object time) {
    return 'آخر قياس · $time';
  }

  @override
  String get healthEcgPrompt => 'أجرِ قياسًا لمدة 30 ثانية';

  @override
  String healthLastSync(Object time) {
    return 'آخر تحديث $time';
  }

  @override
  String get healthNoMeasurement => 'لا توجد قياسات';

  @override
  String get healthNoRecord => 'لا توجد بيانات';

  @override
  String get healthSleep => 'النوم';

  @override
  String healthSleepLastNight(Object start, Object end) {
    return 'الليلة الماضية · $start - $end';
  }

  @override
  String healthStepsToday(Object goal) {
    return 'اليوم · الهدف $goal';
  }

  @override
  String get healthSyncTooltip => 'تحديث من السوار';

  @override
  String get healthSyncing => 'جارٍ جلب البيانات من السوار…';

  @override
  String healthWeightBmi(String bmi, String when) {
    return 'مؤشر كتلة الجسم $bmi · $when';
  }

  @override
  String get healthWeightPrompt => 'أدخل وزنك';

  @override
  String homeActiveGoal(Object minutes) {
    return 'الهدف $minutes دقيقة';
  }

  @override
  String get homeActiveTime => 'وقت النشاط';

  @override
  String get homeAverageStress => 'متوسط التوتر';

  @override
  String homeAverageStressBand(Object band) {
    return 'متوسط التوتر · $band';
  }

  @override
  String homeAverageValue(Object value) {
    return 'المتوسط $value';
  }

  @override
  String get homeBalance => 'التوازن';

  @override
  String get homeBloodOxygen => 'أكسجين الدم';

  @override
  String homeBpm(Object value) {
    return '$value نبضة/د';
  }

  @override
  String get homeCalories => 'السعرات';

  @override
  String homeChartNoData(Object title) {
    return '$title: لا توجد قياسات';
  }

  @override
  String homeChartSemantics(Object title, Object min, Object max, Object unit) {
    return '$title: الأدنى $min، الأعلى $max $unit';
  }

  @override
  String get homeConnectTooltip => 'الاتصال بالسوار';

  @override
  String get homeConnected => 'متصل';

  @override
  String homeConnectedBattery(Object percent) {
    return 'متصل · $percent٪';
  }

  @override
  String get homeConnecting => 'جارٍ الاتصال…';

  @override
  String get homeDaySummary => 'ملخص اليوم';

  @override
  String homeDeepSleep(Object duration) {
    return 'نوم عميق $duration';
  }

  @override
  String get homeDisconnectTooltip => 'قطع الاتصال';

  @override
  String get homeEcg => 'تخطيط القلب';

  @override
  String homeEcgSubtitle(Object bpm, Object seconds) {
    return '$bpm نبضة/د · $seconds ث';
  }

  @override
  String homeEcgSubtitleNoHr(Object seconds) {
    return '$seconds ث';
  }

  @override
  String get homeGoodAfternoon => 'طاب يومك';

  @override
  String get homeGoodEvening => 'مساء الخير';

  @override
  String get homeGoodMorning => 'صباح الخير';

  @override
  String get homeHeartRateHint => 'ارتدِ السوار طوال اليوم لترى معدل نبض قلبك.';

  @override
  String get homeHeartRateLabel => 'معدل نبض القلب';

  @override
  String get homeHeroEmpty => 'صِل السوار لترى نبضك.';

  @override
  String homeHeroSemantics(Object value) {
    return 'النبض $value نبضة/د';
  }

  @override
  String get homeHourlyStressSemantics => 'أعمدة التوتر لكل ساعة';

  @override
  String get homeHrvLabel => 'تقلب معدل نبض القلب';

  @override
  String get homeKcal => 'سعرة';

  @override
  String homeKm(Object value) {
    return '$value كم';
  }

  @override
  String homeLastMeasured(Object time) {
    return 'آخر قياس $time';
  }

  @override
  String get homeListSeparator => '، ';

  @override
  String get homeLive => 'مباشر';

  @override
  String get homeMeasureNow => 'قِس الآن';

  @override
  String homeMs(Object value) {
    return '$value مللي ثانية';
  }

  @override
  String get homeNextDay => 'اليوم التالي';

  @override
  String get homeNoRecord => 'لا يوجد سجل';

  @override
  String get homeNoSleepLastNight => 'لم يُسجَّل نوم الليلة الماضية';

  @override
  String get homeNoSleepPastHint =>
      'يظهر هنا ملخص الأيام التي ارتديت فيها السوار.';

  @override
  String get homeNoSleepStages => 'لا توجد مراحل نوم';

  @override
  String get homeNoSleepThisDay => 'لا يوجد سجل نوم لهذا اليوم';

  @override
  String get homeNoSleepTonightHint =>
      'ارتدِ السوار الليلة، وستجد ملخص نومك وتعافيك هنا في الصباح.';

  @override
  String get homeNotConnected => 'غير متصل';

  @override
  String homePercent(Object value) {
    return '$value٪';
  }

  @override
  String get homePickDay => 'اختر يومًا';

  @override
  String get homePrevDay => 'اليوم السابق';

  @override
  String get homeQuickActions => 'إجراءات سريعة';

  @override
  String get homeQuickHeartRate => 'قِس النبض';

  @override
  String get homeQuickSync => 'مزامنة';

  @override
  String homeRange(Object min, Object max) {
    return '$min–$max';
  }

  @override
  String get homeRecovery => 'التعافي';

  @override
  String homeRestingHr(Object value) {
    return 'نبض الراحة $value نبضة/د';
  }

  @override
  String get homeSleep => 'النوم';

  @override
  String homeSleepStageItem(Object stage, Object duration) {
    return '$stage $duration';
  }

  @override
  String homeSleepStagesSemantics(Object stages) {
    return 'مراحل النوم: $stages';
  }

  @override
  String homeSleptHrvBandSummary(Object duration, Object hrv, Object band) {
    return 'نمت $duration، وكان متوسط HRV الليلي $hrv مللي ثانية ($band).';
  }

  @override
  String homeSleptHrvSummary(Object duration, Object hrv) {
    return 'نمت $duration، وكان متوسط HRV الليلي $hrv مللي ثانية.';
  }

  @override
  String homeSleptSummary(Object duration) {
    return 'نمت $duration.';
  }

  @override
  String get homeSpo2Hint => 'ارتدِ السوار طوال اليوم لترى مستوى أكسجين دمك.';

  @override
  String get homeStartWorkout => 'ابدأ التمرين';

  @override
  String homeStepGoal(Object goal) {
    return 'الهدف: $goal خطوة';
  }

  @override
  String homeStepGoalProgress(Object percent, Object goal) {
    return '$percent٪ · الهدف $goal';
  }

  @override
  String homeStepGoalSemantics(Object steps, Object goal, Object percent) {
    return 'هدف الخطوات: $steps من $goal، $percent بالمئة';
  }

  @override
  String get homeSteps => 'الخطوات';

  @override
  String get homeStressHint =>
      'يُقاس التوتر وHRV خلال اليوم أثناء ارتداء السوار.';

  @override
  String get homeStressLevel => 'مستوى التوتر';

  @override
  String get homeStressLoad => 'عبء التوتر';

  @override
  String get homeSyncing => 'جارٍ المزامنة…';

  @override
  String get homeTimeline => 'الخط الزمني';

  @override
  String get homeTimelineEmpty =>
      'تظهر هنا تمارينك وتخطيطات القلب ونومك بترتيب الوقت.';

  @override
  String get homeTimelineSubtitle => 'سجلات اليوم';

  @override
  String get homeToday => 'اليوم';

  @override
  String homeWeekdayDate(Object weekday, Object date) {
    return '$weekday، $date';
  }

  @override
  String get homeWokeUp => 'استيقظت';

  @override
  String homeWokeUpSubtitle(Object duration, Object time) {
    return 'نوم $duration · وقت النوم $time';
  }

  @override
  String homeWorkoutSubtitle(Object duration, Object kcal) {
    return '$duration · $kcal سعرة';
  }

  @override
  String get homeYesterday => 'أمس';

  @override
  String get hpActivity => 'الخطوات والمسافة والسعرات';

  @override
  String get hpAuto => 'تُرسل البيانات الجديدة تلقائيًا بعد كل مزامنة للسوار.';

  @override
  String get hpBody => 'الوزن ونسبة الدهون ومؤشر كتلة الجسم';

  @override
  String get hpChooseTypes => 'البيانات المراد إرسالها';

  @override
  String hpConnect(Object platform) {
    return 'الاتصال بـ $platform';
  }

  @override
  String get hpConnected => 'متصل';

  @override
  String hpDenied(Object platform) {
    return 'لم يُمنح الإذن. يمكنك السماح به من إعدادات $platform.';
  }

  @override
  String get hpDisconnect => 'إيقاف الإرسال';

  @override
  String hpDisconnectNote(Object platform) {
    return 'تبقى البيانات المكتوبة في $platform؛ استخدم إعدادات $platform لحذفها.';
  }

  @override
  String get hpExportNow => 'إرسال الآن';

  @override
  String hpExported(Object records) {
    return 'تم إرسال $records';
  }

  @override
  String get hpHrv => 'تقلب نبض القلب (HRV)';

  @override
  String hpIntro(Object platform) {
    return 'تُكتب بيانات السوار في $platform، حيث يمكن لتطبيقات الصحة الأخرى في هاتفك رؤيتها. أنت تختار الأنواع التي تُرسل.';
  }

  @override
  String hpLastExport(Object time, Object records) {
    return 'آخر إرسال: $time · $records';
  }

  @override
  String get hpNever => 'لم يُرسل بعد';

  @override
  String get hpNotExported =>
      'لا يُرسل ضغط الدم لأنه تقديري. لا تقبل منصات الصحة تسجيلات تخطيط القلب من التطبيقات الأخرى.';

  @override
  String get hpNothingNew => 'لا توجد سجلات جديدة للإرسال';

  @override
  String hpPermissionNote(Object platform) {
    return 'عند المتابعة تفتح $platform شاشة الأذونات، ويمكنك الاختيار هناك أيضًا واحدًا تلو الآخر.';
  }

  @override
  String hpRecords(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سجل',
      many: '$count سجلًا',
      few: '$count سجلات',
      two: 'سجلان',
      one: 'سجل واحد',
      zero: 'لا سجلات',
    );
    return '$_temp0';
  }

  @override
  String get hpTitle => 'تطبيق الصحة';

  @override
  String hpUnavailable(Object platform) {
    return '$platform غير متوفر على هذا الهاتف. يمكنك تثبيته من Google Play.';
  }

  @override
  String get hpWorkouts => 'التمارين';

  @override
  String get hrvBeats => 'النبضات';

  @override
  String get hrvDetailEmpty => 'لا توجد قياسات ليلية للفاصل بين النبضات خلال الأسبوع الماضي. ارتدِ السوار أثناء النوم.';

  @override
  String hrvDetailNight(Object date) {
    return 'الليلة المنتهية صباح $date';
  }

  @override
  String get hrvDetailNote => 'يُحسب من الفواصل بين النبضات المقاسة ليلًا. يعكس RMSSD التقلب قصير المدى وSDNN التقلب العام؛ قارنه باتجاهك الخاص.';

  @override
  String get hrvDetailTitle => 'تفاصيل تقلب نبض القلب الليلي';

  @override
  String get hrvMeanHeartRate => 'متوسط النبض';

  @override
  String get hrvPnn50 => 'pNN50';

  @override
  String get hrvRmssd => 'RMSSD';

  @override
  String get hrvSdnn => 'SDNN';

  @override
  String get issueBusy => 'السوار مشغول بتمرين أو قياس آخر.';

  @override
  String get issueFailed =>
      'تعذر الاتصال بالسوار. تأكد من أنه قريب وقيد التشغيل.';

  @override
  String get issueNoEcgSignal =>
      'لم يتم استلام بيانات تخطيط القلب. ارتدِ السوار والمس القطب بإصبعك.';

  @override
  String get issueNoSpotSignal =>
      'تعذّر الحصول على قراءة. شدّ السوار قليلًا وحاول مرة أخرى.';

  @override
  String get issueNotPaired => 'أقرِن سوارك أولًا من الملف الشخصي > الجهاز.';

  @override
  String get languagePickHint => 'يمكنك تغييرها لاحقًا من شاشة الملف الشخصي.';

  @override
  String get languagePickTitle => 'اختر لغتك';

  @override
  String get languageSystem => 'لغة الهاتف';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get liveCancel => 'إلغاء';

  @override
  String get liveConfirmBody => 'سيُحفظ التمرين ويُعرض ملخصه.';

  @override
  String get liveConfirmTitle => 'إنهاء التمرين';

  @override
  String get liveContinue => 'استئناف';

  @override
  String get liveFinish => 'إنهاء';

  @override
  String liveInactiveBody(int minutes, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'مشيت أقل من $steps خطوة في آخر $minutes دقيقة. هل تريد إنهاء التمرين؟',
      few:
          'مشيت أقل من $steps خطوة في آخر $minutes دقائق. هل تريد إنهاء التمرين؟',
      two:
          'مشيت أقل من $steps خطوة في الدقيقتين الأخيرتين. هل تريد إنهاء التمرين؟',
      one: 'مشيت أقل من $steps خطوة في الدقيقة الأخيرة. هل تريد إنهاء التمرين؟',
    );
    return '$_temp0';
  }

  @override
  String get liveInactiveTitle => 'يبدو أنك توقفت عن الحركة';

  @override
  String get livePause => 'إيقاف مؤقت';

  @override
  String get livePaused => 'متوقف مؤقتًا';

  @override
  String get measureEcg => 'تخطيط القلب';

  @override
  String get measureEcgHint => 'بلمس القطب بإصبعك';

  @override
  String get measureHeartRate => 'نبض القلب';

  @override
  String get measureSheetTitle => 'ماذا تريد أن تقيس؟';

  @override
  String get measureSpo2 => 'أكسجين الدم (SpO2)';

  @override
  String measureTakes(Object seconds) {
    return 'يستغرق نحو $seconds ثانية';
  }

  @override
  String get metricBmi => 'مؤشر كتلة الجسم';

  @override
  String get metricBodyFat => 'نسبة الدهون';

  @override
  String get metricCalories => 'السعرات';

  @override
  String metricDetailAbove(Object value) {
    return '> $value';
  }

  @override
  String get metricDetailBands => 'النطاقات';

  @override
  String get metricDetailBpEstimate =>
      'قيمة ضغط الدم من السوار تقديرية. استخدم جهاز قياس ضغط معتمدًا للتشخيص والعلاج.';

  @override
  String get metricDetailDailyAverage => 'المتوسط اليومي';

  @override
  String get metricDetailNext => 'التالي';

  @override
  String get metricDetailNoData => 'لا توجد بيانات لهذه الفترة';

  @override
  String get metricDetailPrevious => 'السابق';

  @override
  String get metricDetailTotal => 'الإجمالي';

  @override
  String metricDetailWeekRange(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get metricDiastolic => 'ضغط الدم (الانبساطي)';

  @override
  String get metricDistance => 'المسافة';

  @override
  String get metricHeartRate => 'معدل ضربات القلب';

  @override
  String get metricHrv => 'تقلب معدل ضربات القلب';

  @override
  String get metricMuscleMass => 'الكتلة العضلية';

  @override
  String get metricPpi => 'الفاصل بين النبضات';

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
  String get metricWeight => 'الوزن';

  @override
  String get navExercise => 'التمارين';

  @override
  String get navHealth => 'الصحة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get navSemantics => 'القائمة الرئيسية';

  @override
  String get noValue => '--';

  @override
  String get pairBluetoothDenied => 'يلزم إذن البلوتوث للبحث عن السوار. اسمح به لهذا التطبيق من إعدادات الهاتف ثم حاول مرة أخرى.';

  @override
  String get pairBluetoothOff => 'البلوتوث متوقف. شغّل البلوتوث في هاتفك ثم حاول مرة أخرى.';

  @override
  String get pairBluetoothUnsupported => 'هذا الجهاز لا يدعم البلوتوث منخفض الطاقة الذي يستخدمه السوار.';

  @override
  String get pairCode => 'الإقران بالعنوان';

  @override
  String get pairCodeHint =>
      'أدخل العنوان المطبوع أسفل رمز QR على العلبة أو على ظهر السوار.';

  @override
  String get pairCodeInvalid =>
      'يتكون العنوان من 12 حرفًا، مثل A1:B2:C3:D4:E5:F6';

  @override
  String get pairCodeLabel => 'عنوان الجهاز';

  @override
  String get pairCodeNotFound => 'لم يتم العثور على سوار بهذا العنوان.';

  @override
  String get pairConnect => 'اتصال';

  @override
  String get pairConnected => 'تم توصيل السوار.';

  @override
  String get pairFound => 'الأساور التي تم العثور عليها';

  @override
  String get pairNoneFound =>
      'لم يتم العثور على سوار. تأكد من شحنه وقربه ثم حاول مرة أخرى.';

  @override
  String get pairNote =>
      'اشحن السوار وأبقه قريبًا من هاتفك. يجب أن يكون البلوتوث مفعّلًا.';

  @override
  String get pairQr => 'مسح رمز QR';

  @override
  String get pairQrHint => 'ضع رمز QR الموجود على العلبة أو خلف السوار داخل الإطار.';

  @override
  String get pairQrInvalid => 'لا يحتوي رمز QR هذا على عنوان سوار.';

  @override
  String get pairScan => 'بدء البحث';

  @override
  String get pairScanning => 'جارٍ البحث…';

  @override
  String pairSignal(Object rssi) {
    return 'الإشارة $rssi';
  }

  @override
  String get pairSubtitle => 'اربط سوارك لتصل قياساتك إلى هاتفك.';

  @override
  String get pairTitle => 'إقران السوار';

  @override
  String get periodDay => 'يوم';

  @override
  String get periodMonth => 'شهر';

  @override
  String get periodWeek => 'أسبوع';

  @override
  String get personalInfoTitle => 'المعلومات الشخصية';

  @override
  String get profileAge => 'العمر';

  @override
  String get profileConnectFirst => 'صِل السوار أولًا لحفظ بياناتك.';

  @override
  String profileDevice(Object mac) {
    return 'الجهاز: $mac';
  }

  @override
  String get profileFemale => 'أنثى';

  @override
  String get profileHeight => 'الطول';

  @override
  String get profileMale => 'ذكر';

  @override
  String get profileMenuAbout => 'حول التطبيق';

  @override
  String get profileMenuCommunity => 'مجتمع الصحة';

  @override
  String get profileMenuCommunitySubtitle => 'مجموعات العائلة وأذونات المشاركة';

  @override
  String get profileMenuDevice => 'الجهاز';

  @override
  String profileMenuDeviceConnected(Object battery) {
    return 'متصل · البطارية $battery٪';
  }

  @override
  String get profileMenuDeviceNone => 'لا يوجد سوار متصل';

  @override
  String get profileMenuExport => 'تصدير بياناتي';

  @override
  String get profileMenuExportSubtitle => 'ملف FHIR لطبيبك أو لتطبيق آخر';

  @override
  String get profileMenuFeedback => 'الملاحظات';

  @override
  String get profileMenuGeneral => 'الإعدادات العامة';

  @override
  String get profileMenuGeneralSubtitle => 'اللغة، تنسيق الوقت، الوحدات';

  @override
  String get profileMenuPersonalEmpty => 'أدخل عمرك وطولك ووزنك';

  @override
  String profileMenuPersonalSummary(Object age, Object height, Object weight) {
    return '$age سنة · $height سم · $weight كغ';
  }

  @override
  String get profileMenuResearch => 'الأطباء ومؤسسات البحث';

  @override
  String get profileMenuResearchSubtitle => 'مشاركة البيانات برمز دعوة';

  @override
  String get profileMenuThirdParty => 'ربط تطبيقات الصحة';

  @override
  String get profileMenuThirdPartySubtitle =>
      'إرسال البيانات إلى تطبيق الصحة في هاتفك';

  @override
  String get profileMenuVersion => 'إصدار التطبيق';

  @override
  String profileRangeError(Object min, Object max) {
    return 'يجب أن تكون القيمة بين $min و$max';
  }

  @override
  String get profileSave => 'حفظ';

  @override
  String get profileSaved => 'تم حفظ البيانات على السوار';

  @override
  String get profileSectionApp => 'التطبيق';

  @override
  String get profileSectionSettings => 'الإعدادات';

  @override
  String get profileSectionSharing => 'المشاركة والربط';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get profileUnitCm => 'سم';

  @override
  String get profileUnitKg => 'كغ';

  @override
  String get profileUnitYears => 'سنة';

  @override
  String get profileWeight => 'الوزن';

  @override
  String get qrCameraDenied => 'لم يُمنح إذن الكاميرا. اسمح به من إعدادات الهاتف أو أدخل الرمز يدويًا.';

  @override
  String get qrCameraUnavailable => 'تعذر فتح الكاميرا. يمكنك إدخال الرمز يدويًا.';

  @override
  String get qrManual => 'إدخال الرمز يدويًا';

  @override
  String get reminderAddMedication => 'إضافة موعد دواء';

  @override
  String get reminderAddWater => 'إضافة موعد شرب الماء';

  @override
  String get reminderAlarm => 'المنبّه';

  @override
  String reminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير',
      many: '$count تذكيرًا',
      few: '$count تذكيرات',
      two: 'تذكيران',
      one: 'تذكير واحد',
      zero: 'لا تذكيرات',
    );
    return '$_temp0';
  }

  @override
  String reminderCountSedentary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكير وتنبيه قلة الحركة',
      many: '$count تذكيرًا وتنبيه قلة الحركة',
      few: '$count تذكيرات وتنبيه قلة الحركة',
      two: 'تذكيران وتنبيه قلة الحركة',
      one: 'تذكير واحد وتنبيه قلة الحركة',
      zero: 'تنبيه قلة الحركة فقط',
    );
    return '$_temp0';
  }

  @override
  String get reminderDelete => 'حذف';

  @override
  String get reminderDuplicate =>
      'يوجد بالفعل تذكير من هذا النوع في هذا الوقت.';

  @override
  String get reminderEdit => 'تعديل التذكير';

  @override
  String get reminderEmptyMedication =>
      'أضف مواعيد دوائك؛ يهتز السوار في كل موعد.';

  @override
  String get reminderEmptyWater =>
      'أضف مواعيد ليذكّرك السوار بشرب الماء خلال اليوم.';

  @override
  String get reminderLabel => 'اسم الدواء (اختياري)';

  @override
  String get reminderLabelHint => 'مثال: دواء الصباح';

  @override
  String get reminderMedication => 'الدواء';

  @override
  String get reminderNewMedication => 'تذكير دواء جديد';

  @override
  String get reminderNewWater => 'تذكير ماء جديد';

  @override
  String get reminderSave => 'حفظ';

  @override
  String get reminderTime => 'الوقت';

  @override
  String get reminderWater => 'الماء';

  @override
  String get reminderWeekdays => 'أيام العمل';

  @override
  String get reminderWeekend => 'عطلة نهاية الأسبوع';

  @override
  String remindersFull(int max) {
    return 'يتسع السوار لـ $max تذكيرات كحد أقصى.';
  }

  @override
  String get remindersIntro =>
      'عند حلول موعد التذكير يهتز السوار؛ لا يظهر إشعار على الهاتف.';

  @override
  String get remindersLoadFailed => 'تعذّرت قراءة التذكيرات من السوار.';

  @override
  String get remindersNotConnected => 'وصّل السوار لعرض التذكيرات وتغييرها.';

  @override
  String get remindersSaveFailed =>
      'تعذّر حفظ التذكير في السوار. حاول مرة أخرى.';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String sedentaryHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعة',
      many: '$hours ساعة',
      few: '$hours ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String sedentaryHoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get sedentaryInterval => 'مدة عدم الحركة';

  @override
  String sedentaryMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String sedentaryNote(int steps) {
    return 'يصلك التنبيه إذا مشيت أقل من $steps خطوة خلال هذه المدة.';
  }

  @override
  String sedentarySubtitle(String time) {
    return 'يهتز السوار إذا لم تتحرك لمدة $time.';
  }

  @override
  String get sedentaryTitle => 'تنبيه قلة الحركة';

  @override
  String get shareActivity => 'النشاط والخطوات';

  @override
  String get shareBloodPressure => 'ضغط الدم (تقديري)';

  @override
  String get shareEcg => 'تسجيلات تخطيط القلب';

  @override
  String get shareHeartRate => 'نبض القلب';

  @override
  String get shareSleep => 'النوم';

  @override
  String get shareSpo2 => 'أكسجين الدم (SpO2)';

  @override
  String get shareStress => 'التوتر وتقلب نبض القلب';

  @override
  String get shareTemperature => 'حرارة الجسم';

  @override
  String get sleepAwake => 'مستيقظ';

  @override
  String get sleepDeep => 'عميق';

  @override
  String get sleepDuration => 'مدة النوم';

  @override
  String get sleepEmpty => 'لا توجد بيانات نوم بعد';

  @override
  String get sleepLast7Nights => 'آخر 7 ليالٍ';

  @override
  String get sleepLight => 'خفيف';

  @override
  String get sleepNextNight => 'الليلة التالية';

  @override
  String sleepPercent(Object value) {
    return '$value٪';
  }

  @override
  String get sleepPreviousNight => 'الليلة السابقة';

  @override
  String get sleepRem => 'حركة العين السريعة';

  @override
  String sleepTimeRange(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get sleepTitle => 'النوم';

  @override
  String sleepWeekBarHint(Object day, Object duration) {
    return '$day: $duration';
  }

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
  String get spotAgain => 'قِس مرة أخرى';

  @override
  String get spotDone => 'تم';

  @override
  String get spotKeepStill => 'ثبّت السوار على معصمك، وأسند ذراعك ولا تتحرك.';

  @override
  String get spotLowSpo2 =>
      'القيمة منخفضة. استرح وقِس مرة أخرى؛ وإذا بقيت منخفضة فاستشر طبيبك.';

  @override
  String get spotMeasuring => 'جارٍ القياس…';

  @override
  String get spotMoving => 'تم رصد حركة. أبقِ ذراعك ثابتة.';

  @override
  String get spotNote => 'قراءات السوار لا تغني عن الجهاز الطبي.';

  @override
  String get spotOffWrist => 'يبدو أن السوار ليس على معصمك. ارتدِه بإحكام.';

  @override
  String spotSaved(Object time) {
    return 'حُفظ القياس الساعة $time';
  }

  @override
  String get statAverage => 'المتوسط';

  @override
  String get statAvgHeartRate => 'متوسط النبض';

  @override
  String get statDuration => 'المدة';

  @override
  String get statMax => 'الأعلى';

  @override
  String get statMin => 'الأدنى';

  @override
  String get statPace => 'الوتيرة';

  @override
  String statPercent(Object value) {
    return '$value٪';
  }

  @override
  String get unitPerMinute => '/د';

  @override
  String get unitSteps => 'خطوة';

  @override
  String get unitsImperial => 'أمريكي (ميل، °ف)';

  @override
  String get unitsMetric => 'متري (كم، °م)';

  @override
  String get unitsTitle => 'الوحدات';

  @override
  String vo2MaxBasis(Object age, Object resting) {
    return 'بناءً على العمر $age ونبض الراحة $resting';
  }

  @override
  String get vo2MaxNeedsAge => 'يلزم عمرك للتقدير. اربط السوار وأدخله من الملف الشخصي > المعلومات الشخصية.';

  @override
  String get vo2MaxNeedsData => 'يلزم بضعة أيام من قياسات النبض أو القياسات الليلية لحساب نبض الراحة.';

  @override
  String get vo2MaxNote => 'يُقدَّر من نسبة أقصى نبض متوقع حسب العمر إلى نبض الراحة؛ وليس قياسًا مخبريًا. استخدمه لمتابعة اتجاه لياقتك.';

  @override
  String get vo2MaxTitle => 'الحد الأقصى المقدر لاستهلاك الأكسجين';

  @override
  String vo2MaxValue(Object value) {
    return '$value مل/كغ/دقيقة';
  }

  @override
  String get wearDetectionFailed => 'تعذّر تغيير كشف الارتداء في السوار.';

  @override
  String get wearDetectionSubtitle =>
      'ينبّهك أثناء القياس إذا نُزع السوار أو تحرّكت ذراعك.';

  @override
  String get wearDetectionTitle => 'كشف الارتداء';

  @override
  String get workoutCongrats => 'أحسنت! تم حفظ التمرين';

  @override
  String workoutTimeRange(Object day, Object start, Object end) {
    return '$day · $start - $end';
  }
}
