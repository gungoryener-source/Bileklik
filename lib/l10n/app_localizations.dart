import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @aboutDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik, JCV8 EKG bilekliğinizin ölçümlerini telefonunuzda gösterir.'**
  String get aboutDescription;

  /// No description provided for @aboutLicenses.
  ///
  /// In tr, this message translates to:
  /// **'Açık kaynak lisansları'**
  String get aboutLicenses;

  /// No description provided for @aboutMedical.
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulama tıbbi cihaz değildir; teşhis ve tedavi için hekiminize danışın. Tansiyon değerleri tahminidir.'**
  String get aboutMedical;

  /// No description provided for @aboutPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümleriniz yalnızca bu telefonda tutulur. Paylaşım geldiğinde kimin neyi göreceğine siz karar vereceksiniz (KVKK).'**
  String get aboutPrivacy;

  /// No description provided for @aboutVersion.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version}'**
  String aboutVersion(Object version);

  /// No description provided for @achFirstEcg.
  ///
  /// In tr, this message translates to:
  /// **'İlk EKG'**
  String get achFirstEcg;

  /// No description provided for @achFirstEcgText.
  ///
  /// In tr, this message translates to:
  /// **'İlk EKG kaydınızı aldınız.'**
  String get achFirstEcgText;

  /// No description provided for @achFirstSync.
  ///
  /// In tr, this message translates to:
  /// **'İlk adım'**
  String get achFirstSync;

  /// No description provided for @achFirstSyncText.
  ///
  /// In tr, this message translates to:
  /// **'Bileklikten ilk ölçümler geldi.'**
  String get achFirstSyncText;

  /// No description provided for @achGoalStreak7.
  ///
  /// In tr, this message translates to:
  /// **'Bir hafta durmadan'**
  String get achGoalStreak7;

  /// No description provided for @achGoalStreak7Text.
  ///
  /// In tr, this message translates to:
  /// **'7 gün art arda adım hedefi.'**
  String get achGoalStreak7Text;

  /// No description provided for @achMarathonWeek.
  ///
  /// In tr, this message translates to:
  /// **'Maraton haftası'**
  String get achMarathonWeek;

  /// No description provided for @achMarathonWeekText.
  ///
  /// In tr, this message translates to:
  /// **'Bir haftada 42,2 km.'**
  String get achMarathonWeekText;

  /// No description provided for @achSleepStreak7.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli uyku'**
  String get achSleepStreak7;

  /// No description provided for @achSleepStreak7Text.
  ///
  /// In tr, this message translates to:
  /// **'7 gece art arda en az 7 saat uyku.'**
  String get achSleepStreak7Text;

  /// No description provided for @achSteps10k.
  ///
  /// In tr, this message translates to:
  /// **'10.000 adım'**
  String get achSteps10k;

  /// No description provided for @achSteps10kText.
  ///
  /// In tr, this message translates to:
  /// **'Bir günde 10.000 adım.'**
  String get achSteps10kText;

  /// No description provided for @achSteps20k.
  ///
  /// In tr, this message translates to:
  /// **'20.000 adım'**
  String get achSteps20k;

  /// No description provided for @achSteps20kText.
  ///
  /// In tr, this message translates to:
  /// **'Bir günde 20.000 adım.'**
  String get achSteps20kText;

  /// No description provided for @achWear30.
  ///
  /// In tr, this message translates to:
  /// **'Sadık bileklik'**
  String get achWear30;

  /// No description provided for @achWear30Text.
  ///
  /// In tr, this message translates to:
  /// **'30 farklı günde bilekliği taktınız.'**
  String get achWear30Text;

  /// No description provided for @achWorkouts10.
  ///
  /// In tr, this message translates to:
  /// **'10 egzersiz'**
  String get achWorkouts10;

  /// No description provided for @achWorkouts10Text.
  ///
  /// In tr, this message translates to:
  /// **'Toplam 10 egzersiz kaydı.'**
  String get achWorkouts10Text;

  /// No description provided for @achievementEarned.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde kazanıldı'**
  String achievementEarned(Object date);

  /// No description provided for @achievementProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get achievementProgress;

  /// No description provided for @achievementsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get achievementsTitle;

  /// No description provided for @actionCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get actionClose;

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik'**
  String get appTitle;

  /// No description provided for @autoMeasureAllDay.
  ///
  /// In tr, this message translates to:
  /// **'Tüm gün'**
  String get autoMeasureAllDay;

  /// No description provided for @autoMeasureConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get autoMeasureConnect;

  /// No description provided for @autoMeasureDays.
  ///
  /// In tr, this message translates to:
  /// **'Günler'**
  String get autoMeasureDays;

  /// No description provided for @autoMeasureEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get autoMeasureEnd;

  /// No description provided for @autoMeasureEveryDay.
  ///
  /// In tr, this message translates to:
  /// **'Her gün'**
  String get autoMeasureEveryDay;

  /// No description provided for @autoMeasureEveryHours.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saatte bir'**
  String autoMeasureEveryHours(int hours);

  /// No description provided for @autoMeasureEveryMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakikada bir'**
  String autoMeasureEveryMinutes(int minutes);

  /// No description provided for @autoMeasureHours.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm saatleri'**
  String get autoMeasureHours;

  /// No description provided for @autoMeasureInterval.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm aralığı'**
  String get autoMeasureInterval;

  /// No description provided for @autoMeasureIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik seçtiğiniz saatlerde kendiliğinden ölçer. Her ölçüm 1 dakika sürer; aralık kısaldıkça pil daha çabuk biter.'**
  String get autoMeasureIntro;

  /// No description provided for @autoMeasureLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik ayarları okunamadı.'**
  String get autoMeasureLoadFailed;

  /// No description provided for @autoMeasureNextDay.
  ///
  /// In tr, this message translates to:
  /// **'{time} (ertesi gün)'**
  String autoMeasureNextDay(String time);

  /// No description provided for @autoMeasureNoDays.
  ///
  /// In tr, this message translates to:
  /// **'En az bir gün seçili kalmalı.'**
  String get autoMeasureNoDays;

  /// No description provided for @autoMeasureNotConnected.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları görmek ve değiştirmek için bilekliği bağlayın.'**
  String get autoMeasureNotConnected;

  /// No description provided for @autoMeasureOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get autoMeasureOff;

  /// No description provided for @autoMeasureRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get autoMeasureRetry;

  /// No description provided for @autoMeasureSameTime.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç ve bitiş aynı olamaz.'**
  String get autoMeasureSameTime;

  /// No description provided for @autoMeasureSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ayar bilekliğe yazılamadı. Tekrar deneyin.'**
  String get autoMeasureSaveFailed;

  /// No description provided for @autoMeasureSleepNote.
  ///
  /// In tr, this message translates to:
  /// **'Uykudayken bileklik nabzı 5 dakikada bir ölçer.'**
  String get autoMeasureSleepNote;

  /// No description provided for @autoMeasureStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get autoMeasureStart;

  /// No description provided for @autoMeasureTitle.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik ölçüm'**
  String get autoMeasureTitle;

  /// No description provided for @autoMeasureTurnOn.
  ///
  /// In tr, this message translates to:
  /// **'{name} otomatik ölçümü'**
  String autoMeasureTurnOn(String name);

  /// No description provided for @bandAnxious.
  ///
  /// In tr, this message translates to:
  /// **'Kaygılı'**
  String get bandAnxious;

  /// No description provided for @bandCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakin'**
  String get bandCalm;

  /// No description provided for @bandGood.
  ///
  /// In tr, this message translates to:
  /// **'İyi'**
  String get bandGood;

  /// No description provided for @bandGreat.
  ///
  /// In tr, this message translates to:
  /// **'Harika'**
  String get bandGreat;

  /// No description provided for @bandLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get bandLow;

  /// No description provided for @bandMild.
  ///
  /// In tr, this message translates to:
  /// **'Hafif'**
  String get bandMild;

  /// No description provided for @bandNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get bandNormal;

  /// No description provided for @bandTense.
  ///
  /// In tr, this message translates to:
  /// **'Gergin'**
  String get bandTense;

  /// No description provided for @bmiNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get bmiNormal;

  /// No description provided for @bmiObese.
  ///
  /// In tr, this message translates to:
  /// **'Obez'**
  String get bmiObese;

  /// No description provided for @bmiOver.
  ///
  /// In tr, this message translates to:
  /// **'Fazla kilolu'**
  String get bmiOver;

  /// No description provided for @bmiUnder.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf'**
  String get bmiUnder;

  /// No description provided for @bodyAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm ekle'**
  String get bodyAdd;

  /// No description provided for @bodyBmiNeedsHeight.
  ///
  /// In tr, this message translates to:
  /// **'VKİ için boyunuzu girin.'**
  String get bodyBmiNeedsHeight;

  /// No description provided for @bodyBmiNote.
  ///
  /// In tr, this message translates to:
  /// **'VKİ yetişkinler için genel bir göstergedir; kas oranı yüksek kişilerde, gebelikte ve çocuklarda yanıltıcı olabilir.'**
  String get bodyBmiNote;

  /// No description provided for @bodyChange.
  ///
  /// In tr, this message translates to:
  /// **'Önceki ölçüme göre {change}'**
  String bodyChange(String change);

  /// No description provided for @bodyChartEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde ölçüm yok.'**
  String get bodyChartEmpty;

  /// No description provided for @bodyDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get bodyDate;

  /// No description provided for @bodyDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get bodyDelete;

  /// No description provided for @bodyDeleteBody.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihli ölçüm bu telefondan silinir.'**
  String bodyDeleteBody(String date);

  /// No description provided for @bodyDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm silinsin mi?'**
  String get bodyDeleteTitle;

  /// No description provided for @bodyEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Tartıldığınızda kilonuzu buraya girin; değişimi grafikte izleyin.'**
  String get bodyEmpty;

  /// No description provided for @bodyHeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy'**
  String get bodyHeight;

  /// No description provided for @bodyHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get bodyHistory;

  /// No description provided for @bodyMuscleTooHigh.
  ///
  /// In tr, this message translates to:
  /// **'Kas kütlesi kilodan büyük olamaz'**
  String get bodyMuscleTooHigh;

  /// No description provided for @bodyNoChange.
  ///
  /// In tr, this message translates to:
  /// **'Önceki ölçümle aynı'**
  String get bodyNoChange;

  /// No description provided for @bodyNote.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümler yalnızca bu telefonda saklanır. Bileklik bağlıysa kilonuz kalori hesabı için bilekliğe de yazılır.'**
  String get bodyNote;

  /// No description provided for @bodyOptional.
  ///
  /// In tr, this message translates to:
  /// **'{name} (isteğe bağlı)'**
  String bodyOptional(String name);

  /// No description provided for @bodyRange3Months.
  ///
  /// In tr, this message translates to:
  /// **'3 ay'**
  String get bodyRange3Months;

  /// No description provided for @bodyRangeError.
  ///
  /// In tr, this message translates to:
  /// **'{min} ile {max} arasında olmalı'**
  String bodyRangeError(String min, String max);

  /// No description provided for @bodyRangeMonth.
  ///
  /// In tr, this message translates to:
  /// **'1 ay'**
  String get bodyRangeMonth;

  /// No description provided for @bodyRangeYear.
  ///
  /// In tr, this message translates to:
  /// **'1 yıl'**
  String get bodyRangeYear;

  /// No description provided for @bodySave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get bodySave;

  /// No description provided for @bodySheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ölçüm'**
  String get bodySheetTitle;

  /// No description provided for @bodyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ve vücut'**
  String get bodyTitle;

  /// No description provided for @bodyToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get bodyToday;

  /// No description provided for @clock12.
  ///
  /// In tr, this message translates to:
  /// **'12 saat (ÖÖ/ÖS)'**
  String get clock12;

  /// No description provided for @clock24.
  ///
  /// In tr, this message translates to:
  /// **'24 saat'**
  String get clock24;

  /// No description provided for @clockSystem.
  ///
  /// In tr, this message translates to:
  /// **'Dile göre'**
  String get clockSystem;

  /// No description provided for @clockTitle.
  ///
  /// In tr, this message translates to:
  /// **'Saat biçimi'**
  String get clockTitle;

  /// No description provided for @comingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get comingSoon;

  /// No description provided for @comingSoonMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu bölüm sonraki bir sürümde gelecek.'**
  String get comingSoonMessage;

  /// No description provided for @communityAccept.
  ///
  /// In tr, this message translates to:
  /// **'Katıl'**
  String get communityAccept;

  /// No description provided for @communityAnswered.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtlandı'**
  String get communityAnswered;

  /// No description provided for @communityCodeCopied.
  ///
  /// In tr, this message translates to:
  /// **'Kod kopyalandı'**
  String get communityCodeCopied;

  /// No description provided for @communityCodeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Bu kodla bir grup bulunamadı.'**
  String get communityCodeInvalid;

  /// No description provided for @communityCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Grup kodu'**
  String get communityCodeLabel;

  /// No description provided for @communityConsentSince.
  ///
  /// In tr, this message translates to:
  /// **'İzin tarihi: {date}'**
  String communityConsentSince(Object date);

  /// No description provided for @communityCopyCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu kopyala'**
  String get communityCopyCode;

  /// No description provided for @communityCreate.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get communityCreate;

  /// No description provided for @communityCreateGroup.
  ///
  /// In tr, this message translates to:
  /// **'Yeni grup oluştur'**
  String get communityCreateGroup;

  /// No description provided for @communityDecline.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get communityDecline;

  /// No description provided for @communityDelete.
  ///
  /// In tr, this message translates to:
  /// **'Grubu sil'**
  String get communityDelete;

  /// No description provided for @communityDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{group}\" silinir ve gruptaki tüm paylaşımlar sona erer.'**
  String communityDeleteConfirm(Object group);

  /// No description provided for @communityGroupName.
  ///
  /// In tr, this message translates to:
  /// **'Grup adı'**
  String get communityGroupName;

  /// No description provided for @communityGroupNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Ailem'**
  String get communityGroupNameHint;

  /// No description provided for @communityInvite.
  ///
  /// In tr, this message translates to:
  /// **'Üye davet et'**
  String get communityInvite;

  /// No description provided for @communityInviteCodeBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu kodu {name} ile paylaşın. Uygulamada Sağlık topluluğu > Kodla katıl ile gruba katılabilir.'**
  String communityInviteCodeBody(Object name);

  /// No description provided for @communityInviteCodeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Davet kodu'**
  String get communityInviteCodeTitle;

  /// No description provided for @communityInviteName.
  ///
  /// In tr, this message translates to:
  /// **'Davet edilecek kişinin adı'**
  String get communityInviteName;

  /// No description provided for @communityInviteSend.
  ///
  /// In tr, this message translates to:
  /// **'Davet et'**
  String get communityInviteSend;

  /// No description provided for @communityJoinWithCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodla katıl'**
  String get communityJoinWithCode;

  /// No description provided for @communityJoinedEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bir davetle ya da grup koduyla katılabilirsiniz.'**
  String get communityJoinedEmpty;

  /// No description provided for @communityJoinedGroups.
  ///
  /// In tr, this message translates to:
  /// **'Katıldığım gruplar'**
  String get communityJoinedGroups;

  /// No description provided for @communityJoinedMessage.
  ///
  /// In tr, this message translates to:
  /// **'\"{group}\" grubuna katıldınız.'**
  String communityJoinedMessage(Object group);

  /// No description provided for @communityLeave.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan ayrıl'**
  String get communityLeave;

  /// No description provided for @communityLeaveConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{group}\" grubundan ayrılınca paylaştığınız veriler üyelere artık görünmez.'**
  String communityLeaveConfirm(Object group);

  /// No description provided for @communityMemberCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 üye} other{{count} üye}}'**
  String communityMemberCount(num count);

  /// No description provided for @communityMembers.
  ///
  /// In tr, this message translates to:
  /// **'Üyeler'**
  String get communityMembers;

  /// No description provided for @communityMessages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get communityMessages;

  /// No description provided for @communityMessagesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok.'**
  String get communityMessagesEmpty;

  /// No description provided for @communityMsgInvite.
  ///
  /// In tr, this message translates to:
  /// **'{name} sizi \"{group}\" grubuna davet etti.'**
  String communityMsgInvite(Object name, Object group);

  /// No description provided for @communityMsgJoined.
  ///
  /// In tr, this message translates to:
  /// **'{name}, \"{group}\" grubuna katıldı.'**
  String communityMsgJoined(Object name, Object group);

  /// No description provided for @communityMyGroups.
  ///
  /// In tr, this message translates to:
  /// **'Gruplarım'**
  String get communityMyGroups;

  /// No description provided for @communityMyGroupsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir grubunuz yok. Bir grup oluşturup ailenizi davet edin.'**
  String get communityMyGroupsEmpty;

  /// No description provided for @communityMyShareNote.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca bu grubun üyeleri görür. Siz açmadıkça hiçbir veri paylaşılmaz.'**
  String get communityMyShareNote;

  /// No description provided for @communityMyShareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu grupla paylaştıklarınız'**
  String get communityMyShareTitle;

  /// No description provided for @communityOwner.
  ///
  /// In tr, this message translates to:
  /// **'Grup sahibi'**
  String get communityOwner;

  /// No description provided for @communityOwnerName.
  ///
  /// In tr, this message translates to:
  /// **'Grup sahibi: {name}'**
  String communityOwnerName(Object name);

  /// No description provided for @communityPending.
  ///
  /// In tr, this message translates to:
  /// **'Davet bekleniyor'**
  String get communityPending;

  /// No description provided for @communityPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık verileriniz yalnızca seçtiğiniz gruplarla ve seçtiğiniz türlerde paylaşılır. İzninizi istediğiniz an geri alabilirsiniz.'**
  String get communityPrivacyNote;

  /// No description provided for @communityRemoveMember.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan çıkar'**
  String get communityRemoveMember;

  /// No description provided for @communityShares.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşıyor: {types}'**
  String communityShares(Object types);

  /// No description provided for @communitySharesNothing.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir şey paylaşmıyor'**
  String get communitySharesNothing;

  /// No description provided for @communityYou.
  ///
  /// In tr, this message translates to:
  /// **'Siz'**
  String get communityYou;

  /// No description provided for @connActive.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantılarım'**
  String get connActive;

  /// No description provided for @connAgree.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgileri okudum. Seçtiğim verilerin yukarıdaki amaçla {name} ile paylaşılmasına açıkça rıza veriyorum.'**
  String connAgree(Object name);

  /// No description provided for @connCodeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Bu kod geçersiz ya da süresi dolmuş.'**
  String get connCodeInvalid;

  /// No description provided for @connConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla ve bağlan'**
  String get connConfirm;

  /// No description provided for @connConnected.
  ///
  /// In tr, this message translates to:
  /// **'{name} ile bağlantı kuruldu.'**
  String connConnected(Object name);

  /// No description provided for @connConsentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açık rıza'**
  String get connConsentTitle;

  /// No description provided for @connDisconnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kaldır'**
  String get connDisconnect;

  /// No description provided for @connDisconnectConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} artık yeni verilerinizi göremez. Daha önce paylaşılanların silinmesini kurumdan isteyebilirsiniz.'**
  String connDisconnectConfirm(Object name);

  /// No description provided for @connDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get connDuration;

  /// No description provided for @connDurationText.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihine kadar ({days} gün). Süre bitince paylaşım kendiliğinden durur; daha önce de kaldırabilirsiniz.'**
  String connDurationText(Object date, Object days);

  /// No description provided for @connEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir bağlantınız yok.'**
  String get connEmpty;

  /// No description provided for @connEnterCode.
  ///
  /// In tr, this message translates to:
  /// **'Davet kodu gir'**
  String get connEnterCode;

  /// No description provided for @connIntro.
  ///
  /// In tr, this message translates to:
  /// **'Hekiminiz ya da katıldığınız bir araştırma size davet kodu verir. Kodu girince kimin, hangi verileri, ne kadar süre istediğini görür ve siz karar verirsiniz.'**
  String get connIntro;

  /// No description provided for @connKindClinician.
  ///
  /// In tr, this message translates to:
  /// **'Hekim'**
  String get connKindClinician;

  /// No description provided for @connKindResearch.
  ///
  /// In tr, this message translates to:
  /// **'Araştırma kurumu'**
  String get connKindResearch;

  /// No description provided for @connPurpose.
  ///
  /// In tr, this message translates to:
  /// **'Amaç'**
  String get connPurpose;

  /// No description provided for @connQrInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Bu QR kodu bir davet kodu içermiyor.'**
  String get connQrInvalid;

  /// No description provided for @connRequested.
  ///
  /// In tr, this message translates to:
  /// **'İstenen veriler'**
  String get connRequested;

  /// No description provided for @connRequestedNote.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşmak istediklerinizi seçin. Seçmedikleriniz paylaşılmaz.'**
  String get connRequestedNote;

  /// No description provided for @connRights.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz KVKK kapsamında işlenir. Verilerinize erişme, düzeltilmesini ya da silinmesini isteme hakkınız vardır.'**
  String get connRights;

  /// No description provided for @connScan.
  ///
  /// In tr, this message translates to:
  /// **'QR kodu tara'**
  String get connScan;

  /// No description provided for @connScanHint.
  ///
  /// In tr, this message translates to:
  /// **'Hekiminizin ya da araştırma kurumunun verdiği QR kodunu çerçevenin içine getirin.'**
  String get connScanHint;

  /// No description provided for @connSelectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü seç'**
  String get connSelectAll;

  /// No description provided for @connShared.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan veriler'**
  String get connShared;

  /// No description provided for @connSharedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 veri türü} other{{count} veri türü}}'**
  String connSharedCount(num count);

  /// No description provided for @connSince.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç: {date}'**
  String connSince(Object date);

  /// No description provided for @connUntil.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş: {date}'**
  String connUntil(Object date);

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueButton;

  /// No description provided for @deviceAddress.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get deviceAddress;

  /// No description provided for @deviceBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil'**
  String get deviceBattery;

  /// No description provided for @deviceBatteryValue.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String deviceBatteryValue(Object value);

  /// No description provided for @deviceConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get deviceConnected;

  /// No description provided for @deviceDisconnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kes'**
  String get deviceDisconnect;

  /// No description provided for @deviceDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değil'**
  String get deviceDisconnected;

  /// No description provided for @deviceLastSync.
  ///
  /// In tr, this message translates to:
  /// **'Son eşitleme'**
  String get deviceLastSync;

  /// No description provided for @devicePairNew.
  ///
  /// In tr, this message translates to:
  /// **'Başka bileklik eşleştir'**
  String get devicePairNew;

  /// No description provided for @deviceSectionSettings.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik ayarları'**
  String get deviceSectionSettings;

  /// No description provided for @deviceStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get deviceStatus;

  /// No description provided for @durationHours.
  ///
  /// In tr, this message translates to:
  /// **'{h} sa'**
  String durationHours(Object h);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{h} sa {m} dk'**
  String durationHoursMinutes(Object h, Object m);

  /// No description provided for @durationMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{m} dk'**
  String durationMinutes(Object m);

  /// No description provided for @ecgAverageBpm.
  ///
  /// In tr, this message translates to:
  /// **'{bpm} bpm ortalama'**
  String ecgAverageBpm(Object bpm);

  /// No description provided for @ecgAverageHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama nabız'**
  String get ecgAverageHeartRate;

  /// No description provided for @ecgBeats.
  ///
  /// In tr, this message translates to:
  /// **'Atım sayısı'**
  String get ecgBeats;

  /// No description provided for @ecgBpm.
  ///
  /// In tr, this message translates to:
  /// **'bpm'**
  String get ecgBpm;

  /// No description provided for @ecgCancel.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümü iptal et'**
  String get ecgCancel;

  /// No description provided for @ecgConnectFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce Ana Sayfa\'dan bilekliği bağlayın.'**
  String get ecgConnectFirst;

  /// No description provided for @ecgDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'EKG · {date} {time}'**
  String ecgDetailTitle(Object date, Object time);

  /// No description provided for @ecgDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu ölçüm tıbbi tanı yerine geçmez. Göğüs ağrısı, nefes darlığı ya da bayılma hissi varsa hemen 112\'yi arayın.'**
  String get ecgDisclaimer;

  /// No description provided for @ecgHowToSteps.
  ///
  /// In tr, this message translates to:
  /// **'1. Bilekliği bileğinize sıkıca takın.\n2. Oturun, kolunuzu masaya koyun.\n3. Diğer elinizin parmağını bilekliğin üstündeki elektroda hafifçe dokundurun.\n4. 30 saniye boyunca hareket etmeyin ve konuşmayın.'**
  String get ecgHowToSteps;

  /// No description provided for @ecgHowToTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl ölçülür'**
  String get ecgHowToTitle;

  /// No description provided for @ecgKeepStill.
  ///
  /// In tr, this message translates to:
  /// **'Parmağınızı elektrottan kaldırmayın ve hareket etmeyin.'**
  String get ecgKeepStill;

  /// No description provided for @ecgMeasuringTitle.
  ///
  /// In tr, this message translates to:
  /// **'EKG ölçülüyor'**
  String get ecgMeasuringTitle;

  /// No description provided for @ecgMs.
  ///
  /// In tr, this message translates to:
  /// **'ms'**
  String get ecgMs;

  /// No description provided for @ecgNoHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Nabız hesaplanamadı'**
  String get ecgNoHeartRate;

  /// No description provided for @ecgNoRecords.
  ///
  /// In tr, this message translates to:
  /// **'Henüz EKG kaydı yok.'**
  String get ecgNoRecords;

  /// No description provided for @ecgRange.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get ecgRange;

  /// No description provided for @ecgRangeValue.
  ///
  /// In tr, this message translates to:
  /// **'{min}-{max}'**
  String ecgRangeValue(Object min, Object max);

  /// No description provided for @ecgRecordHeader.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ({seconds} sn, satır başına {perRow} sn)'**
  String ecgRecordHeader(Object seconds, Object perRow);

  /// No description provided for @ecgRecordSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{when} · {seconds} sn'**
  String ecgRecordSubtitle(Object when, Object seconds);

  /// No description provided for @ecgRecordsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar'**
  String get ecgRecordsTitle;

  /// No description provided for @ecgSdnn.
  ///
  /// In tr, this message translates to:
  /// **'Değişkenlik (SDNN)'**
  String get ecgSdnn;

  /// No description provided for @ecgSecondsLeft.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} sn'**
  String ecgSecondsLeft(Object seconds);

  /// No description provided for @ecgStartButton.
  ///
  /// In tr, this message translates to:
  /// **'30 saniyelik ölçüm başlat'**
  String get ecgStartButton;

  /// No description provided for @ecgTitle.
  ///
  /// In tr, this message translates to:
  /// **'EKG'**
  String get ecgTitle;

  /// No description provided for @energyDayTitle.
  ///
  /// In tr, this message translates to:
  /// **'{date} enerjisi'**
  String energyDayTitle(Object date);

  /// No description provided for @energyDrain.
  ///
  /// In tr, this message translates to:
  /// **'Gün içi harcama'**
  String get energyDrain;

  /// No description provided for @energyEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Enerji için gece uykusu ya da HRV ölçümü gerekiyor.'**
  String get energyEmpty;

  /// No description provided for @energyHigh.
  ///
  /// In tr, this message translates to:
  /// **'Enerjiniz yüksek'**
  String get energyHigh;

  /// No description provided for @energyLow.
  ///
  /// In tr, this message translates to:
  /// **'Enerjiniz düşük; dinlenmeye zaman ayırın'**
  String get energyLow;

  /// No description provided for @energyMedium.
  ///
  /// In tr, this message translates to:
  /// **'Enerjiniz orta düzeyde'**
  String get energyMedium;

  /// No description provided for @energyNote.
  ///
  /// In tr, this message translates to:
  /// **'Gece uykusunun süresi ve derinliği ile HRV'nin son iki haftaya göre durumu enerjiyi doldurur; adım ve stres gün içinde azaltır. Uygulamanın kendi tahminidir, tıbbi bir ölçüm değildir.'**
  String get energyNote;

  /// No description provided for @energyRecovery.
  ///
  /// In tr, this message translates to:
  /// **'Toparlanma'**
  String get energyRecovery;

  /// No description provided for @energySemantics.
  ///
  /// In tr, this message translates to:
  /// **'Enerji {score}/100, {level}'**
  String energySemantics(Object score, Object level);

  /// No description provided for @energySleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get energySleep;

  /// No description provided for @energyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Enerji'**
  String get energyTitle;

  /// No description provided for @exerciseConnectFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce Ana Sayfa\'dan bilekliği bağlayın.'**
  String get exerciseConnectFirst;

  /// No description provided for @exerciseConnectHint.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş egzersizleri görmek için bilekliği bağlayın.'**
  String get exerciseConnectHint;

  /// No description provided for @exerciseCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} egzersiz'**
  String exerciseCount(int count);

  /// No description provided for @exerciseEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz egzersiz kaydı yok.'**
  String get exerciseEmpty;

  /// No description provided for @exerciseInProgress.
  ///
  /// In tr, this message translates to:
  /// **'{sport} sürüyor'**
  String exerciseInProgress(Object sport);

  /// No description provided for @exerciseLast30Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün'**
  String get exerciseLast30Days;

  /// No description provided for @exercisePausedAt.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı · {time}'**
  String exercisePausedAt(Object time);

  /// No description provided for @exerciseStart.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz başlat'**
  String get exerciseStart;

  /// No description provided for @exerciseThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta'**
  String get exerciseThisWeek;

  /// No description provided for @exportEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde dışa aktarılacak kayıt yok.'**
  String get exportEmpty;

  /// No description provided for @exportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dosya hazırlanamadı. Tekrar deneyin.'**
  String get exportFailed;

  /// No description provided for @exportIncludeEcg.
  ///
  /// In tr, this message translates to:
  /// **'EKG kayıtlarını ekle'**
  String get exportIncludeEcg;

  /// No description provided for @exportIncludeEcgNote.
  ///
  /// In tr, this message translates to:
  /// **'Ham EKG verisi dosyayı büyütür.'**
  String get exportIncludeEcgNote;

  /// No description provided for @exportIntro.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümleriniz sağlık sistemlerinin ortak biçimi olan FHIR R4 dosyası olarak hazırlanır. Dosyayı hekiminize gönderebilir ya da bu biçimi okuyan bir uygulamada açabilirsiniz.'**
  String get exportIntro;

  /// No description provided for @exportPeriod.
  ///
  /// In tr, this message translates to:
  /// **'Dönem'**
  String get exportPeriod;

  /// No description provided for @exportPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Dosya sağlık verisi içerir. Yalnızca güvendiğiniz kişi ve kurumlarla paylaşın. Dosyada adınız yok; yalnızca bu telefona özel bir takma kimlik var.'**
  String get exportPrivacy;

  /// No description provided for @exportRecordCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt'**
  String exportRecordCount(int count);

  /// No description provided for @exportShare.
  ///
  /// In tr, this message translates to:
  /// **'Dosyayı paylaş'**
  String get exportShare;

  /// No description provided for @exportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimi dışa aktar'**
  String get exportTitle;

  /// No description provided for @healthBloodPressure.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon'**
  String get healthBloodPressure;

  /// Tansiyon kartı alt yazısı; değerin tahmini olduğunu belirtir.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini · {details}'**
  String healthBloodPressureSubtitle(Object details);

  /// No description provided for @healthConnectHint.
  ///
  /// In tr, this message translates to:
  /// **'Verileri görmek için Ana Sayfa\'dan bilekliği bağlayın.'**
  String get healthConnectHint;

  /// No description provided for @healthEcg.
  ///
  /// In tr, this message translates to:
  /// **'EKG'**
  String get healthEcg;

  /// No description provided for @healthEcgLast.
  ///
  /// In tr, this message translates to:
  /// **'Son ölçüm · {time}'**
  String healthEcgLast(Object time);

  /// No description provided for @healthEcgPrompt.
  ///
  /// In tr, this message translates to:
  /// **'30 saniyelik ölçüm yapın'**
  String get healthEcgPrompt;

  /// No description provided for @healthLastSync.
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme {time}'**
  String healthLastSync(Object time);

  /// No description provided for @healthNoMeasurement.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm yok'**
  String get healthNoMeasurement;

  /// No description provided for @healthNoRecord.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get healthNoRecord;

  /// No description provided for @healthSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get healthSleep;

  /// No description provided for @healthSleepLastNight.
  ///
  /// In tr, this message translates to:
  /// **'Dün gece · {start} - {end}'**
  String healthSleepLastNight(Object start, Object end);

  /// No description provided for @healthStepsToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün · hedef {goal}'**
  String healthStepsToday(Object goal);

  /// No description provided for @healthSyncTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bileklikten güncelle'**
  String get healthSyncTooltip;

  /// No description provided for @healthSyncing.
  ///
  /// In tr, this message translates to:
  /// **'Bileklikten veriler alınıyor…'**
  String get healthSyncing;

  /// No description provided for @healthWeightBmi.
  ///
  /// In tr, this message translates to:
  /// **'VKİ {bmi} · {when}'**
  String healthWeightBmi(String bmi, String when);

  /// No description provided for @healthWeightPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Kilonuzu girin'**
  String get healthWeightPrompt;

  /// No description provided for @homeActiveGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef {minutes} dk'**
  String homeActiveGoal(Object minutes);

  /// No description provided for @homeActiveTime.
  ///
  /// In tr, this message translates to:
  /// **'Aktif süre'**
  String get homeActiveTime;

  /// No description provided for @homeAverageStress.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama stres'**
  String get homeAverageStress;

  /// No description provided for @homeAverageStressBand.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama stres · {band}'**
  String homeAverageStressBand(Object band);

  /// No description provided for @homeAverageValue.
  ///
  /// In tr, this message translates to:
  /// **'Ort. {value}'**
  String homeAverageValue(Object value);

  /// No description provided for @homeBalance.
  ///
  /// In tr, this message translates to:
  /// **'Denge'**
  String get homeBalance;

  /// No description provided for @homeBloodOxygen.
  ///
  /// In tr, this message translates to:
  /// **'Kan oksijeni'**
  String get homeBloodOxygen;

  /// No description provided for @homeBpm.
  ///
  /// In tr, this message translates to:
  /// **'{value} bpm'**
  String homeBpm(Object value);

  /// No description provided for @homeCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get homeCalories;

  /// No description provided for @homeChartNoData.
  ///
  /// In tr, this message translates to:
  /// **'{title}: ölçüm yok'**
  String homeChartNoData(Object title);

  /// No description provided for @homeChartSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{title}: en düşük {min}, en yüksek {max} {unit}'**
  String homeChartSemantics(Object title, Object min, Object max, Object unit);

  /// No description provided for @homeConnectTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bilekliğe bağlan'**
  String get homeConnectTooltip;

  /// No description provided for @homeConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get homeConnected;

  /// No description provided for @homeConnectedBattery.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı · %{percent}'**
  String homeConnectedBattery(Object percent);

  /// No description provided for @homeConnecting.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanıyor…'**
  String get homeConnecting;

  /// No description provided for @homeDaySummary.
  ///
  /// In tr, this message translates to:
  /// **'Günün özeti'**
  String get homeDaySummary;

  /// No description provided for @homeDeepSleep.
  ///
  /// In tr, this message translates to:
  /// **'Derin uyku {duration}'**
  String homeDeepSleep(Object duration);

  /// No description provided for @homeDisconnectTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kes'**
  String get homeDisconnectTooltip;

  /// No description provided for @homeEcg.
  ///
  /// In tr, this message translates to:
  /// **'EKG'**
  String get homeEcg;

  /// No description provided for @homeEcgSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{bpm} bpm · {seconds} sn'**
  String homeEcgSubtitle(Object bpm, Object seconds);

  /// No description provided for @homeEcgSubtitleNoHr.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} sn'**
  String homeEcgSubtitleNoHr(Object seconds);

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get homeGoodEvening;

  /// No description provided for @homeGoodMorning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get homeGoodMorning;

  /// No description provided for @homeHeartRateHint.
  ///
  /// In tr, this message translates to:
  /// **'Kalp atış hızınızı görmek için bilekliği gün boyu takın.'**
  String get homeHeartRateHint;

  /// No description provided for @homeHeartRateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalp atış hızı'**
  String get homeHeartRateLabel;

  /// No description provided for @homeHeroEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Nabzınızı görmek için bilekliği bağlayın.'**
  String get homeHeroEmpty;

  /// No description provided for @homeHeroSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Nabız {value} bpm'**
  String homeHeroSemantics(Object value);

  /// No description provided for @homeHourlyStressSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Saatlik stres sütunları'**
  String get homeHourlyStressSemantics;

  /// No description provided for @homeHrvLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalp atış hızı değişkenliği'**
  String get homeHrvLabel;

  /// No description provided for @homeKcal.
  ///
  /// In tr, this message translates to:
  /// **'kcal'**
  String get homeKcal;

  /// No description provided for @homeKm.
  ///
  /// In tr, this message translates to:
  /// **'{value} km'**
  String homeKm(Object value);

  /// No description provided for @homeLastMeasured.
  ///
  /// In tr, this message translates to:
  /// **'Son ölçüm {time}'**
  String homeLastMeasured(Object time);

  /// No description provided for @homeListSeparator.
  ///
  /// In tr, this message translates to:
  /// **', '**
  String get homeListSeparator;

  /// No description provided for @homeLive.
  ///
  /// In tr, this message translates to:
  /// **'Canlı'**
  String get homeLive;

  /// No description provided for @homeMeasureNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi ölç'**
  String get homeMeasureNow;

  /// No description provided for @homeMs.
  ///
  /// In tr, this message translates to:
  /// **'{value} ms'**
  String homeMs(Object value);

  /// No description provided for @homeNextDay.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki gün'**
  String get homeNextDay;

  /// No description provided for @homeNoRecord.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get homeNoRecord;

  /// No description provided for @homeNoSleepLastNight.
  ///
  /// In tr, this message translates to:
  /// **'Dün gece uyku ölçülmedi'**
  String get homeNoSleepLastNight;

  /// No description provided for @homeNoSleepPastHint.
  ///
  /// In tr, this message translates to:
  /// **'Bilekliğin takılı olduğu günlerin özeti burada görünür.'**
  String get homeNoSleepPastHint;

  /// No description provided for @homeNoSleepStages.
  ///
  /// In tr, this message translates to:
  /// **'Uyku evresi yok'**
  String get homeNoSleepStages;

  /// No description provided for @homeNoSleepThisDay.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün için uyku kaydı yok'**
  String get homeNoSleepThisDay;

  /// No description provided for @homeNoSleepTonightHint.
  ///
  /// In tr, this message translates to:
  /// **'Bilekliği bu gece takın; sabah uyku ve toparlanma özetiniz burada olacak.'**
  String get homeNoSleepTonightHint;

  /// No description provided for @homeNotConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değil'**
  String get homeNotConnected;

  /// No description provided for @homePercent.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String homePercent(Object value);

  /// No description provided for @homePickDay.
  ///
  /// In tr, this message translates to:
  /// **'Gün seçin'**
  String get homePickDay;

  /// No description provided for @homePrevDay.
  ///
  /// In tr, this message translates to:
  /// **'Önceki gün'**
  String get homePrevDay;

  /// No description provided for @homeQuickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı işlemler'**
  String get homeQuickActions;

  /// No description provided for @homeQuickHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Nabız ölç'**
  String get homeQuickHeartRate;

  /// No description provided for @homeQuickSync.
  ///
  /// In tr, this message translates to:
  /// **'Senkronize'**
  String get homeQuickSync;

  /// No description provided for @homeRange.
  ///
  /// In tr, this message translates to:
  /// **'{min}-{max}'**
  String homeRange(Object min, Object max);

  /// No description provided for @homeRecovery.
  ///
  /// In tr, this message translates to:
  /// **'Toparlanma'**
  String get homeRecovery;

  /// No description provided for @homeRestingHr.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenik nabız {value} bpm'**
  String homeRestingHr(Object value);

  /// No description provided for @homeSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get homeSleep;

  /// No description provided for @homeSleepStageItem.
  ///
  /// In tr, this message translates to:
  /// **'{stage} {duration}'**
  String homeSleepStageItem(Object stage, Object duration);

  /// No description provided for @homeSleepStagesSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Uyku evreleri: {stages}'**
  String homeSleepStagesSemantics(Object stages);

  /// No description provided for @homeSleptHrvBandSummary.
  ///
  /// In tr, this message translates to:
  /// **'{duration} uyudunuz, gece HRV ortalamanız {hrv} ms ({band}).'**
  String homeSleptHrvBandSummary(Object duration, Object hrv, Object band);

  /// No description provided for @homeSleptHrvSummary.
  ///
  /// In tr, this message translates to:
  /// **'{duration} uyudunuz, gece HRV ortalamanız {hrv} ms.'**
  String homeSleptHrvSummary(Object duration, Object hrv);

  /// No description provided for @homeSleptSummary.
  ///
  /// In tr, this message translates to:
  /// **'{duration} uyudunuz.'**
  String homeSleptSummary(Object duration);

  /// No description provided for @homeSpo2Hint.
  ///
  /// In tr, this message translates to:
  /// **'Kan oksijeninizi görmek için bilekliği gün boyu takın.'**
  String get homeSpo2Hint;

  /// No description provided for @homeStartWorkout.
  ///
  /// In tr, this message translates to:
  /// **'Egzersize başla'**
  String get homeStartWorkout;

  /// No description provided for @homeStepGoal.
  ///
  /// In tr, this message translates to:
  /// **'Hedef {goal} adım'**
  String homeStepGoal(Object goal);

  /// No description provided for @homeStepGoalProgress.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} · hedef {goal}'**
  String homeStepGoalProgress(Object percent, Object goal);

  /// No description provided for @homeStepGoalSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Adım hedefi: {steps} / {goal}, yüzde {percent}'**
  String homeStepGoalSemantics(Object steps, Object goal, Object percent);

  /// No description provided for @homeSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adım'**
  String get homeSteps;

  /// No description provided for @homeStressHint.
  ///
  /// In tr, this message translates to:
  /// **'Stres ve HRV, bileklik takılıyken gün içinde ölçülür.'**
  String get homeStressHint;

  /// No description provided for @homeStressLevel.
  ///
  /// In tr, this message translates to:
  /// **'Stres düzeyi'**
  String get homeStressLevel;

  /// No description provided for @homeStressLoad.
  ///
  /// In tr, this message translates to:
  /// **'Stres yükü'**
  String get homeStressLoad;

  /// No description provided for @homeSyncing.
  ///
  /// In tr, this message translates to:
  /// **'Senkronize ediliyor…'**
  String get homeSyncing;

  /// No description provided for @homeTimeline.
  ///
  /// In tr, this message translates to:
  /// **'Zaman çizelgesi'**
  String get homeTimeline;

  /// No description provided for @homeTimelineEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz, EKG ve uyku kayıtlarınız burada saat sırasıyla görünür.'**
  String get homeTimelineEmpty;

  /// No description provided for @homeTimelineSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün kayıtları'**
  String get homeTimelineSubtitle;

  /// No description provided for @homeToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get homeToday;

  /// No description provided for @homeWeekdayDate.
  ///
  /// In tr, this message translates to:
  /// **'{weekday}, {date}'**
  String homeWeekdayDate(Object weekday, Object date);

  /// No description provided for @homeWokeUp.
  ///
  /// In tr, this message translates to:
  /// **'Uyandınız'**
  String get homeWokeUp;

  /// No description provided for @homeWokeUpSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{duration} uyku · {time} yatış'**
  String homeWokeUpSubtitle(Object duration, Object time);

  /// No description provided for @homeWorkoutSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{duration} · {kcal} kcal'**
  String homeWorkoutSubtitle(Object duration, Object kcal);

  /// No description provided for @homeYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get homeYesterday;

  /// No description provided for @hpActivity.
  ///
  /// In tr, this message translates to:
  /// **'Adım, mesafe ve kalori'**
  String get hpActivity;

  /// No description provided for @hpAuto.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik eşitlendikçe yeni veriler kendiliğinden aktarılır.'**
  String get hpAuto;

  /// No description provided for @hpBody.
  ///
  /// In tr, this message translates to:
  /// **'Kilo, yağ oranı ve VKİ'**
  String get hpBody;

  /// No description provided for @hpChooseTypes.
  ///
  /// In tr, this message translates to:
  /// **'Aktarılacak veriler'**
  String get hpChooseTypes;

  /// No description provided for @hpConnect.
  ///
  /// In tr, this message translates to:
  /// **'{platform} ile bağlan'**
  String hpConnect(Object platform);

  /// No description provided for @hpConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get hpConnected;

  /// No description provided for @hpDenied.
  ///
  /// In tr, this message translates to:
  /// **'İzin verilmedi. {platform} ayarlarından izin verebilirsiniz.'**
  String hpDenied(Object platform);

  /// No description provided for @hpDisconnect.
  ///
  /// In tr, this message translates to:
  /// **'Aktarımı durdur'**
  String get hpDisconnect;

  /// No description provided for @hpDisconnectNote.
  ///
  /// In tr, this message translates to:
  /// **'Daha önce yazılan veriler {platform} içinde kalır; silmek için {platform} ayarlarını kullanın.'**
  String hpDisconnectNote(Object platform);

  /// No description provided for @hpExportNow.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi aktar'**
  String get hpExportNow;

  /// No description provided for @hpExported.
  ///
  /// In tr, this message translates to:
  /// **'{records} aktarıldı'**
  String hpExported(Object records);

  /// No description provided for @hpHrv.
  ///
  /// In tr, this message translates to:
  /// **'Kalp atış hızı değişkenliği (HRV)'**
  String get hpHrv;

  /// No description provided for @hpIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik verileriniz {platform} uygulamasına yazılır; telefonunuzdaki diğer sağlık uygulamaları da görebilir. Hangi türlerin aktarılacağını siz seçersiniz.'**
  String hpIntro(Object platform);

  /// No description provided for @hpLastExport.
  ///
  /// In tr, this message translates to:
  /// **'Son aktarım: {time} · {records}'**
  String hpLastExport(Object time, Object records);

  /// No description provided for @hpNever.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aktarılmadı'**
  String get hpNever;

  /// No description provided for @hpNotExported.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon tahmini olduğu için aktarılmaz. EKG kayıtlarını sağlık platformları dışarıdan kabul etmez.'**
  String get hpNotExported;

  /// No description provided for @hpNothingNew.
  ///
  /// In tr, this message translates to:
  /// **'Aktarılacak yeni kayıt yok'**
  String get hpNothingNew;

  /// No description provided for @hpPermissionNote.
  ///
  /// In tr, this message translates to:
  /// **'Devam edince {platform} izin penceresi açılır; orada da tek tek seçebilirsiniz.'**
  String hpPermissionNote(Object platform);

  /// No description provided for @hpRecords.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{kayıt yok} other{{count} kayıt}}'**
  String hpRecords(num count);

  /// No description provided for @hpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık uygulaması'**
  String get hpTitle;

  /// No description provided for @hpUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'{platform} bu telefonda yok. Google Play\'den yükleyebilirsiniz.'**
  String hpUnavailable(Object platform);

  /// No description provided for @hpWorkouts.
  ///
  /// In tr, this message translates to:
  /// **'Egzersizler'**
  String get hpWorkouts;

  /// No description provided for @hrvBeats.
  ///
  /// In tr, this message translates to:
  /// **'Atım'**
  String get hrvBeats;

  /// No description provided for @hrvDetailEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Son bir haftada gece atım aralığı ölçümü yok. Bilekliği uyurken takın.'**
  String get hrvDetailEmpty;

  /// No description provided for @hrvDetailNight.
  ///
  /// In tr, this message translates to:
  /// **'{date} sabahına kadarki gece'**
  String hrvDetailNight(Object date);

  /// No description provided for @hrvDetailNote.
  ///
  /// In tr, this message translates to:
  /// **'Gece ölçülen atım aralıklarından hesaplanır. RMSSD kısa süreli, SDNN genel değişkenliği gösterir; kendi eğiliminizle karşılaştırın.'**
  String get hrvDetailNote;

  /// No description provided for @hrvDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gece HRV ayrıntısı'**
  String get hrvDetailTitle;

  /// No description provided for @hrvMeanHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama nabız'**
  String get hrvMeanHeartRate;

  /// No description provided for @hrvPnn50.
  ///
  /// In tr, this message translates to:
  /// **'pNN50'**
  String get hrvPnn50;

  /// No description provided for @hrvRmssd.
  ///
  /// In tr, this message translates to:
  /// **'RMSSD'**
  String get hrvRmssd;

  /// No description provided for @hrvSdnn.
  ///
  /// In tr, this message translates to:
  /// **'SDNN'**
  String get hrvSdnn;

  /// No description provided for @issueBusy.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik şu an başka bir egzersizde ya da ölçümde.'**
  String get issueBusy;

  /// No description provided for @issueFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bileklikle iletişim kurulamadı. Yakında ve açık olduğundan emin olun.'**
  String get issueFailed;

  /// No description provided for @issueNoEcgSignal.
  ///
  /// In tr, this message translates to:
  /// **'EKG verisi alınamadı. Bilekliği takıp parmağınızı elektroda dokundurun.'**
  String get issueNoEcgSignal;

  /// No description provided for @issueNoSpotSignal.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm alınamadı. Bilekliği biraz sıkılaştırıp tekrar deneyin.'**
  String get issueNoSpotSignal;

  /// No description provided for @issueNotPaired.
  ///
  /// In tr, this message translates to:
  /// **'Önce Profil > Cihaz bölümünden bilekliğinizi eşleştirin.'**
  String get issueNotPaired;

  /// No description provided for @languagePickHint.
  ///
  /// In tr, this message translates to:
  /// **'Daha sonra Profil ekranından değiştirebilirsiniz.'**
  String get languagePickHint;

  /// No description provided for @languagePickTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dilinizi seçin'**
  String get languagePickTitle;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun dili'**
  String get languageSystem;

  /// No description provided for @languageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageTitle;

  /// No description provided for @liveCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get liveCancel;

  /// No description provided for @liveConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz kaydedilip özet gösterilecek.'**
  String get liveConfirmBody;

  /// No description provided for @liveConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Egzersizi bitir'**
  String get liveConfirmTitle;

  /// No description provided for @liveContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get liveContinue;

  /// No description provided for @liveFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get liveFinish;

  /// No description provided for @liveInactiveBody.
  ///
  /// In tr, this message translates to:
  /// **'Son {minutes} dakikada {steps} adımdan az attınız. Egzersizi bitirmek ister misiniz?'**
  String liveInactiveBody(int minutes, int steps);

  /// No description provided for @liveInactiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsiz görünüyorsunuz'**
  String get liveInactiveTitle;

  /// No description provided for @livePause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get livePause;

  /// No description provided for @livePaused.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get livePaused;

  /// No description provided for @measureEcg.
  ///
  /// In tr, this message translates to:
  /// **'EKG'**
  String get measureEcg;

  /// No description provided for @measureEcgHint.
  ///
  /// In tr, this message translates to:
  /// **'Parmağınızı elektroda dokundurarak'**
  String get measureEcgHint;

  /// No description provided for @measureHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Nabız'**
  String get measureHeartRate;

  /// No description provided for @measureSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne ölçmek istersiniz?'**
  String get measureSheetTitle;

  /// No description provided for @measureSpo2.
  ///
  /// In tr, this message translates to:
  /// **'Kan oksijeni (SpO2)'**
  String get measureSpo2;

  /// No description provided for @measureTakes.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşık {seconds} saniye sürer'**
  String measureTakes(Object seconds);

  /// No description provided for @metricBmi.
  ///
  /// In tr, this message translates to:
  /// **'VKİ'**
  String get metricBmi;

  /// No description provided for @metricBodyFat.
  ///
  /// In tr, this message translates to:
  /// **'Vücut yağ oranı'**
  String get metricBodyFat;

  /// No description provided for @metricCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get metricCalories;

  /// No description provided for @metricDetailAbove.
  ///
  /// In tr, this message translates to:
  /// **'> {value}'**
  String metricDetailAbove(Object value);

  /// No description provided for @metricDetailBands.
  ///
  /// In tr, this message translates to:
  /// **'Aralıklar'**
  String get metricDetailBands;

  /// Tansiyonun tahmini olduğu notu; her dilde bu anlam korunmalı.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik tansiyonu tahmini olarak hesaplar. Tanı ve tedavi için onaylı bir tansiyon aleti kullanın.'**
  String get metricDetailBpEstimate;

  /// No description provided for @metricDetailDailyAverage.
  ///
  /// In tr, this message translates to:
  /// **'Günlük ortalama'**
  String get metricDetailDailyAverage;

  /// No description provided for @metricDetailNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get metricDetailNext;

  /// No description provided for @metricDetailNoData.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönem için kayıt yok'**
  String get metricDetailNoData;

  /// No description provided for @metricDetailPrevious.
  ///
  /// In tr, this message translates to:
  /// **'Önceki'**
  String get metricDetailPrevious;

  /// No description provided for @metricDetailTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get metricDetailTotal;

  /// No description provided for @metricDetailWeekRange.
  ///
  /// In tr, this message translates to:
  /// **'{start} - {end}'**
  String metricDetailWeekRange(Object start, Object end);

  /// No description provided for @metricDiastolic.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon (küçük)'**
  String get metricDiastolic;

  /// No description provided for @metricDistance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get metricDistance;

  /// No description provided for @metricHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Kalp Atış Hızı'**
  String get metricHeartRate;

  /// No description provided for @metricHrv.
  ///
  /// In tr, this message translates to:
  /// **'Kalp Atış Hızı Değişkenliği'**
  String get metricHrv;

  /// No description provided for @metricMuscleMass.
  ///
  /// In tr, this message translates to:
  /// **'Kas kütlesi'**
  String get metricMuscleMass;

  /// No description provided for @metricPpi.
  ///
  /// In tr, this message translates to:
  /// **'Atım aralığı'**
  String get metricPpi;

  /// No description provided for @metricRespiratoryRate.
  ///
  /// In tr, this message translates to:
  /// **'Solunum Hızı'**
  String get metricRespiratoryRate;

  /// No description provided for @metricSpo2.
  ///
  /// In tr, this message translates to:
  /// **'Kan Oksijen Doygunluğu'**
  String get metricSpo2;

  /// No description provided for @metricSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adım'**
  String get metricSteps;

  /// No description provided for @metricStress.
  ///
  /// In tr, this message translates to:
  /// **'Stres'**
  String get metricStress;

  /// No description provided for @metricSystolic.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon (büyük)'**
  String get metricSystolic;

  /// No description provided for @metricTemperature.
  ///
  /// In tr, this message translates to:
  /// **'Vücut Isısı'**
  String get metricTemperature;

  /// No description provided for @metricWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get metricWeight;

  /// No description provided for @navExercise.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz'**
  String get navExercise;

  /// No description provided for @navHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get navHealth;

  /// No description provided for @navHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navHome;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Ana menü'**
  String get navSemantics;

  /// No description provided for @noValue.
  ///
  /// In tr, this message translates to:
  /// **'--'**
  String get noValue;

  /// No description provided for @pairBluetoothDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik aramak için Bluetooth izni gerekiyor. Telefonun ayarlarından bu uygulamaya izin verip tekrar deneyin.'**
  String get pairBluetoothDenied;

  /// No description provided for @pairBluetoothOff.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth kapalı. Telefonun Bluetooth'unu açıp tekrar deneyin.'**
  String get pairBluetoothOff;

  /// No description provided for @pairBluetoothUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz bilekliğin kullandığı Bluetooth Low Energy'yi desteklemiyor.'**
  String get pairBluetoothUnsupported;

  /// No description provided for @pairCode.
  ///
  /// In tr, this message translates to:
  /// **'Adresle eşleştir'**
  String get pairCode;

  /// No description provided for @pairCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'Kutudaki ya da bilekliğin arkasındaki QR kodunun altında yazan adresi girin.'**
  String get pairCodeHint;

  /// No description provided for @pairCodeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Adres 12 karakterdir, ör. A1:B2:C3:D4:E5:F6'**
  String get pairCodeInvalid;

  /// No description provided for @pairCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz adresi'**
  String get pairCodeLabel;

  /// No description provided for @pairCodeNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu adreste bir bileklik bulunamadı.'**
  String get pairCodeNotFound;

  /// No description provided for @pairConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlan'**
  String get pairConnect;

  /// No description provided for @pairConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik bağlandı.'**
  String get pairConnected;

  /// No description provided for @pairFound.
  ///
  /// In tr, this message translates to:
  /// **'Bulunan bileklikler'**
  String get pairFound;

  /// No description provided for @pairNoneFound.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik bulunamadı. Şarjlı ve yakında olduğundan emin olup tekrar deneyin.'**
  String get pairNoneFound;

  /// No description provided for @pairNote.
  ///
  /// In tr, this message translates to:
  /// **'Bilekliği şarj edin ve telefonun yakınında tutun. Bluetooth açık olmalı.'**
  String get pairNote;

  /// No description provided for @pairQr.
  ///
  /// In tr, this message translates to:
  /// **'QR kodu tara'**
  String get pairQr;

  /// No description provided for @pairQrHint.
  ///
  /// In tr, this message translates to:
  /// **'Kutudaki ya da bilekliğin arkasındaki QR kodunu çerçevenin içine getirin.'**
  String get pairQrHint;

  /// No description provided for @pairQrInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Bu QR kodunda bileklik adresi yok.'**
  String get pairQrInvalid;

  /// No description provided for @pairScan.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı başlat'**
  String get pairScan;

  /// No description provided for @pairScanning.
  ///
  /// In tr, this message translates to:
  /// **'Aranıyor…'**
  String get pairScanning;

  /// No description provided for @pairSignal.
  ///
  /// In tr, this message translates to:
  /// **'Sinyal {rssi}'**
  String pairSignal(Object rssi);

  /// No description provided for @pairSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilekliğinizi bağlayın, ölçümleriniz telefonunuza gelsin.'**
  String get pairSubtitle;

  /// No description provided for @pairTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik eşleştirme'**
  String get pairTitle;

  /// No description provided for @periodDay.
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get periodDay;

  /// No description provided for @periodMonth.
  ///
  /// In tr, this message translates to:
  /// **'Ay'**
  String get periodMonth;

  /// No description provided for @periodWeek.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get periodWeek;

  /// No description provided for @personalInfoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel bilgiler'**
  String get personalInfoTitle;

  /// No description provided for @profileAge.
  ///
  /// In tr, this message translates to:
  /// **'Yaş'**
  String get profileAge;

  /// No description provided for @profileConnectFirst.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri kaydetmek için önce bilekliği bağlayın.'**
  String get profileConnectFirst;

  /// No description provided for @profileDevice.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz: {mac}'**
  String profileDevice(Object mac);

  /// No description provided for @profileFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get profileFemale;

  /// No description provided for @profileHeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy'**
  String get profileHeight;

  /// No description provided for @profileMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get profileMale;

  /// No description provided for @profileMenuAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get profileMenuAbout;

  /// No description provided for @profileMenuCommunity.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık topluluğu'**
  String get profileMenuCommunity;

  /// No description provided for @profileMenuCommunitySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aile grupları ve paylaşım izinleri'**
  String get profileMenuCommunitySubtitle;

  /// No description provided for @profileMenuDevice.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz'**
  String get profileMenuDevice;

  /// No description provided for @profileMenuDeviceConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı · pil %{battery}'**
  String profileMenuDeviceConnected(Object battery);

  /// No description provided for @profileMenuDeviceNone.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik bağlı değil'**
  String get profileMenuDeviceNone;

  /// No description provided for @profileMenuExport.
  ///
  /// In tr, this message translates to:
  /// **'Verilerimi dışa aktar'**
  String get profileMenuExport;

  /// No description provided for @profileMenuExportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hekiminize ya da başka bir uygulamaya FHIR dosyası'**
  String get profileMenuExportSubtitle;

  /// No description provided for @profileMenuFeedback.
  ///
  /// In tr, this message translates to:
  /// **'Geri bildirim'**
  String get profileMenuFeedback;

  /// No description provided for @profileMenuGeneral.
  ///
  /// In tr, this message translates to:
  /// **'Genel ayarlar'**
  String get profileMenuGeneral;

  /// No description provided for @profileMenuGeneralSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil, saat biçimi, birimler'**
  String get profileMenuGeneralSubtitle;

  /// No description provided for @profileMenuPersonalEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yaş, boy ve kilonuzu girin'**
  String get profileMenuPersonalEmpty;

  /// No description provided for @profileMenuPersonalSummary.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaş · {height} cm · {weight} kg'**
  String profileMenuPersonalSummary(Object age, Object height, Object weight);

  /// No description provided for @profileMenuResearch.
  ///
  /// In tr, this message translates to:
  /// **'Hekim ve araştırma kurumu'**
  String get profileMenuResearch;

  /// No description provided for @profileMenuResearchSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Davet koduyla veri paylaşımı'**
  String get profileMenuResearchSubtitle;

  /// No description provided for @profileMenuThirdParty.
  ///
  /// In tr, this message translates to:
  /// **'Health Connect ve Apple Health'**
  String get profileMenuThirdParty;

  /// No description provided for @profileMenuThirdPartySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Verileri telefonun sağlık uygulamasına aktar'**
  String get profileMenuThirdPartySubtitle;

  /// No description provided for @profileMenuVersion.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama sürümü'**
  String get profileMenuVersion;

  /// No description provided for @profileRangeError.
  ///
  /// In tr, this message translates to:
  /// **'{min} ile {max} arasında olmalı'**
  String profileRangeError(Object min, Object max);

  /// No description provided for @profileSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In tr, this message translates to:
  /// **'Bilgiler bilekliğe kaydedildi'**
  String get profileSaved;

  /// No description provided for @profileSectionApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama'**
  String get profileSectionApp;

  /// No description provided for @profileSectionSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get profileSectionSettings;

  /// No description provided for @profileSectionSharing.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım ve bağlantılar'**
  String get profileSectionSharing;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileUnitCm.
  ///
  /// In tr, this message translates to:
  /// **'cm'**
  String get profileUnitCm;

  /// No description provided for @profileUnitKg.
  ///
  /// In tr, this message translates to:
  /// **'kg'**
  String get profileUnitKg;

  /// No description provided for @profileUnitYears.
  ///
  /// In tr, this message translates to:
  /// **'yıl'**
  String get profileUnitYears;

  /// No description provided for @profileWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get profileWeight;

  /// No description provided for @progressTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get progressTitle;

  /// No description provided for @qrCameraDenied.
  ///
  /// In tr, this message translates to:
  /// **'Kamera izni verilmedi. Telefonun ayarlarından izin verin ya da kodu elle girin.'**
  String get qrCameraDenied;

  /// No description provided for @qrCameraUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Kamera açılamadı. Kodu elle girebilirsiniz.'**
  String get qrCameraUnavailable;

  /// No description provided for @qrManual.
  ///
  /// In tr, this message translates to:
  /// **'Kodu elle gir'**
  String get qrManual;

  /// No description provided for @reminderAddMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç saati ekle'**
  String get reminderAddMedication;

  /// No description provided for @reminderAddWater.
  ///
  /// In tr, this message translates to:
  /// **'Su saati ekle'**
  String get reminderAddWater;

  /// No description provided for @reminderAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Çalar saat'**
  String get reminderAlarm;

  /// No description provided for @reminderCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Hatırlatıcı yok} =1{1 hatırlatıcı} other{{count} hatırlatıcı}}'**
  String reminderCount(int count);

  /// No description provided for @reminderCountSedentary.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Yalnızca hareketsizlik uyarısı} =1{1 hatırlatıcı ve hareketsizlik uyarısı} other{{count} hatırlatıcı ve hareketsizlik uyarısı}}'**
  String reminderCountSedentary(int count);

  /// No description provided for @reminderDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get reminderDelete;

  /// No description provided for @reminderDuplicate.
  ///
  /// In tr, this message translates to:
  /// **'Bu saatte aynı türde bir hatırlatıcı zaten var.'**
  String get reminderDuplicate;

  /// No description provided for @reminderEdit.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcıyı düzenle'**
  String get reminderEdit;

  /// No description provided for @reminderEmptyMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç saatlerinizi ekleyin; bileklik o saatte titrer.'**
  String get reminderEmptyMedication;

  /// No description provided for @reminderEmptyWater.
  ///
  /// In tr, this message translates to:
  /// **'Gün içinde su içmeyi hatırlatması için saat ekleyin.'**
  String get reminderEmptyWater;

  /// No description provided for @reminderLabel.
  ///
  /// In tr, this message translates to:
  /// **'İlaç adı (isteğe bağlı)'**
  String get reminderLabel;

  /// No description provided for @reminderLabelHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. Sabah ilacı'**
  String get reminderLabelHint;

  /// No description provided for @reminderMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get reminderMedication;

  /// No description provided for @reminderNewMedication.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ilaç hatırlatıcısı'**
  String get reminderNewMedication;

  /// No description provided for @reminderNewWater.
  ///
  /// In tr, this message translates to:
  /// **'Yeni su hatırlatıcısı'**
  String get reminderNewWater;

  /// No description provided for @reminderSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get reminderSave;

  /// No description provided for @reminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get reminderTime;

  /// No description provided for @reminderWater.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get reminderWater;

  /// No description provided for @reminderWeekdays.
  ///
  /// In tr, this message translates to:
  /// **'Hafta içi'**
  String get reminderWeekdays;

  /// No description provided for @reminderWeekend.
  ///
  /// In tr, this message translates to:
  /// **'Hafta sonu'**
  String get reminderWeekend;

  /// No description provided for @remindersFull.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik en fazla {max} hatırlatıcı tutabilir.'**
  String remindersFull(int max);

  /// No description provided for @remindersIntro.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma saati gelince bileklik titrer; telefona bildirim gelmez.'**
  String get remindersIntro;

  /// No description provided for @remindersLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar bileklikten okunamadı.'**
  String get remindersLoadFailed;

  /// No description provided for @remindersNotConnected.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcıları görmek ve değiştirmek için bilekliği bağlayın.'**
  String get remindersNotConnected;

  /// No description provided for @remindersSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı bilekliğe yazılamadı. Tekrar deneyin.'**
  String get remindersSaveFailed;

  /// No description provided for @remindersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar'**
  String get remindersTitle;

  /// No description provided for @reportAverageSteps.
  ///
  /// In tr, this message translates to:
  /// **'Günlük ortalama adım'**
  String get reportAverageSteps;

  /// No description provided for @reportDown.
  ///
  /// In tr, this message translates to:
  /// **'Azaldı'**
  String get reportDown;

  /// No description provided for @reportEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta için veri yok.'**
  String get reportEmpty;

  /// No description provided for @reportGoalDays.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe ulaşılan gün'**
  String get reportGoalDays;

  /// No description provided for @reportHrv.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama HRV'**
  String get reportHrv;

  /// No description provided for @reportSleep.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama uyku'**
  String get reportSleep;

  /// No description provided for @reportSteps.
  ///
  /// In tr, this message translates to:
  /// **'Toplam adım'**
  String get reportSteps;

  /// No description provided for @reportStress.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama stres'**
  String get reportStress;

  /// No description provided for @reportUp.
  ///
  /// In tr, this message translates to:
  /// **'Arttı'**
  String get reportUp;

  /// No description provided for @reportVsPrevious.
  ///
  /// In tr, this message translates to:
  /// **'Oklar önceki haftaya göre değişimi gösterir.'**
  String get reportVsPrevious;

  /// No description provided for @reportWorkouts.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz'**
  String get reportWorkouts;

  /// No description provided for @reportWorkoutsValue.
  ///
  /// In tr, this message translates to:
  /// **'{count} kez · {time}'**
  String reportWorkoutsValue(Object count, Object time);

  /// No description provided for @sedentaryHours.
  ///
  /// In tr, this message translates to:
  /// **'{hours, plural, =1{1 saat} other{{hours} saat}}'**
  String sedentaryHours(int hours);

  /// No description provided for @sedentaryHoursMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String sedentaryHoursMinutes(int hours, int minutes);

  /// No description provided for @sedentaryInterval.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsiz kalma süresi'**
  String get sedentaryInterval;

  /// No description provided for @sedentaryMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika'**
  String sedentaryMinutes(int minutes);

  /// No description provided for @sedentaryNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu sürede {steps} adımdan az atarsanız uyarı gelir.'**
  String sedentaryNote(int steps);

  /// No description provided for @sedentarySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{time} boyunca kıpırdamazsanız bileklik titrer.'**
  String sedentarySubtitle(String time);

  /// No description provided for @sedentaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsizlik uyarısı'**
  String get sedentaryTitle;

  /// No description provided for @shareActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite ve adım'**
  String get shareActivity;

  /// No description provided for @shareBloodPressure.
  ///
  /// In tr, this message translates to:
  /// **'Tansiyon (tahmini)'**
  String get shareBloodPressure;

  /// No description provided for @shareEcg.
  ///
  /// In tr, this message translates to:
  /// **'EKG kayıtları'**
  String get shareEcg;

  /// No description provided for @shareHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Nabız'**
  String get shareHeartRate;

  /// No description provided for @shareSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get shareSleep;

  /// No description provided for @shareSpo2.
  ///
  /// In tr, this message translates to:
  /// **'Kan oksijeni (SpO2)'**
  String get shareSpo2;

  /// No description provided for @shareStress.
  ///
  /// In tr, this message translates to:
  /// **'Stres ve HRV'**
  String get shareStress;

  /// No description provided for @shareTemperature.
  ///
  /// In tr, this message translates to:
  /// **'Vücut ısısı'**
  String get shareTemperature;

  /// No description provided for @sleepAwake.
  ///
  /// In tr, this message translates to:
  /// **'Uyanık'**
  String get sleepAwake;

  /// No description provided for @sleepDeep.
  ///
  /// In tr, this message translates to:
  /// **'Derin'**
  String get sleepDeep;

  /// No description provided for @sleepDuration.
  ///
  /// In tr, this message translates to:
  /// **'Uyku süresi'**
  String get sleepDuration;

  /// No description provided for @sleepEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz uyku kaydı yok'**
  String get sleepEmpty;

  /// No description provided for @sleepLast7Nights.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gece'**
  String get sleepLast7Nights;

  /// No description provided for @sleepLight.
  ///
  /// In tr, this message translates to:
  /// **'Hafif'**
  String get sleepLight;

  /// No description provided for @sleepNextNight.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki gece'**
  String get sleepNextNight;

  /// No description provided for @sleepPercent.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String sleepPercent(Object value);

  /// No description provided for @sleepPreviousNight.
  ///
  /// In tr, this message translates to:
  /// **'Önceki gece'**
  String get sleepPreviousNight;

  /// No description provided for @sleepRem.
  ///
  /// In tr, this message translates to:
  /// **'REM'**
  String get sleepRem;

  /// No description provided for @sleepTimeRange.
  ///
  /// In tr, this message translates to:
  /// **'{start} - {end}'**
  String sleepTimeRange(Object start, Object end);

  /// No description provided for @sleepTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get sleepTitle;

  /// No description provided for @sleepWeekBarHint.
  ///
  /// In tr, this message translates to:
  /// **'{day}: {duration}'**
  String sleepWeekBarHint(Object day, Object duration);

  /// No description provided for @sportAerobics.
  ///
  /// In tr, this message translates to:
  /// **'Aerobik'**
  String get sportAerobics;

  /// No description provided for @sportBadminton.
  ///
  /// In tr, this message translates to:
  /// **'Badminton'**
  String get sportBadminton;

  /// No description provided for @sportBasketball.
  ///
  /// In tr, this message translates to:
  /// **'Basketbol'**
  String get sportBasketball;

  /// No description provided for @sportCricket.
  ///
  /// In tr, this message translates to:
  /// **'Kriket'**
  String get sportCricket;

  /// No description provided for @sportCycling.
  ///
  /// In tr, this message translates to:
  /// **'Bisiklet'**
  String get sportCycling;

  /// No description provided for @sportDance.
  ///
  /// In tr, this message translates to:
  /// **'Dans'**
  String get sportDance;

  /// No description provided for @sportFootball.
  ///
  /// In tr, this message translates to:
  /// **'Futbol'**
  String get sportFootball;

  /// No description provided for @sportHiking.
  ///
  /// In tr, this message translates to:
  /// **'Doğa yürüyüşü'**
  String get sportHiking;

  /// No description provided for @sportMeditation.
  ///
  /// In tr, this message translates to:
  /// **'Meditasyon'**
  String get sportMeditation;

  /// No description provided for @sportPingPong.
  ///
  /// In tr, this message translates to:
  /// **'Masa tenisi'**
  String get sportPingPong;

  /// No description provided for @sportRopeJump.
  ///
  /// In tr, this message translates to:
  /// **'İp atlama'**
  String get sportRopeJump;

  /// No description provided for @sportRun.
  ///
  /// In tr, this message translates to:
  /// **'Koşu'**
  String get sportRun;

  /// No description provided for @sportSitUps.
  ///
  /// In tr, this message translates to:
  /// **'Mekik'**
  String get sportSitUps;

  /// No description provided for @sportTennis.
  ///
  /// In tr, this message translates to:
  /// **'Tenis'**
  String get sportTennis;

  /// No description provided for @sportUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Egzersiz'**
  String get sportUnknown;

  /// No description provided for @sportVolleyball.
  ///
  /// In tr, this message translates to:
  /// **'Voleybol'**
  String get sportVolleyball;

  /// No description provided for @sportWalk.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş'**
  String get sportWalk;

  /// No description provided for @sportWorkout.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman'**
  String get sportWorkout;

  /// No description provided for @sportYoga.
  ///
  /// In tr, this message translates to:
  /// **'Yoga'**
  String get sportYoga;

  /// No description provided for @spotAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar ölç'**
  String get spotAgain;

  /// No description provided for @spotDone.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get spotDone;

  /// No description provided for @spotKeepStill.
  ///
  /// In tr, this message translates to:
  /// **'Bilekliği bileğinize oturtun, kolunuzu bir yere dayayıp hareket etmeyin.'**
  String get spotKeepStill;

  /// No description provided for @spotLowSpo2.
  ///
  /// In tr, this message translates to:
  /// **'Değer düşük. Dinlenip tekrar ölçün; düşük kalırsa hekiminize danışın.'**
  String get spotLowSpo2;

  /// No description provided for @spotMeasuring.
  ///
  /// In tr, this message translates to:
  /// **'Ölçülüyor…'**
  String get spotMeasuring;

  /// No description provided for @spotMoving.
  ///
  /// In tr, this message translates to:
  /// **'Hareket algılandı. Kolunuzu sabit tutun.'**
  String get spotMoving;

  /// No description provided for @spotNote.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik ölçümü tıbbi cihaz yerine geçmez.'**
  String get spotNote;

  /// No description provided for @spotOffWrist.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik bileğinizde görünmüyor. Takıp sıkıca oturtun.'**
  String get spotOffWrist;

  /// No description provided for @spotSaved.
  ///
  /// In tr, this message translates to:
  /// **'{time} ölçümü kaydedildi'**
  String spotSaved(Object time);

  /// No description provided for @statAverage.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama'**
  String get statAverage;

  /// No description provided for @statAvgHeartRate.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama nabız'**
  String get statAvgHeartRate;

  /// No description provided for @statDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get statDuration;

  /// No description provided for @statMax.
  ///
  /// In tr, this message translates to:
  /// **'En yüksek'**
  String get statMax;

  /// No description provided for @statMin.
  ///
  /// In tr, this message translates to:
  /// **'En düşük'**
  String get statMin;

  /// No description provided for @statPace.
  ///
  /// In tr, this message translates to:
  /// **'Tempo'**
  String get statPace;

  /// Yüzde değeri; dile göre % işaretinin yeri değişir.
  ///
  /// In tr, this message translates to:
  /// **'%{value}'**
  String statPercent(Object value);

  /// No description provided for @unitPerMinute.
  ///
  /// In tr, this message translates to:
  /// **'/dk'**
  String get unitPerMinute;

  /// No description provided for @unitSteps.
  ///
  /// In tr, this message translates to:
  /// **'adım'**
  String get unitSteps;

  /// No description provided for @unitsImperial.
  ///
  /// In tr, this message translates to:
  /// **'ABD (mil, °F)'**
  String get unitsImperial;

  /// No description provided for @unitsMetric.
  ///
  /// In tr, this message translates to:
  /// **'Metrik (km, °C)'**
  String get unitsMetric;

  /// No description provided for @unitsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birimler'**
  String get unitsTitle;

  /// No description provided for @vo2MaxBasis.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaş ve dinlenik nabız {resting} ile'**
  String vo2MaxBasis(Object age, Object resting);

  /// No description provided for @vo2MaxNeedsAge.
  ///
  /// In tr, this message translates to:
  /// **'Tahmin için yaşınız gerekiyor. Bilekliği bağlayıp Profil > Kişisel bilgiler'den girin.'**
  String get vo2MaxNeedsAge;

  /// No description provided for @vo2MaxNeedsData.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenik nabzı hesaplamak için birkaç günlük nabız ya da gece ölçümü gerekiyor.'**
  String get vo2MaxNeedsData;

  /// No description provided for @vo2MaxNote.
  ///
  /// In tr, this message translates to:
  /// **'Yaştan beklenen en yüksek nabız ile dinlenik nabzın oranından tahmin edilir; laboratuvar ölçümü değildir. Kondisyonunuzun eğilimini izlemek için kullanın.'**
  String get vo2MaxNote;

  /// No description provided for @vo2MaxTitle.
  ///
  /// In tr, this message translates to:
  /// **'VO2 Max tahmini'**
  String get vo2MaxTitle;

  /// No description provided for @vo2MaxValue.
  ///
  /// In tr, this message translates to:
  /// **'{value} ml/kg/dk'**
  String vo2MaxValue(Object value);

  /// No description provided for @wearDetectionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Takma algılama ayarı bilekliğe yazılamadı.'**
  String get wearDetectionFailed;

  /// No description provided for @wearDetectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm sırasında bileklik çıkarılırsa ya da kolunuz hareket ederse uyarır.'**
  String get wearDetectionSubtitle;

  /// No description provided for @wearDetectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takma algılama'**
  String get wearDetectionTitle;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık rapor'**
  String get weeklyReportTitle;

  /// No description provided for @workoutCongrats.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler, egzersiz kaydedildi'**
  String get workoutCongrats;

  /// No description provided for @workoutTimeRange.
  ///
  /// In tr, this message translates to:
  /// **'{day} · {start} - {end}'**
  String workoutTimeRange(Object day, Object start, Object end);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
