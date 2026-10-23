import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// iOS izin metinleri her dilde var mı: Info.plist'teki her `…UsageDescription`
/// anahtarı dört dilin InfoPlist.strings dosyasında da olmalı.
void main() {
  test('iOS izin metinleri dört dilde', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final keys = RegExp(r'<key>(NS\w+UsageDescription)</key>')
        .allMatches(plist)
        .map((m) => m.group(1)!)
        .toSet();
    expect(keys, isNotEmpty);
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    for (final lang in ['tr', 'en', 'ar', 'de']) {
      final file = File('ios/Runner/$lang.lproj/InfoPlist.strings');
      expect(file.existsSync(), isTrue, reason: lang);
      final strings = file.readAsStringSync();
      for (final k in keys) {
        expect(
          RegExp('"$k" = ".+";').hasMatch(strings),
          isTrue,
          reason: '$lang: $k',
        );
      }
      expect(project, contains('path = $lang.lproj/InfoPlist.strings;'));
      expect(plist, contains('<string>$lang</string>'));
    }
  });
}
