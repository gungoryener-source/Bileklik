import 'dart:typed_data';

import 'packet.dart';

/// Hatırlatıcı komutları (V8 API V1.2 "Set alarm" ve "Read alarm").
///
/// Bileklik ekransız olduğu için hatırlatıcı titreşimle gelir. Aynı listede
/// sıradan çalar saat, ilaç ve su hatırlatıcısı tutulur; en fazla 5 kayıt.
abstract final class ReminderCmd {
  /// 0x23: bilekliğe tüm hatırlatıcıları yazar (öncekilerin yerine geçer).
  static const set = 0x23;

  /// 0x57: bilekliğe kayıtlı hatırlatıcıları okur; `57 99` hepsini siler.
  static const get = 0x57;

  /// Okuma ve silme modları.
  static const read = 0x00;
  static const deleteAll = 0x99;

  /// 0x23 yanıtındaki `23 EE`: liste alındı ve kaydediliyor.
  static const saved = 0xEE;
}

/// Hatırlatıcı türü; değer 0x23'teki tür baytı (CC) ve 0x57'deki tür
/// baytıdır (BB; 0x57'de 0 kapalı demektir).
enum ReminderKind {
  /// Bilekliğe başka bir uygulamadan yazılmış sıradan çalar saat. Bu
  /// uygulama oluşturmaz ama listeyi yeniden yazarken korur.
  alarm(1),
  medication(2),
  water(3);

  const ReminderKind(this.code);
  final int code;

  static ReminderKind? byCode(int code) {
    for (final k in values) {
      if (k.code == code) return k;
    }
    return null;
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

  /// Bit0 pazar ... bit6 cumartesi; 0x7F her gün.
  static const allDays = 0x7F;

  /// Bileklikte tutulabilen en fazla hatırlatıcı (indeks 0-4).
  static const maxCount = 5;

  /// Etiketin bileklikte kapladığı en fazla bayt (ASCII). Ekransız bileklik
  /// etiketi göstermez; listeyi geri okuyunca adı kaybolmasın diye yazılır.
  static const maxLabelBytes = 30;

  final ReminderKind kind;
  final bool enabled;

  /// Gece yarısından itibaren dakika (0-1439).
  final int minuteOfDay;
  final int weekdays;

  /// İlaç adı gibi kısa not; boş olabilir. Uygulamada tam hali tutulur,
  /// bilekliğe ASCII karşılığı yazılır ([reminderLabelBytes]).
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

/// 0x23 ve 0x57 kaydının uzunluğu: 9 baytlık başlık ve 30 bayt etiket.
///
/// 0x23: `23 XX AA BB CC DD EE FF GG T1…T30` (toplam, sıra, açık, tür, saat,
/// dakika, günler, etiket uzunluğu). 0x57: `57 ID1 ID2 AA BB CC DD EE FF
/// T1…T30` (okuma no, sıra, tür, saat, dakika, günler, etiket uzunluğu).
const reminderRecordLength = 9 + Reminder.maxLabelBytes;

/// Türkçe ve Almanca harflerin ASCII karşılıkları.
const _ascii = {
  'ç': 'c', 'Ç': 'C', 'ğ': 'g', 'Ğ': 'G', 'ı': 'i', 'İ': 'I', 'ö': 'o',
  'Ö': 'O', 'ş': 's', 'Ş': 'S', 'ü': 'u', 'Ü': 'U', 'ä': 'a', 'Ä': 'A',
  'ß': 'ss', 'â': 'a', 'î': 'i', 'û': 'u', 'é': 'e', 'è': 'e',
};

/// Etiketin bilekliğe yazılan ASCII hali, en fazla
/// [Reminder.maxLabelBytes] bayt. Karşılığı olmayan harfler (ör. Arapça)
/// atlanır.
String asciiLabel(String label) {
  final out = StringBuffer();
  for (final rune in label.trim().runes) {
    final ch = String.fromCharCode(rune);
    final a = rune >= 0x20 && rune < 0x7F ? ch : _ascii[ch];
    if (a == null) continue;
    if (out.length + a.length > Reminder.maxLabelBytes) break;
    out.write(a);
  }
  return out.toString().trim();
}

List<int> reminderLabelBytes(String label) => asciiLabel(label).codeUnits;

/// 0x23 kaydı (saat BCD).
List<int> encodeReminder(
  Reminder r, {
  required int index,
  required int total,
}) {
  final label = reminderLabelBytes(r.label);
  final out = List<int>.filled(reminderRecordLength, 0);
  out[0] = ReminderCmd.set;
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

/// 0x23 kaydını çözer (sahte bileklik ve testler için). Etiket ASCII'dir.
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
    kind: ReminderKind.byCode(r[4]) ?? ReminderKind.alarm,
    enabled: r[3] == 1,
    minuteOfDay: hour * 60 + minute,
    weekdays: r[7] & 0x7F,
    label: String.fromCharCodes(r.sublist(9, 9 + len)),
  );
}

/// 0x57 ile okunan kayıt. Kapalı hatırlatıcının türü bileklikte tutulmaz
/// (tür baytı 0 olur); [kind] o durumda null'dır.
class StoredReminder {
  const StoredReminder({
    required this.index,
    required this.kind,
    required this.minuteOfDay,
    required this.weekdays,
    required this.label,
  });

  final int index;
  final ReminderKind? kind;
  final int minuteOfDay;
  final int weekdays;
  final String label;

  bool get enabled => kind != null;

  /// Uygulamadaki hatırlatıcı. Kapalı kaydın türü ve etiketin tam hali
  /// (ASCII'ye çevrilmeden önceki) [known] varsa ondan alınır.
  Reminder toReminder({Reminder? known}) {
    final fullLabel = known != null && asciiLabel(known.label) == label
        ? known.label
        : label;
    return Reminder(
      kind: kind ?? known?.kind ?? ReminderKind.medication,
      enabled: enabled,
      minuteOfDay: minuteOfDay,
      weekdays: weekdays,
      label: fullLabel,
    );
  }
}

/// 0x57 kaydını çözer.
StoredReminder decodeStoredReminder(List<int> r) {
  if (r.length < reminderRecordLength) {
    throw const FormatException('Hatırlatıcı kaydı kısa');
  }
  final hour = fromBcd(r[5]);
  final minute = fromBcd(r[6]);
  if (hour > 23 || minute > 59) {
    throw const FormatException('Geçersiz hatırlatıcı saati');
  }
  final len = r[8].clamp(0, Reminder.maxLabelBytes);
  return StoredReminder(
    index: r[3],
    // Bilinmeyen tür kodu sıradan çalar saat sayılır.
    kind: r[4] == 0 ? null : ReminderKind.byCode(r[4]) ?? ReminderKind.alarm,
    minuteOfDay: hour * 60 + minute,
    weekdays: r[7] & 0x7F,
    label: String.fromCharCodes(
      r.sublist(9, 9 + len).where((b) => b >= 0x20 && b < 0x7F),
    ),
  );
}

/// 0x57 kaydı üretir (sahte bileklik ve testler için).
List<int> encodeStoredReminder(Reminder r, {required int index, int readId = 0}) {
  final label = reminderLabelBytes(r.label);
  final out = List<int>.filled(reminderRecordLength, 0);
  out[0] = ReminderCmd.get;
  out[1] = readId & 0xFF;
  out[2] = (readId >> 8) & 0xFF;
  out[3] = index;
  out[4] = r.enabled ? r.kind.code : 0;
  out[5] = toBcd(r.minuteOfDay ~/ 60);
  out[6] = toBcd(r.minuteOfDay % 60);
  out[7] = r.weekdays & 0x7F;
  out[8] = label.length;
  out.setAll(9, label);
  return out;
}

/// 0x23 yazımını bilekliğin bir seferde aldığı en büyük boya
/// ([maxPacket], 0x01 yanıtındaki değer) göre parçalar. Her parça tam
/// kayıtlardan oluşur; son parça `23 FF` ile biter (bileklik o anda
/// kaydeder). Paketler 16 baytlık değil, CRC taşımaz.
List<Uint8List> setRemindersCommand(
  List<Reminder> reminders, {
  int maxPacket = 244,
}) {
  if (reminders.isEmpty || reminders.length > Reminder.maxCount) {
    throw ArgumentError.value(reminders.length, 'reminders', '1-5 olmalı');
  }
  final perPacket = (maxPacket ~/ reminderRecordLength).clamp(1, 255);
  final records = [
    for (var i = 0; i < reminders.length; i++)
      encodeReminder(reminders[i], index: i, total: reminders.length),
  ];
  final out = <Uint8List>[];
  for (var i = 0; i < records.length; i += perPacket) {
    out.add(
      Uint8List.fromList([
        for (final r in records.skip(i).take(perPacket)) ...r,
      ]),
    );
  }
  const end = [ReminderCmd.set, 0xFF];
  if (out.last.length + end.length <= maxPacket) {
    out[out.length - 1] = Uint8List.fromList([...out.last, ...end]);
  } else {
    out.add(Uint8List.fromList(end));
  }
  return out;
}

/// 0x23 yanıtı: `23 R1 23 R2 … 23 EE`. Kayıtları alındı olarak döner;
/// `23 EE` gelince true. Bir yanıt birden fazla bildirimde gelebilir.
bool remindersSavedIn(List<int> raw) {
  for (var i = 0; i + 1 < raw.length; i += 2) {
    if (raw[i] == ReminderCmd.set && raw[i + 1] == ReminderCmd.saved) {
      return true;
    }
  }
  return false;
}

/// 0x57 00: kayıtlı hatırlatıcıları ister.
Packet getRemindersCommand() =>
    Packet.build(ReminderCmd.get, [ReminderCmd.read]);

/// 0x57 99: bileklikteki tüm hatırlatıcıları siler. Silme yanıtının gövdesi
/// belgede yok; aynı komut koduyla gelen paket onay sayılır (gerçek
/// cihazda doğrulanacak).
Packet deleteRemindersCommand() =>
    Packet.build(ReminderCmd.get, [ReminderCmd.deleteAll]);
