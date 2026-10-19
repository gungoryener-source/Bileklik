// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bileklik';

  @override
  String get bandAnxious => 'Anxious';

  @override
  String get bandCalm => 'Calm';

  @override
  String get bandGood => 'Good';

  @override
  String get bandGreat => 'Great';

  @override
  String get bandLow => 'Low';

  @override
  String get bandMild => 'Mild';

  @override
  String get bandNormal => 'Normal';

  @override
  String get bandTense => 'Tense';

  @override
  String get continueButton => 'Continue';

  @override
  String durationHours(Object h) {
    return '$h h';
  }

  @override
  String durationHoursMinutes(Object h, Object m) {
    return '$h h $m min';
  }

  @override
  String durationMinutes(Object m) {
    return '$m min';
  }

  @override
  String get issueBusy =>
      'The wristband is busy with another exercise or measurement.';

  @override
  String get issueFailed =>
      'Could not reach the wristband. Make sure it is nearby and switched on.';

  @override
  String get issueNoEcgSignal =>
      'No ECG data received. Wear the wristband and touch the electrode with your finger.';

  @override
  String get languagePickHint =>
      'You can change this later on the Profile screen.';

  @override
  String get languagePickTitle => 'Choose your language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get languageTitle => 'Language';

  @override
  String get metricCalories => 'Calories';

  @override
  String get metricDiastolic => 'Blood Pressure (diastolic)';

  @override
  String get metricDistance => 'Distance';

  @override
  String get metricHeartRate => 'Heart Rate';

  @override
  String get metricHrv => 'Heart Rate Variability';

  @override
  String get metricRespiratoryRate => 'Respiratory Rate';

  @override
  String get metricSpo2 => 'Blood Oxygen';

  @override
  String get metricSteps => 'Steps';

  @override
  String get metricStress => 'Stress';

  @override
  String get metricSystolic => 'Blood Pressure (systolic)';

  @override
  String get metricTemperature => 'Body Temperature';

  @override
  String get navExercise => 'Exercise';

  @override
  String get navHealth => 'Health';

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profile';

  @override
  String get noValue => '--';

  @override
  String get periodDay => 'Day';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodWeek => 'Week';

  @override
  String get sleepAwake => 'Awake';

  @override
  String get sleepDeep => 'Deep';

  @override
  String get sleepLight => 'Light';

  @override
  String get sleepRem => 'REM';

  @override
  String get sportAerobics => 'Aerobics';

  @override
  String get sportBadminton => 'Badminton';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportCricket => 'Cricket';

  @override
  String get sportCycling => 'Cycling';

  @override
  String get sportDance => 'Dance';

  @override
  String get sportFootball => 'Football';

  @override
  String get sportHiking => 'Hiking';

  @override
  String get sportMeditation => 'Meditation';

  @override
  String get sportPingPong => 'Table tennis';

  @override
  String get sportRopeJump => 'Jump rope';

  @override
  String get sportRun => 'Running';

  @override
  String get sportSitUps => 'Sit-ups';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get sportUnknown => 'Exercise';

  @override
  String get sportVolleyball => 'Volleyball';

  @override
  String get sportWalk => 'Walking';

  @override
  String get sportWorkout => 'Workout';

  @override
  String get sportYoga => 'Yoga';

  @override
  String get unitPerMinute => '/min';

  @override
  String get unitSteps => 'steps';
}
