// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get aboutDescription =>
      'Bileklik zeigt die Messwerte Ihres JCV8-EKG-Armbands auf dem Telefon an.';

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutMedical =>
      'Diese App ist kein Medizinprodukt; wenden Sie sich für Diagnose und Behandlung an Ihren Arzt. Blutdruckwerte sind Schätzwerte.';

  @override
  String get aboutPrivacy =>
      'Ihre Messwerte bleiben auf diesem Telefon. Wenn das Teilen hinzukommt, entscheiden Sie, wer was sieht.';

  @override
  String aboutVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get achFirstEcg => 'Erstes EKG';

  @override
  String get achFirstEcgText => 'Sie haben Ihr erstes EKG aufgezeichnet.';

  @override
  String get achFirstSync => 'Erster Schritt';

  @override
  String get achFirstSyncText => 'Die ersten Messwerte sind vom Armband angekommen.';

  @override
  String get achGoalStreak7 => 'Eine Woche am Stück';

  @override
  String get achGoalStreak7Text => '7 Tage hintereinander das Schrittziel.';

  @override
  String get achMarathonWeek => 'Marathonwoche';

  @override
  String get achMarathonWeekText => '42,2 km in einer Woche.';

  @override
  String get achSleepStreak7 => 'Regelmäßiger Schlaf';

  @override
  String get achSleepStreak7Text => '7 Nächte hintereinander mindestens 7 Stunden Schlaf.';

  @override
  String get achSteps10k => '10.000 Schritte';

  @override
  String get achSteps10kText => '10.000 Schritte an einem Tag.';

  @override
  String get achSteps20k => '20.000 Schritte';

  @override
  String get achSteps20kText => '20.000 Schritte an einem Tag.';

  @override
  String get achWear30 => 'Treuer Träger';

  @override
  String get achWear30Text => 'Sie haben das Armband an 30 verschiedenen Tagen getragen.';

  @override
  String get achWorkouts10 => '10 Trainings';

  @override
  String get achWorkouts10Text => 'Insgesamt 10 Trainings aufgezeichnet.';

  @override
  String achievementEarned(Object date) {
    return 'Erhalten am $date';
  }

  @override
  String get achievementProgress => 'Fortschritt';

  @override
  String get achievementsTitle => 'Abzeichen';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionClose => 'Schließen';

  @override
  String get allDayHeartRateFailed => 'Die Einstellung konnte nicht auf dem Armband gespeichert werden. Bitte erneut versuchen.';

  @override
  String get allDayHeartRateSubtitle => 'Wenn aus, zeichnet das Armband tagsüber keinen Puls auf.';

  @override
  String get allDayHeartRateTitle => 'Ganztägige Pulsmessung';

  @override
  String get appTitle => 'Bileklik';

  @override
  String get autoMeasureAllDay => 'Ganztägig';

  @override
  String get autoMeasureConnect => 'Verbinden';

  @override
  String get autoMeasureDays => 'Tage';

  @override
  String get autoMeasureEnd => 'Ende';

  @override
  String get autoMeasureEveryDay => 'Täglich';

  @override
  String autoMeasureEveryHours(int hours) {
    return 'Alle $hours Std.';
  }

  @override
  String autoMeasureEveryMinutes(int minutes) {
    return 'Alle $minutes Min.';
  }

  @override
  String get autoMeasureHours => 'Messzeiten';

  @override
  String get autoMeasureInterval => 'Intervall';

  @override
  String get autoMeasureIntro =>
      'Das Armband misst selbstständig zu den gewählten Zeiten. Jede Messung dauert 1 Minute; kürzere Abstände leeren den Akku schneller.';

  @override
  String get autoMeasureLoadFailed =>
      'Einstellungen des Armbands konnten nicht gelesen werden.';

  @override
  String autoMeasureNextDay(String time) {
    return '$time (Folgetag)';
  }

  @override
  String get autoMeasureNoDays => 'Mindestens ein Tag muss ausgewählt bleiben.';

  @override
  String get autoMeasureNotConnected =>
      'Verbinde das Armband, um seine Einstellungen zu sehen und zu ändern.';

  @override
  String get autoMeasureOff => 'Aus';

  @override
  String get autoMeasureRetry => 'Erneut versuchen';

  @override
  String get autoMeasureSameTime => 'Beginn und Ende dürfen nicht gleich sein.';

  @override
  String get autoMeasureSaveFailed =>
      'Einstellung konnte nicht gespeichert werden. Erneut versuchen.';

  @override
  String get autoMeasureSleepNote =>
      'Im Schlaf misst das Armband den Puls alle 5 Minuten.';

  @override
  String get autoMeasureStart => 'Beginn';

  @override
  String get autoMeasureTitle => 'Automatische Messung';

  @override
  String autoMeasureTurnOn(String name) {
    return 'Automatische Messung: $name';
  }

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
  String get bmiNormal => 'Normalgewicht';

  @override
  String get bmiObese => 'Adipositas';

  @override
  String get bmiOver => 'Übergewicht';

  @override
  String get bmiUnder => 'Untergewicht';

  @override
  String get bodyAdd => 'Eintrag hinzufügen';

  @override
  String get bodyBmiNeedsHeight =>
      'Geben Sie Ihre Größe ein, um Ihren BMI zu sehen.';

  @override
  String get bodyBmiNote =>
      'Der BMI ist ein grober Richtwert für Erwachsene; bei sehr muskulösen Menschen, in der Schwangerschaft und bei Kindern kann er täuschen.';

  @override
  String bodyChange(String change) {
    return '$change seit dem letzten Eintrag';
  }

  @override
  String get bodyChartEmpty => 'Keine Einträge in diesem Zeitraum.';

  @override
  String get bodyDate => 'Datum';

  @override
  String get bodyDelete => 'Löschen';

  @override
  String bodyDeleteBody(String date) {
    return 'Der Eintrag vom $date wird von diesem Telefon gelöscht.';
  }

  @override
  String get bodyDeleteTitle => 'Eintrag löschen?';

  @override
  String get bodyEmpty =>
      'Tragen Sie Ihr Gewicht ein, wenn Sie sich wiegen, und verfolgen Sie den Verlauf im Diagramm.';

  @override
  String get bodyHeight => 'Größe';

  @override
  String get bodyHistory => 'Verlauf';

  @override
  String get bodyMuscleTooHigh =>
      'Muskelmasse kann nicht größer als das Gewicht sein';

  @override
  String get bodyNoChange => 'Wie beim letzten Eintrag';

  @override
  String get bodyNote =>
      'Einträge werden nur auf diesem Telefon gespeichert. Ist das Armband verbunden, erhält es Ihr Gewicht auch für die Kalorienberechnung.';

  @override
  String bodyOptional(String name) {
    return '$name (optional)';
  }

  @override
  String get bodyRange3Months => '3 Monate';

  @override
  String bodyRangeError(String min, String max) {
    return 'Muss zwischen $min und $max liegen';
  }

  @override
  String get bodyRangeMonth => '1 Monat';

  @override
  String get bodyRangeYear => '1 Jahr';

  @override
  String get bodySave => 'Speichern';

  @override
  String get bodySheetTitle => 'Neuer Eintrag';

  @override
  String get bodyTitle => 'Gewicht und Körper';

  @override
  String get bodyToday => 'Heute';

  @override
  String get clock12 => '12 Stunden (AM/PM)';

  @override
  String get clock24 => '24 Stunden';

  @override
  String get clockSystem => 'Wie Sprache';

  @override
  String get clockTitle => 'Zeitformat';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get comingSoonMessage =>
      'Dieser Bereich folgt in einer späteren Version.';

  @override
  String get communityAccept => 'Beitreten';

  @override
  String get communityAnswered => 'Beantwortet';

  @override
  String get communityCodeCopied => 'Code kopiert';

  @override
  String get communityCodeInvalid => 'Keine Gruppe mit diesem Code gefunden.';

  @override
  String get communityCodeLabel => 'Gruppencode';

  @override
  String communityConsentSince(Object date) {
    return 'Freigegeben am: $date';
  }

  @override
  String get communityCopyCode => 'Code kopieren';

  @override
  String get communityCreate => 'Erstellen';

  @override
  String get communityCreateGroup => 'Neue Gruppe erstellen';

  @override
  String get communityDecline => 'Ablehnen';

  @override
  String get communityDelete => 'Gruppe löschen';

  @override
  String communityDeleteConfirm(Object group) {
    return '„$group“ wird gelöscht und alle Freigaben darin enden.';
  }

  @override
  String get communityGroupName => 'Gruppenname';

  @override
  String get communityGroupNameHint => 'z. B. Meine Familie';

  @override
  String get communityInvite => 'Mitglied einladen';

  @override
  String communityInviteCodeBody(Object name) {
    return 'Teilen Sie diesen Code mit $name. Beitritt über Gesundheitsgemeinschaft > Mit Code beitreten.';
  }

  @override
  String get communityInviteCodeTitle => 'Einladungscode';

  @override
  String get communityInviteName => 'Name der einzuladenden Person';

  @override
  String get communityInviteSend => 'Einladen';

  @override
  String get communityJoinWithCode => 'Mit Code beitreten';

  @override
  String get communityJoinedEmpty =>
      'Sie können per Einladung oder Gruppencode beitreten.';

  @override
  String get communityJoinedGroups => 'Beigetretene Gruppen';

  @override
  String communityJoinedMessage(Object group) {
    return 'Sie sind „$group“ beigetreten.';
  }

  @override
  String get communityLeave => 'Gruppe verlassen';

  @override
  String communityLeaveConfirm(Object group) {
    return 'Wenn Sie „$group“ verlassen, sehen die Mitglieder Ihre geteilten Daten nicht mehr.';
  }

  @override
  String communityMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get communityMembers => 'Mitglieder';

  @override
  String get communityMessages => 'Nachrichten';

  @override
  String get communityMessagesEmpty => 'Noch keine Nachrichten.';

  @override
  String communityMsgInvite(Object name, Object group) {
    return '$name hat Sie in die Gruppe „$group“ eingeladen.';
  }

  @override
  String communityMsgJoined(Object name, Object group) {
    return '$name ist „$group“ beigetreten.';
  }

  @override
  String get communityMyGroups => 'Meine Gruppen';

  @override
  String get communityMyGroupsEmpty =>
      'Sie haben noch keine Gruppe. Erstellen Sie eine und laden Sie Ihre Familie ein.';

  @override
  String get communityMyShareNote =>
      'Nur Mitglieder dieser Gruppe sehen es. Nichts wird geteilt, bevor Sie es einschalten.';

  @override
  String get communityMyShareTitle => 'Was Sie mit dieser Gruppe teilen';

  @override
  String get communityOwner => 'Inhaber';

  @override
  String communityOwnerName(Object name) {
    return 'Inhaber: $name';
  }

  @override
  String get communityPending => 'Einladung ausstehend';

  @override
  String get communityPrivacyNote =>
      'Ihre Gesundheitsdaten werden nur mit den Gruppen geteilt, die Sie wählen, und nur in den Arten, die Sie festlegen. Sie können die Freigabe jederzeit widerrufen.';

  @override
  String get communityRemoveMember => 'Aus Gruppe entfernen';

  @override
  String communityShares(Object types) {
    return 'Teilt: $types';
  }

  @override
  String get communitySharesNothing => 'Teilt noch nichts';

  @override
  String get communityYou => 'Sie';

  @override
  String get connActive => 'Meine Verbindungen';

  @override
  String connAgree(Object name) {
    return 'Ich habe diese Informationen gelesen und willige ausdrücklich ein, die ausgewählten Daten für den genannten Zweck mit $name zu teilen.';
  }

  @override
  String get connCodeInvalid => 'Dieser Code ist ungültig oder abgelaufen.';

  @override
  String get connConfirm => 'Zustimmen und verbinden';

  @override
  String connConnected(Object name) {
    return 'Mit $name verbunden.';
  }

  @override
  String get connConsentTitle => 'Ausdrückliche Einwilligung';

  @override
  String get connDisconnect => 'Verbindung entfernen';

  @override
  String connDisconnectConfirm(Object name) {
    return '$name sieht Ihre neuen Daten nicht mehr. Die Löschung bereits geteilter Daten können Sie dort verlangen.';
  }

  @override
  String get connDuration => 'Dauer';

  @override
  String connDurationText(Object date, Object days) {
    return 'Bis $date ($days Tage). Danach endet die Freigabe automatisch; Sie können sie auch früher beenden.';
  }

  @override
  String get connEmpty => 'Noch keine Verbindungen.';

  @override
  String get connEnterCode => 'Einladungscode eingeben';

  @override
  String get connIntro =>
      'Ihr Arzt oder eine Studie, an der Sie teilnehmen, gibt Ihnen einen Einladungscode. Nach der Eingabe sehen Sie, wer welche Daten wie lange möchte, und entscheiden selbst.';

  @override
  String get connKindClinician => 'Arzt';

  @override
  String get connKindResearch => 'Forschungseinrichtung';

  @override
  String get connPurpose => 'Zweck';

  @override
  String get connQrInvalid => 'Dieser QR-Code enthält keinen Einladungscode.';

  @override
  String get connRequested => 'Angeforderte Daten';

  @override
  String get connRequestedNote =>
      'Wählen Sie, was Sie teilen möchten. Nicht Ausgewähltes bleibt privat.';

  @override
  String get connRights =>
      'Ihre Daten werden nach dem Datenschutzgesetz (KVKK) verarbeitet. Sie haben das Recht auf Auskunft, Berichtigung und Löschung.';

  @override
  String get connScan => 'QR-Code scannen';

  @override
  String get connScanHint => 'Halten Sie den QR-Code Ihrer Ärztin, Ihres Arztes oder der Forschungseinrichtung in den Rahmen.';

  @override
  String get connSelectAll => 'Alle auswählen';

  @override
  String get connShared => 'Geteilte Daten';

  @override
  String connSharedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Datentypen',
      one: '1 Datentyp',
    );
    return '$_temp0';
  }

  @override
  String connSince(Object date) {
    return 'Seit $date';
  }

  @override
  String connUntil(Object date) {
    return 'Bis $date';
  }

  @override
  String get continueButton => 'Weiter';

  @override
  String get deviceAddress => 'Adresse';

  @override
  String get deviceBattery => 'Akku';

  @override
  String deviceBatteryValue(Object value) {
    return '$value %';
  }

  @override
  String get deviceConnected => 'Verbunden';

  @override
  String get deviceDisconnect => 'Trennen';

  @override
  String get deviceDisconnected => 'Nicht verbunden';

  @override
  String get deviceFirmware => 'Firmware';

  @override
  String get deviceLastSync => 'Letzte Synchronisierung';

  @override
  String get devicePairNew => 'Anderes Armband koppeln';

  @override
  String get deviceSectionSettings => 'Armband-Einstellungen';

  @override
  String get deviceStatus => 'Status';

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
  String energyDayTitle(Object date) {
    return 'Energie am $date';
  }

  @override
  String get energyDrain => 'Tagesverbrauch';

  @override
  String get energyEmpty => 'Für die Energie wird der Schlaf der letzten Nacht oder eine HRV-Messung benötigt.';

  @override
  String get energyHigh => 'Ihre Energie ist hoch';

  @override
  String get energyLow => 'Ihre Energie ist niedrig; gönnen Sie sich Ruhe';

  @override
  String get energyMedium => 'Ihre Energie ist mittel';

  @override
  String get energyNote => 'Schlafdauer und -tiefe sowie die HRV im Vergleich zu den letzten zwei Wochen füllen Ihre Energie auf; Schritte und Stress verbrauchen sie im Lauf des Tages. Dies ist eine Schätzung der App, keine medizinische Messung.';

  @override
  String get energyRecovery => 'Erholung';

  @override
  String energySemantics(Object score, Object level) {
    return 'Energie $score/100, $level';
  }

  @override
  String get energySleep => 'Schlaf';

  @override
  String get energyTitle => 'Energie';

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
  String get exportEmpty => 'In diesem Zeitraum gibt es keine Einträge zum Exportieren.';

  @override
  String get exportFailed => 'Die Datei konnte nicht erstellt werden. Bitte versuchen Sie es erneut.';

  @override
  String get exportIncludeEcg => 'EKG-Aufzeichnungen einschließen';

  @override
  String get exportIncludeEcgNote => 'Rohe EKG-Daten machen die Datei größer.';

  @override
  String get exportIntro => 'Ihre Messwerte werden als FHIR-R4-Datei erstellt, dem gemeinsamen Format von Gesundheitssystemen. Sie können sie Ihrer Ärztin oder Ihrem Arzt senden oder in einer App öffnen, die dieses Format liest.';

  @override
  String get exportPeriod => 'Zeitraum';

  @override
  String get exportPrivacy => 'Die Datei enthält Gesundheitsdaten. Teilen Sie sie nur mit Personen und Einrichtungen, denen Sie vertrauen. Sie enthält nicht Ihren Namen, sondern nur eine pseudonyme Kennung dieses Telefons.';

  @override
  String exportRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get exportShare => 'Datei teilen';

  @override
  String get exportTitle => 'Meine Daten exportieren';

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
  String healthWeightBmi(String bmi, String when) {
    return 'BMI $bmi · $when';
  }

  @override
  String get healthWeightPrompt => 'Gewicht eintragen';

  @override
  String homeActiveGoal(Object minutes) {
    return 'Ziel $minutes Min.';
  }

  @override
  String get homeActiveTime => 'Aktive Zeit';

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
  String get homeCalories => 'Kalorien';

  @override
  String homeChartNoData(Object title) {
    return '$title: keine Messwerte';
  }

  @override
  String homeChartSemantics(Object title, Object min, Object max, Object unit) {
    return '$title: niedrigster Wert $min, höchster Wert $max $unit';
  }

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
  String get homeHeroEmpty =>
      'Verbinden Sie das Armband, um Ihren Puls zu sehen.';

  @override
  String homeHeroSemantics(Object value) {
    return 'Puls $value bpm';
  }

  @override
  String get homeHourlyStressSemantics => 'Stress pro Stunde (Balken)';

  @override
  String get homeHrvLabel => 'Herzfrequenzvariabilität';

  @override
  String get homeKcal => 'kcal';

  @override
  String homeKm(Object value) {
    return '$value km';
  }

  @override
  String homeLastMeasured(Object time) {
    return 'Letzte Messung $time';
  }

  @override
  String get homeListSeparator => ', ';

  @override
  String get homeLive => 'Live';

  @override
  String get homeMeasureNow => 'Jetzt messen';

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
  String get homeNotConnected => 'Nicht verbunden';

  @override
  String homePercent(Object value) {
    return '$value %';
  }

  @override
  String get homePickDay => 'Tag auswählen';

  @override
  String get homePrevDay => 'Vorheriger Tag';

  @override
  String get homeQuickActions => 'Schnellaktionen';

  @override
  String get homeQuickHeartRate => 'Puls messen';

  @override
  String get homeQuickSync => 'Synchronisieren';

  @override
  String homeRange(Object min, Object max) {
    return '$min–$max';
  }

  @override
  String get homeRecovery => 'Erholung';

  @override
  String homeRestingHr(Object value) {
    return 'Ruhepuls $value bpm';
  }

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
  String get homeSyncing => 'Wird synchronisiert…';

  @override
  String get homeTimeline => 'Zeitachse';

  @override
  String get homeTimelineEmpty =>
      'Ihre Trainings, EKGs und Schlafdaten erscheinen hier in zeitlicher Reihenfolge.';

  @override
  String get homeTimelineSubtitle => 'Einträge des Tages';

  @override
  String get homeToday => 'Heute';

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
  String get homeYesterday => 'Gestern';

  @override
  String get hpActivity => 'Schritte, Strecke und Kalorien';

  @override
  String get hpAuto =>
      'Neue Daten werden nach jeder Armband-Synchronisierung automatisch gesendet.';

  @override
  String get hpBody => 'Gewicht, Körperfett und BMI';

  @override
  String get hpChooseTypes => 'Zu sendende Daten';

  @override
  String hpConnect(Object platform) {
    return 'Mit $platform verbinden';
  }

  @override
  String get hpConnected => 'Verbunden';

  @override
  String hpDenied(Object platform) {
    return 'Keine Berechtigung erteilt. Sie können sie in den Einstellungen von $platform erlauben.';
  }

  @override
  String get hpDisconnect => 'Senden beenden';

  @override
  String hpDisconnectNote(Object platform) {
    return 'Bereits geschriebene Daten bleiben in $platform; löschen Sie sie in den Einstellungen von $platform.';
  }

  @override
  String get hpExportNow => 'Jetzt senden';

  @override
  String hpExported(Object records) {
    return '$records gesendet';
  }

  @override
  String get hpHrv => 'Herzfrequenzvariabilität (HRV)';

  @override
  String hpIntro(Object platform) {
    return 'Ihre Armbanddaten werden in $platform geschrieben, wo andere Gesundheits-Apps auf Ihrem Telefon sie sehen können. Sie wählen, welche Arten gesendet werden.';
  }

  @override
  String hpLastExport(Object time, Object records) {
    return 'Zuletzt gesendet: $time · $records';
  }

  @override
  String get hpNever => 'Noch nicht gesendet';

  @override
  String get hpNotExported =>
      'Der Blutdruck ist geschätzt und wird daher nicht gesendet. Gesundheitsplattformen nehmen keine EKG-Aufzeichnungen anderer Apps an.';

  @override
  String get hpNothingNew => 'Keine neuen Einträge zum Senden';

  @override
  String hpPermissionNote(Object platform) {
    return 'Beim Fortfahren öffnet $platform das Berechtigungsfenster; dort können Sie ebenfalls einzeln wählen.';
  }

  @override
  String hpRecords(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String get hpTitle => 'Gesundheits-App';

  @override
  String hpUnavailable(Object platform) {
    return '$platform ist auf diesem Telefon nicht verfügbar. Sie können es über Google Play installieren.';
  }

  @override
  String get hpWorkouts => 'Trainings';

  @override
  String get hrvBeats => 'Schläge';

  @override
  String get hrvDetailEmpty => 'In der letzten Woche gibt es keine nächtlichen Schlagintervall-Messungen. Tragen Sie das Armband im Schlaf.';

  @override
  String hrvDetailNight(Object date) {
    return 'Nacht bis zum Morgen des $date';
  }

  @override
  String get hrvDetailNote => 'Berechnet aus nachts gemessenen Schlagintervallen. RMSSD zeigt die kurzfristige, SDNN die gesamte Variabilität; vergleichen Sie mit Ihrem eigenen Verlauf.';

  @override
  String get hrvDetailTitle => 'Nächtliche HRV im Detail';

  @override
  String get hrvMeanHeartRate => 'Mittlerer Puls';

  @override
  String get hrvPnn50 => 'pNN50';

  @override
  String get hrvRmssd => 'RMSSD';

  @override
  String get hrvSdnn => 'SDNN';

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
  String get issueNoSpotSignal =>
      'Keine Messung möglich. Ziehen Sie das Armband etwas enger und versuchen Sie es erneut.';

  @override
  String get issueNotPaired => 'Koppeln Sie zuerst Ihr Armband unter Profil > Gerät.';

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
  String get measureEcg => 'EKG';

  @override
  String get measureEcgHint => 'Mit dem Finger auf der Elektrode';

  @override
  String get measureHeartRate => 'Herzfrequenz';

  @override
  String get measureSheetTitle => 'Was möchten Sie messen?';

  @override
  String get measureSpo2 => 'Blutsauerstoff (SpO2)';

  @override
  String measureTakes(Object seconds) {
    return 'Dauert etwa $seconds Sekunden';
  }

  @override
  String get metricBmi => 'BMI';

  @override
  String get metricBodyFat => 'Körperfett';

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
  String get metricMuscleMass => 'Muskelmasse';

  @override
  String get metricPpi => 'Schlagintervall';

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
  String get metricWeight => 'Gewicht';

  @override
  String get navExercise => 'Training';

  @override
  String get navHealth => 'Gesundheit';

  @override
  String get navHome => 'Start';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSemantics => 'Hauptmenü';

  @override
  String get noValue => '--';

  @override
  String get pairBluetoothDenied => 'Für die Suche nach dem Armband ist die Bluetooth-Berechtigung nötig. Erlauben Sie sie dieser App in den Telefoneinstellungen und versuchen Sie es erneut.';

  @override
  String get pairBluetoothOff => 'Bluetooth ist ausgeschaltet. Schalten Sie Bluetooth am Telefon ein und versuchen Sie es erneut.';

  @override
  String get pairBluetoothUnsupported => 'Dieses Gerät unterstützt Bluetooth Low Energy nicht, das das Armband verwendet.';

  @override
  String get pairCode => 'Mit Adresse koppeln';

  @override
  String get pairCodeHint =>
      'Geben Sie die Adresse unter dem QR-Code auf der Verpackung oder der Rückseite des Armbands ein.';

  @override
  String get pairCodeInvalid =>
      'Die Adresse hat 12 Zeichen, z. B. A1:B2:C3:D4:E5:F6';

  @override
  String get pairCodeLabel => 'Geräteadresse';

  @override
  String get pairCodeNotFound =>
      'Unter dieser Adresse wurde kein Armband gefunden.';

  @override
  String get pairConnect => 'Verbinden';

  @override
  String get pairConnected => 'Armband verbunden.';

  @override
  String get pairFound => 'Gefundene Armbänder';

  @override
  String get pairNoneFound =>
      'Kein Armband gefunden. Prüfen Sie, ob es geladen und in der Nähe ist, und versuchen Sie es erneut.';

  @override
  String get pairNote =>
      'Laden Sie das Armband und halten Sie es in der Nähe des Telefons. Bluetooth muss eingeschaltet sein.';

  @override
  String get pairQr => 'QR-Code scannen';

  @override
  String get pairQrHint => 'Halten Sie den QR-Code auf der Verpackung oder der Rückseite des Armbands in den Rahmen.';

  @override
  String get pairQrInvalid => 'Dieser QR-Code enthält keine Armbandadresse.';

  @override
  String get pairScan => 'Suche starten';

  @override
  String get pairScanning => 'Suche läuft…';

  @override
  String pairSignal(Object rssi) {
    return 'Signal $rssi';
  }

  @override
  String get pairSubtitle =>
      'Verbinden Sie Ihr Armband, damit Ihre Messwerte auf das Telefon kommen.';

  @override
  String get pairTitle => 'Armband koppeln';

  @override
  String get periodDay => 'Tag';

  @override
  String get periodMonth => 'Monat';

  @override
  String get periodWeek => 'Woche';

  @override
  String get personalInfoTitle => 'Persönliche Daten';

  @override
  String get profileAge => 'Alter';

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
  String get profileMenuAbout => 'Über die App';

  @override
  String get profileMenuCommunity => 'Gesundheitsgemeinschaft';

  @override
  String get profileMenuCommunitySubtitle => 'Familiengruppen und Freigaben';

  @override
  String get profileMenuDevice => 'Gerät';

  @override
  String profileMenuDeviceConnected(Object battery) {
    return 'Verbunden · Akku $battery %';
  }

  @override
  String get profileMenuDeviceNone => 'Kein Armband verbunden';

  @override
  String get profileMenuExport => 'Meine Daten exportieren';

  @override
  String get profileMenuExportSubtitle => 'FHIR-Datei für Ihre Ärztin, Ihren Arzt oder eine andere App';

  @override
  String get profileMenuFeedback => 'Feedback';

  @override
  String get profileMenuGeneral => 'Allgemeine Einstellungen';

  @override
  String get profileMenuGeneralSubtitle => 'Sprache, Zeitformat, Einheiten';

  @override
  String get profileMenuPersonalEmpty => 'Alter, Größe und Gewicht eingeben';

  @override
  String profileMenuPersonalSummary(Object age, Object height, Object weight) {
    return '$age J. · $height cm · $weight kg';
  }

  @override
  String get profileMenuResearch => 'Ärzte und Forschung';

  @override
  String get profileMenuResearchSubtitle => 'Daten per Einladungscode teilen';

  @override
  String get profileMenuThirdParty => 'Health Connect und Apple Health';

  @override
  String get profileMenuThirdPartySubtitle =>
      'Daten an die Gesundheits-App des Telefons senden';

  @override
  String get profileMenuVersion => 'App-Version';

  @override
  String profileRangeError(Object min, Object max) {
    return 'Muss zwischen $min und $max liegen';
  }

  @override
  String get profileSave => 'Speichern';

  @override
  String get profileSaved => 'Angaben auf dem Armband gespeichert';

  @override
  String get profileSectionApp => 'App';

  @override
  String get profileSectionSettings => 'Einstellungen';

  @override
  String get profileSectionSharing => 'Teilen und Verbindungen';

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
  String get progressTitle => 'Fortschritt';

  @override
  String get qrCameraDenied => 'Der Kamerazugriff wurde nicht erlaubt. Erlauben Sie ihn in den Telefoneinstellungen oder geben Sie den Code manuell ein.';

  @override
  String get qrCameraUnavailable => 'Die Kamera konnte nicht geöffnet werden. Sie können den Code manuell eingeben.';

  @override
  String get qrManual => 'Code manuell eingeben';

  @override
  String get reminderAddMedication => 'Medikamentenzeit hinzufügen';

  @override
  String get reminderAddWater => 'Trinkzeit hinzufügen';

  @override
  String get reminderAlarm => 'Wecker';

  @override
  String reminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erinnerungen',
      one: '1 Erinnerung',
      zero: 'Keine Erinnerungen',
    );
    return '$_temp0';
  }

  @override
  String get reminderDelete => 'Löschen';

  @override
  String get reminderDuplicate =>
      'Zu dieser Uhrzeit gibt es bereits eine Erinnerung dieser Art.';

  @override
  String get reminderEdit => 'Erinnerung bearbeiten';

  @override
  String get reminderEmptyMedication =>
      'Fügen Sie Ihre Medikamentenzeiten hinzu; das Armband vibriert zu jeder Zeit.';

  @override
  String get reminderEmptyWater =>
      'Fügen Sie Zeiten hinzu, um tagsüber ans Trinken erinnert zu werden.';

  @override
  String get reminderLabel => 'Name des Medikaments (optional)';

  @override
  String get reminderLabelHint => 'z. B. Morgentablette';

  @override
  String get reminderLabelNote => 'Wird auf dem Armband nur mit lateinischen Buchstaben gespeichert (ä → a).';

  @override
  String get reminderMedication => 'Medikament';

  @override
  String get reminderNewMedication => 'Neue Medikamentenerinnerung';

  @override
  String get reminderNewWater => 'Neue Trinkerinnerung';

  @override
  String get reminderSave => 'Speichern';

  @override
  String get reminderTime => 'Uhrzeit';

  @override
  String get reminderWater => 'Wasser';

  @override
  String get reminderWeekdays => 'Werktags';

  @override
  String get reminderWeekend => 'Am Wochenende';

  @override
  String remindersFull(int max) {
    return 'Das Armband speichert höchstens $max Erinnerungen.';
  }

  @override
  String get remindersIntro =>
      'Zur Erinnerungszeit vibriert das Armband; auf dem Handy erscheint keine Mitteilung.';

  @override
  String get remindersLoadFailed =>
      'Erinnerungen konnten nicht vom Armband gelesen werden.';

  @override
  String get remindersNotConnected =>
      'Verbinden Sie das Armband, um Erinnerungen zu sehen und zu ändern.';

  @override
  String get remindersSaveFailed =>
      'Die Erinnerung konnte nicht auf dem Armband gespeichert werden. Versuchen Sie es erneut.';

  @override
  String get remindersTitle => 'Erinnerungen';

  @override
  String get reportAverageSteps => 'Schritte pro Tag (Ø)';

  @override
  String get reportDown => 'Gesunken';

  @override
  String get reportEmpty => 'Keine Daten für diese Woche.';

  @override
  String get reportGoalDays => 'Tage mit Schrittziel';

  @override
  String get reportHrv => 'HRV (Ø)';

  @override
  String get reportSleep => 'Schlaf (Ø)';

  @override
  String get reportSteps => 'Schritte gesamt';

  @override
  String get reportStress => 'Stress (Ø)';

  @override
  String get reportUp => 'Gestiegen';

  @override
  String get reportVsPrevious => 'Pfeile zeigen die Veränderung zur Vorwoche.';

  @override
  String get reportWorkouts => 'Trainings';

  @override
  String reportWorkoutsValue(Object count, Object time) {
    return '$count× · $time';
  }

  @override
  String get shareActivity => 'Aktivität und Schritte';

  @override
  String get shareBloodPressure => 'Blutdruck (geschätzt)';

  @override
  String get shareEcg => 'EKG-Aufzeichnungen';

  @override
  String get shareHeartRate => 'Herzfrequenz';

  @override
  String get shareSleep => 'Schlaf';

  @override
  String get shareSpo2 => 'Blutsauerstoff (SpO2)';

  @override
  String get shareStress => 'Stress und HRV';

  @override
  String get shareTemperature => 'Körpertemperatur';

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
  String get spotAgain => 'Erneut messen';

  @override
  String get spotDone => 'Fertig';

  @override
  String get spotKeepStill =>
      'Tragen Sie das Armband eng, legen Sie den Arm ab und halten Sie still.';

  @override
  String get spotLowSpo2 =>
      'Der Wert ist niedrig. Ruhen Sie sich aus und messen Sie erneut; bleibt er niedrig, sprechen Sie mit Ihrer Ärztin oder Ihrem Arzt.';

  @override
  String get spotMeasuring => 'Wird gemessen…';

  @override
  String get spotMoving => 'Bewegung erkannt. Halte den Arm still.';

  @override
  String get spotNote => 'Armbandmessungen ersetzen kein Medizinprodukt.';

  @override
  String get spotOffWrist =>
      'Das Armband scheint nicht am Handgelenk zu sein. Lege es eng an.';

  @override
  String spotSaved(Object time) {
    return 'Gespeichert, gemessen um $time';
  }

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
  String get unitsImperial => 'US (mi, °F)';

  @override
  String get unitsMetric => 'Metrisch (km, °C)';

  @override
  String get unitsTitle => 'Einheiten';

  @override
  String vo2MaxBasis(Object age, Object resting) {
    return 'Basierend auf Alter $age und Ruhepuls $resting';
  }

  @override
  String get vo2MaxNeedsAge => 'Für die Schätzung wird Ihr Alter benötigt. Verbinden Sie das Armband und tragen Sie es unter Profil > Persönliche Daten ein.';

  @override
  String get vo2MaxNeedsData => 'Für den Ruhepuls werden Puls- oder Nachtmessungen von einigen Tagen benötigt.';

  @override
  String get vo2MaxNote => 'Geschätzt aus dem Verhältnis von altersbasiertem Maximalpuls zu Ruhepuls; keine Labormessung. Nutzen Sie den Wert, um Ihren Fitnessverlauf zu verfolgen.';

  @override
  String get vo2MaxTitle => 'Geschätzte VO2max';

  @override
  String vo2MaxValue(Object value) {
    return '$value ml/kg/min';
  }

  @override
  String get wearDetectionFailed =>
      'Trageerkennung konnte nicht geändert werden.';

  @override
  String get wearDetectionSubtitle =>
      'Warnt während einer Messung, wenn das Armband nicht getragen wird oder sich der Arm bewegt.';

  @override
  String get wearDetectionTitle => 'Trageerkennung';

  @override
  String get weeklyReportTitle => 'Wochenbericht';

  @override
  String get workoutCongrats => 'Gut gemacht! Training gespeichert';

  @override
  String workoutTimeRange(Object day, Object start, Object end) {
    return '$day · $start–$end';
  }
}
