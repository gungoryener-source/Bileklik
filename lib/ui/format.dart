import 'package:flutter/material.dart';

import '../data/models.dart';
import '../device/protocol/exercise.dart';
import 'theme.dart';

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];
const weekdaysShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const weekdaysLong = [
  'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar', //
];

String two(int v) => v.toString().padLeft(2, '0');
String hhmm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
String dayMonth(DateTime t) => '${t.day} ${_months[t.month - 1]}';
String monthYear(DateTime t) => '${_months[t.month - 1]} ${t.year}';

/// "1 sa 25 dk" biçiminde süre.
String duration(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m dk';
  return m == 0 ? '$h sa' : '$h sa $m dk';
}

/// Ölçümün en yakın zamanı: bugünse saat, değilse gün ve saat.
String whenText(DateTime t, DateTime now) {
  final sameDay =
      t.year == now.year && t.month == now.month && t.day == now.day;
  return sameDay ? hhmm(t) : '${dayMonth(t)} ${hhmm(t)}';
}

/// Her metriğin ekrandaki rengi ve simgesi.
extension MetricLook on MetricType {
  Color get color => switch (this) {
    MetricType.steps || MetricType.distance => AppColors.steps,
    MetricType.calories => AppColors.temperature,
    MetricType.heartRate => AppColors.heart,
    MetricType.spo2 => AppColors.oxygen,
    MetricType.hrv => AppColors.accent,
    MetricType.stress => const Color(0xFFB388EB),
    MetricType.temperature => AppColors.temperature,
    MetricType.respiratoryRate => const Color(0xFF7BDFF2),
    MetricType.systolic || MetricType.diastolic => const Color(0xFFFF8FA3),
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
  };

  String format(double v) => switch (this) {
    MetricType.temperature => v.toStringAsFixed(1),
    MetricType.distance => v.toStringAsFixed(2),
    _ => v.round().toString(),
  };
}

extension SportLook on SportType {
  String get label => switch (this) {
    SportType.run => 'Koşu',
    SportType.cycling => 'Bisiklet',
    SportType.badminton => 'Badminton',
    SportType.football => 'Futbol',
    SportType.tennis => 'Tenis',
    SportType.yoga => 'Yoga',
    SportType.meditation => 'Meditasyon',
    SportType.dance => 'Dans',
    SportType.basketball => 'Basketbol',
    SportType.walk => 'Yürüyüş',
    SportType.workout => 'Antrenman',
    SportType.cricket => 'Kriket',
    SportType.hiking => 'Doğa yürüyüşü',
    SportType.aerobics => 'Aerobik',
    SportType.pingPong => 'Masa tenisi',
    SportType.ropeJump => 'İp atlama',
    SportType.sitUps => 'Mekik',
    SportType.volleyball => 'Voleybol',
  };

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
String sportLabel(SportType? t) => t?.label ?? 'Egzersiz';
IconData sportIcon(SportType? t) => t?.icon ?? Icons.fitness_center;

/// "12:05" ya da "1:02:05" biçiminde süre.
String clock(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Tempo: 1 km için dakika ve saniye, örneğin 6'12".
String paceText(Duration? pace) {
  if (pace == null || pace == Duration.zero) return '--';
  return "${pace.inMinutes}'${two(pace.inSeconds % 60)}\"";
}
