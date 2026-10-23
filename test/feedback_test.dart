import 'dart:async';

import 'package:bileklik/app_info.dart';
import 'package:bileklik/data/feedback.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeFeedbackService> _open(
  WidgetTester tester, {
  String language = 'tr',
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final service = FakeFeedbackService();
  await tester.pumpWidget(
    BileklikApp(
      controller: DeviceController(FakeDevice(), store: MemoryHealthStore()),
      settings: AppSettings.memory(language: language),
      feedback: service,
    ),
  );
  await tester.pumpAndSettle();
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  unawaited(
    nav.push(MaterialPageRoute<void>(builder: (_) => const FeedbackScreen())),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('geri bildirim konu ve mesajla gönderilir', (tester) async {
    final service = await _open(tester);
    final send = find.text('Gönder');
    // Boş mesaj gönderilemez.
    await tester.tap(send);
    await tester.pump();
    expect(service.sent, isEmpty);

    await tester.tap(find.text('Öneri'));
    await tester.enterText(find.byType(TextField), '  Haftalık rapor e-postayla gelsin  ');
    await tester.pump();
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();

    final sent = service.sent.single;
    expect(sent.topic, FeedbackTopic.idea);
    expect(sent.message, 'Haftalık rapor e-postayla gelsin');
    expect(sent.context!.appVersion, appVersion);
    expect(sent.context!.locale, 'tr');
    expect(find.byType(FeedbackScreen), findsNothing);
    expect(find.text('Teşekkürler, geri bildiriminiz alındı.'), findsOneWidget);
  });

  testWidgets('teknik bilgi istenmezse eklenmez; hata ekranı kapatmaz', (
    tester,
  ) async {
    final service = await _open(tester)..fail = true;
    await tester.enterText(find.byType(TextField), 'Uygulama kapanıyor');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    final send = find.text('Gönder');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(service.sent, isEmpty);
    expect(find.byType(FeedbackScreen), findsOneWidget);
    expect(find.textContaining('Sunucuya ulaşılamadı'), findsOneWidget);

    service.fail = false;
    // Bildirim kapanana kadar bekle; düğmenin üstünü örtebilir.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(service.sent.single.context, isNull);
  });

  for (final lang in ['en', 'ar', 'de']) {
    testWidgets('geri bildirim ekranı $lang dilinde taşmaz', (tester) async {
      await _open(tester, language: lang);
      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedButton<FeedbackTopic>), findsOneWidget);
    });
  }
}
