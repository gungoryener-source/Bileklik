import 'dart:async';

import 'protocol/commands.dart';
import 'protocol/history.dart';
import 'protocol/packet.dart';
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

  void _onData(List<int> raw) {
    if (raw.isEmpty) return;
    final command = raw[0] & 0x7F;
    if (command == Cmd.realtime && raw.length > Packet.length) {
      _realtime.add(Decoders.realtime(raw));
      return;
    }
    final history = _history;
    if (history != null && history.kind.command == command) {
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
        final collector = _HistoryCollector(kind);
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
  }
}

class _HistoryCollector {
  _HistoryCollector(this.kind);

  final HistoryKind kind;
  final _records = <List<int>>[];
  final _done = Completer<List<List<int>>>();

  Future<List<List<int>>> get done => _done.future;

  void add(List<int> raw) {
    if (_done.isCompleted) return;
    if (raw[0] & Packet.errorBit != 0) {
      _done.completeError(
        DeviceCommandException(kind.command, 'cihaz hata döndü'),
      );
      return;
    }
    final chunk = splitHistory(kind, raw);
    _records.addAll(chunk.records);
    if (chunk.ended) _done.complete(_records);
  }
}
