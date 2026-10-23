// Çeviri inceleme tablosunu üretir: docs/ceviri-inceleme.csv
//
//   dart run tool/ceviri_tablosu.dart
//
// Tüm anahtarlar dört dilde yan yana; sağlık ve hukuk terimleri başta.
// Ayrıntı: docs/ceviri-inceleme.md
import 'dart:convert';
import 'dart:io';

const _langs = ['tr', 'en', 'ar', 'de'];

final _priority = RegExp(
  '(hrv|spo2|ecg|ekg|heart|pulse|sleep|blood|pressure|stress|temperature|'
  'vo2|ppi|bmi|bodyfat|body|metric|health|privacy|consent|measure|energy|'
  'recovery|load)',
  caseSensitive: false,
);

String _cell(String v) => '"${v.replaceAll('"', '""')}"';

void main() {
  final arb = {
    for (final l in _langs)
      l: (jsonDecode(File('lib/l10n/app_$l.arb').readAsStringSync()) as Map)
          .cast<String, Object?>(),
  };
  final keys = [
    for (final k in arb['tr']!.keys)
      if (!k.startsWith('@')) k,
  ]..sort((a, b) {
      final pa = _priority.hasMatch(a) ? 0 : 1;
      final pb = _priority.hasMatch(b) ? 0 : 1;
      return pa != pb ? pa - pb : a.compareTo(b);
    });
  final out = StringBuffer('anahtar,öncelik,tr,en,ar,de,not\r\n');
  for (final k in keys) {
    out
      ..write(k)
      ..write(',')
      ..write(_priority.hasMatch(k) ? 'sağlık/hukuk' : '');
    for (final l in _langs) {
      out
        ..write(',')
        ..write(_cell('${arb[l]![k] ?? ''}'));
    }
    out.write(',\r\n');
  }
  File('docs/ceviri-inceleme.csv').writeAsStringSync(out.toString());
  stdout.writeln('${keys.length} anahtar yazıldı.');
}
