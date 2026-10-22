import 'dart:async';

import 'protocol/commands.dart';
import 'protocol/ecg.dart';
import 'protocol/exercise.dart';
import 'protocol/history.dart';
import 'protocol/packet.dart';
import 'protocol/reminders.dart';
import 'protocol/settings.dart';
import 'transport.dart';

class DeviceCommandException implements Exception {
  final int command;
  final String message;
  DeviceCommandException(this.command, this.message);

  @override
  String toString() =>
      'Komut 0x${command.toRadixString(16).padLeft(2, '0')}: $message';
}

/// Bileklik komutlarını gönderip yanıtlarını çözen katman.
///
/// Her komut için cihazın aynı komut koduyla döndüğü yanıtı bekler.
/// 0x09 anlık veri akışı ayrı bir yayın olarak sunulur.
class WristbandClient {
  WristbandClient(this.transport, {this.timeout = const Duration(seconds: 5)}) {
    _sub = transport.incoming.listen(_onData);
  }

  final DeviceTransport transport;
  final Duration timeout;
  late final StreamSubscription<List<int>> _sub;
  final _pending = <int, Completer<Packet>>{};
  final _realtime = StreamController<RealtimeData>.broadcast();

  Stream<RealtimeData> get realtime => _realtime.stream;

  final _ecg = StreamController<EcgPacket>.broadcast();

  /// 0x07 ile açılan ham EKG örnekleri.
  Stream<EcgPacket> get ecg => _ecg.stream;

  final _exercise = StreamController<ExerciseEvent>.broadcast();

  /// Egzersiz sürerken gelen 0x18 verileri ve uyarıları.
  Stream<ExerciseEvent> get exerciseEvents => _exercise.stream;

  final _wear = StreamController<WearEvent>.broadcast();

  /// Ölçüm sırasında gelen takma algılama bildirimleri (0x86).
  Stream<WearEvent> get wearEvents => _wear.stream;
  Completer<void>? _wearAck;

  void _onData(List<int> raw) {
    if (raw.isEmpty) return;
    // 0x86'nın 7. biti zaten 1; hata yanıtı sanılmasın diye önce bakılır.
    if (raw[0] == SettingsCmd.wearDetection) {
      final ack = _wearAck;
      if (ack != null && !ack.isCompleted) {
        _wearAck = null;
        ack.complete();
        return;
      }
      if (WearEvent.parse(raw) case final e?) _wear.add(e);
      return;
    }
    final command = raw[0] & 0x7F;
    if (command == Cmd.realtime && raw.length > Packet.length) {
      _realtime.add(Decoders.realtime(raw));
      return;
    }
    if (EcgPacket.isData(raw)) {
      _ecg.add(EcgPacket.parse(raw));
      return;
    }
    if (command == ExerciseCmd.live && raw.length > 3) {
      _exercise.add(ExerciseEvent.parse(raw));
      return;
    }
    final history = _history;
    if (history != null && history.command == command) {
      history.add(raw);
      return;
    }
    final completer = _pending.remove(command);
    if (completer == null) return;
    try {
      final packet = Packet.parse(raw);
      if (packet.isError) {
        completer.completeError(
          DeviceCommandException(command, 'cihaz hata döndü'),
        );
      } else {
        completer.complete(packet);
      }
    } on FormatException catch (e) {
      completer.completeError(DeviceCommandException(command, e.message));
    }
  }

  Future<Packet> _request(Packet packet) {
    final completer = Completer<Packet>();
    _pending[packet.command]?.completeError(
      DeviceCommandException(packet.command, 'yeni istekle değiştirildi'),
    );
    _pending[packet.command] = completer;
    transport.send(packet.bytes);
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(packet.command);
        throw DeviceCommandException(packet.command, 'yanıt gelmedi');
      },
    );
  }

  Future<void> syncTime(DateTime now) => _request(Commands.setTime(now));

  Future<DateTime> getTime() async =>
      Decoders.time(await _request(Commands.getTime()));

  Future<void> setPersonalInfo(PersonalInfo info) =>
      _request(Commands.setPersonalInfo(info));

  Future<PersonalInfo> getPersonalInfo() async =>
      Decoders.personalInfo(await _request(Commands.getPersonalInfo()));

  Future<BatteryStatus> getBattery() async =>
      Decoders.battery(await _request(Commands.batteryLevel()));

  Future<void> startRealtime() => transport.send(Commands.realtime(true).bytes);

  Future<void> stopRealtime() => _request(Commands.realtime(false));

  /// 0x19: egzersizi başlatır, duraklatır, sürdürür ya da bitirir.
  Future<ExerciseControlResult> controlExercise(
    ExerciseAction action, [
    SportType type = SportType.run,
  ]) async => ExerciseControlResult.parse(
    await _request(exerciseControl(action, type)),
  );

  /// EKG ölçümünü başlatır: önce ham veri akışı, sonra 0x28 04 01.
  Future<void> startEcg({int seconds = 30}) async {
    await _request(ecgRawSwitch(true));
    await _request(measurement(MeasureMode.ecg, start: true, seconds: seconds));
  }

  Future<void> stopEcg() async {
    await _request(measurement(MeasureMode.ecg, start: false));
    await _request(ecgRawSwitch(false));
  }

  /// 0x28 02/03: elle nabız ya da SpO2 ölçümünü başlatır. Ölçülen değer
  /// saniyede bir 0x09 anlık verisiyle gelir; anlık mod açık olmalı.
  Future<void> startSpot(MeasureMode mode, {int seconds = 30}) =>
      _request(measurement(mode, start: true, seconds: seconds));

  Future<void> stopSpot(MeasureMode mode) =>
      _request(measurement(mode, start: false));

  /// 0x2A: bir türün otomatik ölçüm ayarını yazar.
  Future<void> setAutoMeasure(AutoMeasureConfig config) =>
      _request(setAutoMeasureCommand(config));

  /// 0x2B: bir türün otomatik ölçüm ayarını okur.
  Future<AutoMeasureConfig> getAutoMeasure(AutoMeasureType type) async =>
      decodeAutoMeasure(await _request(getAutoMeasureCommand(type)), type);

  /// 0x86: takma algılamasını açar ya da kapatır. Onay paketinin gövdesi
  /// PDF'te yok; gelen ilk 0x86 paketi onay sayılır (gerçek cihazda
  /// doğrulanacak).
  Future<void> setWearDetection(bool enabled) async {
    final ack = Completer<void>();
    _wearAck = ack;
    await transport.send(wearDetectionCommand(enabled));
    await ack.future.timeout(
      timeout,
      onTimeout: () {
        if (_wearAck == ack) _wearAck = null;
        throw DeviceCommandException(
          SettingsCmd.wearDetection,
          'yanıt gelmedi',
        );
      },
    );
  }

  /// 0x57: bileklikteki hatırlatıcıları okur. Kayıtlar geçmiş verisi gibi
  /// uç uca gelir ve `57 FF` ile biter (gerçek cihazda doğrulanacak).
  Future<List<Reminder>> getReminders() async {
    if (_history != null) {
      throw DeviceCommandException(
        ReminderCmd.get,
        'başka bir senkron sürüyor',
      );
    }
    final collector = _HistoryCollector(ReminderCmd.get, reminderRecordLength);
    _history = collector;
    try {
      await transport.send(getRemindersCommand().bytes);
      final records = await collector.done.timeout(
        timeout,
        onTimeout: () {
          throw DeviceCommandException(ReminderCmd.get, 'yanıt gelmedi');
        },
      );
      return [for (final r in records) decodeReminder(r)];
    } finally {
      _history = null;
    }
  }

  /// 0x23: hatırlatıcı listesini bilekliğe yazar; boş listede 0x57 99 ile
  /// hepsini siler. Bileklik 16 baytlık `23` onayı döner (gerçek cihazda
  /// doğrulanacak).
  Future<void> setReminders(List<Reminder> reminders) async {
    if (reminders.isEmpty) {
      await _request(deleteRemindersCommand());
      return;
    }
    final completer = Completer<Packet>();
    _pending[ReminderCmd.set]?.completeError(
      DeviceCommandException(ReminderCmd.set, 'yeni istekle değiştirildi'),
    );
    _pending[ReminderCmd.set] = completer;
    await transport.send(setRemindersCommand(reminders));
    await completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(ReminderCmd.set);
        throw DeviceCommandException(ReminderCmd.set, 'yanıt gelmedi');
      },
    );
  }

  /// 0x25: hareketsizlik uyarısını yazar.
  Future<void> setSedentary(SedentaryConfig config) =>
      _request(setSedentaryCommand(config));

  /// 0x26: hareketsizlik uyarısını okur.
  Future<SedentaryConfig> getSedentary() async => SedentaryConfig.fromBytes(
    (await _request(getSedentaryCommand())).payload,
  );

  _HistoryCollector? _history;

  /// Bir geçmiş türünün [since] sonrasındaki tüm kayıtlarını çeker.
  ///
  /// Cihaz her istekte en fazla [pageSize] kayıt döner; tam sayfa gelirse
  /// "devam" moduyla sonraki sayfa istenir.
  Future<List<List<int>>> fetchHistory(
    HistoryKind kind, {
    DateTime? since,
    int pageSize = 50,
  }) async {
    if (_history != null) {
      throw DeviceCommandException(kind.command, 'başka bir senkron sürüyor');
    }
    final all = <List<int>>[];
    var mode = HistoryMode.read;
    try {
      while (true) {
        final collector = _HistoryCollector(kind.command, kind.recordLength);
        _history = collector;
        await transport.send(historyRequest(kind, mode, since: since).bytes);
        final page = await collector.done.timeout(
          timeout,
          onTimeout: () {
            throw DeviceCommandException(kind.command, 'yanıt gelmedi');
          },
        );
        all.addAll(page);
        if (kind == HistoryKind.dailyTotals || page.length < pageSize) break;
        mode = HistoryMode.next;
      }
    } finally {
      _history = null;
    }
    return all;
  }

  Future<void> dispose() async {
    await _sub.cancel();
    await _realtime.close();
    await _exercise.close();
    await _ecg.close();
    await _wear.close();
  }
}

class _HistoryCollector {
  _HistoryCollector(this.command, this.recordLength);

  final int command;
  final int recordLength;
  final _records = <List<int>>[];
  final _done = Completer<List<List<int>>>();

  Future<List<List<int>>> get done => _done.future;

  void add(List<int> raw) {
    if (_done.isCompleted) return;
    if (raw[0] & Packet.errorBit != 0) {
      _done.completeError(DeviceCommandException(command, 'cihaz hata döndü'));
      return;
    }
    final chunk = splitRecords(command, recordLength, raw);
    _records.addAll(chunk.records);
    if (chunk.ended) _done.complete(_records);
  }
}
