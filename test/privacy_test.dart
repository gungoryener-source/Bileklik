import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/about_screen.dart';
import 'package:bileklik/ui/screens/privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {String language = 'tr'}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BileklikApp(
      controller: DeviceController(FakeDevice(), store: MemoryHealthStore()),
      settings: AppSettings.memory(language: language),
    ),
  );
  await tester.pumpAndSettle();
}

final _scrollable = find.descendant(
  of: find.byType(PrivacyScreen),
  matching: find.byType(Scrollable),
);

void main() {
  testWidgets('Hakkında ekranından gizlilik politikası açılır', (tester) async {
    await _pump(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
    await tester.pumpAndSettle();
    final button = find.text('Gizlilik politikası');
    await tester.scrollUntilVisible(
      button,
      200,
      scrollable: find.descendant(
        of: find.byType(AboutScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.textContaining('KVKK'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('İletişim'),
      300,
      scrollable: _scrollable,
    );
    expect(find.text('İletişim'), findsOneWidget);
  });

  testWidgets('Health Connect bağlantısıyla gelen rota gizlilik sayfasını açar', (
    tester,
  ) async {
    await _pump(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(PrivacyScreen.routeName);
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
  });

  for (final lang in ['en', 'ar', 'de']) {
    testWidgets('gizlilik sayfası $lang dilinde taşmaz', (tester) async {
      await _pump(tester, language: lang);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushNamed(PrivacyScreen.routeName);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Dokuz bölüm başlığı + giriş ve taslak notu.
      await tester.scrollUntilVisible(
        find.byType(Text).last,
        400,
        scrollable: _scrollable,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
