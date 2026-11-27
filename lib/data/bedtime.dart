import 'aggregate.dart';
import 'health_store.dart';

/// Yatma düzeni: haftanın her akşamı için uykuya yatış saati ve ideal
/// aralığa uyup uymadığı.
///
/// İdeal yatma saati şimdilik sabittir (23:00, ±30 dk). Kullanıcı ayarı
/// eklenince [ideal] oradan gelir.
class BedtimeWeek {
  BedtimeWeek._(this.range, this.bedtimes);

  /// Pazartesiden başlayan hafta.
  final PeriodRange range;

  /// Haftanın 7 akşamı (pazartesi ilk); o akşam uyku yoksa null.
  final List<DateTime?> bedtimes;

  /// İdeal yatma saati, gece yarısından dakika.
  static const ideal = 23 * 60;

  /// İdeal aralığın yarı genişliği (dakika).
  static const tolerance = 30;

  /// Gece uykusunun başlayabileceği saatler: 18:00 ile 06:00 arası.
  /// Gündüz şekerlemeleri yatma saati sayılmaz.
  static bool _isEvening(DateTime t) => t.hour >= 18 || t.hour < 6;

  /// Uykunun ait olduğu akşam: 00:30'da yatılan gece önceki güne yazılır.
  static DateTime eveningOf(DateTime t) {
    final e = t.subtract(const Duration(hours: 12));
    return DateTime(e.year, e.month, e.day);
  }

  /// Saati öğleden itibaren dakikaya çevirir; gece yarısını aşan saatler
  /// (00:30 gibi) 23:00'ün ardından gelsin diye. 23:00 = 660, 01:00 = 780.
  static int sinceNoon(DateTime t) => (t.hour * 60 + t.minute - 720) % 1440;

  /// [ideal]'in öğleden itibaren dakikası.
  static const idealSinceNoon = ideal - 720;

  /// Yatış saatinin ideal saatten farkı (dakika; erken eksi, geç artı).
  static int deviation(DateTime t) => sinceNoon(t) - idealSinceNoon;

  static bool onTrack(DateTime t) => deviation(t).abs() <= tolerance;

  /// [day]'in içinde olduğu haftanın yatış saatleri.
  static BedtimeWeek of(HealthStore store, DateTime day) {
    final range = PeriodRange.of(Period.week, day);
    final out = List<DateTime?>.filled(7, null);
    final sessions = store.sleepBetween(
      range.start.add(const Duration(hours: 12)),
      range.end.add(const Duration(hours: 12)),
    );
    for (final s in sessions) {
      if (!_isEvening(s.start)) continue;
      // Yaz saati geçişinde gün 23/25 saat olabilir; yuvarlayarak bulunur.
      final index =
          (eveningOf(s.start).difference(range.start).inMinutes / 1440).round();
      if (index < 0 || index > 6) continue;
      final prev = out[index];
      if (prev == null || s.start.isBefore(prev)) out[index] = s.start;
    }
    return BedtimeWeek._(range, out);
  }

  Iterable<DateTime> get recorded => bedtimes.whereType<DateTime>();

  int get onTrackCount => recorded.where(onTrack).length;

  bool get isEmpty => recorded.isEmpty;
}

/// Ana Sayfa'nın sakinleşme (gece) görünümüne geçtiği saatler: 22:00-05:00.
bool isWindDownTime(DateTime t) => t.hour >= 22 || t.hour < 5;

/// Sakinleşme görünümünün bir sonraki açılış ya da kapanış anı.
DateTime nextWindDownChange(DateTime t) {
  if (t.hour < 5) return DateTime(t.year, t.month, t.day, 5);
  if (t.hour < 22) return DateTime(t.year, t.month, t.day, 22);
  return DateTime(t.year, t.month, t.day + 1, 5);
}
