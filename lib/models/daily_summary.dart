import 'dart:math' as math;

/// Bilekliğin bağlantı durumu.
class BandStatus {
  const BandStatus({required this.connected, this.batteryPercent});

  final bool connected;
  final int? batteryPercent;

  static const disconnected = BandStatus(connected: false);
}

/// Ana ekranda gösterilen günlük özet.
///
/// Değeri olmayan alanlar `null` olur ve ekranda boş durum gösterilir.
class DailySummary {
  const DailySummary({
    this.heartRateBpm,
    this.restingHeartRateBpm,
    this.steps,
    this.stepGoal = 10000,
    this.sleepMinutes,
    this.calories,
    this.calorieGoal = 2100,
    this.activeMinutes,
    this.activeGoal = 60,
    this.weeklyRestingHr = const [null, null, null, null, null, null, null],
  });

  final int? heartRateBpm;
  final int? restingHeartRateBpm;
  final int? steps;
  final int stepGoal;
  final int? sleepMinutes;
  final int? calories;
  final int calorieGoal;
  final int? activeMinutes;
  final int activeGoal;

  /// Pazartesiden pazara 7 değer; ölçüm olmayan gün `null`.
  final List<int?> weeklyRestingHr;

  double get stepProgress => _ratio(steps, stepGoal);
  double get calorieProgress => _ratio(calories, calorieGoal);
  double get activeProgress => _ratio(activeMinutes, activeGoal);

  static double _ratio(int? value, int goal) {
    if (value == null || goal <= 0) return 0.0;
    return math.min(value / goal, 1.0);
  }

  /// Gerçek bileklik verisi bağlanana kadar kullanılan örnek veri.
  static const sample = DailySummary(
    heartRateBpm: 72,
    restingHeartRateBpm: 64,
    steps: 6482,
    sleepMinutes: 444,
    calories: 1240,
    activeMinutes: 32,
    weeklyRestingHr: [62, 66, 60, 64, 58, 63, 68],
  );

  /// Hiç veri yokken.
  static const empty = DailySummary();
}
