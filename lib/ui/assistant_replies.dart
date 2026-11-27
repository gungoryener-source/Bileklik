import '../data/assistant.dart';
import '../data/ecg_analysis.dart';
import '../data/progress.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';
import 'screens/recovery_screen.dart';

/// Telefonda, kurallarla hazırlanan asistan yanıtı. Sorudaki konulara göre
/// kullanıcının verisinden cümleler kurar; teşhis koymaz, acil belirtide
/// önce 112'ye yönlendirir.
String offlineReply(String question, AssistantFacts f, AppLocalizations l) {
  final topics = AssistantIntents.of(question);
  if (topics.contains(AssistantTopic.emergency)) return l.asstEmergency;

  final parts = <String>[];
  if (topics.contains(AssistantTopic.medication)) parts.add(l.asstNoDiagnosis);

  final data = topics.where(
    (t) => !const {
      AssistantTopic.medication,
      AssistantTopic.greeting,
      AssistantTopic.thanks,
    }.contains(t),
  );
  // "Antrenman" sözcüğü egzersiz geçmişini de kapsar; ikisi birlikte
  // gelirse yalnızca program.
  final chosen = data.toList();
  if (chosen.contains(AssistantTopic.training)) {
    chosen.remove(AssistantTopic.workouts);
  }
  for (final t in chosen.take(3)) {
    parts.add(_topic(t, f, l));
  }

  if (parts.isEmpty) {
    if (topics.contains(AssistantTopic.thanks)) return l.asstThanks;
    if (topics.contains(AssistantTopic.greeting)) return l.asstGreeting;
    return l.asstUnknown;
  }
  return parts.join('\n\n');
}

String _topic(AssistantTopic t, AssistantFacts f, AppLocalizations l) =>
    switch (t) {
      AssistantTopic.report => _report(f, l),
      AssistantTopic.training => _training(f, l),
      AssistantTopic.sleep => _join([_sleep(f, l)], l),
      AssistantTopic.heart => _join([_heart(f, l), _ecg(f, l)], l),
      AssistantTopic.recovery => _join([_recovery(f, l)], l),
      AssistantTopic.strain => _join([_strain(f, l)], l),
      AssistantTopic.stress => _join([_stress(f, l, tip: true)], l),
      AssistantTopic.ecg => _ecg(f, l, note: true) ?? l.asstEcgNone,
      AssistantTopic.bioAge => _bioAge(f, l),
      AssistantTopic.steps => _join([_steps(f, l, tip: true)], l),
      AssistantTopic.workouts => _join([_workouts(f, l)], l),
      _ => l.asstUnknown,
    };

/// Boş olmayan parçalar; hiçbiri yoksa "veri yok".
String _join(List<String?> parts, AppLocalizations l) {
  final p = parts.whereType<String>().toList();
  return p.isEmpty ? l.asstNoData : p.join(' ');
}

String? _sleep(AssistantFacts f, AppLocalizations l) {
  final m = f.sleepMinutes;
  if (m == null || f.sleepStart == null || f.sleepEnd == null) return null;
  return [
    l.asstSleep(hhmm(f.sleepStart!), hhmm(f.sleepEnd!), duration(m)),
    if (f.sleepScore case final s?) l.asstSleepScore('$s'),
    if (f.sleepEfficiency case final e?) l.asstSleepEfficiency('$e'),
    if ((f.sleepDebtMinutes ?? 0) >= 30)
      l.asstSleepDebt(duration(f.sleepDebtMinutes!))
    else if (m >= 7 * 60 && m <= 9 * 60)
      l.asstSleepGood,
  ].join(' ');
}

String? _recovery(AssistantFacts f, AppLocalizations l) {
  final r = f.recovery;
  if (r == null) return null;
  return [
    l.asstRecovery('$r', f.recoveryLevel!.label.toLowerCase()),
    if (f.hrv != null && f.hrvBaseline != null)
      l.asstHrv('${f.hrv}', '${f.hrvBaseline}'),
    if (f.restingHeartRate != null && f.restingBaseline != null)
      l.asstRestingHr('${f.restingHeartRate}', '${f.restingBaseline}'),
  ].join(' ');
}

String? _heart(AssistantFacts f, AppLocalizations l) {
  if (f.averageHeartRate == null) return null;
  return [
    l.asstHeart(
      '${f.averageHeartRate}',
      '${f.minHeartRate}',
      '${f.maxHeartRate}',
    ),
    if (f.restingHeartRate != null && f.restingBaseline != null)
      l.asstRestingHr('${f.restingHeartRate}', '${f.restingBaseline}'),
  ].join(' ');
}

String? _ecg(AssistantFacts f, AppLocalizations l, {bool note = false}) {
  final t = f.ecgTime;
  if (t == null) return null;
  final result = switch (f.ecgState) {
    FindingState.ok => l.asstEcgNormal,
    FindingState.flagged => l.asstEcgFlagged,
    _ => l.asstEcgUnknown,
  };
  return [
    l.asstEcg(dayMonth(t), result),
    if (note || f.ecgState == FindingState.flagged) l.asstEcgNote,
  ].join(' ');
}

String? _strain(AssistantFacts f, AppLocalizations l) {
  final s = f.strain;
  if (s == null) return null;
  return switch (f.strainOptimal) {
    (final lo, final hi) => l.asstStrain(oneDecimal(s), _short(lo), _short(hi)),
    null => l.asstStrainPlain(oneDecimal(s)),
  };
}

String _short(double v) =>
    v == v.roundToDouble() ? v.round().toString() : oneDecimal(v);

String? _stress(AssistantFacts f, AppLocalizations l, {bool tip = false}) {
  final s = f.stress;
  if (s == null) return null;
  return [l.asstStress('$s'), if (tip || s >= 60) l.asstStressTip].join(' ');
}

String? _steps(AssistantFacts f, AppLocalizations l, {bool tip = false}) {
  if (f.steps == 0) return null;
  final left = dailyStepGoal - f.steps;
  return [
    l.asstSteps('${f.steps}', '$dailyStepGoal'),
    if (left <= 0) l.asstStepsDone else if (tip) l.asstStepsLeft('$left'),
  ].join(' ');
}

String? _workouts(AssistantFacts f, AppLocalizations l) => f.workouts7 == 0
    ? null
    : l.asstWorkouts('${f.workouts7}', duration(f.workoutMinutes7));

String _bioAge(AssistantFacts f, AppLocalizations l) {
  final age = f.age;
  if (age == null) return l.asstBioNeedsAge;
  final bio = f.biologicalAge;
  if (bio == null) return l.asstBioCollecting('${f.bioAgeDays}');
  return [
    l.asstBioAge('$bio', '$age'),
    if (bio < age) l.asstBioYounger else if (bio > age) l.asstBioOlder,
  ].join(' ');
}

String _training(AssistantFacts f, AppLocalizations l) {
  final r = f.recovery;
  return [
    r == null
        ? l.asstTrainingUnknown
        : r >= 67
        ? l.asstTrainingHigh
        : r >= 34
        ? l.asstTrainingMid
        : l.asstTrainingLow,
    l.asstTrainingWeek(duration(f.workoutMinutes7)),
    l.asstTrainingSafety,
  ].join('\n\n');
}

String _report(AssistantFacts f, AppLocalizations l) {
  final lines = [
    _sleep(f, l),
    _recovery(f, l),
    _strain(f, l),
    _heart(f, l),
    _stress(f, l),
    _steps(f, l, tip: true),
    _ecg(f, l),
  ].whereType<String>().toList();
  if (lines.isEmpty) return l.asstNoData;
  return [
    l.asstReportIntro(longDate(f.day)),
    for (final x in lines) '• $x',
  ].join('\n');
}
