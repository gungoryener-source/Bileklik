// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutDescription =>
      'Bileklik shows the measurements of your JCV8 ECG wristband on your phone.';

  @override
  String get aboutLicenses => 'Open source licenses';

  @override
  String get aboutMedical =>
      'This app is not a medical device; consult your doctor for diagnosis and treatment. Blood pressure values are estimates.';

  @override
  String get aboutPrivacy =>
      'Your measurements stay on this phone. When sharing arrives, you will decide who sees what.';

  @override
  String aboutVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get appTitle => 'Bileklik';

  @override
  String get autoMeasureAllDay => 'All day';

  @override
  String get autoMeasureConnect => 'Connect';

  @override
  String get autoMeasureDays => 'Days';

  @override
  String get autoMeasureEnd => 'End';

  @override
  String get autoMeasureEveryDay => 'Every day';

  @override
  String autoMeasureEveryHours(int hours) {
    return 'Every $hours h';
  }

  @override
  String autoMeasureEveryMinutes(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get autoMeasureHours => 'Hours';

  @override
  String get autoMeasureInterval => 'Interval';

  @override
  String get autoMeasureIntro =>
      'The band measures on its own during the hours you choose. Each measurement takes 1 minute; shorter intervals drain the battery faster.';

  @override
  String get autoMeasureLoadFailed => 'Couldn\'t read the band\'s settings.';

  @override
  String autoMeasureNextDay(String time) {
    return '$time (next day)';
  }

  @override
  String get autoMeasureNoDays => 'Keep at least one day selected.';

  @override
  String get autoMeasureNotConnected =>
      'Connect the band to see and change its settings.';

  @override
  String get autoMeasureOff => 'Off';

  @override
  String get autoMeasureRetry => 'Try again';

  @override
  String get autoMeasureSameTime => 'Start and end can\'t be the same.';

  @override
  String get autoMeasureSaveFailed =>
      'Couldn\'t save the setting to the band. Try again.';

  @override
  String get autoMeasureSleepNote =>
      'While you sleep, the band measures heart rate every 5 minutes.';

  @override
  String get autoMeasureStart => 'Start';

  @override
  String get autoMeasureTitle => 'Automatic measurement';

  @override
  String autoMeasureTurnOn(String name) {
    return 'Automatic $name measurement';
  }

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
  String get clock12 => '12-hour (AM/PM)';

  @override
  String get clock24 => '24-hour';

  @override
  String get clockSystem => 'Follow language';

  @override
  String get clockTitle => 'Time format';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonMessage => 'This section is coming in a future version.';

  @override
  String get communityAccept => 'Join';

  @override
  String get communityAnswered => 'Answered';

  @override
  String get communityCodeCopied => 'Code copied';

  @override
  String get communityCodeInvalid => 'No group found with this code.';

  @override
  String get communityCodeLabel => 'Group code';

  @override
  String communityConsentSince(Object date) {
    return 'Permission given: $date';
  }

  @override
  String get communityCopyCode => 'Copy code';

  @override
  String get communityCreate => 'Create';

  @override
  String get communityCreateGroup => 'Create a new group';

  @override
  String get communityDecline => 'Decline';

  @override
  String get communityDelete => 'Delete group';

  @override
  String communityDeleteConfirm(Object group) {
    return '\"$group\" will be deleted and all sharing in it ends.';
  }

  @override
  String get communityGroupName => 'Group name';

  @override
  String get communityGroupNameHint => 'e.g. My family';

  @override
  String get communityInvite => 'Invite a member';

  @override
  String communityInviteCodeBody(Object name) {
    return 'Share this code with $name. They can join from Health community > Join with a code.';
  }

  @override
  String get communityInviteCodeTitle => 'Invitation code';

  @override
  String get communityInviteName => 'Name of the person to invite';

  @override
  String get communityInviteSend => 'Invite';

  @override
  String get communityJoinWithCode => 'Join with a code';

  @override
  String get communityJoinedEmpty =>
      'You can join with an invitation or a group code.';

  @override
  String get communityJoinedGroups => 'Groups I\'ve joined';

  @override
  String communityJoinedMessage(Object group) {
    return 'You joined \"$group\".';
  }

  @override
  String get communityLeave => 'Leave group';

  @override
  String communityLeaveConfirm(Object group) {
    return 'When you leave \"$group\", its members can no longer see the data you share.';
  }

  @override
  String communityMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get communityMembers => 'Members';

  @override
  String get communityMessages => 'Messages';

  @override
  String get communityMessagesEmpty => 'No messages yet.';

  @override
  String communityMsgInvite(Object name, Object group) {
    return '$name invited you to the group \"$group\".';
  }

  @override
  String communityMsgJoined(Object name, Object group) {
    return '$name joined \"$group\".';
  }

  @override
  String get communityMyGroups => 'My groups';

  @override
  String get communityMyGroupsEmpty =>
      'You don\'t have a group yet. Create one and invite your family.';

  @override
  String get communityMyShareNote =>
      'Only members of this group can see it. Nothing is shared until you turn it on.';

  @override
  String get communityMyShareTitle => 'What you share with this group';

  @override
  String get communityOwner => 'Owner';

  @override
  String communityOwnerName(Object name) {
    return 'Owner: $name';
  }

  @override
  String get communityPending => 'Invitation pending';

  @override
  String get communityPrivacyNote =>
      'Your health data is shared only with the groups you choose, and only the types you choose. You can withdraw permission at any time.';

  @override
  String get communityRemoveMember => 'Remove from group';

  @override
  String communityShares(Object types) {
    return 'Shares: $types';
  }

  @override
  String get communitySharesNothing => 'Not sharing anything yet';

  @override
  String get communityYou => 'You';

  @override
  String get connActive => 'My connections';

  @override
  String connAgree(Object name) {
    return 'I have read this information and explicitly consent to sharing the data I selected with $name for the purpose above.';
  }

  @override
  String get connCodeInvalid => 'This code is invalid or has expired.';

  @override
  String get connConfirm => 'Agree and connect';

  @override
  String connConnected(Object name) {
    return 'Connected with $name.';
  }

  @override
  String get connConsentTitle => 'Explicit consent';

  @override
  String get connDisconnect => 'Remove connection';

  @override
  String connDisconnectConfirm(Object name) {
    return '$name will no longer see your new data. You can ask them to delete data that was already shared.';
  }

  @override
  String get connDuration => 'Duration';

  @override
  String connDurationText(Object date, Object days) {
    return 'Until $date ($days days). Sharing stops by itself when this ends, and you can remove it earlier.';
  }

  @override
  String get connEmpty => 'You have no connections yet.';

  @override
  String get connEnterCode => 'Enter invitation code';

  @override
  String get connIntro =>
      'Your doctor or a study you take part in gives you an invitation code. When you enter it, you see who is asking, for which data and for how long, and you decide.';

  @override
  String get connKindClinician => 'Doctor';

  @override
  String get connKindResearch => 'Research institution';

  @override
  String get connPurpose => 'Purpose';

  @override
  String get connRequested => 'Requested data';

  @override
  String get connRequestedNote =>
      'Choose what you want to share. Anything you don\'t choose stays private.';

  @override
  String get connRights =>
      'Your data is processed under data protection law (KVKK). You have the right to access your data and to ask for it to be corrected or deleted.';

  @override
  String get connScan => 'Scan QR code';

  @override
  String get connScanSoon =>
      'Camera scanning is coming soon. For now, enter the code printed under the QR code.';

  @override
  String get connSelectAll => 'Select all';

  @override
  String get connShared => 'Shared data';

  @override
  String connSharedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count data types',
      one: '1 data type',
    );
    return '$_temp0';
  }

  @override
  String connSince(Object date) {
    return 'Since $date';
  }

  @override
  String connUntil(Object date) {
    return 'Until $date';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get deviceAddress => 'Address';

  @override
  String get deviceBattery => 'Battery';

  @override
  String deviceBatteryValue(Object value) {
    return '$value%';
  }

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceDisconnect => 'Disconnect';

  @override
  String get deviceDisconnected => 'Not connected';

  @override
  String get deviceLastSync => 'Last sync';

  @override
  String get devicePairNew => 'Pair another wristband';

  @override
  String get deviceSectionSettings => 'Band settings';

  @override
  String get deviceStatus => 'Status';

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
  String ecgAverageBpm(Object bpm) {
    return '$bpm bpm average';
  }

  @override
  String get ecgAverageHeartRate => 'Average heart rate';

  @override
  String get ecgBeats => 'Beats';

  @override
  String get ecgBpm => 'bpm';

  @override
  String get ecgCancel => 'Cancel reading';

  @override
  String get ecgConnectFirst => 'Connect your wristband on the Home tab first.';

  @override
  String ecgDetailTitle(Object date, Object time) {
    return 'ECG · $date $time';
  }

  @override
  String get ecgDisclaimer =>
      'This reading does not replace a medical diagnosis. If you have chest pain, shortness of breath or feel faint, call your local emergency number right away.';

  @override
  String get ecgHowToSteps =>
      '1. Wear the wristband snugly on your wrist.\n2. Sit down and rest your arm on a table.\n3. Lightly touch the electrode on top of the wristband with a finger of your other hand.\n4. Stay still and don\'t talk for 30 seconds.';

  @override
  String get ecgHowToTitle => 'How to measure';

  @override
  String get ecgKeepStill =>
      'Keep your finger on the electrode and stay still.';

  @override
  String get ecgMeasuringTitle => 'Recording ECG';

  @override
  String get ecgMs => 'ms';

  @override
  String get ecgNoHeartRate => 'Couldn\'t calculate heart rate';

  @override
  String get ecgNoRecords => 'No ECG recordings yet.';

  @override
  String get ecgRange => 'Range';

  @override
  String ecgRangeValue(Object min, Object max) {
    return '$min-$max';
  }

  @override
  String ecgRecordHeader(Object seconds, Object perRow) {
    return 'Recording ($seconds s, $perRow s per row)';
  }

  @override
  String ecgRecordSubtitle(Object when, Object seconds) {
    return '$when · $seconds s';
  }

  @override
  String get ecgRecordsTitle => 'Recordings';

  @override
  String get ecgSdnn => 'Variability (SDNN)';

  @override
  String ecgSecondsLeft(Object seconds) {
    return '$seconds s';
  }

  @override
  String get ecgStartButton => 'Start 30-second reading';

  @override
  String get ecgTitle => 'ECG';

  @override
  String get exerciseConnectFirst =>
      'Connect your wristband on the Home tab first.';

  @override
  String get exerciseConnectHint =>
      'Connect your wristband to see past workouts.';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String get exerciseEmpty => 'No workouts yet.';

  @override
  String exerciseInProgress(Object sport) {
    return '$sport in progress';
  }

  @override
  String get exerciseLast30Days => 'Last 30 days';

  @override
  String exercisePausedAt(Object time) {
    return 'Paused · $time';
  }

  @override
  String get exerciseStart => 'Start a workout';

  @override
  String get exerciseThisWeek => 'This week';

  @override
  String get healthBloodPressure => 'Blood pressure';

  @override
  String healthBloodPressureSubtitle(Object details) {
    return 'Estimated · $details';
  }

  @override
  String get healthConnectHint =>
      'Connect your wristband on the Home tab to see your data.';

  @override
  String get healthEcg => 'ECG';

  @override
  String healthEcgLast(Object time) {
    return 'Last reading · $time';
  }

  @override
  String get healthEcgPrompt => 'Take a 30-second reading';

  @override
  String healthLastSync(Object time) {
    return 'Last updated $time';
  }

  @override
  String get healthNoMeasurement => 'No readings';

  @override
  String get healthNoRecord => 'No data';

  @override
  String get healthSleep => 'Sleep';

  @override
  String healthSleepLastNight(Object start, Object end) {
    return 'Last night · $start - $end';
  }

  @override
  String healthStepsToday(Object goal) {
    return 'Today · goal $goal';
  }

  @override
  String get healthSyncTooltip => 'Update from wristband';

  @override
  String get healthSyncing => 'Getting data from your wristband…';

  @override
  String homeActiveGoal(Object minutes) {
    return 'Goal $minutes min';
  }

  @override
  String get homeActiveTime => 'Active time';

  @override
  String get homeAverageStress => 'Average stress';

  @override
  String homeAverageStressBand(Object band) {
    return 'Average stress · $band';
  }

  @override
  String homeAverageValue(Object value) {
    return 'Avg. $value';
  }

  @override
  String get homeBalance => 'Balance';

  @override
  String get homeBloodOxygen => 'Blood oxygen';

  @override
  String homeBpm(Object value) {
    return '$value bpm';
  }

  @override
  String get homeCalories => 'Calories';

  @override
  String homeChartNoData(Object title) {
    return '$title: no measurements';
  }

  @override
  String homeChartSemantics(Object title, Object min, Object max, Object unit) {
    return '$title: lowest $min, highest $max $unit';
  }

  @override
  String get homeConnectTooltip => 'Connect to wristband';

  @override
  String get homeConnected => 'Connected';

  @override
  String homeConnectedBattery(Object percent) {
    return 'Connected · $percent%';
  }

  @override
  String get homeConnecting => 'Connecting…';

  @override
  String get homeDaySummary => 'Day summary';

  @override
  String homeDeepSleep(Object duration) {
    return 'Deep sleep $duration';
  }

  @override
  String get homeDisconnectTooltip => 'Disconnect';

  @override
  String get homeEcg => 'ECG';

  @override
  String homeEcgSubtitle(Object bpm, Object seconds) {
    return '$bpm bpm · $seconds s';
  }

  @override
  String homeEcgSubtitleNoHr(Object seconds) {
    return '$seconds s';
  }

  @override
  String get homeGoodAfternoon => 'Good afternoon';

  @override
  String get homeGoodEvening => 'Good evening';

  @override
  String get homeGoodMorning => 'Good morning';

  @override
  String get homeHeartRateHint =>
      'Wear the wristband all day to see your heart rate.';

  @override
  String get homeHeartRateLabel => 'Heart rate';

  @override
  String get homeHeroEmpty => 'Connect your wristband to see your heart rate.';

  @override
  String homeHeroSemantics(Object value) {
    return 'Heart rate $value bpm';
  }

  @override
  String get homeHourlyStressSemantics => 'Hourly stress bars';

  @override
  String get homeHrvLabel => 'Heart rate variability';

  @override
  String get homeKcal => 'kcal';

  @override
  String homeKm(Object value) {
    return '$value km';
  }

  @override
  String homeLastMeasured(Object time) {
    return 'Last reading $time';
  }

  @override
  String get homeListSeparator => ', ';

  @override
  String get homeLive => 'Live';

  @override
  String get homeMeasureNow => 'Measure now';

  @override
  String homeMs(Object value) {
    return '$value ms';
  }

  @override
  String get homeNextDay => 'Next day';

  @override
  String get homeNoRecord => 'No record';

  @override
  String get homeNoSleepLastNight => 'No sleep recorded last night';

  @override
  String get homeNoSleepPastHint =>
      'Summaries appear here for days you wore the wristband.';

  @override
  String get homeNoSleepStages => 'No sleep stages';

  @override
  String get homeNoSleepThisDay => 'No sleep record for this day';

  @override
  String get homeNoSleepTonightHint =>
      'Wear the wristband tonight, and your sleep and recovery summary will be here in the morning.';

  @override
  String get homeNotConnected => 'Not connected';

  @override
  String homePercent(Object value) {
    return '$value%';
  }

  @override
  String get homePickDay => 'Select a day';

  @override
  String get homePrevDay => 'Previous day';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeQuickHeartRate => 'Measure HR';

  @override
  String get homeQuickSync => 'Sync';

  @override
  String homeRange(Object min, Object max) {
    return '$min–$max';
  }

  @override
  String get homeRecovery => 'Recovery';

  @override
  String homeRestingHr(Object value) {
    return 'Resting $value bpm';
  }

  @override
  String get homeSleep => 'Sleep';

  @override
  String homeSleepStageItem(Object stage, Object duration) {
    return '$stage $duration';
  }

  @override
  String homeSleepStagesSemantics(Object stages) {
    return 'Sleep stages: $stages';
  }

  @override
  String homeSleptHrvBandSummary(Object duration, Object hrv, Object band) {
    return 'You slept $duration, and your overnight HRV averaged $hrv ms ($band).';
  }

  @override
  String homeSleptHrvSummary(Object duration, Object hrv) {
    return 'You slept $duration, and your overnight HRV averaged $hrv ms.';
  }

  @override
  String homeSleptSummary(Object duration) {
    return 'You slept $duration.';
  }

  @override
  String get homeSpo2Hint =>
      'Wear the wristband all day to see your blood oxygen.';

  @override
  String get homeStartWorkout => 'Start workout';

  @override
  String homeStepGoal(Object goal) {
    return 'Goal: $goal steps';
  }

  @override
  String homeStepGoalProgress(Object percent, Object goal) {
    return '$percent% · goal $goal';
  }

  @override
  String homeStepGoalSemantics(Object steps, Object goal, Object percent) {
    return 'Step goal: $steps of $goal, $percent percent';
  }

  @override
  String get homeSteps => 'Steps';

  @override
  String get homeStressHint =>
      'Stress and HRV are measured during the day while you wear the wristband.';

  @override
  String get homeStressLevel => 'Stress level';

  @override
  String get homeStressLoad => 'Stress load';

  @override
  String get homeSyncing => 'Syncing…';

  @override
  String get homeTimeline => 'Timeline';

  @override
  String get homeTimelineEmpty =>
      'Your workouts, ECGs and sleep appear here in time order.';

  @override
  String get homeTimelineSubtitle => 'Today\'s records';

  @override
  String get homeToday => 'Today';

  @override
  String homeWeekdayDate(Object weekday, Object date) {
    return '$weekday, $date';
  }

  @override
  String get homeWokeUp => 'You woke up';

  @override
  String homeWokeUpSubtitle(Object duration, Object time) {
    return '$duration asleep · in bed at $time';
  }

  @override
  String homeWorkoutSubtitle(Object duration, Object kcal) {
    return '$duration · $kcal kcal';
  }

  @override
  String get homeYesterday => 'Yesterday';

  @override
  String get hpActivity => 'Steps, distance and calories';

  @override
  String get hpAuto =>
      'New data is sent automatically after each wristband sync.';

  @override
  String get hpChooseTypes => 'Data to send';

  @override
  String hpConnect(Object platform) {
    return 'Connect to $platform';
  }

  @override
  String get hpConnected => 'Connected';

  @override
  String hpDenied(Object platform) {
    return 'Permission was not granted. You can allow it in $platform settings.';
  }

  @override
  String get hpDisconnect => 'Stop sending';

  @override
  String hpDisconnectNote(Object platform) {
    return 'Data already written stays in $platform; use $platform settings to delete it.';
  }

  @override
  String get hpExportNow => 'Send now';

  @override
  String hpExported(Object records) {
    return '$records sent';
  }

  @override
  String get hpHrv => 'Heart rate variability (HRV)';

  @override
  String hpIntro(Object platform) {
    return 'Your wristband data is written to $platform, where other health apps on your phone can see it. You choose which types are sent.';
  }

  @override
  String hpLastExport(Object time, Object records) {
    return 'Last sent: $time · $records';
  }

  @override
  String get hpNever => 'Not sent yet';

  @override
  String get hpNotExported =>
      'Blood pressure is an estimate, so it is not sent. Health platforms don\'t accept ECG recordings from other apps.';

  @override
  String get hpNothingNew => 'No new records to send';

  @override
  String hpPermissionNote(Object platform) {
    return 'When you continue, $platform opens its permission screen, where you can also choose one by one.';
  }

  @override
  String hpRecords(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
      zero: 'no records',
    );
    return '$_temp0';
  }

  @override
  String get hpTitle => 'Health app';

  @override
  String hpUnavailable(Object platform) {
    return '$platform is not available on this phone. You can install it from Google Play.';
  }

  @override
  String get hpWorkouts => 'Workouts';

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
  String get issueNoSpotSignal =>
      'Couldn\'t get a reading. Tighten the band a little and try again.';

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
  String get liveCancel => 'Cancel';

  @override
  String get liveConfirmBody =>
      'Your workout will be saved and a summary shown.';

  @override
  String get liveConfirmTitle => 'End workout';

  @override
  String get liveContinue => 'Resume';

  @override
  String get liveFinish => 'End';

  @override
  String liveInactiveBody(int minutes, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other:
          'You took fewer than $steps steps in the last $minutes minutes. End the workout?',
      one:
          'You took fewer than $steps steps in the last minute. End the workout?',
    );
    return '$_temp0';
  }

  @override
  String get liveInactiveTitle => 'Looks like you\'ve stopped moving';

  @override
  String get livePause => 'Pause';

  @override
  String get livePaused => 'Paused';

  @override
  String get measureEcg => 'ECG';

  @override
  String get measureEcgHint => 'With your finger on the electrode';

  @override
  String get measureHeartRate => 'Heart rate';

  @override
  String get measureSheetTitle => 'What would you like to measure?';

  @override
  String get measureSpo2 => 'Blood oxygen (SpO2)';

  @override
  String measureTakes(Object seconds) {
    return 'Takes about $seconds seconds';
  }

  @override
  String get metricCalories => 'Calories';

  @override
  String metricDetailAbove(Object value) {
    return '> $value';
  }

  @override
  String get metricDetailBands => 'Ranges';

  @override
  String get metricDetailBpEstimate =>
      'Blood pressure from the wristband is an estimate. Use an approved blood pressure monitor for diagnosis and treatment.';

  @override
  String get metricDetailDailyAverage => 'Daily average';

  @override
  String get metricDetailNext => 'Next';

  @override
  String get metricDetailNoData => 'No data for this period';

  @override
  String get metricDetailPrevious => 'Previous';

  @override
  String get metricDetailTotal => 'Total';

  @override
  String metricDetailWeekRange(Object start, Object end) {
    return '$start – $end';
  }

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
  String get navSemantics => 'Main menu';

  @override
  String get noValue => '--';

  @override
  String get pairCode => 'Pair with address';

  @override
  String get pairCodeHint =>
      'Enter the address printed under the QR code on the box or on the back of the wristband.';

  @override
  String get pairCodeInvalid =>
      'The address has 12 characters, e.g. A1:B2:C3:D4:E5:F6';

  @override
  String get pairCodeLabel => 'Device address';

  @override
  String get pairCodeNotFound => 'No wristband found at this address.';

  @override
  String get pairConnect => 'Connect';

  @override
  String get pairConnected => 'Wristband connected.';

  @override
  String get pairFound => 'Wristbands found';

  @override
  String get pairNoneFound =>
      'No wristband found. Make sure it is charged and nearby, then try again.';

  @override
  String get pairNote =>
      'Charge the wristband and keep it near your phone. Bluetooth must be on.';

  @override
  String get pairScan => 'Start search';

  @override
  String get pairScanning => 'Searching…';

  @override
  String pairSignal(Object rssi) {
    return 'Signal $rssi';
  }

  @override
  String get pairSubtitle =>
      'Connect your wristband to bring your measurements to your phone.';

  @override
  String get pairTitle => 'Pair your wristband';

  @override
  String get periodDay => 'Day';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodWeek => 'Week';

  @override
  String get personalInfoTitle => 'Personal info';

  @override
  String get profileAge => 'Age';

  @override
  String get profileConnectFirst =>
      'Connect your wristband to save your details.';

  @override
  String profileDevice(Object mac) {
    return 'Device: $mac';
  }

  @override
  String get profileFemale => 'Female';

  @override
  String get profileHeight => 'Height';

  @override
  String get profileMale => 'Male';

  @override
  String get profileMenuAbout => 'About';

  @override
  String get profileMenuCommunity => 'Health community';

  @override
  String get profileMenuCommunitySubtitle =>
      'Family groups and sharing permissions';

  @override
  String get profileMenuDevice => 'Device';

  @override
  String profileMenuDeviceConnected(Object battery) {
    return 'Connected · battery $battery%';
  }

  @override
  String get profileMenuDeviceNone => 'No wristband connected';

  @override
  String get profileMenuFeedback => 'Feedback';

  @override
  String get profileMenuGeneral => 'General settings';

  @override
  String get profileMenuGeneralSubtitle => 'Language, time format, units';

  @override
  String get profileMenuPersonalEmpty => 'Enter your age, height and weight';

  @override
  String profileMenuPersonalSummary(Object age, Object height, Object weight) {
    return '$age yrs · $height cm · $weight kg';
  }

  @override
  String get profileMenuResearch => 'Doctors and research';

  @override
  String get profileMenuResearchSubtitle =>
      'Share data with an invitation code';

  @override
  String get profileMenuThirdParty => 'Health Connect and Apple Health';

  @override
  String get profileMenuThirdPartySubtitle =>
      'Send data to your phone\'s health app';

  @override
  String get profileMenuVersion => 'App version';

  @override
  String profileRangeError(Object min, Object max) {
    return 'Must be between $min and $max';
  }

  @override
  String get profileSave => 'Save';

  @override
  String get profileSaved => 'Details saved to your wristband';

  @override
  String get profileSectionApp => 'App';

  @override
  String get profileSectionSettings => 'Settings';

  @override
  String get profileSectionSharing => 'Sharing and connections';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileUnitCm => 'cm';

  @override
  String get profileUnitKg => 'kg';

  @override
  String get profileUnitYears => 'yrs';

  @override
  String get profileWeight => 'Weight';

  @override
  String get shareActivity => 'Activity and steps';

  @override
  String get shareBloodPressure => 'Blood pressure (estimated)';

  @override
  String get shareEcg => 'ECG recordings';

  @override
  String get shareHeartRate => 'Heart rate';

  @override
  String get shareSleep => 'Sleep';

  @override
  String get shareSpo2 => 'Blood oxygen (SpO2)';

  @override
  String get shareStress => 'Stress and HRV';

  @override
  String get shareTemperature => 'Body temperature';

  @override
  String get sleepAwake => 'Awake';

  @override
  String get sleepDeep => 'Deep';

  @override
  String get sleepDuration => 'Time asleep';

  @override
  String get sleepEmpty => 'No sleep data yet';

  @override
  String get sleepLast7Nights => 'Last 7 nights';

  @override
  String get sleepLight => 'Light';

  @override
  String get sleepNextNight => 'Next night';

  @override
  String sleepPercent(Object value) {
    return '$value%';
  }

  @override
  String get sleepPreviousNight => 'Previous night';

  @override
  String get sleepRem => 'REM';

  @override
  String sleepTimeRange(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get sleepTitle => 'Sleep';

  @override
  String sleepWeekBarHint(Object day, Object duration) {
    return '$day: $duration';
  }

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
  String get spotAgain => 'Measure again';

  @override
  String get spotDone => 'Done';

  @override
  String get spotKeepStill =>
      'Wear the band snugly, rest your arm and stay still.';

  @override
  String get spotLowSpo2 =>
      'This value is low. Rest and measure again; if it stays low, talk to your doctor.';

  @override
  String get spotMeasuring => 'Measuring…';

  @override
  String get spotMoving => 'Movement detected. Keep your arm still.';

  @override
  String get spotNote => 'Wristband readings do not replace a medical device.';

  @override
  String get spotOffWrist =>
      'The band doesn\'t seem to be on your wrist. Put it on snugly.';

  @override
  String spotSaved(Object time) {
    return 'Saved, measured at $time';
  }

  @override
  String get statAverage => 'Average';

  @override
  String get statAvgHeartRate => 'Avg heart rate';

  @override
  String get statDuration => 'Duration';

  @override
  String get statMax => 'Highest';

  @override
  String get statMin => 'Lowest';

  @override
  String get statPace => 'Pace';

  @override
  String statPercent(Object value) {
    return '$value%';
  }

  @override
  String get unitPerMinute => '/min';

  @override
  String get unitSteps => 'steps';

  @override
  String get unitsImperial => 'US (mi, °F)';

  @override
  String get unitsMetric => 'Metric (km, °C)';

  @override
  String get unitsTitle => 'Units';

  @override
  String get wearDetectionFailed =>
      'Couldn\'t change wear detection on the band.';

  @override
  String get wearDetectionSubtitle =>
      'Warns you during a measurement if the band is off your wrist or your arm moves.';

  @override
  String get wearDetectionTitle => 'Wear detection';

  @override
  String get workoutCongrats => 'Nice work! Workout saved';

  @override
  String workoutTimeRange(Object day, Object start, Object end) {
    return '$day · $start – $end';
  }
}
