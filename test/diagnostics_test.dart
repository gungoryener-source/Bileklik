import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/device_log.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/transport.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/device_screen.dart';
import 'package:bileklik/ui/screens/diagnostics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FakeDevice _device() => FakeDevice(
  random: Random(3),
  realtimeInterval: const Duration(seconds: 30),
);

void main() {
  group('kayıt', () {
    test('onaltılık yazım ve okuma', () {
      expect(hexBytes([0x13, 0, 0xff]), '13 00 FF');
      expect(parseHex('13 00 ff'), [0x13, 0, 0xff]);
      expect(parseHex('0x13,0x01'), [0x13, 0x01]);
      expect(parseHex('130'), isNull);
      expect(parseHex('zz'), isNull);
      expect(parseHex(''), isNull);
    });

    test('kapasite aşılınca en eskiler düşer', () {
      final log = DeviceLog(capacity: 3);
      for (var i = 0; i < 5; i++) {
        log.event('$i');
      }
      expect(log.entries.map((e) => e.text), ['2', '3', '4']);
      expect(log.export(header: 'H').split('\n').first, 'H');
    });

    test('LoggingTransport giden ve gelen paketleri yazar', () async {
      final log = DeviceLog(capacity: 100000);
      final device = _device();
      final t = LoggingTransport(device, log);
      final c = DeviceController(t, store: MemoryHealthStore(), log: log);
      await c.connect();
      expect(log.entries.where((e) => e.kind == LogKind.tx), isNotEmpty);
      expect(log.entries.where((e) => e.kind == LogKind.rx), isNotEmpty);
      // Pil isteği ve yanıtı onaltılık olarak görünür.
      expect(
        log.entries.any(
          (e) => e.kind == LogKind.tx && e.text.startsWith('13 '),
        ),
        isTrue,
      );
      expect(
        log.entries.any(
          (e) => e.kind == LogKind.rx && e.text.startsWith('13 '),
        ),
        isTrue,
      );
      await c.disconnect();
      c.dispose();
      await t.dispose();
      device.dispose();
    });
  });

  group('yeniden bağlanma', () {
    test('kopunca kendiliğinden yeniden bağlanır', () async {
      final device = _device();
      final c = DeviceController(
        device,
        store: MemoryHealthStore(),
        autoReconnect: true,
        reconnectDelays: const [Duration(milliseconds: 20)],
      );
      device.select(const DiscoveredDevice(name: 'JCV8', address: '', rssi: 0));
      await c.start();
      expect(c.isConnected, isTrue);

      device.simulateDropout();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.isConnected, isFalse);
      expect(c.nextReconnect, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(c.isConnected, isTrue);
      await c.disconnect();
      c.dispose();
      device.dispose();
    });

    test(
      'bağlanamazsa artan aralıklarla dener, kullanıcı kesince durur',
      () async {
        final device = _device()..connectError = StateError('GATT 133');
        final c = DeviceController(
          device,
          store: MemoryHealthStore(),
          autoReconnect: true,
          reconnectDelays: const [
            Duration(milliseconds: 10),
            Duration(seconds: 30),
          ],
        );
        device.select(
          const DiscoveredDevice(name: 'JCV8', address: '', rssi: 0),
        );
        await c.start();
        expect(c.isConnected, isFalse);
        // İlk bekleme kısa; ikinci deneme de başarısız olunca 30 sn beklenir.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final next = c.nextReconnect!;
        expect(next.difference(DateTime.now()).inSeconds, greaterThan(20));

        device.connectError = null;
        c.onResumed(); // öne gelince beklemeden dener
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(c.isConnected, isTrue);

        await c.disconnect();
        expect(c.nextReconnect, isNull);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(c.isConnected, isFalse);
        c.dispose();
        device.dispose();
      },
    );

    test('eşleştirme yoksa açılışta bağlanmaz', () async {
      final device = _device();
      final c = DeviceController(
        device,
        store: MemoryHealthStore(),
        autoReconnect: true,
      );
      await c.start();
      expect(c.isConnected, isFalse);
      expect(c.nextReconnect, isNull);
      c.dispose();
      device.dispose();
    });
  });

  group('ekran', () {
    Future<(DeviceController, List<String>)> open(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final log = DeviceLog(capacity: 100000);
      final device = _device();
      final c = DeviceController(
        LoggingTransport(device, log),
        store: MemoryHealthStore(),
        log: log,
      );
      final shared = <String>[];
      await tester.pumpWidget(
        BileklikApp(
          controller: c,
          settings: AppSettings.memory(language: 'tr'),
        ),
      );
      await tester.runAsync(() async {
        device.select(
          const DiscoveredDevice(name: 'JCV8', address: '', rssi: 0),
        );
        await c.connect();
      });
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const DeviceScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bağlantı tanılama'));
      await tester.pumpAndSettle();
      // Paylaşımı yakalamak için ekranı aynı denetleyiciyle yeniden aç.
      nav.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DiagnosticsScreen(share: (t) async => shared.add(t)),
        ),
      );
      await tester.pumpAndSettle();
      return (c, shared);
    }

    final list = find.descendant(
      of: find.byType(DiagnosticsScreen),
      matching: find.byType(Scrollable),
    );
    Future<void> reveal(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: list.first);
      await tester.pumpAndSettle();
    }

    testWidgets('durum, test komutu ve kayıt paylaşımı', (tester) async {
      final (c, shared) = await open(tester);
      expect(find.text('Gerçek bileklik'), findsOneWidget);
      expect(find.text('Bağlı'), findsOneWidget);

      final before = c.log.entries.length;
      await reveal(tester, find.text('Sürüm'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Sürüm'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      final added = c.log.entries.skip(before);
      expect(added.any((e) => e.text.startsWith('27 ')), isTrue);

      await tester.tap(find.byTooltip('Kaydı paylaş'));
      await tester.pump();
      expect(shared.single, contains('Bileklik BLE kaydı'));
      expect(shared.single, contains('>> 27 '));
    });

    testWidgets('ham komut doğrulanır ve CRC eklenir', (tester) async {
      final (c, _) = await open(tester);
      final field = find.byType(TextField);
      await reveal(tester, field);
      await tester.enterText(field, 'XY');
      await tester.tap(find.text('Gönder'));
      await tester.pump();
      expect(
        find.text('Geçerli onaltılık bayt yazın (en çok 15).'),
        findsOneWidget,
      );

      await tester.enterText(field, '14 0a');
      await tester.runAsync(() async {
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      // 14 0A + 13 sıfır + CRC (0x14 + 0x0A = 0x1E).
      final want = '14 0A ${List.filled(13, '00').join(' ')} 1E';
      expect(
        c.log.entries.any((e) => e.kind == LogKind.tx && e.text == want),
        isTrue,
      );
    });

    testWidgets('demo kipi anahtarı tercihe yazılır', (tester) async {
      await open(tester);
      final sw = find.text('Demo kipi (sahte bileklik)');
      await reveal(tester, sw);
      await tester.runAsync(() async {
        await tester.tap(sw);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(DeviceController.demoModeKey), isTrue);
      expect(find.text('Uygulamayı kapatıp yeniden açın.'), findsOneWidget);
    });
  });
}
