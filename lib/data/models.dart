import '../device/protocol/exercise.dart';
import '../device/protocol/history.dart';

/// Uygulamanın sakladığı sağlık ölçüm türleri.
///
/// Portal aktarımında her tür bir FHIR Observation'a eşlenecek
/// (LOINC kodları analiz belgesindeki tabloda).
enum MetricType {
  steps('steps'),
  calories('kcal'),
  distance('km'),
  heartRate('bpm'),
  spo2('%'),
  hrv('ms'),
  stress(''),
  temperature('°C'),
  respiratoryRate('/min'),
  systolic('mmHg'),
  diastolic('mmHg');

  const MetricType(this.symbol);

  /// Dilden bağımsız birim simgesi. Ekrandaki ad ve birim `MetricLook`'ta.
  final String symbol;

  /// Dönem içinde toplanan türler (adım, kalori, mesafe); diğerlerinin ortalaması alınır.
  bool get isTotal => this == steps || this == calories || this == distance;
}

class Measurement {
  final MetricType type;
  final DateTime time;
  final double value;
  const Measurement(this.type, this.time, this.value);

  @override
  bool operator ==(Object other) =>
      other is Measurement &&
      other.type == type &&
      other.time == time &&
      other.value == value;

  @override
  int get hashCode => Object.hash(type, time, value);
}

/// Bir uyku kaydı: başlangıç zamanı ve dakika dakika evreler.
class SleepSession {
  final DateTime start;
  final List<SleepStage> minutes;
  const SleepSession(this.start, this.minutes);

  DateTime get end => start.add(Duration(minutes: minutes.length));

  int minutesIn(SleepStage s) => minutes.where((m) => m == s).length;
}

/// Tamamlanmış bir egzersiz (0x5C kaydı).
class Workout {
  final SportType? type;
  final DateTime start;
  final Duration duration;
  final int steps;
  final double distanceKm;
  final double calories;
  final int averageHeartRate;

  /// 1 km için geçen süre; mesafe yoksa null.
  final Duration? pace;

  const Workout({
    required this.type,
    required this.start,
    required this.duration,
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.averageHeartRate,
    this.pace,
  });

  DateTime get end => start.add(duration);

  factory Workout.fromRecord(ExerciseRecord r) => Workout(
    type: r.type,
    start: r.start,
    duration: Duration(seconds: r.durationSeconds),
    steps: r.steps,
    distanceKm: r.distanceKm,
    calories: r.calories,
    averageHeartRate: r.heartRate,
    pace: r.paceSeconds > 0 ? Duration(seconds: r.paceSeconds) : null,
  );
}

/// Bir EKG kaydı: ham örnekler ve uygulamanın çıkardığı özet.
///
/// Portala FHIR Observation (SampledData) olarak aktarılacak.
class EcgRecording {
  final DateTime start;
  final int sampleRate;
  final List<int> samples;
  final int? averageHeartRate;
  final int? minHeartRate;
  final int? maxHeartRate;

  /// Atımlar arası sürelerin standart sapması (ms).
  final double? sdnn;
  final int beats;

  const EcgRecording({
    required this.start,
    required this.sampleRate,
    required this.samples,
    required this.averageHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.sdnn,
    required this.beats,
  });

  Duration get duration =>
      Duration(milliseconds: samples.length * 1000 ~/ sampleRate);
}
