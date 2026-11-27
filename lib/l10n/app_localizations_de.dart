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
  String get accountCodeCopied => 'Wiederherstellungscode kopiert';

  @override
  String get accountCopy => 'Kopieren';

  @override
  String get accountEraseButton => 'Löschen';

  @override
  String get accountEraseConfirmTitle => 'Portaldaten löschen?';

  @override
  String get accountEraseInfo =>
      'Alle ins Portal hochgeladenen Messwerte werden gelöscht und alle Freigaben enden. Die Daten auf dem Telefon bleiben. Zugriffsprotokolle werden wegen gesetzlicher Pflichten aufbewahrt.';

  @override
  String get accountEraseTitle => 'Meine Portaldaten löschen';

  @override
  String accountErased(int count) {
    return '$count Messwerte im Portal gelöscht.';
  }

  @override
  String get accountMenuSubtitle =>
      'Wiederherstellungscode, Konto wiederherstellen';

  @override
  String get accountRecoveryInfo =>
      'Wenn Sie das Telefon wechseln oder die App löschen, stellen Sie mit diesem Code Ihre Verbindungen zu Ärzten und Einrichtungen wieder her. Notieren Sie ihn sicher und geben Sie ihn nicht weiter.';

  @override
  String get accountRecoveryTitle => 'Wiederherstellungscode';

  @override
  String get accountRenew => 'Neuen Code erstellen';

  @override
  String get accountRenewConfirmBody =>
      'Der alte Code funktioniert dann nicht mehr.';

  @override
  String get accountRenewConfirmTitle => 'Neuen Code erstellen?';

  @override
  String get accountRestoreButton => 'Wiederherstellen';

  @override
  String get accountRestoreConfirm => 'Konto wiederherstellen?';

  @override
  String get accountRestoreField => 'Wiederherstellungscode';

  @override
  String get accountRestoreInfo =>
      'Geben Sie den Wiederherstellungscode Ihres alten Telefons ein. Ihr altes Konto ersetzt das Portal-Konto auf diesem Telefon.';

  @override
  String get accountRestoreInvalid =>
      'Der Code ist ungültig oder wurde bereits verwendet.';

  @override
  String get accountRestoreTitle => 'Mein Konto wiederherstellen';

  @override
  String get accountRestored => 'Ihr Konto wurde wiederhergestellt.';

  @override
  String get accountTitle => 'Portal-Konto';

  @override
  String get achFirstEcg => 'Erstes EKG';

  @override
  String get achFirstEcgText => 'Sie haben Ihr erstes EKG aufgezeichnet.';

  @override
  String get achFirstSync => 'Erster Schritt';

  @override
  String get achFirstSyncText =>
      'Die ersten Messwerte sind vom Armband angekommen.';

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
  String get achSleepStreak7Text =>
      '7 Nächte hintereinander mindestens 7 Stunden Schlaf.';

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
  String get achWear30Text =>
      'Sie haben das Armband an 30 verschiedenen Tagen getragen.';

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
  String get allDayHeartRateFailed =>
      'Die Einstellung konnte nicht auf dem Armband gespeichert werden. Bitte erneut versuchen.';

  @override
  String get allDayHeartRateSubtitle =>
      'Wenn aus, zeichnet das Armband tagsüber keinen Puls auf.';

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
  String get communityAccept => 'Beitreten';

  @override
  String get communityAlertsBody =>
      'Wenn der geteilte Puls, die SpO2, der Blutdruck oder die Körpertemperatur länger deutlich sinkt oder steigt, sehen die Gruppenmitglieder einen Hinweis in der App. Ein Hinweis ist keine Diagnose.';

  @override
  String get communityAlertsNeedScope =>
      'Teilen Sie zuerst Puls, SpO2, Blutdruck oder Körpertemperatur.';

  @override
  String get communityAlertsTitle => 'Gruppe im Notfall benachrichtigen';

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
  String get communityUnnamedMember => 'Ein Mitglied';

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
  String get connScanHint =>
      'Halten Sie den QR-Code Ihrer Ärztin, Ihres Arztes oder der Forschungseinrichtung in den Rahmen.';

  @override
  String get connSelectAll => 'Alle auswählen';

  @override
  String get connServerError =>
      'Der Server ist nicht erreichbar. Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

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
  String get energyEmpty =>
      'Für die Energie wird der Schlaf der letzten Nacht oder eine HRV-Messung benötigt.';

  @override
  String get energyHigh => 'Ihre Energie ist hoch';

  @override
  String get energyLow => 'Ihre Energie ist niedrig; gönnen Sie sich Ruhe';

  @override
  String get energyMedium => 'Ihre Energie ist mittel';

  @override
  String get energyNote =>
      'Schlafdauer und -tiefe sowie die HRV im Vergleich zu den letzten zwei Wochen füllen Ihre Energie auf; Schritte und Stress verbrauchen sie im Lauf des Tages. Dies ist eine Schätzung der App, keine medizinische Messung.';

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
  String get exportEmpty =>
      'In diesem Zeitraum gibt es keine Einträge zum Exportieren.';

  @override
  String get exportFailed =>
      'Die Datei konnte nicht erstellt werden. Bitte versuchen Sie es erneut.';

  @override
  String get exportIncludeEcg => 'EKG-Aufzeichnungen einschließen';

  @override
  String get exportIncludeEcgNote => 'Rohe EKG-Daten machen die Datei größer.';

  @override
  String get exportIntro =>
      'Ihre Messwerte werden als FHIR-R4-Datei erstellt, dem gemeinsamen Format von Gesundheitssystemen. Sie können sie Ihrer Ärztin oder Ihrem Arzt senden oder in einer App öffnen, die dieses Format liest.';

  @override
  String get exportPeriod => 'Zeitraum';

  @override
  String get exportPrivacy =>
      'Die Datei enthält Gesundheitsdaten. Teilen Sie sie nur mit Personen und Einrichtungen, denen Sie vertrauen. Sie enthält nicht Ihren Namen, sondern nur eine pseudonyme Kennung dieses Telefons.';

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
  String familyAlertBloodPressure(
    String name,
    String systolic,
    String diastolic,
  ) {
    return '$name: sehr hoher Blutdruck ($systolic/$diastolic, geschätzt)';
  }

  @override
  String familyAlertFever(String name, String value) {
    return '$name: Fieber ($value)';
  }

  @override
  String familyAlertHeartRateHigh(String name, String value) {
    return '$name: hoher Puls (höchster Wert $value bpm)';
  }

  @override
  String familyAlertHeartRateLow(String name, String value) {
    return '$name: niedriger Puls (niedrigster Wert $value bpm)';
  }

  @override
  String get familyAlertNote =>
      'Dies ist ein automatischer Hinweis, keine Diagnose. Wenn Sie die Person nicht erreichen und es dringend ist, rufen Sie die 112 an.';

  @override
  String familyAlertSpo2Low(String name, String value) {
    return '$name: niedrige SpO2 (niedrigster Wert $value %)';
  }

  @override
  String familyAlertTime(String start, String end) {
    return '$start – $end';
  }

  @override
  String get familyAlertTitle => 'Familienhinweis';

  @override
  String feedbackDetailsValue(String version, String platform) {
    return 'Version $version · $platform';
  }

  @override
  String get feedbackIncludeDetails => 'Version und Geräteinfo anhängen';

  @override
  String get feedbackIntro =>
      'Einen Fehler gefunden oder eine Idee? Schreiben Sie uns, wir geben es an das Team weiter.';

  @override
  String get feedbackMessageHint =>
      'Was ist passiert und was haben Sie erwartet?';

  @override
  String get feedbackMessageLabel => 'Ihre Nachricht';

  @override
  String get feedbackPrivacy =>
      'Name, Kennung und Gesundheitsdaten werden nicht gesendet. Bitte keine persönlichen Angaben eintragen.';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackThanks => 'Danke, Ihr Feedback ist angekommen.';

  @override
  String get feedbackTopicBug => 'Fehler';

  @override
  String get feedbackTopicIdea => 'Idee';

  @override
  String get feedbackTopicOther => 'Sonstiges';

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
  String get hrvDetailEmpty =>
      'In der letzten Woche gibt es keine nächtlichen Schlagintervall-Messungen. Tragen Sie das Armband im Schlaf.';

  @override
  String hrvDetailNight(Object date) {
    return 'Nacht bis zum Morgen des $date';
  }

  @override
  String get hrvDetailNote =>
      'Berechnet aus nachts gemessenen Schlagintervallen. RMSSD zeigt die kurzfristige, SDNN die gesamte Variabilität; vergleichen Sie mit Ihrem eigenen Verlauf.';

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
  String get issueNotPaired =>
      'Koppeln Sie zuerst Ihr Armband unter Profil > Gerät.';

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
  String get pairBluetoothDenied =>
      'Für die Suche nach dem Armband ist die Bluetooth-Berechtigung nötig. Erlauben Sie sie dieser App in den Telefoneinstellungen und versuchen Sie es erneut.';

  @override
  String get pairBluetoothOff =>
      'Bluetooth ist ausgeschaltet. Schalten Sie Bluetooth am Telefon ein und versuchen Sie es erneut.';

  @override
  String get pairBluetoothUnsupported =>
      'Dieses Gerät unterstützt Bluetooth Low Energy nicht, das das Armband verwendet.';

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
  String get pairQrHint =>
      'Halten Sie den QR-Code auf der Verpackung oder der Rückseite des Armbands in den Rahmen.';

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
  String get privacyAuditBody =>
      'Jeder Zugriff auf Ihre Daten im Portal wird protokolliert, auch abgelehnte Versuche. In der App sehen Sie, wer wann zugegriffen hat.';

  @override
  String get privacyAuditTitle => 'Zugriffsprotokoll';

  @override
  String get privacyContactBody =>
      'Name und Anschrift des Verantwortlichen und der Weg für Anfragen werden vor der Veröffentlichung hier ergänzt. Sie können uns auch in der App unter Profil > Feedback schreiben.';

  @override
  String get privacyContactTitle => 'Kontakt';

  @override
  String get privacyDataBody =>
      'Was das Armband misst: Herzfrequenz, Herzfrequenzvariabilität (HRV), Blutsauerstoff (SpO2), EKG, Schlaf, Schritte, Training, Körpertemperatur, Stress und geschätzter Blutdruck. Was Sie eingeben: Alter, Größe, Gewicht, Geschlecht, Körperzusammensetzung und Erinnerungen. Die Bluetooth-Adresse des Armbands. Name, Ausweisnummer, Telefon oder E-Mail werden nicht abgefragt; im Portal sind Sie nur unter einem zufälligen Pseudonym bekannt. Wenn Sie das Partnerformular auf unserer Website ausfüllen, werden Name, Organisation, E-Mail und Nachricht nur für unsere Antwort verschlüsselt gespeichert und nie mit Gesundheitsdaten verknüpft. Das Vorregistrierungsformular nimmt nur Ihre E-Mail-Adresse auf; sie wird für eine einzige Mitteilung verwendet, sobald die App in den Stores ist.';

  @override
  String get privacyDataTitle => 'Welche Daten verarbeiten wir?';

  @override
  String get privacyDraft =>
      'Entwurf: Dieser Text wurde noch nicht juristisch geprüft. Name und Anschrift des Verantwortlichen sowie Speicherfristen werden vor der Veröffentlichung ergänzt.';

  @override
  String get privacyIntro =>
      'Dieser Text erklärt, wie die Bileklik-App und das Portal Ihre personenbezogenen Daten nach dem türkischen Datenschutzgesetz Nr. 6698 (KVKK) verarbeiten.';

  @override
  String get privacyLegalBody =>
      'Gesundheitsdaten sind besondere personenbezogene Daten und werden mit Ihrer ausdrücklichen Einwilligung verarbeitet (KVKK Art. 6). Jede Freigabe braucht eine eigene Einwilligung: Sie wählen, wer welche Datentypen wie lange sieht, und können die Einwilligung jederzeit widerrufen.';

  @override
  String get privacyLegalTitle => 'Rechtsgrundlage';

  @override
  String get privacyPurposeBody =>
      'Um Ihnen Ihre Messwerte anzuzeigen, sie mit den von Ihnen gewählten Ärzten, Forschungseinrichtungen und Familienmitgliedern zu teilen und sie auf Wunsch in Apple Health oder Health Connect zu schreiben. Ihre Daten werden weder für Werbung genutzt noch verkauft.';

  @override
  String get privacyPurposeTitle => 'Wozu verarbeiten wir sie?';

  @override
  String get privacyRetentionBody =>
      'Daten auf dem Telefon bleiben, bis Sie die App löschen. Messwerte im Portal bleiben, bis Sie sie löschen; endet eine Einwilligung, sieht die betreffende Person sie nicht mehr. Zugriffsprotokolle werden wegen gesetzlicher Aufbewahrungspflichten auch nach dem Löschen aufbewahrt.';

  @override
  String get privacyRetentionTitle => 'Wie lange wird gespeichert?';

  @override
  String get privacyRightsBody =>
      'Nach KVKK Art. 11 können Sie Auskunft verlangen, ob Ihre Daten verarbeitet werden, deren Berichtigung oder Löschung verlangen und Ihre Einwilligung widerrufen. In der App können Sie Freigaben unter Profil > Ärzte und Forschung sowie Profil > Gesundheitsgemeinschaft entfernen, Ihre Portaldaten unter Profil > Portal-Konto löschen und alle Daten unter Profil > Meine Daten exportieren als FHIR-Datei erhalten.';

  @override
  String get privacyRightsTitle => 'Ihre Rechte';

  @override
  String get privacySharingBody =>
      'Nur mit den Ärzten, Forschungseinrichtungen oder Mitgliedern einer Familiengruppe, denen Sie zustimmen, nur die gewählten Datentypen und nur für die Dauer der Einwilligung. Selbst eingegebene Werte wie Gewicht und Körperzusammensetzung werden nur geteilt, wenn Sie „Körpermaße“ ausdrücklich auswählen. In Apple Health oder Health Connect werden nur die gewählten Datentypen geschrieben; die App liest dort nichts. Feedback wird nicht mit Ihrer Identität verknüpft. Fällt in den geteilten Datentypen etwas auf (zum Beispiel bleibt die SpO2 lange niedrig oder seit einem Tag kommen keine Daten), zeigt das Portal Ihrem Arzt einen automatischen Hinweis; diese Hinweise sind keine Diagnose und werden mit Ihren Portaldaten gelöscht. Wenn Sie für eine Familiengruppe zusätzlich „Gruppe im Notfall benachrichtigen“ einschalten, sehen deren Mitglieder dieselben Hinweise zu den mit der Gruppe geteilten Datentypen.';

  @override
  String get privacySharingTitle => 'Mit wem wird geteilt?';

  @override
  String get privacyStorageBody =>
      'Die Messwerte liegen auf Ihrem Telefon in einer verschlüsselten Datenbank; der Schlüssel liegt im geschützten Bereich des Telefons (iOS Keychain, Android Keystore). Diese Daten sind nicht Teil von Telefon-Backups. Ins Portal gehen nur die Datentypen, die Sie teilen möchten; auch dort werden sie verschlüsselt gespeichert.';

  @override
  String get privacyStorageTitle => 'Wo werden die Daten gespeichert?';

  @override
  String get privacyTitle => 'Datenschutzerklärung';

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
  String get profileMenuExportSubtitle =>
      'FHIR-Datei für Ihre Ärztin, Ihren Arzt oder eine andere App';

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
  String get qrCameraDenied =>
      'Der Kamerazugriff wurde nicht erlaubt. Erlauben Sie ihn in den Telefoneinstellungen oder geben Sie den Code manuell ein.';

  @override
  String get qrCameraUnavailable =>
      'Die Kamera konnte nicht geöffnet werden. Sie können den Code manuell eingeben.';

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
  String get reminderLabelNote =>
      'Wird auf dem Armband nur mit lateinischen Buchstaben gespeichert (ä → a).';

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
  String get shareRespiration => 'Atemfrequenz';

  @override
  String get shareBody => 'Körpermaße (Gewicht, BMI)';

  @override
  String get connUnverified =>
      'Dieses Ärztekonto wurde vom Portal noch nicht verifiziert. Fahren Sie nur fort, wenn Sie die Person kennen und den Code von ihr erhalten haben.';

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
  String get vo2MaxNeedsAge =>
      'Für die Schätzung wird Ihr Alter benötigt. Verbinden Sie das Armband und tragen Sie es unter Profil > Persönliche Daten ein.';

  @override
  String get vo2MaxNeedsData =>
      'Für den Ruhepuls werden Puls- oder Nachtmessungen von einigen Tagen benötigt.';

  @override
  String get vo2MaxNote =>
      'Geschätzt aus dem Verhältnis von altersbasiertem Maximalpuls zu Ruhepuls; keine Labormessung. Nutzen Sie den Wert, um Ihren Fitnessverlauf zu verfolgen.';

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

  @override
  String get zonesTitle => 'Herzfrequenzzonen';

  @override
  String get zoneWarmUp => 'Aufwärmen';

  @override
  String get zoneFatBurn => 'Fettverbrennung';

  @override
  String get zoneAerobic => 'Aerob';

  @override
  String get zoneAnaerobic => 'Anaerob';

  @override
  String get zoneMaximum => 'Maximal';

  @override
  String get zonesNeedsAge =>
      'Geben Sie Ihr Alter unter Persönliche Angaben ein, um die Zonen zu sehen.';

  @override
  String get zonesEmpty =>
      'In diesem Zeitraum kein Puls oberhalb der Aufwärmzone.';

  @override
  String zonesNote(String max) {
    return 'Ihre maximale Herzfrequenz wurde aus Ihrem Alter geschätzt: $max (208 − 0,7 × Alter). Die Zonen sind Prozentsätze davon.';
  }

  @override
  String zoneSemantics(String zone, String range, String time) {
    return '$zone, $range: $time';
  }

  @override
  String get tempDevTitle => 'Im Vergleich zu Ihrer üblichen Temperatur';

  @override
  String tempDevBaseline(String value, int days, String from, String to) {
    return 'Ihre übliche Temperatur ist $value: der Durchschnitt Ihrer ersten $days Tage mit Messungen ($from – $to).';
  }

  @override
  String tempDevNeedsData(int days) {
    return 'Für Ihre übliche Temperatur sind Messungen an mindestens $days Tagen nötig.';
  }

  @override
  String tempDevAverage(String value) {
    return 'Abweichung in diesem Zeitraum: $value';
  }

  @override
  String get tempDevNote =>
      'Die Handgelenktemperatur unterscheidet sich von der Körperkerntemperatur; sie dient nur dazu, Veränderungen zu verfolgen.';

  @override
  String get bioAgeTitle => 'Biologisches Alter';

  @override
  String bioAgeChronological(int age) {
    return 'Ihr kalendarisches Alter ist $age';
  }

  @override
  String bioAgeYounger(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre jünger',
      one: '1 Jahr jünger',
    );
    return '$_temp0';
  }

  @override
  String bioAgeOlder(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre älter',
      one: '1 Jahr älter',
    );
    return '$_temp0';
  }

  @override
  String get bioAgeSame => 'Wie Ihr kalendarisches Alter';

  @override
  String get bioAgeNeedsAge =>
      'Geben Sie Ihr Alter unter Persönliche Angaben ein (18–90), um Ihr biologisches Alter zu sehen.';

  @override
  String bioAgeNeedsData(int days) {
    return 'Für das biologische Alter sind Puls und Schritte oder Schlaf an mindestens $days der letzten 21 Tage nötig.';
  }

  @override
  String get bioAgeRestingHr => 'Ruhepuls';

  @override
  String get bioAgeSteps => 'Tägliche Schritte';

  @override
  String get bioAgeSleep => 'Nachtschlaf';

  @override
  String get bioAgeBmi => 'Body-Mass-Index';

  @override
  String bioAgeYears(String value) {
    return '$value J.';
  }

  @override
  String get bioAgeTrend => 'Letzte 8 Wochen';

  @override
  String get bioAgeNote =>
      'Eine eigene Schätzung der App aus Ruhepuls, Schritten, Schlaf und BMI der letzten 21 Tage; keine medizinische Messung.';

  @override
  String bioAgeSemantics(int age, String difference) {
    return 'Biologisches Alter $age, $difference';
  }

  @override
  String get radarTitle => 'Gesundheitsradar';

  @override
  String radarCollecting(int nights, int needed) {
    return 'Ihre üblichen Werte werden gelernt: $nights/$needed Nächte.';
  }

  @override
  String get radarNoTonight =>
      'Keine Daten von letzter Nacht. Tragen Sie das Armband auch nachts für das Radar.';

  @override
  String get radarAllClear => 'Die letzte Nacht lag in Ihrem üblichen Bereich.';

  @override
  String get radarWatch =>
      'Ein Wert der letzten Nacht wich von Ihrem Üblichen ab.';

  @override
  String get radarStrong =>
      'Mehrere Werte haben sich gleichzeitig verändert. Gönnen Sie sich heute Ruhe und gehen Sie zum Arzt, wenn Sie sich unwohl fühlen.';

  @override
  String radarHeartRateUp(String value, String base) {
    return 'Nachtpuls $value, üblich $base';
  }

  @override
  String radarHrvDown(String value, String base) {
    return 'Nacht-HRV $value, üblich $base';
  }

  @override
  String radarTemperatureUp(String value, String base) {
    return 'Nachttemperatur $value, üblich $base';
  }

  @override
  String radarSpo2Down(String value, String base) {
    return 'Nächtlicher Sauerstoff $value, üblich $base';
  }

  @override
  String get radarNote =>
      'Jede Nacht wird mit Ihren letzten 14 Nächten verglichen. Es stellt keine Diagnose. Bei Brustschmerzen, Atemnot oder Schwindel rufen Sie den Notruf.';

  @override
  String get aiReportTitle => 'KI-Gesundheitsbericht';

  @override
  String get aiReportCardText =>
      'Ein persönlicher Bericht über Ihre Woche mit Tipps.';

  @override
  String get aiDemoBadge => 'Demo';

  @override
  String get aiDemoNote =>
      'Dies ist ein Beispielbericht: Die KI ist noch nicht verbunden, den Text haben Regeln in der App geschrieben. Ihre Daten haben Ihr Telefon nicht verlassen.';

  @override
  String get aiConsentTitle => 'Einwilligung zur KI-Analyse';

  @override
  String get aiConsentIntro =>
      'Ein KI-Modell schreibt den Wochenbericht. Dazu wird eine Zusammenfassung Ihrer Woche an unseren Server und von dort an den KI-Anbieter gesendet.';

  @override
  String get aiConsentSentTitle => 'Was gesendet wird';

  @override
  String get aiConsentSent =>
      'Altersgruppe und Geschlecht; Wochendurchschnitte für Schritte, Schlaf, Puls, HRV, Stress und Training; Signale des Gesundheitsradars.';

  @override
  String get aiConsentNotSentTitle => 'Was nicht gesendet wird';

  @override
  String get aiConsentNotSent =>
      'Ihr Name, Ihre Kontaktdaten, die Adresse des Armbands, rohe EKG-Aufzeichnungen und einzelne Messwerte.';

  @override
  String get aiConsentAbroad =>
      'Der KI-Anbieter sitzt im Ausland (USA), daher wird die Zusammenfassung ins Ausland übermittelt. Der Anbieter nutzt diese Daten nicht zum Trainieren von Modellen.';

  @override
  String get aiConsentLimits =>
      'Der Bericht stellt keine Diagnose, empfiehlt keine Medikamente und ersetzt keine ärztliche Untersuchung.';

  @override
  String get aiConsentRevoke =>
      'Sie können die Einwilligung jederzeit auf diesem Bildschirm widerrufen. Danach werden keine neuen Berichte erstellt.';

  @override
  String get aiConsentCheck =>
      'Ich willige ausdrücklich ein, dass meine Wochenzusammenfassung zur KI-Analyse ins Ausland übermittelt wird.';

  @override
  String get aiConsentAccept => 'Zulassen';

  @override
  String get aiConsentDecline => 'Nicht jetzt';

  @override
  String get aiGenerate => 'Bericht erstellen';

  @override
  String get aiRegenerate => 'Neu erstellen';

  @override
  String get aiGenerating => 'Bericht wird erstellt …';

  @override
  String aiWeek(String start, String end) {
    return 'Woche vom $start – $end';
  }

  @override
  String get aiEmpty =>
      'Für diese Woche gibt es nicht genug Daten für einen Bericht. Tragen und synchronisieren Sie das Armband ein paar Tage.';

  @override
  String get aiSummaryTitle => 'Zusammenfassung';

  @override
  String get aiWinsTitle => 'Läuft gut';

  @override
  String get aiWatchTitle => 'Im Blick behalten';

  @override
  String get aiTipsTitle => 'Vorschläge';

  @override
  String get aiNothing => 'Diese Woche fällt nichts auf.';

  @override
  String get aiDisclaimer =>
      'Dieser Bericht dient nur der Information. Er stellt keine Diagnose und empfiehlt keine Behandlung. Sprechen Sie bei Beschwerden mit Ihrer Ärztin oder Ihrem Arzt. Rufen Sie bei Brustschmerzen, Atemnot oder Schwächegefühl den Notruf.';

  @override
  String get aiDataTitle => 'Verwendete Daten';

  @override
  String get aiDataNote =>
      'Beim echten Bericht geht nur diese Zusammenfassung an den Server.';

  @override
  String get aiRevoke => 'Einwilligung widerrufen';

  @override
  String get aiRevoked => 'Einwilligung widerrufen.';

  @override
  String aiConsentGiven(String date) {
    return 'Eingewilligt am $date';
  }

  @override
  String aiStepsGood(int steps) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Sie sind im Schnitt $stepsString Schritte am Tag gegangen, über Ihrem Ziel.';
  }

  @override
  String aiStepsLow(int steps) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Ihr Tagesdurchschnitt lag bei $stepsString Schritten, unter Ihrem Bewegungsziel.';
  }

  @override
  String aiStepsUp(int percent) {
    return 'Ihre Schritte sind gegenüber letzter Woche um $percent % gestiegen.';
  }

  @override
  String aiStepsDown(int percent) {
    return 'Ihre Schritte sind gegenüber letzter Woche um $percent % gesunken.';
  }

  @override
  String aiSleepGood(int hours, int minutes) {
    return 'Sie haben im Schnitt $hours Std. $minutes Min. pro Nacht geschlafen, im gesunden Bereich.';
  }

  @override
  String aiSleepShort(int hours, int minutes) {
    return 'Sie haben im Schnitt $hours Std. $minutes Min. pro Nacht geschlafen, unter 7 Stunden.';
  }

  @override
  String aiHrvUp(int percent) {
    return 'Ihre HRV ist gegenüber letzter Woche um $percent % gestiegen, ein Zeichen guter Erholung.';
  }

  @override
  String aiHrvDown(int percent) {
    return 'Ihre HRV ist gegenüber letzter Woche um $percent % gesunken, was auf Müdigkeit oder Stress hindeuten kann.';
  }

  @override
  String aiStressHigh(int level) {
    return 'Ihr durchschnittlicher Stresswert lag bei $level; die Woche war überwiegend hoch.';
  }

  @override
  String aiWorkoutsGood(int count, int minutes) {
    return '$count Trainings, insgesamt $minutes Minuten: Sie bewegen sich regelmäßig.';
  }

  @override
  String get aiRadar =>
      'Der Gesundheitsradar hat letzte Nacht Werte gesehen, die von Ihrem Üblichen abweichen.';

  @override
  String aiBioYounger(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre',
      one: '1 Jahr',
    );
    return 'Ihr geschätztes biologisches Alter liegt $_temp0 unter Ihrem Kalenderalter.';
  }

  @override
  String aiBioOlder(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years Jahre',
      one: '1 Jahr',
    );
    return 'Ihr geschätztes biologisches Alter liegt $_temp0 über Ihrem Kalenderalter.';
  }

  @override
  String get aiTipWalk =>
      'Bauen Sie zwei kurze Spaziergänge von 10–15 Minuten am Tag ein und nehmen Sie die Treppe.';

  @override
  String get aiTipSleep =>
      'Gehen Sie möglichst jeden Tag zur gleichen Zeit ins Bett und stehen Sie zur gleichen Zeit auf; legen Sie Bildschirme eine Stunde vorher weg.';

  @override
  String get aiTipRecover =>
      'Wählen Sie diese Woche lockere Spaziergänge und Dehnen statt hartem Training und geben Sie dem Schlaf Vorrang.';

  @override
  String get aiTipBreathe =>
      'Machen Sie über den Tag einige 2-minütige Pausen mit langsamer Atmung (4 Sekunden ein, 6 Sekunden aus).';

  @override
  String get aiTipMove =>
      'Peilen Sie mindestens 150 Minuten moderate Bewegung pro Woche an; auch kurze Einheiten zählen.';

  @override
  String get aiTipRadar =>
      'Lassen Sie es heute ruhig angehen und trinken Sie viel Wasser. Wenn Sie sich nicht wohlfühlen, sprechen Sie mit Ihrer Ärztin oder Ihrem Arzt.';

  @override
  String get aiTipKeep =>
      'Weiter so – tragen Sie das Armband auch nachts, damit Schlaf- und Erholungsdaten vollständig bleiben.';

  @override
  String get aiSummaryGood =>
      'Insgesamt war es eine gute Woche, ohne auffällige Probleme.';

  @override
  String get aiSummaryMixed =>
      'Eine ausgeglichene Woche: Einiges läuft gut, ein paar Dinge sollten Sie im Blick behalten.';

  @override
  String get aiSummaryCare =>
      'Ihr Körper braucht diese Woche etwas mehr Fürsorge; die Vorschläge unten können helfen.';

  @override
  String aiSummaryFewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage',
      one: '1 Tag',
    );
    return 'Nur $_temp0 mit Daten diese Woche, daher zeigt der Bericht ein begrenztes Bild.';
  }

  @override
  String get premiumTitle => 'Bileklik Premium';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get premiumSubtitle => 'Holen Sie mehr aus Ihren Daten heraus.';

  @override
  String get premiumBenefitReport => 'Wöchentlicher KI-Gesundheitsbericht';

  @override
  String get premiumBenefitCoaching => 'Persönliche Coaching-Tipps';

  @override
  String get premiumBenefitFree =>
      'Messungen, Verlauf, Teilen und Warnungen bleiben kostenlos';

  @override
  String get premiumMonthly => 'Monatlich';

  @override
  String get premiumYearly => 'Jährlich';

  @override
  String premiumPerMonth(String price) {
    return '$price / Monat';
  }

  @override
  String premiumPerYear(String price) {
    return '$price / Jahr';
  }

  @override
  String premiumSave(int percent) {
    return '$percent % sparen';
  }

  @override
  String get premiumSubscribe => 'Abonnieren';

  @override
  String get premiumRestore => 'Käufe wiederherstellen';

  @override
  String get premiumRestoreNone => 'Keine Käufe zum Wiederherstellen.';

  @override
  String get premiumRestored => 'Kauf wiederhergestellt.';

  @override
  String get premiumTerms =>
      'Das Abo verlängert sich am Ende jedes Zeitraums automatisch. Sie können jederzeit in Ihrem Store-Konto kündigen; danach bleibt Premium bis zum Ende des Zeitraums aktiv.';

  @override
  String get premiumDemoNote =>
      'Demo: Bezahlt wird später über den App Store oder Google Play. In dieser Version wird nichts abgebucht, die Preise sind Beispiele.';

  @override
  String get storeSheetTitle => 'Demo-Store';

  @override
  String storeSheetItem(String plan) {
    return 'Bileklik Premium · $plan';
  }

  @override
  String get storeSheetNote => 'Es wird nichts abgebucht.';

  @override
  String get storeConfirm => 'Bestätigen';

  @override
  String get storeCancel => 'Abbrechen';

  @override
  String get premiumActive => 'Premium ist aktiv. Danke!';

  @override
  String get subscriptionTitle => 'Abo';

  @override
  String get subscriptionFree => 'Kostenlos';

  @override
  String subscriptionPremium(String plan) {
    return 'Premium · $plan';
  }

  @override
  String subscriptionRenews(String date) {
    return 'Verlängerung am $date';
  }

  @override
  String subscriptionEnds(String date) {
    return 'Endet am $date';
  }

  @override
  String get subscriptionUpgrade => 'Zu Premium wechseln';

  @override
  String get subscriptionCancel => 'Abo kündigen';

  @override
  String subscriptionCancelConfirm(String date) {
    return 'Das Abo verlängert sich nicht; Premium bleibt bis $date aktiv.';
  }

  @override
  String get subscriptionCancelled => 'Abo gekündigt.';

  @override
  String get subscriptionKeep => 'Abo behalten';

  @override
  String get subscriptionFreeText =>
      'Messungen, Verlauf, Teilen und Warnungen sind kostenlos. Der KI-Bericht ist in Premium enthalten.';

  @override
  String get diagTitle => 'Verbindungsdiagnose';

  @override
  String get diagOpen => 'Verbindungsdiagnose';

  @override
  String get diagIntro =>
      'Zeigt, was bei den ersten Tests mit dem Armband passiert. Wenn etwas nicht klappt, teilen Sie das Protokoll.';

  @override
  String get diagMode => 'Modus';

  @override
  String get diagModeReal => 'Echtes Armband';

  @override
  String get diagModeDemo => 'Demo (simuliertes Armband)';

  @override
  String get diagConnecting => 'Verbindung wird hergestellt';

  @override
  String get diagPaired => 'Gekoppelt mit';

  @override
  String get diagNone => 'Keines';

  @override
  String get diagWriteLength => 'Paketgröße';

  @override
  String diagWriteLengthValue(int bytes) {
    return '$bytes Byte';
  }

  @override
  String get diagNextRetry => 'Nächster Versuch';

  @override
  String diagNextRetryValue(int seconds) {
    return 'in $seconds s';
  }

  @override
  String get diagReconnect => 'Jetzt verbinden';

  @override
  String get diagForget => 'Armband vergessen';

  @override
  String get diagSectionTests => 'Testbefehle';

  @override
  String get diagTestsHint =>
      'Im verbundenen Zustand tippen; gesendete und empfangene Pakete erscheinen unten im Protokoll.';

  @override
  String get diagTestBattery => 'Akku';

  @override
  String get diagTestTime => 'Uhrzeit';

  @override
  String get diagTestFirmware => 'Version';

  @override
  String get diagTestProfile => 'Persönliche Daten';

  @override
  String get diagTestRealtime => 'Live-Daten';

  @override
  String get diagRawLabel => 'Rohbefehl (hex)';

  @override
  String get diagRawHint => 'z. B. 13 — CRC wird automatisch ergänzt';

  @override
  String get diagRawSend => 'Senden';

  @override
  String get diagRawInvalid => 'Gültige Hex-Bytes eingeben (höchstens 15).';

  @override
  String get diagNotConnected => 'Verbinden Sie zuerst das Armband.';

  @override
  String get diagSectionScan => 'Alle Geräte suchen';

  @override
  String get diagScanHint =>
      'Wenn das Armband beim Koppeln nicht erscheint, suchen Sie hier: Alle Bluetooth-Geräte in der Nähe werden ohne Namensfilter angezeigt.';

  @override
  String get diagScan => 'Suchen';

  @override
  String get diagScanning => 'Suche läuft…';

  @override
  String get diagScanEmpty => 'Keine Geräte gefunden.';

  @override
  String get diagConnectTo => 'Verbinden';

  @override
  String get diagSectionDeveloper => 'Entwickler';

  @override
  String get diagDemoSwitch => 'Demo-Modus (simuliertes Armband)';

  @override
  String get diagDemoHint =>
      'Wirkt nach dem Schließen und erneuten Öffnen der App. Demodaten werden nicht in Health Connect geschrieben.';

  @override
  String get diagRestartNeeded => 'App schließen und erneut öffnen.';

  @override
  String get diagSectionLog => 'Protokoll';

  @override
  String get diagLogEmpty => 'Noch keine Einträge.';

  @override
  String get diagShare => 'Protokoll teilen';

  @override
  String get diagClear => 'Protokoll leeren';

  @override
  String diagLogCount(int count) {
    return '$count Zeilen, neueste zuerst';
  }

  @override
  String get startupFailedTitle => 'Die App konnte nicht starten';

  @override
  String get startupFailedBody =>
      'Beim Start ist ein Fehler aufgetreten. Kopieren Sie den Text unten und senden Sie ihn uns, damit wir ihn in einer neuen Version beheben.';

  @override
  String get startupFailedCopy => 'Fehler kopieren';

  @override
  String get ecgPrepareTitle => 'EKG-Messung';

  @override
  String get ecgHandQuestion => 'An welchem Handgelenk tragen Sie das Armband?';

  @override
  String get ecgHandLeft => 'Linke Hand';

  @override
  String get ecgHandRight => 'Rechte Hand';

  @override
  String get ecgWearTip =>
      'Tragen Sie das Armband für beste Ergebnisse etwa einen Finger breit über dem Handgelenkknochen mit vollem Hautkontakt. Halten Sie die Hand während der Messung locker und ruhig.';

  @override
  String get ecgStartMeasure => 'Messung starten';

  @override
  String get ecgTip1Title => 'Setzen Sie sich, Füße flach auf den Boden';

  @override
  String get ecgTip1Body =>
      'Aufrechtes Sitzen verringert den Einfluss der Haltung.';

  @override
  String get ecgTip2Title => 'Legen Sie die Arme auf einen Tisch';

  @override
  String get ecgTip2Body =>
      'Arme locker lassen; Muskelspannung stört das Signal.';

  @override
  String get ecgTip3Title => 'Nicht sprechen, nicht bewegen';

  @override
  String get ecgTip3Body => 'Das Signal wird klarer und stabiler.';

  @override
  String get ecgTip4Title =>
      'Legen Sie einen Finger der anderen Hand auf den Metallkontakt des Armbands';

  @override
  String get ecgTip4Body =>
      'Leichtes Berühren genügt; nicht drücken und bis zum Ende warten.';

  @override
  String get ecgWaitingTitle => 'Finger auf den Metallkontakt legen';

  @override
  String get ecgWaitingBody =>
      'Der Countdown startet von selbst, sobald das Armband ein Signal erkennt.';

  @override
  String ecgWaitingElapsed(int seconds) {
    return 'Warte auf Signal · $seconds s';
  }

  @override
  String get ecgNoSignalYetTitle => 'Noch kein Signal';

  @override
  String get ecgNoSignalYetBody =>
      'Achten Sie auf Hautkontakt des Armbands und darauf, dass Ihr Finger den Metallkontakt berührt. Wenn es so bleibt, senden Sie uns das Verbindungsprotokoll.';

  @override
  String get ecgSecondsUnit => 's';

  @override
  String get ecgLiveDisclaimer =>
      'Die Live-Kurve dient nur der Information, nicht der Diagnose. Nach der Messung öffnet sich ein ausführlicher Bericht.';

  @override
  String get diagCleared => 'Protokoll geleert. Neue Pakete kommen weiter an.';

  @override
  String get ecgReportTitle => 'EKG-Bericht';

  @override
  String get ecgReportPickMonth => 'Monat wählen';

  @override
  String ecgReportMonthEmpty(String month) {
    return 'Keine EKG-Aufnahmen im $month.';
  }

  @override
  String ecgReportMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufnahmen',
      one: '1 Aufnahme',
    );
    return '$_temp0';
  }

  @override
  String ecgReportWhen(String date, String time) {
    return '$date, $time';
  }

  @override
  String get ecgFindingNormalOk => 'Normaler Herzrhythmus erkannt';

  @override
  String get ecgFindingNormalFlagged => 'Auffälligkeiten im Herzrhythmus';

  @override
  String get ecgFindingHighOk => 'Keine hohe Herzfrequenz erkannt';

  @override
  String get ecgFindingHighFlagged =>
      'Hohe Herzfrequenz erkannt (über 100 bpm)';

  @override
  String get ecgFindingLowOk => 'Keine niedrige Herzfrequenz erkannt';

  @override
  String get ecgFindingLowFlagged =>
      'Niedrige Herzfrequenz erkannt (unter 50 bpm)';

  @override
  String get ecgFindingAfibOk => 'Keine Anzeichen von Vorhofflimmern erkannt';

  @override
  String get ecgFindingAfibFlagged =>
      'Unregelmäßiger Rhythmus: mögliches Vorhofflimmern, zeigen Sie die Aufnahme Ihrer Ärztin oder Ihrem Arzt';

  @override
  String get ecgFindingUnknown =>
      'Aufnahme nicht auswertbar: zu wenige Schläge erkannt oder Signal gestört';

  @override
  String get ecgReportNote =>
      'Die Befunde sind eine automatische Ersteinschätzung der App, keine Diagnose.';

  @override
  String get healthMeasure => 'Messen';

  @override
  String get healthAdd => 'Hinzufügen';

  @override
  String healthGoalValue(String goal) {
    return '/$goal';
  }

  @override
  String get healthSleepShort => 'Zu wenig Schlaf';

  @override
  String get healthSleepGood => 'Ausreichend Schlaf';

  @override
  String get healthSleepLong => 'Langer Schlaf';

  @override
  String get healthEcgUnassessed => 'Nicht auswertbar';

  @override
  String get healthVo2Unit => 'ml/kg/min';

  @override
  String get healthVo2NeedsData =>
      'Benötigt Ihr Alter und einige Tage Herzfrequenz';

  @override
  String get healthEstimated => 'Geschätzt';

  @override
  String get homeLateNightTitle => 'Es ist spät, versuchen Sie sich auszuruhen';

  @override
  String get homeLateNightBody =>
      'Früh zu ruhen ist wichtig dafür, wie Sie sich morgen fühlen. Legen Sie das Handy weg und entspannen Sie die Augen.';

  @override
  String get homeLowRecoveryTitle => 'Ihr Körper erholt sich heute';

  @override
  String get homeLowRecoveryBody =>
      'Ihre nächtliche HRV ist niedriger als sonst. Wählen Sie leichte Bewegung und frühen Schlaf statt hartem Training.';

  @override
  String get homeSleepScore => 'Schlaf';

  @override
  String get homeDailyRecovery => 'Tägliche Erholung';

  @override
  String get homeDailyLoad => 'Tägliche Belastung';

  @override
  String homeGaugeSemantics(String label, String value) {
    return '$label: $value';
  }

  @override
  String get homeAiTitle => 'KI-Analyse von heute';

  @override
  String get homeAiBody =>
      'Erstellen Sie aus den heutigen Daten eine persönliche Gesundheitsübersicht.';

  @override
  String get homeSleepExcellent => 'Ausgezeichnet';

  @override
  String get homeSleepGood => 'Gut';

  @override
  String get homeSleepFair => 'Ganz gut';

  @override
  String get homeSleepPoor => 'Schwach';

  @override
  String get homeSleepDuration => 'Dauer';

  @override
  String get homeActivity => 'Aktivität';

  @override
  String get homeActivityLow => 'Zu wenig Bewegung';

  @override
  String get homeActivityFair => 'Mäßige Bewegung';

  @override
  String get homeActivityGood => 'Gute Bewegung';

  @override
  String get homeActivityDone => 'Ziel erreicht';

  @override
  String get homeKilometers => 'Kilometer';

  @override
  String get homeFellAsleep => 'Eingeschlafen';

  @override
  String get homeFellAsleepSubtitle => 'Schlafbeginn';

  @override
  String get homeNightLowHrv => 'Niedrige HRV';

  @override
  String get homeNightHighHr => 'Hoher Puls im Schlaf';

  @override
  String get homeNightLowHr => 'Niedriger Puls im Schlaf';

  @override
  String get homeNightLowSpo2 => 'Abfall des Blutsauerstoffs';

  @override
  String get homeRestingLabel => 'Ruhepuls';

  @override
  String get homeAverageLabel => 'Durchschnitt';

  @override
  String get homeLowestLabel => 'Niedrigster';

  @override
  String get bioAgeCollectingTitle => 'Datenerfassung läuft';

  @override
  String bioAgeCollectingBody(int days) {
    return 'Für Ihren ersten Bericht zum biologischen Alter sind mindestens $days aufeinanderfolgende Tage mit vollständigen Daten nötig.';
  }

  @override
  String get bioAgeCollectingProgress => 'Erfasste Daten';

  @override
  String bioAgeCollectingDays(int done, int total) {
    return '$done/$total Tage';
  }

  @override
  String bioAgeRemaining(int days) {
    return 'Noch $days Tage';
  }

  @override
  String get bioAgeKeepGoing =>
      'Tragen Sie das Armband weiter, bald sehen Sie Ihr biologisches Alter.';

  @override
  String get bioAgeDailyRequired => 'Täglich benötigte Daten';

  @override
  String get bioAgeDataSleep => 'Schlaf';

  @override
  String get bioAgeDataHeartRate => 'Herzfrequenz';

  @override
  String get bioAgeDataExercise => 'Training';

  @override
  String get bioAgeDataSteps => 'Schritte';

  @override
  String get bioAgeToday => 'Heute erhalten';

  @override
  String get bioAgeNotToday => 'Heute noch nicht';

  @override
  String get bioAgeOptional => 'Optional';

  @override
  String get bioAgeAgeCheckTitle =>
      'Prüfen Sie, ob das Alter in Ihrem Profil stimmt.';

  @override
  String get bioAgeAgeCheckBody =>
      'Ihr biologisches Alter und Ihre Gesundheitswerte werden aus Ihrem echten Alter berechnet.';

  @override
  String get bioAgeTipsTitle => 'Tipps zur Datenerfassung';

  @override
  String get bioAgeTipSleep =>
      'Tragen Sie das Armband jede Nacht, damit Ihr Schlaf vollständig erfasst wird.';

  @override
  String get bioAgeTipHeart =>
      'Tragen Sie das Armband den ganzen Tag für genaue Herzfrequenzwerte.';

  @override
  String get bioAgeTipActivity =>
      'Erfassen Sie Ihre täglichen Schritte und Trainings.';

  @override
  String get sleepScoreLabel => 'Schlafwert';

  @override
  String get sleepBedTime => 'Eingeschlafen';

  @override
  String get sleepWakeTime => 'Aufgewacht';

  @override
  String get sleepDistribution => 'Schlafphasen';

  @override
  String get sleepIdealRange => 'Idealbereich';

  @override
  String sleepIdealValue(int low, int high) {
    return 'Ideal $low–$high %';
  }

  @override
  String get sleepPattern => 'Schlafmuster';

  @override
  String get sleepInBed => 'Zeit im Bett';

  @override
  String get sleepEfficiency => 'Schlafeffizienz';

  @override
  String get sleepLatency => 'Einschlafdauer';

  @override
  String get sleepDebt => 'Schlafdefizit';

  @override
  String get sleepNoDebt => 'Keins';

  @override
  String get sleepDuringHeartRate => 'Herzfrequenz im Schlaf';

  @override
  String get sleepDuringSpo2 => 'Blutsauerstoff im Schlaf';

  @override
  String get sleepDuringHrv => 'HRV im Schlaf';

  @override
  String get sleepNaps => 'Nickerchen';

  @override
  String get sleepNoNaps => 'Keine Nickerchen';

  @override
  String sleepSummaryDebt(String duration, String debt) {
    return 'Sie haben $duration geschlafen; gemessen am Bedarf von 8 Stunden fehlen Ihnen $debt.';
  }

  @override
  String sleepSummaryEnough(String duration) {
    return 'Sie haben $duration geschlafen und Ihren Tagesbedarf gedeckt.';
  }

  @override
  String get sleepSummaryLowDeep =>
      'Ihr Tiefschlaf liegt unter dem empfohlenen Bereich; abends auf Koffein und schwere Mahlzeiten zu verzichten kann helfen.';

  @override
  String sleepSummaryLowEfficiency(int value) {
    return 'Sie lagen lange wach im Bett; Ihre Schlafeffizienz beträgt $value %.';
  }

  @override
  String get sleepSummaryNote =>
      'Dies ist eine eigene Einschätzung der App aus den Armbanddaten, keine medizinische.';

  @override
  String sleepStagesChart(String start, String end) {
    return 'Schlafphasen von $start bis $end';
  }

  @override
  String get recoveryTitle => 'Erholung';

  @override
  String get recoveryExcellent => 'Ausgezeichnet';

  @override
  String get recoveryGood => 'Gut';

  @override
  String get recoveryNormal => 'Normal';

  @override
  String get recoveryPoor => 'Schwach';

  @override
  String get recoveryInadequate => 'Unzureichend';

  @override
  String get recoveryOptimal => 'Optimal';

  @override
  String get recoveryAssessment => 'Einschätzung';

  @override
  String get recoveryCommentExcellent =>
      'Sie sind sehr gut erholt; ein guter Tag für intensives Training.';

  @override
  String get recoveryCommentGood =>
      'Sie sind gut erholt; Ihr übliches Training passt.';

  @override
  String get recoveryCommentNormal =>
      'Die Erholung ist mittel, leichte Müdigkeit ist vorhanden. Leichte Aktivität wird empfohlen.';

  @override
  String get recoveryCommentPoor =>
      'Die Erholung ist schwach; machen Sie heute langsamer und ruhen Sie sich aus.';

  @override
  String get recoveryCommentInadequate =>
      'Ihr Körper hat sich nicht ausreichend erholt; ruhen Sie sich heute aus und gehen Sie früh schlafen.';

  @override
  String get recoveryHrvLow =>
      'Ihre HRV liegt unter Ihrem Normalwert; Ihr Körper erholt sich vielleicht noch.';

  @override
  String get recoveryRhrHigh => 'Ihr Ruhepuls ist höher als üblich.';

  @override
  String get recoveryNote =>
      'Eigene Schätzung der App aus den Armbanddaten, keine medizinische.';

  @override
  String get recoveryIndicators => 'Erholungswerte';

  @override
  String get recoveryRestingHr => 'Ruhepuls';

  @override
  String get recoveryHrv => 'HRV';

  @override
  String get recoveryStress => 'Stress';

  @override
  String get recoverySleepScore => 'Schlafwert';

  @override
  String recoveryUsual(String value) {
    return 'Üblich $value';
  }

  @override
  String get recoveryTrend => 'Verlauf';

  @override
  String get recoveryWeek => 'Woche';

  @override
  String get recoveryMonth => 'Monat';

  @override
  String recoveryRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get recoveryEmpty =>
      'Für die Erholung sind nächtliche HRV- oder Schlafdaten nötig. Tragen Sie das Armband heute Nacht.';

  @override
  String get recoveryTrendEmpty => 'Keine Daten in diesem Zeitraum';

  @override
  String recoveryRingSemantics(String value, String level) {
    return 'Tägliche Erholung $value, $level';
  }

  @override
  String recoveryTrendSemantics(String range, String value) {
    return 'Erholungsverlauf $range, Durchschnitt $value';
  }

  @override
  String homeStreakSemantics(int days) {
    return '$days Tage Daten in Folge';
  }

  @override
  String get homeEnergyLabel => 'Energie';

  @override
  String get homeEnergyHigh => 'Hoch';

  @override
  String get homeEnergyNormal => 'Normal';

  @override
  String get homeEnergyLow => 'Niedrig';

  @override
  String homeEnergyVsYesterday(String delta) {
    return '$delta gegenüber gestern';
  }

  @override
  String get homeEnergySame => 'Wie gestern';

  @override
  String get homeEnergyNoCompare => 'Kein Vergleich mit gestern';

  @override
  String get homeTrainingPlan => 'Trainingsplan';

  @override
  String get homeAiCollapse => 'Einklappen';

  @override
  String get homeAiExpand => 'Ausklappen';

  @override
  String homeAiUpdated(String time) {
    return 'Daten aktualisiert um $time';
  }

  @override
  String get homeAiReanalyze => 'Neu analysieren';

  @override
  String get homeAiNoData =>
      'Für heute gibt es noch keine Daten. Tragen Sie das Armband und synchronisieren Sie.';

  @override
  String homeAiLoad(String value) {
    return 'Ihre Tagesbelastung heute: $value/21.';
  }

  @override
  String get navAi => 'KI-Analyse';

  @override
  String get planTitle => 'Trainingsplan für heute';

  @override
  String get planIntenseTitle => 'Intensives Training';

  @override
  String get planIntenseBody =>
      '35–45 Minuten Lauf- oder Intervalltraining sind möglich.';

  @override
  String get planModerateTitle => 'Mittleres Training';

  @override
  String get planModerateBody =>
      '30–40 Minuten zügiges Gehen, Radfahren oder lockeres Laufen.';

  @override
  String get planLightTitle => 'Leichte Aktivität';

  @override
  String get planLightBody => '20–30 Minuten lockeres Gehen oder Dehnen.';

  @override
  String get planRestTitle => 'Ruhetag';

  @override
  String get planRestBody =>
      '10–15 Minuten Dehnen oder Atemübungen; meiden Sie intensives Training.';

  @override
  String planZone(String range, String zone) {
    return 'Zielpuls: $range ($zone)';
  }

  @override
  String planBasedOn(String value) {
    return 'Empfohlen anhand Ihrer heutigen Erholung ($value).';
  }

  @override
  String get planNeedsData =>
      'Für den Plan sind nächtliche HRV- oder Schlafdaten nötig. Tragen Sie das Armband heute Nacht.';

  @override
  String get planNote =>
      'Eigene Empfehlung der App; hören Sie bei Beschwerden auf.';

  @override
  String get planNeedsAge =>
      'Geben Sie für den Zielpuls Ihr Alter unter Persönliche Daten ein.';

  @override
  String get bioAgeUnlockTitle => 'Biologisches Alter freischalten';

  @override
  String bioAgeUnlockIn(int days) {
    return 'Ihr biologisches Alter wird in $days Tagen freigeschaltet.';
  }

  @override
  String get strainVeryLow => 'Sehr niedrig';

  @override
  String get strainNormal => 'Normal';

  @override
  String get strainModerate => 'Mäßig';

  @override
  String get strainHigh => 'Hoch';

  @override
  String get strainOverloaded => 'Überlastet';

  @override
  String get strainAiTitle => 'KI-Analyse';

  @override
  String get strainCommentVeryLow =>
      'Ihre Gesamtbelastung blieb heute niedrig, der Körper wurde kaum beansprucht.';

  @override
  String get strainCommentNormal =>
      'Ihre Belastung war heute ausgewogen; die Alltagsaktivität ist gut.';

  @override
  String get strainCommentModerate =>
      'Sie haben sich heute mäßig gefordert; diese Belastung stärkt die Fitness.';

  @override
  String get strainCommentHigh =>
      'Ihre Belastung war heute hoch; unterstützen Sie die Erholung mit Schlaf und Flüssigkeit.';

  @override
  String get strainCommentOverloaded =>
      'Ihr Körper wurde heute sehr stark belastet; planen Sie morgen einen leichten Tag und ruhen Sie sich gut aus.';

  @override
  String strainBelowOptimal(String low, String high) {
    return 'Ihrer Erholung nach könnten Sie sich heute etwas mehr bewegen; Ihre optimale Belastung liegt bei $low–$high.';
  }

  @override
  String strainAboveOptimal(String low, String high) {
    return 'Ihre Belastung liegt über dem für Ihre Erholung optimalen Bereich ($low–$high); gönnen Sie sich Ruhe.';
  }

  @override
  String get strainNote =>
      'Eigene Schätzung der App aus Puls, Schritten und Training; keine medizinische Aussage.';

  @override
  String get strainIndicators => 'Belastungswerte';

  @override
  String get strainSleep => 'Schlaf';

  @override
  String get strainAvgHr => 'Ø Puls';

  @override
  String get strainSteps => 'Schritte';

  @override
  String get strainKcal => 'kcal';

  @override
  String get strainWorkout => 'Training';

  @override
  String get strainEmpty =>
      'Für die Tagesbelastung braucht es Puls-, Schritt- oder Trainingsdaten. Tragen Sie das Armband über den Tag.';

  @override
  String strainRingSemantics(String value, String level) {
    return 'Tagesbelastung $value, $level';
  }

  @override
  String strainTrendSemantics(String range, String value) {
    return 'Belastungsverlauf $range, Durchschnitt $value';
  }

  @override
  String get strainOpen => 'Details zur Tagesbelastung';

  @override
  String get wrTitle => 'Trainingsbericht';

  @override
  String get wrLoad => 'Trainingsbelastung';

  @override
  String get wrAvgHr => 'Ø Puls';

  @override
  String get wrMaxHr => 'Max. Puls';

  @override
  String get wrMet => 'Metabolisches Äquivalent';

  @override
  String get wrMetLight => 'Leichte Aktivität';

  @override
  String get wrMetModerate => 'Fitness erhalten';

  @override
  String get wrMetVigorous => 'Ausdauer aufbauen';

  @override
  String get wrMetCommentLight =>
      'Ein Training mit leichter Intensität; es regt den Kreislauf an und unterstützt die Erholung.';

  @override
  String get wrMetCommentModerate =>
      'Ein Training mit mittlerer Intensität; es hält Herz und Muskeln fit.';

  @override
  String get wrMetCommentVigorous =>
      'Ein Training mit hoher Intensität. Solche Aktivitäten erhöhen den Puls schnell und verbessern Herz-Lungen-Leistung, Muskelkraft und Ausdauer deutlich.';

  @override
  String get wrRecovery => 'Erholung';

  @override
  String wrHrChart(String unit) {
    return 'Puls ($unit)';
  }

  @override
  String get wrRange => 'Bereich';

  @override
  String get wrZones => 'Pulszonen';

  @override
  String get wrNote =>
      'Eigene Schätzung der App aus Puls und Kalorien; keine medizinische Aussage.';

  @override
  String wrLoadSemantics(String value) {
    return 'Trainingsbelastung $value von 21';
  }

  @override
  String wrGaugeSemantics(String label, String value, String level) {
    return '$label $value, $level';
  }

  @override
  String wrChartSemantics(String range) {
    return 'Puls während des Trainings $range';
  }

  @override
  String get wrNoHeartRate =>
      'Während dieses Trainings wurde kein Puls gemessen.';

  @override
  String get exerciseRecords => 'Trainingsaufzeichnungen ansehen';

  @override
  String get exerciseRecordsTitle => 'Trainingsaufzeichnungen';

  @override
  String get exerciseMinutesUnit => 'Min.';

  @override
  String get exerciseTotalTime => 'Gesamtzeit';

  @override
  String get exerciseTotalCount => 'Anzahl gesamt';

  @override
  String get exerciseMore => 'Mehr';

  @override
  String get exerciseGps => 'GPS-Training';

  @override
  String get exerciseIndoor => 'Indoor-Training';

  @override
  String get exerciseGpsNote =>
      'Routenaufzeichnung gibt es noch nicht; die Distanz kommt vom Armband.';

  @override
  String get exerciseGpsOff => 'GPS-Signal wird nicht genutzt';

  @override
  String get exerciseGo => 'LOS';

  @override
  String exerciseGoSemantics(String sport) {
    return '$sport-Training starten';
  }

  @override
  String get exerciseResume => 'Öffnen';

  @override
  String get exerciseGoal => 'Ziel';

  @override
  String get exerciseGoalNone => 'Kein Ziel';

  @override
  String get exerciseGoalTitle => 'Zeitziel';

  @override
  String get exerciseSportTitle => 'Sportart';

  @override
  String liveGoal(String value) {
    return 'Ziel: $value';
  }

  @override
  String get liveGoalReached => 'Ziel erreicht';

  @override
  String get locationTitle => 'Standortfreigabe';

  @override
  String get locationBanner => 'Ihr Standort wird geteilt';

  @override
  String locationViewers(String names) {
    return 'Sehen Ihren Standort: $names';
  }

  @override
  String get locationOff => 'Ihr Standort wird mit niemandem geteilt.';

  @override
  String get locationOffShort => 'Aus';

  @override
  String locationLastSent(String time) {
    return 'Zuletzt gesendet: $time';
  }

  @override
  String get locationWaiting => 'Standort wird ermittelt…';

  @override
  String get locationStart => 'Freigabe starten';

  @override
  String get locationChoose => 'Personen wählen';

  @override
  String get locationStop => 'Freigabe beenden';

  @override
  String get locationNeedsGroup =>
      'Um Ihren Standort zu teilen, erstellen Sie zuerst eine Gruppe oder treten Sie einer bei.';

  @override
  String get locationSharedWithMe => 'Mit Ihnen geteilt';

  @override
  String get locationNoneShared =>
      'Noch teilt niemand seinen Standort mit Ihnen.';

  @override
  String locationUpdated(String time) {
    return 'Letzter Standort: $time';
  }

  @override
  String get locationMe => 'Ich';

  @override
  String get locationNote =>
      'Ihr Standort wird nur an die von Ihnen gewählten Personen gesendet und nur, solange die App geöffnet ist. Die Freigabe ist standardmäßig aus und Sie können sie jederzeit beenden.';

  @override
  String get locationSheetTitle => 'Wer darf meinen Standort sehen?';

  @override
  String get locationWholeGroup => 'Ganze Gruppe';

  @override
  String get locationNoMembers => 'Dieser Gruppe ist noch niemand beigetreten.';

  @override
  String get locationSave => 'Speichern';

  @override
  String get locationProblemServiceOff =>
      'Die Standortdienste Ihres Telefons sind aus.';

  @override
  String get locationProblemDenied =>
      'Die Standortberechtigung wurde nicht erteilt.';

  @override
  String get locationProblemDeniedForever =>
      'Die Standortberechtigung ist aus; Sie können sie in den Telefoneinstellungen aktivieren.';

  @override
  String get locationProblemFailed =>
      'Standort konnte nicht ermittelt werden; neuer Versuch in Kürze.';

  @override
  String get privacyLocationTitle => 'Standort und Karten';

  @override
  String get privacyLocationBody =>
      'Die Standortfreigabe ist standardmäßig aus. Wenn Sie sie einschalten, wird der Standort Ihres Telefons nur an die von Ihnen gewählten Gruppenmitglieder gesendet, nur solange die App geöffnet ist und alle paar Minuten; außer dem letzten Standort und seiner Zeit wird kein Standortverlauf gespeichert. Solange die Freigabe läuft, ist auf jedem Bildschirm der App ein Hinweis zu sehen, und Sie können sie jederzeit unter Profil > Gesundheitsgemeinschaft > Standortfreigabe beenden. Karten werden mit Google Maps angezeigt: Beim Öffnen einer Karte wird eine Anfrage für die Kartenkacheln des angezeigten Bereichs an Google gesendet; Ihre Gesundheitsdaten werden nicht an Google gesendet. Wie Google diese Daten verarbeitet, steht in der Google-Datenschutzerklärung.';

  @override
  String get asstName => 'Vita';

  @override
  String get asstTitle => 'Vita · Gesundheitsassistent';

  @override
  String get asstTagline => 'Kleine Schritte, großer Unterschied';

  @override
  String get asstHello => 'Hallo, ich bin';

  @override
  String get asstIntro => 'Ich beantworte Ihre Fragen anhand Ihrer Daten.';

  @override
  String get asstInputHint => 'Nachricht eingeben…';

  @override
  String get asstSend => 'Senden';

  @override
  String get asstTyping => 'Vita schreibt';

  @override
  String get asstOffline =>
      'Offline: Antworten werden auf Ihrem Telefon nach Regeln erstellt.';

  @override
  String get asstOnline =>
      'KI verbunden: Ihre Frage und Kennzahlen gehen pseudonymisiert an unseren Server.';

  @override
  String get asstNote =>
      'Vita stellt keine Diagnosen und empfiehlt keine Medikamente. Rufen Sie im Notfall 112 an.';

  @override
  String get asstSuggestReport =>
      'Kannst du den heutigen Gesundheitsbericht erstellen?';

  @override
  String get asstSuggestTraining =>
      'Kannst du mir passend zu meiner Gesundheit einen Trainingsplan vorschlagen?';

  @override
  String get asstSuggestSleep => 'Wie habe ich letzte Nacht geschlafen?';

  @override
  String get asstSuggestHeart => 'Wie steht es um mein Herz und EKG?';

  @override
  String get asstGreeting =>
      'Hallo! Ich bin Vita, Ihr Gesundheitsassistent. Fragen Sie mich zu Schlaf, Puls, Erholung, Tagesbelastung, Stress, EKG-Aufnahmen, biologischem Alter, Schritten und Trainings.';

  @override
  String get asstThanks =>
      'Gern geschehen! Ich bin da, wenn Sie noch eine Frage haben.';

  @override
  String get asstUnknown =>
      'Das habe ich nicht ganz verstanden. Sie können fragen: Wie habe ich geschlafen, heutiger Bericht, Puls, Erholung, Belastung, Stress, EKG, biologisches Alter, Schritte oder ein passendes Training.';

  @override
  String get asstEmergency =>
      'Was Sie beschreiben, kann ein Notfall sein. Rufen Sie sofort 112 an oder gehen Sie in die nächste Notaufnahme. Armband und App können keinen Notfall beurteilen.';

  @override
  String get asstNoDiagnosis =>
      'Ich kann keine Diagnose stellen und keine Medikamente oder Dosen empfehlen; fragen Sie bitte Ihren Arzt. Ich kann Ihnen sagen, was ich in Ihren Daten sehe.';

  @override
  String get asstNoData =>
      'Dazu gibt es noch nicht genug Daten. Je mehr Sie das Armband tragen und synchronisieren, desto mehr kann ich sagen.';

  @override
  String asstSleep(String start, String end, String duration) {
    return 'Letzte Nacht haben Sie $duration geschlafen, von $start bis $end.';
  }

  @override
  String asstSleepScore(String score) {
    return 'Ihr Schlafwert liegt bei $score/100.';
  }

  @override
  String asstSleepEfficiency(String value) {
    return 'Sie haben $value % der Zeit im Bett geschlafen.';
  }

  @override
  String asstSleepDebt(String duration) {
    return 'Sie haben $duration weniger geschlafen als nötig; gehen Sie heute etwas früher ins Bett.';
  }

  @override
  String get asstSleepGood =>
      'Ihre Schlafdauer liegt im empfohlenen Bereich von 7–9 Stunden; weiter so.';

  @override
  String asstRecovery(String score, String level) {
    return 'Ihre Erholung heute: $score/100 ($level).';
  }

  @override
  String asstHrv(String value, String baseline) {
    return 'Ihre nächtliche HRV beträgt $value ms; Ihr 14-Tage-Normalwert $baseline ms.';
  }

  @override
  String asstRestingHr(String value, String baseline) {
    return 'Ihr Ruhepuls liegt bei $value Schlägen/min; normal sind $baseline.';
  }

  @override
  String asstHeart(String avg, String min, String max) {
    return 'Heute liegt Ihr Durchschnittspuls bei $avg Schlägen/min; niedrigster $min, höchster $max.';
  }

  @override
  String asstEcg(String date, String result) {
    return 'Ihr letztes EKG ($date): $result.';
  }

  @override
  String get asstEcgNormal => 'regelmäßiger Rhythmus, nichts Auffälliges';

  @override
  String get asstEcgFlagged =>
      'es gibt einen auffälligen Befund; zeigen Sie die Aufnahme am besten Ihrem Arzt';

  @override
  String get asstEcgUnknown =>
      'die Aufnahme reicht für eine Bewertung nicht aus';

  @override
  String get asstEcgNone =>
      'Sie haben noch keine EKG-Aufnahme. Sie können eine über den EKG-Bildschirm im Tab Gesundheit erstellen.';

  @override
  String get asstEcgNote =>
      'Die EKG-Bewertung ist eine automatische Vorabeinschätzung, keine Diagnose.';

  @override
  String asstStrain(String value, String low, String high) {
    return 'Ihre Belastung heute: $value/21; ideal für Ihre Erholung sind $low–$high.';
  }

  @override
  String asstStrainPlain(String value) {
    return 'Ihre Belastung heute: $value/21.';
  }

  @override
  String asstStress(String value) {
    return 'Ihr durchschnittlicher Stress heute: $value/100.';
  }

  @override
  String get asstStressTip =>
      'Einige Minuten langsames Atmen und kurze Spaziergänge über den Tag können Stress senken.';

  @override
  String asstSteps(String steps, String goal) {
    return 'Sie sind heute $steps Schritte gegangen; das Tagesziel ist $goal.';
  }

  @override
  String asstStepsLeft(String left) {
    return 'Noch $left Schritte; ein kurzer Spaziergang reicht.';
  }

  @override
  String get asstStepsDone =>
      'Sie haben Ihr Tagesziel an Schritten erreicht, gut gemacht!';

  @override
  String asstBioAge(String bio, String age) {
    return 'Ihr biologisches Alter ist $bio, Ihr Kalenderalter $age.';
  }

  @override
  String get asstBioYounger =>
      'Ihre Daten zeigen ein jüngeres Bild als Ihre Altersgruppe.';

  @override
  String get asstBioOlder =>
      'Regelmäßiger Schlaf und mehr Bewegung können helfen, diesen Abstand zu verringern.';

  @override
  String asstBioCollecting(String days) {
    return 'Daten für den Bericht zum biologischen Alter werden gesammelt: $days/21 Tage.';
  }

  @override
  String get asstBioNeedsAge =>
      'Geben Sie Ihr Alter im Profil an, um ein biologisches Alter zu erhalten.';

  @override
  String asstWorkouts(String count, String duration) {
    return 'In den letzten 7 Tagen haben Sie $count Trainings gemacht, insgesamt $duration.';
  }

  @override
  String get asstTrainingHigh =>
      'Ihre Erholung ist hoch, heute passt ein intensives Training. Beispiel: 10 Min. Aufwärmen, 4 × 4 Min. zügig laufen oder radeln (Pulszone 3–4) mit 3 Min. locker dazwischen, 10 Min. Auslaufen.';

  @override
  String get asstTrainingMid =>
      'Ihre Erholung ist mittel: Heute passen 30–45 Min. zügiges Gehen, Radfahren oder lockeres Laufen (Pulszone 2).';

  @override
  String get asstTrainingLow =>
      'Ihre Erholung ist niedrig: Gönnen Sie sich heute Ruhe. 20–30 Min. leichtes Gehen oder Dehnen reichen.';

  @override
  String get asstTrainingUnknown =>
      'Ihre Erholung lässt sich noch nicht berechnen; beginnen Sie mit 30 Min. zügigem Gehen und steigern Sie nach Gefühl.';

  @override
  String asstTrainingWeek(String duration) {
    return 'Wochenziel: mindestens 150 Min. moderate Bewegung; in den letzten 7 Tagen waren es $duration.';
  }

  @override
  String get asstTrainingSafety =>
      'Hören Sie sofort auf, wenn Brustschmerzen, Schwindel oder ungewöhnliche Atemnot auftreten.';

  @override
  String asstReportIntro(String date) {
    return 'Ihre Zusammenfassung für $date:';
  }

  @override
  String get asstFailed =>
      'Server nicht erreichbar; diese Antwort wurde auf dem Telefon erstellt.';

  @override
  String get privacyAiTitle => 'Künstliche Intelligenz';

  @override
  String get privacyAiBody =>
      'Der KI-Bericht und der Gesundheitsassistent Vita arbeiten standardmäßig regelbasiert auf Ihrem Telefon; es verlassen keine Daten das Telefon. Wenn Sie in die KI-Nutzung einwilligen, werden für den Bericht Wochenzusammenfassungen und für den Assistenten Ihre Frage, Ihre letzten Nachrichten und die Tageskennzahlen (Schlafdauer, Erholung, Belastung, Durchschnittspuls, Stress, Schritte, Ergebnis der EKG-Vorabeinschätzung, Alter) pseudonymisiert an unser Portal gesendet; das Portal leitet sie zur Beantwortung an den KI-Dienst Claude von Anthropic (USA) weiter. Name, Ausweisnummer, Geräteadresse und Rohmesswerte werden nicht gesendet. Sie können die Einwilligung jederzeit im Bildschirm KI-Bericht widerrufen. Die KI stellt keine Diagnosen und empfiehlt keine Medikamente.';

  @override
  String get homeNightMore => 'Mehr erfahren';

  @override
  String get bedtimeTitle => 'Schlafenszeit-Routine';

  @override
  String get bedtimeWindDown => 'Zeit zum Abschalten';

  @override
  String get bedtimeWindDownBody =>
      'Das Tagwerk ist getan. Dimmen Sie das Licht, legen Sie das Handy weg und lassen Sie Ihren Körper zur Ruhe kommen. Atmen Sie langsam durch die Nase ein und noch langsamer aus. Den Rest übernimmt die Nacht.';

  @override
  String get bedtimeChartTitle => 'Schlafenszeit';

  @override
  String get bedtimeIdeal => 'Ideale Schlafenszeit';

  @override
  String get bedtimeIdealRange => 'Idealer Bereich';

  @override
  String bedtimeRangeValue(String time, int minutes) {
    return '$time ±$minutes Min.';
  }

  @override
  String get bedtimeOnTrack => 'Im Plan';

  @override
  String get bedtimeOff => 'Abweichung';

  @override
  String bedtimeWeekSummary(int count, int total) {
    return 'Nächte im idealen Bereich: $count/$total';
  }

  @override
  String get bedtimeEmpty =>
      'Diese Woche wurden keine Schlafenszeiten erfasst. Tragen Sie das Armband nachts; sobald Ihr Schlaf erfasst ist, erscheint Ihre Schlafenszeit hier.';

  @override
  String bedtimePointSemantics(String day, String time, String status) {
    return '$day: $time, $status';
  }

  @override
  String get bedtimeTipTitle => 'So finden Sie eine feste Schlafenszeit';

  @override
  String get bedtimeTipBody =>
      'Jeden Abend etwa zur gleichen Zeit ins Bett zu gehen, hilft Ihrer inneren Uhr, sich einzupendeln. Nach Nächten im idealen Bereich ist die Erholung meist besser. Hat sich Ihr Rhythmus einige Nächte verschoben, gehen Sie jeden Abend 15-30 Minuten früher ins Bett, um schrittweise zurückzufinden.';
}
