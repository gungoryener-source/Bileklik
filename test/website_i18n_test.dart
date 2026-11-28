// Tanıtım sitesinin sözlükleri (website/i18n/<dil>.js) birbiriyle ve sayfayla
// tutarlı mı? Sayfadaki metinlerin tamamının çevrildiğini tarayıcıda
// `?lang=en&i18n=eksik` ile konsolda görebilirsiniz; bu test sözlüklerin
// kendi içindeki hataları yakalar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _dict(String lang) {
  final js = File('website/i18n/$lang.js').readAsStringSync();
  final start = js.indexOf('= {');
  final end = js.lastIndexOf('};');
  return (jsonDecode(js.substring(start + 2, end + 1)) as Map)
      .cast<String, String>();
}

List<String> _tags(String s) =>
    RegExp(r'<[^>]+>').allMatches(s).map((m) => m[0]!).toList()..sort();

List<String> _placeholders(String s) =>
    RegExp(r'\{\w+\}').allMatches(s).map((m) => m[0]!).toList()..sort();

void main() {
  final langs = ['en', 'ar', 'de'];
  final dicts = {for (final l in langs) l: _dict(l)};

  test('üç sözlük aynı anahtarlara sahip', () {
    final keys = dicts['en']!.keys.toSet();
    expect(keys, isNotEmpty);
    for (final l in langs) {
      expect(dicts[l]!.keys.toSet(), keys, reason: l);
    }
  });

  test('çeviriler boş değil; etiketler ve yer tutucular korunur', () {
    for (final l in langs) {
      for (final MapEntry(:key, :value) in dicts[l]!.entries) {
        expect(value.trim(), isNotEmpty, reason: '$l: $key');
        expect(_tags(value), _tags(key), reason: '$l: $key');
        expect(_placeholders(value), _placeholders(key), reason: '$l: $key');
      }
    }
  });

  test('sayfa betiklerindeki anlık metinler sözlükte var', () {
    final html = File('website/index.html').readAsStringSync();
    final runtime = {
      for (final m in RegExp(r'\bT\("((?:[^"\\]|\\.)*)"').allMatches(html))
        jsonDecode('"${m[1]}"') as String,
      // Alan adları ve tamam metinleri değişkenlerden T(...) ile çevrilir.
      for (final m in RegExp(r'labels = \{([^}]*)\}').allMatches(html))
        for (final v in RegExp(r': "([^"]+)"').allMatches(m[1]!)) v[1]!,
      for (final m in RegExp(
        r'"#?[\w-]+-form"\), \[[^\]]*\], "([^"]+)"',
      ).allMatches(html))
        m[1]!,
    };
    expect(runtime, isNotEmpty);
    for (final s in runtime) {
      for (final l in langs) {
        expect(dicts[l], contains(s), reason: '$l: $s');
      }
    }
  });

  test('sayfa dil katmanını yükler ve dil seçicisi var', () {
    final html = File('website/index.html').readAsStringSync();
    expect(html, contains('<script src="i18n.js"></script>'));
    expect(html, contains('data-lang-picker'));
    expect(html, contains('name="lang"'));
  });
}
