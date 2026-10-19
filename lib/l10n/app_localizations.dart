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

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bileklik'**
  String get appTitle;

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

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueButton;

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

  /// No description provided for @metricCalories.
  ///
  /// In tr, this message translates to:
  /// **'Kalori'**
  String get metricCalories;

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

  /// No description provided for @noValue.
  ///
  /// In tr, this message translates to:
  /// **'--'**
  String get noValue;

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

  /// No description provided for @sleepLight.
  ///
  /// In tr, this message translates to:
  /// **'Hafif'**
  String get sleepLight;

  /// No description provided for @sleepRem.
  ///
  /// In tr, this message translates to:
  /// **'REM'**
  String get sleepRem;

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
