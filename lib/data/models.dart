import '../device/protocol/history.dart';

/// Uygulamanın sakladığı sağlık ölçüm türleri.
///
/// Portal aktarımında her tür bir FHIR Observation'a eşlenecek
/// (LOINC kodları analiz belgesindeki tabloda).
enum MetricType {
  steps('Adım', 'adım'),
  heartRate('Kalp Atış Hızı', 'bpm'),
  spo2('Kan Oksijen Doygunluğu', '%'),
  hrv('Kalp Atış Hızı Değişkenliği', 'ms'),
  stress('Stres', ''),
  temperature('Vücut Isısı', '°C'),
  respiratoryRate('Solunum Hızı', '/dk'),
  systolic('Tansiyon (büyük)', 'mmHg'),
  diastolic('Tansiyon (küçük)', 'mmHg');

  const MetricType(this.label, this.unit);
  final String label;
  final String unit;
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
