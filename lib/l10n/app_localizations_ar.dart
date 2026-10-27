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
  String get accountCodeCopied => 'تم نسخ رمز الاسترداد';

  @override
  String get accountCopy => 'نسخ';

  @override
  String get accountEraseButton => 'حذف';

  @override
  String get accountEraseConfirmTitle => 'هل تريد حذف بيانات البوابة؟';

  @override
  String get accountEraseInfo =>
      'تُحذف جميع القياسات المرفوعة إلى البوابة وتنتهي جميع مشاركاتك. تبقى البيانات على هاتفك. تُحفظ سجلات الوصول بسبب التزامات قانونية.';

  @override
  String get accountEraseTitle => 'حذف بياناتي في البوابة';

  @override
  String accountErased(int count) {
    return 'تم حذف $count من القياسات من البوابة.';
  }

  @override
  String get accountMenuSubtitle => 'رمز الاسترداد، استعادة الحساب';

  @override
  String get accountRecoveryInfo =>
      'إذا غيّرت هاتفك أو حذفت التطبيق، يعيد لك هذا الرمز اتصالاتك بالأطباء والمؤسسات. اكتبه في مكان آمن ولا تشاركه مع أحد.';

  @override
  String get accountRecoveryTitle => 'رمز الاسترداد';

  @override
  String get accountRenew => 'إنشاء رمز جديد';

  @override
  String get accountRenewConfirmBody => 'لن يعمل الرمز القديم بعد الآن.';

  @override
  String get accountRenewConfirmTitle => 'هل تريد إنشاء رمز جديد؟';

  @override
  String get accountRestoreButton => 'استعادة';

  @override
  String get accountRestoreConfirm => 'هل تريد استعادة الحساب؟';

  @override
  String get accountRestoreField => 'رمز الاسترداد';

  @override
  String get accountRestoreInfo =>
      'أدخل رمز الاسترداد من هاتفك القديم. سيحل حسابك القديم محل حساب البوابة على هذا الهاتف.';

  @override
  String get accountRestoreInvalid => 'الرمز غير صالح أو تم استخدامه من قبل.';

  @override
  String get accountRestoreTitle => 'استعادة حسابي';

  @override
  String get accountRestored => 'تمت استعادة حسابك.';

  @override
  String get accountTitle => 'حساب البوابة';

  @override
  String get achFirstEcg => 'أول تخطيط للقلب';

  @override
  String get achFirstEcgText => 'سجلت أول تخطيط للقلب.';

  @override
  String get achFirstSync => 'الخطوة الأولى';

  @override
  String get achFirstSyncText => 'وصلت أولى القياسات من السوار.';

  @override
  String get achGoalStreak7 => 'أسبوع بلا انقطاع';

  @override
  String get achGoalStreak7Text => 'بلوغ هدف الخطوات 7 أيام متتالية.';

  @override
  String get achMarathonWeek => 'أسبوع الماراثون';

  @override
  String get achMarathonWeekText => '42.2 كم في أسبوع واحد.';

  @override
  String get achSleepStreak7 => 'نوم منتظم';

  @override
  String get achSleepStreak7Text => '7 ساعات نوم على الأقل لـ7 ليالٍ متتالية.';

  @override
  String get achSteps10k => '10,000 خطوة';

  @override
  String get achSteps10kText => '10,000 خطوة في يوم واحد.';

  @override
  String get achSteps20k => '20,000 خطوة';

  @override
  String get achSteps20kText => '20,000 خطوة في يوم واحد.';

  @override
  String get achWear30 => 'مرتدٍ وفيّ';

  @override
  String get achWear30Text => 'ارتديت السوار في 30 يومًا مختلفًا.';

  @override
  String get achWorkouts10 => '10 تمارين';

  @override
  String get achWorkouts10Text => 'تسجيل 10 تمارين إجمالًا.';

  @override
  String achievementEarned(Object date) {
    return 'حُصل عليها في $date';
  }

  @override
  String get achievementProgress => 'التقدم';

  @override
  String get achievementsTitle => 'الشارات';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get allDayHeartRateFailed =>
      'تعذر حفظ الإعداد على السوار. حاول مرة أخرى.';

  @override
  String get allDayHeartRateSubtitle =>
      'عند إيقافها لا يسجّل السوار نبضك خلال اليوم.';

  @override
  String get allDayHeartRateTitle => 'متابعة النبض طوال اليوم';

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
  String get communityAccept => 'انضمام';

  @override
  String get communityAlertsBody =>
      'إذا انخفض أو ارتفع نبضك أو SpO2 أو ضغط الدم أو حرارة الجسم التي تشاركها لفترة طويلة، يرى أعضاء المجموعة تنبيهًا في التطبيق. التنبيه ليس تشخيصًا.';

  @override
  String get communityAlertsNeedScope =>
      'شارك أولًا النبض أو SpO2 أو ضغط الدم أو حرارة الجسم.';

  @override
  String get communityAlertsTitle => 'نبّه المجموعة في حالة طارئة';

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
  String get communityUnnamedMember => 'عضو';

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
  String get connScanHint =>
      'ضع رمز QR الذي حصلت عليه من طبيبك أو من مؤسسة البحث داخل الإطار.';

  @override
  String get connSelectAll => 'تحديد الكل';

  @override
  String get connServerError =>
      'تعذر الوصول إلى الخادم. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';

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
  String get deviceFirmware => 'إصدار البرنامج الثابت';

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
  String energyDayTitle(Object date) {
    return 'الطاقة في $date';
  }

  @override
  String get energyDrain => 'المستهلك خلال اليوم';

  @override
  String get energyEmpty =>
      'تحتاج الطاقة إلى نوم الليلة الماضية أو قياس لتقلب نبض القلب.';

  @override
  String get energyHigh => 'طاقتك مرتفعة';

  @override
  String get energyLow => 'طاقتك منخفضة؛ خصص وقتًا للراحة';

  @override
  String get energyMedium => 'طاقتك متوسطة';

  @override
  String get energyNote =>
      'تملأ مدة النوم وعمقه وتقلب نبض القلب مقارنةً بالأسبوعين الماضيين طاقتك، وتستهلكها الخطوات والتوتر خلال اليوم. هذا تقدير التطبيق وليس قياسًا طبيًا.';

  @override
  String get energyRecovery => 'التعافي';

  @override
  String energySemantics(Object score, Object level) {
    return 'الطاقة $score/100، $level';
  }

  @override
  String get energySleep => 'النوم';

  @override
  String get energyTitle => 'الطاقة';

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
  String get exportIntro =>
      'تُجهَّز قياساتك في ملف بصيغة FHIR R4، وهي الصيغة المشتركة للأنظمة الصحية. يمكنك إرساله إلى طبيبك أو فتحه في تطبيق يقرأ هذه الصيغة.';

  @override
  String get exportPeriod => 'الفترة';

  @override
  String get exportPrivacy =>
      'يحتوي الملف على بيانات صحية. شاركه فقط مع أشخاص ومؤسسات تثق بها. لا يتضمن الملف اسمك، بل معرّفًا مستعارًا خاصًا بهذا الهاتف فقط.';

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
  String familyAlertBloodPressure(
    String name,
    String systolic,
    String diastolic,
  ) {
    return '$name: ضغط دم مرتفع جدًا ($systolic/$diastolic، تقديري)';
  }

  @override
  String familyAlertFever(String name, String value) {
    return '$name: حمى ($value)';
  }

  @override
  String familyAlertHeartRateHigh(String name, String value) {
    return '$name: نبض مرتفع (الأعلى $value نبضة/د)';
  }

  @override
  String familyAlertHeartRateLow(String name, String value) {
    return '$name: نبض منخفض (الأدنى $value نبضة/د)';
  }

  @override
  String get familyAlertNote =>
      'هذا تنبيه تلقائي وليس تشخيصًا. إذا لم تستطع الوصول إليه وكان الأمر طارئًا فاتصل برقم الطوارئ المحلي.';

  @override
  String familyAlertSpo2Low(String name, String value) {
    return '$name: انخفاض SpO2 (الأدنى $value٪)';
  }

  @override
  String familyAlertTime(String start, String end) {
    return '$start – $end';
  }

  @override
  String get familyAlertTitle => 'تنبيه عائلي';

  @override
  String feedbackDetailsValue(String version, String platform) {
    return 'الإصدار $version · $platform';
  }

  @override
  String get feedbackIncludeDetails => 'إرفاق معلومات الإصدار والجهاز';

  @override
  String get feedbackIntro =>
      'هل وجدت خطأ أو لديك اقتراح؟ اكتب لنا وسننقله إلى الفريق.';

  @override
  String get feedbackMessageHint => 'ماذا حدث، وماذا كنت تتوقع؟';

  @override
  String get feedbackMessageLabel => 'رسالتك';

  @override
  String get feedbackPrivacy =>
      'لا يتم إرسال اسمك أو هويتك أو بياناتك الصحية. يُرجى عدم كتابة معلومات شخصية.';

  @override
  String get feedbackSend => 'إرسال';

  @override
  String get feedbackThanks => 'شكرًا، تم استلام ملاحظاتك.';

  @override
  String get feedbackTopicBug => 'خطأ';

  @override
  String get feedbackTopicIdea => 'اقتراح';

  @override
  String get feedbackTopicOther => 'أخرى';

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
  String get hrvDetailEmpty =>
      'لا توجد قياسات ليلية للفاصل بين النبضات خلال الأسبوع الماضي. ارتدِ السوار أثناء النوم.';

  @override
  String hrvDetailNight(Object date) {
    return 'الليلة المنتهية صباح $date';
  }

  @override
  String get hrvDetailNote =>
      'يُحسب من الفواصل بين النبضات المقاسة ليلًا. يعكس RMSSD التقلب قصير المدى وSDNN التقلب العام؛ قارنه باتجاهك الخاص.';

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
  String get pairBluetoothDenied =>
      'يلزم إذن البلوتوث للبحث عن السوار. اسمح به لهذا التطبيق من إعدادات الهاتف ثم حاول مرة أخرى.';

  @override
  String get pairBluetoothOff =>
      'البلوتوث متوقف. شغّل البلوتوث في هاتفك ثم حاول مرة أخرى.';

  @override
  String get pairBluetoothUnsupported =>
      'هذا الجهاز لا يدعم البلوتوث منخفض الطاقة الذي يستخدمه السوار.';

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
  String get pairQrHint =>
      'ضع رمز QR الموجود على العلبة أو خلف السوار داخل الإطار.';

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
  String get privacyAuditBody =>
      'يُسجَّل كل وصول إلى بياناتك في البوابة، بما في ذلك المحاولات المرفوضة. يمكنك أن ترى في التطبيق من اطلع ومتى.';

  @override
  String get privacyAuditTitle => 'سجل الوصول';

  @override
  String get privacyContactBody =>
      'سيظهر هنا قبل النشر اسم المسؤول عن البيانات وعنوانه وطريقة تقديم الطلب. يمكنك أيضًا مراسلتنا من التطبيق عبر الملف الشخصي > الملاحظات.';

  @override
  String get privacyContactTitle => 'التواصل';

  @override
  String get privacyDataBody =>
      'ما يقيسه السوار: نبض القلب وتقلبه (HRV) وأكسجين الدم (SpO2) وتخطيط القلب والنوم والخطوات والتمارين وحرارة الجسم والتوتر وضغط الدم التقديري. ما تدخله أنت: العمر والطول والوزن والجنس وتكوين الجسم والتذكيرات. عنوان البلوتوث للسوار. لا نطلب اسمك أو رقم هويتك أو هاتفك أو بريدك الإلكتروني؛ تُعرف في البوابة باسم مستعار عشوائي فقط. إذا ملأت نموذج الشراكة على موقعنا، يُحفظ اسمك وجهتك وبريدك الإلكتروني ورسالتك مشفّرة فقط للرد عليك، ولا تُدمج مع البيانات الصحية. نموذج التسجيل المسبق يأخذ بريدك الإلكتروني فقط، ويُستخدم لإعلان واحد عند وصول التطبيق إلى المتاجر.';

  @override
  String get privacyDataTitle => 'ما البيانات التي نعالجها؟';

  @override
  String get privacyDraft =>
      'مسودة: لم تتم مراجعة هذا النص قانونيًا. سيُضاف اسم المسؤول عن البيانات وعنوانه ومدد الاحتفاظ قبل النشر.';

  @override
  String get privacyIntro =>
      'يوضح هذا النص كيف يعالج تطبيق Bileklik وبوابته بياناتك الشخصية وفق قانون حماية البيانات الشخصية التركي رقم 6698 (KVKK).';

  @override
  String get privacyLegalBody =>
      'البيانات الصحية فئة خاصة من البيانات الشخصية وتُعالج بموافقتك الصريحة (المادة 6 من KVKK). كل مشاركة تحتاج إلى موافقة مستقلة: تختار من يرى أي الأنواع ولأي مدة، ويمكنك سحب موافقتك في أي وقت.';

  @override
  String get privacyLegalTitle => 'الأساس القانوني';

  @override
  String get privacyPurposeBody =>
      'لعرض قياساتك عليك، ومشاركتها مع الأطباء ومؤسسات البحث وأفراد العائلة الذين تختارهم، وكتابتها في Apple Health أو Health Connect إن رغبت. لا تُستخدم بياناتك للإعلانات ولا تُباع.';

  @override
  String get privacyPurposeTitle => 'لماذا نعالجها؟';

  @override
  String get privacyRetentionBody =>
      'تبقى البيانات على هاتفك حتى تحذف التطبيق. تبقى القياسات في البوابة حتى تحذفها؛ وعند انتهاء الموافقة لا يعود المتابع يراها. تُحفظ سجلات الوصول بعد الحذف بسبب التزامات الاحتفاظ القانونية.';

  @override
  String get privacyRetentionTitle => 'كم مدة الاحتفاظ؟';

  @override
  String get privacyRightsBody =>
      'بموجب المادة 11 من KVKK يمكنك أن تسأل إن كانت بياناتك تُعالج، وأن تطلب تصحيحها أو حذفها، وأن تسحب موافقتك. في التطبيق يمكنك إزالة المشاركة من الملف الشخصي > الأطباء ومؤسسات البحث والملف الشخصي > مجتمع الصحة، وحذف بياناتك في البوابة من الملف الشخصي > حساب البوابة، والحصول على جميع بياناتك كملف FHIR من الملف الشخصي > تصدير بياناتي.';

  @override
  String get privacyRightsTitle => 'حقوقك';

  @override
  String get privacySharingBody =>
      'فقط مع الأطباء أو مؤسسات البحث أو أفراد مجموعة العائلة الذين توافق عليهم، وللأنواع التي تختارها فقط وطوال مدة الموافقة. القيم التي تدخلها بنفسك مثل الوزن وتكوين الجسم لا تُشارك إلا إذا اخترت «قياسات الجسم» صراحةً. لا يُكتب في Apple Health أو Health Connect إلا ما تختاره، ولا يقرأ التطبيق منهما. الملاحظات لا ترتبط بهويتك. عندما يظهر تغيّر واضح في الأنواع التي تشاركها (مثلًا انخفاض SpO2 لفترة طويلة أو عدم وصول بيانات منذ يوم)، تعرض البوابة على طبيبك تنبيهًا تلقائيًا؛ هذه التنبيهات ليست تشخيصًا وتُحذف عند حذف بياناتك من البوابة. إذا فعّلت أيضًا «نبّه المجموعة في حالة طارئة» لمجموعة عائلية، تظهر التنبيهات نفسها للأنواع التي تشاركها مع تلك المجموعة لأعضائها.';

  @override
  String get privacySharingTitle => 'مع من تُشارك؟';

  @override
  String get privacyStorageBody =>
      'تُحفظ القياسات على هاتفك في قاعدة بيانات مشفرة، ومفتاحها في المنطقة الآمنة للهاتف (iOS Keychain وAndroid Keystore). لا تدخل هذه البيانات في نسخ الهاتف الاحتياطية. لا يُرسل إلى البوابة إلا الأنواع التي تختار مشاركتها، وتُحفظ هناك مشفرة أيضًا.';

  @override
  String get privacyStorageTitle => 'أين تُحفظ البيانات؟';

  @override
  String get privacyTitle => 'سياسة الخصوصية';

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
  String get progressTitle => 'التقدم';

  @override
  String get qrCameraDenied =>
      'لم يُمنح إذن الكاميرا. اسمح به من إعدادات الهاتف أو أدخل الرمز يدويًا.';

  @override
  String get qrCameraUnavailable =>
      'تعذر فتح الكاميرا. يمكنك إدخال الرمز يدويًا.';

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
  String get reminderLabelNote => 'يُحفظ على السوار بالأحرف اللاتينية فقط.';

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
  String get reportAverageSteps => 'متوسط الخطوات اليومي';

  @override
  String get reportDown => 'انخفض';

  @override
  String get reportEmpty => 'لا توجد بيانات لهذا الأسبوع.';

  @override
  String get reportGoalDays => 'أيام بلوغ الهدف';

  @override
  String get reportHrv => 'متوسط تقلب نبض القلب';

  @override
  String get reportSleep => 'متوسط النوم';

  @override
  String get reportSteps => 'إجمالي الخطوات';

  @override
  String get reportStress => 'متوسط التوتر';

  @override
  String get reportUp => 'ارتفع';

  @override
  String get reportVsPrevious => 'تُظهر الأسهم التغير مقارنةً بالأسبوع السابق.';

  @override
  String get reportWorkouts => 'التمارين';

  @override
  String reportWorkoutsValue(Object count, Object time) {
    return '$count مرات · $time';
  }

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
  String get shareRespiration => 'معدل التنفس';

  @override
  String get shareBody => 'قياسات الجسم (الوزن، مؤشر الكتلة)';

  @override
  String get connUnverified =>
      'لم تتحقق البوابة من حساب هذا الطبيب بعد. تابع فقط إذا كنت تعرف هذا الشخص وحصلت على الرمز منه.';

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
  String get vo2MaxNeedsAge =>
      'يلزم عمرك للتقدير. اربط السوار وأدخله من الملف الشخصي > المعلومات الشخصية.';

  @override
  String get vo2MaxNeedsData =>
      'يلزم بضعة أيام من قياسات النبض أو القياسات الليلية لحساب نبض الراحة.';

  @override
  String get vo2MaxNote =>
      'يُقدَّر من نسبة أقصى نبض متوقع حسب العمر إلى نبض الراحة؛ وليس قياسًا مخبريًا. استخدمه لمتابعة اتجاه لياقتك.';

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
  String get weeklyReportTitle => 'التقرير الأسبوعي';

  @override
  String get workoutCongrats => 'أحسنت! تم حفظ التمرين';

  @override
  String workoutTimeRange(Object day, Object start, Object end) {
    return '$day · $start - $end';
  }

  @override
  String get zonesTitle => 'مناطق نبض القلب';

  @override
  String get zoneWarmUp => 'الإحماء';

  @override
  String get zoneFatBurn => 'حرق الدهون';

  @override
  String get zoneAerobic => 'هوائي';

  @override
  String get zoneAnaerobic => 'لاهوائي';

  @override
  String get zoneMaximum => 'الحد الأقصى';

  @override
  String get zonesNeedsAge => 'أدخل عمرك في المعلومات الشخصية لعرض المناطق.';

  @override
  String get zonesEmpty => 'لا يوجد نبض فوق منطقة الإحماء في هذه الفترة.';

  @override
  String zonesNote(String max) {
    return 'تم تقدير الحد الأقصى لنبضك من عمرك: $max (208 − 0.7 × العمر). المناطق نسب مئوية منه.';
  }

  @override
  String zoneSemantics(String zone, String range, String time) {
    return '$zone، $range: $time';
  }

  @override
  String get tempDevTitle => 'مقارنةً بحرارتك المعتادة';

  @override
  String tempDevBaseline(String value, int days, String from, String to) {
    return 'حرارتك المعتادة $value: متوسط أول $days أيام بها قياسات ($from – $to).';
  }

  @override
  String tempDevNeedsData(int days) {
    return 'يلزم قياس لمدة $days أيام على الأقل لتحديد حرارتك المعتادة.';
  }

  @override
  String tempDevAverage(String value) {
    return 'الفرق في هذه الفترة: $value';
  }

  @override
  String get tempDevNote =>
      'تختلف حرارة المعصم عن حرارة الجسم الداخلية؛ استخدمها لمتابعة التغيّر فقط.';

  @override
  String get bioAgeTitle => 'العمر البيولوجي';

  @override
  String bioAgeChronological(int age) {
    return 'عمرك الزمني $age';
  }

  @override
  String bioAgeYounger(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'أصغر بـ $years سنة',
      few: 'أصغر بـ $years سنوات',
      two: 'أصغر بسنتين',
      one: 'أصغر بسنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String bioAgeOlder(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'أكبر بـ $years سنة',
      few: 'أكبر بـ $years سنوات',
      two: 'أكبر بسنتين',
      one: 'أكبر بسنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get bioAgeSame => 'مماثل لعمرك الزمني';

  @override
  String get bioAgeNeedsAge =>
      'أدخل عمرك في المعلومات الشخصية (18–90) لعرض عمرك البيولوجي.';

  @override
  String bioAgeNeedsData(int days) {
    return 'يحتاج العمر البيولوجي إلى بيانات النبض والخطوات أو النوم في $days أيام على الأقل من آخر 21 يومًا.';
  }

  @override
  String get bioAgeRestingHr => 'نبض الراحة';

  @override
  String get bioAgeSteps => 'الخطوات اليومية';

  @override
  String get bioAgeSleep => 'نوم الليل';

  @override
  String get bioAgeBmi => 'مؤشر كتلة الجسم';

  @override
  String bioAgeYears(String value) {
    return '$value سنة';
  }

  @override
  String get bioAgeTrend => 'آخر 8 أسابيع';

  @override
  String get bioAgeNote =>
      'تقدير خاص بالتطبيق من نبض الراحة والخطوات والنوم ومؤشر كتلة الجسم خلال آخر 21 يومًا؛ وليس قياسًا طبيًا.';

  @override
  String bioAgeSemantics(int age, String difference) {
    return 'العمر البيولوجي $age، $difference';
  }

  @override
  String get radarTitle => 'رادار الصحة';

  @override
  String radarCollecting(int nights, int needed) {
    return 'جارٍ التعرّف على قيمك المعتادة: $nights/$needed ليالٍ.';
  }

  @override
  String get radarNoTonight =>
      'لا توجد بيانات من الليلة الماضية. ارتدِ السوار ليلًا ليعمل الرادار.';

  @override
  String get radarAllClear => 'كانت الليلة الماضية ضمن نطاقك المعتاد.';

  @override
  String get radarWatch => 'اختلفت قيمة واحدة من الليلة الماضية عن المعتاد.';

  @override
  String get radarStrong =>
      'تغيّرت عدة قيم معًا. خذ قسطًا من الراحة اليوم، واستشر طبيبًا إن شعرت بتوعك.';

  @override
  String radarHeartRateUp(String value, String base) {
    return 'نبض الليل $value، المعتاد $base';
  }

  @override
  String radarHrvDown(String value, String base) {
    return 'HRV الليل $value، المعتاد $base';
  }

  @override
  String radarTemperatureUp(String value, String base) {
    return 'حرارة الليل $value، المعتاد $base';
  }

  @override
  String radarSpo2Down(String value, String base) {
    return 'أكسجين الليل $value، المعتاد $base';
  }

  @override
  String get radarNote =>
      'تُقارن كل ليلة بآخر 14 ليلة لديك. لا يقدّم تشخيصًا. إذا شعرت بألم في الصدر أو ضيق في التنفس أو دوار، فاتصل برقم الطوارئ المحلي.';

  @override
  String get aiReportTitle => 'تقرير الذكاء الاصطناعي';

  @override
  String get aiReportCardText => 'تقرير شخصي عن أسبوعك مع نصائح.';

  @override
  String get aiDemoBadge => 'تجريبي';

  @override
  String get aiDemoNote =>
      'هذا تقرير تجريبي: الذكاء الاصطناعي غير متصل بعد، لذا كتبت قواعد داخل التطبيق النص. لم تغادر بياناتك هاتفك.';

  @override
  String get aiConsentTitle => 'إذن لتحليل الذكاء الاصطناعي';

  @override
  String get aiConsentIntro =>
      'يكتب نموذج ذكاء اصطناعي التقرير الأسبوعي. لذلك يُرسل ملخص أسبوعك إلى خادمنا ومنه إلى مزوّد الذكاء الاصطناعي.';

  @override
  String get aiConsentSentTitle => 'ما يُرسل';

  @override
  String get aiConsentSent =>
      'الفئة العمرية والجنس؛ المتوسطات الأسبوعية للخطوات والنوم والنبض وتقلب نبض القلب والتوتر والتمارين؛ إشارات رادار الصحة.';

  @override
  String get aiConsentNotSentTitle => 'ما لا يُرسل';

  @override
  String get aiConsentNotSent =>
      'اسمك وبيانات الاتصال وعنوان السوار وتسجيلات تخطيط القلب الخام والقياسات الفردية.';

  @override
  String get aiConsentAbroad =>
      'مزوّد الذكاء الاصطناعي خارج البلاد (الولايات المتحدة)، لذا يُنقل الملخص إلى الخارج. لا يستخدم المزوّد هذه البيانات لتدريب النماذج.';

  @override
  String get aiConsentLimits =>
      'لا يشخّص التقرير ولا يوصي بأدوية، ولا يغني عن فحص الطبيب.';

  @override
  String get aiConsentRevoke =>
      'يمكنك سحب الإذن من هذه الشاشة في أي وقت. بعد ذلك لا تُكتب تقارير جديدة.';

  @override
  String get aiConsentCheck =>
      'أوافق صراحةً على نقل ملخصي الأسبوعي إلى الخارج لتحليله بالذكاء الاصطناعي.';

  @override
  String get aiConsentAccept => 'السماح';

  @override
  String get aiConsentDecline => 'ليس الآن';

  @override
  String get aiGenerate => 'إنشاء التقرير';

  @override
  String get aiRegenerate => 'إنشاء من جديد';

  @override
  String get aiGenerating => 'جارٍ إعداد التقرير…';

  @override
  String aiWeek(String start, String end) {
    return 'أسبوع $start – $end';
  }

  @override
  String get aiEmpty =>
      'لا توجد بيانات كافية هذا الأسبوع لإعداد تقرير. ارتدِ السوار وزامنه لبضعة أيام.';

  @override
  String get aiSummaryTitle => 'الملخص';

  @override
  String get aiWinsTitle => 'ما يسير جيدًا';

  @override
  String get aiWatchTitle => 'ما يستحق الانتباه';

  @override
  String get aiTipsTitle => 'اقتراحات';

  @override
  String get aiNothing => 'لا شيء لافت هذا الأسبوع.';

  @override
  String get aiDisclaimer =>
      'هذا التقرير للمعلومات فقط، ولا يشخّص ولا يقترح علاجًا. إذا كانت لديك أعراض فاستشر طبيبك. عند ألم الصدر أو ضيق التنفس أو الشعور بالإغماء اتصل برقم الطوارئ.';

  @override
  String get aiDataTitle => 'البيانات المستخدمة';

  @override
  String get aiDataNote => 'في التقرير الفعلي يُرسل هذا الملخص فقط إلى الخادم.';

  @override
  String get aiRevoke => 'سحب الإذن';

  @override
  String get aiRevoked => 'تم سحب الإذن.';

  @override
  String aiConsentGiven(String date) {
    return 'تاريخ الإذن: $date';
  }

  @override
  String aiStepsGood(int steps) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'مشيت في المتوسط $stepsString خطوة يوميًا، وهذا فوق هدفك.';
  }

  @override
  String aiStepsLow(int steps) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'كان متوسطك اليومي $stepsString خطوة، أقل من هدف الحركة.';
  }

  @override
  String aiStepsUp(int percent) {
    return 'زادت خطواتك بنسبة $percent% عن الأسبوع الماضي.';
  }

  @override
  String aiStepsDown(int percent) {
    return 'انخفضت خطواتك بنسبة $percent% عن الأسبوع الماضي.';
  }

  @override
  String aiSleepGood(int hours, int minutes) {
    return 'نمت في المتوسط $hours س $minutes د كل ليلة، ضمن المدى الصحي.';
  }

  @override
  String aiSleepShort(int hours, int minutes) {
    return 'نمت في المتوسط $hours س $minutes د كل ليلة، أقل من 7 ساعات.';
  }

  @override
  String aiHrvUp(int percent) {
    return 'ارتفع تقلب نبض قلبك بنسبة $percent% عن الأسبوع الماضي، وهي علامة على تعافٍ جيد.';
  }

  @override
  String aiHrvDown(int percent) {
    return 'انخفض تقلب نبض قلبك بنسبة $percent% عن الأسبوع الماضي، وقد يكون علامة على التعب أو التوتر.';
  }

  @override
  String aiStressHigh(int level) {
    return 'كان متوسط مستوى التوتر لديك $level، وكان معظم الأسبوع مرتفعًا.';
  }

  @override
  String aiWorkoutsGood(int count, int minutes) {
    return '$count تمارين بمجموع $minutes دقيقة: أنت تتحرك بانتظام.';
  }

  @override
  String get aiRadar =>
      'رصد رادار الصحة الليلة الماضية قيمًا تختلف عن المعتاد لديك.';

  @override
  String aiBioYounger(int years) {
    return 'عمرك البيولوجي المقدّر أصغر من عمرك الفعلي بـ $years سنة.';
  }

  @override
  String aiBioOlder(int years) {
    return 'عمرك البيولوجي المقدّر أكبر من عمرك الفعلي بـ $years سنة.';
  }

  @override
  String get aiTipWalk =>
      'أضف نزهتين قصيرتين من 10 إلى 15 دقيقة يوميًا واستخدم الدرج.';

  @override
  String get aiTipSleep =>
      'حاول النوم والاستيقاظ في الوقت نفسه يوميًا، وابتعد عن الشاشات قبل النوم بساعة.';

  @override
  String get aiTipRecover =>
      'اختر هذا الأسبوع المشي الخفيف والتمدد بدل التمارين الشاقة، واجعل النوم أولوية.';

  @override
  String get aiTipBreathe =>
      'خذ عدة استراحات تنفس بطيء لمدة دقيقتين خلال اليوم (شهيق 4 ثوانٍ، زفير 6).';

  @override
  String get aiTipMove =>
      'استهدف 150 دقيقة على الأقل من النشاط المعتدل أسبوعيًا؛ الفترات القصيرة تُحتسب أيضًا.';

  @override
  String get aiTipRadar =>
      'خذ قسطًا من الراحة اليوم واشرب الكثير من الماء. إذا لم تشعر بتحسن فاستشر طبيبك.';

  @override
  String get aiTipKeep =>
      'واصل على هذا النحو، وارتدِ السوار ليلًا أيضًا لتبقى بيانات النوم والتعافي كاملة.';

  @override
  String get aiSummaryGood =>
      'كان أسبوعك جيدًا بشكل عام، ولا يظهر ما يدعو للقلق.';

  @override
  String get aiSummaryMixed =>
      'كان أسبوعًا متوازنًا: بعض العادات تسير جيدًا، وهناك أمور قليلة تستحق الانتباه.';

  @override
  String get aiSummaryCare =>
      'يحتاج جسمك إلى مزيد من العناية هذا الأسبوع؛ قد تساعدك الاقتراحات أدناه.';

  @override
  String aiSummaryFewDays(int days) {
    return 'توجد بيانات $days يوم فقط هذا الأسبوع، لذا يعرض التقرير صورة محدودة.';
  }

  @override
  String get premiumTitle => 'Bileklik Premium';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get premiumSubtitle => 'استفد أكثر من بياناتك.';

  @override
  String get premiumBenefitReport => 'تقرير صحي أسبوعي بالذكاء الاصطناعي';

  @override
  String get premiumBenefitCoaching => 'نصائح تدريب شخصية';

  @override
  String get premiumBenefitFree =>
      'تبقى القياسات والسجل والمشاركة والتنبيهات مجانية';

  @override
  String get premiumMonthly => 'شهري';

  @override
  String get premiumYearly => 'سنوي';

  @override
  String premiumPerMonth(String price) {
    return '$price / شهر';
  }

  @override
  String premiumPerYear(String price) {
    return '$price / سنة';
  }

  @override
  String premiumSave(int percent) {
    return 'وفّر $percent٪';
  }

  @override
  String get premiumSubscribe => 'اشترك';

  @override
  String get premiumRestore => 'استعادة المشتريات';

  @override
  String get premiumRestoreNone => 'لا توجد مشتريات لاستعادتها.';

  @override
  String get premiumRestored => 'تمت استعادة الشراء.';

  @override
  String get premiumTerms =>
      'يتجدد الاشتراك تلقائيًا في نهاية كل فترة. يمكنك الإلغاء في أي وقت من حساب المتجر، وبعد الإلغاء يستمر Premium حتى نهاية الفترة.';

  @override
  String get premiumDemoNote =>
      'تجريبي: سيتم الدفع لاحقًا عبر App Store أو Google Play. لا يُؤخذ أي دفع حقيقي في هذا الإصدار، والأسعار أمثلة.';

  @override
  String get storeSheetTitle => 'متجر تجريبي';

  @override
  String storeSheetItem(String plan) {
    return 'Bileklik Premium · $plan';
  }

  @override
  String get storeSheetNote => 'لن يُؤخذ أي دفع حقيقي.';

  @override
  String get storeConfirm => 'تأكيد';

  @override
  String get storeCancel => 'إلغاء';

  @override
  String get premiumActive => 'تم تفعيل Premium. شكرًا لك!';

  @override
  String get subscriptionTitle => 'الاشتراك';

  @override
  String get subscriptionFree => 'مجاني';

  @override
  String subscriptionPremium(String plan) {
    return 'Premium · $plan';
  }

  @override
  String subscriptionRenews(String date) {
    return 'يتجدد في $date';
  }

  @override
  String subscriptionEnds(String date) {
    return 'ينتهي في $date';
  }

  @override
  String get subscriptionUpgrade => 'الترقية إلى Premium';

  @override
  String get subscriptionCancel => 'إلغاء الاشتراك';

  @override
  String subscriptionCancelConfirm(String date) {
    return 'لن يتجدد الاشتراك؛ يستمر Premium حتى $date.';
  }

  @override
  String get subscriptionCancelled => 'تم إلغاء الاشتراك.';

  @override
  String get subscriptionKeep => 'الإبقاء على الاشتراك';

  @override
  String get subscriptionFreeText =>
      'القياسات والسجل والمشاركة والتنبيهات مجانية. يتوفر تقرير الذكاء الاصطناعي مع Premium.';
}
