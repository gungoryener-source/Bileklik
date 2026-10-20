import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/theme.dart';
import 'package:bileklik/ui/widgets/cam/cam.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// Yarı saydam rengi zeminin üstüne serer.
Color _over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

void main() {
  const c = AppColors.cam;

  group('Cam renkleri', () {
    test('tema tek ve koyu', () {
      final t = buildTheme();
      expect(t.brightness, Brightness.dark);
      expect(t.extension<AppColors>(), same(c));
      expect(t.appBarTheme.elevation, 0);
      expect(t.appBarTheme.scrolledUnderElevation, 0);
    });

    // En kötü durum: auroranın en parlak noktaları (merkezde tam opak
    // ışık), üstünde koyu perde, onun üstünde cam kart.
    final zeminler = <String, Color>{
      for (final (name, top) in [
        ('üst', c.bgTop),
        ('orta', c.bgMid),
        ('alt', c.bgBottom),
      ])
        for (final (light, color) in [
          ('ışıksız', const Color(0x00000000)),
          ('pembe', c.auroraPink),
          ('mor', c.auroraViolet),
          ('camgöbeği', c.auroraCyan),
          ('yeşil', c.auroraLime),
        ])
          '$name/$light': _over(c.scrim, _over(color, top)),
    };

    test('ikincil metin en parlak auroranın üstünde bile 4.5:1', () {
      for (final MapEntry(:key, :value) in zeminler.entries) {
        final card = _over(c.glassSheenStart, _over(c.glassBase, value));
        expect(
          _contrast(_over(c.muted, value), value),
          greaterThanOrEqualTo(4.5),
          reason: 'zemin $key',
        );
        expect(
          _contrast(_over(c.muted, card), card),
          greaterThanOrEqualTo(4.5),
          reason: 'cam kart $key',
        );
        expect(_contrast(c.text, card), greaterThanOrEqualTo(4.5));
      }
    });

    test('ana düğme ve alt menü yazısı okunur', () {
      for (final bg in [c.ctaStart, c.ctaEnd]) {
        expect(_contrast(c.text, bg), greaterThanOrEqualTo(4.5));
      }
      // Seçili sekmenin yazısı hapın ortasında durur.
      final pill = Color.lerp(c.navActiveStart, c.navActiveEnd, 0.5)!;
      expect(_contrast(c.text, pill), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
    });

    test('hata metni okunur', () {
      for (final bg in zeminler.values) {
        expect(_contrast(c.danger, bg), greaterThanOrEqualTo(4.5));
      }
    });
  });

  testWidgets('her rota Cam zemini çizer, eski tema ayarı yok sayılır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Eski sürümün kaydettiği açık tema seçimi uygulamayı bozmamalı.
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'light',
      'language': 'tr',
      'language_chosen': true,
    });
    final settings = await AppSettings.load();
    final device = FakeDevice(random: Random(1));
    final controller = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(
      BileklikApp(controller: controller, settings: settings),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.darkTheme, isNull);
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.brightness, Brightness.dark);
    expect(find.byType(CamBackground), findsOneWidget);
    expect(find.byType(GlassNavBar), findsOneWidget);

    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genel ayarlar'));
    await tester.pumpAndSettle();
    // Tema seçimi kaldırıldı; yalnızca dil satırı var.
    expect(find.text('Koyu'), findsNothing);
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    expect(find.text('Dil'), findsOneWidget);
    // Yeni rota kendi zeminini çizer.
    expect(find.byType(CamBackground, skipOffstage: false), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    device.dispose();
  });
}
