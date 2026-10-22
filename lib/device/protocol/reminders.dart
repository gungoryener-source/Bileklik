import 'dart:convert';
import 'dart:typed_data';

import 'packet.dart';

/// Hatırlatıcı komutları.
///
/// V8 API PDF'i bu oturumda elde değildi; bayt düzeni aynı ailenin
/// (J-Style) SDK'sındaki çalar saat ve hareketsizlik komutlarından alındı.
/// Aşağıdaki her alan gerçek cihazda doğrulanacak.
abstract final class ReminderCmd {
  /// 0x23: bilekliğe tüm hatırlatıcıları yazar (öncekilerin yerine geçer).
  static const set = 0x23;

  /// 0x57: bilekliğe kayıtlı hatırlatıcıları okur; `57 99` hepsini siler.
  static const get = 0x57;

  /// 0x25: hareketsizlik uyarısını yazar. ROADMAP yalnızca 0x23/0x57'yi
  /// anıyor; bu kod SDK'dan, gerçek cihazda doğrulanacak.
  static const setSedentary = 0x25;

  /// 0x26: hareketsizlik uyarısını okur (gerçek cihazda doğrulanacak).
  static const getSedentary = 0x26;

  /// Okuma ve silme modları (geçmiş komutlarıyla aynı).
  static const read = 0x00;
  static const deleteAll = 0x99;
}

/// Hatırlatıcı türü; değer 0x23 kaydındaki tür baytıdır (gerçek cihazda
/// doğrulanacak).
enum ReminderKind {
  /// Bilekliğe başka bir uygulamadan yazılmış sıradan çalar saat. Bu
  /// uygulama oluşturmaz ama listeyi yeniden yazarken korur.
  alarm(1),
  medication(2),
  water(3);

  const ReminderKind(this.code);
  final int code;

  static ReminderKind byCode(int code) {
    for (final k in values) {
      if (k.code == code) return k;
    }
    return alarm;
  }
}

/// Bileklikteki tek hatırlatıcı: belirli saatte, seçili günlerde titrer.
class Reminder {
  const Reminder({
    required this.kind,
    required this.minuteOfDay,
    this.enabled = true,
    this.weekdays = allDays,
    this.label = '',
  });

  /// Bit0 pazar ... bit6 cumartesi; 0x7F her gün (0x2A ile aynı düzen).
  static const allDays = 0x7F;

  /// Bileklikte tutulabilen en fazla hatırlatıcı. Gerçek cihazda doğrulanacak.
  static const maxCount = 10;

  /// Etiketin bileklikte kapladığı en fazla bayt (UTF-8). Ekransız bileklik
  /// etiketi göstermez; listeyi geri okuyunca adı kaybolmasın diye yazılır.
  static const maxLabelBytes = 30;

  final ReminderKind kind;
  final bool enabled;

  /// Gece yarısından itibaren dakika (0-1439).
  final int minuteOfDay;
  final int weekdays;

  /// İlaç adı gibi kısa not; boş olabilir.
  final String label;

  bool hasDay(int weekday) => weekdays & (1 << (weekday % 7)) != 0;

  Reminder withDay(int weekday, bool on) {
    final bit = 1 << (weekday % 7);
    return copyWith(weekdays: on ? weekdays | bit : weekdays & ~bit);
  }

  Reminder copyWith({
    ReminderKind? kind,
    bool? enabled,
    int? minuteOfDay,
    int? weekdays,
    String? label,
  }) => Reminder(
    kind: kind ?? this.kind,
    enabled: enabled ?? this.enabled,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    weekdays: weekdays ?? this.weekdays,
    label: label ?? this.label,
  );

  @override
  bool operator ==(Object other) =>
      other is Reminder &&
      other.kind == kind &&
      other.enabled == enabled &&
      other.minuteOfDay == minuteOfDay &&
      other.weekdays == weekdays &&
      other.label == label;

  @override
  int get hashCode => Object.hash(kind, enabled, minuteOfDay, weekdays, label);
}

/// 0x23 ve 0x57 kaydının uzunluğu: komut, toplam, sıra, açık, tür, saat,
/// dakika, günler, etiket uzunluğu ve 30 bayt etiket.
const reminderRecordLength = 9 + Reminder.maxLabelBytes;

/// Etiketi en fazla [Reminder.maxLabelBytes] bayta, harf ortasından
/// bölmeden kısaltır.
List<int> reminderLabelBytes(String label) {
  final out = <int>[];
  for (final rune in label.trim().runes) {
    final b = utf8.encode(String.fromCharCode(rune));
    if (out.length + b.length > Reminder.maxLabelBytes) break;
    out.addAll(b);
  }
  return out;
}

/// Tek kayıt: `cmd NN ID EN TT HH mm WW LL etiket...` (saat BCD).
List<int> encodeReminder(
  Reminder r, {
  required int index,
  required int total,
  int command = ReminderCmd.set,
}) {
  final label = reminderLabelBytes(r.label);
  final out = List<int>.filled(reminderRecordLength, 0);
  out[0] = command;
  out[1] = total;
  out[2] = index;
  out[3] = r.enabled ? 1 : 0;
  out[4] = r.kind.code;
  out[5] = toBcd(r.minuteOfDay ~/ 60);
  out[6] = toBcd(r.minuteOfDay % 60);
  out[7] = r.weekdays & 0x7F;
  out[8] = label.length;
  out.setAll(9, label);
  return out;
}

Reminder decodeReminder(List<int> r) {
  if (r.length < reminderRecordLength) {
    throw const FormatException('Hatırlatıcı kaydı kısa');
  }
  final hour = fromBcd(r[5]);
  final minute = fromBcd(r[6]);
  if (hour > 23 || minute > 59) {
    throw const FormatException('Geçersiz hatırlatıcı saati');
  }
  final len = r[8].clamp(0, Reminder.maxLabelBytes);
  return Reminder(
    kind: ReminderKind.byCode(r[4]),
    enabled: r[3] == 1,
    minuteOfDay: hour * 60 + minute,
    weekdays: r[7] & 0x7F,
    label: utf8.decode(r.sublist(9, 9 + len), allowMalformed: true),
  );
}

/// 0x23: tüm hatırlatıcılar uç uca, sonda `23 FF`. Paket 16 bayttan uzun ve
/// CRC taşımıyor; BLE katmanı MTU'ya göre böler (gerçek cihazda doğrulanacak).
/// Liste boşsa bunun yerine [deleteRemindersCommand] gönderilir.
Uint8List setRemindersCommand(List<Reminder> reminders) {
  if (reminders.isEmpty || reminders.length > Reminder.maxCount) {
    throw ArgumentError.value(reminders.length, 'reminders', '1-10 olmalı');
  }
  return Uint8List.fromList([
    for (var i = 0; i < reminders.length; i++)
      ...encodeReminder(reminders[i], index: i, total: reminders.length),
    ReminderCmd.set,
    0xFF,
  ]);
}

/// 0x57 00: kayıtlı hatırlatıcıları ister.
Packet getRemindersCommand() =>
    Packet.build(ReminderCmd.get, [ReminderCmd.read]);

/// 0x57 99: bileklikteki tüm hatırlatıcıları siler.
Packet deleteRemindersCommand() =>
    Packet.build(ReminderCmd.get, [ReminderCmd.deleteAll]);

/// Hareketsizlik uyarısı: [startMinute]-[endMinute] arasında, seçili
/// günlerde, [intervalMinutes] boyunca [minSteps] adımdan az atılırsa
/// bileklik titrer.
class SedentaryConfig {
  const SedentaryConfig({
    this.enabled = false,
    this.startMinute = 9 * 60,
    this.endMinute = 18 * 60,
    this.weekdays = 0x3E,
    this.intervalMinutes = 60,
    this.minSteps = 50,
  });

  /// Arayüzde sunulan aralıklar (dakika).
  static const intervalChoices = [30, 45, 60, 90, 120];

  final bool enabled;
  final int startMinute;
  final int endMinute;

  /// Bit0 pazar ... bit6 cumartesi; varsayılan hafta içi.
  final int weekdays;
  final int intervalMinutes;
  final int minSteps;

  bool hasDay(int weekday) => weekdays & (1 << (weekday % 7)) != 0;

  SedentaryConfig withDay(int weekday, bool on) {
    final bit = 1 << (weekday % 7);
    return copyWith(weekdays: on ? weekdays | bit : weekdays & ~bit);
  }

  SedentaryConfig copyWith({
    bool? enabled,
    int? startMinute,
    int? endMinute,
    int? weekdays,
    int? intervalMinutes,
  }) => SedentaryConfig(
    enabled: enabled ?? this.enabled,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    weekdays: weekdays ?? this.weekdays,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    minSteps: minSteps,
  );

  /// `HH mm HH mm WW AA SS EN`: saatler BCD, aralık dakika, adım eşiği.
  /// Alan sırası gerçek cihazda doğrulanacak.
  List<int> toBytes() => [
    toBcd(startMinute ~/ 60),
    toBcd(startMinute % 60),
    toBcd(endMinute ~/ 60),
    toBcd(endMinute % 60),
    weekdays & 0x7F,
    intervalMinutes & 0xFF,
    minSteps & 0xFF,
    enabled ? 1 : 0,
  ];

  static SedentaryConfig fromBytes(List<int> d) => SedentaryConfig(
    startMinute: fromBcd(d[0]) * 60 + fromBcd(d[1]),
    endMinute: fromBcd(d[2]) * 60 + fromBcd(d[3]),
    weekdays: d[4] & 0x7F,
    intervalMinutes: d[5] == 0 ? 60 : d[5],
    minSteps: d[6],
    enabled: d[7] == 1,
  );

  @override
  bool operator ==(Object other) =>
      other is SedentaryConfig &&
      other.enabled == enabled &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.weekdays == weekdays &&
      other.intervalMinutes == intervalMinutes &&
      other.minSteps == minSteps;

  @override
  int get hashCode => Object.hash(
    enabled,
    startMinute,
    endMinute,
    weekdays,
    intervalMinutes,
    minSteps,
  );
}

Packet setSedentaryCommand(SedentaryConfig c) =>
    Packet.build(ReminderCmd.setSedentary, c.toBytes());

Packet getSedentaryCommand() => Packet.build(ReminderCmd.getSedentary);
