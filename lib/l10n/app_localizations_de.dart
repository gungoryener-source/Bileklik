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
  String ecgAverageBpm(Object bpm) {
    return 'Ø $bpm bpm';
  }

  @override
  String get ecgAverageHeartRate => 'Durchschnittspuls';

  @override
  String get ecgBeats => 'Schläge';

  @override
  String get ecgBpm => 'bpm';

  @override
  String get ecgCancel => 'Messung abbrechen';

  @override
  String get ecgConnectFirst =>
      'Verbinden Sie zuerst das Armband auf der Startseite.';

  @override
  String ecgDetailTitle(Object date, Object time) {
    return 'EKG · $date $time';
  }

  @override
  String get ecgDisclaimer =>
      'Diese Messung ersetzt keine ärztliche Diagnose. Wenn Sie Brustschmerzen, Atemnot oder ein Ohnmachtsgefühl haben, rufen Sie sofort die 112 an.';

  @override
  String get ecgHowToSteps =>
      '1. Tragen Sie das Armband fest am Handgelenk.\n2. Setzen Sie sich und legen Sie den Arm auf einen Tisch.\n3. Berühren Sie mit einem Finger der anderen Hand leicht die Elektrode oben auf dem Armband.\n4. Bewegen Sie sich 30 Sekunden lang nicht und sprechen Sie nicht.';

  @override
  String get ecgHowToTitle => 'So messen Sie';

  @override
  String get ecgKeepStill =>
      'Lassen Sie den Finger auf der Elektrode und bewegen Sie sich nicht.';

  @override
  String get ecgMeasuringTitle => 'EKG wird gemessen';

  @override
  String get ecgMs => 'ms';

  @override
  String get ecgNoHeartRate => 'Puls konnte nicht berechnet werden';

  @override
  String get ecgNoRecords => 'Noch keine EKG-Aufzeichnungen.';

  @override
  String get ecgRange => 'Bereich';

  @override
  String ecgRangeValue(Object min, Object max) {
    return '$min-$max';
  }

  @override
  String ecgRecordHeader(Object seconds, Object perRow) {
    return 'Aufzeichnung ($seconds s, $perRow s pro Zeile)';
  }

  @override
  String ecgRecordSubtitle(Object when, Object seconds) {
    return '$when · $seconds s';
  }

  @override
  String get ecgRecordsTitle => 'Aufzeichnungen';

  @override
  String get ecgSdnn => 'Variabilität (SDNN)';

  @override
  String ecgSecondsLeft(Object seconds) {
    return '$seconds s';
  }

  @override
  String get ecgStartButton => '30-Sekunden-Messung starten';

  @override
  String get ecgTitle => 'EKG';

  @override
  String get exerciseConnectFirst =>
      'Verbinden Sie zuerst das Armband auf der Startseite.';

  @override
  String get exerciseConnectHint =>
      'Verbinden Sie das Armband, um frühere Trainings zu sehen.';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Trainings',
      one: '1 Training',
    );
    return '$_temp0';
  }

  @override
  String get exerciseEmpty => 'Noch keine Trainings.';

  @override
  String exerciseInProgress(Object sport) {
    return '$sport läuft';
  }

  @override
  String get exerciseLast30Days => 'Letzte 30 Tage';

  @override
  String exercisePausedAt(Object time) {
    return 'Pausiert · $time';
  }

  @override
  String get exerciseStart => 'Training starten';

  @override
  String get exerciseThisWeek => 'Diese Woche';

  @override
  String get healthBloodPressure => 'Blutdruck';

  @override
  String healthBloodPressureSubtitle(Object details) {
    return 'Geschätzt · $details';
  }

  @override
  String get healthConnectHint =>
      'Verbinden Sie das Armband auf der Startseite, um Ihre Daten zu sehen.';

  @override
  String get healthEcg => 'EKG';

  @override
  String healthEcgLast(Object time) {
    return 'Letzte Messung · $time';
  }

  @override
  String get healthEcgPrompt => '30-Sekunden-Messung starten';

  @override
  String healthLastSync(Object time) {
    return 'Zuletzt aktualisiert $time';
  }

  @override
  String get healthNoMeasurement => 'Keine Messwerte';

  @override
  String get healthNoRecord => 'Keine Daten';

  @override
  String get healthSleep => 'Schlaf';

  @override
  String healthSleepLastNight(Object start, Object end) {
    return 'Letzte Nacht · $start - $end';
  }

  @override
  String healthStepsToday(Object goal) {
    return 'Heute · Ziel $goal';
  }

  @override
  String get healthSyncTooltip => 'Vom Armband aktualisieren';

  @override
  String get healthSyncing => 'Daten werden vom Armband geladen…';

  @override
  String get homeActivity => 'Aktivität';

  @override
  String get homeAverageStress => 'Durchschnittlicher Stress';

  @override
  String homeAverageStressBand(Object band) {
    return 'Durchschnittlicher Stress · $band';
  }

  @override
  String homeAverageValue(Object value) {
    return 'Ø $value';
  }

  @override
  String get homeBalance => 'Balance';

  @override
  String get homeBloodOxygen => 'Blutsauerstoff';

  @override
  String homeBpm(Object value) {
    return '$value bpm';
  }

  @override
  String get homeCaloriesKcal => 'Kalorien (kcal)';

  @override
  String homeChartNoData(Object title) {
    return '$title: keine Messwerte';
  }

  @override
  String homeChartSemantics(Object title, Object min, Object max, Object unit) {
    return '$title: niedrigster Wert $min, höchster Wert $max $unit';
  }

  @override
  String get homeConnect => 'Verbinden';

  @override
  String get homeConnectTooltip => 'Mit Armband verbinden';

  @override
  String get homeConnected => 'Verbunden';

  @override
  String homeConnectedBattery(Object percent) {
    return 'Verbunden · $percent %';
  }

  @override
  String get homeConnecting => 'Verbindung wird hergestellt…';

  @override
  String get homeDaySummary => 'Tagesübersicht';

  @override
  String homeDeepSleep(Object duration) {
    return 'Tiefschlaf $duration';
  }

  @override
  String get homeDisconnectTooltip => 'Verbindung trennen';

  @override
  String get homeDuration => 'Dauer';

  @override
  String get homeEcg => 'EKG';

  @override
  String homeEcgSubtitle(Object bpm, Object seconds) {
    return '$bpm bpm · $seconds s';
  }

  @override
  String homeEcgSubtitleNoHr(Object seconds) {
    return '$seconds s';
  }

  @override
  String get homeGoodAfternoon => 'Guten Tag';

  @override
  String get homeGoodEvening => 'Guten Abend';

  @override
  String get homeGoodMorning => 'Guten Morgen';

  @override
  String get homeHeartRateHint =>
      'Tragen Sie das Armband den ganzen Tag, um Ihre Herzfrequenz zu sehen.';

  @override
  String get homeHeartRateLabel => 'Herzfrequenz';

  @override
  String get homeHourlyStressSemantics => 'Stress pro Stunde (Balken)';

  @override
  String get homeHrvLabel => 'Herzfrequenzvariabilität';

  @override
  String get homeKilometers => 'Kilometer';

  @override
  String get homeListSeparator => ', ';

  @override
  String get homeMeasureEcg => 'EKG messen';

  @override
  String homeMs(Object value) {
    return '$value ms';
  }

  @override
  String get homeNextDay => 'Nächster Tag';

  @override
  String get homeNoRecord => 'Keine Daten';

  @override
  String get homeNoSleepLastNight => 'Letzte Nacht wurde kein Schlaf erfasst';

  @override
  String get homeNoSleepPastHint =>
      'Hier erscheint die Übersicht für Tage, an denen Sie das Armband getragen haben.';

  @override
  String get homeNoSleepStages => 'Keine Schlafphasen';

  @override
  String get homeNoSleepThisDay => 'Für diesen Tag gibt es keine Schlafdaten';

  @override
  String get homeNoSleepTonightHint =>
      'Tragen Sie das Armband heute Nacht – morgen früh finden Sie hier Ihre Schlaf- und Erholungsübersicht.';

  @override
  String homePercent(Object value) {
    return '$value %';
  }

  @override
  String get homePickDay => 'Tag auswählen';

  @override
  String get homePrevDay => 'Vorheriger Tag';

  @override
  String get homeProfileTooltip => 'Profil';

  @override
  String homeRange(Object min, Object max) {
    return '$min–$max';
  }

  @override
  String get homeRecovery => 'Erholung';

  @override
  String get homeSleep => 'Schlaf';

  @override
  String homeSleepStageItem(Object stage, Object duration) {
    return '$stage $duration';
  }

  @override
  String homeSleepStagesSemantics(Object stages) {
    return 'Schlafphasen: $stages';
  }

  @override
  String homeSleptHrvBandSummary(Object duration, Object hrv, Object band) {
    return 'Sie haben $duration geschlafen, Ihre nächtliche HRV lag im Mittel bei $hrv ms ($band).';
  }

  @override
  String homeSleptHrvSummary(Object duration, Object hrv) {
    return 'Sie haben $duration geschlafen, Ihre nächtliche HRV lag im Mittel bei $hrv ms.';
  }

  @override
  String homeSleptSummary(Object duration) {
    return 'Sie haben $duration geschlafen.';
  }

  @override
  String get homeSpo2Hint =>
      'Tragen Sie das Armband den ganzen Tag, um Ihren Blutsauerstoff zu sehen.';

  @override
  String get homeStartWorkout => 'Training starten';

  @override
  String homeStepGoal(Object goal) {
    return 'Ziel: $goal Schritte';
  }

  @override
  String homeStepGoalProgress(Object percent, Object goal) {
    return '$percent % · Ziel $goal';
  }

  @override
  String homeStepGoalSemantics(Object steps, Object goal, Object percent) {
    return 'Schrittziel: $steps von $goal, $percent Prozent';
  }

  @override
  String get homeSteps => 'Schritte';

  @override
  String get homeStressHint =>
      'Stress und HRV werden tagsüber gemessen, während Sie das Armband tragen.';

  @override
  String get homeStressLevel => 'Stresslevel';

  @override
  String get homeStressLoad => 'Stressbelastung';

  @override
  String get homeSyncTooltip => 'Synchronisieren';

  @override
  String get homeTimeline => 'Zeitachse';

  @override
  String get homeTimelineEmpty =>
      'Ihre Trainings, EKGs und Schlafdaten erscheinen hier in zeitlicher Reihenfolge.';

  @override
  String get homeTimelineSubtitle => 'Einträge des Tages';

  @override
  String homeTodayDate(Object date) {
    return 'Heute, $date';
  }

  @override
  String homeWeekdayDate(Object weekday, Object date) {
    return '$weekday, $date';
  }

  @override
  String get homeWokeUp => 'Aufgewacht';

  @override
  String homeWokeUpSubtitle(Object duration, Object time) {
    return '$duration Schlaf · zu Bett um $time';
  }

  @override
  String homeWorkoutSubtitle(Object duration, Object kcal) {
    return '$duration · $kcal kcal';
  }

  @override
  String homeYesterdayDate(Object date) {
    return 'Gestern, $date';
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
  String get liveCancel => 'Abbrechen';

  @override
  String get liveConfirmBody =>
      'Das Training wird gespeichert und eine Zusammenfassung angezeigt.';

  @override
  String get liveConfirmTitle => 'Training beenden';

  @override
  String get liveContinue => 'Fortsetzen';

  @override
  String get liveFinish => 'Beenden';

  @override
  String liveInactiveBody(int minutes, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'Sie sind in den letzten $minutes Minuten weniger als $steps Schritte gegangen. Möchten Sie das Training beenden?',
      one:
          'Sie sind in der letzten Minute weniger als $steps Schritte gegangen. Möchten Sie das Training beenden?',
    );
    return '$_temp0';
  }

  @override
  String get liveInactiveTitle => 'Sie scheinen sich nicht zu bewegen';

  @override
  String get livePause => 'Pausieren';

  @override
  String get livePaused => 'Pausiert';

  @override
  String get metricCalories => 'Kalorien';

  @override
  String metricDetailAbove(Object value) {
    return '> $value';
  }

  @override
  String get metricDetailBands => 'Bereiche';

  @override
  String get metricDetailBpEstimate =>
      'Der Blutdruck des Armbands ist ein Schätzwert. Verwenden Sie für Diagnose und Behandlung ein zugelassenes Blutdruckmessgerät.';

  @override
  String get metricDetailDailyAverage => 'Tagesdurchschnitt';

  @override
  String get metricDetailNext => 'Weiter';

  @override
  String get metricDetailNoData => 'Keine Daten für diesen Zeitraum';

  @override
  String get metricDetailPrevious => 'Zurück';

  @override
  String get metricDetailTotal => 'Gesamt';

  @override
  String metricDetailWeekRange(Object start, Object end) {
    return '$start – $end';
  }

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
  String get profileAge => 'Alter';

  @override
  String get profileAppearance => 'Darstellung';

  @override
  String get profileConnectFirst =>
      'Verbinden Sie zuerst das Armband, um Ihre Angaben zu speichern.';

  @override
  String profileDevice(Object mac) {
    return 'Gerät: $mac';
  }

  @override
  String get profileFemale => 'Weiblich';

  @override
  String get profileHeight => 'Größe';

  @override
  String get profileMale => 'Männlich';

  @override
  String profileRangeError(Object min, Object max) {
    return 'Muss zwischen $min und $max liegen';
  }

  @override
  String get profileSave => 'Speichern';

  @override
  String get profileSaved => 'Angaben auf dem Armband gespeichert';

  @override
  String get profileThemeDark => 'Dunkel';

  @override
  String get profileThemeLight => 'Hell';

  @override
  String get profileThemeSystem => 'System';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileUnitCm => 'cm';

  @override
  String get profileUnitKg => 'kg';

  @override
  String get profileUnitYears => 'Jahre';

  @override
  String get profileWeight => 'Gewicht';

  @override
  String get sleepAwake => 'Wach';

  @override
  String get sleepDeep => 'Tief';

  @override
  String get sleepDuration => 'Schlafdauer';

  @override
  String get sleepEmpty => 'Noch keine Schlafdaten';

  @override
  String get sleepLast7Nights => 'Letzte 7 Nächte';

  @override
  String get sleepLight => 'Leicht';

  @override
  String get sleepNextNight => 'Nächste Nacht';

  @override
  String sleepPercent(Object value) {
    return '$value %';
  }

  @override
  String get sleepPreviousNight => 'Vorherige Nacht';

  @override
  String get sleepRem => 'REM';

  @override
  String sleepTimeRange(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get sleepTitle => 'Schlaf';

  @override
  String sleepWeekBarHint(Object day, Object duration) {
    return '$day: $duration';
  }

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
  String get statAverage => 'Durchschnitt';

  @override
  String get statAvgHeartRate => 'Ø Puls';

  @override
  String get statDuration => 'Dauer';

  @override
  String get statMax => 'Höchstwert';

  @override
  String get statMin => 'Tiefstwert';

  @override
  String get statPace => 'Tempo';

  @override
  String statPercent(Object value) {
    return '$value %';
  }

  @override
  String get unitPerMinute => '/Min.';

  @override
  String get unitSteps => 'Schritte';

  @override
  String get workoutCongrats => 'Gut gemacht! Training gespeichert';

  @override
  String workoutTimeRange(Object day, Object start, Object end) {
    return '$day · $start–$end';
  }
}
