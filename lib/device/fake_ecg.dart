import 'dart:math';

/// Sahte EKG sinyali: P, QRS ve T dalgaları Gauss eğrileriyle çizilir,
/// üzerine solunum kaynaklı taban kayması ve küçük gürültü eklenir.
class EcgSynth {
  EcgSynth({required this.sampleRate, this.heartRate = 72, Random? random})
    : _random = random ?? Random();

  final int sampleRate;
  final double heartRate;
  final Random _random;

  int _n = 0;
  double _beatStart = 0;
  double _beatLength = 0.83;

  /// Bir sonraki örnek (ham ADC benzeri, taban değeri 12000 civarı).
  int next() {
    final t = _n / sampleRate;
    _n++;
    var phase = t - _beatStart;
    if (phase >= _beatLength) {
      _beatStart += _beatLength;
      phase -= _beatLength;
      // Atımdan atıma ±%4 doğal değişkenlik.
      _beatLength = 60 / heartRate * (1 + (_random.nextDouble() - 0.5) * 0.08);
    }
    double g(double center, double width, double height) =>
        height * exp(-pow(phase - center, 2) / (2 * width * width));
    final mv =
        g(0.12, 0.025, 0.12) - // P
        g(0.21, 0.008, 0.12) + // Q
        g(0.23, 0.010, 1.1) - // R
        g(0.255, 0.010, 0.22) + // S
        g(0.45, 0.045, 0.3) + // T
        0.08 * sin(2 * pi * 0.25 * t) + // solunum
        (_random.nextDouble() - 0.5) * 0.03;
    return 12000 + (mv * 1000).round();
  }
}
