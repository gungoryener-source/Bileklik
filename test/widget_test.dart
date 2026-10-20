import 'package:bileklik/models/daily_summary.dart';
import 'package:bileklik/screens/home_screen.dart';
import 'package:bileklik/theme/app_text.dart';
import 'package:bileklik/theme/app_theme.dart';
import 'package:bileklik/widgets/aurora_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              Positioned.fill(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Testte font ağdan indirilmesin.
  setUpAll(() => AppText.useGoogleFonts = false);

  final tuesday = DateTime(2026, 10, 20);
  const connected = BandStatus(connected: true, batteryPercent: 78);

  testWidgets('örnek veriyle değerler görünür', (tester) async {
    await tester.pumpWidget(_wrap(HomeScreen(
      summary: DailySummary.sample,
      band: connected,
      now: tuesday,
    )));
    await tester.pumpAndSettle();

    expect(find.text('20 Ekim Salı'), findsOneWidget);
    expect(find.text('JCV8 · %78'), findsOneWidget);
    expect(find.text('Canlı'), findsOneWidget);
    expect(find.text('6.482'), findsOneWidget);
    expect(find.text('7 sa 24 dk'), findsOneWidget);
  });

  testWidgets('veri yokken ve bileklik bağlı değilken boş durum', (tester) async {
    await tester.pumpWidget(_wrap(HomeScreen(
      summary: DailySummary.empty,
      band: BandStatus.disconnected,
      now: tuesday,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Bağlı değil'), findsOneWidget);
    expect(find.text('Bileklik bağlı değil'), findsOneWidget);
    expect(find.text('Canlı'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('küçük ekran ve 2x yazı boyutunda taşma yok', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(
      HomeScreen(summary: DailySummary.sample, band: connected, now: tuesday),
      textScale: 2,
    ));
    await tester.pumpAndSettle();

    // Listenin sonuna kadar kaydırıp her kartın çizilmesini sağla.
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
