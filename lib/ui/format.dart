import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];
const weekdaysShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

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
    MetricType.steps => AppColors.steps,
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
    _ => v.round().toString(),
  };
}
