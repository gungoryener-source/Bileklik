import 'model.dart';

/// Bundle'daki bir kaydın neden alınmadığı.
class Rejection {
  const Rejection(this.index, this.reason);

  /// `entry` dizisindeki sıra.
  final int index;
  final String reason;
}

/// Ayrıştırma sonucu: alınabilecek Observation'lar ve reddedilenler.
class IngestResult {
  const IngestResult(this.observations, this.rejected);

  final List<StoredObservation> observations;
  final List<Rejection> rejected;
}

/// Uygulamanın gönderdiği Bundle'ı ayrıştırır. Yalnızca [patientId]'ye ait
/// Observation'lar alınır; Patient kaynağı kimliği doğrulamak için okunur.
///
/// Bundle başka bir hastaya aitse [FormatException] fırlatır (tüm istek
/// reddedilir). Tek tek bozuk kayıtlar [IngestResult.rejected]'e düşer.
IngestResult parseBundle(Object? json, String patientId) {
  if (json is! Map || json['resourceType'] != 'Bundle') {
    throw const FormatException('Bundle bekleniyordu');
  }
  final entries = json['entry'];
  if (entries is! List) throw const FormatException('entry yok');

  final subject = 'urn:uuid:$patientId';
  final accepted = <StoredObservation>[];
  final rejected = <Rejection>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final r = entry is Map ? entry['resource'] : null;
    if (r is! Map) {
      rejected.add(Rejection(i, 'resource yok'));
      continue;
    }
    switch (r['resourceType']) {
      case 'Patient':
        if (r['id'] != patientId) {
          throw const FormatException('Bundle başka bir hastaya ait');
        }
      case 'Observation':
        final reason = _check(r, subject);
        if (reason != null) {
          rejected.add(Rejection(i, reason));
          continue;
        }
        accepted.add(
          StoredObservation(
            patientId: patientId,
            identifier: _identifier(r)!,
            code: _code(r)!,
            effective: _effective(r)!,
            resource: Map<String, Object?>.from(r),
          ),
        );
      default:
        rejected.add(Rejection(i, '${r['resourceType']} desteklenmiyor'));
    }
  }
  return IngestResult(accepted, rejected);
}

String? _check(Map r, String subject) {
  if (r['status'] != 'final') return 'status final olmalı';
  final s = r['subject'];
  if (s is! Map || s['reference'] != subject) return 'subject bu hasta değil';
  if (_identifier(r) == null) return 'identifier yok';
  if (_code(r) == null) return 'code yok';
  if (_effective(r) == null) return 'effective zamanı yok ya da bozuk';
  return null;
}

String? _identifier(Map r) {
  final ids = r['identifier'];
  if (ids is! List || ids.isEmpty || ids.first is! Map) return null;
  final first = ids.first as Map;
  final system = first['system'];
  final value = first['value'];
  if (system is! String || value is! String || value.isEmpty) return null;
  return '$system|$value';
}

String? _code(Map r) {
  final code = r['code'];
  if (code is! Map) return null;
  final coding = code['coding'];
  if (coding is! List || coding.isEmpty || coding.first is! Map) return null;
  final c = (coding.first as Map)['code'];
  return c is String && c.isNotEmpty ? c : null;
}

DateTime? _effective(Map r) {
  final at = r['effectiveDateTime'];
  if (at is String) return DateTime.tryParse(at);
  final period = r['effectivePeriod'];
  if (period is Map && period['start'] is String) {
    return DateTime.tryParse(period['start'] as String);
  }
  return null;
}
