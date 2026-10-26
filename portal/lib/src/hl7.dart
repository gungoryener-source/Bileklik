import 'model.dart';

/// Ölçümleri HL7 v2.5.1 ORU^R01 iletisine çevirir (hastane bilgi sistemleri
/// için). FHIR R4 dışa aktarmasının eski sistemlere giden karşılığı.
///
/// - Tek OBR altında her sayısal değer bir OBX (NM). Tansiyon gibi
///   bileşenli ölçümlerin her bileşeni ayrı OBX'tir.
/// - LOINC kodları `LN`, uygulamanın kendi kodları `L` sistemiyle yazılır.
/// - Birimler UCUM. Zamanlar UTC (`+0000`).
/// - EKG dalga formu (SampledData) iletiye konmaz; atlanan sayısı NTE'de.
/// - Hasta: hekimin kaydı varsa dosya no (MR) ve ad; her durumda takma kimlik
///   (PI). Kayıt yoksa ad alanı boş kalır.
///
/// Gerçek bir hastane arayüzüyle (MLLP, kabul iletisi) denenmedi; alan
/// eşlemesi kurumla birlikte doğrulanacak.
class Hl7Export {
  Hl7Export._();

  static const sendingApp = 'BILEKLIK';

  /// [observations] zamana göre sıralanır.
  static String oru({
    required String messageId,
    required DateTime now,
    required String patientId,
    required List<StoredObservation> observations,
    required DateTime from,
    required DateTime to,
    PatientRecord? record,
    String? facility,
  }) {
    final fac = esc(facility ?? '');
    final items = [...observations]
      ..sort((a, b) => a.effective.compareTo(b.effective));
    final segments = <String>[
      [
        'MSH',
        r'^~\&',
        sendingApp,
        fac,
        '',
        '',
        ts(now),
        '',
        'ORU^R01^ORU_R01',
        esc(messageId),
        'P',
        '2.5.1',
        '',
        '',
        'AL',
        'NE',
        '',
        'UNICODE UTF-8',
      ].join('|'),
      _pid(patientId, record, fac),
      [
        'OBR',
        '1',
        '',
        '${esc(messageId)}^$sendingApp',
        'WRIST^Wristband measurements^L',
        '',
        '',
        ts(from),
        ts(to),
      ].join('|'),
    ];
    var n = 0;
    var skipped = 0;
    for (final o in items) {
      final r = o.resource;
      final rows = <String>[];
      final main = _quantity(r['valueQuantity']);
      final coding = _coding(r['code']);
      if (main != null && coding != null) {
        rows.add(_obx(++n, coding, main, o.effective));
      }
      for (final c in (r['component'] as List?) ?? const []) {
        if (c is! Map) continue;
        final q = _quantity(c['valueQuantity']);
        final cc = _coding(c['code']);
        if (q != null && cc != null) rows.add(_obx(++n, cc, q, o.effective));
      }
      if (rows.isEmpty) {
        skipped++;
        continue;
      }
      segments.addAll(rows);
      for (final note in (r['note'] as List?) ?? const []) {
        if (note is Map && note['text'] is String) {
          segments.add('NTE|1|L|${esc(note['text'] as String)}');
        }
      }
    }
    if (skipped > 0) {
      segments.add(
        'NTE|1|L|${esc('$skipped observation(s) without numeric value '
        '(e.g. ECG waveform) are only in the FHIR export.')}',
      );
    }
    return '${segments.join('\r')}\r';
  }

  static String _pid(String patientId, PatientRecord? rec, String fac) {
    final ids = [
      if (rec?.fileNo case final f? when f.isNotEmpty) '${esc(f)}^^^$fac^MR',
      '${esc(patientId)}^^^$sendingApp^PI',
    ].join('~');
    var name = '';
    final full = rec?.name.trim() ?? '';
    if (full.isNotEmpty) {
      final parts = full.split(RegExp(r'\s+'));
      final family = parts.removeLast();
      name = '${esc(family)}^${esc(parts.join(' '))}';
    }
    final b = rec?.birthDate;
    final birth = b == null
        ? ''
        : '${b.year.toString().padLeft(4, '0')}${_two(b.month)}${_two(b.day)}';
    final sex = switch (rec?.sex) {
      Sex.female => 'F',
      Sex.male => 'M',
      Sex.other => 'O',
      null => rec == null ? '' : 'U',
    };
    return ['PID', '1', '', ids, '', name, '', birth, sex].join('|');
  }

  static String _obx(
    int n,
    (String, String, String) code,
    (num, String) q,
    DateTime at,
  ) {
    final (system, value, display) = code;
    final (v, unit) = q;
    return [
      'OBX',
      '$n',
      'NM',
      '${esc(value)}^${esc(display)}^$system',
      '',
      _num(v),
      unit.isEmpty ? '' : '${esc(unit)}^${esc(unit)}^UCUM',
      '',
      '',
      '',
      '',
      'F',
      '',
      '',
      ts(at),
    ].join('|');
  }

  /// (sistem, kod, ad); LOINC dışındakiler yerel kod.
  static (String, String, String)? _coding(Object? concept) {
    if (concept is! Map) return null;
    final c = (concept['coding'] as List?)?.firstOrNull;
    if (c is! Map || c['code'] is! String) return null;
    final system = c['system'] == 'http://loinc.org' ? 'LN' : 'L';
    return (system, c['code'] as String, (c['display'] as String?) ?? '');
  }

  static (num, String)? _quantity(Object? q) {
    if (q is! Map || q['value'] is! num) return null;
    return (q['value'] as num, (q['code'] ?? q['unit'] ?? '').toString());
  }

  static String _num(num v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

  /// HL7 zaman damgası, UTC.
  static String ts(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, '0')}${_two(u.month)}${_two(u.day)}'
        '${_two(u.hour)}${_two(u.minute)}${_two(u.second)}+0000';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Ayraç karakterlerini kaçırır; satır sonları boşluk olur.
  static String esc(String s) => s
      .replaceAll(r'\', r'\E\')
      .replaceAll('|', r'\F\')
      .replaceAll('^', r'\S\')
      .replaceAll('~', r'\R\')
      .replaceAll('&', r'\T\')
      .replaceAll(RegExp(r'[\r\n]+'), ' ');
}
