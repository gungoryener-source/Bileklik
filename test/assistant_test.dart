import 'dart:math';

import 'package:bileklik/data/assistant.dart';
import 'package:bileklik/data/ecg_analysis.dart';
import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/l10n/app_localizations.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/assistant_replies.dart';
import 'package:bileklik/ui/screens/assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime(2026, 11, 26);

AssistantFacts _facts({int? recovery = 82}) => AssistantFacts(
  day: _day,
  sleepMinutes: 7 * 60 + 20,
  sleepStart: DateTime(2026, 11, 25, 23, 10),
  sleepEnd: DateTime(2026, 11, 26, 6, 50),
  sleepScore: 84,
  sleepEfficiency: 93,
  sleepDebtMinutes: 0,
  recovery: recovery,
  hrv: 48,
  hrvBaseline: 44,
  restingHeartRate: 58,
  restingBaseline: 60,
  stress: 32,
  strain: 8.4,
  strainOptimal: (10, 14),
  steps: 6400,
  averageHeartRate: 72,
  minHeartRate: 52,
  maxHeartRate: 141,
  ecgTime: DateTime(2026, 11, 24, 9),
  ecgState: FindingState.ok,
  age: 40,
  biologicalAge: 36,
  bioAgeDays: 21,
  workouts7: 3,
  workoutMinutes7: 125,
);

class _Remote implements AssistantService {
  _Remote(this.answer);
  final String? answer;
  List<ChatMessage>? history;
  AssistantFacts? facts;

  @override
  Future<String?> reply(
    List<ChatMessage> history,
    AssistantFacts facts,
    String language,
  ) async {
    this.history = [...history];
    this.facts = facts;
    return answer;
  }
}

void main() {
  group('konu bulma', () {
    test('dört dilde uyku', () {
      for (final q in [
        'Dün gece uykum nasıldı?',
        'How did I sleep last night?',
        'Wie habe ich letzte Nacht geschlafen?',
        'كيف كان نومي الليلة الماضية؟',
      ]) {
        final t = AssistantIntents.of(q);
        expect(t, contains(AssistantTopic.sleep), reason: q);
        expect(t, isNot(contains(AssistantTopic.medication)), reason: q);
      }
    });

    test('acil belirti ve ilaç', () {
      expect(
        AssistantIntents.of('Göğsümde ağrı var, nefes darlığı çekiyorum'),
        contains(AssistantTopic.emergency),
      );
      expect(
        AssistantIntents.of('I have chest pain'),
        contains(AssistantTopic.emergency),
      );
      expect(
        AssistantIntents.of('Hangi ilacı almalıyım?'),
        contains(AssistantTopic.medication),
      );
    });
  });

  group('çevrimdışı yanıt', () {
    final l = lookupAppLocalizations(const Locale('tr'));

    test('uyku verisiyle', () {
      final r = offlineReply('Dün gece uykum nasıldı?', _facts(), l);
      expect(r, contains('23:10'));
      expect(r, contains('84/100'));
    });

    test('acil durumda önce 112, başka bir şey yok', () {
      final r = offlineReply('göğüs ağrım var, uykum da kötü', _facts(), l);
      expect(r, l.asstEmergency);
    });

    test('ilaç sorusunda teşhis yok', () {
      final r = offlineReply('Nabzım için ilaç önerir misin?', _facts(), l);
      expect(r, startsWith(l.asstNoDiagnosis));
      expect(r, contains('72'));
    });

    test('antrenman toparlanmaya göre', () {
      expect(
        offlineReply('antrenman programı', _facts(recovery: 20), l),
        startsWith(l.asstTrainingLow),
      );
      expect(
        offlineReply('antrenman programı', _facts(recovery: 90), l),
        startsWith(l.asstTrainingHigh),
      );
    });

    test('rapor birden çok başlık içerir', () {
      final r = offlineReply('Bugünün sağlık raporu', _facts(), l);
      expect(r, contains('•'));
      expect(r, contains('82/100'));
      expect(r, contains('6400'));
    });

    test('anlaşılmayan soru', () {
      expect(offlineReply('qwerty', _facts(), l), l.asstUnknown);
    });

    test('veri yoksa söyler', () {
      final r = offlineReply('uykum nasıl', AssistantFacts(day: _day), l);
      expect(r, l.asstNoData);
    });
  });

  test('sunucuya giden veride kimlik yok', () {
    final json = _facts().toJson();
    expect(json['sleep_start'], '23:10');
    expect(
      json.keys.any((k) => k.contains('name') || k.contains('id')),
      isFalse,
    );
  });

  group('ekran', () {
    Future<DeviceController> pump(
      WidgetTester tester, {
      AppSettings? settings,
    }) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final device = FakeDevice(random: Random(5));
      final c = DeviceController(device, store: MemoryHealthStore());
      await tester.runAsync(c.connect);
      await tester.pumpWidget(BileklikApp(controller: c, settings: settings));
      await tester.pumpAndSettle();
      addTearDown(() async {
        await tester.runAsync(c.disconnect);
        device.dispose();
      });
      return c;
    }

    void open(WidgetTester tester) => tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const AssistantScreen(typingDelay: Duration.zero),
          ),
        );

    tearDown(() => PortalAssistantService.instance = null);

    testWidgets('hazır soru çevrimdışı yanıtlanır', (tester) async {
      await pump(tester);
      open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Küçük adımlar, büyük fark'), findsOneWidget);
      const q = 'Bugünün sağlık raporunu hazırlar mısın?';
      await tester.tap(find.text(q));
      await tester.pumpAndSettle();
      expect(find.textContaining('için özetiniz'), findsOneWidget);
      expect(find.textContaining('uyudunuz'), findsOneWidget);
    });

    testWidgets('yazılan soru gönderilir', (tester) async {
      await pump(tester);
      open(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'merhaba');
      await tester.tap(find.byTooltip('Gönder'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ben Vita'), findsOneWidget);
    });

    testWidgets('rıza varsa sunucu yanıtı, yoksa telefon', (tester) async {
      final remote = _Remote('Sunucudan yanıt');
      PortalAssistantService.instance = remote;
      final settings = AppSettings.memory();
      await pump(tester, settings: settings);
      open(tester);
      await tester.pumpAndSettle();
      // Rıza yok: sunucu kullanılmaz.
      await tester.enterText(find.byType(TextField), 'merhaba');
      await tester.tap(find.byTooltip('Gönder'));
      await tester.pumpAndSettle();
      expect(remote.history, isNull);

      await settings.setAiConsent(DateTime(2026, 11, 26));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'uykum nasıl?');
      await tester.tap(find.byTooltip('Gönder'));
      await tester.pumpAndSettle();
      expect(find.text('Sunucudan yanıt'), findsOneWidget);
      expect(remote.history!.last.text, 'uykum nasıl?');
    });

    testWidgets('sunucu yanıt vermezse telefonda hazırlanır', (tester) async {
      PortalAssistantService.instance = _Remote(null);
      final settings = AppSettings.memory();
      await settings.setAiConsent(DateTime(2026, 11, 26));
      await pump(tester, settings: settings);
      open(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'merhaba');
      await tester.tap(find.byTooltip('Gönder'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ben Vita'), findsOneWidget);
      expect(
        find.text('Sunucuya ulaşılamadı; bu yanıt telefonda hazırlandı.'),
        findsOneWidget,
      );
    });
  });
}
