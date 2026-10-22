import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../data/community.dart';
import '../data/models.dart';
import '../data/aggregate.dart';
import '../device/protocol/exercise.dart';
import '../device/protocol/history.dart';
import '../l10n/l10n.dart';
import '../state/app_settings.dart';
import '../state/device_controller.dart';
import 'theme.dart';

/// Tarih biçimleri etkin dile göre; rakamlar her dilde Batı rakamı
/// (sağlık değerleriyle aynı görünsün).
DateFormat _fmt(String pattern) {
  if (!_dateReady) {
    initializeDateFormatting();
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    _dateReady = true;
  }
  return DateFormat(pattern, currentL10n.localeName);
}

bool _dateReady = false;

/// Kısa gün adı; 1 = Pazartesi.
String weekdayShort(int weekday) => _fmt('E').format(_monday(weekday));

/// Uzun gün adı; 1 = Pazartesi.
String weekdayLong(int weekday) => _fmt('EEEE').format(_monday(weekday));

// 2024-01-01 bir pazartesi.
DateTime _monday(int weekday) => DateTime(2024, 1, weekday);

/// Sayı ve birimi soldan sağa yalıtır; Arapça satırda "3.81 km" parçalanmaz.
String ltr(String s) => '\u2066$s\u2069';

/// Karşı tarafın yazdığı metni (kurum adı, amaç) kendi yönünde yalıtır;
/// Arapça ekranda Türkçe bir cümlenin noktası başa kaçmaz.
String isolate(String s) => '\u2068$s\u2069';

String two(int v) => v.toString().padLeft(2, '0');

/// Saat ve birim tercihleri; BuildContext olmayan biçimlendiriciler okur.
/// [DisplaySync] her tercih değişiminde günceller; testlerde 24 saat ve
/// metrik başlar.
abstract final class DisplayPrefs {
  /// null: dilin alışkanlığı (Türkçe ve Almanca 24 saat, İngilizce 12 saat).
  static bool? use24h;
  static bool imperial = false;
}

/// Saat:dakika; 12 saat seçiliyse "9:05 ÖS" gibi, dile göre.
String hhmm(DateTime t) {
  final h24 = DisplayPrefs.use24h;
  if (h24 == true) return '${two(t.hour)}:${two(t.minute)}';
  if (h24 == false) return _fmt('h:mm a').format(t);
  return _fmt(DateFormat.HOUR_MINUTE).format(t);
}

/// Gece yarısından itibaren dakikayı saat olarak yazar (ayarlarda).
String minuteOfDay(int minutes) =>
    hhmm(DateTime(2024, 1, 1, minutes ~/ 60, minutes % 60));

/// 1 km = 0.621371 mil.
const kmPerMile = 1.609344;

/// 1 kg = 2.20462 libre.
const lbPerKg = 2.2046226218;

/// Mesafe değerini seçili birimde yazar (birim ayrı: [MetricLook.unit]).
String distanceValue(double km) => MetricType.distance.format(km);

/// Seçili birimde 1 km ya da 1 mil için tempo.
Duration? paceFor(int seconds, double km) {
  final d = DisplayPrefs.imperial ? km / kmPerMile : km;
  if (d < 0.01) return null;
  return Duration(seconds: (seconds / d).round());
}

// Kalıp yerine iskelet: her dil kendi sırasını ve noktalamasını kullanır
// (19 Ekim, October 19, 19. Oktober).
String dayMonth(DateTime t) => _fmt(DateFormat.MONTH_DAY).format(t);
String monthYear(DateTime t) => _fmt(DateFormat.YEAR_MONTH).format(t);
String monthShort(DateTime t) => _fmt(DateFormat.ABBR_MONTH).format(t);
String longDate(DateTime t) => _fmt(DateFormat.YEAR_MONTH_DAY).format(t);

/// "1 sa 25 dk" biçiminde süre.
String duration(int minutes) {
  final l = currentL10n;
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return l.durationMinutes(m);
  return m == 0 ? l.durationHours(h) : l.durationHoursMinutes(h, m);
}

/// Ölçümün en yakın zamanı: bugünse saat, değilse gün ve saat.
String whenText(DateTime t, DateTime now) {
  final sameDay =
      t.year == now.year && t.month == now.month && t.day == now.day;
  return sameDay ? hhmm(t) : '${dayMonth(t)} ${hhmm(t)}';
}

/// Her metriğin ekrandaki rengi ve simgesi.
extension MetricLook on MetricType {
  /// Ekrandaki ad, etkin dilde.
  String get label {
    final l = currentL10n;
    return switch (this) {
      MetricType.steps => l.metricSteps,
      MetricType.calories => l.metricCalories,
      MetricType.distance => l.metricDistance,
      MetricType.heartRate => l.metricHeartRate,
      MetricType.spo2 => l.metricSpo2,
      MetricType.hrv => l.metricHrv,
      MetricType.stress => l.metricStress,
      MetricType.temperature => l.metricTemperature,
      MetricType.respiratoryRate => l.metricRespiratoryRate,
      MetricType.systolic => l.metricSystolic,
      MetricType.diastolic => l.metricDiastolic,
      MetricType.weight => l.metricWeight,
      MetricType.bodyFat => l.metricBodyFat,
      MetricType.muscleMass => l.metricMuscleMass,
      MetricType.bmi => l.metricBmi,
    };
  }

  /// Ekrandaki birim; yalnızca dile bağlı olanlar çevrilir.
  String get unit => switch (this) {
    MetricType.steps => currentL10n.unitSteps,
    MetricType.respiratoryRate => currentL10n.unitPerMinute,
    // Soldan sağa işareti: Arapçada "°C" ters dönüp "C°" görünmesin.
    MetricType.temperature =>
      DisplayPrefs.imperial ? '\u200E°F' : '\u200E$symbol',
    MetricType.distance => DisplayPrefs.imperial ? 'mi' : symbol,
    MetricType.weight ||
    MetricType.muscleMass => DisplayPrefs.imperial ? 'lb' : symbol,
    _ => symbol,
  };

  Color get color => switch (this) {
    MetricType.steps || MetricType.distance => DataColors.steps,
    MetricType.calories => DataColors.temperature,
    MetricType.heartRate => DataColors.heart,
    MetricType.spo2 => DataColors.oxygen,
    MetricType.hrv => DataColors.hrv,
    MetricType.stress => DataColors.stress,
    MetricType.temperature => DataColors.temperature,
    MetricType.respiratoryRate => DataColors.respiration,
    MetricType.systolic || MetricType.diastolic => DataColors.pressure,
    MetricType.weight ||
    MetricType.bodyFat ||
    MetricType.muscleMass ||
    MetricType.bmi => DataColors.body,
  };

  IconData get icon => switch (this) {
    MetricType.steps => Icons.directions_walk,
    MetricType.calories => Icons.local_fire_department,
    MetricType.distance => Icons.straighten,
    MetricType.heartRate => Icons.favorite,
    MetricType.spo2 => Icons.water_drop,
    MetricType.hrv => Icons.monitor_heart,
    MetricType.stress => Icons.self_improvement,
    MetricType.temperature => Icons.thermostat,
    MetricType.respiratoryRate => Icons.air,
    MetricType.systolic || MetricType.diastolic => Icons.bloodtype,
    MetricType.weight => Icons.monitor_weight_outlined,
    MetricType.bodyFat => Icons.pie_chart_outline,
    MetricType.muscleMass => Icons.fitness_center,
    MetricType.bmi => Icons.accessibility_new,
  };

  /// Değeri seçili birimde yazar; mesafe km, ısı °C olarak saklanır.
  String format(double v) => switch (this) {
    MetricType.temperature =>
      (DisplayPrefs.imperial ? v * 9 / 5 + 32 : v).toStringAsFixed(1),
    MetricType.distance =>
      (DisplayPrefs.imperial ? v / kmPerMile : v).toStringAsFixed(2),
    MetricType.weight || MetricType.muscleMass =>
      (DisplayPrefs.imperial ? v * lbPerKg : v).toStringAsFixed(1),
    MetricType.bodyFat || MetricType.bmi => v.toStringAsFixed(1),
    _ => v.round().toString(),
  };
}

extension SportLook on SportType {
  String get label {
    final l = currentL10n;
    return switch (this) {
      SportType.run => l.sportRun,
      SportType.cycling => l.sportCycling,
      SportType.badminton => l.sportBadminton,
      SportType.football => l.sportFootball,
      SportType.tennis => l.sportTennis,
      SportType.yoga => l.sportYoga,
      SportType.meditation => l.sportMeditation,
      SportType.dance => l.sportDance,
      SportType.basketball => l.sportBasketball,
      SportType.walk => l.sportWalk,
      SportType.workout => l.sportWorkout,
      SportType.cricket => l.sportCricket,
      SportType.hiking => l.sportHiking,
      SportType.aerobics => l.sportAerobics,
      SportType.pingPong => l.sportPingPong,
      SportType.ropeJump => l.sportRopeJump,
      SportType.sitUps => l.sportSitUps,
      SportType.volleyball => l.sportVolleyball,
    };
  }

  IconData get icon => switch (this) {
    SportType.run => Icons.directions_run,
    SportType.cycling => Icons.directions_bike,
    SportType.badminton || SportType.tennis => Icons.sports_tennis,
    SportType.football => Icons.sports_soccer,
    SportType.yoga || SportType.meditation => Icons.self_improvement,
    SportType.dance => Icons.music_note,
    SportType.basketball => Icons.sports_basketball,
    SportType.walk => Icons.directions_walk,
    SportType.workout || SportType.sitUps => Icons.fitness_center,
    SportType.cricket => Icons.sports_cricket,
    SportType.hiking => Icons.hiking,
    SportType.aerobics || SportType.ropeJump => Icons.sports_gymnastics,
    SportType.pingPong => Icons.sports_tennis,
    SportType.volleyball => Icons.sports_volleyball,
  };

  /// Mesafe ve tempo anlamlı mı (koşu, yürüyüş, bisiklet gibi).
  bool get hasDistance => const {
    SportType.run,
    SportType.walk,
    SportType.cycling,
    SportType.hiking,
  }.contains(this);
}

/// Spor türü bilinmiyorsa kullanılan ad ve simge.
String sportLabel(SportType? t) => t?.label ?? currentL10n.sportUnknown;
IconData sportIcon(SportType? t) => t?.icon ?? Icons.fitness_center;

/// "12:05" ya da "1:02:05" biçiminde süre.
String clock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Tempo: 1 km (ya da mil) için dakika ve saniye, örneğin 6'12".
String paceText(Duration? pace) {
  if (pace == null || pace == Duration.zero) return '--';
  return "${pace.inMinutes}'${two(pace.inSeconds % 60)}\"";
}

extension BandLook on Band {
  /// Aralığın etkin dildeki adı.
  String get label {
    final l = currentL10n;
    return switch (id) {
      'calm' => l.bandCalm,
      'mild' => l.bandMild,
      'tense' => l.bandTense,
      'anxious' => l.bandAnxious,
      'low' => l.bandLow,
      'normal' => l.bandNormal,
      'good' => l.bandGood,
      'great' => l.bandGreat,
      _ => id,
    };
  }
}

extension PeriodLook on Period {
  String get label => switch (this) {
    Period.day => currentL10n.periodDay,
    Period.week => currentL10n.periodWeek,
    Period.month => currentL10n.periodMonth,
  };
}

extension SleepStageName on SleepStage {
  String get label => switch (this) {
    SleepStage.deep => currentL10n.sleepDeep,
    SleepStage.light => currentL10n.sleepLight,
    SleepStage.rem => currentL10n.sleepRem,
    SleepStage.awake => currentL10n.sleepAwake,
  };
}

/// Denetleyicinin son hatası, etkin dilde; hata yoksa null.
String? issueText(DeviceController c) => switch (c.issue) {
  null => null,
  DeviceIssue.busy => currentL10n.issueBusy,
  DeviceIssue.noEcgSignal => currentL10n.issueNoEcgSignal,
  DeviceIssue.noSpotSignal => currentL10n.issueNoSpotSignal,
  DeviceIssue.failed => currentL10n.issueFailed,
};

extension ShareScopeLook on ShareScope {
  String get label {
    final l = currentL10n;
    return switch (this) {
      ShareScope.heartRate => l.shareHeartRate,
      ShareScope.spo2 => l.shareSpo2,
      ShareScope.sleep => l.shareSleep,
      ShareScope.activity => l.shareActivity,
      ShareScope.ecg => l.shareEcg,
      ShareScope.bloodPressure => l.shareBloodPressure,
      ShareScope.stress => l.shareStress,
      ShareScope.temperature => l.shareTemperature,
    };
  }

  IconData get icon => switch (this) {
    ShareScope.heartRate => Icons.favorite,
    ShareScope.spo2 => Icons.water_drop,
    ShareScope.sleep => Icons.bedtime,
    ShareScope.activity => Icons.directions_walk,
    ShareScope.ecg => Icons.monitor_heart,
    ShareScope.bloodPressure => Icons.bloodtype,
    ShareScope.stress => Icons.self_improvement,
    ShareScope.temperature => Icons.thermostat,
  };

  Color get color => switch (this) {
    ShareScope.heartRate || ShareScope.ecg => DataColors.heart,
    ShareScope.spo2 => DataColors.oxygen,
    ShareScope.sleep => DataColors.sleepLight,
    ShareScope.activity => DataColors.steps,
    ShareScope.bloodPressure => DataColors.pressure,
    ShareScope.stress => DataColors.stress,
    ShareScope.temperature => DataColors.temperature,
  };
}

/// Paylaşılan türlerin kısa listesi, sabit sırayla ("Nabız, Uyku").
String shareList(Set<ShareScope> scopes) => ShareScope.values
    .where(scopes.contains)
    .map((s) => s.label)
    .join(currentL10n.localeName == 'ar' ? '، ' : ', ');

/// MaterialApp altında saat ve birim tercihlerini [DisplayPrefs]'e yazar;
/// saat seçicisi de aynı biçimi kullansın diye `alwaysUse24HourFormat`
/// değerini ayarlar. Tercih değişince açık ekranlar da yeniden çizilir
/// (biçimlendiriciler BuildContext'e bağlı olmadığı için kendiliğinden
/// yenilenmezler).
class DisplaySync extends StatefulWidget {
  const DisplaySync({
    super.key,
    required this.clock,
    required this.units,
    required this.child,
  });

  final ClockFormat clock;
  final UnitSystem units;
  final Widget child;

  @override
  State<DisplaySync> createState() => _DisplaySyncState();
}

class _DisplaySyncState extends State<DisplaySync> {
  @override
  void didUpdateWidget(DisplaySync old) {
    super.didUpdateWidget(old);
    if (old.clock != widget.clock || old.units != widget.units) {
      void mark(Element e) {
        e.markNeedsBuild();
        e.visitChildren(mark);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(mark);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    DisplayPrefs.imperial = widget.units == UnitSystem.imperial;
    DisplayPrefs.use24h = switch (widget.clock) {
      ClockFormat.h24 => true,
      ClockFormat.h12 => false,
      ClockFormat.system => mq.alwaysUse24HourFormat ? true : null,
    };
    final use24 =
        DisplayPrefs.use24h ??
        !_fmt(DateFormat.HOUR_MINUTE).pattern!.contains('a');
    return MediaQuery(
      data: mq.copyWith(alwaysUse24HourFormat: use24),
      child: widget.child,
    );
  }
}
