// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Bileklik';

  @override
  String get bandAnxious => 'Ängstlich';

  @override
  String get bandCalm => 'Ruhig';

  @override
  String get bandGood => 'Gut';

  @override
  String get bandGreat => 'Sehr gut';

  @override
  String get bandLow => 'Niedrig';

  @override
  String get bandMild => 'Leicht';

  @override
  String get bandNormal => 'Normal';

  @override
  String get bandTense => 'Angespannt';

  @override
  String get continueButton => 'Weiter';

  @override
  String durationHours(Object h) {
    return '$h Std.';
  }

  @override
  String durationHoursMinutes(Object h, Object m) {
    return '$h Std. $m Min.';
  }

  @override
  String durationMinutes(Object m) {
    return '$m Min.';
  }

  @override
  String get issueBusy =>
      'Das Armband ist gerade mit einem anderen Training oder einer Messung beschäftigt.';

  @override
  String get issueFailed =>
      'Das Armband ist nicht erreichbar. Achten Sie darauf, dass es in der Nähe und eingeschaltet ist.';

  @override
  String get issueNoEcgSignal =>
      'Keine EKG-Daten empfangen. Tragen Sie das Armband und berühren Sie die Elektrode mit dem Finger.';

  @override
  String get languagePickHint => 'Sie können dies später im Profil ändern.';

  @override
  String get languagePickTitle => 'Sprache wählen';

  @override
  String get languageSystem => 'Telefonsprache';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get metricCalories => 'Kalorien';

  @override
  String get metricDiastolic => 'Blutdruck (diastolisch)';

  @override
  String get metricDistance => 'Strecke';

  @override
  String get metricHeartRate => 'Herzfrequenz';

  @override
  String get metricHrv => 'Herzfrequenzvariabilität';

  @override
  String get metricRespiratoryRate => 'Atemfrequenz';

  @override
  String get metricSpo2 => 'Blutsauerstoff';

  @override
  String get metricSteps => 'Schritte';

  @override
  String get metricStress => 'Stress';

  @override
  String get metricSystolic => 'Blutdruck (systolisch)';

  @override
  String get metricTemperature => 'Körpertemperatur';

  @override
  String get navExercise => 'Training';

  @override
  String get navHealth => 'Gesundheit';

  @override
  String get navHome => 'Start';

  @override
  String get navProfile => 'Profil';

  @override
  String get noValue => '--';

  @override
  String get periodDay => 'Tag';

  @override
  String get periodMonth => 'Monat';

  @override
  String get periodWeek => 'Woche';

  @override
  String get sleepAwake => 'Wach';

  @override
  String get sleepDeep => 'Tief';

  @override
  String get sleepLight => 'Leicht';

  @override
  String get sleepRem => 'REM';

  @override
  String get sportAerobics => 'Aerobic';

  @override
  String get sportBadminton => 'Badminton';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportCricket => 'Cricket';

  @override
  String get sportCycling => 'Radfahren';

  @override
  String get sportDance => 'Tanzen';

  @override
  String get sportFootball => 'Fußball';

  @override
  String get sportHiking => 'Wandern';

  @override
  String get sportMeditation => 'Meditation';

  @override
  String get sportPingPong => 'Tischtennis';

  @override
  String get sportRopeJump => 'Seilspringen';

  @override
  String get sportRun => 'Laufen';

  @override
  String get sportSitUps => 'Sit-ups';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportUnknown => 'Training';

  @override
  String get sportVolleyball => 'Volleyball';

  @override
  String get sportWalk => 'Gehen';

  @override
  String get sportWorkout => 'Workout';

  @override
  String get sportYoga => 'Yoga';

  @override
  String get unitPerMinute => '/Min.';

  @override
  String get unitSteps => 'Schritte';
}
