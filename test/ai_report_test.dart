import 'dart:math';

import 'package:bileklik/data/ai_report.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/data/models.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/history.dart';
import 'package:bileklik/l10n/app_localizations.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/ai_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pazartesi.
final _monday = DateTime(2026, 10, 19);

DateTime _day(int offset) =>
    DateTime(_monday.year, _monday.month, _monday.day + offset);

/// [day] sabahına biten gece: [minutes] dakika hafif uyku.
SleepSession _night(DateTime day, int minutes) => SleepSession(
  DateTime(day.year, day.month, day.day - 1, 23),
  List.filled(minutes, SleepStage.light),
);

/// Pazartesiden itibaren [days] gün, her gün [steps] adım ve [sleep] dk uyku.
MemoryHealthStore _week({int days = 7, int steps = 12000, int sleep = 450}) =>
    MemoryHealthStore()
      ..addSleep([for (var d = 0; d < days; d++) _night(_day(d), sleep)])
      ..addMeasurements([
        for (var d = 0; d < days; d++)
          Measurement(
            MetricType.steps,
            _day(d).add(const Duration(hours: 12)),
            steps.toDouble(),
          ),
      ]);

/// Açık ekranın kaydırılan listesi (alttaki Ana Sayfa'nınki değil).
final _list = find
    .descendant(
      of: find.byType(AiReportScreen),
      matching: find.byType(Scrollable),
    )
    .first;

final _tr = lookupAppLocalizations(const Locale('tr'));

void main() {
  test('veri yoksa rapor yazılmaz', () {
    final input = AiReportInput.of(MemoryHealthStore(), _day(3));
    expect(input.isEmpty, isTrue);
    expect(DemoAiReportService.write(input, _tr, _day(3)), isNull);
  });

  test('iyi bir hafta: adım ve uyku iyi gidenlerde', () {
    final input = AiReportInput.of(_week(), _day(6), age: 34, isMale: false);
    final r = DemoAiReportService.write(input, _tr, _day(6))!;
    expect(r.demo, isTrue);
    expect(r.language, 'tr');
    expect(r.summary, _tr.aiSummaryGood);
    expect(r.wins, contains(_tr.aiStepsGood(12000)));
    expect(r.wins, contains(_tr.aiSleepGood(7, 30)));
    expect(r.watch, isEmpty);
    expect(r.tips, isNotEmpty);
  });

  test('az adım ve kısa uyku: dikkat ve öneri', () {
    final input = AiReportInput.of(_week(steps: 3000, sleep: 300), _day(6));
    final r = DemoAiReportService.write(input, _tr, _day(6))!;
    expect(r.watch, contains(_tr.aiStepsLow(3000)));
    expect(r.watch, contains(_tr.aiSleepShort(5, 0)));
    expect(r.tips, containsAll([_tr.aiTipWalk, _tr.aiTipSleep]));
    expect(r.summary, _tr.aiSummaryCare);
    for (final list in [r.wins, r.watch, r.tips]) {
      expect(list.length, lessThanOrEqualTo(DemoAiReportService.maxItems));
    }
  });

  test('az günlük veri özette söylenir', () {
    final input = AiReportInput.of(_week(days: 2), _day(6));
    final r = DemoAiReportService.write(input, _tr, _day(6))!;
    expect(r.summary, _tr.aiSummaryFewDays(2));
  });

  test('gönderilecek özet kimlik ve ham veri taşımaz', () {
    final input = AiReportInput.of(_week(), _day(6), age: 34, isMale: true);
    final json = input.toJson();
    expect(json['age_group'], '30-39');
    expect(json['sex'], 'male');
    expect((json['week'] as Map)['avg_steps'], 12000);
    expect(json.keys, isNot(contains('name')));
    expect(input.toPrettyJson(), isNot(contains('mac')));
  });

  test('rapor her dilde yazılır', () {
    final input = AiReportInput.of(_week(), _day(6));
    for (final lang in ['tr', 'en', 'ar', 'de']) {
      final l = lookupAppLocalizations(Locale(lang));
      final r = DemoAiReportService.write(input, l, _day(6))!;
      expect(r.language, lang);
      expect(r.summary, l.aiSummaryGood);
    }
  });

  Future<void> open(
    WidgetTester tester, {
    String lang = 'tr',
    MemoryHealthStore? store,
  }) async {
    final controller = DeviceController(
      FakeDevice(random: Random(5)),
      store: store ?? _week(),
    );
    await tester.pumpWidget(
      BileklikApp(
        controller: controller,
        settings: AppSettings.memory(language: lang),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => AiReportScreen(
              day: _day(6),
              service: const DemoAiReportService(delay: Duration.zero),
              now: () => _day(6),
            ),
          ),
        );
    await tester.pumpAndSettle();
  }

  testWidgets('önce rıza, sonra rapor; rıza geri alınabilir', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester);

    expect(find.text(_tr.aiConsentTitle), findsOneWidget);
    // Kutu işaretlenmeden izin verilemez.
    await tester.tap(find.text(_tr.aiConsentAccept));
    await tester.pumpAndSettle();
    expect(find.text(_tr.aiConsentTitle), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      200,
      scrollable: _list,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr.aiConsentAccept));
    await tester.pumpAndSettle();

    expect(find.text(_tr.aiGenerate), findsOneWidget);
    await tester.tap(find.text(_tr.aiGenerate));
    await tester.pumpAndSettle();
    expect(find.text(_tr.aiSummaryGood), findsOneWidget);
    expect(find.text(_tr.aiDemoNote), findsOneWidget);
    expect(find.text(_tr.aiRegenerate), findsOneWidget);

    await tester.tap(find.byTooltip(_tr.aiRevoke));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr.aiRevoke));
    await tester.pumpAndSettle();
    expect(find.text(_tr.aiConsentTitle), findsOneWidget);
    expect(find.text(_tr.aiRevoked), findsOneWidget);
  });

  testWidgets('veri yoksa boş durum', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, store: MemoryHealthStore());
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      200,
      scrollable: _list,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr.aiConsentAccept));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_tr.aiGenerate));
    await tester.pumpAndSettle();
    expect(find.text(_tr.aiEmpty), findsOneWidget);
  });

  for (final lang in ['tr', 'en', 'ar', 'de']) {
    testWidgets('$lang: rıza ve rapor 320 dp büyük yazıda taşmaz', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 1920);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final l = lookupAppLocalizations(Locale(lang));
      await open(tester, lang: lang, store: _week(steps: 3000, sleep: 300));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        200,
        scrollable: _list,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.aiConsentAccept));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.aiGenerate));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l.aiSummaryCare),
        200,
        scrollable: _list,
      );
      expect(find.text(l.aiSummaryCare), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
