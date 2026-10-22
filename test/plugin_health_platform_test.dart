import 'package:bileklik/data/health_platform.dart';
import 'package:bileklik/data/plugin_health_platform.dart';
import 'package:bileklik/device/protocol/exercise.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  test('her aktarım türünün iki platformda da izin türü var', () {
    for (final ios in [true, false]) {
      for (final t in ExportType.values) {
        final types = PluginHealthPlatform.typesOf(t, ios: ios);
        expect(types, isNotEmpty, reason: '$t ios=$ios');
        expect(
          types.toSet().length,
          types.length,
          reason: 'tekrarlanan tür: $t ios=$ios',
        );
      }
    }
  });

  test('platforma özgü türler doğru tarafta', () {
    expect(
      PluginHealthPlatform.typesOf(ExportType.hrv, ios: true),
      [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
    );
    expect(
      PluginHealthPlatform.typesOf(ExportType.hrv, ios: false),
      [HealthDataType.HEART_RATE_VARIABILITY_RMSSD],
    );
    // Health Connect'te VKİ kaydı yok.
    expect(
      PluginHealthPlatform.typesOf(ExportType.body, ios: false),
      isNot(contains(HealthDataType.BODY_MASS_INDEX)),
    );
    expect(
      PluginHealthPlatform.typesOf(ExportType.sleep, ios: false),
      [HealthDataType.SLEEP_SESSION],
    );
  });

  test('spor türleri iki platformda da olan karşılıklara eşlenir', () {
    expect(
      PluginHealthPlatform.activityOf(SportType.run),
      HealthWorkoutActivityType.RUNNING,
    );
    expect(
      PluginHealthPlatform.activityOf(SportType.football),
      HealthWorkoutActivityType.SOCCER,
    );
    expect(
      PluginHealthPlatform.activityOf(null),
      HealthWorkoutActivityType.OTHER,
    );
    for (final s in SportType.values) {
      expect(PluginHealthPlatform.activityOf(s), isNotNull);
    }
  });
}
