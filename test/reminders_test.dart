import 'dart:math';

import 'package:bileklik/data/health_store.dart';
import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/device/protocol/packet.dart';
import 'package:bileklik/device/protocol/reminders.dart';
import 'package:bileklik/device/wristband_client.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/app_settings.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:bileklik/ui/screens/device_screen.dart';
import 'package:bileklik/ui/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) =>
    s.split(' ').map((b) => int.parse(b, radix: 16)).toList();

FakeDevice _device() => FakeDevice(
  random: Random(3),
  realtimeInterval: const Duration(seconds: 30),
);

void main() {
  group('protokol', () {
    test('0x23 kaydı: saat BCD, günler, etiket', () {
      const r = Reminder(
        kind: ReminderKind.medication,
        minuteOfDay: 8 * 60 + 30,
        weekdays: 0x3E,
        label: 'Ab',
      );
      final b = encodeReminder(r, index: 1, total: 2);
      expect(b.length, reminderRecordLength);
      expect(b.sublist(0, 11), hex('23 02 01 01 02 08 30 3E 02 41 62'));
      expect(decodeReminder(b), r);
    });

    test('0x23 tüm liste: kayıtlar uç uca, sonda 23 FF', () {
      final bytes = setRemindersCommand(const [
        Reminder(kind: ReminderKind.water, minuteOfDay: 10 * 60),
        Reminder(kind: ReminderKind.water, minuteOfDay: 14 * 60),
      ]);
      expect(bytes.length, reminderRecordLength * 2 + 2);
      expect(bytes.sublist(bytes.length - 2), hex('23 FF'));
      expect(() => setRemindersCommand(const []), throwsArgumentError);
    });

    test('etiket 30 bayta harf bölünmeden kısalır', () {
      final label = 'ğ' * 20; // her biri 2 bayt
      expect(reminderLabelBytes(label).length, 30);
      final r = decodeReminder(
        encodeReminder(
          Reminder(
            kind: ReminderKind.medication,
            minuteOfDay: 0,
            label: '${'a' * 29}ş',
          ),
          index: 0,
          total: 1,
        ),
      );
      expect(r.label, 'a' * 29);
    });

    test('bilinmeyen tür çalar saat sayılır, bozuk saat reddedilir', () {
      final b = encodeReminder(
        const Reminder(kind: ReminderKind.water, minuteOfDay: 60),
        index: 0,
        total: 1,
      );
      b[4] = 9;
      expect(decodeReminder(b).kind, ReminderKind.alarm);
      b[5] = 0x25;
      expect(() => decodeReminder(b), throwsFormatException);
    });

    test('0x57 okuma ve silme paketleri', () {
      expect(getRemindersCommand().bytes.sublist(0, 2), hex('57 00'));
      expect(deleteRemindersCommand().bytes.sublist(0, 2), hex('57 99'));
      final p = deleteRemindersCommand().bytes;
      expect(p.last, Packet.crc(p));
    });

    test('0x25 hareketsizlik: 09:00-18:00 hafta içi, 60 dk, 50 adım', () {
      const c = SedentaryConfig(enabled: true);
      expect(
        setSedentaryCommand(c).bytes.sublist(0, 9),
        hex('25 09 00 18 00 3E 3C 32 01'),
      );
      expect(SedentaryConfig.fromBytes(c.toBytes()), c);
    });
  });

  group('sahte bileklik', () {
    test('liste yazılır, geri okunur ve silinir', () async {
      final device = _device();
      final client = WristbandClient(device);
      await device.connect();
      expect(await client.getReminders(), isEmpty);
      const list = [
        Reminder(
          kind: ReminderKind.medication,
          minuteOfDay: 9 * 60,
          label: 'Sabah ilacı',
        ),
        Reminder(kind: ReminderKind.water, minuteOfDay: 11 * 60),
      ];
      await client.setReminders(list);
      expect(await client.getReminders(), list);
      await client.setReminders(const []);
      expect(device.reminders, isEmpty);

      await client.setSedentary(const SedentaryConfig(enabled: true));
      expect((await client.getSedentary()).enabled, isTrue);
      await device.disconnect();
      await client.dispose();
      device.dispose();
    });

    test('bozuk liste reddedilir, eski liste kalır', () async {
      final device = _device();
      final client = WristbandClient(device);
      await device.connect();
      device.reminders.add(
        const Reminder(kind: ReminderKind.water, minuteOfDay: 600),
      );
      final bad = setRemindersCommand(const [
        Reminder(kind: ReminderKind.water, minuteOfDay: 60),
      ]).toList();
      bad[5] = 0x25; // saat 25
      final replies = <List<int>>[];
      final sub = device.incoming.listen(replies.add);
      await device.send(bad);
      await Future<void>.delayed(Duration.zero);
      expect(replies.single.first, 0xA3);
      expect(device.reminders.single.minuteOfDay, 600);
      await sub.cancel();
      await device.disconnect();
      await client.dispose();
      device.dispose();
    });
  });

  group('denetleyici', () {
    test('bağlanınca okunur, kaydedilir, bağlantı kesilince boşalır', () async {
      final device = _device();
      final c = DeviceController(device, store: MemoryHealthStore());
      await c.connect();
      expect(c.reminders, isEmpty);
      expect(c.sedentary, const SedentaryConfig());
      expect(c.remindersFailed, isFalse);

      final ok = await c.saveReminders(const [
        Reminder(kind: ReminderKind.medication, minuteOfDay: 8 * 60),
      ]);
      expect(ok, isTrue);
      expect(device.reminders.single.minuteOfDay, 8 * 60);
      expect(
        await c.saveSedentary(const SedentaryConfig(enabled: true)),
        isTrue,
      );
      expect(device.sedentary.enabled, isTrue);

      // Sınır aşılırsa yazılmaz.
      final tooMany = [
        for (var i = 0; i <= Reminder.maxCount; i++)
          Reminder(kind: ReminderKind.water, minuteOfDay: i * 60),
      ];
      expect(await c.saveReminders(tooMany), isFalse);
      expect(c.reminders!.length, 1);

      await c.disconnect();
      expect(c.reminders, isNull);
      expect(c.sedentary, isNull);
      device.dispose();
    });

    test('bileklik reddedince eski liste geri gelir', () async {
      final device = _device();
      final c = DeviceController(device, store: MemoryHealthStore());
      await c.connect();
      // Saat 24:00 geçersiz; sahte bileklik hata döner.
      final ok = await c.saveReminders(const [
        Reminder(kind: ReminderKind.water, minuteOfDay: 24 * 60),
      ]);
      expect(ok, isFalse);
      expect(c.reminders, isEmpty);
      await c.disconnect();
      device.dispose();
    });
  });

  Future<(DeviceController, FakeDevice)> openScreen(
    WidgetTester tester, {
    String language = 'tr',
    Size size = const Size(1080, 2340),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final device = _device();
    final c = DeviceController(device, store: MemoryHealthStore());
    await tester.pumpWidget(
      BileklikApp(
        controller: c,
        settings: AppSettings.memory(language: language),
      ),
    );
    await tester.runAsync(() => c.connect());
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const DeviceScreen()));
    await tester.pumpAndSettle();
    return (c, device);
  }

  testWidgets('ilaç saati eklenir, kapatılır ve silinir', (tester) async {
    final (c, device) = await openScreen(tester);
    expect(find.text('Hatırlatıcı yok'), findsOneWidget);
    await tester.tap(find.text('Hatırlatıcılar'));
    await tester.pumpAndSettle();
    expect(find.byType(RemindersScreen), findsOneWidget);
    expect(
      find.text('İlaç saatlerinizi ekleyin; bileklik o saatte titrer.'),
      findsOneWidget,
    );

    await tester.tap(find.text('İlaç saati ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni ilaç hatırlatıcısı'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tansiyon');
    await tester.runAsync(() async {
      await tester.tap(find.text('Kaydet'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.reminders.single.label, 'Tansiyon');
    expect(device.reminders.single.kind, ReminderKind.medication);
    expect(find.textContaining('09:00'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byType(Switch).first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.reminders.single.enabled, isFalse);

    await tester.tap(find.textContaining('09:00'));
    await tester.pumpAndSettle();
    expect(find.text('Hatırlatıcıyı düzenle'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Sil'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.reminders, isEmpty);
    expect(c.reminders, isEmpty);

    await tester.runAsync(() => c.disconnect());
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Hatırlatıcıları görmek ve değiştirmek için bilekliği bağlayın.',
      ),
      findsOneWidget,
    );
    device.dispose();
  });

  testWidgets('aynı saatte ikinci su hatırlatıcısı eklenmez', (tester) async {
    final (c, device) = await openScreen(tester);
    await tester.runAsync(
      () => c.saveReminders(const [
        Reminder(kind: ReminderKind.water, minuteOfDay: 10 * 60),
      ]),
    );
    await tester.tap(find.text('Hatırlatıcılar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Su saati ekle'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bu saatte aynı türde bir hatırlatıcı zaten var.'),
      findsOneWidget,
    );
    expect(device.reminders.length, 1);
    await tester.runAsync(() => c.disconnect());
    device.dispose();
  });

  testWidgets('hareketsizlik uyarısı açılır, süre seçilir', (tester) async {
    final (c, device) = await openScreen(tester);
    await tester.tap(find.text('Hatırlatıcılar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Hareketsizlik uyarısı'), 200);
    await tester.runAsync(() async {
      await tester.tap(find.text('Hareketsizlik uyarısı'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.sedentary.enabled, isTrue);
    expect(
      find.text('1 saat boyunca kıpırdamazsanız bileklik titrer.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Hareketsiz kalma süresi'), 200);
    await tester.tap(find.text('Hareketsiz kalma süresi'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('45 dakika'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(device.sedentary.intervalMinutes, 45);
    await tester.runAsync(() => c.disconnect());
    device.dispose();
  });

  testWidgets('sınıra ulaşınca ekleme kapanır', (tester) async {
    final (c, device) = await openScreen(tester);
    await tester.runAsync(
      () => c.saveReminders([
        for (var i = 0; i < Reminder.maxCount; i++)
          Reminder(kind: ReminderKind.water, minuteOfDay: 8 * 60 + i * 60),
      ]),
    );
    await tester.tap(find.text('Hatırlatıcılar'));
    await tester.pumpAndSettle();
    final add = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('İlaç saati ekle'),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
    );
    expect(add.onPressed, isNull);
    await tester.scrollUntilVisible(
      find.text('Bileklik en fazla 10 hatırlatıcı tutabilir.'),
      200,
    );
    expect(
      find.text('Bileklik en fazla 10 hatırlatıcı tutabilir.'),
      findsOneWidget,
    );
    await tester.runAsync(() => c.disconnect());
    device.dispose();
  });

  for (final lang in ['ar', 'de', 'en']) {
    testWidgets('$lang: hatırlatıcılar 320 dp\'de taşmaz', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (c, device) = await openScreen(
        tester,
        language: lang,
        size: const Size(960, 1920),
      );
      await tester.runAsync(() async {
        await c.saveReminders(const [
          Reminder(
            kind: ReminderKind.medication,
            minuteOfDay: 21 * 60 + 45,
            weekdays: 0x15,
            label: 'Çok uzun bir ilaç adı yazıldı',
          ),
          Reminder(kind: ReminderKind.water, minuteOfDay: 10 * 60),
          Reminder(kind: ReminderKind.alarm, minuteOfDay: 7 * 60),
        ]);
        await c.saveSedentary(
          const SedentaryConfig(
            enabled: true,
            startMinute: 22 * 60,
            endMinute: 6 * 60,
            intervalMinutes: 90,
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(builder: (_) => const RemindersScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => c.disconnect());
      device.dispose();
    });
  }
}
