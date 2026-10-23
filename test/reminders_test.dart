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

/// Cihaz ekranında "Hatırlatıcılar" satırını görünür yapıp açar.
Future<void> _openReminders(WidgetTester tester) async {
  final row = find.text('Hatırlatıcılar');
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
}

FakeDevice _device() => FakeDevice(
  random: Random(3),
  realtimeInterval: const Duration(seconds: 30),
);

void main() {
  group('protokol', () {
    test('0x23 kaydı: 23 XX AA BB CC DD EE FF GG T1…T30', () {
      const r = Reminder(
        kind: ReminderKind.medication,
        minuteOfDay: 8 * 60 + 30,
        weekdays: 0x3E,
        label: 'Ab',
      );
      final b = encodeReminder(r, index: 1, total: 2);
      expect(b.length, 39);
      expect(b.sublist(0, 11), hex('23 02 01 01 02 08 30 3E 02 41 62'));
      expect(decodeReminder(b), r);
    });

    test('0x57 kaydı: 57 ID1 ID2 AA BB CC DD EE FF T1…T30', () {
      // Belgedeki düzen: okuma no, sıra, tür (0 kapalı), saat, dakika,
      // günler, etiket uzunluğu.
      final b = hex(
        '57 03 00 02 03 23 59 7F 02 41 62 ${List.filled(28, '00').join(' ')}',
      );
      final s = decodeStoredReminder(b);
      expect(s.index, 2);
      expect(s.kind, ReminderKind.water);
      expect(s.minuteOfDay, 23 * 60 + 59);
      expect(s.weekdays, 0x7F);
      expect(s.label, 'Ab');

      // Kapalı kayıt: tür baytı 0; tür ve tam etiket bilinen listeden gelir.
      b[4] = 0;
      final off = decodeStoredReminder(b);
      expect(off.enabled, isFalse);
      const known = Reminder(
        kind: ReminderKind.water,
        minuteOfDay: 0,
        label: 'Âb',
      );
      final r = off.toReminder(known: known);
      expect(r.kind, ReminderKind.water);
      expect(r.enabled, isFalse);
      expect(r.label, 'Âb');
      expect(off.toReminder().kind, ReminderKind.medication);

      b[5] = 0x25;
      expect(() => decodeStoredReminder(b), throwsFormatException);
    });

    test('etiket ASCII: Türkçe harfler çevrilir, diğerleri atlanır', () {
      expect(asciiLabel('Şeker ilacı'), 'Seker ilaci');
      expect(asciiLabel('Größe'), 'Grosse');
      expect(asciiLabel('دواء'), '');
      expect(reminderLabelBytes('a' * 40), hasLength(30));
      expect(reminderLabelBytes('ğüşiöç').every((b) => b < 0x80), isTrue);
    });

    test('0x23 liste paket boyuna göre bölünür, sonda 23 FF', () {
      final five = [
        for (var i = 0; i < 5; i++)
          Reminder(kind: ReminderKind.water, minuteOfDay: 8 * 60 + i * 60),
      ];
      // 244 bayt: 6 kayıt sığar; tek parça ve sonunda 23 FF.
      final one = setRemindersCommand(five);
      expect(one, hasLength(1));
      expect(one.single.length, 5 * 39 + 2);
      expect(one.single.sublist(one.single.length - 2), hex('23 FF'));
      expect(one.single[1], 5, reason: 'XX: toplam kayıt');
      expect(one.single[39 + 2], 1, reason: 'AA: ikinci kaydın sırası');

      // 100 bayt: parça başına 2 kayıt.
      final parts = setRemindersCommand(five, maxPacket: 100);
      expect(parts.map((p) => p.length), [78, 78, 41]);
      expect(parts.every((p) => p.length <= 100), isTrue);

      // 78 bayt: bitiş işareti ayrı parça.
      final tight = setRemindersCommand(five.take(2).toList(), maxPacket: 78);
      expect(tight.map((p) => p.length), [78, 2]);

      expect(() => setRemindersCommand(const []), throwsArgumentError);
      expect(
        () => setRemindersCommand([...five, five.first]),
        throwsArgumentError,
      );
    });

    test('0x23 onayı: 23 R1 23 R2 … 23 EE', () {
      expect(remindersSavedIn(hex('23 00 23 01 23 EE')), isTrue);
      expect(remindersSavedIn(hex('23 00 23 01')), isFalse);
      expect(remindersSavedIn(hex('23 EE')), isTrue);
    });

    test('0x57 okuma ve silme paketleri', () {
      expect(getRemindersCommand().bytes.sublist(0, 2), hex('57 00'));
      expect(deleteRemindersCommand().bytes.sublist(0, 2), hex('57 99'));
      final p = deleteRemindersCommand().bytes;
      expect(p.last, Packet.crc(p));
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
        Reminder(kind: ReminderKind.water, minuteOfDay: 11 * 60, enabled: false),
      ];
      await client.setReminders(list);
      final stored = await client.getReminders();
      expect(stored.map((s) => s.index), [0, 1]);
      expect(stored.first.label, 'Sabah ilaci');
      expect(stored.last.kind, isNull, reason: 'kapalı kayıt');
      expect(stored.map((s) => s.minuteOfDay), [9 * 60, 11 * 60]);
      await client.setReminders(const []);
      expect(device.reminders, isEmpty);
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
      ]).single.toList();
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
      expect(c.remindersFailed, isFalse);

      final ok = await c.saveReminders(const [
        Reminder(
          kind: ReminderKind.water,
          minuteOfDay: 8 * 60,
          enabled: false,
          label: 'Öğle',
        ),
      ]);
      expect(ok, isTrue);
      expect(device.reminders.single.minuteOfDay, 8 * 60);
      expect(device.reminders.single.label, 'Ogle');

      // Geri okununca kapalı kaydın türü ve tam etiket korunur.
      await c.reloadDeviceSettings();
      expect(c.reminders!.single.kind, ReminderKind.water);
      expect(c.reminders!.single.label, 'Öğle');
      expect(c.reminders!.single.enabled, isFalse);

      // Sınır aşılırsa yazılmaz.
      final tooMany = [
        for (var i = 0; i <= Reminder.maxCount; i++)
          Reminder(kind: ReminderKind.water, minuteOfDay: i * 60),
      ];
      expect(await c.saveReminders(tooMany), isFalse);
      expect(c.reminders!.length, 1);

      await c.disconnect();
      expect(c.reminders, isNull);
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
    await _openReminders(tester);
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
    await _openReminders(tester);
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

  testWidgets('sınıra ulaşınca ekleme kapanır', (tester) async {
    final (c, device) = await openScreen(tester);
    await tester.runAsync(
      () => c.saveReminders([
        for (var i = 0; i < Reminder.maxCount; i++)
          Reminder(kind: ReminderKind.water, minuteOfDay: 8 * 60 + i * 60),
      ]),
    );
    await _openReminders(tester);
    await tester.pumpAndSettle();
    final add = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('İlaç saati ekle'),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
    );
    expect(add.onPressed, isNull);
    await tester.scrollUntilVisible(
      find.text('Bileklik en fazla 5 hatırlatıcı tutabilir.'),
      200,
    );
    expect(
      find.text('Bileklik en fazla 5 hatırlatıcı tutabilir.'),
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
